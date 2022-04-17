Scully.Discord = {
    Players = {}
}

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

function Scully.Discord.GetUserRoles(source)
    local userID, userRoles = Scully.Discord.GetUserID(source), nil
    if userID then
        local user = Scully.Discord.Request(userID)
        if user.code == 200 then
            local data = json.decode(user.data)
            userRoles = data.roles
        end
    end
    return userRoles
end

function Scully.Discord.HasPermission(source, permission)
    local roles, hasPermission = {}, false
    if Scully.Discord.Players[source] then
        if Scully.Discord.Players[source].Permissions[permission] then
            return true
        end
        roles = Scully.Discord.Players[source].Roles
    else
        roles = Scully.Discord.GetUserRoles(source)
    end
    if roles then
        for _, role in ipairs(roles) do
            if type(permission) == 'table' then
                for k, v in ipairs(permission) do
                    if role == Scully.Permissions[v] then
                        hasPermission = true
                        break
                    end
                end
            else
                if role == Scully.Permissions[permission] then
                    hasPermission = true
                    break
                end
            end
        end
    end
    return hasPermission
end

exports('hasPermission', Scully.Discord.HasPermission)

CreateThread(function()
    if GetCurrentResourceName() ~= 'scully_perms' then
        print('^1ERROR: ^7The resource needs to be named ^5scully_perms^7.')
    elseif Scully.Guild == '' or Scully.Token == '' then
        print('^1ERROR: ^7Please make sure to configure the resource in the ^5config.lua^7.')
    end
end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
	local src = source
    local userID, userRoles, userPermissions = Scully.Discord.GetUserID(src), Scully.Discord.GetUserRoles(src), {}
    for permission, role in pairs(Scully.Permissions) do
        for k, v in ipairs(userRoles) do
            if role == v then
                table.insert(userPermissions, permission)
                ExecuteCommand(('add_principal identifier.discord:%s group.%s'):format(userID, permission))
            end
        end
    end
    Scully.Discord.Players[src] = {
        Roles = userRoles,
        Permissions = userPermissions
    }
end)

AddEventHandler('playerDropped', function(reason)
	local src = source
    local userID = Scully.Discord.GetUserID(src)
    if Scully.Discord.Players[src] then
        local userPermissions = Scully.Discord.Players[src].Permissions
        for _, permission in ipairs(userPermissions) do
            ExecuteCommand(('remove_principal identifier.discord:%s group.%s'):format(userID, permission))
        end
    end
    Scully.Discord.Players[src] = nil
end)