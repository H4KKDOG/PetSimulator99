repeat
    task.wait()
until game:IsLoaded()
if game.PlaceId ~= ps99 and game.PlaceId ~= 16498369169 and game.PlaceId ~= 17503543197 then
    return
end

if getgenv().Executed then return end
getgenv().Executed = true

-- Compatibility Check
local function checkFunctions()
    local functionNames = ""
    if not isfile then
        functionNames = functionNames.."isfile "
    end
    if not writefile then
        functionNames = functionNames.."writefile "
    end
    if not readfile then
        functionNames = functionNames.."readfile "
    end
    if not isfolder then
        functionNames = functionNames.."isfolder "
    end
    if not makefolder then
        functionNames = functionNames.."makefolder "
    end
    if not cloneref then
        functionNames = functionNames.."cloneref "
    end
    if not setclipboard then
        functionNames = functionNames.."setclipboard "
    end
    if not identifyexecutor then
        functionNames = functionNames.."identifyexecutor "
    end
    return functionNames
end

local function output(text: string, type: string)
    local outputTag = "[@stupidzero.] "
    type = type or "print"
    pcall(function()
        if type == "print" then
            print(outputTag..text)
        elseif type == "warn" then
            warn(outputTag..text)
        elseif type == "error" then
            error(outputTag..text)
        end
    end)
end

local missingFunctions = checkFunctions()
if missingFunctions ~= "" then
    return output("Missing: "..missingFunctions, "error")
end

-- Variables
local LocalPlayer = game.Players.LocalPlayer
local HumanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart", true)

local VirtualUser = cloneref(game:GetService("VirtualUser"))
local HttpService = cloneref(game:GetService("HttpService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Network = ReplicatedStorage.Network

local Workspace = cloneref(game:GetService("Workspace"))
local Things = Workspace["__THINGS"]
local Instances = Things.Instances
local instanceContainer = Things["__INSTANCE_CONTAINER"]
local Lootbags = Things.Lootbags
local Orbs = Things.Orbs
local Breakables = Things.Breakables

LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false

if getconnections then
    for _,connection in getconnections(LocalPlayer.Idled) do
        if connection["Disable"] then
            connection["Disable"](connection)
        elseif connection["Disconnect"] then
            connection["Disconnect"](connection)
        end
    end
end

local function getMap()
    local rValue
    for _,map in ipairs(Workspace:GetChildren()) do
        if map.Name:find("Map") then
            rValue = map
            break
        end
    end
    return rValue
end

local Map
if getMap() then
    Map = getMap()
else
    task.spawn(function()
        repeat
            task.wait()
        until getMap()
        Map = getMap()
    end)
end

getgenv().start = false
getgenv().start = true

-- Configuration File
getgenv().config = getgenv().config
local isFirstTime = false
local configTemplate = {
    farmSettings = {
        breakObjects = false,
        singleTarget = false,
        breakRadius = 150,
        waitTime = 0.1,
        collectOrbs = false,
		collectLootbags = false
    },
    eggSettings = {
		eventEggs = false,
        openEggs = false,
        selectedEgg = "None",
        openAmount = 1
    },
    rewardSettings = {
        collectTimeRewards = false
    },
    miscSettings = {
        antiAFK = false
    }
}

if not isfolder("ShiroConfig") then
    isFirstTime = true
    makefolder("ShiroConfig")
end

if not isfile("ShiroConfig/ps99.config") then
    isFirstTime = true
    writefile("ShiroConfig/ps99.config", "")
end

if isFirstTime then
    local encodedConfig = HttpService:JSONEncode(configTemplate)
    writefile("ShiroConfig/ps99.config", encodedConfig)
end

local function loadConfig()
    local decodedConfig = HttpService:JSONDecode(readfile("ShiroConfig/ps99.config"))
    getgenv().config = decodedConfig
end

local function updateConfig()
    local encodedConfig = HttpService:JSONEncode(getgenv().config)
    writefile("ShiroConfig/ps99.config", encodedConfig)
end

loadConfig()

-- Tables
getgenv().coinQueue = {}
local PS99Info = loadstring(game:HttpGet("https://raw.githubusercontent.com/H4KKDOG/PetSimulator99/main/World/"..Map.Name..".lua"))()
local eggs = PS99Info.Eggs

-- Misc Functions
local function getNames(tbl)
    local returnTable = {}
    for _,info in tbl do
        if typeof(info) == "table" then
            table.insert(returnTable, info.Name)
        elseif typeof(info) == "string" then
            table.insert(returnTable, info)
        end
    end
    return returnTable
end

local function findInTable(tbl, name)
    for index,info in tbl do
        if typeof(info) == "table" and info.Name == name then
            return tbl[index]
        elseif typeof(info) == "string" and info == name then
            return tbl[index]
        end
        if info.Name == name then
            return tbl[index]
        end
    end
    return nil
end

local function Fire(name, args)
    if Network:FindFirstChild(name) then
        Network[name]:FireServer(unpack(args))
    end
end

local function Invoke(name, args)
    if Network:FindFirstChild(name) then
        Network[name]:InvokeServer(unpack(args))
    end
end

local function XZDist(obj1, obj2)
    local PosX1, PosZ1 = obj1.CFrame.X, obj1.CFrame.Z
    local PosX2, PosZ2 = obj2.CFrame.X, obj2.CFrame.Z
    return math.sqrt(math.pow(PosX1 - PosX2, 2) + math.pow(PosZ1 - PosZ2, 2))
end

local function clickPosition(x,y)
    VirtualUser:Button1Down(Vector2.new(x,y))
    VirtualUser:Button1Up(Vector2.new(x,y))
end

local function findNearestBreakable()
    local nearestBreakable
    local nearestDistance = 9e9
    for _, breakable in ipairs(Breakables:GetChildren()) do
        if breakable:FindFirstChildWhichIsA("MeshPart") then
            local meshPart = breakable:FindFirstChildWhichIsA("MeshPart")
            local distance = (HumanoidRootPart.Position - meshPart.Position).magnitude
            if distance < nearestDistance then
                nearestBreakable = breakable
                nearestDistance = distance
            end
        end
    end
    return nearestBreakable
end

local function isBreakableInRadius(breakable)
    if breakable:FindFirstChild("Hitbox", true) and XZDist(breakable:FindFirstChild("Hitbox", true), HumanoidRootPart) <= config.farmSettings.breakRadius then
        return true
    end
    return false
end

function find_nearest_egg()
    local nearest, nearest_distance = nil, math.huge
    if Things:FindFirstChild("CustomEggs") then
      for _,v in Things.CustomEggs:GetChildren() do
         if not v:IsA("Model") then continue end
         local dist = (LocalPlayer.Character.HumanoidRootPart.Position - v.PrimaryPart.Position).Magnitude
         if dist > nearest_distance then continue end
         nearest = v.Name
         nearest_distance = dist
      end
   end
   return nearest
end

-- Looped Functions
local doingQueue = false
local farmBreakablesDebounce = false
local collectLootbagsDebounce = false
local collectOrbsDebounce = false
local farmEggsDebounce = false
local collectTimeRewardsDebounce = false
local collectStarterWheelTicketDebounce = false
local antiAFKDebounce = false
local nearEggDebounce = false

local function farmBreakables()
    if config.farmSettings.breakObjects and not farmBreakablesDebounce then
        farmBreakablesDebounce = true
        local breakable = findNearestBreakable()
        if config.farmSettings.singleTarget then
            repeat
                task.wait(config.farmSettings.waitTime)
                Fire("Breakables_PlayerDealDamage", {breakable.Name})
            until not Breakables:FindFirstChild(breakable.Name) or not isBreakableInRadius(breakable) or not config.farmSettings.breakObjects or not config.farmSettings.singleTarget
        else
            if not table.find(coinQueue, breakable.Name) then
                table.insert(coinQueue, breakable.Name)
                task.spawn(function()
                    repeat
                        task.wait()
                    until not Breakables:FindFirstChild(breakable) or not isBreakableInRadius(breakable) or config.farmSettings.singleTarget or not config.farmSettings.breakObjects
                    table.remove(coinQueue, table.find(coinQueue, breakable))
                end)
            end
            task.spawn(function()
                if not doingQueue then
                    doingQueue = true
                    for _,currentCoin in ipairs(coinQueue) do
                        Fire("Breakables_PlayerDealDamage", {currentCoin})
                        task.wait(config.farmSettings.waitTime)
                    end
                    doingQueue = false
                end
            end)
        end
        farmBreakablesDebounce = false
    end
end

local function collectLootbags()
    if config.farmSettings.collectLootbags and not collectLootbagsDebounce then
        collectLootbagsDebounce = true
        local lootbags = {}
        for _, lootbag in ipairs(Lootbags:GetChildren()) do
            if not config.farmSettings.collectLootbags then break end
            lootbags[lootbag.Name] = lootbag.Name
            lootbag:Destroy()
        end
        Fire("Lootbags_Claim", {lootbags})
        collectLootbagsDebounce = false
    end
end

local function collectOrbs()
    if config.farmSettings.collectOrbs and not collectOrbsDebounce then
        collectOrbsDebounce = true
        local orbs = {}
        for _, orb in ipairs(Orbs:GetChildren()) do
            if not config.farmSettings.collectOrbs then break end
            table.insert(orbs, tonumber(orb.Name))
            orb:Destroy()
        end
        Fire("Orbs: Collect", {orbs})
        collectOrbsDebounce = false
    end
end

local function farmEggs()
    if config.eggSettings.openEggs and not farmEggsDebounce then
        farmEggsDebounce = true
        local splitName = string.split(config.eggSettings.selectedEgg, " | ")
        Invoke("Eggs_RequestPurchase",{splitName[2], config.eggSettings.openAmount})
        task.wait(0.4)
        repeat
            task.wait()
            clickPosition(math.huge,math.huge)
        until not Workspace.Camera:FindFirstChild("Eggs") or not config.eggSettings.openEggs
        task.wait(0.75)
        farmEggsDebounce = false
    end
end

local function collectTimeRewards()
    if config.rewardSettings.collectTimeRewards and not collectTimeRewardsDebounce then
        collectTimeRewardsDebounce = true
        for i=1,12 do
            Invoke("Redeem Free Gift", {i})
        end
        collectTimeRewardsDebounce = false
    end
end

local function collectStarterWheelTicket()
    if config.rewardSettings.collectSpinnerTicket and not collectStarterWheelTicketDebounce then
        collectStarterWheelTicketDebounce = true
        Fire("Spinny Wheel: Request Ticket", {"StarterWheel"})
        collectStarterWheelTicketDebounce = false
    end
end

local function oeventEggs()
    if config.eggSettings.eventEggs and not nearEggDebounce then
        nearEggDebounce = true
        Invoke("CustomEggs_Hatch",{find_nearest_egg(), config.eggSettings.openAmount})
        task.wait(0.4)
        repeat
            task.wait()
            clickPosition(math.huge,math.huge)
        until not Workspace.Camera:FindFirstChild("Eggs") or not config.eggSettings.eventEggs
        task.wait(0.75)
        nearEggDebounce = false
    end
end

local function antiAFK()
    if config.miscSettings.antiAFK and not antiAFKDebounce then
        antiAFKDebounce = true
        LocalPlayer.Character.Humanoid:ChangeState(3)
        task.wait(math.random(120,180))
        antiAFKDebounce = false
    end
end

-- Ui Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "Pet Simulator 99 (Solara)",
    SubTitle = "by @stupidzero.",
    TabWidth = 150,
    Size = UDim2.fromOffset(550, 450),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "circle" }),
	Egg = Window:AddTab({ Title = "Egg", Icon = "circle" }),
	Misc = Window:AddTab({ Title = "Misc", Icon = "circle" })
}

local Options = Fluent.Options

do
    Tabs.Main:AddParagraph({
        Title = "Why Less Function?",
        Content = "to be able to use in Solara"
    })
	
	Tabs.Main:AddButton({
        Title = "Rejoin",
        Description = "Rejoin Current Server/Game",
        Callback = function()
            Window:Dialog({
                Title = "Rejoin",
                Content = "",
                Buttons = {
                    {
                        Title = "Confirm",
                        Callback = function()
                            game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                        end
                    },
                    {
                        Title = "Cancel",
                        Callback = function()
                            print("Cancelled")
                        end
                    }
                }
            })
        end
    })

    Tabs.Main:AddParagraph({
        Title = "Breakables",
        Content = "(Tap) Farm Breakables"
    })
	
	local Toggle1 = Tabs.Main:AddToggle("Breakable", {Title = "Auto Tap Breakable", Default = config.farmSettings.breakObjects })
    Toggle1:OnChanged(function(Breakable)
        config.farmSettings.breakObjects = Breakable
		updateConfig()
    end)
	
	local Toggle2 = Tabs.Main:AddToggle("Target", {Title = "Single Target", Default = config.farmSettings.singleTarget })
    Toggle2:OnChanged(function(Target)
        config.farmSettings.singleTarget = Target
		updateConfig()
    end)
	
	local Input1 = Tabs.Main:AddInput("Radius", {
        Title = "Tap Radius",
        Default = config.farmSettings.breakRadius,
        Placeholder = "Placeholder",
        Numeric = true,
        Finished = false,
    })
    Input1:OnChanged(function(Radius)
        config.farmSettings.breakRadius = Radius
		updateConfig()
    end)
	
	local Input2 = Tabs.Main:AddInput("Delay", {
        Title = "Tap Delay",
        Default = config.farmSettings.waitTime,
        Placeholder = "Placeholder",
        Numeric = true,
        Finished = false,
    })
    Input2:OnChanged(function(Delay)
        config.farmSettings.waitTime = Delay
		updateConfig()
    end)
	
	Tabs.Main:AddParagraph({
        Title = "Magnet/Drops",
        Content = "Auto Collect Orbs and Lootbags"
    })
	
	local Toggle3 = Tabs.Main:AddToggle("Orbs", {Title = "Auto Collect Orbs", Default = config.farmSettings.collectOrbs })
    Toggle3:OnChanged(function(Orbs)
        config.farmSettings.collectOrbs = Orbs
		updateConfig()
    end)
	
	local Toggle4 = Tabs.Main:AddToggle("Lootbags", {Title = "Auto Collect Lootbags", Default = config.farmSettings.collectLootbags })
    Toggle4:OnChanged(function(Lootbags)
        config.farmSettings.collectLootbags = Lootbags
		updateConfig()
    end)
	
	Tabs.Egg:AddParagraph({
        Title = "Egg",
        Content = "You must be near eggs to Hatch"
    })
	
	local Dropdown1 = Tabs.Egg:AddDropdown("Select", {
        Title = "Select Egg",
        Values = eggs,
        Multi = false,
        Default = config.eggSettings.selectedEgg,
    })
	Dropdown1:OnChanged(function(Select)
        config.eggSettings.selectedEgg = Select
		updateConfig()
    end)
	
	local Input3 = Tabs.Egg:AddInput("Amount", {
        Title = "Egg Amount",
        Default = config.eggSettings.openAmount,
        Placeholder = "Placeholder",
        Numeric = true,
        Finished = false,
    })
    Input3:OnChanged(function(Amount)
        config.eggSettings.openAmount = Amount
    end)
	
	local Toggle5 = Tabs.Egg:AddToggle("Hatch", {Title = "Start Auto Hatch", Default = config.eggSettings.openEggs })
    Toggle5:OnChanged(function(Hatch)
        config.eggSettings.openEggs = Hatch
		updateConfig()
    end)
	
	Tabs.Egg:AddParagraph({
        Title = "Event Egg",
        Content = "Hatch Event/Custom Egg"
    })
	
	local Toggle6 = Tabs.Egg:AddToggle("Event", {Title = "Nearest Event Egg Auto Hatch", Default = config.eggSettings.eventEggs })
    Toggle6:OnChanged(function(Event)
        config.eggSettings.eventEggs = Event
		updateConfig()
    end)

    Tabs.Misc:AddParagraph({
        Title = "Gift",
        Content = "Claim Gift/Time Reward"
    })

    local Toggle7 = Tabs.Egg:AddToggle("Gift", {Title = "Auto Claim Gift/Reward", Default = config.rewardSettings.collectTimeRewards })
    Toggle7:OnChanged(function(Gift)
        config.rewardSettings.collectTimeRewards = Gift
		updateConfig()
    end)

    local Toggle8 = Tabs.Egg:AddToggle("AFK", {Title = "Anti AFK", Default = config.miscSettings.antiAFK })
    Toggle8:OnChanged(function(AFK)
        config.miscSettings.antiAFK = AFK
		updateConfig()
    end)
end

while task.wait() and getgenv().start do
    task.spawn(farmBreakables)
    task.spawn(collectLootbags)
    task.spawn(collectOrbs)
    task.spawn(farmEggs)
    task.spawn(collectTimeRewards)
    task.spawn(oeventEggs)
    task.spawn(antiAFK)
end
