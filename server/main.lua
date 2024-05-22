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

if not Config or not Config.Token or Config.Token == '' then
    debugPrint('error', 'You need to configure your bot token in the config.lua')
    return
end

if not Config.Guilds or next(Config.Guilds) == nil then
    debugPrint('error', 'You need to configure your guilds in the config.lua')
    return
end

---@param userId string
---@param guildId string
---@return table | false
local function sendRequest(userId, guildId)
    local data = nil
    local request = ('https://discord.com/api/guilds/%s/members/%s'):format(guildId, userId)

    PerformHttpRequest(request, function(code, result, headers)
        if not result then
            debugPrint('error', 'Failed to get a response from the server.')
            return
        end
        data = { data = result, code = code, headers = headers }
        local error = ApiCodes[code]
        if error then
            debugPrint(error.bad and 'error' or 'success', error.text)
        else
            debugPrint('error', 'Unknown response code: ' .. code)
        end
    end, 'GET', '', {['Content-Type'] = 'application/json', ['Authorization'] = 'Bot ' .. Config.Token})

    local start = GetGameTimer()

    while not data do
        Wait(100)  -- Small wait to reduce CPU usage
        local timer = GetGameTimer() - start

        if timer > Config.MaxRefreshTime then
            debugPrint('error', 'The request timed out (Discord). Please increase the MaxRefreshTime in config.lua if you have a big server.')
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
    local userID, roles = getUserIdentifier(source), {}

    if userID then
        local rolesFound = false
        for guildName, guildData in pairs(Config.Guilds) do
            local user = sendRequest(userID, guildData.GuildID)
            if user then
                if user.code == 200 then
                    local data = json.decode(user.data)
                    if data.roles then
                        for _, role in ipairs(data.roles) do
                            table.insert(roles, { role = role, guild = guildName })
                        end
                        rolesFound = true
                    end
                else
                    debugPrint('error', 'Failed to fetch user roles for guild: ' .. guildName)
                end
            else
                debugPrint('error', 'Failed to send request for user info for guild: ' .. guildName)
            end
        end

        if not rolesFound then
            debugPrint('error', 'Failed to fetch user roles (if any), make sure the bot is invited to your servers and that the token is correct.')
        end
    else
        debugPrint('error', 'Failed to get user identifier.')
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

---@param userId string
---@param permission string
local function removePermission(userId, permission)
    ExecuteCommand(('remove_principal identifier.discord:%s group.%s'):format(userId, permission))
    debugPrint('success', ('The %s permission has been removed from %s'):format(permission, userId))
end

AddEventHandler('playerJoining', function(_)
    local src = source --[[@as number]]
    local userID, userRoles = getUserInfo(src)
    local userPermissions = {}

    if not userRoles or #userRoles == 0 then
        debugPrint('error', 'User has no roles in any server.')
    else
        for _, roleData in ipairs(userRoles) do
            local guildData = Config.Guilds[roleData.guild]
            if guildData then
                for permission, role in pairs(guildData.Permissions) do
                    if type(role) == 'table' then
                        for _, roleId in ipairs(role) do
                            if roleId == roleData.role then
                                userPermissions[permission] = true
                                addPermission(userID, permission)
                            end
                        end
                    else
                        if role == roleData.role then
                            userPermissions[permission] = true
                            addPermission(userID, permission)
                        end
                    end
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
            removePermission(user.ID, permission)
        end

        Players[src] = nil
    end
end)

local lock = false

CreateThread(function()
    while true do
        if not lock then
            lock = true
            for src, player in pairs(Players) do
                if player then
                    local userID, userRoles = getUserInfo(src)
                    if userID and userRoles then
                        local userPermissions = {}
                        for _, roleData in ipairs(userRoles) do
                            local guildData = Config.Guilds[roleData.guild]
                            if guildData then
                                for permission, role in pairs(guildData.Permissions) do
                                    if type(role) == 'table' then
                                        for _, roleId in ipairs(role) do
                                            if roleId == roleData.role then
                                                userPermissions[permission] = true
                                                if not player.Permissions[permission] then
                                                    addPermission(userID, permission)
                                                end
                                            end
                                        end
                                    else
                                        if role == roleData.role then
                                            userPermissions[permission] = true
                                            if not player.Permissions[permission] then
                                                addPermission(userID, permission)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        for permission in pairs(player.Permissions) do
                            if not userPermissions[permission] then
                                removePermission(userID, permission)
                            end
                        end
                        Players[src].Permissions = userPermissions
                    end
                end
            end
            lock = false
        end
        Wait(Config.RefreshThrottle)
    end
end)
