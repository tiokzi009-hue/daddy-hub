-- DADDY KILLER LOCK v4
-- Violence District | Player Killer Detection + Anti Grab

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
    AntiHang = true,
    Range = 1000,
    FireRate = 0.15,
    Debug = true,
    TargetAllPlayers = false, -- true = anggap semua player lain killer
}

local function log(...)
    if CFG.Debug then print("[DADDY]", ...) end
end

-- CEK APAKAH PLAYER INI KILLER
local function isKillerPlayer(plr)
    if not plr or plr == player then return false end
    if not plr.Character or not plr.Character:FindFirstChild("Humanoid") then return false end
    if plr.Character.Humanoid.Health <= 0 then return false end

    -- cek nama player
    local n = plr.Name:lower()
    local dn = plr.DisplayName and plr.DisplayName:lower() or ""
    if n:find("killer") or dn:find("killer") then return true end

    -- cek atribut di player
    if plr:GetAttribute("IsKiller") or plr:GetAttribute("isKiller") 
    or plr:GetAttribute("Killer") or plr:GetAttribute("Role") == "Killer" then
        return true
    end

    -- cek atribut di karakter
    local c = plr.Character
    if c:GetAttribute("IsKiller") or c:GetAttribute("isKiller") 
    or c:GetAttribute("Role") == "Killer" then
        return true
    end

    -- cek Team
    if plr.Team and plr.Team.Name:lower():find("killer") then return true end

    -- cek leaderstats / tag
    local ls = plr:FindFirstChild("leaderstats")
    if ls then
        for _, v in pairs(ls:GetChildren()) do
            if tostring(v.Value):lower():find("killer") then return true end
        end
    end

    -- cek tag di Humanoid
    local h = c:FindFirstChild("Humanoid")
    if h then
        for _, tag in pairs(h:GetChildren()) do
            if tag:IsA("ObjectValue") and tostring(tag.Value):lower():find("killer") then
                return true
            end
        end
    end

    return CFG.TargetAllPlayers
end

-- CARI KILLER PLAYER TERDEKAT
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

    -- fallback: NPC killer di workspace
    if not closest then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                if obj.Humanoid.Health > 0 and obj ~= char then
                    local n = obj.Name:lower()
                    if n == "killer" or n:find("killer") then
                        local hrp = obj:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local d = (hrp.Position - root.Position).Magnitude
                            if d < dist then
                                dist = d
                                closest = obj
                            end
                        end
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
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = model
    log("Paint merah:", model.Name)
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
    beam.Width0 = 0.15
    beam.Width1 = 0.15
    beam.FaceCamera = true
    beam.Parent = root
    taliBeam = beam
    taliAtt1 = att1
end

-- ANTI GRAB: bersihin semua constraint yang nyambung keluar
local function forceRelease()
    -- 1. Hapus HRP_Clone
    for _, obj in pairs(char:GetDescendants()) do
        if obj.Name == "HRP_Clone" then
            pcall(function() obj:Destroy() end)
        end
    end
    
    -- 2. Hapus Weld/WeldConstraint ke HRP_Clone
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
    
    -- 3. Hapus isi folder RagdollConstraints
    local ragdoll = char:FindFirstChild("RagdollConstraints")
    if ragdoll then
        for _, obj in pairs(ragdoll:GetChildren()) do
            pcall(function() obj:Destroy() end)
        end
    end
    
    -- 4. Hapus BallSocket/Align/Rope/Rod
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("BallSocketConstraint") 
        or obj:IsA("AlignPosition") 
        or obj:IsA("AlignOrientation")
        or obj:IsA("RopeConstraint")
        or obj:IsA("RodConstraint") then
            pcall(function() obj:Destroy() end)
        end
    end
    
    -- 5. Lepas state
    pcall(function()
        root.Anchored = false
        hum.PlatformStand = false
        hum.Sit = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        hum.WalkSpeed = 50
        hum.JumpPower = 100
    end)
    
    -- 6. Teleport dikit ke atas
    pcall(function()
        root.CFrame = root.CFrame + Vector3.new(0, 5, 0)
    end)
end

-- MAIN LOOP
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

-- ANTI GRAB
RunService.Heartbeat:Connect(function()
    if not char or not char.Parent then return end
    if CFG.AntiGrab then
        local beingHeld = false
        if char:FindFirstChild("HRP_Clone") then beingHeld = true end
        if char:FindFirstChild("RagdollConstraints") then beingHeld = true end
        if hum.PlatformStand or hum.Sit or root.Anchored then beingHeld = true end
        if hum.WalkSpeed < 5 then beingHeld = true end
        
        if beingHeld then
            log("DIGENDONG → force release")
            forceRelease()
        end
    end
    
    if CFG.ForceUnanchor and root.Anchored then
        root.Anchored = false
    end
    if CFG.ForceWalkSpeed then
        if hum.WalkSpeed < CFG.WalkSpeed then hum.WalkSpeed = CFG.WalkSpeed end
        if hum.JumpPower < CFG.JumpPower then hum.JumpPower = CFG.JumpPower end
    end
end)

player.CharacterAdded:Connect(function(c)
    char = c
    hum = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
    taliBeam = nil
    taliAtt1 = nil
    task.wait(1)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "DADDY",
            Text = "cheat tayo telah aktif☕",
            Duration = 5
        })
    end)
end)

log("Killer Lock v4 aktif ☕")
