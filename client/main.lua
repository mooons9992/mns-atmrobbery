local cashObjects = {}

local atmModels = {
    ["prop_atm_01"] = vector3(0.202237, -0.20293, 0.779063),
    ["prop_atm_02"] = vector3(0.01,0.11,0.92),
    ["prop_atm_03"] = vector3(-0.14,-0.01,0.88),
    ["prop_fleeca_atm"] = vector3(0.127, 0.017, 1.0)
}

local QBCore = exports['qb-core']:GetCoreObject()

-- Local variables
local atmProps = Config.AtmModels
local atmBlips = {}

-- Send notification based on notification system in config
function SendNotification(message, type, duration)
    if not message then return end
    duration = duration or 3000
    
    if Config.Notify == 'ox' then
        lib.notify({
            title = 'ATM Robbery',
            description = message,
            type = type,
            duration = duration
        })
    elseif Config.Notify == 'qb' then
        QBCore.Functions.Notify(message, type, duration)
    elseif Config.Notify == 'okok' then
        exports['okokNotify']:Alert("ATM Robbery", message, duration, type)
    elseif Config.Notify == 'custom' then
        -- Add your custom notification here
        print("[ATM Robbery] "..message)
    end
end

-- Check police count
function CheckPoliceCount(cb)
    QBCore.Functions.TriggerCallback('mns-atmrobbery:server:checkPolice', function(result)
        cb(result)
    end)
end

-- Function to handle model loading
function LoadModel(model)
    if not HasModelLoaded(model) then
        RequestModel(model)
        local timeout = 0
        while not HasModelLoaded(model) and timeout < 10 do
            timeout = timeout + 1
            Wait(100)
        end
    end
    return HasModelLoaded(model)
end

-- Clean up resources when resource stops
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    -- Remove all blips
    for _, blip in ipairs(atmBlips) do
        RemoveBlip(blip)
    end
end)

for _, model in ipairs(Config.AtmModels) do
    if Config.Target == 'ox-target' then
        local options = {}
        if Config.EnableHacking then
            table.insert(options, {
                event = 'mns-atmrobbery_hack',
                label = "Hack ATM",
                icon = 'fas fa-laptop-code',
                model = model,
                distance = 1,
                items = Config.HackingItem, -- This will now require the electronickit
            })
        end
        if Config.EnableDrilling then
            -- No item requirement in target, we'll check in the event handler
            table.insert(options, {
                event = 'mns-atmrobbery_drill',
                label = "Drill ATM",
                icon = 'fas fa-tools',
                model = model,
                distance = 1,
            })
        end
        exports.ox_target:addModel(model, options)
        
    elseif Config.Target == 'qb-target' then
        local options = {}
        if Config.EnableHacking then
            table.insert(options, {
                type = "client",
                event = 'mns-atmrobbery_hack',
                icon = 'fas fa-laptop-code',
                label = "Hack ATM",
                model = model,
                item = Config.HackingItem,
            })
        end
        if Config.EnableDrilling then
            -- No item requirement in target, we'll check in the event handler
            table.insert(options, {
                type = "client",
                event = 'mns-atmrobbery_drill',
                icon = 'fas fa-tools',
                label = "Drill ATM",
                model = model,
            })
        end
        exports['qb-target']:AddTargetModel(model, {
            options = options,
            distance = 1.0
        })
    end
end

function AddCashToTarget(cash, atmCoords, method)
    method = method or "drilling" -- Default to drilling if not specified
    
    if Config.Target == 'qb-target' then
        exports['qb-target']:AddTargetEntity(cash, {
            options = {
                {
                    type = "client",
                    event = "mns-atmrobbery:pickupCash",
                    icon = "fas fa-money-bill-wave",
                    label = "Pick up cash",
                    atmCoords = atmCoords,
                    method = method
                }
            },
            distance = 1.5
        })
    elseif Config.Target == 'ox-target' then
        exports.ox_target:addLocalEntity(cash, {
            {
                event = "mns-atmrobbery:pickupCash",
                icon = "fas fa-money-bill-wave",
                label = "Pick up cash",
                args = atmCoords,
                method = method
            }
        })
    end
end

RegisterNetEvent('mns-atmrobbery:notification')
AddEventHandler('mns-atmrobbery:notification', function(message, type)
    if Config.Notify == 'ox' then
        lib.notify({
            title = 'ATM Robbery',
            description = message,
            type = type or "success",
            duration = 6000
        })
    elseif Config.Notify == 'okok' then
        exports['okokNotify']:Alert("ATM Robbery", message, 6000, type)
    elseif Config.Notify == 'qb' then
        QBCore.Functions.Notify(message, type, 6000)
    elseif Config.Notify == 'wasabi' then
        exports.wasabi_notify:notify("ATM ROBBERY", message, 6000, type, false, 'fas fa-ghost')
    elseif Config.Notify == 'custom' then
        -- Add your custom notifications here
    end
end)

function DispatchAlert()
    if Config.Dispatch == 'default' then
        TriggerServerEvent('mns-atmrobbery:server:policeAlert', "ATM robbery in progress")
    elseif Config.Dispatch == 'ps' then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street1name = GetStreetNameFromHashKey(street1)
        local street2name = GetStreetNameFromHashKey(street2)
        local alert = {
            coords = coords,
            message = "ATM robbery in progress at "..street1name.. ' ' ..street2name,
            dispatchCode = '10-90',
            description = 'ATM Robbery',
            radius = 0,
            sprite = 431,
            color = 1,
            scale = 1.0,
            length = 3
        }
        exports["ps-dispatch"]:CustomAlert(alert)
    elseif Config.Dispatch == 'qs' then
        local playerData = exports['qs-dispatch']:GetPlayerInfo()
        TriggerServerEvent('qs-dispatch:server:CreateDispatchCall', {
            job = Config.Police.Job,
            callLocation = playerData.coords,
            callCode = { code = '10-90', snippet = 'ATM Robbery' },
            message = "street_1: ".. playerData.street_1.. " street_2: ".. playerData.street_2.."",
            flashes = false, -- No flashing icon
            image = nil,
            blip = {
                sprite = 431,
                scale = 1.2,
                colour = 1,
                flashes = true,
                text = 'ATM Robbery',
                time = (30 * 1000), 
            }
        })
    elseif Config.Dispatch == 'aty' then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street1name = GetStreetNameFromHashKey(street1)
        local street2name = GetStreetNameFromHashKey(street2)
        TriggerServerEvent("aty_dispatch:server:customDispatch",
            "ATM Robbery",          -- title
            "10-90",                -- code
            street1name..' '..street2name, -- location
            coords,      -- coords (vector3)
            nil,         -- gender
            nil, -- vehicle name
            nil, -- vehicle object (optional)
            nil, -- weapon (not needed for ATM robbery)
            431, -- blip sprite (robbery icon)
            Config.Police.Job -- jobs to notify
            )
    elseif Config.Dispatch == 'rcore_disptach' then
        local playerData = exports['rcore_dispatch']:GetPlayerData()
        exports['screenshot-basic']:requestScreenshotUpload('InsertWebhookLinkHERE', "files[]", function(val)
            local image = json.decode(val)
            local alert = {
                code = '10-90 - ATM Robbery',
                default_priority = 'low',
                coords = playerData.coords,
                job = Config.Police.Job,
                text = 'ATM Robbery in progress on ' ..playerData.street_1,
                type = 'alerts',
                blip_time = 30,
                image = image.attachments[1].proxy_url,
                blip = {
                    sprite = 431,
                    colour = 1,
                    scale = 1.0,
                    text = '10-990 - ATM Robbery',
                    flashes = false,
                    radius = 0,
                }
            }
        TriggerServerEvent('rcore_dispatch:server:sendAlert', alert)
    end)
    elseif Config.Dispatch == 'custom' then
        -- Add your custom dispatch code here
    end
end

RegisterNetEvent('mns-atmrobbery_drill')
AddEventHandler('mns-atmrobbery_drill', function(data)
    local entity = data.entity
    local atmModel = GetEntityModel(entity)

    if entity and DoesEntityExist(entity) then
        local atmCoords = GetEntityCoords(entity)
        if not IsPedHeadingTowardsPosition(PlayerPedId(), atmCoords.x,atmCoords.y,atmCoords.z,10.0) then
            TaskTurnPedToFaceCoord(PlayerPedId(), atmCoords.x,atmCoords.y,atmCoords.z, 1500)
        end
        
        -- Check if player has the drill item first
        local hasDrill = lib.callback.await('mns-atmrobbery:server:hasItem', false, Config.DrillItem)
        if not hasDrill then
            TriggerEvent('mns-atmrobbery:notification', "You need a drill to rob this ATM", 'error')
            return
        end
        
        -- Continue with police count check
        local enoughpolice = lib.callback.await('mns-atmrobbery:checkforpolice', false)
        if enoughpolice then
            local checktime, remainingTime = lib.callback.await('mns-atmrobbery:checktime', false)
            if checktime then
                Wait(1000)
                if Config.Police.notify then
                    DispatchAlert()
                end
                
                -- Request animation dictionary for drilling
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
                
                -- Calculate drill position on ATM
                local atmForward = GetEntityForwardVector(entity)
                local drillPos = atmCoords + (atmForward * -0.2) -- Position slightly in front of ATM
                drillPos = vector3(drillPos.x, drillPos.y, drillPos.z + 0.6) -- Adjust height
                
                -- Setup sparks effect
                local ptfxDict = "core"
                local ptfxName = "ent_dst_elec_fire"
                
                RequestNamedPtfxAsset(ptfxDict)
                while not HasNamedPtfxAssetLoaded(ptfxDict) do
                    Wait(10)
                end
                
                -- Create thread for spark effects during drilling
                local sparkEffect = nil
                local sparkThread = nil
                local soundId = GetSoundId() -- Get a sound ID for our drilling sound
                
                sparkThread = CreateThread(function()
                    UseParticleFxAssetNextCall(ptfxDict)
                    sparkEffect = StartParticleFxLoopedAtCoord(
                        ptfxName,
                        drillPos.x, drillPos.y, drillPos.z,
                        0.0, 0.0, 0.0,
                        0.5, -- Scale
                        false, false, false, false
                    )
                    
                    SetParticleFxLoopedColour(sparkEffect, 1.0, 1.0, 0.0, false)
                    
                    -- Get sound ID for drilling sound
                    if soundId == -1 then
                        soundId = GetSoundId()
                    end
                    
                    -- Primary drilling sound - attached to drill object
                    PlaySoundFromEntity(soundId, "Drill", drillObject, "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
                    
                    -- Add a subtle electrical buzz from the sparks
                    PlaySoundFromCoord(-1, "Electrical_Sparks", drillPos.x, drillPos.y, drillPos.z, "EXILE_1", true, 15, false)
                    
                    -- Check if sound needs to be restarted periodically
                    Citizen.CreateThread(function()
                        while DoesEntityExist(drillObject) do
                            -- Update sound parameters to ensure it continues playing
                            if HasSoundFinished(soundId) then
                                PlaySoundFromEntity(soundId, "Drill", drillObject, "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
                            end
                            Wait(500)
                        end
                    end)
                end)
                
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
                    if sparkEffect then
                        StopParticleFxLooped(sparkEffect, 0)
                    end
                    DeleteEntity(drillObject)
                    ClearPedTasks(ped)
                    
                    -- Stop all sounds
                    StopSound(soundId)
                    ReleaseSoundId(soundId)
                    
                    -- Generate more sparks as a drilling completion effect
                    UseParticleFxAssetNextCall(ptfxDict)
                    local finalSpark = StartParticleFxLoopedAtCoord(
                        "ent_sht_electrical_box_sp", -- Bigger spark effect for completion
                        drillPos.x, drillPos.y, drillPos.z,
                        0.0, 0.0, 0.0,
                        1.0, -- Larger scale
                        false, false, false, false
                    )
                    
                    -- Play a success sound
                    PlaySoundFromCoord(-1, "Drill_Pin_Break", drillPos.x, drillPos.y, drillPos.z, "DLC_HEIST_FLEECA_SOUNDSET", true, 50, false)
                    
                    Wait(500)
                    StopParticleFxLooped(finalSpark, 0)
                    
                    -- Alert police
                    TriggerEvent('mns-atmrobbery:notification', "You successfully drilled into the ATM", 'success')
                    
                    -- Reward player
                    if Config.MoneyDrop then
                        -- Spawn money on ground
                        TriggerEvent('mns-atmrobbery_drill:success', entity, atmCoords, atmModel)
                    else
                        -- Add directly to inventory
                        TriggerServerEvent('mns-atmrobbery:GiveReward', atmCoords, 'drilling')
                    end
                else
                    -- Drilling cancelled
                    if sparkEffect then
                        StopParticleFxLooped(sparkEffect, 0)
                    end
                    DeleteEntity(drillObject)
                    ClearPedTasks(ped)
                    
                    -- Stop all sounds
                    StopSound(soundId)
                    ReleaseSoundId(soundId)
                    
                    -- Report failure to server for cooldown reset
                    TriggerServerEvent('mns-atmrobbery:MinigameResult', false)
                end
                
                -- Clean up thread if it exists
                if sparkThread then
                    TerminateThread(sparkThread)
                    sparkThread = nil
                end
            else
                local minutes = math.floor(remainingTime / 60)
                local seconds = remainingTime % 60
                local timeString = string.format("%02d:%02d", minutes, seconds)
                TriggerEvent('mns-atmrobbery:notification', "You must wait " .. timeString .. " before robbing another ATM", 'error')
            end
        else
            TriggerEvent('mns-atmrobbery:notification', "Not enough police online", 'error')
        end
    end
end)

RegisterNetEvent('mns-atmrobbery_hack')
AddEventHandler('mns-atmrobbery_hack', function(data)
    local entity = data.entity
    local atmModel = GetEntityModel(entity)

    if entity and DoesEntityExist(entity) then
        local atmCoords = GetEntityCoords(entity)
        if not IsPedHeadingTowardsPosition(PlayerPedId(), atmCoords.x,atmCoords.y,atmCoords.z,10.0) then
            TaskTurnPedToFaceCoord(PlayerPedId(), atmCoords.x,atmCoords.y,atmCoords.z, 1500)
        end
        
        -- Check if player has the electronic kit item first
        local hasElectronicKit = lib.callback.await('mns-atmrobbery:server:hasItem', false, Config.HackingItem)
        if not hasElectronicKit then
            TriggerEvent('mns-atmrobbery:notification', "You need an electronic kit to hack this ATM", 'error')
            return
        end
        
        local enoughpolice = lib.callback.await('mns-atmrobbery:checkforpolice', false)
        if enoughpolice then
            local checktime, remainingTime = lib.callback.await('mns-atmrobbery:checktime', false)
            if checktime then
                Wait(1000)
                if Config.Police.notify then
                    DispatchAlert()
                end
                
                -- Create and use tablet prop instead of laptop setup
                local tabletProp = CreateObject(`prop_cs_tablet`, 0.0, 0.0, 0.0, true, true, true)
                local playerPed = PlayerPedId()
                
                -- Attach tablet to player's hand
                AttachEntityToEntity(tabletProp, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                
                -- Simple tablet animation
                local animDict = "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a"
                RequestAnimDict(animDict)
                while not HasAnimDictLoaded(animDict) do
                    Wait(10)
                end
                
                -- Play tablet animation
                TaskPlayAnim(playerPed, animDict, "idle_a", 8.0, 8.0, -1, 49, 0, false, false, false)
                
                -- Instead of teleporting player, just set heading to face the ATM
                -- This avoids crashes and positional issues
                local atmHeading = GetEntityHeading(entity)
                SetEntityHeading(playerPed, atmHeading - 180.0) -- Face the ATM
                
                -- Show progress bar
                if lib.progressBar({
                    duration = Config.Hacking.InitialHackDuration,
                    label = 'Initializing Hack',
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        car = true,
                        move = true,
                        combat = true,
                    },
                }) then
                    -- After progress bar, start minigame
                    TriggerEvent('mns-atmrobbery:StartMinigame', entity, atmCoords, atmModel, tabletProp)
                else
                    -- Progress was canceled
                    ClearPedTasks(playerPed)
                    DeleteEntity(tabletProp)
                end
            else
                local minutes = math.floor(remainingTime / 60)
                local seconds = remainingTime % 60
                local timeString = string.format("%02d:%02d", minutes, seconds)
                TriggerEvent('mns-atmrobbery:notification', "You must wait " .. timeString .. " before robbing another ATM", 'error')
            end
        else
            TriggerEvent('mns-atmrobbery:notification', "Not enough police online",'error')
        end
    end
end)

RegisterNetEvent('mns-atmrobbery:StartMinigame')
AddEventHandler('mns-atmrobbery:StartMinigame', function(entity, atmCoords, atmModel, tabletProp)
    if Config.Hacking.Minigame == 'utk_fingerprint' then
        TriggerEvent("utk_fingerprint:Start", 1, 6, 1, function(outcome, reason)
            -- Handle outcome
            if outcome == true then
                if not Config.MoneyDrop then
                    LootATM(atmCoords)
                else
                    TriggerEvent("mns-atmrobbery:spitCash", entity, atmCoords, atmModel)
                end
            elseif outcome == false then
                TriggerServerEvent('mns-atmrobbery:MinigameResult', false)
                TriggerEvent('mns-atmrobbery:notification', "ATM robbery failed", 'error')
            end
            
            -- Always clean up tablet prop and animations
            ClearPedTasks(PlayerPedId())
            if DoesEntityExist(tabletProp) then
                DeleteEntity(tabletProp)
            end
        end)
    elseif Config.Hacking.Minigame == 'ox_lib' then
        local outcome = lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 1}, 'easy'}, {'w', 'a', 's', 'd'})
        if outcome == true then
            if not Config.MoneyDrop then
                LootATM(atmCoords)
            else
                TriggerEvent("mns-atmrobbery:spitCash", entity, atmCoords, atmModel)
            end
        elseif outcome == false then
            TriggerServerEvent('mns-atmrobbery:MinigameResult', false)
            TriggerEvent('mns-atmrobbery:notification', "ATM robbery failed", 'error')
        end
        
        -- Clean up tablet prop and animations
        ClearPedTasks(PlayerPedId())
        if DoesEntityExist(tabletProp) then
            DeleteEntity(tabletProp)
        end
    end
end)

function LootATM(atmCoords)
    lib.progressBar({
        duration = Config.Hacking.LootAtmDuration,
        label = 'Collecting Cash',
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'oddjobs@shop_robbery@rob_till',
            clip = 'loop', 
        }
    })

    -- Collect the reward
    TriggerServerEvent('mns-atmrobbery:GiveReward', atmCoords)
end

AddEventHandler('progressBar:cancel', function(data)
    if data and data.label == 'Initializing Hack' then
        -- Find and delete any tablet props attached to player
        local playerPed = PlayerPedId()
        local tablets = GetGamePool('CObject')
        
        for i = 1, #tablets do
            if GetEntityModel(tablets[i]) == `prop_cs_tablet` and IsEntityAttachedToEntity(tablets[i], playerPed) then
                DeleteEntity(tablets[i])
            end
        end
        
        -- Clear animations
        ClearPedTasks(playerPed)
    end
end)

RegisterNetEvent('mns-atmrobbery:client:policeAlert', function(coords, text)
    local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street1name = GetStreetNameFromHashKey(street1)
    local street2name = GetStreetNameFromHashKey(street2)
    TriggerEvent('mns-atmrobbery:notification', ''..text..' at '..street1name.. ' ' ..street2name, 'success')
    PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)
    local transG = 250
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    local blip2 = AddBlipForCoord(coords.x, coords.y, coords.z)
    local blipText = text
    SetBlipSprite(blip, 60)
    SetBlipSprite(blip2, 161)
    SetBlipColour(blip, 1)
    SetBlipColour(blip2, 1)
    SetBlipDisplay(blip, 4)
    SetBlipDisplay(blip2, 8)
    SetBlipAlpha(blip, transG)
    SetBlipAlpha(blip2, transG)
    SetBlipScale(blip, 0.8)
    SetBlipScale(blip2, 2.0)
    SetBlipAsShortRange(blip, false)
    SetBlipAsShortRange(blip2, false)
    PulseBlip(blip2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(blipText)
    EndTextCommandSetBlipName(blip)
    while transG ~= 0 do
        Wait(180 * 4)
        transG = transG - 1
        SetBlipAlpha(blip, transG)
        SetBlipAlpha(blip2, transG)
        if transG == 0 then
            RemoveBlip(blip)
            return
        end
    end
end)

RegisterNetEvent("mns-atmrobbery:pickupCash")
AddEventHandler("mns-atmrobbery:pickupCash", function(data)
    local entity = data.entity
    local playerPed = PlayerPedId()
    local atmCoords
    local method = data.method or "drilling" -- Add method parameter
    
    if Config.Target == 'ox-target' then
        atmCoords = data.args
    elseif Config.Target == 'qb-target' then
        atmCoords = data.atmCoords
    end
    
    RequestAnimDict("pickup_object")
    while not HasAnimDictLoaded("pickup_object") do
        Wait(10)
    end

    TaskPlayAnim(playerPed, "pickup_object", "pickup_low", 8.0, -8.0, -1, 48, 0, false, false, false)

    Wait(1000)

    if DoesEntityExist(entity) then
        DeleteEntity(entity)
        TriggerServerEvent('mns-atmrobbery:GiveReward', atmCoords, method)
    end
    ClearPedTasks(playerPed)
end)

local function getModelNameFromHash(hash)
    for modelName, _ in pairs(atmModels) do
        if GetHashKey(modelName) == hash then
            return modelName
        end
    end
    return nil -- Not found
end

RegisterNetEvent("mns-atmrobbery_drill:success")
AddEventHandler("mns-atmrobbery_drill:success", function(atmEntity, atmCoords, atmModel)
    local cashModel = "hei_prop_heist_cash_pile"
    RequestModel(cashModel)
    while not HasModelLoaded(cashModel) do
        Wait(10)
    end

    local atmForward = GetEntityForwardVector(atmEntity)
    local atmHeading = GetEntityHeading(atmEntity)

    local dropOffset
    local atmModelName = getModelNameFromHash(atmModel)
    if atmModels[atmModelName] then
        dropOffset = atmModels[atmModelName]
    end
    local dropPosition = atmCoords + dropOffset
    for i = 1, Config.Reward.drill_cash_pile do 
        Wait(150)

        local cash = CreateObject(GetHashKey(cashModel), dropPosition.x, dropPosition.y, dropPosition.z, true, true, true)
        SetEntityHeading(cash, atmHeading)

        local forceX = atmForward.x * 2
        local forceY = atmForward.y * 2
        local forceZ = 0.2

        SetEntityVelocity(cash, forceX, forceY, forceZ)
        AddCashToTarget(cash, atmCoords, "drilling") -- Specify drilling method
        table.insert(cashObjects, cash)
    end
end)

RegisterNetEvent("mns-atmrobbery:spitCash")
AddEventHandler("mns-atmrobbery:spitCash", function(atmEntity, atmCoords, atmModel)
    local cashModel = "prop_anim_cash_pile_01"
    RequestModel(cashModel)
    while not HasModelLoaded(cashModel) do
        Wait(10)
    end

    local atmForward = GetEntityForwardVector(atmEntity)
    local atmHeading = GetEntityHeading(atmEntity)

    local dropOffset
    local atmModelName = getModelNameFromHash(atmModel)
    if atmModels[atmModelName] then
        dropOffset = atmModels[atmModelName]
    end
    local dropPosition = atmCoords + dropOffset
    for i = 1, Config.Reward.hack_cash_pile do 
        Wait(150)

        local cash = CreateObject(GetHashKey(cashModel), dropPosition.x, dropPosition.y, dropPosition.z, true, true, true)
        SetEntityHeading(cash, atmHeading)
        local forceX = atmForward.x * 2 
        local forceY = atmForward.y * 2
        local forceZ = 0.2

        SetEntityVelocity(cash, forceX, forceY, forceZ)
        AddCashToTarget(cash, atmCoords, "hacking") -- Specify hacking method
        table.insert(cashObjects, cash)
    end
end)

function DeleteCashObjects()
    for _, cash in pairs(cashObjects) do
        if Config.Target == 'ox-target' then
            exports.ox_target:removeEntity(cash)
        elseif Config.Target == 'qb-target' then
            exports['qb-target']:RemoveTargetEntity(cash)
        end
        DeleteEntity(cash)
    end
    cashObjects = {}
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DeleteCashObjects() 
    end
end)

