local QBCore = exports['qb-core']:GetCoreObject()
local CurrentWashingLocation = nil
local washCooldowns = {}

-- Function to create money washing blips
local function CreateWashingBlips()
    if not Config.MoneyWash.enabled then return end
    
    for i, location in ipairs(Config.MoneyWash.locations) do
        if location.blip and location.blip.enabled then
            local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
            SetBlipSprite(blip, location.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, location.blip.scale)
            SetBlipColour(blip, location.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(location.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end

-- Function to open the money washing menu
local function OpenWashingMenu(locationIndex)
    local location = Config.MoneyWash.locations[locationIndex]
    local playerId = GetPlayerServerId(PlayerId())
    
    -- Check if player has marked bills
    local hasMarkedBills, totalStacks = lib.callback.await('mns-atmrobbery:server:checkMarkedBills', false)
    if not hasMarkedBills then
        SendNotification("You don't have any marked bills to wash.", "error")
        return
    end
    
    CurrentWashingLocation = locationIndex
    
    -- Use slider input with ox_lib
    local input = lib.inputDialog('Money Washing', {
        {
            type = 'slider',
            label = 'Stacks to wash',
            description = 'Select how many stacks of marked bills to wash',
            icon = 'fa-solid fa-money-bill-wave',
            required = true,
            min = 1,
            max = totalStacks,
            default = 1,
        }
    })
    
    if not input or not input[1] then return end
    
    local stackCount = tonumber(input[1])
    if not stackCount or stackCount < 1 or stackCount > totalStacks then
        SendNotification("Invalid number of stacks.", "error")
        return
    end
    
    -- Now show the wash type options
    ShowWashTypeMenu(stackCount, locationIndex)
end

-- New function to show wash type menu after selecting stack amount
function ShowWashTypeMenu(stackCount, locationIndex)
    local location = Config.MoneyWash.locations[locationIndex]
    
    -- Create options menu for wash type
    local options = {}
    for _, option in ipairs(location.options) do
        -- Calculate estimated earnings to display in the menu
        local estimatedValue = math.floor((Config.Reward.cash_prop_value * stackCount * option.rate * 1.05))
        
        table.insert(options, {
            title = option.label,
            description = string.format('Wash %d %s for ~$%s', 
                stackCount, 
                stackCount == 1 and "stack" or "stacks", 
                FormatNumber(estimatedValue)),
            icon = option.type == 'cash' and 'fa-solid fa-money-bill-wave' or 'fa-solid fa-building-columns',
            onSelect = function()
                StartMoneyWash(stackCount, option.type, locationIndex)
            end,
            metadata = {
                {label = 'Return Rate', value = math.floor(option.rate * 100) .. '%'},
                {label = 'Estimated Value', value = '$' .. FormatNumber(estimatedValue)}
            }
        })
    end
    
    lib.registerContext({
        id = 'money_wash_options',
        title = 'Select Washing Method',
        menu = 'money_wash_stacks', -- Back button will go to stack selection
        options = options
    })
    
    lib.showContext('money_wash_options')
end

-- Helper function to format numbers with commas for thousands
function FormatNumber(number)
    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1,")
    return minus .. int:reverse():gsub("^,", "") .. fraction
end

-- Function to start the money washing process
function StartMoneyWash(stackCount, washType, locationIndex)
    local location = Config.MoneyWash.locations[locationIndex]
    
    -- Find the correct rate for this wash type
    local rate = 0.75 -- Default rate
    for _, option in ipairs(location.options) do
        if option.type == washType then
            rate = option.rate
            break
        end
    end
    
    -- Start washing progress
    SendNotification("Washing " .. stackCount .. " stacks of marked bills...", "primary")
    
    if lib.progressBar({
        duration = location.washTime * 1000,
        label = 'Washing money...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'mp_common',
            clip = 'givetake2_a'
        },
    }) then
        -- Completed successfully
        TriggerServerEvent('mns-atmrobbery:server:washMoney', stackCount, washType, rate)
    else
        -- Cancelled
        SendNotification("Money washing cancelled.", "error")
    end
end

-- Function to send notifications based on config
function SendNotification(message, type)
    if Config.Notify == 'ox' then
        lib.notify({
            title = 'Money Washing',
            description = message,
            type = type
        })
    elseif Config.Notify == 'qb' then
        QBCore.Functions.Notify(message, type)
    elseif Config.Notify == 'esx' then
        ESX.ShowNotification(message)
    elseif Config.Notify == 'okok' then
        exports['okokNotify']:Alert("Money Washing", message, 5000, type)
    elseif Config.Notify == 'wasabi' then
        TriggerEvent('wasabi_notify:custom', {
            title = "Money Washing",
            message = message,
            type = type,
            icon = "💸"
        })
    elseif Config.Notify == 'custom' then
        -- Add your custom notification here
        print("[Money Wash] " .. message)
    end
end

-- Setup target zones for money washing
local function SetupMoneyWashTargets()
    if not Config.MoneyWash.enabled then return end
    
    if Config.Target == "qb-target" then
        for i, location in ipairs(Config.MoneyWash.locations) do
            exports['qb-target']:AddCircleZone("moneywash_" .. i, vector3(location.coords.x, location.coords.y, location.coords.z), 1.0, {
                name = "moneywash_" .. i,
                debugPoly = false,
            }, {
                options = {
                    {
                        icon = "fas fa-money-bill-wave",
                        label = "Wash Money",
                        action = function()
                            OpenWashingMenu(i)
                        end,
                    },
                },
                distance = 2.0
            })
        end
    elseif Config.Target == "ox-target" then
        for i, location in ipairs(Config.MoneyWash.locations) do
            exports['ox_target']:addSphereZone({
                coords = location.coords,
                radius = 1.0,
                debug = false,
                options = {
                    {
                        name = 'money_wash',
                        icon = 'fa-solid fa-money-bill-wave',
                        label = 'Wash Money',
                        onSelect = function()
                            OpenWashingMenu(i)
                        end,
                        distance = 2.0
                    }
                }
            })
        end
    end
end

-- Initialize money washing system
CreateThread(function()
    Wait(1000) -- Wait for resources to load
    CreateWashingBlips()
    SetupMoneyWashTargets()
end)