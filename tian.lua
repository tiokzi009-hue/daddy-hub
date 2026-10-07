--========================================================--
-- SCRIPT TIAN v12 🚬
-- Steal an Egg | Menu Bawah + Draggable
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
        Text = "tian v12 siap 🚬",
        Duration = 5
    })
end)

--========================================================--
-- REMOTE
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
-- CARRY ALL
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
                root.CFrame = CFrame.new(egg.pos + Vector3.new(0, 6, 0))
                task.wait(0.15)
                if RF_EggCarry then
                    pcall(function() RF_EggCarry:InvokeServer(egg.model) end)
                    carried = carried + 1
                end
                task.wait(0.15)
            end
        end
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
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.AnchorPoint = Vector2.new(0, 0)
-- MENU DI BAWAH KIRI, GA KETIBAN TOMBOL ROBLOX
Main.Position = UDim2.new(0, 10, 0.35, 0)
Main.Size = UDim2.new(0, 280, 0, 320)
Main.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
Main.BackgroundTransparency = 0.1
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Draggable manual
do
    local dragging = false
    local dragStart, startPos, dragInput

    Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    Main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 36)
Header.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 24, 0, 24)
Logo.Position = UDim2.new(0, 8, 0.5, -12)
Logo.BackgroundColor3 = Color3.fromRGB(120, 70, 200)
Logo.Parent = Header
Instance.new("UICorner", Logo).CornerRadius = UDim.new(1, 0)

local LogoT = Instance.new("TextLabel")
LogoT.Size = UDim2.new(1, 0, 1, 0)
LogoT.BackgroundTransparency = 1
LogoT.Text = "T"
LogoT.TextColor3 = Color3.new(1,1,1)
LogoT.TextSize = 14
LogoT.Font = Enum.Font.GothamBold
LogoT.Parent = Logo

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 38, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "TIAN CENTER"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Min = Instance.new("TextButton")
Min.Size = UDim2.new(0, 22, 0, 22)
Min.Position = UDim2.new(1, -28, 0.5, -11)
Min.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
Min.Text = "–"
Min.TextColor3 = Color3.new(1,1,1)
Min.TextSize = 12
Min.Font = Enum.Font.GothamBold
Min.Parent = Header
Instance.new("UICorner", Min).CornerRadius = UDim.new(0, 5)

-- HOME
local HomeLabel = Instance.new("TextLabel")
HomeLabel.Size = UDim2.new(1, -20, 0, 16)
HomeLabel.Position = UDim2.new(0, 10, 0, 42)
HomeLabel.BackgroundTransparency = 1
HomeLabel.Text = "HOME: -, -, -"
HomeLabel.TextColor3 = Color3.fromRGB(160, 200, 160)
HomeLabel.TextSize = 10
HomeLabel.Font = Enum.Font.Code
HomeLabel.TextXAlignment = Enum.TextXAlignment.Left
HomeLabel.Parent = Main

-- BUTTONS
local function makeBtn(text, xPos, yPos, color, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 62, 0, 24)
    Btn.Position = UDim2.new(0, xPos, 0, yPos)
    Btn.BackgroundColor3 = color
    Btn.Text = text
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.TextSize = 9
    Btn.Font = Enum.Font.GothamBold
    Btn.BorderSizePixel = 0
    Btn.Parent = Main
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 5)
    Btn.MouseButton1Click:Connect(callback)
end

makeBtn("SET HOME", 10, 62, Color3.fromRGB(40, 90, 150), function()
    _G.tian.Home = root.Position
    print("[TIAN] home set")
end)

makeBtn("SCAN", 76, 62, Color3.fromRGB(40, 120, 60), function()
    scanEggs()
    print("[TIAN] scanned:", #_G.tian.Eggs)
end)

makeBtn("CARRY", 142, 62, Color3.fromRGB(150, 90, 30), function()
    carryAll()
end)

makeBtn("STOP", 208, 62, Color3.fromRGB(140, 40, 40), function()
    carrying = false
    print("[TIAN] stopped")
end)

-- STATS
local StatsLbl = Instance.new("TextLabel")
StatsLbl.Size = UDim2.new(1, -20, 0, 16)
StatsLbl.Position = UDim2.new(0, 10, 0, 90)
StatsLbl.BackgroundTransparency = 1
StatsLbl.Text = "0 eggs"
StatsLbl.TextColor3 = Color3.fromRGB(140, 140, 160)
StatsLbl.TextSize = 9
StatsLbl.Font = Enum.Font.Code
StatsLbl.TextXAlignment = Enum.TextXAlignment.Left
StatsLbl.Parent = Main

-- LIST
local ListFrame = Instance.new("ScrollingFrame")
ListFrame.Size = UDim2.new(1, -20, 1, -120)
ListFrame.Position = UDim2.new(0, 10, 0, 110)
ListFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
ListFrame.BorderSizePixel = 0
ListFrame.ScrollBarThickness = 4
ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ListFrame.Parent = Main
Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 6)

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 1)
ListLayout.Parent = ListFrame

local function refreshList()
    for _, c in pairs(ListFrame:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    local eggs = _G.tian.Eggs or {}
    for i, egg in ipairs(eggs) do
        local L = Instance.new("TextLabel")
        L.Size = UDim2.new(1, -6, 0, 16)
        L.BackgroundTransparency = 1
        L.Text = string.format("%d. [R%d] %s", i, egg.rank, egg.area)
        L.TextColor3 = Color3.fromRGB(200, 200, 200)
        L.TextSize = 10
        L.Font = Enum.Font.Code
        L.TextXAlignment = Enum.TextXAlignment.Left
        L.Parent = ListFrame
    end
end

Min.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)

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
    carrying = false
end)

print("[TIAN] v12 aktif 🚬")
