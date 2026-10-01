-- DADDY KILLER LOCK v2
-- Violence District | Auto Aim + ESP + Anti Grab

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

-- NOTIF AKTIF
StarterGui:SetCore("SendNotification", {
    Title = "DADDY",
    Text = "cheat tayo telah aktif☕",
    Duration = 5
})

-- KONFIG
local CFG = {
    Headshot = true,
    AutoFire = true,
    ForceRed = true,
    ShowTali = true,
    AntiGrab = true,
    AntiHang = true,
    Range = 500,
    UpdateRate = 0.05
}

-- CARI KILLER
local function findKiller()
    local closest, dist = nil, CFG.Range
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= char then
            if obj.Humanoid.Health > 0 then
                local n = obj.Name:lower()
                if n:find("killer") or n:find("pembunuh") or n:find("enemy") or n:find("npc") or obj:GetAttribute("IsKiller") then
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
    return closest
end

-- HIGHLIGHT MERAH
local function paintRed(model)
    if not model then return end
    if model:FindFirstChild("DaddyRed") then return end
    local hl = Instance.new("Highlight")
    hl.Name = "DaddyRed"
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = model
end

-- TALI KE KILLER
local function makeTali()
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
    return beam, att1
end

local taliBeam, taliAtt1 = nil, nil

-- AUTO AIM + AUTO FIRE
local lastFire = 0

RunService.RenderStepped:Connect(function()
    local killer = findKiller()
    if not killer then
        if taliBeam then taliBeam.Enabled = false end
        return
    end

    local hrp = killer:FindFirstChild("HumanoidRootPart")
    local head = killer:FindFirstChild("Head")

    -- PAINT MERAH
    if CFG.ForceRed then paintRed(killer) end

    -- TALI
    if CFG.ShowTali and hrp then
        if not taliBeam then
            taliBeam, taliAtt1 = makeTali()
        end
        taliBeam.Enabled = true
        taliAtt1.Parent = hrp
    end

    -- AUTO AIM KE HEAD
    local targetPart = CFG.Headshot and head or hrp
    if targetPart then
        cam.CFrame = CFrame.new(cam.CFrame.Position, targetPart.Position)
    end

    -- AUTO FIRE
    if CFG.AutoFire and tick() - lastFire > CFG.UpdateRate then
        lastFire = tick()
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
        else
            -- fallback: raycast damage
            if targetPart then
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {char}
                params.FilterType = Enum.RaycastFilterType.Exclude
                local dir = (targetPart.Position - cam.CFrame.Position).Unit * CFG.Range
                local result = workspace:Raycast(cam.CFrame.Position, dir, params)
                if result and result.Instance and result.Instance:IsDescendantOf(killer) then
                    killer.Humanoid:TakeDamage(35)
                end
            end
        end
    end
end)

-- ANTI GRAB / ANTI HANG
RunService.Heartbeat:Connect(function()
    if not CFG.AntiGrab then return end
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("Weld") or obj:IsA("Motor6D") or obj:IsA("Snap") then
            local p0 = obj.Part0
            if p0 and not p0:IsDescendantOf(char) then
                obj:Destroy()
            end
        end
    end
    if CFG.AntiHang then
        hum.PlatformStand = false
        root.Anchored = false
        root.Velocity = Vector3.new(root.Velocity.X, math.max(root.Velocity.Y, 0), root.Velocity.Z)
    end
end)

-- RESPAWN HANDLER
player.CharacterAdded:Connect(function(c)
    char = c
    hum = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
end)

print("[DADDY] Killer Lock aktif ☕")
