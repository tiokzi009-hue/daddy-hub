--========================================================--
-- SCRIPT TIAN v18 🚬
-- Steal an Egg | Hold 4 Detik + 4 Telur Terbaik
--========================================================--

_G.tian = _G.tian or {}
_G.tian.Home = _G.tian.Home or nil
_G.tian.Stats = { carried = 0 }

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
        Text = "tian v18 siap 🚬",
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

local RF_EggPlace = findRemote("AskPlaceEgg")
print("[TIAN] EggPlace:", RF_EggPlace and "OK" or "NIL")

--========================================================--
-- AREA RANK
--========================================================--
local AREA_RANK = {
    ["Enchanted Forest"] = 100,
    ["Light Dark"] = 99,
    ["Titan Temple"] = 98,
    ["Cherry Blossom"] = 97,
    ["Cosmic"] = 96,
    ["Prehistoric"] = 50,
    ["Abyss Ocean"] = 49,
    ["Volcano"] = 48,
    ["Snow"] = 47,
    ["Jungle"] = 46,
    ["Desert"] = 45,
    ["Lake"] = 44,
    ["Forest"] = 43,
}

--========================================================--
-- SCAN TOP 4
--========================================================--
local function scanTop4()
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
    local top4 = {}
    for i = 1, math.min(4, #list) do
        top4[#top4+1] = list[i]
    end
    return top4
end

--========================================================--
-- CARI TOMBOL ClickRegion
--========================================================--
local function findClickRegion()
    for _, g in pairs(player.PlayerGui:GetDescendants()) do
        if g.Name == "ClickRegion" and g.Visible then
            if g:IsA("TextButton") or g:IsA("ImageButton") then
                return g
            end
        end
    end
    return nil
end

--========================================================--
-- HOLD TOMBOL 4 DETIK
--========================================================--
local HOLD_DURATION = 4.0  -- 4 detik

local function holdButton(btn)
    if not btn then return false end
    
    print("[TIAN] hold tombol 4 detik...")
    
    -- FIRE DOWN
    pcall(function() btn.MouseButton1Down:Fire() end)
    pcall(function() btn.InputBegan:Fire(
        Instance.new("InputObject", btn), 
        false
    ) end)
    
    -- HOLD selama 4 detik
    task.wait(HOLD_DURATION)
    
    -- FIRE UP
    pcall(function() btn.MouseButton1Up:Fire() end)
    pcall(function() btn.MouseButton1Click:Fire() end)
    
    print("[TIAN] hold selesai")
    task.wait(0.3)
    return true
end

--========================================================--
-- AMBIL 4 TELUR
--========================================================--
local carrying = false

local function takeTop4()
    if carrying then return end
    carrying = true
    task.spawn(function()
        local eggs = scanTop4()
        print("[TIAN] top:", #eggs)

        if #eggs == 0 then
            carrying = false
            return
        end

        local carried = 0
        for i, egg in ipairs(eggs) do
            if not carrying then break end
            print(string.format("[TIAN] %d/%d → %s", i, #eggs, egg.area))

            -- Teleport ke telur
            root.CFrame = CFrame.new(egg.pos + Vector3.new(0, 5, 0))
            task.wait(0.4)

            -- Cari tombol
            local btn = findClickRegion()
            if btn then
                holdButton(btn)
                carried = carried + 1
            else
                print("[TIAN] tombol ga muncul, tunggu...")
                task.wait(1)
                btn = findClickRegion()
                if btn then
                    holdButton(btn)
                    carried = carried + 1
                end
            end

            task.wait(0.4)

            -- Ke home
            if _G.tian.Home and RF_EggPlace then
                root.CFrame = CFrame.new(_G.tian.Home + Vector3.new(0, 5, 0))
                task.wait(0.3)
                pcall(function() RF_EggPlace:InvokeServer() end)
                task.wait(0.2)
            end
        end

        _G.tian.Stats.carried = carried
        carrying = false
        print("[TIAN] done — carried:", carried, "/ 4")
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
Main.Position = UDim2.new(0, 10, 0.35, 0)
Main.Size = UDim2.new(0, 260, 0, 180)
Main.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
Main.BackgroundTransparency = 0.1
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

do
    local dragging, dragStart, startPos, dragInput
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

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 32)
Header.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 22, 0, 22)
Logo.Position = UDim2.new(0, 8, 0.5, -11)
Logo.BackgroundColor3 = Color3.fromRGB(120, 70, 200)
Logo.Parent = Header
Instance.new("UICorner", Logo).CornerRadius = UDim.new(1, 0)

local LogoT = Instance.new("TextLabel")
LogoT.Size = UDim2.new(1, 0, 1, 0)
LogoT.BackgroundTransparency = 1
LogoT.Text = "T"
LogoT.TextColor3 = Color3.new(1,1,1)
LogoT.TextSize = 12
LogoT.Font = Enum.Font.GothamBold
LogoT.Parent = Logo

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 34, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "TIAN v18"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextSize = 11
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

local HomeLabel = Instance.new("TextLabel")
HomeLabel.Size = UDim2.new(1, -20, 0, 16)
HomeLabel.Position = UDim2.new(0, 10, 0, 38)
HomeLabel.BackgroundTransparency = 1
HomeLabel.Text = "HOME: -, -, -"
HomeLabel.TextColor3 = Color3.fromRGB(160, 200, 160)
HomeLabel.TextSize = 10
HomeLabel.Font = Enum.Font.Code
HomeLabel.TextXAlignment = Enum.TextXAlignment.Left
HomeLabel.Parent = Main

local function makeBtn(text, xPos, color, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 78, 0, 30)
    Btn.Position = UDim2.new(0, xPos, 0, 60)
    Btn.BackgroundColor3 = color
    Btn.Text = text
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.TextSize = 10
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

makeBtn("AMBIL 4", 92, Color3.fromRGB(150, 90, 30), function()
    takeTop4()
end)

makeBtn("STOP", 174, Color3.fromRGB(140, 40, 40), function()
    carrying = false
end)

local StatsLbl = Instance.new("TextLabel")
StatsLbl.Size = UDim2.new(1, -20, 0, 16)
StatsLbl.Position = UDim2.new(0, 10, 0, 100)
StatsLbl.BackgroundTransparency = 1
StatsLbl.Text = "carried: 0/4"
StatsLbl.TextColor3 = Color3.fromRGB(140, 140, 160)
StatsLbl.TextSize = 10
StatsLbl.Font = Enum.Font.Code
StatsLbl.TextXAlignment = Enum.TextXAlignment.Left
StatsLbl.Parent = Main

local InfoLbl = Instance.new("TextLabel")
InfoLbl.Size = UDim2.new(1, -20, 1, -130)
InfoLbl.Position = UDim2.new(0, 10, 0, 118)
InfoLbl.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
InfoLbl.BorderSizePixel = 0
InfoLbl.Text = "1. SET HOME di markas\n2. AMBIL 4 → hold 4 detik\n3. Prioritas: 5 area ujung"
InfoLbl.TextColor3 = Color3.fromRGB(180, 180, 200)
InfoLbl.TextSize = 10
InfoLbl.Font = Enum.Font.Code
InfoLbl.TextXAlignment = Enum.TextXAlignment.Left
InfoLbl.TextYAlignment = Enum.TextYAlignment.Top
InfoLbl.TextWrapped = true
InfoLbl.Parent = Main
Instance.new("UICorner", InfoLbl).CornerRadius = UDim.new(0, 6)

Min.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)

RunService.Heartbeat:Connect(function()
    if _G.tian.Home then
        HomeLabel.Text = string.format("HOME: %.1f, %.1f, %.1f",
            _G.tian.Home.X, _G.tian.Home.Y, _G.tian.Home.Z)
    else
        HomeLabel.Text = string.format("POS: %.1f, %.1f, %.1f",
            root.Position.X, root.Position.Y, root.Position.Z)
    end
    StatsLbl.Text = string.format("carried: %d/4", _G.tian.Stats.carried)
end)

player.CharacterAdded:Connect(function(c)
    char = c
    hum = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
    carrying = false
end)

print("[TIAN] v18 aktif 🚬")
