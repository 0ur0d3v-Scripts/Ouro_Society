-- Webhook logging system

function SendWebhookLog(job, title, description)
    local jobConfig = Config.Jobs[job]
    local webhook = jobConfig and jobConfig.Webhook or ""
    
    if webhook == "" or webhook == nil then
        return
    end
    
    local embed = {
        {
            ["color"] = 16711680,
            ["title"] = title,
            ["description"] = description,
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S"),
            },
        }
    }
    
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        username = "Ouro Society",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

function SendDutyWebhookLog(job, playerName, status)
    local webhook = Config.DutyWebhooks[job] or ""
    
    if webhook == "" or webhook == nil then
        return
    end
    
    local color = status == "On Duty" and 65280 or 16711680
    
    local embed = {
        {
            ["color"] = color,
            ["title"] = "Duty Status Changed",
            ["description"] = playerName .. " - " .. status,
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S"),
            },
        }
    }
    
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        username = "Ouro Society - Duty Log",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

function SendAlertWebhookLog(job, playerName, message, coords)
    local jobConfig = Config.Jobs[job]
    local webhook = jobConfig and jobConfig.Webhook or ""
    
    if webhook == "" or webhook == nil then
        return
    end
    
    local coordsStr = "X: " .. coords.x .. " Y: " .. coords.y .. " Z: " .. coords.z
    
    local embed = {
        {
            ["color"] = 16776960,
            ["title"] = "Alert Sent",
            ["description"] = playerName .. " sent an alert: " .. message,
            ["fields"] = {
                {
                    ["name"] = "Location",
                    ["value"] = coordsStr,
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S"),
            },
        }
    }
    
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        username = "Ouro Society - Alerts",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Export logging functions
exports('SendWebhookLog', SendWebhookLog)
exports('SendDutyWebhookLog', SendDutyWebhookLog)
exports('SendAlertWebhookLog', SendAlertWebhookLog)

