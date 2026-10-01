-- DADDY KILLER LOCK v7
-- Violence District | Anti Grab Smooth

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

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
    WalkSpeed = 30,
    JumpPower = 60,
}

local function log(...)
    if CFG.Debug then print("[DADDY]", ...) end
end

-- CARI KILLER PLAYER
local function findKiller()
    local closest, dist = nil, CFG.Range
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            local c = plr.Character
            if c and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0 then
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
    end
    -- fallback NPC
    if not closest then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= char then
                if obj.Humanoid.Health > 0 and obj.Name:lower():find("killer") then
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local d = (hrp.Position - root.Position).Magnitude
                        if d < dist then dist, closest = d, obj end
                    end
                end
            end
        end
    end
    return closest
end

-- HIGHLIGHT MERAH
local function paintRed(model)
    if not model then return end
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

-- TALI
local taliBeam, taliAtt1 = nil, nil
local function makeTali()
    if taliBeam then taliBeam:Destroy() end
    local att0 = Instance.new("Attachment")
    att0.Name = "DaddyAtt0"
    att0.Parent = root
    local att1 = Instance.new("Attachment")
    att1.Name = "DaddyAtt1"
    att1.Parent = root
    local beam = Instance.new("Beam")
    beam.Name = "DaddyTali"
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 120))
    beam.Width0 = 0.2
    beam.Width1 = 0.2
    beam.FaceCamera = true
    beam.Parent = root
    taliBeam = beam
    taliAtt1 = att1
end

-- ANTI GRAB: bersih TANPA teleport, TANPA force speed
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
            local p0Name = p0 and p0.Name or ""
            local p1Name = p1 and p1.Name or ""
            if p0Name:find("HRP_Clone") or p1Name:find("HRP_Clone") then
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
    
    -- Lepas state, TANPA teleport, TANPA force speed
    pcall(function()
        root.Anchored = false
        hum.PlatformStand = false
        hum.Sit = false
    end)
end

-- MAIN LOOP: AIM + FIRE
local lastFire = 0
RunService.RenderStepped:Connect(function()
    if not char or not char.Parent then return end
    local killer = findKiller()
    if not killer then
        if taliBeam then taliBeam.Enabled = false end
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

    if CFG.AutoFire and tick() - lastFire > CFG.FireRate then
        lastFire = tick()
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
        else
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {char}
            params.FilterType = Enum.RaycastFilterType.Exclude
            local origin = cam.CFrame.Position
            local dir = (targetPart.Position - origin).Unit * CFG.Range
            local result = workspace:Raycast(origin, dir, params)
            if result and result.Instance and result.Instance:IsDescendantOf(killer) then
                killer.Humanoid:TakeDamage(35)
            end
        end
    end
end)

-- ANTI GRAB SMOOTH: cooldown 1 detik, GA maksa speed, GA teleport
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
        
        -- Cooldown 1 detik, cuma lepas kalau bener-bener digendong
        if beingHeld and tick() - lastRelease > 1 then
            lastRelease = tick()
            log("DIGENDONG → release")
            forceRelease()
        end
    end
    
    -- Cuma unanchor kalau memang anchored
    if root.Anchored then
        root.Anchored = false
    end
end)

player.CharacterAdded:Connect(function(c)
    char = c
    hum = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
    taliBeam = nil
    taliAtt1 = nil
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

log("Killer Lock v7 aktif ☕")
