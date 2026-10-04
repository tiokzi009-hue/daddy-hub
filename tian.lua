--========================================================--
-- SCRIPT TIAN v3 🚬
-- Steal an Egg | AUTO FULL + Anti Trap + Anti Guard + GUI
--========================================================--

_G.tian = _G.tian or {}
_G.tian.Settings = _G.tian.Settings or {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "TIAN",
        Text = "script tian v3 aktif 🚬",
        Duration = 5
    })
end)

--========================================================--
-- CONFIG
--========================================================--
_G.tian.CFG = {
    FlySpeed = 120,
    TrapRadius = 15,
    GuardRadius = 25,
    ClubRange = 15,
    AutoLoop = true,       -- ulang terus
    Debug = true,
    LogoText = "T",
}

local function log(...)
    if _G.tian.CFG.Debug then print("[TIAN]", ...) end
end

--========================================================--
-- REMOTE PATH HELPER (pakai slash bener)
--========================================================--
local function getRemote(path)
    local current = ReplicatedStorage
    for segment in string.gmatch(path, "[^%.]+") do
        current = current:FindFirstChild(segment)
        if not current then return nil end
    end
    return current
end

local RF_EggCarry   = getRemote("Packages.Networking.RF/EggWorld.AskFieldEggCarry")
local RF_EggDrop    = getRemote("Packages.Networking.RF/EggWorld.AskFieldEggDrop")
local RF_EggPlace   = getRemote("Packages.Networking.RF/EggWorld.AskPlaceEgg")
local RF_EggHatch   = getRemote("Packages.Networking.RF/EggWorld.AskHatch")
local RF_EggSnap    = getRemote("Packages.Networking.RF/EggWorld.AskFieldEggSnapshot")
local RF_EggRarity  = getRemote("Packages.Networking.RF/EggWorld.AskFieldEggRarityShows")

log("EggCarry:", RF_EggCarry and "OK" or "NIL")
log("EggDrop:", RF_EggDrop and "OK" or "NIL")
log("EggPlace:", RF_EggPlace and "OK" or "NIL")

--========================================================--
-- FLY (BV + BodyVelocity)
--========================================================--
local bv = nil
local bg = nil

local function startFly()
    if not char or not root then return end
    if bv then bv:Destroy() end
    if bg then bg:Destroy() end
    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = root
    bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.P = 1e4
    bg.Parent = root
end

local function stopFly()
    if bv then bv:Destroy() bv = nil end
    if bg then bg:Destroy() bg = nil end
end

local function flyTo(pos)
    if not root or not bv then return end
    local dir = (pos - root.Position)
    local dist = dir.Magnitude
    if dist > 3 then
        bv.Velocity = dir.Unit * _G.tian.CFG.FlySpeed
    else
        bv.Velocity = Vector3.zero
    end
    bg.CFrame = CFrame.new(root.Position, pos)
    hum.PlatformStand = true
    if hum.PlatformStand then end
end

--========================================================--
-- FIND BEST EGG (dari folder NestModel)
--========================================================--
local function findAllEggs()
    local list = {}
    local world = workspace:FindFirstChild("World")
    if not world then return list end
    local areas = world:FindFirstChild("Areas")
    if not areas then return list end
    local guardAreas = areas:FindFirstChild("GuardAreas")
    if not guardAreas then return list end

    for _, area in pairs(guardAreas:GetChildren()) do
        local nests = area:FindFirstChild("Nests")
        if nests then
            for _, nest in pairs(nests:GetChildren()) do
                if nest.Name:find("NestModel") then
                    for _, egg in pairs(nest:GetDescendants()) do
                        if egg:IsA("Model") or egg:IsA("BasePart") then
                            local n = egg.Name:lower()
                            if n:find("egg") or n:find("telur") then
                                table.insert(list, egg)
                            end
                        end
                    end
                end
            end
        end
    end
    return list
end

local function eggRank(egg)
    local n = egg.Name:lower()
    if n:find("cosmic") or n:find("legendary") then return 1000 end
    if n:find("titan") or n:find("divine") then return 900 end
    if n:find("mythic") or n:find("golden") then return 800 end
    if n:find("epic") then return 500 end
    if n:find("rare") then return 200 end
    local num = tonumber(n:match("%d+"))
    return num or 1
end

local function findBestEgg()
    local eggs = findAllEggs()
    if #eggs == 0 then return nil end
    local best, bestRank = nil, 0
    for _, egg in pairs(eggs) do
        local r = eggRank(egg)
        if r > bestRank then bestRank = r; best = egg end
    end
    return best
end

local function getEggPos(egg)
    if not egg then return nil end
    if egg:IsA("Model") then
        local p = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
        return p and p.Position or nil
    elseif egg:IsA("BasePart") then
        return egg.Position
    end
    return nil
end

--========================================================--
-- FIND BASE (Markas)
--========================================================--
local function findBase()
    for _, obj in pairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("base") or n:find("markas") or n:find("deposit") then
            if obj:IsA("Model") or obj:IsA("BasePart") then
                return obj
            end
        end
    end
    return nil
end

local function getBasePos(base)
    if not base then return nil end
    if base:IsA("Model") then
        local p = base.PrimaryPart or base:FindFirstChildWhichIsA("BasePart")
        return p and p.Position or nil
    elseif base:IsA("BasePart") then
        return base.Position
    end
    return nil
end

--========================================================--
-- ANTI TRAP / GUARD / HIT
--========================================================--
local function antiTrap()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("mine") or n:find("trap") or n:find("jebakan") then
                if (obj.Position - root.Position).Magnitude < _G.tian.CFG.TrapRadius then
                    pcall(function()
                        obj.CanTouch = false
                        obj.CanCollide = false
                        obj.Transparency = 1
                    end)
                end
            end
        end
    end
end

local function antiGuard()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
            local n = obj.Name:lower()
            if n:find("guard") or n:find("penjaga") then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - root.Position).Magnitude < _G.tian.CFG.GuardRadius then
                    pcall(function()
                        obj.Humanoid.WalkSpeed = 0
                        obj.Humanoid.JumpPower = 0
                    end)
                end
            end
        end
    end
end

local function antiHit()
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("Weld") or obj:IsA("WeldConstraint") then
            local p0, p1 = obj.Part0, obj.Part1
            local p0Out = p0 and not p0:IsDescendantOf(char)
            local p1Out = p1 and not p1:IsDescendantOf(char)
            if p0Out or p1Out then
                pcall(function() obj:Destroy() end)
            end
        end
    end
    if root.Anchored then root.Anchored = false end
end

--========================================================--
-- CLUB ATTACKER
--========================================================--
local function clubAttacker(targetPlr)
    if not targetPlr or not targetPlr.Character then return end
    local club = nil
    for _, obj in pairs(char:GetChildren()) do
        if obj:IsA("Tool") then
            local n = obj.Name:lower()
            if n:find("club") or n:find("pentung") or n:find("bat") or n:find("stick") then
                club = obj; break
            end
        end
    end
    if not club then return end
    local hrp = targetPlr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    cam.CFrame = CFrame.new(cam.CFrame.Position, hrp.Position)
    pcall(function() club:Activate() end)
end

--========================================================--
-- AUTO LOOP (Ambil → Terbang ke Markas → Taruh)
--========================================================--
local autoState = "idle"  -- idle / flyToEgg / carryEgg / flyToBase / deposit

local function runAutoLoop()
    if not _G.tian.Settings.AutoFull then
        if autoState ~= "idle" then
            stopFly()
            autoState = "idle"
        end
        return
    end

    if not char or not char.Parent then return end

    if autoState == "idle" then
        local bestEgg = findBestEgg()
        if bestEgg then
            local pos = getEggPos(bestEgg)
            if pos then
                startFly()
                autoState = "flyToEgg"
                log("Terbang ke egg:", bestEgg.Name)
            end
        end

    elseif autoState == "flyToEgg" then
        local bestEgg = findBestEgg()
        if not bestEgg then
            stopFly()
            autoState = "idle"
            return
        end
        local pos = getEggPos(bestEgg)
        if pos then
            flyTo(pos)
            if (pos - root.Position).Magnitude < 8 then
                -- udah deket → ambil
                if RF_EggCarry then
                    pcall(function() RF_EggCarry:InvokeServer(bestEgg) end)
                end
                autoState = "flyToBase"
                log("Egg diambil, terbang ke markas")
            end
        end

    elseif autoState == "flyToBase" then
        local base = findBase()
        local basePos = getBasePos(base)
        if basePos then
            flyTo(basePos)
            if (basePos - root.Position).Magnitude < 10 then
                -- udah di markas → taruh
                if RF_EggPlace then
                    pcall(function() RF_EggPlace:InvokeServer() end)
                end
                stopFly()
                autoState = "idle"
                log("Egg ditaruh di markas")
            end
        else
            -- ga nemu markas → balik idle
            stopFly()
            autoState = "idle"
        end
    end
end

--========================================================--
-- GUI + LOGO BULAT
--========================================================--
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TianUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.AnchorPoint = Vector2.new(0, 0.5)
Main.Position = UDim2.new(0, 10, 0.5, 0)
Main.Size = UDim2.new(0, 220, 0, 280)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 55)
Header.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 40, 0, 40)
Logo.Position = UDim2.new(0, 10, 0.5, -20)
Logo.BackgroundColor3 = Color3.fromRGB(120, 70, 200)
Logo.BorderSizePixel = 0
Logo.Parent = Header
Instance.new("UICorner", Logo).CornerRadius = UDim.new(1, 0)

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = _G.tian.CFG.LogoText
LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
LogoText.TextSize = 20
LogoText.Font = Enum.Font.GothamBold
LogoText.Parent = Logo

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -65, 0, 25)
Title.Position = UDim2.new(0, 58, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "script tian v3 🚬"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Sub = Instance.new("TextLabel")
Sub.Size = UDim2.new(1, -65, 0, 15)
Sub.Position = UDim2.new(0, 58, 0, 30)
Sub.BackgroundTransparency = 1
Sub.Text = "Steal an Egg"
Sub.TextColor3 = Color3.fromRGB(160, 160, 175)
Sub.TextSize = 10
Sub.Font = Enum.Font.Gotham
Sub.TextXAlignment = Enum.TextXAlignment.Left
Sub.Parent = Header

local Min = Instance.new("TextButton")
Min.Size = UDim2.new(0, 28, 0, 28)
Min.Position = UDim2.new(1, -33, 0, 4)
Min.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
Min.Text = "–"
Min.TextColor3 = Color3.new(1, 1, 1)
Min.TextSize = 16
Min.Font = Enum.Font.GothamBold
Min.Parent = Main
Instance.new("UICorner", Min).CornerRadius = UDim.new(0, 6)

local Content = Instance.new("Frame")
Content.Position = UDim2.new(0, 8, 0, 62)
Content.Size = UDim2.new(1, -16, 1, -70)
Content.BackgroundTransparency = 1
Content.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.Parent = Content

local function makeToggle(name, key, default)
    _G.tian.Settings[key] = (_G.tian.Settings[key] == nil) and default or _G.tian.Settings[key]
    local Holder = Instance.new("TextButton")
    Holder.Size = UDim2.new(1, 0, 0, 28)
    Holder.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    Holder.Text = ""
    Holder.AutoButtonColor = false
    Holder.Parent = Content
    Instance.new("UICorner", Holder).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -50, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(240, 240, 240)
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamSemibold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Holder

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 14, 0, 14)
    Dot.Position = UDim2.new(1, -22, 0.5, -7)
    Dot.BackgroundColor3 = _G.tian.Settings[key] and Color3.fromRGB(120, 70, 200) or Color3.fromRGB(60, 60, 70)
    Dot.Parent = Holder
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    Holder.MouseButton1Click:Connect(function()
        _G.tian.Settings[key] = not _G.tian.Settings[key]
        Dot.BackgroundColor3 = _G.tian.Settings[key] and Color3.fromRGB(120, 70, 200) or Color3.fromRGB(60, 60, 70)
    end)
end

-- SATU TOMBOL AUTO
makeToggle("AUTO EGG FULL", "AutoFull", true)
makeToggle("Anti Trap", "AntiTrap", true)
makeToggle("Anti Pukul", "AntiHit", true)
makeToggle("Anti Penjaga", "AntiGuard", true)
makeToggle("Auto Pukul Pencuri", "AutoClub", true)

Min.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)

-- Draggable
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

--========================================================--
-- MAIN LOOP
--========================================================--
RunService.Heartbeat:Connect(function()
    if not char or not char.Parent then return end
    if _G.tian.Settings.AntiTrap then antiTrap() end
    if _G.tian.Settings.AntiHit then antiHit() end
    if _G.tian.Settings.AntiGuard then antiGuard() end
    runAutoLoop()
end)

--========================================================--
-- RESPAWN
--========================================================--
player.CharacterAdded:Connect(function(c)
    char = c
    hum = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
    stopFly()
    autoState = "idle"
    task.wait(1)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "TIAN",
            Text = "script tian v3 aktif 🚬",
            Duration = 5
        })
    end)
end)

log("Script Tian v3 aktif 🚬")
