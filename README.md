# Scully Perms
![scully](https://github.com/Scullyy/scully_perms/assets/136627966/d8a2a42b-9f1e-4d53-8acc-0c03ecc86642)

## Need Help? Join My Discord!
[Join Discord](https://discord.gg/eNtGFS6)

## How to Install
Add this to your `server.cfg` file:

```plaintext
ensure scully_perms

add_ace resource.scully_perms command.add_principal allow
add_ace resource.scully_perms command.remove_principal allow
```

## How to Use
You can check permissions by using either of these methods (with exports), or by using `IsPlayerAceAllowed` directly:

```lua
exports['scully_perms']:hasPermission(source, 'permission')
```
or
```lua
exports['scully_perms']:hasPermission(source, {'permission1', 'permission2', 'permission3'})
```

### Examples of Valid ACE Syntax

You can set permissions in different ways. Here are some examples:
```lua
-- Single role permission
['leo'] = 'roleid1'

-- Multiple roles for one permission
['admin'] = {'roleid2', 'roleid3'}

-- Role with an underscore
['team_lead'] = 'roleid4'

-- Role with a number
['supervisor1'] = 'roleid5'

-- Role with mixed case (valid but not recommended)
['SuperAdmin'] = 'roleid6'
```

### Examples of Invalid ACE Syntax
Here are some incorrect examples:
```lua
-- Using spaces in a role name (invalid)
['leo 2'] = 'roleid'

-- Role name with a dot/comma/etc.
['leo.2'] = 'roleid'

-- Using special characters in a role name (invalid)
['leo@admin'] = 'roleid'

-- Empty role ID (invalid)
['admin'] = ''

-- Role ID not a string (invalid)
['mod'] = 12345

-- Role name starting with a number (invalid)
['1admin'] = 'roleid'

-- Role ID is nil (invalid)
['user'] = nil

-- Using mixed types in role IDs (invalid)
['moderator'] = {'roleid1', 12345}

-- Special characters in role ID (invalid)
['vip'] = 'role$id'

-- Empty role names (invalid)
[''] = 'roleid'

-- Do this instead (explained in FAQ)
['group.leo'] = 'roleid'
```

## Example Configurations
For one Guild:
```lua
Config = {
    Debug = true,
    Token = '', -- Set up your BOT (Tutorial: https://dfuze.vip/scully/scullyperms.mp4)
    RefreshThrottle = 20000, -- Time between refreshes in milliseconds (20000ms = 20 seconds)
    MaxRefreshTime = 15000, -- Max time to wait for API response in milliseconds (15000ms = 15 seconds)
    Guilds = {
        ['Server Name'] = {
            GuildID = '', -- Guild ID
            Permissions = {
                ['leo'] = 'roleid1',
                ['admin'] = {'roleid2', 'roleid3'},
                ['moderator'] = 'roleid4',
                ['supervisor1'] = 'roleid5',
                ['leo.2'] = 'roleid6'
            }
        }
    }
}
```
For two or more Guilds:
```lua
Config = {
    Debug = true,
    Token = '', -- Set up your BOT (Tutorial: https://dfuze.vip/scully/scullyperms.mp4)
    RefreshThrottle = 20000, -- Time between refreshes in milliseconds (20000ms = 20 seconds)
    MaxRefreshTime = 15000, -- Max time to wait for API response in milliseconds (15000ms = 15 seconds)
    Guilds = {
        ['Guild Name 1'] = {
            GuildID = '', -- Guild ID
            Permissions = {
                ['leo'] = 'roleid1',
                ['admin'] = {'roleid2', 'roleid3'},
                ['mOderaTor'] = 'roleid4',
                ['superVisor1'] = 'roleid5',
            }
        },
        ['Guild Name 2'] = {
            GuildID = '', -- Guild ID
            Permissions = {
                ['leo'] = 'roleid1',
                ['admin'] = {'roleid2', 'roleid3'},
                ['mOderaTor'] = 'roleid4',
                ['superVisor1'] = 'roleid5',
            }
        },
        -- Add more Guilds here
    }
}
```
## Updates Overview
- Added error messages for missing guild and token in `config.lua`.
- Fixed/Added `sendRequest` function to use `GuildID`.
- Added error handling for request timeouts.
- Improved role fetching logic and error messages.
- Updated user role permission checking and setting.
- Added function to remove permissions.
- Added infinite role checking for players.
- Updated `config.lua` with new structure for guilds and permissions.
- Expanded ReadMe for more clarity.

## Frequently Asked Questions
### Why is this invalid?
```lua
['group.leo'] = 'roleid'
-- or
['group.whatever'] = 'roleid'
```

Adding `['group.leo'] = 'roleid'` to your `config.lua` might result in it being interpreted as `group.group.leo`, causing errors in permission checking.
> This feature saves you from adding `group.` every time!

## Need Assistance?
If you need help, join our [Discord Server](https://discord.gg/eNtGFS6).