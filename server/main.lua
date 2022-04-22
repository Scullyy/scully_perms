Scully.Discord = {
    Players = {}
}

CreateThread(function()
    if GetCurrentResourceName() ~= 'scully_perms' then
        print('^1ERROR: ^7The resource needs to be named ^5scully_perms^7.')
    elseif Scully.Guild == '' or Scully.Token == '' then
        print('^1ERROR: ^7Please make sure to configure the resource in the ^5config.lua^7.')
    end
end)

function Scully.Discord.Request(userid)
    local data = nil
    PerformHttpRequest('https://discordapp.com/api/guilds/' .. Scully.Guild .. '/members/' .. userid, function(errorCode, resultData, resultHeaders)
		data = {data=resultData, code=errorCode, headers=resultHeaders}
    end, 'GET', '', {['Content-Type'] = 'application/json', ['Authorization'] = 'Bot ' .. Scully.Token})

    while not data do
        Wait(0)
    end
	
    return data
end

function Scully.Discord.GetUserID(source)
    local userID = nil
	for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
		if string.match(identifier, 'discord:') then
			userID = string.gsub(identifier, 'discord:', '')
			break
		end
	end
    return userID
end

function Scully.Discord.GetUserInfo(source)
    local userID, userRoles = Scully.Discord.GetUserID(source), nil
    if userID then
        local user = Scully.Discord.Request(userID)
        if user.code == 200 then
            local data = json.decode(user.data)
            userRoles = data.roles
        end
    end
    return userID, userRoles
end

function Scully.Discord.HasPermission(source, permission)
    local user, hasPermission = Scully.Discord.Players[source], false
    if type(permission) == 'table' then
        for _, perm in ipairs(permission) do
            if user.Permissions[perm] then
                hasPermission = true
                break
            end
        end
    else
        if user.Permissions[permission] then
            hasPermission = true
        end
    end
    return hasPermission
end

exports('hasPermission', Scully.Discord.HasPermission)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
	local src = source
    local userID, userRoles = Scully.Discord.GetUserInfo(src)
    local userPermissions = {}
    for permission, role in pairs(Scully.Permissions) do
        for k, v in ipairs(userRoles) do
            if type(role) == 'table' then
                for _, roleid in ipairs(role) do
                    if roleid == v then
                        userPermissions[permission] = true
                        ExecuteCommand(('add_principal identifier.discord:%s group.%s'):format(userID, permission))
                        if Scully.Debug then
                            print('^5[scully_perms] ^7Permission added: ^5[^2' .. userID .. ' : ' .. permission .. '^5]^7')
                        end
                    end
                end
            else
                if role == v then
                    userPermissions[permission] = true
                    ExecuteCommand(('add_principal identifier.discord:%s group.%s'):format(userID, permission))
                    if Scully.Debug then
                        print('^5[scully_perms] ^7Permission added: ^5[^2' .. userID .. ' : ' .. permission .. '^5]^7')
                    end
                end
            end
        end
    end
    Scully.Discord.Players[src] = {
        ID = userID,
        Roles = userRoles,
        Permissions = userPermissions
    }
end)

AddEventHandler('playerDropped', function(reason)
	local src = source
    local user = Scully.Discord.Players[src]
    if user then
        local userPermissions = user.Permissions
        for _, permission in ipairs(userPermissions) do
            ExecuteCommand(('remove_principal identifier.discord:%s group.%s'):format(user.ID, permission))
            if Scully.Debug then
                print('^5[scully_perms] ^7Permission removed: ^5[^1' .. user.ID .. ' : ' .. permission .. '^5]^7')
            end
        end
    end
    Scully.Discord.Players[src] = nil
end)