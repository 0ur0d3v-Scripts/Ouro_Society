local VORPcore = exports.vorp_core:GetCore()

-- Variables
local PlayerData = {}
local PlayerJobs = {}
local CurrentJob = nil
local CurrentJobGrade = 0
local InJobMenuZone = false
local InJobCenterZone = false
local CurrentMenu = nil
local OnDuty = {}
local CurrentLedgerBalance = 0

-- Clan Variables
local PlayerClans = {}
local CurrentClan = nil
local CurrentClanGrade = 0
local InClanMenuZone = false
local CurrentClanLedgerBalance = 0

-- Initialize
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('ouro_society:server:GetPlayerJobs')
    TriggerServerEvent('ouro_society:server:GetPlayerClans')
end)

-- Get player jobs
RegisterNetEvent('ouro_society:client:ReceiveJobs')
AddEventHandler('ouro_society:client:ReceiveJobs', function(jobs)
    PlayerJobs = jobs
end)

-- Receive employees list
RegisterNetEvent('ouro_society:client:ReceiveEmployees')
AddEventHandler('ouro_society:client:ReceiveEmployees', function(employees)
    -- Open employee management menu
    OpenEmployeeMenu(employees)
end)

-- Update ledger balance
RegisterNetEvent('ouro_society:client:UpdateLedger')
AddEventHandler('ouro_society:client:UpdateLedger', function(balance)
    CurrentLedgerBalance = balance
end)

-- Receive bills
RegisterNetEvent('ouro_society:client:ReceiveBills')
AddEventHandler('ouro_society:client:ReceiveBills', function(bills)
    -- Open bills menu
    OpenBillsMenu(bills)
end)

-- Main thread for job zones
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Check job menu zones
        for jobName, jobData in pairs(Config.Jobs) do
            if jobData.JobMenu then
                for _, menuPos in ipairs(jobData.JobMenu) do
                    local distance = #(playerCoords - vector3(menuPos.x, menuPos.y, menuPos.z))
                    
                    if distance < 2.0 then
                        sleep = 0
                        InJobMenuZone = true
                        
                        -- Draw text
                        if Config.NormalDrawText then
                            local label = Config.Language.DrawTextJobMenu
                            DrawTxt(label, 0.50, 0.95, 0.4, 0.4, true, 255, 255, 255, 255, true)
                        end
                        
                        -- Check for key press
                        if IsControlJustReleased(0, Config.OpenMenuKey) then
                            OpenJobMenu(jobName)
                        end
                        break
                    end
                end
            end
        end
        
        -- Check job center zones
        for _, centerData in pairs(Config.JobCenters) do
            local distance = #(playerCoords - vector3(centerData.Pos.x, centerData.Pos.y, centerData.Pos.z))
            
            if distance < 2.0 then
                sleep = 0
                InJobCenterZone = true
                
                -- Draw text
                if Config.NormalDrawText then
                    local label = Config.Language.DrawTextJobCenter
                    DrawTxt(label, 0.50, 0.95, 0.4, 0.4, true, 255, 255, 255, 255, true)
                end
                
                -- Check for key press
                if IsControlJustReleased(0, Config.OpenMenuKey) then
                    OpenJobCenter()
                end
                break
            end
        end
        
        Wait(sleep)
    end
end)

-- Open job menu
function OpenJobMenu(jobName)
    local jobData = Config.Jobs[jobName]
    if not jobData then return end
    
    -- Request server to check if player has this job (checks VORP character table)
    TriggerServerEvent('ouro_society:server:CheckJobAccess', jobName)
end

-- Callback from server with job access result
RegisterNetEvent('ouro_society:client:OpenJobMenu')
AddEventHandler('ouro_society:client:OpenJobMenu', function(jobName, jobGrade)
    local jobData = Config.Jobs[jobName]
    if not jobData then return end
    
    WarMenu.OpenMenu('job_main')
    CurrentJob = jobName
    CurrentJobGrade = jobGrade
    
    CreateThread(function()
        while WarMenu.IsMenuOpened('job_main') do
            WarMenu.MenuButton(Config.Language.ManageEmployees, 'manage_employees', function()
                if jobGrade >= jobData.BossRank then
                    TriggerServerEvent('ouro_society:server:GetOnlineEmployees', jobName)
                else
                    TriggerEvent('vorp:TipRight', Config.Language.NoPermission, 3000)
                end
            end)
            
            WarMenu.MenuButton(Config.Language.Ledger, 'ledger_menu', function()
                if jobGrade >= jobData.BossRank then
                    OpenLedgerMenu(jobName)
                else
                    TriggerEvent('vorp:TipRight', Config.Language.NoPermission, 3000)
                end
            end)
            
            WarMenu.MenuButton(Config.Language.Inventory, 'storage_menu', function()
                OpenJobStorage(jobName, jobData.ContainerID, jobData.ContainerName)
            end)
            
            if jobData.AllowBilling then
                WarMenu.MenuButton(Config.Language.ViewBills, 'view_bills', function()
                    TriggerServerEvent('ouro_society:server:GetBills')
                end)
            end
            
            -- Duty toggle for duty jobs
            for _, dutyJob in ipairs(Config.DutyJobs) do
                if dutyJob == jobName then
                    local dutyText = OnDuty[jobName] and Config.Language.OffDuty or Config.Language.OnDuty
                    WarMenu.MenuButton(dutyText, 'toggle_duty', function()
                        TriggerServerEvent('ouro_society:server:ToggleDuty', jobName)
                        OnDuty[jobName] = not OnDuty[jobName]
                    end)
                    break
                end
            end
            
            WarMenu.Display()
            Wait(0)
        end
    end)
end)

-- Open employee management menu
function OpenEmployeeMenu(employees)
    WarMenu.OpenMenu('manage_employees')
    
    CreateThread(function()
        while WarMenu.IsMenuOpened('manage_employees') do
            for _, employee in ipairs(employees) do
                local gradeLabel = "Grade " .. employee.grade
                if Config.Jobs[employee.job] and Config.Jobs[employee.job].Grades and Config.Jobs[employee.job].Grades[employee.grade] then
                    gradeLabel = Config.Jobs[employee.job].Grades[employee.grade].label
                end
                
                WarMenu.MenuButton(employee.name .. " - " .. gradeLabel, 'employee_' .. employee.serverId, function()
                    OpenEmployeeActions(employee)
                end)
            end
            
            if #employees == 0 then
                WarMenu.MenuButton("No employees online", '', function() end)
            end
            
            WarMenu.Display()
            Wait(0)
        end
    end)
end

-- Open employee actions menu
function OpenEmployeeActions(employee)
    WarMenu.OpenMenu('employee_actions')
    
    CreateThread(function()
        while WarMenu.IsMenuOpened('employee_actions') do
            WarMenu.MenuButton(Config.Language.Fire, 'fire_employee', function()
                TriggerServerEvent('ouro_society:server:RemoveJob', employee.serverId, employee.job)
                WarMenu.CloseMenu()
            end)
            
            WarMenu.MenuButton(Config.Language.SetRank, 'set_rank', function()
                -- Open rank selection menu
                OpenRankSelectionMenu(employee)
            end)
            
            WarMenu.Display()
            Wait(0)
        end
    end)
end

-- Open rank selection menu
function OpenRankSelectionMenu(employee)
    WarMenu.OpenMenu('rank_selection')
    
    local jobData = Config.Jobs[employee.job]
    if not jobData or not jobData.Grades then return end
    
    CreateThread(function()
        while WarMenu.IsMenuOpened('rank_selection') do
            for grade, gradeData in pairs(jobData.Grades) do
                WarMenu.MenuButton(gradeData.label, 'select_rank_' .. grade, function()
                    TriggerServerEvent('ouro_society:server:SetGrade', employee.serverId, employee.job, grade)
                    WarMenu.CloseMenu()
                end)
            end
            
            WarMenu.Display()
            Wait(0)
        end
    end)
end

-- Open job storage
function OpenJobStorage(jobName, containerID, containerName)
    -- Close the menu first
    WarMenu.CloseMenu()
    -- Use proper server event to open inventory
    TriggerServerEvent("ouro_society:server:OpenJobStorage", containerID)
end

-- Open ledger menu
function OpenLedgerMenu(jobName)
    -- First get the current balance
    TriggerServerEvent('ouro_society:server:GetLedger', jobName)
    Wait(200)
    
    WarMenu.OpenMenu('ledger_menu')
    
    CreateThread(function()
        while WarMenu.IsMenuOpened('ledger_menu') do
            -- Display current balance
            WarMenu.Button("Balance: $" .. CurrentLedgerBalance)
            WarMenu.Button("---")
            
            if WarMenu.Button("Deposit Money") then
                WarMenu.CloseMenu()
                
                -- Use native text entry
                DisplayPrompt("Enter amount to deposit", function(amount)
                    if amount and amount ~= "" then
                        local depositAmount = tonumber(amount)
                        if depositAmount and depositAmount > 0 then
                            TriggerServerEvent('ouro_society:server:DepositLedger', jobName, depositAmount)
                            Wait(500)
                            TriggerServerEvent('ouro_society:server:GetLedger', jobName)
                            Wait(200)
                        else
                            TriggerEvent('vorp:TipRight', Config.Language.InvalidAmount, 3000)
                        end
                    end
                    Wait(100)
                    OpenLedgerMenu(jobName)
                end)
            end
            
            if WarMenu.Button("Withdraw Money") then
                WarMenu.CloseMenu()
                
                -- Use native text entry
                DisplayPrompt("Enter amount to withdraw", function(amount)
                    if amount and amount ~= "" then
                        local withdrawAmount = tonumber(amount)
                        if withdrawAmount and withdrawAmount > 0 then
                            TriggerServerEvent('ouro_society:server:WithdrawLedger', jobName, withdrawAmount)
                            Wait(500)
                            TriggerServerEvent('ouro_society:server:GetLedger', jobName)
                            Wait(200)
                        else
                            TriggerEvent('vorp:TipRight', Config.Language.InvalidAmount, 3000)
                        end
                    end
                    Wait(100)
                    OpenLedgerMenu(jobName)
                end)
            end
            
            WarMenu.Display()
            Wait(0)
        end
    end)
end

-- Simple text input prompt function
function DisplayPrompt(text, callback)
    AddTextEntry('FMMC_MPM_NA', text)
    DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 64)
    
    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end
    
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        callback(result)
    else
        callback(nil)
    end
end

-- Open bills menu
function OpenBillsMenu(bills)
    WarMenu.OpenMenu('bills_menu')
    
    CreateThread(function()
        while WarMenu.IsMenuOpened('bills_menu') do
            for _, bill in ipairs(bills) do
                local billText = "$" .. bill.amount .. " - " .. bill.job .. " (" .. bill.issuer .. ")"
                WarMenu.MenuButton(billText, 'bill_' .. bill.id, function()
                    TriggerServerEvent('ouro_society:server:PayBill', bill.id)
                end)
            end
            
            if #bills == 0 then
                WarMenu.MenuButton("No bills", '', function() end)
            end
            
            WarMenu.Display()
            Wait(0)
        end
    end)
end

-- Open job center
function OpenJobCenter()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openJobCenter",
        jobs = Config.AllowedJobCenterJobs
    })
end

-- Open job management menu
function OpenJobManagementMenu()
    -- Refresh job list first
    TriggerServerEvent('ouro_society:server:GetPlayerJobs')
    Wait(100)
    
    WarMenu.OpenMenu('job_management')
    
    CreateThread(function()
        while WarMenu.IsMenuOpened('job_management') do
            -- Save Current Job button
            if WarMenu.Button("Save Current Job") then
                TriggerServerEvent('ouro_society:server:SaveCurrentJob')
                Wait(500)
                TriggerServerEvent('ouro_society:server:GetPlayerJobs')
            end
            
            -- Refresh Jobs button
            if WarMenu.Button("Refresh Jobs") then
                TriggerServerEvent('ouro_society:server:RefreshJob')
                Wait(500)
                TriggerServerEvent('ouro_society:server:GetPlayerJobs')
            end
            
            -- Spacer
            WarMenu.Button("=== Your Jobs ===")
            
            -- Show current jobs
            if PlayerJobs and #PlayerJobs > 0 then
                for _, job in ipairs(PlayerJobs) do
                    local jobLabel = Config.Jobs[job.job] and Config.Jobs[job.job].Label or job.job
                    local gradeLabel = "Grade " .. job.grade
                    if Config.Jobs[job.job] and Config.Jobs[job.job].Grades and Config.Jobs[job.job].Grades[job.grade] then
                        gradeLabel = Config.Jobs[job.job].Grades[job.grade].label
                    end
                    
                    local activeText = job.is_active == 1 and " [ACTIVE]" or ""
                    local displayText = jobLabel .. " - " .. gradeLabel .. activeText
                    
                    if WarMenu.Button(displayText) then
                        if job.is_active ~= 1 then
                            TriggerServerEvent('ouro_society:server:SwitchJob', job.job)
                            Wait(500)
                            WarMenu.CloseMenu()
                        end
                    end
                end
            else
                WarMenu.Button("No jobs saved yet")
            end
            
            WarMenu.Display()
            Wait(0)
        end
    end)
end

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "close"
    })
    cb('ok')
end)

RegisterNUICallback('selectJob', function(data, cb)
    if data.job then
        TriggerServerEvent('ouro_society:server:AddJob', GetPlayerServerId(PlayerId()), data.job, 0)
    end
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Commands
RegisterCommand('job', function()
    OpenJobManagementMenu()
end, false)

RegisterCommand('switchjob', function(source, args, rawCommand)
    if #args > 0 then
        local jobName = args[1]
        TriggerServerEvent('ouro_society:server:SwitchJob', jobName)
    else
        TriggerEvent('vorp:TipRight', "Usage: /switchjob [jobname]", 3000)
    end
end, false)

RegisterCommand('bill', function(source, args, rawCommand)
    if #args > 1 then
        local targetId = tonumber(args[1])
        local amount = tonumber(args[2])
        
        if targetId and amount then
            -- Check if player has a job that allows billing
            local canBill = false
            for _, job in ipairs(PlayerJobs) do
                if Config.Jobs[job.job] and Config.Jobs[job.job].AllowBilling then
                    canBill = true
                    TriggerServerEvent('ouro_society:server:CreateBill', targetId, amount, job.job)
                    break
                end
            end
            
            if not canBill then
                TriggerEvent('vorp:TipRight', "Your job doesn't allow billing", 3000)
            end
        end
    else
        TriggerEvent('vorp:TipRight', "Usage: /bill [playerid] [amount]", 3000)
    end
end, false)

-- Duty commands
if Config.OnDutyCommand then
    RegisterCommand(Config.OnDutyCommand, function()
        -- Check if player has a duty job
        for _, job in ipairs(PlayerJobs) do
            for _, dutyJob in ipairs(Config.DutyJobs) do
                if dutyJob == job.job then
                    TriggerServerEvent('ouro_society:server:ToggleDuty', job.job)
                    OnDuty[job.job] = not OnDuty[job.job]
                    return
                end
            end
        end
        TriggerEvent('vorp:TipRight', "You don't have a duty job", 3000)
    end, false)
end

-- Blip creation
CreateThread(function()
    for jobName, jobData in pairs(Config.Jobs) do
        if jobData.ShowBlip and jobData.Pos then
            for _, pos in ipairs(jobData.Pos) do
                local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, pos.x, pos.y, pos.z)
                SetBlipSprite(blip, jobData.BlipSprite, 1)
                Citizen.InvokeNative(0x9CB1A1623062F402, blip, jobData.Name or jobName)
            end
        end
    end
    
    for centerName, centerData in pairs(Config.JobCenters) do
        if centerData.ShowBlip then
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, centerData.Pos.x, centerData.Pos.y, centerData.Pos.z)
            SetBlipSprite(blip, centerData.BlipSprite, 1)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, centerData.Name)
        end
    end
end)

-- Draw text helper
function DrawTxt(str, x, y, w, h, enableShadow, col1, col2, col3, a, centre)
    local str = CreateVarString(10, "LITERAL_STRING", str)
    SetTextScale(w, h)
    SetTextColor(math.floor(col1), math.floor(col2), math.floor(col3), math.floor(a))
    SetTextCentre(centre)
    if enableShadow then SetTextDropshadow(1, 0, 0, 0, 255) end
    Citizen.InvokeNative(0xADA9255D, 1)
    DisplayText(str, x, y)
end

function CreateVarString(p0, p1, variadic)
    return Citizen.InvokeNative(0xFA925AC00EB830B9, p0, p1, variadic, Citizen.ResultAsLong())
end

-- ============================
-- CLAN SYSTEM (Same as Jobs)
-- ============================

-- Get player clans
RegisterNetEvent('ouro_society:client:ReceiveClans')
AddEventHandler('ouro_society:client:ReceiveClans', function(clans)
    PlayerClans = clans
end)

-- Get clan members
RegisterNetEvent('ouro_society:client:ReceiveClanMembers')
AddEventHandler('ouro_society:client:ReceiveClanMembers', function(members)
    OpenClanMemberMenu(members)
end)

-- Update clan ledger balance
RegisterNetEvent('ouro_society:client:UpdateClanLedger')
AddEventHandler('ouro_society:client:UpdateClanLedger', function(balance)
    CurrentClanLedgerBalance = balance
end)

-- Commands
RegisterCommand('clan', function()
    OpenClanManagementMenu()
end, false)

-- Check clan zone access and open menu
RegisterNetEvent('ouro_society:client:OpenClanMenu')
AddEventHandler('ouro_society:client:OpenClanMenu', function(clanName, clanGrade)
    local clanData = Config.Clans[clanName]
    if not clanData then return end
    
    WarMenu.OpenMenu('clan_main')
    CurrentClan = clanName
    CurrentClanGrade = clanGrade
    
    CreateThread(function()
        while WarMenu.IsMenuOpened('clan_main') do
            WarMenu.MenuButton(Config.Language.ManageClan, 'manage_clan_members', function()
                if clanGrade >= clanData.BossRank then
                    TriggerServerEvent('ouro_society:server:GetOnlineClanMembers', clanName)
                else
                    TriggerEvent('vorp:TipRight', Config.Language.NoPermission, 3000)
                end
            end)
            
            WarMenu.MenuButton(Config.Language.ClanLedger, 'clan_ledger_menu', function()
                if clanGrade >= clanData.BossRank then
                    OpenClanLedgerMenu(clanName)
                else
                    TriggerEvent('vorp:TipRight', Config.Language.NoPermission, 3000)
                end
            end)
            
            WarMenu.MenuButton(Config.Language.ClanStorage, 'clan_storage_menu', function()
                OpenClanStorage(clanName, clanData.ContainerID, clanData.ContainerName)
            end)
            
            WarMenu.Display()
            Wait(0)
        end
    end)
end)

-- Open clan management menu
function OpenClanManagementMenu()
    TriggerServerEvent('ouro_society:server:GetPlayerClans')
    Wait(100)
    
    WarMenu.OpenMenu('clan_management')
    
    CreateThread(function()
        while WarMenu.IsMenuOpened('clan_management') do
            if WarMenu.Button("=== Your Clans ===") then end
            
            -- Show current clans
            if PlayerClans and #PlayerClans > 0 then
                for _, clan in ipairs(PlayerClans) do
                    local clanLabel = Config.Clans[clan.clan] and Config.Clans[clan.clan].Label or clan.clan
                    local gradeLabel = "Rank " .. clan.grade
                    if Config.Clans[clan.clan] and Config.Clans[clan.clan].Grades and Config.Clans[clan.clan].Grades[clan.grade] then
                        gradeLabel = Config.Clans[clan.clan].Grades[clan.grade].label
                    end
                    
                    local activeText = clan.is_active == 1 and " [ACTIVE]" or ""
                    local displayText = clanLabel .. " - " .. gradeLabel .. activeText
                    
                    if WarMenu.Button(displayText) then
                        if clan.is_active ~= 1 then
                            TriggerServerEvent('ouro_society:server:SwitchClan', clan.clan)
                            Wait(500)
                            WarMenu.CloseMenu()
                        end
                    end
                end
            else
                WarMenu.Button("No clans joined yet")
            end
            
            WarMenu.Button("---")
            
            if WarMenu.Button("Leave Current Clan") then
                if PlayerClans and #PlayerClans > 0 then
                    for _, clan in ipairs(PlayerClans) do
                        if clan.is_active == 1 then
                            TriggerServerEvent('ouro_society:server:LeaveClan', clan.clan)
                            Wait(500)
                            WarMenu.CloseMenu()
                            break
                        end
                    end
                else
                    TriggerEvent('vorp:TipRight', "Not in any clan", 3000)
                end
            end
            
            WarMenu.Display()
            Wait(0)
        end
    end)
end

-- Open clan member management
function OpenClanMemberMenu(members)
    WarMenu.OpenMenu('manage_clan_members')
    
    CreateThread(function()
        while WarMenu.IsMenuOpened('manage_clan_members') do
            for _, member in ipairs(members) do
                local gradeLabel = "Rank " .. member.grade
                if Config.Clans[member.clan] and Config.Clans[member.clan].Grades and Config.Clans[member.clan].Grades[member.grade] then
                    gradeLabel = Config.Clans[member.clan].Grades[member.grade].label
                end
                
                WarMenu.MenuButton(member.name .. " - " .. gradeLabel, 'clan_member_' .. member.serverId, function()
                    OpenClanMemberActions(member)
                end)
            end
            
            if #members == 0 then
                WarMenu.MenuButton("No members online", '', function() end)
            end
            
            WarMenu.Display()
            Wait(0)
        end
    end)
end

-- Open clan member actions
function OpenClanMemberActions(member)
    WarMenu.OpenMenu('clan_member_actions')
    
    CreateThread(function()
        while WarMenu.IsMenuOpened('clan_member_actions') do
            WarMenu.MenuButton("Remove from Clan", 'remove_clan_member', function()
                TriggerServerEvent('ouro_society:server:RemoveClanMember', member.serverId, member.clan)
                WarMenu.CloseMenu()
            end)
            
            WarMenu.MenuButton("Set Rank", 'set_clan_rank', function()
                OpenClanRankSelection(member)
            end)
            
            WarMenu.Display()
            Wait(0)
        end
    end)
end

-- Open clan rank selection
function OpenClanRankSelection(member)
    WarMenu.OpenMenu('clan_rank_selection')
    
    CreateThread(function()
        while WarMenu.IsMenuOpened('clan_rank_selection') do
            local clanData = Config.Clans[member.clan]
            if clanData and clanData.Grades then
                for grade, gradeData in pairs(clanData.Grades) do
                    WarMenu.MenuButton(gradeData.label .. " (Rank " .. grade .. ")", 'rank_' .. grade, function()
                        TriggerServerEvent('ouro_society:server:SetClanGrade', member.serverId, member.clan, grade)
                        WarMenu.CloseMenu()
                    end)
                end
            end
            
            WarMenu.Display()
            Wait(0)
        end
    end)
end

-- Open clan storage
function OpenClanStorage(clanName, containerID, containerName)
    WarMenu.CloseMenu()
    TriggerServerEvent("ouro_society:server:OpenClanStorage", containerID)
end

-- Open clan ledger menu
function OpenClanLedgerMenu(clanName)
    TriggerServerEvent('ouro_society:server:GetClanLedger', clanName)
    Wait(200)
    
    WarMenu.OpenMenu('clan_ledger_menu')
    
    CreateThread(function()
        while WarMenu.IsMenuOpened('clan_ledger_menu') do
            WarMenu.Button("Balance: $" .. CurrentClanLedgerBalance)
            WarMenu.Button("---")
            
            if WarMenu.Button("Deposit Money") then
                WarMenu.CloseMenu()
                
                DisplayPrompt("Enter amount to deposit", function(amount)
                    if amount and amount ~= "" then
                        local depositAmount = tonumber(amount)
                        if depositAmount and depositAmount > 0 then
                            TriggerServerEvent('ouro_society:server:DepositClanLedger', clanName, depositAmount)
                            Wait(500)
                            TriggerServerEvent('ouro_society:server:GetClanLedger', clanName)
                            Wait(200)
                        else
                            TriggerEvent('vorp:TipRight', Config.Language.InvalidAmount, 3000)
                        end
                    end
                    Wait(100)
                    OpenClanLedgerMenu(clanName)
                end)
            end
            
            if WarMenu.Button("Withdraw Money") then
                WarMenu.CloseMenu()
                
                DisplayPrompt("Enter amount to withdraw", function(amount)
                    if amount and amount ~= "" then
                        local withdrawAmount = tonumber(amount)
                        if withdrawAmount and withdrawAmount > 0 then
                            TriggerServerEvent('ouro_society:server:WithdrawClanLedger', clanName, withdrawAmount)
                            Wait(500)
                            TriggerServerEvent('ouro_society:server:GetClanLedger', clanName)
                            Wait(200)
                        else
                            TriggerEvent('vorp:TipRight', Config.Language.InvalidAmount, 3000)
                        end
                    end
                    Wait(100)
                    OpenClanLedgerMenu(clanName)
                end)
            end
            
            WarMenu.Display()
            Wait(0)
        end
    end)
end

-- Clan zone thread (same as job zones)
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Check clan menu zones
        for clanName, clanData in pairs(Config.Clans) do
            if clanData.ClanMenu then
                for _, menuPos in ipairs(clanData.ClanMenu) do
                    local distance = #(playerCoords - vector3(menuPos.x, menuPos.y, menuPos.z))
                    
                    if distance < 2.0 then
                        sleep = 0
                        InClanMenuZone = true
                        
                        -- Draw text
                        if Config.NormalDrawText then
                            local label = "Press [G] to open Clan Menu"
                            DrawTxt(label, 0.50, 0.95, 0.4, 0.4, true, 255, 255, 255, 255, true)
                        end
                        
                        -- Check for key press
                        if IsControlJustReleased(0, Config.OpenMenuKey) then
                            TriggerServerEvent('ouro_society:server:CheckClanAccess', clanName)
                        end
                        break
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Initialize WarMenu
CreateThread(function()
    WarMenu.CreateMenu('job_main', Config.Language.JobMenu)
    WarMenu.SetSubTitle('job_main', Config.Language.JobMenu)
    
    WarMenu.CreateSubMenu('manage_employees', 'job_main', Config.Language.ManageEmployees)
    WarMenu.CreateSubMenu('employee_actions', 'manage_employees', 'Employee Actions')
    WarMenu.CreateSubMenu('rank_selection', 'employee_actions', 'Select Rank')
    WarMenu.CreateSubMenu('ledger_menu', 'job_main', Config.Language.Ledger)
    WarMenu.CreateSubMenu('storage_menu', 'job_main', Config.Language.Inventory)
    WarMenu.CreateSubMenu('bills_menu', 'job_main', Config.Language.ViewBills)
    
    -- Job management menu
    WarMenu.CreateMenu('job_management', 'Job Management')
    WarMenu.SetSubTitle('job_management', 'Manage Your Jobs')
    
    -- Clan menus
    WarMenu.CreateMenu('clan_main', 'Clan Menu')
    WarMenu.SetSubTitle('clan_main', 'Clan Menu')
    
    WarMenu.CreateSubMenu('manage_clan_members', 'clan_main', Config.Language.ManageClan)
    WarMenu.CreateSubMenu('clan_member_actions', 'manage_clan_members', 'Member Actions')
    WarMenu.CreateSubMenu('clan_rank_selection', 'clan_member_actions', 'Select Rank')
    WarMenu.CreateSubMenu('clan_ledger_menu', 'clan_main', Config.Language.ClanLedger)
    WarMenu.CreateSubMenu('clan_storage_menu', 'clan_main', Config.Language.ClanStorage)
    
    -- Clan management menu
    WarMenu.CreateMenu('clan_management', 'Clan Management')
    WarMenu.SetSubTitle('clan_management', 'Manage Your Clans')
end)

