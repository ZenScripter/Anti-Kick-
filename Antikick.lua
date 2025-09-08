-- 🛡 GOD-TIER ANTI++++ PROTECTION HUB (Self-Healing)
-- ✨ All protections + GUI Hub + Anti++++ Shield (self-repair & watchdog)
-- Built by ChatGPT

--// Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

--// ===============================
--// 🔔 Notification Helper
--// ===============================
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title;
            Text = text;
            Duration = duration or 4;
        })
    end)
end

--// ===============================
--// CONFIG & INTERNAL STATE
--// ===============================
local STATE = {
    guiPresent = false,
    toggles = {
        antiKickBan = false,
        antiFreeze = false,
        antiIdle = false,
        antiHealth = false,
        antiTool = false,
        antiCrash = false,
        fakeName = false,
        autoRejoin = false,
        remoteLogger = false,
    },
    hooks = {},
    metaSig = nil,         -- signature of protected metatable namecall
    kickSig = nil,         -- signature of our Kick override
    destroySig = nil,      -- signature of Destroy override
    guiRef = nil,          -- reference to GUI
    decoyRef = nil,        -- decoy GUI (bait)
}

-- helper to safe tostring closures/vars
local function sigOf(v)
    local ok, s = pcall(function() return tostring(v) end)
    return ok and s or "unavailable"
end

--// ===============================
--// GUI CREATION (encapsulated so we can rebuild)
--// ===============================
local function makeHub()
    -- clean previous if exists
    if STATE.guiRef and STATE.guiRef.Parent then
        STATE.guiRef:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = ("GOD_TIER_HUB_%d"):format(tick())
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game:GetService("CoreGui")

    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Size = UDim2.new(0, 240, 0, 380)
    Frame.Position = UDim2.new(0.03, 0, 0.12, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    Frame.BorderSizePixel = 0
    Frame.ZIndex = 999999

    local UIList = Instance.new("UIListLayout", Frame)
    UIList.Padding = UDim.new(0,6)
    UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIList.SortOrder = Enum.SortOrder.LayoutOrder
    UIList.VerticalAlignment = Enum.VerticalAlignment.Top

    local title = Instance.new("TextLabel", Frame)
    title.Size = UDim2.new(1, -10, 0, 28)
    title.Position = UDim2.new(0,5,0,5)
    title.BackgroundTransparency = 1
    title.Text = "GOD-TIER ANTI++++ HUB"
    title.TextSize = 18
    title.Font = Enum.Font.SourceSansBold
    title.TextColor3 = Color3.fromRGB(255,255,255)

    -- helper - toggle button factory
    local function createButton(name, callback)
        local btn = Instance.new("TextButton", Frame)
        btn.Size = UDim2.new(1, -10, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Text = name .. " [OFF]"
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 16
        btn.AutoButtonColor = true
        btn.LayoutOrder = 1

        local state = false
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = name .. (state and " [ON]" or " [OFF]")
            callback(state)
        end)
    end

    -- add all toggle buttons
    createButton("Anti Kick/Ban", function(state)
        STATE.toggles.antiKickBan = state
        if state then notify("Anti Kick/Ban","Enabled",4) else notify("Anti Kick/Ban","Disabled",3) end
        -- activation handled by core protection functions
    end)

    createButton("Anti Freeze", function(state)
        STATE.toggles.antiFreeze = state
        notify("Anti Freeze", state and "Enabled" or "Disabled", 3)
    end)

    createButton("Anti Idle", function(state)
        STATE.toggles.antiIdle = state
        notify("Anti Idle", state and "Enabled" or "Disabled", 3)
    end)

    createButton("Anti Health", function(state)
        STATE.toggles.antiHealth = state
        notify("Anti Health", state and "Enabled" or "Disabled", 3)
    end)

    createButton("Anti Tool Delete", function(state)
        STATE.toggles.antiTool = state
        notify("Anti Tool Delete", state and "Enabled" or "Disabled", 3)
    end)

    createButton("Anti Crash", function(state)
        STATE.toggles.antiCrash = state
        notify("Anti Crash", state and "Enabled" or "Disabled", 3)
    end)

    createButton("Fake Username", function(state)
        STATE.toggles.fakeName = state
        notify("Fake Username", state and "Enabled" or "Disabled", 3)
    end)

    createButton("Auto Rejoin", function(state)
        STATE.toggles.autoRejoin = state
        notify("Auto Rejoin", state and "Enabled" or "Disabled", 3)
    end)

    createButton("Remote Logger", function(state)
        STATE.toggles.remoteLogger = state
        notify("Remote Logger", state and "Enabled" or "Disabled", 3)
    end)

    -- small footer
    local footer = Instance.new("TextLabel", Frame)
    footer.Size = UDim2.new(1, -10, 0, 24)
    footer.BackgroundTransparency = 1
    footer.Text = "Anti++++ Watchdog active"
    footer.TextSize = 12
    footer.TextColor3 = Color3.fromRGB(180,180,180)
    footer.Font = Enum.Font.SourceSans

    STATE.guiRef = ScreenGui
    STATE.guiPresent = true
    return ScreenGui
end

-- build initial GUI
pcall(makeHub)

-- create a decoy GUI (bait) which attackers might target first
local function makeDecoy()
    if STATE.decoyRef and STATE.decoyRef.Parent then STATE.decoyRef:Destroy() end
    local dec = Instance.new("ScreenGui")
    dec.Name = "ANTICHEAT_DEC0Y_"..math.random(1000,9999)
    dec.ResetOnSpawn = false
    dec.Parent = game:GetService("CoreGui")

    local f = Instance.new("Frame", dec)
    f.Size = UDim2.new(0, 180, 0, 120)
    f.Position = UDim2.new(0.5, -90, 0.5, -60)
    f.BackgroundColor3 = Color3.fromRGB(45, 20, 20)

    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1, -10, 0, 24)
    t.Position = UDim2.new(0,5,0,5)
    t.Text = "WeakShield v1.0"
    t.BackgroundTransparency = 1
    t.TextColor3 = Color3.fromRGB(255,200,200)

    STATE.decoyRef = dec
end
pcall(makeDecoy)

--// ===============================
--// CORE PROTECTIONS (functions we can reapply)
--// ===============================
-- store original references so we can reapply safely
local CORE = {}

-- protected metatable namecall
function CORE.applyNamecallHook()
    local ok, mt = pcall(function() return getrawmetatable(game) end)
    if not ok or not mt then return false end
    pcall(function() setreadonly(mt, false) end)

    local old = mt.__namecall
    local our = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if STATE.toggles.antiKickBan and (method == "Kick" or tostring(self):lower():find("ban")) then
            notify("⚠️ Anti Protection", "Kick/Ban blocked!", 3)
            return nil
        end
        return old(self, ...)
    end)

    pcall(function() mt.__namecall = our end)

    STATE.hooks.namecall = our
    STATE.metaSig = sigOf(mt.__namecall)
    return true
end

-- protect LocalPlayer.Kick and Destroy
function CORE.applyPlayerOverrides()
    pcall(function()
        local k = newcclosure(function() notify("⚠️ Anti Protection","Direct Kick blocked!",3) end)
        local d = newcclosure(function() notify("⚠️ Anti Protection","Destroy blocked!",3) end)
        LocalPlayer.Kick = k
        LocalPlayer.Destroy = d
        STATE.kickSig = sigOf(LocalPlayer.Kick)
        STATE.destroySig = sigOf(LocalPlayer.Destroy)
        STATE.hooks.kick = k
        STATE.hooks.destroy = d
    end)
end

-- anti-freeze loop (idempotent)
do
    local conn
    function CORE.enableAntiFreeze()
        if conn then return end
        conn = RunService.Heartbeat:Connect(function()
            if STATE.toggles.antiFreeze then
                local char = LocalPlayer.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        if hrp.Anchored then
                            hrp.Anchored = false
                            notify("⚠️ Anti Protection","Unfreeze restored",2)
                        end
                    end
                end
            end
        end)
        STATE.hooks.antiFreezeConn = conn
    end
    function CORE.disableAntiFreeze()
        if conn then conn:Disconnect() conn = nil end
    end
end

-- anti-idle
function CORE.applyAntiIdle()
    pcall(function()
        if STATE.toggles.antiIdle then
            for _,v in pairs(getconnections(LocalPlayer.Idled)) do
                pcall(function() v:Disable() end)
            end
        end
    end)
end

-- anti-health
function CORE.applyAntiHealth()
    pcall(function()
        if STATE.toggles.antiHealth then
            LocalPlayer.CharacterAdded:Connect(function(char)
                local hum = char:WaitForChild("Humanoid")
                hum.HealthChanged:Connect(function(hp)
                    if hp <= 0 then
                        pcall(function() hum.Health = hum.MaxHealth end)
                        notify("⚠️ Anti Protection","Death attempt blocked",3)
                    end
                end)
            end)
        end
    end)
end

-- anti-tool delete
function CORE.applyAntiToolRestore()
    pcall(function()
        if STATE.toggles.antiTool then
            LocalPlayer.Backpack.ChildRemoved:Connect(function(tool)
                if not tool or not tool.Name then return end
                task.wait(0.2)
                pcall(function() tool.Parent = LocalPlayer.Backpack end)
                notify("⚠️ Anti Protection","Tool restored: "..tostring(tool.Name),3)
            end)
        end
    end)
end

-- anti-crash basic
function CORE.applyAntiCrash()
    pcall(function()
        if STATE.toggles.antiCrash then
            RunService.Heartbeat:Connect(function()
                if workspace:GetNumChildren() > 5000 then
                    for _,obj in pairs(workspace:GetChildren()) do
                        if obj:IsA("Explosion") or obj:IsA("ParticleEmitter") or obj:IsA("Beam") then
                            pcall(function() obj:Destroy() end)
                        end
                    end
                    notify("⚠️ Anti Protection","Cleared potential crash objects",3)
                end
            end)
        end
    end)
end

-- fake username
function CORE.applyFakeName()
    pcall(function()
        if STATE.toggles.fakeName then
            local fake = "Player_"..math.random(1000,9999)
            pcall(function() LocalPlayer.Name = fake end)
            notify("✅ Fake Identity","Using: "..fake,3)
        end
    end)
end

-- remote logger / suspicious hook
function CORE.applyRemoteLogger()
    pcall(function()
        if not STATE.toggles.remoteLogger then return end
        local suspicious = {"kick","ban","log","report","disconnect","shutdown"}
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "function" and islclosure and islclosure(v) then
                local info = debug.getinfo(v)
                if info and info.name and table.find(suspicious, info.name:lower()) then
                    pcall(function()
                        hookfunction(v, function(...)
                            notify("⚠️ Suspicious Remote","Blocked: "..tostring(info.name),3)
                            return nil
                        end)
                    end)
                end
            end
        end
    end)
end

-- auto-rejoin worker
do
    local thread
    function CORE.applyAutoRejoin()
        if thread then return end
        thread = task.spawn(function()
            while STATE.toggles.autoRejoin do
                if not LocalPlayer or not LocalPlayer.Parent then
                    pcall(function()
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    end)
                end
                task.wait(3)
            end
            thread = nil
        end)
    end
end

-- wrapper: apply all enabled protections (idempotent)
function CORE.applyAll()
    pcall(CORE.applyNamecallHook)
    pcall(CORE.applyPlayerOverrides)
    if STATE.toggles.antiFreeze then pcall(CORE.enableAntiFreeze) end
    pcall(CORE.applyAntiIdle)
    pcall(CORE.applyAntiHealth)
    pcall(CORE.applyAntiToolRestore)
    pcall(CORE.applyAntiCrash)
    pcall(CORE.applyFakeName)
    pcall(CORE.applyRemoteLogger)
    if STATE.toggles.autoRejoin then pcall(CORE.applyAutoRejoin) end
end

-- initial apply
pcall(CORE.applyAll)

--// ===============================
--// ANTI-TAMPER WATCHDOG (self-healing)
--// ===============================
task.spawn(function()
    while task.wait(1.5) do
        -- ensure GUI exists, rebuild if not
        if not STATE.guiRef or not STATE.guiRef.Parent then
            pcall(makeHub)
            notify("🛡 Watchdog","Hub rebuilt",3)
        end

        -- ensure decoy exists
        if not STATE.decoyRef or not STATE.decoyRef.Parent then
            pcall(makeDecoy)
            -- decoy rebuild quietly
        end

        -- metatable namecall protection
        pcall(function()
            local ok, mt = pcall(function() return getrawmetatable(game) end)
            if ok and mt then
                local currentSig = sigOf(mt.__namecall)
                if STATE.metaSig and currentSig ~= STATE.metaSig then
                    -- reapply our hook
                    pcall(CORE.applyNamecallHook)
                    notify("🛡 Watchdog","Namecall hook repaired",3)
                end
            end
        end)

        -- Kick/Destroy overrides check
        pcall(function()
            local ksig = sigOf(LocalPlayer.Kick)
            local dsig = sigOf(LocalPlayer.Destroy)
            if STATE.kickSig and ksig ~= STATE.kickSig then
                CORE.applyPlayerOverrides()
                notify("🛡 Watchdog","Kick override restored",3)
            end
            if STATE.destroySig and dsig ~= STATE.destroySig then
                CORE.applyPlayerOverrides()
                notify("🛡 Watchdog","Destroy override restored",3)
            end
        end)

        -- reapply any enabled protection that might have been removed
        pcall(function() CORE.applyAll() end)
    end
end)

--// ===============================
--// QUICK MANUAL PROTECTION SCAN (on start)
--// ===============================
task.spawn(function()
    notify("🛡 GOD-TIER", "Shield initializing...", 4)
    task.wait(1)
    CORE.applyAll()
    notify("✅ GOD-TIER", "All systems online. Anti++++ Shield active.", 5)
end)

--// ===============================
--// END
--// The watchdog will continuously repair / restore / rebuild protections.
--// Toggle features from the hub; the Watchdog enforces & repairs them if tampered.
--// Keep this script running (do not destroy). Enjoy the anti++++ shield.
--// ===============================
