-- 🛡 Enhanced Anti-Exploit + Shadow Layer for [Slasher] Forsaken
-- ⚠️ Use ONLY in your own/test game

local allowedPlace = 18687417158
if game.PlaceId ~= allowedPlace then return end

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Safe pcall helper
local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    if ok then return res end
end

-- ================================
-- 0️⃣ Shadow Layer: Fake Kick/Ban
-- ================================
local function shadow_kick_ban(fake_type)
    -- fake_type = "kick" or "ban"
    local StarterGui = game:GetService("StarterGui")
    safe(function()
        StarterGui:SetCore("SendNotification", {
            Title = fake_type:upper().." Notice",
            Text = "You have been "..fake_type.."ed from the game.",
            Duration = 3
        })
    end)

    safe(function()
        local screenGui = Instance.new("ScreenGui")
        screenGui.IgnoreGuiInset = true
        screenGui.ResetOnSpawn = false
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,0,1,0)
        frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
        frame.BackgroundTransparency = 0
        frame.Parent = screenGui

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,0,1,0)
        label.Text = "You have been "..fake_type.."ed.\nRejoining..."
        label.TextColor3 = Color3.fromRGB(255,0,0)
        label.TextScaled = true
        label.BackgroundTransparency = 1
        label.Parent = frame

        task.wait(2) -- illusion duration
        screenGui:Destroy()
    end)

    -- Immediately restore player
    safe(function()
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then hum.Health = hum.MaxHealth end
        end
    end)
end

-- ================================
-- 1️⃣ Namecall Hook (Kick/Ban + Shadow)
-- ================================
local function apply_namecall_hook()
    local ok, mt = pcall(getrawmetatable, game)
    if not ok or not mt then return end
    safe(setreadonly, mt, false)

    local old_nc = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local caller = tostring(self)
        if method == "Kick" or tostring(caller):lower():find("ban") then
            task.spawn(function() shadow_kick_ban(method:lower()) end)
            return nil -- block real kick/ban
        end
        return old_nc(self, ...)
    end)
end

-- ================================
-- 2️⃣ __index Hook (Protect Kick/Destroy & Shadow)
-- ================================
local function apply_index_hook()
    local ok, mt = pcall(getrawmetatable, LocalPlayer)
    if not ok or not mt then ok, mt = pcall(getrawmetatable, game) if not ok or not mt then return end end
    safe(setreadonly, mt, false)

    local old_index = mt.__index
    mt.__index = newcclosure(function(self, key)
        local k = tostring(key):lower()
        if self == LocalPlayer and (k=="kick" or k=="destroy" or k=="health") then
            return function() task.spawn(function() shadow_kick_ban(k) end) end -- fake shadow call
        end
        return old_index(self, key)
    end)
end

-- ================================
-- 3️⃣ RemoteEvent Watcher + Payload Filter + Shadow
-- ================================
local SUSPICIOUS_WORDS = {"kick","ban","report","log","disconnect","shutdown","admin"}

local function is_suspicious(name) 
    if not name then return false end
    name = tostring(name):lower()
    for _,w in ipairs(SUSPICIOUS_WORDS) do if name:find(w) then return true end end
    return false
end

local hookedRemotes = {}
local function hook_remote(ev)
    if not ev:IsA("RemoteEvent") or hookedRemotes[ev] then return end
    hookedRemotes[ev] = true
    ev.OnClientEvent:Connect(function(...)
        if is_suspicious(ev.Name) or is_suspicious(ev:GetFullName()) then
            task.spawn(function() shadow_kick_ban("kick") end)
            return
        end
    end)
end

local function scan_remotes(root)
    for _,child in pairs(root:GetDescendants()) do
        if child:IsA("RemoteEvent") then hook_remote(child) end
    end
end

local function start_remote_watcher()
    scan_remotes(ReplicatedStorage)
    scan_remotes(Workspace)
    ReplicatedStorage.DescendantAdded:Connect(hook_remote)
    Workspace.DescendantAdded:Connect(hook_remote)
end

-- ================================
-- 4️⃣ Fake Return Injection (Context-Aware)
-- ================================
local function fake_replace(fn, ret)
    if type(fn)~="function" then return false end
    safe(function()
        if hookfunction then hookfunction(fn, function(...) return ret end) end
    end)
end

local function inject_fakes()
    if not getgc then return end
    for _,v in pairs(getgc(true) or {}) do
        if type(v)=="function" then
            local ok, info = pcall(debug.getinfo, v)
            if ok and info and info.name and is_suspicious(info.name) then
                fake_replace(v, false)
            end
        end
    end
end

-- ================================
-- 5️⃣ Extra Layers: Anti-Freeze, Death, Tool, Crash, Idle
-- ================================
local function apply_extra_layers()
    -- Anti-Freeze + Anti-Crash
    RunService.Heartbeat:Connect(function()
        local c = LocalPlayer.Character
        if c then
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Anchored then hrp.Anchored = false end
        end

        if workspace:GetNumChildren() > 4000 then
            for _,o in pairs(workspace:GetChildren()) do
                if o:IsA("Explosion") or o:IsA("ParticleEmitter") or o:IsA("Beam") then
                    safe(o.Destroy, o)
                end
            end
        end
    end)

    -- Anti-Death
    LocalPlayer.CharacterAdded:Connect(function(ch)
        safe(function()
            local hum = ch:WaitForChild("Humanoid",10)
            if hum then
                hum.HealthChanged:Connect(function(hp)
                    if hp and hp <= 0 then hum.Health = hum.MaxHealth end
                end)
            end
        end)
    end)

    -- Anti-Tool loss
    LocalPlayer.Backpack.ChildRemoved:Connect(function(tool)
        safe(function() tool.Parent = LocalPlayer.Backpack end)
    end)

    -- Anti-Idle
    for _,c in pairs(getconnections(LocalPlayer.Idled) or {}) do safe(c.Disable, c) end

    -- Fake Username
    LocalPlayer.Name = "Player_"..math.random(1000,9999)

    -- Auto-Rejoin Illusion
    task.spawn(function()
        while true do task.wait(3)
            if not LocalPlayer or not LocalPlayer.Parent then
                safe(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
            end
        end
    end)
end

-- ================================
-- 6️⃣ Self-Healing Watchdog (Event-driven)
-- ================================
local function watchdog()
    apply_namecall_hook()
    apply_index_hook()
    start_remote_watcher()
    inject_fakes()
    apply_extra_layers()
end

-- Initial Apply
watchdog()

-- Continuous Watchdog
task.spawn(function()
    while true do
        task.wait(4)
        watchdog()
    end
end)

-- Ready Message
print("[ANTI++++] Enhanced Anti-Exploit + Shadow Layer initialized for [Slasher] Forsaken.")
