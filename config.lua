Config = {}

-- Item names for hacking and drilling
Config.HackingItem = 'electronickit'  -- Set the hacking item to electronickit
Config.DrillItem = 'drill'  -- Setting a default drill item name to fix the drilling functionality

-- Enable or disable ATM robbery actions (hacking and drilling)
Config.EnableHacking = true  -- Set to true to enable ATM hacking
Config.EnableDrilling = true  -- Set to true to enable ATM drilling

-- If you disable this the cash will not be dropped on the ground and will be added to your inventory directly
Config.MoneyDrop = true

Config.AtmModels = {'prop_fleeca_atm', 'prop_atm_01', 'prop_atm_02', 'prop_atm_03'}

Config.Notify = 'ox' --ox, esx, okok,qb,wasabi,custom

Config.Target = 'ox-target' --qb-target, ox-target

Config.Hacking = {
    Minigame = 'ox_lib', --utk_fingerprint, ox_lib
    InitialHackDuration = 2000, --2 seconds
    LootAtmDuration = 20000, --20 seconds
    RewardMultiplier = 1.0, -- Default multiplier for hacking reward (1.0 = standard reward)
    MinReward = 80,  -- Minimum amount per cash pile when hacking
    MaxReward = 120  -- Maximum amount per cash pile when hacking (adds randomness)
}

Config.Drilling = {
    Duration = 25000, -- 25 seconds drilling time (increased from 15s)
    Animation = {
        Dict = "anim@heists@fleeca_bank@drilling",
        Clip = "drill_straight_idle"
    },
    RewardMultiplier = 1.5, -- Higher multiplier for drilling reward (50% more than hacking)
    MinReward = 150,  -- Minimum amount per cash pile when drilling
    MaxReward = 200   -- Maximum amount per cash pile when drilling (adds randomness)
}

Config.CooldownTimer = 60 -- default 10 minutes | 60 = 1 minute

Config.Reward = {
    -- The account type where the reward is credited. Can be:
    -- 'bank' for bank account, 'cash' for cash in hand, or 'dirty' for dirty money.
    account = 'dirty',  
    -- The base value of each cash pile (in game currency).
    -- This is the default value, actual value will be modified by the min/max ranges above
    cash_prop_value = 100,  
    -- The total reward value for completing the robbery.
    -- This value is used when 'MoneyDrop' is false and determines the total reward.
    reward = 1000,  
    -- The number of cash piles that will be dropped during the hack action.
    hack_cash_pile = 10,  
    -- The number of cash piles that will be dropped during the drill action.
    drill_cash_pile = 8,  -- Increased from 5 to 8
    -- The name of the marked money item that's given from ATM robberies
    dirty_money_item = 'markedbills',
    -- Advanced reward settings
    UseRandomAmounts = true,  -- If true, cash pile values will vary between Min/Max ranges
    DrillHasHigherChance = true, -- If true, drilling has a higher chance of getting max values
    -- Stack settings for marked bills
    StackSize = 10,  -- Maximum number of marked bills in one inventory slot
    -- New setting to handle quantity-based item stacks
    UseItemQuantity = true, -- Set to true to count the quantity of items in a stack instead of just counting slots
}

Config.Police = {
    notify = true,
    required = 0,
    Job = {'police'},
}

--default for inbuilt
--ps for ps-dispatch
--aty for aty_disptach
--qs for qausar dispatch
--rcore for rcore dispatch
--custom for your own
Config.Dispatch = 'default'

-- Money washing configuration
Config.MoneyWash = {
    enabled = true,
    locations = {
        -- Original location inside the drug lab interior
        {
            coords = vector3(1122.35, -3194.48, -40.4),
            blip = {
                enabled = true,
                sprite = 500,  -- Money washing icon
                color = 25,    -- Purple color
                scale = 0.7,
                label = "Money Laundering"
            },
            washRate = 0.85,   -- Increased from 0.75 to 0.85 (85% return)
            washTime = 30,     -- Time in seconds to wash money (30 seconds)
            minWashAmount = 1000,  -- Minimum amount that can be washed at once
            maxWashAmount = 50000, -- Maximum amount that can be washed at once
            cooldown = 0,      -- Set to 0 to remove cooldown
            options = {
                {
                    type = "cash",   -- Cash option gives physical cash
                    label = "Cash",
                    rate = 0.85      -- Increased from 0.75 to 0.85 (85% return)
                },
                {
                    type = "bank",   -- Bank option deposits to bank account
                    label = "Bank Transfer",
                    rate = 0.90      -- Increased from 0.80 to 0.90 (90% return)
                }
            }
        },
        
        -- New location at Mirror Park
        {
            coords = vector3(1136.08, -990.75, 46.11),
            heading = 94.4,
            blip = {
                enabled = true,
                sprite = 500,  -- Money washing icon
                color = 25,    -- Purple color
                scale = 0.7,
                label = "Mirror Park Laundry"
            },
            washRate = 0.80,   -- Increased from 0.70 to 0.80 (80% return)
            washTime = 40,     -- Time in seconds to wash money (40 seconds)
            minWashAmount = 500,   -- Lower minimum amount
            maxWashAmount = 30000, -- Lower maximum amount
            cooldown = 0,      -- Set to 0 to remove cooldown
            options = {
                {
                    type = "cash",   -- Cash option gives physical cash
                    label = "Cash",
                    rate = 0.80      -- Increased from 0.70 to 0.80 (80% return)
                },
                {
                    type = "bank",   -- Bank option deposits to bank account
                    label = "Bank Transfer",
                    rate = 0.85      -- Increased from 0.75 to 0.85 (85% return)
                }
            }
        }
    }
}

-- Debug settings
Config.Debug = false -- Set to true to enable debug prints


