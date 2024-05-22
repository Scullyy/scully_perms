Config = {
    Debug = false, -- Turn on debug mode (true/false)
    Token = '', -- Setup BOT (Tutorial: https://dfuze.vip/scully/scullyperms.mp4)
    -- ❗ Required bot permission:
    -- Read Messages/View Channels: Bot needs to see the channels and get member info
    
    RefreshThrottle = 20000, -- Wait time between refreshes in milliseconds (20000ms = 20 seconds)
    MaxRefreshTime = 15000, -- Max time in milliseconds to wait for API response (15000ms = 15 seconds)
    Guilds = {
        ['Server Name'] = {
            GuildID = '', -- Guild ID
            Permissions = {
                ['member'] = 'roleid', -- Example 1
                ['perm2'] = {'roleid', 'roleid2', 'roleid3'} -- Example 2
            }
        },
        -- ['Server Name'] = {
        --     GuildID = '', -- Third guild ID (Optional)
        --     Permissions = {
        --         ['perm'] = 'roleid',
        --         ['perm2'] = {'roleid', 'roleid2', 'roleid3'}
        --     }
        -- },
        -- Add more guilds here (Optional)
    }
}