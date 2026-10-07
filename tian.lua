--========================================================--
-- SCRIPT TIAN v10 🚬
-- Steal an Egg | Final | Auto Carry + Rank Area
--========================================================--

_G.tian = _G.tian or {}
_G.tian.Settings = _G.tian.Settings or {}
_G.tian.Home = _G.tian.Home or nil
_G.tian.Stats = { eggs = 0, carried = 0 }

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "TIAN",
        Text = "tian v10 siap 🚬",
        Duration = 5
    })
end)

--========================================================--
-- CARI REMOTE PAKAI GETDESCENDANTS (ANTI GAGAL)
--========================================================--
local function findRemote(name)
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name == name and (obj:IsA("RemoteFunction") or obj:IsA("RemoteEvent")) then
            return obj
        end
    end
    return nil
end

local RF_EggCarry = findRemote("AskFieldEggCarry")
local RF_EggPlace = findRemote("AskPlaceEgg")

print("[TIAN] EggCarry:", RF_EggCarry and "OK" or "NIL")
print("[TIAN] EggPlace:", RF_EggPlace and "OK" or "NIL")

--========================================================--
-- AREA RANK
--========================================================--
local AREA_RANK = {
    ["Cosmic"] = 13, ["Titan Temple"] = 12, ["Abyss Ocean"] = 11,
    ["Prehistoric"] = 10, ["Volcano"] = 9, ["Cherry Blossom"] = 8,
    ["Enchanted Forest"] = 7, ["Snow"] = 6, ["Desert"] = 5,
    ["Jungle"] = 4, ["Lake"] = 3, ["Forest"] = 2, ["Light Dark"] = 1,
}

local function getAreaName(egg)
    local node = egg
    while node and node.Parent do
        node = node.Parent
        if AREA_RANK[node.Name] then return node.Name end
    end
    return "?"
end

--========================================================--
-- SCAN EGGS
--========================================================--
local function scanEggs()
    local list = {}
    local world = workspace:FindFirstChild("World")
    if not world then return list end
    local areas = world:FindFirstChild("Areas")
    if not areas then return list end
    local guard = areas:FindFirstChild("GuardAreas")
    if not guard then return list end

    for _, area in pairs(guard:GetChildren()) do
        local nests = area:FindFirstChild("Nests")
        if nests then
            for _, nest in pairs(nests:GetChildren()) do
                if nest.Name:find("NestModel") then
                    for _, egg in pairs(nest:GetChildren()) do
                        if egg:IsA("Model") and egg.Name == "Model" then
                            local part = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
                            if part then
                                list[#list+1] = {
                                    model = egg,
                                    area = area.Name,
                                    rank = AREA_RANK[area.Name] or 0,
                                    pos = part.Position,
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(list, function(a, b) return a.rank > b.rank end)
    _G.tian.Eggs = list
    _G.tian.Stats.eggs = #list
    return list
end

--========================================================--
-- FLY
--========================================================--
local bv, bg = nil, nil
local function startFly()
    if bv then bv:Destroy() end
    if bg then bg:Destroy() end
    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Parent = root
    bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.P = 1e4
    bg.Parent = root
end

local function stopFly()
    if bv then bv:Destroy() bv = nil end
    if bg then bg:Destroy() bg = nil end
    pcall(function() hum.PlatformStand = false end)
end

--========================================================--
-- CARRY ALL (teleport satu-satu)
--========================================================--
local carrying = false

local function carryAll()
    if carrying then return end
    carrying = true
    task.spawn(function()
        local eggs = scanEggs()
        print("[TIAN] carry:", #eggs, "eggs")
        local carried = 0
        for i, egg in ipairs(eggs) do
            if not carrying then break end
            if egg.pos then
                -- TELEPORT LANGSUNG
                root.CFrame = CFrame.new(egg.pos + Vector3.new(0, 6, 0))
                task.wait(0.15)
                if RF_EggCarry then
                    pcall(function() RF_EggCarry:InvokeServer(egg.model) end)
                    carried = carried + 1
                end
                task.wait(0.15)
            end
        end
        -- KE HOME
        if _G.tian.Home and RF_EggPlace then
            root.CFrame = CFrame.new(_G.tian.Home + Vector3.new(0, 6, 0))
            task.wait(0.3)
            pcall(function() RF_EggPlace:InvokeServer() end)
        end
        _G.tian.Stats.carried = carried
        carrying = false
        print("[TIAN] done:", carried)
    end)
end

--========================================================--
-- GUI
--========================================================--
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TianUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.AnchorPoint = Vector2.new(0, 0)
Main.Position = UDim2.new(0, 10, 0.2, 0)
Main.Size = UDim2.new(0, 340, 0, 400)
Main.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 28, 0, 28)
Logo.Position = UDim2.new(0, 8, 0.5, -14)
Logo.BackgroundColor3 = Color3.fromRGB(120, 70, 200)
Logo.Parent = Header
Instance.new("UICorner", Logo).CornerRadius = UDim.new(1, 0)

local LogoT = Instance.new("TextLabel")
LogoT.Size = UDim2.new(1, 0, 1, 0)
LogoT.BackgroundTransparency = 1
LogoT.Text = "T"
LogoT.TextColor3 = Color3.new(1,1,1)
LogoT.TextSize = 16
LogoT.Font = Enum.Font.GothamBold
LogoT.Parent = Logo

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 42, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "TIAN CENTER"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- HOME
local HomeLabel = Instance.new("TextLabel")
HomeLabel.Size = UDim2.new(1, -20, 0, 18)
HomeLabel.Position = UDim2.new(0, 10, 0, 46)
HomeLabel.BackgroundTransparency = 1
HomeLabel.Text = "HOME: -, -, -"
HomeLabel.TextColor3 = Color3.fromRGB(160, 200, 160)
HomeLabel.TextSize = 11
HomeLabel.Font = Enum.Font.Code
HomeLabel.TextXAlignment = Enum.TextXAlignment.Left
HomeLabel.Parent = Main

-- SPEED (visual only)
local SpeedFrame = Instance.new("Frame")
SpeedFrame.Size = UDim2.new(1, -20, 0, 28)
SpeedFrame.Position = UDim2.new(0, 10, 0, 68)
SpeedFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
SpeedFrame.BorderSizePixel = 0
SpeedFrame.Parent = Main
Instance.new("UICorner", SpeedFrame).CornerRadius = UDim.new(0, 6)

local SpeedLbl = Instance.new("TextLabel")
SpeedLbl.Size = UDim2.new(0, 60, 1, 0)
SpeedLbl.Position = UDim2.new(0, 8, 0, 0)
SpeedLbl.BackgroundTransparency = 1
SpeedLbl.Text = "SPEED:"
SpeedLbl.TextColor3 = Color3.fromRGB(200,200,200)
SpeedLbl.TextSize = 11
SpeedLbl.Font = Enum.Font.GothamBold
SpeedLbl.TextXAlignment = Enum.TextXAlignment.Left
SpeedLbl.Parent = SpeedFrame

local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(0, 100, 1, -8)
SpeedBox.Position = UDim2.new(0, 70, 0, 4)
SpeedBox.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
SpeedBox.Text = "5000"
SpeedBox.TextColor3 = Color3.fromRGB(255,255,255)
SpeedBox.TextSize = 12
SpeedBox.Font = Enum.Font.Code
SpeedBox.BorderSizePixel = 0
SpeedBox.Parent = SpeedFrame
Instance.new("UICorner", SpeedBox).CornerRadius = UDim.new(0, 4)

-- BUTTONS
local function makeBtn(text, xPos, color, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 78, 0, 26)
    Btn.Position = UDim2.new(0, xPos, 0, 102)
    Btn.BackgroundColor3 = color
    Btn.Text = text
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.TextSize = 11
    Btn.Font = Enum.Font.GothamBold
    Btn.BorderSizePixel = 0
    Btn.Parent = Main
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 5)
    Btn.MouseButton1Click:Connect(callback)
end

makeBtn("SET HOME", 10, Color3.fromRGB(40, 90, 150), function()
    _G.tian.Home = root.Position
    print("[TIAN] home set")
end)

makeBtn("SCAN", 92, Color3.fromRGB(40, 120, 60), function()
    scanEggs()
    print("[TIAN] scanned:", #_G.tian.Eggs)
end)

makeBtn("CARRY ALL", 174, Color3.fromRGB(150, 90, 30), function()
    carryAll()
end)

makeBtn("STOP", 256, Color3.fromRGB(140, 40, 40), function()
    carrying = false
    stopFly()
    print("[TIAN] stopped")
end)

-- STATS
local StatsLbl = Instance.new("TextLabel")
StatsLbl.Size = UDim2.new(1, -20, 0, 18)
StatsLbl.Position = UDim2.new(0, 10, 0, 136)
StatsLbl.BackgroundTransparency = 1
StatsLbl.Text = "0 eggs"
StatsLbl.TextColor3 = Color3.fromRGB(140, 140, 160)
StatsLbl.TextSize = 10
StatsLbl.Font = Enum.Font.Code
StatsLbl.TextXAlignment = Enum.TextXAlignment.Left
StatsLbl.Parent = Main

-- LIST
local ListFrame = Instance.new("ScrollingFrame")
ListFrame.Size = UDim2.new(1, -20, 1, -170)
ListFrame.Position = UDim2.new(0, 10, 0, 160)
ListFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
ListFrame.BorderSizePixel = 0
ListFrame.ScrollBarThickness = 4
ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ListFrame.Parent = Main
Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 6)

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 2)
ListLayout.Parent = ListFrame

local function refreshList()
    for _, c in pairs(ListFrame:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    local eggs = _G.tian.Eggs or {}
    for i, egg in ipairs(eggs) do
        local L = Instance.new("TextLabel")
        L.Size = UDim2.new(1, -8, 0, 18)
        L.BackgroundTransparency = 1
        L.Text = string.format("%d. [Rank %d] %s", i, egg.rank, egg.area)
        L.TextColor3 = Color3.fromRGB(200, 200, 200)
        L.TextSize = 11
        L.Font = Enum.Font.Code
        L.TextXAlignment = Enum.TextXAlignment.Left
        L.Parent = ListFrame
    end
end

RunService.Heartbeat:Connect(function()
    if _G.tian.Home then
        HomeLabel.Text = string.format("HOME: %.1f, %.1f, %.1f",
            _G.tian.Home.X, _G.tian.Home.Y, _G.tian.Home.Z)
    else
        HomeLabel.Text = string.format("HOME: %.1f, %.1f, %.1f",
            root.Position.X, root.Position.Y, root.Position.Z)
    end
    StatsLbl.Text = string.format("%d eggs | carried: %d",
        _G.tian.Stats.eggs, _G.tian.Stats.carried)
end)

task.spawn(function()
    while task.wait(2) do refreshList() end
end)

--========================================================--
-- RESPAWN
--========================================================--
player.CharacterAdded:Connect(function(c)
    char = c
    hum = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
    stopFly()
    carrying = false
end)

print("[TIAN] v10 aktif 🚬")
