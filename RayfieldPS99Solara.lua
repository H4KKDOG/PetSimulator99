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

getgenv().cooking = false
getgenv().cooking = true

getgenv().config = getgenv().config
local isFirstTime = false
local configTemplate = {
    farmSettings = {
        breakObjects = false,
        buyZones = false,
        collectOrbs = false,
        collectLootbags = false,
    },
    eggSettings = {
        openEggs = false,
        openeventEggs = false,
        EggName = "World/Area Egg Only",
        openAmount = 1
    },
    rewardSettings = {
        collectTimeRewards = false,
    },
    miscSettings = {
        antiAFK = false,
    }
}

if not isfolder("ps99 configs") then
    isFirstTime = true
    makefolder("ps99 configs")
end
if not isfile("ps99 configs/12345.config") then
    isFirstTime = true
    writefile("ps99 configs/12345.config", "")
end

if isFirstTime then
    local encodedConfig = HttpService:JSONEncode(configTemplate)
    writefile("ps99 configs/12345.config", encodedConfig)
end

local function loadConfig()
    local decodedConfig = HttpService:JSONDecode(readfile("ps99 configs/12345.config"))
    getgenv().config = decodedConfig
end
local function updateConfig()
    local encodedConfig = HttpService:JSONEncode(getgenv().config)
    writefile("ps99 configs/12345.config", encodedConfig)
end

loadConfig()

getgenv().coinQueue = {}

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

local function farmBreakables()
    if config.farmSettings.breakObjects and not farmBreakablesDebounce then
        farmBreakablesDebounce = true
        local breakable = findNearestBreakable()
        if not table.find(coinQueue, breakable.Name) then
            table.insert(coinQueue, breakable.Name)
            task.spawn(function()
                repeat
                    task.wait()
                until not Breakables:FindFirstChild(breakable) or not isBreakableInRadius(breakable) or not config.farmSettings.breakObjects
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
        Network:WaitForChild("Eggs_RequestPurchase"):InvokeServer(config.eggSettings.EggName, config.eggSettings.openAmount)
        task.wait(0.25)
        farmEggsDebounce = false
    end
end

local function eventEggs()
    if config.eggSettings.openeventEggs and not nearEggsDebounce then
        nearEggsDebounce = true
        Network:WaitForChild("CustomEggs_Hatch"):InvokeServer(find_nearest_egg(), config.eggSettings.openAmount)
        task.wait(0.25)
        nearEggsDebounce = false
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

local function antiAFK()
    if config.miscSettings.antiAFK and not antiAFKDebounce then
        antiAFKDebounce = true
        LocalPlayer.Character.Humanoid:ChangeState(3)
        task.wait(math.random(180,360))
        antiAFKDebounce = false
    end
end

--// Ui
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "PS99 (SolaraVersion)",
   LoadingTitle = "PS99 Solara",
   LoadingSubtitle = "by @stupidzero.",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "ps99settings"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false,
   KeySettings = {
      Title = "Loader",
      Subtitle = "Key System",
      Note = "github.com/H4KKDOG",
      FileName = "ps99key",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"ps99"}
   }
})

local Tab = Window:CreateTab("Main      ", 0)

local Section = Tab:CreateSection("Farm")

local Toggle1 = Tab:CreateToggle({
   Name = "AutoTap Breakable",
   CurrentValue = config.farmSettings.breakObjects,
   Flag = "config.farmSettings.breakObjects", 
   Callback = function(value)
        config.farmSettings.breakObjects = value
        if not config.farmSettings.breakObjects then
            table.clear(coinQueue)
        end
   end,
})

local Toggle = Tab:CreateToggle({
   Name = "AutoCollect Orbs",
   CurrentValue = config.farmSettings.collectOrbs,
   Flag = "config.farmSettings.collectOrbs", 
   Callback = function(value)
        config.farmSettings.collectOrbs = value
        updateConfig()
   end,
})

local Toggle = Tab:CreateToggle({
   Name = "AutoCollet Lootbags",
   CurrentValue = config.farmSettings.collectLootbags,
   Flag = "config.farmSettings.collectLootbags", 
   Callback = function(value)
        config.farmSettings.collectLootbags = value
        updateConfig()
   end,
})

local Section = Tab:CreateSection("Egg")

local Input = Tab:CreateInput({
   Name = "EggName to Hatch",
   PlaceholderText = config.eggSettings.EggName,
   RemoveTextAfterFocusLost = false,
   Callback = function(eggPicked)
        print(eggPicked)
        config.eggSettings.EggName = eggPicked
        updateConfig()
   end,
})

local Input = Tab:CreateInput({
   Name = "EggAmount to Hatch",
   PlaceholderText = config.eggSettings.openAmount,
   RemoveTextAfterFocusLost = false,
   Callback = function(openamount)
        print(tonumber(openamount))
        config.eggSettings.openAmount = tonumber(openamount)
        updateConfig()
   end,
})

local Toggle = Tab:CreateToggle({
   Name = "Start AutoHatch",
   CurrentValue = config.eggSettings.openEggs,
   Flag = config.eggSettings.openEggs, 
   Callback = function(openegg)
        config.eggSettings.openEggs = openegg
        updateConfig()
   end,
})

local Section = Tab:CreateSection("Event")

local Toggle = Tab:CreateToggle({
   Name = "Nearest AutoHatch Event",
   CurrentValue = config.eggSettings.openeventEggs,
   Flag = config.eggSettings.openeventEggs, 
   Callback = function(nearegg)
        config.eggSettings.openeventEggs = nearegg
        updateConfig()
   end,
})

local Section = Tab:CreateSection("Misc")

local Toggle = Tab:CreateToggle({
   Name = "AutoOpen GiftBag",
   CurrentValue = config.rewardSettings.collectTimeRewards,
   Flag = "config.rewardSettings.collectTimeRewards", 
   Callback = function(value)
        config.rewardSettings.collectTimeRewards = value
        updateConfig()
        if not config.farmSettings.collectOrbs and not config.farmSettings.Lootbags then
            collectOrbs:SetValue(config.rewardSettings.collectTimeRewards)
            Lootbags:SetValue(config.rewardSettings.collectTimeRewards)
        end
   end,
})

local Toggle = Tab:CreateToggle({
   Name = "AntiAFK",
   CurrentValue = config.miscSettings.antiAFK,
   Flag = "config.miscSettings.antiAFK", 
   Callback = function(value)
        config.miscSettings.antiAFK = value
        updateConfig()

        LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false

        if getconnections then
            for _, v in pairs(getconnections(LocalPlayer.Idled)) do
                v:Disable()
            end
        else
            LocalPlayer.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
                task.wait()
                VirtualUser:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            end)
        end
   end,
})

local Button = Tab:CreateButton({
   Name = "Remove Water",
   Callback = function()
        for _, water in ipairs(Map:GetDescendants()) do
            if water:IsA("Folder") and water.Name == "Water Bounds" then
                water:Destroy()
            end
        end
   end,
})

local Section = Tab:CreateSection("Server")

local Button = Tab:CreateButton({
   Name = "Rejoin Server",
   Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
   end,
})

while task.wait() and getgenv().cooking do
    task.spawn(farmBreakables)
    task.spawn(collectLootbags)
    task.spawn(collectOrbs)
    task.spawn(farmEggs)
    task.spawn(collectTimeRewards)
    task.spawn(antiAFK)
    task.spawn(eventEggs)
end
