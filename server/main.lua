local QBCore = exports['qb-core']:GetCoreObject()

-- Change from a single variable to a table tracking per-player cooldowns
local playerCooldowns = {}
local resourceName = 'mns-atmrobbery'

-- Debug print function
local function DebugPrint(msg)
    if Config.Debug then
        print("^3[MNS-ATMROBBERY]^7 " .. msg)
    end
end

local isQbCoreStarted = GetResourceState('qb-core') == 'started'

--credits to Lation for checkforpolice
--https://github.com/IamLation/lation_247robbery
lib.callback.register('mns-atmrobbery:checkforpolice', function()
    local copCount = 0
    local jobs = {}
    
    for _, job in pairs(Config.Police.Job) do
        jobs[job] = true
    end
    
    local requiredCount = Config.Police.required

    for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
        local player = QBCore.Functions.GetPlayer(playerId)
        if player and jobs[player.PlayerData.job.name] and player.PlayerData.job.onduty then
            copCount = copCount + 1
        end
    end
    
    return copCount >= requiredCount
end)

-- Modified to check player-specific cooldown
lib.callback.register('mns-atmrobbery:checktime', function(source)
    local src = source
    local currentTime = os.time()
    
    -- Check if this specific player has a cooldown
    if playerCooldowns[src] and playerCooldowns[src] > currentTime then
        local remainingTime = playerCooldowns[src] - currentTime
        return false, remainingTime
    end

    -- Set the cooldown for this specific player
    playerCooldowns[src] = currentTime + Config.CooldownTimer
    return true
end)

lib.callback.register('mns-atmrobbery:server:hasItem', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return false end
    
    return Player.Functions.GetItemByName(item) ~= nil
end)

-- Modified to reset just the specific player's cooldown
RegisterServerEvent('mns-atmrobbery:MinigameResult')
AddEventHandler('mns-atmrobbery:MinigameResult', function(success)
    local src = source
    if not success then
        -- Reset this player's cooldown on failure
        playerCooldowns[src] = nil 
    end
end)

-- Clean up player cooldowns when they disconnect
AddEventHandler('playerDropped', function()
    local src = source
    if playerCooldowns[src] then
        playerCooldowns[src] = nil
    end
end)

RegisterNetEvent('mns-atmrobbery:GiveReward')
AddEventHandler('mns-atmrobbery:GiveReward', function(atmCoords, method)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Identifier = Player.PlayerData.citizenid
    local PlayerName = Player.PlayerData.name
    local ped = GetPlayerPed(src)
    local distance = #(GetEntityCoords(ped) - atmCoords)
    
    if distance <= 5 then
        -- Determine reward amount based on method
        local amount = 0
        method = method or "drilling" -- Default to drilling if not specified
        
        if method == "hacking" then
            local baseValue = Config.Reward.cash_prop_value
            if Config.Reward.UseRandomAmounts then
                baseValue = math.random(Config.Hacking.MinReward, Config.Hacking.MaxReward)
            end
            amount = baseValue * Config.Hacking.RewardMultiplier
        else -- drilling
            local baseValue = Config.Reward.cash_prop_value
            if Config.Reward.UseRandomAmounts then
                baseValue = math.random(Config.Drilling.MinReward, Config.Drilling.MaxReward)
                
                -- Extra chance for max value when drilling
                if Config.Reward.DrillHasHigherChance and math.random(1, 100) > 70 then
                    baseValue = Config.Drilling.MaxReward
                end
            end
            amount = baseValue * Config.Drilling.RewardMultiplier
        end
        
        -- Round to nearest integer
        amount = math.floor(amount)
        
        -- Give reward with stacking capability
        if Config.Reward.account == 'dirty' then
            -- Add stack of marked bills with worth info
            local info = {
                worth = amount
            }
            Player.Functions.AddItem(Config.Reward.dirty_money_item, 1, false, info)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Reward.dirty_money_item], "add")
            TriggerClientEvent('mns-atmrobbery:notification', src, "You picked up a stack of marked bills", 'success')
        else
            Player.Functions.AddMoney(Config.Reward.account, amount)
            TriggerClientEvent('mns-atmrobbery:notification', src, "You picked up $" .. amount, 'success')
        end
    else
        print('**Name:** ' .. PlayerName .. '\n**Identifier:** ' .. Identifier .. '** Attempted Exploit : Possible Hacker**')
    end
end)

RegisterNetEvent('mns-atmrobbery:server:policeAlert')
AddEventHandler('mns-atmrobbery:server:policeAlert', function(text)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    
    for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
        local player = QBCore.Functions.GetPlayer(playerId)
        if player and table.contains(Config.Police.Job, player.PlayerData.job.name) and player.PlayerData.job.onduty then
            TriggerClientEvent('mns-atmrobbery:client:policeAlert', playerId, coords, text)
        end
    end
end)

-- Helper function to check if value exists in table
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Version check notification
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("^2[MNS-ATMROBBERY]^7 Resource started successfully")
    end
end)

local WaterMark = function()
    SetTimeout(1500, function()
        print('^1['..resourceName..'] ^2Thank you for using MNS ATM Robbery^0')
    end)
end

WaterMark()

