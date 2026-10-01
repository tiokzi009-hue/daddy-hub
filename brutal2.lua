--========================================================--
-- DADDY KILLER LOCK v11
-- Violence District | VANZ + Brutal2 Fusion
-- Lead Prediction + Remote Attack + Anti Grab + GUI
--========================================================--

_G.daddy = _G.daddy or {}
_G.daddy.Settings = _G.daddy.Settings or {}

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
        Title = "DADDY",
        Text = "cheat tayo telah aktif☕",
        Duration = 5
    })
end)

--========================================================--
-- CONFIG
--========================================================--
_G.daddy.CFG = {
    Range = 1000,
    FireRate = 0.15,
    Headshot = true,
    Debug = true,
    BulletSpeed = 200,
    BulletSpeedAuto = true,
    LeadIterations = 4,
}

--========================================================--
-- REMOTE REFERENCES
--========================================================--
local remoteHit = nil
local remoteCancelGrab = nil

pcall(function()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
    if remotes then
        local attacks = remotes:FindFirstChild("Attacks")
        if attacks then
            remoteHit = attacks:FindFirstChild("hit")
        end
        local killers = remotes:FindFirstChild("Killers")
        if killers then
            local stalker = killers:FindFirstChild("Stalker")
            if stalker then
                remoteCancelGrab = stalker:FindFirstChild("CancelGrabHitbox")
            end
        end
    end
end)

local function log(...)
    if _G.daddy.CFG.Debug then print("[DADDY]", ...) end
end

log("remoteHit:", remoteHit and "OK" or "NIL")
log("remoteCancelGrab:", remoteCancelGrab and "OK" or "NIL")

--========================================================--
-- FILTER KILLER (BY TEAM)
--========================================================--
local function isKillerPlayer(plr)
    if not plr or plr == player then return false end
    if not plr.Character or not plr.Character:FindFirstChild("Humanoid") then return false end
    if plr.Character.Humanoid.Health <= 0 then return false end
    if not plr.Team then return false end
    local tn = plr.Team.Name:lower()
    return tn == "killer" or tn:find("killer") ~= nil
end

--========================================================--
-- VELOCITY TRACKER (Lead Prediction)
--========================================================--
_G.daddy.VelTracker = {}

local SAMPLE_WINDOW = 0.08
local MAX_SAMPLES = 20
local SMOOTH_ALPHA = 0.55

local function getRootPart(plr)
    local c = plr and plr.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
        or c:FindFirstChild("UpperTorso")
        or c:FindFirstChild("Torso")
end

local function sampleVelocity(plr)
    local rp = getRootPart(plr)
    if not rp then return end

    local now = tick()
    local pos = rp.Position

    local tracker = _G.daddy.VelTracker[plr]
    if not tracker then
        tracker = { samples = {}, smoothVel = Vector3.zero, lastSpeed = 0 }
        _G.daddy.VelTracker[plr] = tracker
    end

    table.insert(tracker.samples, { t = now, pos = pos })
    while #tracker.samples > MAX_SAMPLES do
        table.remove(tracker.samples, 1)
    end
    while #tracker.samples > 2
    and (now - tracker.samples[1].t) > SAMPLE_WINDOW do
        table.remove(tracker.samples, 1)
    end

    if #tracker.samples >= 2 then
        local oldest = tracker.samples[1]
        local newest = tracker.samples[#tracker.samples]
        local dt = newest.t - oldest.t
        if dt > 0.005 then
            local instVel = (newest.pos - oldest.pos) / dt
            tracker.smoothVel = tracker.smoothVel:Lerp(instVel, SMOOTH_ALPHA)
            tracker.lastSpeed = tracker.smoothVel.Magnitude
        end
    end
end

local function getVelocity(plr)
    local t = _G.daddy.VelTracker[plr]
    if t then return t.smoothVel end
    return Vector3.zero
end

--========================================================--
-- FIND KILLER (BY TEAM)
--========================================================--
local function findKiller()
    local closest, dist = nil, _G.daddy.CFG.Range
    for _, plr in pairs(Players:GetPlayers()) do
        if isKillerPlayer(plr) then
            local c = plr.Character
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - root.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = c
                end
            end
        end
    end
    return closest
end

--========================================================--
-- LEAD PREDICTION
--========================================================--
local function predictPosition(targetChar, targetPart, bulletSpeed)
    if not targetChar or not targetPart then return targetPart and targetPart.Position end

    local targetPlr = Players:GetPlayerFromCharacter(targetChar)
    if not targetPlr then return targetPart.Position end

    local vel = getVelocity(targetPlr)
    if vel.Magnitude < 1 then return targetPart.Position end

    local origin = cam.CFrame.Position
    local targetPos = targetPart.Position

    -- Iterative prediction
    for i = 1, _G.daddy.CFG.LeadIterations do
        local dist = (targetPos - origin).Magnitude
        local t = dist / bulletSpeed
        targetPos = targetPart.Position + vel * t
    end

    return targetPos
end

--========================================================--
-- HIGHLIGHT
--========================================================--
local currentHL = nil
local function paintRed(model)
    if not model then return end
    if currentHL and currentHL ~= model then
        local old = currentHL:FindFirstChild("DaddyRed")
        if old then old:Destroy() end
    end
    currentHL = model
    if model:FindFirstChild("DaddyRed") then return end
    local hl = Instance.new("Highlight")
    hl.Name = "DaddyRed"
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(255, 50, 50)
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = model
end

--========================================================--
-- TALI
--========================================================--
local taliBeam, taliAtt1 = nil, nil
local function makeTali()
    if taliBeam then taliBeam:Destroy() end
    local a0 = Instance.new("Attachment")
    a0.Name = "DaddyAtt0"
    a0.Parent = root
    local a1 = Instance.new("Attachment")
    a1.Name = "DaddyAtt1"
    a1.Parent = root
    local beam = Instance.new("Beam")
    beam.Name = "DaddyTali"
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 120))
    beam.Width0 = 0.2
    beam.Width1 = 0.2
    beam.FaceCamera = true
    beam.Parent = root
    taliBeam = beam
    taliAtt1 = a1
end

--========================================================--
-- ANTI GRAB
--========================================================--
local function forceRelease()
    for _, obj in pairs(char:GetDescendants()) do
        if obj.Name == "HRP_Clone" then
            pcall(function() obj:Destroy() end)
        end
    end
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("Weld") or obj:IsA("WeldConstraint") then
            local p0 = obj.Part0
            local p1 = obj.Part1
            local p0N = p0 and p0.Name or ""
            local p1N = p1 and p1.Name or ""
            if p0N:find("HRP_Clone") or p1N:find("HRP_Clone") then
                pcall(function() obj:Destroy() end)
            end
        end
    end
    local ragdoll = char:FindFirstChild("RagdollConstraints")
    if ragdoll then
        for _, obj in pairs(ragdoll:GetChildren()) do
            pcall(function() obj:Destroy() end)
        end
    end
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("BallSocketConstraint")
        or obj:IsA("AlignPosition")
        or obj:IsA("AlignOrientation")
        or obj:IsA("RopeConstraint")
        or obj:IsA("RodConstraint") then
            pcall(function() obj:Destroy() end)
        end
    end
    pcall(function()
        root.Anchored = false
        hum.PlatformStand = false
        hum.Sit = false
    end)
    if remoteCancelGrab then
        pcall(function()
            remoteCancelGrab:FireServer()
            log("CANCEL GRAB fired")
        end)
    end
end

--========================================================--
-- AUTO FIRE (Remote + Tool + Prediction)
--========================================================--
local function autoFire(killer)
    if not killer then return end
    local hrp = killer:FindFirstChild("HumanoidRootPart")
    local head = killer:FindFirstChild("Head")
    local targetPart = (_G.daddy.CFG.Headshot and head) or hrp
    if not targetPart then return end

    -- Fire remote
    if remoteHit then
        pcall(function()
            remoteHit:FireServer(killer)
        end)
    end

    -- Fire tool
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
    end
end

--========================================================--
-- GUI
--========================================================--
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DaddyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.AnchorPoint = Vector2.new(0, 0.5)
Main.Position = UDim2.new(0, 10, 0.5, 0)
Main.Size = UDim2.new(0, 200, 0, 220)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
Title.BorderSizePixel = 0
Title.Text = "DADDY • v11"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.Parent = Main
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

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
Content.Position = UDim2.new(0, 8, 0, 42)
Content.Size = UDim2.new(1, -16, 1, -50)
Content.BackgroundTransparency = 1
Content.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.Parent = Content

local function makeToggle(name, key, default)
    _G.daddy.Settings[key] = (_G.daddy.Settings[key] == nil) and default or _G.daddy.Settings[key]

    local Holder = Instance.new("TextButton")
    Holder.Size = UDim2.new(1, 0, 0, 30)
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
    Dot.BackgroundColor3 = _G.daddy.Settings[key] and Color3.fromRGB(70, 170, 100) or Color3.fromRGB(60, 60, 70)
    Dot.Parent = Holder
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    Holder.MouseButton1Click:Connect(function()
        _G.daddy.Settings[key] = not _G.daddy.Settings[key]
        Dot.BackgroundColor3 = _G.daddy.Settings[key] and Color3.fromRGB(70, 170, 100) or Color3.fromRGB(60, 60, 70)
    end)
end

makeToggle("Auto Fire", "AutoFire", true)
makeToggle("ESP Merah", "ForceRed", true)
makeToggle("Tali Hijau", "ShowTali", true)
makeToggle("Anti Grab", "AntiGrab", true)
makeToggle("Lead Prediction", "LeadPredict", true)
makeToggle("Headshot", "Headshot", true)

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
-- MAIN LOOP: SCAN + PREDICT + FIRE
--========================================================--
local lastFire = 0

RunService.RenderStepped:Connect(function()
    if not char or not char.Parent then return end

    -- Sample velocity tiap frame
    for _, plr in pairs(Players:GetPlayers()) do
        if isKillerPlayer(plr) then
            sampleVelocity(plr)
        end
    end

    local killer = findKiller()
    if not killer then
        if taliBeam then taliBeam.Enabled = false end
        if currentHL then
            local old = currentHL:FindFirstChild("DaddyRed")
            if old then old:Destroy() end
            currentHL = nil
        end
        return
    end

    local hrp = killer:FindFirstChild("HumanoidRootPart")
    local head = killer:FindFirstChild("Head")
    if not hrp then return end

    -- ESP
    if _G.daddy.Settings.ForceRed then paintRed(killer) end

    -- Tali
    if _G.daddy.Settings.ShowTali then
        if not taliBeam then makeTali() end
        taliBeam.Enabled = true
        taliAtt1.Parent = hrp
    else
        if taliBeam then taliBeam.Enabled = false end
    end

    -- AIM + LEAD PREDICTION
    local targetPart = (_G.daddy.Settings.Headshot and head) or hrp
    local aimPos = targetPart.Position

    if _G.daddy.Settings.LeadPredict then
        local speed = _G.daddy.CFG.BulletSpeed
        aimPos = predictPosition(killer, targetPart, speed)
    end

    cam.CFrame = CFrame.new(cam.CFrame.Position, aimPos)

    -- FIRE
    if _G.daddy.Settings.AutoFire and tick() - lastFire > _G.daddy.CFG.FireRate then
        lastFire = tick()
        autoFire(killer)
    end
end)

--========================================================--
-- ANTI GRAB LOOP
--========================================================--
local lastRelease = 0
RunService.Heartbeat:Connect(function()
    if not char or not char.Parent then return end
    if _G.daddy.Settings.AntiGrab then
        local beingHeld = false
        if char:FindFirstChild("HRP_Clone") then beingHeld = true end
        if char:FindFirstChild("RagdollConstraints") then beingHeld = true end
        if hum.PlatformStand then beingHeld = true end
        if hum.Sit then beingHeld = true end
        if root.Anchored then beingHeld = true end

        if beingHeld and tick() - lastRelease > 1 then
            lastRelease = tick()
            log("DIGENDONG → release")
            forceRelease()
        end
    end
    if root.Anchored then root.Anchored = false end
end)

--========================================================--
-- RESPAWN
--========================================================--
player.CharacterAdded:Connect(function(c)
    char = c
    hum = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
    taliBeam = nil
    taliAtt1 = nil
    currentHL = nil
    lastRelease = 0
    _G.daddy.VelTracker = {}
    task.wait(1)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "DADDY",
            Text = "cheat tayo telah aktif☕",
            Duration = 5
        })
    end)
end)

log("Killer Lock v11 aktif ☕")
