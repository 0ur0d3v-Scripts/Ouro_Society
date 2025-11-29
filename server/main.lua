local VORPcore = exports.vorp_core:GetCore()
local VORPInv = exports.vorp_inventory:vorp_inventoryApi()

-- Cache
local PlayerJobs = {}
local PlayerSubJobs = {}
local OnDutyPlayers = {}
local AlertCooldowns = {}
local SocietyLedgers = {}

-- Initialize on resource start
CreateThread(function()
    Wait(2000)
    LoadAllLedgers()
    RegisterInventoryContainers()
end)

-- Register all job containers with VORP Inventory
function RegisterInventoryContainers()
    for jobName, jobData in pairs(Config.Jobs) do
        if jobData.ContainerID and jobData.ContainerName then
            -- Convert ID to string to match VORP's internal ID handling
            local containerId = tostring(jobData.ContainerID)
            
            -- Register with VORP Inventory using the correct API
            exports.vorp_inventory:registerInventory({
                id = containerId,
                name = jobData.ContainerName,
                limit = jobData.ContainerSlots or 50,
                acceptWeapons = true,
                shared = true,
                ignoreItemStackLimit = true,
                whitelistItems = false,
                UsePermissions = false,
                UseBlackList = false,  -- Disabled blacklist so all items are allowed
                whiteList = {},
                blackList = {}
            })
            print("[Ouro Society] Registered inventory: " .. jobData.ContainerName .. " (ID: " .. containerId .. ")")
        end
    end
    print("[Ouro Society] Registered " .. TableLength(Config.Jobs) .. " job inventory containers")
end

-- Open job storage
RegisterServerEvent('ouro_society:server:OpenJobStorage')
AddEventHandler('ouro_society:server:OpenJobStorage', function(containerID)
    local _source = source
    -- Convert ID to string to match VORP's internal ID handling
    local containerId = tostring(containerID)
    -- Use the proper VORP inventory export to open custom inventory
    exports.vorp_inventory:openInventory(_source, containerId)
end)

function TableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

-- Load all society ledgers into cache
function LoadAllLedgers()
    MySQL.query('SELECT * FROM ouro_society_ledger', {}, function(result)
        if result then
            for _, ledger in ipairs(result) do
                SocietyLedgers[ledger.job] = ledger.ledger or 0
            end
            print("[Ouro Society] Loaded " .. #result .. " society ledgers")
        end
    end)
end

-- Get society ledger balance
function GetSocietyLedger(job)
    return SocietyLedgers[job] or 0
end

-- Update society ledger
function UpdateSocietyLedger(job, amount, operation)
    local currentBalance = GetSocietyLedger(job)
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
    
    SocietyLedgers[job] = newBalance
    
    MySQL.update('UPDATE ouro_society_ledger SET ledger = ? WHERE job = ?', {newBalance, job}, function(affectedRows)
        if affectedRows == 0 then
            MySQL.insert('INSERT INTO ouro_society_ledger (job, ledger) VALUES (?, ?)', {job, newBalance})
        end
    end)
    
    return true, newBalance
end

-- Check if player has access to job menu (checks VORP character table)
RegisterServerEvent('ouro_society:server:CheckJobAccess')
AddEventHandler('ouro_society:server:CheckJobAccess', function(jobName)
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local currentJob = Character.job
    local currentJobGrade = Character.jobGrade
    
    -- Check if player's current VORP job matches the requested job
    if currentJob ~= jobName then
        TriggerClientEvent('vorp:TipRight', _source, "You don't work here", 3000)
        return
    end
    
    -- Player has access, open the menu
    TriggerClientEvent('ouro_society:client:OpenJobMenu', _source, jobName, currentJobGrade)
end)

-- Get player jobs
RegisterServerEvent('ouro_society:server:GetPlayerJobs')
AddEventHandler('ouro_society:server:GetPlayerJobs', function()
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local identifier = Character.identifier
    local charIdentifier = Character.charIdentifier
    
    MySQL.query('SELECT * FROM ouro_player_jobs WHERE charidentifier = ?', {charIdentifier}, function(result)
        PlayerJobs[_source] = result or {}
        TriggerClientEvent('ouro_society:client:ReceiveJobs', _source, result or {})
    end)
end)

-- Add job to player
RegisterServerEvent('ouro_society:server:AddJob')
AddEventHandler('ouro_society:server:AddJob', function(targetId, job, grade)
    local _source = source
    local User = VORPcore.getUser(targetId)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local identifier = Character.identifier
    local charIdentifier = Character.charIdentifier
    
    -- Check if player already has this job
    MySQL.query('SELECT * FROM ouro_player_jobs WHERE charidentifier = ? AND job = ?', {charIdentifier, job}, function(result)
        if result and #result > 0 then
            TriggerClientEvent('vorp:TipRight', _source, "Player already has this job", 3000)
            return
        end
        
        -- Check max jobs
        MySQL.query('SELECT COUNT(*) as count FROM ouro_player_jobs WHERE charidentifier = ?', {charIdentifier}, function(countResult)
            local jobCount = countResult[1].count or 0
            if jobCount >= Config.MaxJobSlots then
                TriggerClientEvent('vorp:TipRight', _source, "Player has reached max job slots", 3000)
                return
            end
            
            -- Add the job
            MySQL.insert('INSERT INTO ouro_player_jobs (identifier, charidentifier, job, grade, is_active) VALUES (?, ?, ?, ?, ?)', 
            {identifier, charIdentifier, job, grade or 0, 0}, function(insertId)
                if insertId then
                    -- Update VORP core job if this is the first job
                    if jobCount == 0 then
                        Character.setJob(job)
                        Character.setJobGrade(grade or 0)
                        MySQL.update('UPDATE ouro_player_jobs SET is_active = 1 WHERE id = ?', {insertId})
                    end
                    
                    TriggerClientEvent('vorp:TipRight', targetId, Config.Language.Hired .. (Config.Jobs[job] and Config.Jobs[job].Label or job), 5000)
                    TriggerClientEvent('vorp:TipRight', _source, Config.Language.YouHired .. GetPlayerName(targetId), 5000)
                end
            end)
        end)
    end)
end)

-- Remove job from player
RegisterServerEvent('ouro_society:server:RemoveJob')
AddEventHandler('ouro_society:server:RemoveJob', function(targetId, job)
    local _source = source
    local User = VORPcore.getUser(targetId)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local charIdentifier = Character.charIdentifier
    
    MySQL.execute('DELETE FROM ouro_player_jobs WHERE charidentifier = ? AND job = ?', {charIdentifier, job}, function(affectedRows)
        if affectedRows > 0 then
            -- Check if this was the active job
            if Character.job == job then
                -- Set to unemployed or switch to another job
                MySQL.query('SELECT * FROM ouro_player_jobs WHERE charidentifier = ? AND is_active = 0 LIMIT 1', {charIdentifier}, function(result)
                    if result and #result > 0 then
                        local newJob = result[1].job
                        local newGrade = result[1].grade
                        Character.setJob(newJob)
                        Character.setJobGrade(newGrade)
                        MySQL.update('UPDATE ouro_player_jobs SET is_active = 1 WHERE id = ?', {result[1].id})
                    else
                        Character.setJob(Config.UnemployedJobName)
                        Character.setJobGrade(0)
                    end
                end)
            end
            
            -- Remove subjobs
            MySQL.execute('DELETE FROM ouro_player_subjobs WHERE charidentifier = ? AND main_job = ?', {charIdentifier, job})
            
            TriggerClientEvent('vorp:TipRight', targetId, Config.Language.Fired .. (Config.Jobs[job] and Config.Jobs[job].Label or job), 5000)
            TriggerClientEvent('vorp:TipRight', _source, Config.Language.YouFired .. GetPlayerName(targetId), 5000)
            
        end
    end)
end)

-- Set player job grade
RegisterServerEvent('ouro_society:server:SetGrade')
AddEventHandler('ouro_society:server:SetGrade', function(targetId, job, newGrade)
    local _source = source
    local User = VORPcore.getUser(targetId)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local charIdentifier = Character.charIdentifier
    
    MySQL.update('UPDATE ouro_player_jobs SET grade = ? WHERE charidentifier = ? AND job = ?', {newGrade, charIdentifier, job}, function(affectedRows)
        if affectedRows > 0 then
            -- Update VORP core if this is the active job
            if Character.job == job then
                Character.setJobGrade(newGrade)
            end
            
            local gradeLabel = "Rank " .. newGrade
            if Config.Jobs[job] and Config.Jobs[job].Grades and Config.Jobs[job].Grades[newGrade] then
                gradeLabel = Config.Jobs[job].Grades[newGrade].label
            end
            
            TriggerClientEvent('vorp:TipRight', targetId, Config.Language.RankChanged .. gradeLabel, 5000)
            TriggerClientEvent('vorp:TipRight', _source, Config.Language.ChangeRank .. GetPlayerName(targetId) .. Config.Language.ToRank .. gradeLabel, 5000)
            
            TriggerClientEvent('vorp:TipRight', _source, Config.Language.ChangeRank .. GetPlayerName(targetId) .. Config.Language.ToRank .. gradeLabel, 5000)
            
        end
    end)
end)

-- Set grade salaryro_society:server:SetGradeSalary', function(job, grade, salary)
    local _source = source
    
    if salary > Config.MaxSalary then
        TriggerClientEvent('vorp:TipRight', _source, Config.Language.MaxSalary .. Config.MaxSalary, 3000)
        return
    end
    
    MySQL.update('UPDATE ouro_society SET salary = ? WHERE job = ? AND jobgrade = ?', {salary, job, grade}, function(affectedRows)
        if affectedRows == 0 then
            MySQL.insert('INSERT INTO ouro_society (job, jobgrade, salary) VALUES (?, ?, ?)', {job, grade, salary})
        end
        
        TriggerClientEvent('vorp:TipRight', _source, Config.Language.SalaryUpdated .. grade .. Config.Language.To .. salary, 5000)
        
        -- Log
        SendWebhookLog(job, "Salary Updated", GetPlayerName(_source) .. " set grade " .. grade .. " salary to $" .. salary)
        TriggerClientEvent('vorp:TipRight', _source, Config.Language.SalaryUpdated .. grade .. Config.Language.To .. salary, 5000)
        
    end)
end)

-- Switch active jobPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local charIdentifier = Character.charIdentifier
    
    -- Check if player has this job
    MySQL.query('SELECT * FROM ouro_player_jobs WHERE charidentifier = ? AND job = ?', {charIdentifier, job}, function(result)
        if result and #result > 0 then
            local jobData = result[1]
            
            -- Set all jobs to inactive
            MySQL.update('UPDATE ouro_player_jobs SET is_active = 0 WHERE charidentifier = ?', {charIdentifier}, function()
                -- Set new job as active
                MySQL.update('UPDATE ouro_player_jobs SET is_active = 1 WHERE id = ?', {jobData.id}, function()
                    Character.setJob(job)
                    Character.setJobGrade(jobData.grade)
                    
                    local jobLabel = Config.Jobs[job] and Config.Jobs[job].Label or job
                    TriggerClientEvent('vorp:TipRight', _source, "Switched to " .. jobLabel, 3000)
                end)
            end)
        else
            TriggerClientEvent('vorp:TipRight', _source, "You don't have this job", 3000)
        end
    end)
end)

-- Deposit to society ledger
RegisterServerEvent('ouro_society:server:DepositLedger')
AddEventHandler('ouro_society:server:DepositLedger', function(job, amount)
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    
    if Character.money >= amount then
        Character.removeCurrency(0, amount)
        
        local success, newBalance = UpdateSocietyLedger(job, amount, "add")
        if success then
            TriggerClientEvent('vorp:TipRight', _source, Config.Language.Deposited .. "$" .. amount, 3000)
            TriggerClientEvent('ouro_society:client:UpdateLedger', _source, newBalance)
            
            -- Log
            SendWebhookLog(job, "Ledger Deposit", GetPlayerName(_source) .. " deposited $" .. amount)
        end
    else
            TriggerClientEvent('ouro_society:client:UpdateLedger', _source, newBalance)
            
        end
    else
        TriggerClientEvent('vorp:TipRight', _source, Config.Language.NoCash, 3000)
    end
end)local User = VORPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    
    local success, result = UpdateSocietyLedger(job, amount, "remove")
    if success then
        Character.addCurrency(0, amount)
        TriggerClientEvent('vorp:TipRight', _source, Config.Language.Withdrew .. "$" .. amount, 3000)
        TriggerClientEvent('ouro_society:client:UpdateLedger', _source, result)
        
        -- Log
        SendWebhookLog(job, "Ledger Withdrawal", GetPlayerName(_source) .. " withdrew $" .. amount)
    else
        TriggerClientEvent('vorp:TipRight', _source, result, 3000)
        TriggerClientEvent('ouro_society:client:UpdateLedger', _source, result)
        
    else
        TriggerClientEvent('vorp:TipRight', _source, result, 3000)
    end
end)
    -- Query database directly to ensure we get the latest value
    MySQL.query('SELECT ledger FROM ouro_society_ledger WHERE job = ?', {job}, function(result)
        local balance = 0
        if result and #result > 0 then
            balance = result[1].ledger or 0
            -- Update cache
            SocietyLedgers[job] = balance
        end
        
        TriggerClientEvent('ouro_society:client:UpdateLedger', _source, balance)
        print("[Ouro Society] Retrieved ledger for " .. job .. ": $" .. balance)
    end)
end)

-- Billing system
RegisterServerEvent('ouro_society:server:CreateBill')
AddEventHandler('ouro_society:server:CreateBill', function(targetId, amount, job)
    local _source = source
    local User = VORPcore.getUser(targetId)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local IssuerUser = VORPcore.getUser(_source)
    local IssuerCharacter = IssuerUser.getUsedCharacter
    
    MySQL.insert('INSERT INTO ouro_bills (job, playername, identifier, charidentifier, issuer, amount) VALUES (?, ?, ?, ?, ?, ?)',
    {job, Character.firstname .. " " .. Character.lastname, Character.identifier, Character.charIdentifier, IssuerCharacter.firstname .. " " .. IssuerCharacter.lastname, amount},
    function(insertId)
        if insertId then
            TriggerClientEvent('vorp:TipRight', _source, Config.Language.FineSent .. "$" .. amount, 3000)
            TriggerClientEvent('vorp:TipRight', targetId, Config.Language.FineReceive .. "$" .. amount, 5000)
            
            -- Log
            SendWebhookLog(job, "Bill Created", GetPlayerName(_source) .. " billed " .. GetPlayerName(targetId) .. " for $" .. amount)
        end
    end)
end)

            TriggerClientEvent('vorp:TipRight', targetId, Config.Language.FineReceive .. "$" .. amount, 5000)
            
        end
    end)
end)

-- Pay bill
    MySQL.query('SELECT * FROM ouro_bills WHERE id = ?', {billId}, function(result)
        if result and #result > 0 then
            local bill = result[1]
            
            if Character.money >= bill.amount then
                Character.removeCurrency(0, bill.amount)
                
                -- Add to society ledger if auto-collect
                if Config.AutoCollect and bill.job then
                    for _, autoJob in ipairs(Config.AutoCollectJobs) do
                        if autoJob == bill.job then
                            UpdateSocietyLedger(bill.job, bill.amount, "add")
                            break
                        end
                    end
                end
                
                MySQL.execute('DELETE FROM ouro_bills WHERE id = ?', {billId})
                
                TriggerClientEvent('vorp:TipRight', _source, Config.Language.BillPaid .. "$" .. bill.amount, 3000)
                
                -- Log
                SendWebhookLog(bill.job, "Bill Paid", Character.firstname .. " " .. Character.lastname .. " paid bill of $" .. bill.amount)
            else
                TriggerClientEvent('vorp:TipRight', _source, Config.Language.NoCash, 3000)
            end
        end
    end)
end)
                TriggerClientEvent('vorp:TipRight', _source, Config.Language.BillPaid .. "$" .. bill.amount, 3000)
                
            else
                TriggerClientEvent('vorp:TipRight', _source, Config.Language.NoCash, 3000)
            end
        end
    end)l Character = User.getUsedCharacter
    
    MySQL.query('SELECT * FROM ouro_bills WHERE charidentifier = ?', {Character.charIdentifier}, function(result)
        TriggerClientEvent('ouro_society:client:ReceiveBills', _source, result or {})
    end)
end)

-- Salary payment thread
if Config.SalaryTime > 0 then
    CreateThread(function()
        while true do
            Wait(Config.SalaryTime * 60 * 1000)
            
            local players = GetPlayers()
            for _, playerId in ipairs(players) do
                local User = VORPcore.getUser(tonumber(playerId))
                if User then
                    local Character = User.getUsedCharacter
                    if Character then
                        local job = Character.job
                        local grade = Character.jobGrade
                        
                        -- Check if job requires duty and player is on duty
                        local requiresDuty = false
                        for _, dutyJob in ipairs(Config.DutyJobs) do
                            if dutyJob == job then
                                requiresDuty = true
                                break
                            end
                        end
                        
                        local canPaySalary = true
                        if requiresDuty and Config.NoSalaryOffDuty then
                            if not OnDutyPlayers[tonumber(playerId)] or not OnDutyPlayers[tonumber(playerId)][job] then
                                canPaySalary = false
                            end
                        end
                        
                        if canPaySalary and job ~= Config.UnemployedJobName then
                            -- Get salary amount
                            MySQL.query('SELECT salary FROM ouro_society WHERE job = ? AND jobgrade = ?', {job, grade}, function(result)
                                if result and #result > 0 then
                                    local salary = result[1].salary
                                    if salary > 0 then
                                        -- Check if society can afford it
                                        if Config.Jobs[job] and Config.Jobs[job].AllowSalary then
                                            local ledgerBalance = GetSocietyLedger(job)
                                            if ledgerBalance >= salary then
                                                UpdateSocietyLedger(job, salary, "remove")
                                                Character.addCurrency(0, salary)
                                                TriggerClientEvent('vorp:TipRight', tonumber(playerId), Config.Language.Salary .. "$" .. salary, 5000)
                                            else
                                                -- Notify boss that ledger is empty
                                                TriggerClientEvent('vorp:TipRight', tonumber(playerId), Config.Language.NoLedgerCash, 5000)
                                            end
                                        else
                                            Character.addCurrency(0, salary)
                                            TriggerClientEvent('vorp:TipRight', tonumber(playerId), Config.Language.Salary .. "$" .. salary, 5000)
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end
    end)
end

-- Duty system
RegisterServerEvent('ouro_society:server:ToggleDuty')
AddEventHandler('ouro_society:server:ToggleDuty', function(job)
    local _source = source
    
    if not OnDutyPlayers[_source] then
        OnDutyPlayers[_source] = {}
    end
    
    if OnDutyPlayers[_source][job] then
        OnDutyPlayers[_source][job] = nil
        TriggerClientEvent('vorp:TipRight', _source, Config.Language.YouOffDuty, 3000)
        SendWebhookLog(job, "Off Duty", GetPlayerName(_source) .. " went off duty")
    else
        OnDutyPlayers[_source][job] = true
        TriggerClientEvent('vorp:TipRight', _source, Config.Language.YouOnDuty, 3000)
        SendWebhookLog(job, "On Duty", GetPlayerName(_source) .. " went on duty")
    end
end)

-- Get online employees
RegisterServerEvent('ouro_society:server:GetOnlineEmployees')
AddEventHandler('ouro_society:server:GetOnlineEmployees', function(job)
        TriggerClientEvent('vorp:TipRight', _source, Config.Language.YouOffDuty, 3000)
    else
        OnDutyPlayers[_source][job] = true
        TriggerClientEvent('vorp:TipRight', _source, Config.Language.YouOnDuty, 3000)
    end
end)        local Character = User.getUsedCharacter
            if Character then
                -- Check if player has this job
                MySQL.query('SELECT * FROM ouro_player_jobs WHERE charidentifier = ? AND job = ?', 
                {Character.charIdentifier, job}, function(result)
                    if result and #result > 0 then
                        table.insert(employees, {
                            serverId = tonumber(playerId),
                            name = Character.firstname .. " " .. Character.lastname,
                            job = job,
                            grade = result[1].grade
                        })
                    end
                end)
            end
        end
    end
    
    Wait(500) -- Wait for queries to complete
    TriggerClientEvent('ouro_society:client:ReceiveEmployees', _source, employees)
end)

-- Save current VORP job to multijob list
RegisterServerEvent('ouro_society:server:SaveCurrentJob')
AddEventHandler('ouro_society:server:SaveCurrentJob', function()
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local identifier = Character.identifier
    local charIdentifier = Character.charIdentifier
    local currentJob = Character.job
    local currentGrade = Character.jobGrade
    
    if currentJob == Config.UnemployedJobName then
        TriggerClientEvent('vorp:TipRight', _source, "You don't have a job to save", 3000)
        return
    end
    
    -- Check if player already has this job in multijob list
    MySQL.query('SELECT * FROM ouro_player_jobs WHERE charidentifier = ? AND job = ?', {charIdentifier, currentJob}, function(result)
        if result and #result > 0 then
            -- Job exists, update the grade instead
            MySQL.update('UPDATE ouro_player_jobs SET grade = ?, is_active = 1 WHERE charidentifier = ? AND job = ?', 
            {currentGrade, charIdentifier, currentJob}, function(affectedRows)
                if affectedRows > 0 then
                    -- Set all other jobs to inactive
                    MySQL.update('UPDATE ouro_player_jobs SET is_active = 0 WHERE charidentifier = ? AND job != ?', {charIdentifier, currentJob})
                    
                    TriggerClientEvent('vorp:TipRight', _source, "Job updated to grade " .. currentGrade, 3000)
                    
                    -- Refresh player jobs
                    MySQL.query('SELECT * FROM ouro_player_jobs WHERE charidentifier = ?', {charIdentifier}, function(result)
                        TriggerClientEvent('ouro_society:client:ReceiveJobs', _source, result or {})
                    end)
                end
            end)
            return
        end
        
        -- Check max jobs
        MySQL.query('SELECT COUNT(*) as count FROM ouro_player_jobs WHERE charidentifier = ?', {charIdentifier}, function(countResult)
            local jobCount = countResult[1].count or 0
            if jobCount >= Config.MaxJobSlots then
                TriggerClientEvent('vorp:TipRight', _source, "You have reached max job slots (" .. Config.MaxJobSlots .. ")", 3000)
                return
            end
            
            -- Add the job with active status
            MySQL.insert('INSERT INTO ouro_player_jobs (identifier, charidentifier, job, grade, is_active) VALUES (?, ?, ?, ?, ?)', 
            {identifier, charIdentifier, currentJob, currentGrade, 1}, function(insertId)
                if insertId then
                    -- Set all other jobs to inactive
                    MySQL.update('UPDATE ouro_player_jobs SET is_active = 0 WHERE charidentifier = ? AND id != ?', {charIdentifier, insertId})
                    
                    TriggerClientEvent('vorp:TipRight', _source, "Current job saved to your job list!", 3000)
                    
                    -- Refresh player jobs
                    MySQL.query('SELECT * FROM ouro_player_jobs WHERE charidentifier = ?', {charIdentifier}, function(result)
                        TriggerClientEvent('ouro_society:client:ReceiveJobs', _source, result or {})
                    end)
                end
            end)
        end)
    end)
end)

-- Refresh player job (sync with VORP character data)
RegisterServerEvent('ouro_society:server:RefreshJob')
AddEventHandler('ouro_society:server:RefreshJob', function()
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local charIdentifier = Character.charIdentifier
    local currentJob = Character.job
    local currentGrade = Character.jobGrade
    
    -- Update the active job in database to match VORP
    MySQL.query('SELECT * FROM ouro_player_jobs WHERE charidentifier = ? AND job = ?', {charIdentifier, currentJob}, function(result)
        if result and #result > 0 then
            -- Update grade and set as active
            MySQL.update('UPDATE ouro_player_jobs SET is_active = 0 WHERE charidentifier = ?', {charIdentifier}, function()
                MySQL.update('UPDATE ouro_player_jobs SET grade = ?, is_active = 1 WHERE charidentifier = ? AND job = ?', 
                {currentGrade, charIdentifier, currentJob}, function()
                    TriggerClientEvent('vorp:TipRight', _source, "Job refreshed!", 3000)
                    
                    -- Refresh player jobs
                    MySQL.query('SELECT * FROM ouro_player_jobs WHERE charidentifier = ?', {charIdentifier}, function(result)
                        TriggerClientEvent('ouro_society:client:ReceiveJobs', _source, result or {})
                    end)
                end)
            end)
        else
            TriggerClientEvent('vorp:TipRight', _source, "Current job not found in multijob list. Use 'Save Current Job' first.", 3000)
        end
    end)
end)

-- Exports
exports('GetSocietyLedger', GetSocietyLedger)
exports('UpdateSocietyLedger', UpdateSocietyLedger)
exports('IsPlayerOnDuty', function(source, job)
    return OnDutyPlayers[source] and OnDutyPlayers[source][job] or false
end)

