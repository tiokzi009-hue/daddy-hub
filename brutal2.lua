-- DADDY KILLER LOCK v10
-- Violence District | Team Filter + Remote Attack + Auto Cancel Grab

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
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

local CFG = {
    Headshot = true,
    AutoFire = true,
    ForceRed = true,
    ShowTali = true,
    AntiGrab = true,
    Range = 1000,
    FireRate = 0.15,
    Debug = true,
    UseRemote = true,
}

local function log(...)
    if CFG.Debug then print("[DADDY]", ...) end
end

-- ===== FILTER KILLER PAKAI TEAM =====
local function isKillerPlayer(plr)
    if not plr or plr == player then return false end
    if not plr.Character or not plr.Character:FindFirstChild("Humanoid") then return false end
    if plr.Character.Humanoid.Health <= 0 then return false end
    if not plr.Team then return false end
    local tn = plr.Team.Name:lower()
    return tn == "killer" or tn:find("killer") ~= nil
end

-- ===== CARI KILLER =====
local function findKiller()
    local closest, dist = nil, CFG.Range
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

-- ===== HIGHLIGHT MERAH (cuma 1 target) =====
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

-- ===== TALI =====
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

-- ===== REMOTE REFERENCES =====
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

if remoteHit then log("remoteHit OK") else log("remoteHit GA ADA") end
if remoteCancelGrab then log("remoteCancelGrab OK") else log("remoteCancelGrab GA ADA") end

-- ===== ANTI GRAB =====
local function forceRelease()
    -- Hapus HRP_Clone
    for _, obj in pairs(char:GetDescendants()) do
        if obj.Name == "HRP_Clone" then
            pcall(function() obj:Destroy() end)
        end
    end

    -- Hapus Weld/WeldConstraint ke HRP_Clone
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

    -- Hapus isi folder RagdollConstraints
    local ragdoll = char:FindFirstChild("RagdollConstraints")
    if ragdoll then
        for _, obj in pairs(ragdoll:GetChildren()) do
            pcall(function() obj:Destroy() end)
        end
    end

    -- Hapus BallSocket / Align / Rope / Rod
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("BallSocketConstraint")
        or obj:IsA("AlignPosition")
        or obj:IsA("AlignOrientation")
        or obj:IsA("RopeConstraint")
        or obj:IsA("RodConstraint") then
            pcall(function() obj:Destroy() end)
        end
    end

    -- Lepas state
    pcall(function()
        root.Anchored = false
        hum.PlatformStand = false
        hum.Sit = false
    end)

    -- FIRE REMOTE CANCEL GRAB
    if remoteCancelGrab then
        pcall(function()
            remoteCancelGrab:FireServer()
            log("CANCEL GRAB fired")
        end)
    end
end

-- ===== MAIN LOOP: AIM + FIRE =====
local lastFire = 0
RunService.RenderStepped:Connect(function()
    if not char or not char.Parent then return end
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

    if CFG.ForceRed then paintRed(killer) end

    if CFG.ShowTali then
        if not taliBeam then makeTali() end
        taliBeam.Enabled = true
        taliAtt1.Parent = hrp
    end

    local targetPart = (CFG.Headshot and head) or hrp
    if targetPart then
        cam.CFrame = CFrame.new(cam.CFrame.Position, targetPart.Position)
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Handle") then
            pcall(function()
                tool.Handle.CFrame = CFrame.new(tool.Handle.Position, targetPart.Position)
            end)
        end
    end

    -- AUTO FIRE PAKAI REMOTE ATAU TOOL
    if CFG.AutoFire and tick() - lastFire > CFG.FireRate then
        lastFire = tick()
        if CFG.UseRemote and remoteHit then
            pcall(function()
                remoteHit:FireServer(killer)
            end)
        end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
        end
    end
end)

-- ===== ANTI GRAB LOOP =====
local lastRelease = 0
RunService.Heartbeat:Connect(function()
    if not char or not char.Parent then return end

    if CFG.AntiGrab then
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

-- ===== RESPAWN =====
player.CharacterAdded:Connect(function(c)
    char = c
    hum = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
    taliBeam = nil
    taliAtt1 = nil
    currentHL = nil
    lastRelease = 0
    task.wait(1)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "DADDY",
            Text = "cheat tayo telah aktif☕",
            Duration = 5
        })
    end)
end)

log("Killer Lock v10 aktif ☕")
