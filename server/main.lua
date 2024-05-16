local Players = {}
local ApiCodes = {
    [200] = {text = 'The request completed successfully.', bad = false},
    [201] = {text = 'The entity was created successfully.', bad = false},
    [204] = {text = 'The request completed successfully but returned no content.', bad = false},
    [304] = {text = 'The entity was not modified (no action was taken).', bad = false},
    [400] = {text = 'The request was improperly formatted, or the server couldn\'t understand it.', bad = true},
    [401] = {text = 'The Authorization header was missing or invalid.', bad = true},
    [403] = {text = 'The Authorization token you passed did not have permission to the resource.', bad = true},
    [404] = {text = 'The resource at the location specified doesn\'t exist.', bad = true},
    [405] = {text = 'The HTTP method used is not valid for the location specified.', bad = true},
    [429] = {text = 'You are being rate-limited.', bad = true},
    [502] = {text = 'There was not a gateway available to process your request.', bad = true},
    [500] = {text = 'The server had an error processing your request.', bad = true},
}

---@param prefix string
---@param message string
local function debugPrint(prefix, message)
    if not Config.Debug and (prefix ~= 'error') then return end

    prefix = (prefix == 'error' and '^1[ERROR] ') or (prefix == 'success' and '^2[SUCCESS] ') --[[@as string]]

    print(('%s ^7%s'):format(prefix, message))
end

if Config.Guild == '' or Config.Token == '' then
    debugPrint('error', 'You need to configure your guild and token in the config.lua')
    return
end

---@param userId string
---@return table | false
local function sendRequest(userId)
    local data = nil
    local request = ('https://discord.com/api/guilds/%s/members/%s'):format(Config.Guild, userId)

    PerformHttpRequest(request, function(code, result, headers)
        data = { data = result, code = code, headers = headers }
        local error = ApiCodes[code]

        debugPrint(error.bad and 'error' or 'success', error.text)
    end, 'GET', '', {['Content-Type'] = 'application/json', ['Authorization'] = 'Bot ' .. Config.Token})

    local start = GetGameTimer()

    while not data do
        Wait(0)

        local timer = GetGameTimer() - start

        if timer > 15000 then
            debugPrint('error', 'The request timed out.')
            return false
        end
    end

    return data
end

---@param source number
---@return string | nil
local function getUserIdentifier(source)
    local identifier = GetPlayerIdentifierByType(source --[[@as string]], 'discord')

    return identifier and string.gsub(identifier, 'discord:', '')
end

---@param source number
---@return string | nil, table | nil
local function getUserInfo(source)
    local userID, roles = getUserIdentifier(source), nil
    local user = userID and sendRequest(userID)

    if user?.code == 200 then
        ---@diagnostic disable-next-line: need-check-nil
        local data = json.decode(user.data)

        roles = data.roles
    end

    return userID, roles
end

---@param source number
---@param permission string | table
local function hasPermission(source, permission)
    local user, value = Players[source], false

    if type(permission) == 'table' then
        for i = 1, #permission do
            local perm = permission[i]

            if user.Permissions[perm] then
                value = true
                break
            end
        end
    else
        if user.Permissions[permission] then
            value = true
        end
    end

    return value
end
exports('hasPermission', hasPermission)

---@param userId string
---@param permission string
local function addPermission(userId, permission)
    ExecuteCommand(('add_principal identifier.discord:%s group.%s'):format(userId, permission))
    debugPrint('success', ('The %s permission has been added to %s'):format(permission, userId))
end

AddEventHandler('playerJoining', function(_)
    local src = source --[[@as number]]
    local userID, userRoles = getUserInfo(src)
    local userPermissions = {}

    if not userRoles then
        debugPrint('error', 'Failed to fetch user roles, make sure the bot is invited to your server and that the token is correct.')
        return
    end

    for permission, role in pairs(Config.Permissions) do
        for i = 1, #userRoles do
            local v = userRoles[i]

            if type(role) == 'table' then
                for k = 1, #role do
                    local roleid = role[k]

                    if roleid == v then
                        userPermissions[permission] = true

                        addPermission(userID --[[@as string]], permission)
                    end
                end
            else
                if role == v then
                    userPermissions[permission] = true

                    addPermission(userID --[[@as string]], permission)
                end
            end
        end
    end

    Players[src] = {
        ID = userID,
        Roles = userRoles,
        Permissions = userPermissions
    }
end)

AddEventHandler('playerDropped', function(_)
    local src = source --[[@as number]]
    local user = Players[src]

    if user then
        for permission, _ in pairs(user.Permissions) do
            ExecuteCommand(('remove_principal identifier.discord:%s group.%s'):format(user.ID, permission))
            debugPrint('success', ('The %s permission has been removed from %s'):format(permission, user.ID))
        end

        Players[src] = nil
    end
end)