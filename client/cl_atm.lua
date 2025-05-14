-- Find the function that handles ATM interactions and update the drilling part:

-- This is a simplified version of what the function might look like:
local function SetupATMTargets()
    -- Create options array for target
    local options = {}
    
    -- Add hacking option if enabled
    if Config.EnableHacking then
        table.insert(options, {
            name = 'hack_atm',
            icon = 'fa-solid fa-laptop-code',
            label = 'Hack ATM',
            canInteract = function()
                -- Check conditions for hacking
                return true -- Add your conditions here
            end,
            onSelect = function(data)
                -- Hacking logic
                StartHackingATM(data.entity)
            end
        })
    end
    
    -- Add drilling option if enabled
    if Config.EnableDrilling then
        table.insert(options, {
            name = 'drill_atm',
            icon = 'fa-solid fa-screwdriver',
            label = 'Drill ATM',
            canInteract = function()
                -- Check conditions for drilling
                return true -- Add your conditions here
            end,
            onSelect = function(data)
                -- Start drilling process
                StartDrillingATM(data.entity)
            end
        })
    end
    
    -- Setup the target
    if Config.Target == 'ox-target' then
        exports.ox_target:addModel(Config.AtmModels, options)
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddTargetModel(Config.AtmModels, {
            options = options,
            distance = 2.0
        })
    end
end

-- Add this new function for drilling
function StartDrillingATM(entity)
    -- Check if player has the drill item if configured
    if Config.DrillItem then
        local hasItem = lib.callback.await('mns-atmrobbery:server:hasItem', false, Config.DrillItem)
        if not hasItem then
            SendNotification("You don't have a drill", "error")
            return
        end
    end
    
    -- Check police count
    if not lib.callback.await('mns-atmrobbery:server:checkPolice', false) then
        SendNotification("There aren't enough police to rob the ATM", "error")
        return
    end

    -- Request animation dictionary
    if not HasAnimDictLoaded(Config.Drilling.Animation.Dict) then
        RequestAnimDict(Config.Drilling.Animation.Dict)
        while not HasAnimDictLoaded(Config.Drilling.Animation.Dict) do
            Wait(10)
        end
    end
    
    -- Create drill prop
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    local drillObject = CreateObject(GetHashKey("hei_prop_heist_drill"), coords.x, coords.y, coords.z, true, true, true)
    AttachEntityToEntity(drillObject, ped, GetPedBoneIndex(ped, 57005), 0.14, 0, -0.01, 90.0, -90.0, 180.0, true, true, false, true, 1, true)
    
    -- Start drilling with progress bar
    if lib.progressBar({
        duration = Config.Drilling.Duration,
        label = 'Drilling ATM',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = Config.Drilling.Animation.Dict,
            clip = Config.Drilling.Animation.Clip,
        },
    }) then
        -- Drilling successful
        DeleteEntity(drillObject)
        ClearPedTasks(ped)
        
        -- Alert police
        AlertPolice(GetEntityCoords(entity), "ATM Drilling")
        
        -- Reward player
        if Config.MoneyDrop then
            -- Spawn money on ground
            for i = 1, Config.Reward.drill_cash_pile do
                SpawnCashPile(GetEntityCoords(entity))
            end
        else
            -- Add directly to inventory
            TriggerServerEvent('mns-atmrobbery:server:giveReward', 'drilling')
        end
    else
        -- Drilling cancelled
        DeleteEntity(drillObject)
        ClearPedTasks(ped)
    end
end