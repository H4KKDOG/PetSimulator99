repeat
    task.wait()
until game:IsLoaded()
if game.PlaceId ~= 8737899170 and game.PlaceId ~= 16498369169 and game.PlaceId ~= 17503543197 then
    return
end

if getgenv().Running then
    return
end
getgenv().Running = true

--// Function
local LocalPlayer = game.Players.LocalPlayer
local HumanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart", true)

local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage.Network

local Workspace = game:GetService("Workspace")
local Things = Workspace["__THINGS"]
local Instances = Things.Instances
local instanceContainer = Things["__INSTANCE_CONTAINER"]
local Lootbags = Things.Lootbags
local Orbs = Things.Orbs
local Breakables = Things.Breakables

LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false

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

if getconnections then
    for _, v in pairs(getconnections(LocalPlayer.Idled)) do
        v:Disable()
    end
end

for _, water in ipairs(Map:GetDescendants()) do
    if water:IsA("Folder") and water.Name == "Water Bounds" then
        water:Destroy()
    end
end

getgenv().cooking = false
getgenv().cooking = true
getgenv().coinQueue = {}
local PS99Info = loadstring(game:HttpGet("https://raw.githubusercontent.com/H4KKDOG/PetSimulator99/main/World/"..Map.Name..".lua"))()
local Eggs = PS99Info.Eggs

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

local function findNearestBreakable()
    local nearestBreakable
    local nearestDistance = math.huge
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
    if breakable:FindFirstChild("Hitbox", true) and XZDist(breakable:FindFirstChild("Hitbox", true), HumanoidRootPart) <= 150 then
        return true
    end
    return false
end

function find_nearest_egg()
    local nearest, nearest_distance = nil, 300
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

local doingQueue = false
local farmBreakablesDebounce = false
local collectLootbagsDebounce = false
local collectOrbsDebounce = false
local farmEggsDebounce = false
local collectTimeRewardsDebounce = false
local collectStarterWheelTicketDebounce = false
local antiAFKDebounce = false

local function TfarmBreakables()
    if breakObjects and not farmBreakablesDebounce then
        farmBreakablesDebounce = true
        local breakable = findNearestBreakable()
        if not table.find(coinQueue, breakable.Name) then
            table.insert(coinQueue, breakable.Name)
            task.spawn(function()
                repeat
                    task.wait()
                until not Breakables:FindFirstChild(breakable) or not isBreakableInRadius(breakable) or not breakObjects
                table.remove(coinQueue, table.find(coinQueue, breakable))
            end)
        end
        task.spawn(function()
            if not doingQueue then
                doingQueue = true
                for _,currentCoin in ipairs(coinQueue) do
                    Fire("Breakables_PlayerDealDamage", {currentCoin})
                    task.wait(0.1)
                end
                doingQueue = false
            end
        end)
    end
    farmBreakablesDebounce = false
end

local function TcollectLootbags()
    if collectLootbags and not collectLootbagsDebounce then
        collectLootbagsDebounce = true
        local lootbags = {}
        for _, lootbag in ipairs(Lootbags:GetChildren()) do
            if not collectLootbags then break end
            lootbags[lootbag.Name] = lootbag.Name
            lootbag:Destroy()
        end
        Fire("Lootbags_Claim", {lootbags})
        collectLootbagsDebounce = false
    end
end

local function TcollectOrbs()
    if collectOrbs and not collectOrbsDebounce then
        collectOrbsDebounce = true
        local orbs = {}
        for _, orb in ipairs(Orbs:GetChildren()) do
            if not collectOrbs then break end
            table.insert(orbs, tonumber(orb.Name))
            orb:Destroy()
        end
        Fire("Orbs: Collect", {orbs})
        collectOrbsDebounce = false
    end
end

local function TfarmEggs()
    if openEggs and not farmEggsDebounce then
        farmEggsDebounce = true
        local splitName = string.split(EggName, " | ")
        Network:WaitForChild("Eggs_RequestPurchase"):InvokeServer(splitName[2], openAmount)
        task.wait(0.25)
        farmEggsDebounce = false
    end
end

local function TeventEggs()
    if openeventEggs and not nearEggsDebounce then
        nearEggsDebounce = true
        Network:WaitForChild("CustomEggs_Hatch"):InvokeServer(find_nearest_egg(), openAmount)
        task.wait(0.25)
        nearEggsDebounce = false
    end
end

local function TcollectTimeRewards()
    if collectTimeRewards and not collectTimeRewardsDebounce then
        collectTimeRewardsDebounce = true
        for i=1,12 do
            Invoke("Redeem Free Gift", {i})
        end
        collectTimeRewardsDebounce = false
    end
end

local function TantiAFK()
    if antiAFK and not antiAFKDebounce then
        antiAFKDebounce = true
        LocalPlayer.Character.Humanoid:ChangeState(3)
        task.wait(math.random(180,360))
        antiAFKDebounce = false
    end
end

--// Ui
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "PS99 (Solara Edition)", HidePremium = true, SaveConfig = true, ConfigFolder = "ps99config"})

OrionLib:MakeNotification({
	Name = "@stupidzero.",
	Content = "PS99 Script for Solara",
	Image = "rbxassetid://4483345998",
	Time = 5
})

local Tab = Window:MakeTab({
	Name = "Main",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local Section = Tab:AddSection({ Name = "Farm" })

Tab:AddToggle({
	Name = "Auto Tap Breakable",
	Default = false,
    Save = true,
    Flag = "abreak",
	Callback = function(Value)
        breakObjects = Value
        if not breakObjects then
            table.clear(coinQueue)
        end
	end    
})

Tab:AddToggle({
	Name = "Auto Collect Orbs",
	Default = false,
    Save = true,
    Flag = "ccoin",
	Callback = function(Value)
		collectOrbs = Value
	end    
})

Tab:AddToggle({
	Name = "Auto Collect Lootbags",
	Default = false,
    Save = true,
    Flag = "aloot",
	Callback = function(Value)
		collectLootbags = Value
	end    
})

local Section = Tab:AddSection({ Name = "Egg" })

Tab:AddDropdown({
	Name = "Select Egg",
	Default = "None",
    Save = true,
    Flag = "eggsel",
	Options = Eggs,
	Callback = function(Value)
		EggName = Value
	end    
})

Tab:AddSlider({
	Name = "Egg Amount",
	Min = 1,
	Max = 99,
	Default = 1,
    Save = true,
    Flag = "eggamo",
	Color = Color3.fromRGB(250,250,255),
	Increment = 1,
	ValueName = "Egg",
	Callback = function(Value)
		openAmount = Value
	end    
})

Tab:AddToggle({
	Name = "Start Auto Hatch",
	Default = false,
    Save = true,
    Flag = "ahatch",
	Callback = function(Value)
		openEggs = Value
	end    
})

local Section = Tab:AddSection({ Name = "Event" })

Tab:AddToggle({
	Name = "Nearest Egg Auto Hatch (Event)",
	Default = false,
    Save = true,
    Flag = "eventnear",
	Callback = function(Value)
		openeventEggs = Value
	end    
})

local Section = Tab:AddSection({ Name = "Misc" })

Tab:AddToggle({
	Name = "Auto Claim Gift Bag",
	Default = false,
    Save = true,
    Flag = "reward",
	Callback = function(Value)
		collectTimeRewards = Value
	end    
})

Tab:AddToggle({
	Name = "Anti AFK",
	Default = false,
    Save = true,
    Flag = "afk",
	Callback = function(Value)
		antiAFK = Value
	end    
})

local Section = Tab:AddSection({ Name = "Server" })

Tab:AddButton({
	Name = "Rejoin Game",
	Callback = function()
      	game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
  	end    
})

while task.wait() and getgenv().cooking do
    task.spawn(TfarmBreakables)
    task.spawn(TcollectLootbags)
    task.spawn(TcollectOrbs)
    task.spawn(TfarmEggs)
    task.spawn(TcollectTimeRewards)
    task.spawn(TantiAFK)
    task.spawn(TeventEggs)
end

OrionLib:Init()
