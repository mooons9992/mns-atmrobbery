-- Add QBCore initialization at the top of the file
local QBCore = exports['qb-core']:GetCoreObject()

-- Add this callback to check for the drill item
lib.callback.register('mns-atmrobbery:server:hasItem', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local hasItem = Player.Functions.GetItemByName(item)
    return hasItem and hasItem.amount > 0
end)

-- Make sure to add this event handler for giving rewards
RegisterNetEvent('mns-atmrobbery:server:giveReward', function(method)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local amount = 0
    local valuePerPile = Config.Reward.cash_prop_value
    local numPiles = 0
    
    -- Calculate reward based on method and new config options
    if method == 'hacking' then
        numPiles = Config.Reward.hack_cash_pile
        
        if Config.Reward.UseRandomAmounts then
            valuePerPile = math.random(Config.Hacking.MinReward, Config.Hacking.MaxReward)
        end
        
        -- Apply hacking multiplier
        amount = numPiles * valuePerPile * Config.Hacking.RewardMultiplier
    elseif method == 'drilling' then
        numPiles = Config.Reward.drill_cash_pile
        
        if Config.Reward.UseRandomAmounts then
            valuePerPile = math.random(Config.Drilling.MinReward, Config.Drilling.MaxReward)
            
            -- Extra chance for higher values when drilling if enabled
            if Config.Reward.DrillHasHigherChance and math.random(1, 100) > 70 then
                -- 30% chance to get max value when drilling
                valuePerPile = Config.Drilling.MaxReward
            end
        end
        
        -- Apply drilling multiplier
        amount = numPiles * valuePerPile * Config.Drilling.RewardMultiplier
    end
    
    -- Round the final amount
    amount = math.floor(amount)
    
    -- Debug output
    if Config.Debug then
        print("[ATM Robbery] Player " .. src .. " received " .. method .. " reward of $" .. amount)
    end
    
    -- Give the reward to player based on account type
    if Config.Reward.account == 'dirty' then
        -- Convert amount to number of marked bills based on their value
        local billsToGive = math.ceil(amount / Config.Reward.cash_prop_value)
        Player.Functions.AddItem(Config.Reward.dirty_money_item, billsToGive)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Reward.dirty_money_item], "add")
    else
        Player.Functions.AddMoney(Config.Reward.account, amount)
    end
    
    TriggerClientEvent('QBCore:Notify', src, "You got $" .. amount .. " from the ATM.", "success")
end)