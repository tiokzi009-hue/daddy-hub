-- DADDY BRUTAL COMBAT v1
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local CFG = {
    Range = 8,
    Dmg = 35,
    CD = 0.35,
    Auto = true,
    Aggro = 60,
    Wanted = 25
}

local last = 0

local function findGuard()
    local closest, dist = nil, CFG.Aggro
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
            local n = npc.Name:lower()
            if n:find("guard") or n:find("penjaga") or n:find("polisi") or npc:GetAttribute("IsGuard") then
                local d = (npc.HumanoidRootPart.Position - root.Position).Magnitude
                if d < dist then dist, closest = d, npc end
            end
        end
    end
    return closest
end

local function hit(target)
    if not target or not target:FindFirstChild("Humanoid") then return end
    if tick() - last < CFG.CD then return end
    last = tick()
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://180436148"
    local track = hum:FindFirstChildOfClass("Animator"):LoadAnimation(anim)
    track:Play()
    target.Humanoid:TakeDamage(CFG.Dmg)
    if target:FindFirstChild("HumanoidRootPart") then
        local dir = (target.HumanoidRootPart.Position - root.Position).Unit
        target.HumanoidRootPart.Velocity = dir * 45 + Vector3.new(0,20,0)
    end
    if _G.DaddyWanted then _G.DaddyWanted(CFG.Wanted) end
end

RunService.Heartbeat:Connect(function()
    if CFG.Auto then
        local t = findGuard()
        if t then hit(t) end
    end
end)

UIS.TouchTap:Connect(function(pos, processed)
    if processed then return end
    if #pos >= 2 then
        local t = findGuard()
        if t then hit(t) end
    end
end)

-- tombol BRUTAL
local gui = player:WaitForChild("PlayerGui")
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0,120,0,60)
btn.Position = UDim2.new(1,-140,0.5,0)
btn.BackgroundColor3 = Color3.fromRGB(180,0,0)
btn.Text = "BRUTAL"
btn.TextColor3 = Color3.new(1,1,1)
btn.TextScaled = true
btn.Parent = gui
btn.MouseButton1Click:Connect(function()
    local t = findGuard()
    if t then hit(t) end
end)

_G.ToggleBrutal = function(s) CFG.Auto = s end

print("[DADDY] Brutal Mode aktif☕")
