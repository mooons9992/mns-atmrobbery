# ATM Robbery Script for FiveM

## Overview

A comprehensive ATM robbery system featuring two distinct robbery methods: drilling and hacking. Players can strategically choose their approach to each robbery and receive marked bills that can be laundered into clean money.

![ATM Robbery](https://i.imgur.com/example.jpg)

## Features

### Multiple Robbery Methods
- **Drilling**: Physically break into ATMs with a drill tool
- **Hacking**: Use a hacking device to electronically compromise ATMs

### Advanced Money System
- Rewards players with marked bills
- Configurable reward amounts based on robbery method
- Randomized reward values for unpredictable payouts

### Money Laundering
- Convert marked bills to clean cash or bank transfers
- Multiple laundering locations with different rates and options
- Sliding scale UI to select the number of stacks to launder

### Immersive Effects
- Realistic drilling animations and particle effects
- Sound effects for drilling and successful breakthroughs
- Advanced money collection system

### Admin-Friendly Configuration
- Easily adjust police requirements
- Customize cooldown timers between robberies
- Configure reward rates and money washing options
- Compatible with multiple dispatch systems

## Dependencies
- QBCore Framework
- ox_lib
- ESX Menu (Optional)

## Installation
1. Download the script and place it in your resources folder
2. Add `ensure mns-atmrobbery` to your server.cfg
3. Ensure all dependencies are installed and running
4. Configure the script settings in `config.lua`
5. Restart your server

## Configuration Options
The script is highly customizable through the `config.lua` file:

```lua
Config.Police = {
    notify = true,     -- Enable police notifications
    required = 0,      -- Minimum police required for robberies
    Job = {'police'},  -- Jobs that count as police
}

Config.MoneyWash = {
    enabled = true,
    locations = {
        -- Washing locations with custom rates and options
    }
}
```

## Items Required
The script requires the following items to be added to your items.lua:

```lua
["drill"] = {
    ["name"] = "drill",
    ["label"] = "Drill",
    ["weight"] = 5000,
    ["type"] = "item",
    ["image"] = "drill.png",
    ["unique"] = false,
    ["useable"] = true,
    ["shouldClose"] = true,
    ["combinable"] = nil,
    ["description"] = "Used for drilling into things"
},
["electronickit"] = {
    ["name"] = "electronickit",
    ["label"] = "Electronic Kit",
    ["weight"] = 2000,
    ["type"] = "item",
    ["image"] = "electronickit.png",
    ["unique"] = false,
    ["useable"] = true,
    ["shouldClose"] = true,
    ["combinable"] = nil,
    ["description"] = "Kit used for hacking electronic systems"
}
```

## Usage

### Robbery
1. Approach any ATM in the world
2. Use a drill or hacking device from your inventory
3. Complete the robbery minigame
4. Collect your marked bills

### Money Laundering
1. Visit any money laundering location
2. Use the UI to select how many stacks to wash
3. Choose between cash or bank transfer options
4. Receive your cleaned money

## Dispatch Integration
The script supports multiple dispatch systems:
- Default QBCore
- QS Dispatch
- rCore Dispatch
- Custom Dispatch (configurable)

## Support
For support or feature requests, please contact us via:
- Discord: [Your Discord Server Link]
- GitHub Issues: [GitHub Repository Link]

## Credits
- Created by [Your Name/Team]
- Special thanks to contributors and testers