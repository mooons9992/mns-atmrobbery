local QBCore = exports['qb-core']:GetCoreObject()

-- Check if player has marked bills and return count
lib.callback.register('mns-atmrobbery:server:checkMarkedBills', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false, 0 end
    
    -- Get all marked bills items
    local items = Player.PlayerData.items
    local totalStacks = 0
    
    -- Count stacks based on configuration
    for _, item in pairs(items) do
        if item.name == Config.Reward.dirty_money_item then
            if Config.Reward.UseItemQuantity then
                -- Count the quantity of the item in this slot
                totalStacks = totalStacks + (item.amount or 1)
            else
                -- Just count the slot itself as one stack
                totalStacks = totalStacks + 1
            end
        end
    end
    
    return totalStacks > 0, totalStacks
end)

-- Check if player can wash the specified amount
lib.callback.register('mns-atmrobbery:server:canWashMoney', function(source, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    -- Calculate the total value of all marked bills the player has
    local items = Player.PlayerData.items
    local totalValue = 0
    
    for _, item in pairs(items) do
        if item.name == Config.Reward.dirty_money_item then
            -- Get worth from info if available, otherwise use default value
            local worth = item.info and item.info.worth or Config.Reward.cash_prop_value
            totalValue = totalValue + worth
        end
    end
    
    return totalValue >= amount
end)

-- Wash the money
RegisterNetEvent('mns-atmrobbery:server:washMoney', function(stackCount, washType, rate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Validate input
    stackCount = tonumber(stackCount)
    if not stackCount or stackCount < 1 then
        TriggerClientEvent('QBCore:Notify', src, "Invalid amount of stacks.", "error")
        return
    end
    
    -- Get all marked bills items and track their information
    local items = Player.PlayerData.items
    local remainingToRemove = stackCount
    local totalValue = 0
    local itemsToProcess = {}
    
    -- First pass: collect all the marked bills we have and their info
    for slot, item in pairs(items) do
        if item.name == Config.Reward.dirty_money_item and remainingToRemove > 0 then
            -- Get the amount in this stack
            local billsInStack = item.amount or 1
            local worthPerBill = item.info and item.info.worth or Config.Reward.cash_prop_value
            
            -- Calculate how many we need from this slot
            local billsToTake = math.min(remainingToRemove, billsInStack)
            
            -- Add to our processing list
            table.insert(itemsToProcess, {
                slot = slot,
                billsInStack = billsInStack,
                billsToTake = billsToTake,
                worthPerBill = worthPerBill
            })
            
            -- Update total value and remaining count
            totalValue = totalValue + (worthPerBill * billsToTake)
            remainingToRemove = remainingToRemove - billsToTake
            
            -- Debug output
            print(string.format("[WASH] Adding %d bills from slot %d (worth $%d each) to process list", 
                billsToTake, slot, worthPerBill))
            
            -- If we've found all we need, stop searching
            if remainingToRemove <= 0 then
                break
            end
        end
    end
    
    -- Verify we found enough bills
    if remainingToRemove > 0 then
        TriggerClientEvent('QBCore:Notify', src, "You don't have enough marked bills.", "error")
        return
    end
    
    print("[WASH] Processing " .. stackCount .. " bills worth a total of $" .. totalValue)
    
    -- Second pass: remove the items
    for _, itemData in ipairs(itemsToProcess) do
        if itemData.billsToTake > 0 then
            -- Debug logging
            print(string.format("[WASH] Taking %d of %d bills from slot %d", 
                itemData.billsToTake, itemData.billsInStack, itemData.slot))
                
            if itemData.billsToTake == itemData.billsInStack then
                -- Remove the entire stack if we're taking all bills
                Player.Functions.RemoveItem(Config.Reward.dirty_money_item, itemData.billsInStack, itemData.slot)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Reward.dirty_money_item], "remove")
            else
                -- Remove partial stack
                Player.Functions.RemoveItem(Config.Reward.dirty_money_item, itemData.billsToTake, itemData.slot)
                -- No visual notification for partial removal
            end
        end
    end
    
    -- Calculate washed amount with bonus
    local bonusMultiplier = 1.05 -- 5% extra bonus
    local washAmount = math.floor(totalValue * rate * bonusMultiplier)
    
    -- Add the washed money to appropriate account
    if washType == "cash" then
        Player.Functions.AddMoney("cash", washAmount)
        TriggerClientEvent('QBCore:Notify', src, "You received $" .. washAmount .. " in cash.", "success")
    elseif washType == "bank" then
        Player.Functions.AddMoney("bank", washAmount)
        TriggerClientEvent('QBCore:Notify', src, "You received $" .. washAmount .. " in your bank account.", "success")
    end
    
    -- Log the transaction
    print("Player " .. Player.PlayerData.name .. " (ID: " .. src .. ") washed " .. stackCount .. 
          " marked bills worth $" .. totalValue .. " for $" .. washAmount .. " in " .. washType)
end)