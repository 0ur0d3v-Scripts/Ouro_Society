if not Config.ClansEnabled then return end

local VORPcore = exports.vorp_core:GetCore()

-- Cache
local ClanLedgers = {}

-- Load all clan ledgers into cache
CreateThread(function()
    Wait(3000)
    LoadAllClanLedgers()
    RegisterClanContainers()
end)

function LoadAllClanLedgers()
    MySQL.query('SELECT * FROM ouro_clan_ledger', {}, function(result)
        if result then
            for _, ledger in ipairs(result) do
                ClanLedgers[ledger.clan] = ledger.ledger or 0
            end
            print("[Ouro Society] Loaded " .. #result .. " clan ledgers")
        end
    end)
end

-- Register all clan containers with VORP Inventory
function RegisterClanContainers()
    for clanName, clanData in pairs(Config.Clans) do
        if clanData.ContainerID and clanData.ContainerName then
            -- Convert ID to string to match VORP's internal ID handling
            local containerId = tostring(clanData.ContainerID)
            
            -- Register with VORP Inventory
            exports.vorp_inventory:registerInventory({
                id = containerId,
                name = clanData.ContainerName,
                limit = clanData.ContainerSlots or 150,
                acceptWeapons = true,
                shared = true,
                ignoreItemStackLimit = true,
                whitelistItems = false,
                UsePermissions = false,
                UseBlackList = false,
                whiteList = {},
                blackList = {}
            })
            print("[Ouro Society] Registered clan inventory: " .. clanData.ContainerName .. " (ID: " .. containerId .. ")")
        end
    end
    print("[Ouro Society] Registered " .. TableLength(Config.Clans) .. " clan inventory containers")
end

function TableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

-- Get clan ledger balance
function GetClanLedger(clan)
    return ClanLedgers[clan] or 0
end

-- Update clan ledger
function UpdateClanLedger(clan, amount, operation)
    local currentBalance = GetClanLedger(clan)
    local newBalance = currentBalance
    
    if operation == "add" then
        newBalance = currentBalance + amount
    elseif operation == "remove" then
        if currentBalance < amount then
            return false, "Insufficient funds"
        end
        newBalance = currentBalance - amount
    else
        newBalance = amount
    end
    
    ClanLedgers[clan] = newBalance
    
    MySQL.update('UPDATE ouro_clan_ledger SET ledger = ? WHERE clan = ?', {newBalance, clan}, function(affectedRows)
        if affectedRows == 0 then
            MySQL.insert('INSERT INTO ouro_clan_ledger (clan, ledger) VALUES (?, ?)', {clan, newBalance})
        end
    end)
    
    return true, newBalance
end

-- Check if player has access to clan menu
RegisterServerEvent('ouro_society:server:CheckClanAccess')
AddEventHandler('ouro_society:server:CheckClanAccess', function(clanName)
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local charIdentifier = Character.charIdentifier
    
    -- Check if player has this clan
    MySQL.query('SELECT * FROM ouro_player_clans WHERE charidentifier = ? AND clan = ?', {charIdentifier, clanName}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('vorp:TipRight', _source, "You're not a member of this clan", 3000)
            return
        end
        
        local clanGrade = result[1].grade
        
        -- Player has access, open the menu
        TriggerClientEvent('ouro_society:client:OpenClanMenu', _source, clanName, clanGrade)
    end)
end)

-- Get player clans
RegisterServerEvent('ouro_society:server:GetPlayerClans')
AddEventHandler('ouro_society:server:GetPlayerClans', function()
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local charIdentifier = Character.charIdentifier
    
    MySQL.query('SELECT * FROM ouro_player_clans WHERE charidentifier = ?', {charIdentifier}, function(result)
        TriggerClientEvent('ouro_society:client:ReceiveClans', _source, result or {})
    end)
end)

-- Save current clan (from multijob list or manual add)
RegisterServerEvent('ouro_society:server:SaveClan')
AddEventHandler('ouro_society:server:SaveClan', function(clanName, grade)
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local identifier = Character.identifier
    local charIdentifier = Character.charIdentifier
    
    -- Check if clan exists in config
    if not Config.Clans[clanName] then
        TriggerClientEvent('vorp:TipRight', _source, "Invalid clan", 3000)
        return
    end
    
    -- Check if player already has this clan
    MySQL.query('SELECT * FROM ouro_player_clans WHERE charidentifier = ? AND clan = ?', {charIdentifier, clanName}, function(result)
        if result and #result > 0 then
            -- Clan exists, update the grade
            MySQL.update('UPDATE ouro_player_clans SET grade = ? WHERE charidentifier = ? AND clan = ?', 
            {grade, charIdentifier, clanName}, function(affectedRows)
                if affectedRows > 0 then
                    TriggerClientEvent('vorp:TipRight', _source, "Clan rank updated to " .. grade, 3000)
                    
                    -- Refresh player clans
                    MySQL.query('SELECT * FROM ouro_player_clans WHERE charidentifier = ?', {charIdentifier}, function(result)
                        TriggerClientEvent('ouro_society:client:ReceiveClans', _source, result or {})
                    end)
                end
            end)
            return
        end
        
        -- Check max clans
        MySQL.query('SELECT COUNT(*) as count FROM ouro_player_clans WHERE charidentifier = ?', {charIdentifier}, function(countResult)
            local clanCount = countResult[1].count or 0
            if clanCount >= Config.MaxClanSlots then
                TriggerClientEvent('vorp:TipRight', _source, "You have reached max clan slots (" .. Config.MaxClanSlots .. ")", 3000)
                return
            end
            
            -- Add the clan
            MySQL.insert('INSERT INTO ouro_player_clans (identifier, charidentifier, clan, grade, is_active) VALUES (?, ?, ?, ?, ?)', 
            {identifier, charIdentifier, clanName, grade, 0}, function(insertId)
                if insertId then
                    TriggerClientEvent('vorp:TipRight', _source, "Joined clan: " .. Config.Clans[clanName].Label, 3000)
                    
                    -- Refresh player clans
                    MySQL.query('SELECT * FROM ouro_player_clans WHERE charidentifier = ?', {charIdentifier}, function(result)
                        TriggerClientEvent('ouro_society:client:ReceiveClans', _source, result or {})
                    end)
                end
            end)
        end)
    end)
end)

-- Switch active clan
RegisterServerEvent('ouro_society:server:SwitchClan')
AddEventHandler('ouro_society:server:SwitchClan', function(clanName)
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local charIdentifier = Character.charIdentifier
    
    -- Check if player has this clan
    MySQL.query('SELECT * FROM ouro_player_clans WHERE charidentifier = ? AND clan = ?', {charIdentifier, clanName}, function(result)
        if result and #result > 0 then
            -- Set all clans to inactive
            MySQL.update('UPDATE ouro_player_clans SET is_active = 0 WHERE charidentifier = ?', {charIdentifier}, function()
                -- Set new clan as active
                MySQL.update('UPDATE ouro_player_clans SET is_active = 1 WHERE charidentifier = ? AND clan = ?', {charIdentifier, clanName}, function()
                    local clanLabel = Config.Clans[clanName] and Config.Clans[clanName].Label or clanName
                    TriggerClientEvent('vorp:TipRight', _source, "Switched to " .. clanLabel, 3000)
                end)
            end)
        else
            TriggerClientEvent('vorp:TipRight', _source, "You're not in this clan", 3000)
        end
    end)
end)

-- Remove player from clan
RegisterServerEvent('ouro_society:server:LeaveClan')
AddEventHandler('ouro_society:server:LeaveClan', function(clanName)
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local charIdentifier = Character.charIdentifier
    
    MySQL.execute('DELETE FROM ouro_player_clans WHERE charidentifier = ? AND clan = ?', {charIdentifier, clanName}, function(affectedRows)
        if affectedRows > 0 then
            local clanLabel = Config.Clans[clanName] and Config.Clans[clanName].Label or clanName
            TriggerClientEvent('vorp:TipRight', _source, "Left " .. clanLabel, 3000)
            
            -- Refresh player clans
            MySQL.query('SELECT * FROM ouro_player_clans WHERE charidentifier = ?', {charIdentifier}, function(result)
                TriggerClientEvent('ouro_society:client:ReceiveClans', _source, result or {})
            end)
        end
    end)
end)

-- Deposit to clan ledger
RegisterServerEvent('ouro_society:server:DepositClanLedger')
AddEventHandler('ouro_society:server:DepositClanLedger', function(clan, amount)
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    
    if Character.money >= amount then
        Character.removeCurrency(0, amount)
        
        local success, newBalance = UpdateClanLedger(clan, amount, "add")
        if success then
            TriggerClientEvent('vorp:TipRight', _source, Config.Language.Deposited .. "$" .. amount, 3000)
            TriggerClientEvent('ouro_society:client:UpdateClanLedger', _source, newBalance)
        end
    else
        TriggerClientEvent('vorp:TipRight', _source, Config.Language.NoCash, 3000)
    end
end)

-- Withdraw from clan ledger
RegisterServerEvent('ouro_society:server:WithdrawClanLedger')
AddEventHandler('ouro_society:server:WithdrawClanLedger', function(clan, amount)
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    
    local success, result = UpdateClanLedger(clan, amount, "remove")
    if success then
        Character.addCurrency(0, amount)
        TriggerClientEvent('vorp:TipRight', _source, Config.Language.Withdrew .. "$" .. amount, 3000)
        TriggerClientEvent('ouro_society:client:UpdateClanLedger', _source, result)
    else
        TriggerClientEvent('vorp:TipRight', _source, result, 3000)
    end
end)

-- Get clan ledger balance
RegisterServerEvent('ouro_society:server:GetClanLedger')
AddEventHandler('ouro_society:server:GetClanLedger', function(clan)
    local _source = source
    
    -- Query database directly to ensure we get the latest value
    MySQL.query('SELECT ledger FROM ouro_clan_ledger WHERE clan = ?', {clan}, function(result)
        local balance = 0
        if result and #result > 0 then
            balance = result[1].ledger or 0
            -- Update cache
            ClanLedgers[clan] = balance
        end
        
        TriggerClientEvent('ouro_society:client:UpdateClanLedger', _source, balance)
        print("[Ouro Society] Retrieved clan ledger for " .. clan .. ": $" .. balance)
    end)
end)

-- Open clan storage
RegisterServerEvent('ouro_society:server:OpenClanStorage')
AddEventHandler('ouro_society:server:OpenClanStorage', function(containerID)
    local _source = source
    -- Convert ID to string to match VORP's internal ID handling
    local containerId = tostring(containerID)
    -- Use the proper VORP inventory export to open custom inventory
    exports.vorp_inventory:openInventory(_source, containerId)
end)

-- Get online clan members
RegisterServerEvent('ouro_society:server:GetOnlineClanMembers')
AddEventHandler('ouro_society:server:GetOnlineClanMembers', function(clanName)
    local _source = source
    local members = {}
    
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local User = VORPcore.getUser(tonumber(playerId))
        if User then
            local Character = User.getUsedCharacter
            if Character then
                -- Check if player has this clan
                MySQL.query('SELECT * FROM ouro_player_clans WHERE charidentifier = ? AND clan = ?', 
                {Character.charIdentifier, clanName}, function(result)
                    if result and #result > 0 then
                        table.insert(members, {
                            serverId = tonumber(playerId),
                            name = Character.firstname .. " " .. Character.lastname,
                            clan = clanName,
                            grade = result[1].grade
                        })
                    end
                end)
            end
        end
    end
    
    Wait(500) -- Wait for queries to complete
    TriggerClientEvent('ouro_society:client:ReceiveClanMembers', _source, members)
end)

-- Set clan member grade
RegisterServerEvent('ouro_society:server:SetClanGrade')
AddEventHandler('ouro_society:server:SetClanGrade', function(targetId, clanName, newGrade)
    local _source = source
    local User = VORPcore.getUser(targetId)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local charIdentifier = Character.charIdentifier
    
    MySQL.update('UPDATE ouro_player_clans SET grade = ? WHERE charidentifier = ? AND clan = ?', {newGrade, charIdentifier, clanName}, function(affectedRows)
        if affectedRows > 0 then
            local gradeLabel = "Rank " .. newGrade
            if Config.Clans[clanName] and Config.Clans[clanName].Grades and Config.Clans[clanName].Grades[newGrade] then
                gradeLabel = Config.Clans[clanName].Grades[newGrade].label
            end
            
            TriggerClientEvent('vorp:TipRight', targetId, Config.Language.RankChanged .. gradeLabel, 5000)
            TriggerClientEvent('vorp:TipRight', _source, Config.Language.ChangeRank .. GetPlayerName(targetId) .. Config.Language.ToRank .. gradeLabel, 5000)
        end
    end)
end)

-- Set clan grade salary
RegisterServerEvent('ouro_society:server:SetClanGradeSalary')
AddEventHandler('ouro_society:server:SetClanGradeSalary', function(clan, grade, salary)
    local _source = source
    
    if salary > Config.MaxSalary then
        TriggerClientEvent('vorp:TipRight', _source, Config.Language.MaxSalary .. Config.MaxSalary, 3000)
        return
    end
    
    MySQL.update('UPDATE ouro_clans SET salary = ? WHERE clan = ? AND clangrade = ?', {salary, clan, grade}, function(affectedRows)
        if affectedRows == 0 then
            MySQL.insert('INSERT INTO ouro_clans (clan, clangrade, salary) VALUES (?, ?, ?)', {clan, grade, salary})
        end
        
        TriggerClientEvent('vorp:TipRight', _source, Config.Language.SalaryUpdated .. grade .. Config.Language.To .. salary, 5000)
    end)
end)

-- Remove player from clan
RegisterServerEvent('ouro_society:server:RemoveClanMember')
AddEventHandler('ouro_society:server:RemoveClanMember', function(targetId, clanName)
    local _source = source
    local User = VORPcore.getUser(targetId)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local charIdentifier = Character.charIdentifier
    
    MySQL.execute('DELETE FROM ouro_player_clans WHERE charidentifier = ? AND clan = ?', {charIdentifier, clanName}, function(affectedRows)
        if affectedRows > 0 then
            TriggerClientEvent('vorp:TipRight', targetId, Config.Language.Fired .. Config.Clans[clanName].Label, 5000)
            TriggerClientEvent('vorp:TipRight', _source, Config.Language.YouFired .. GetPlayerName(targetId), 5000)
        end
    end)
end)

-- Admin command to set player clan (called from vorp_admin)
RegisterServerEvent('ouro_society:admin:SetClan')
AddEventHandler('ouro_society:admin:SetClan', function(targetId, clanName, clanGrade, adminName)
    local _source = source
    local User = VORPcore.getUser(targetId)
    if not User then 
        TriggerClientEvent('vorp:TipRight', _source, "Player not found", 3000)
        return 
    end
    
    local Character = User.getUsedCharacter
    local identifier = Character.identifier
    local charIdentifier = Character.charIdentifier
    
    -- Check if clan exists in config
    if not Config.Clans[clanName] then
        TriggerClientEvent('vorp:TipRight', _source, "Clan '" .. clanName .. "' not found in config", 5000)
        return
    end
    
    -- Check if player already has this clan
    MySQL.query('SELECT * FROM ouro_player_clans WHERE charidentifier = ? AND clan = ?', {charIdentifier, clanName}, function(result)
        if result and #result > 0 then
            -- Update existing clan grade
            MySQL.update('UPDATE ouro_player_clans SET grade = ? WHERE charidentifier = ? AND clan = ?', 
            {clanGrade, charIdentifier, clanName}, function(affectedRows)
                if affectedRows > 0 then
                    TriggerClientEvent('vorp:TipRight', targetId, "Clan rank updated: " .. Config.Clans[clanName].Label .. " - Rank " .. clanGrade, 5000)
                    TriggerClientEvent('vorp:TipRight', _source, "Updated " .. Character.firstname .. " " .. Character.lastname .. "'s rank in " .. Config.Clans[clanName].Label, 5000)
                end
            end)
        else
            -- Check max clans
            MySQL.query('SELECT COUNT(*) as count FROM ouro_player_clans WHERE charidentifier = ?', {charIdentifier}, function(countResult)
                local clanCount = countResult[1].count or 0
                if clanCount >= Config.MaxClanSlots then
                    TriggerClientEvent('vorp:TipRight', _source, "Player has reached max clan slots (" .. Config.MaxClanSlots .. ")", 5000)
                    return
                end
                
                -- Add the clan
                MySQL.insert('INSERT INTO ouro_player_clans (identifier, charidentifier, clan, grade, is_active) VALUES (?, ?, ?, ?, ?)', 
                {identifier, charIdentifier, clanName, clanGrade, 0}, function(insertId)
                    if insertId then
                        TriggerClientEvent('vorp:TipRight', targetId, "Added to clan: " .. Config.Clans[clanName].Label .. " - Rank " .. clanGrade, 5000)
                        TriggerClientEvent('vorp:TipRight', _source, "Added " .. Character.firstname .. " " .. Character.lastname .. " to " .. Config.Clans[clanName].Label, 5000)
                        
                        print("[Ouro Society] Admin " .. (adminName or "Unknown") .. " added player " .. Character.firstname .. " " .. Character.lastname .. " to clan " .. clanName .. " with rank " .. clanGrade)
                    end
                end)
            end)
        end
    end)
end)

-- Exports
exports('GetClanLedger', GetClanLedger)
exports('UpdateClanLedger', UpdateClanLedger)
