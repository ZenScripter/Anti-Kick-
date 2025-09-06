--[[
    All-in-One Exploit Protection v1.0 by hellocun ✨ (Enhanced by Copilot)
    Features: Anti-Kick | Anti-Teleport | Anti-Crash (heuristic) | Anti-Logger | Auto-Rejoin
    NOTES: Tweak toggles/config below. Adapt for your exploit API/environment as needed!
--]]

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PLACE_ID = game.PlaceId

-- ======================
-- ====== CONFIG ========
-- ======================
local CONFIG = {
    ANTI_KICK        = true,
    ANTI_TELEPORT    = true,
    ANTI_CRASH       = true,
    ANTI_LOGGER      = true,
    AUTO_REJOIN      = true,    -- rejoin same place when forcibly removed (use carefully)
    REJOIN_COOLDOWN  = 6,       -- seconds between auto-rejoin attempts
    CRASH_THRESHOLD  = { -- heuristics for anti-crash
        instance_count_spike = 150, -- new instances added within window considered suspicious
        window_seconds = 2,
        memory_mb_spike = 300,      -- optional: memory spike in MB
        fps_drop = 10,              -- optional: FPS drop threshold, if FPS monitoring available
    },
    LOG_SUSPICIOUS_HITS = true, -- print names/infos of GC functions we hook for anti-logger
}

-- ======= UTIL DEBOUNCE =======
local lastRejoin = 0
local function canRejoin()
    return (tick() - lastRejoin) >= CONFIG.REJOIN_COOLDOWN
end

local function tryRejoin(reason)
    if CONFIG.AUTO_REJOIN and canRejoin() then
        lastRejoin = tick()
        warn("🔁 AntiProtect: Attempting auto-rejoin... Reason:", reason or "unknown")
        pcall(function()
            TeleportService:Teleport(PLACE_ID, LocalPlayer)
        end)
    end
end

-- ======= SAFE PCALL WRAPPER =======
local function safe(f, ...)
    local ok, res = pcall(f, ...)
    return ok and res or nil
end

-- ============================
-- ====== ANTI - KICK =========
-- ============================
local function enableAntiKick()
    if not CONFIG.ANTI_KICK then return end

    -- Hook __namecall to block Kick/Destroy on LocalPlayer
    local success_mt, mt = pcall(getrawmetatable, game)
    if success_mt and mt then
        safe(function()
            setreadonly(mt, false)
            local oldNamecall = mt.__namecall
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if (method == "Kick" or method == "kick") and self == LocalPlayer then
                    warn("⚠️ AntiProtect: Blocked namecall Kick.")
                    return nil
                end
                if (method:lower():find("destroy") or method:lower():find("remove")) and tostring(self):find("Player") and self == LocalPlayer then
                    warn("⚠️ AntiProtect: Blocked namecall Destroy/Remove on player.")
                    return nil
                end
                return oldNamecall(self, ...)
            end)
            setreadonly(mt, true)
        end)
    end

    -- Override LocalPlayer.Kick
    if LocalPlayer and rawget(LocalPlayer, "Kick") ~= nil then
        LocalPlayer.Kick = function()
            warn("⚠️ AntiProtect: Direct Kick() blocked.")
            return
        end
    end

    -- Monitor removal of LocalPlayer and attempt auto-rejoin
    Players.PlayerRemoving:Connect(function(plr)
        if plr == LocalPlayer then
            warn("⚠️ AntiProtect: PlayerRemoving fired for LocalPlayer.")
            tryRejoin("PlayerRemoving")
        end
    end)
end

-- =============================
-- ====== ANTI - TELEPORT ======
-- =============================
local function enableAntiTeleport()
    if not CONFIG.ANTI_TELEPORT then return end

    -- Hook TeleportService methods to block remote teleport attempts
    safe(function()
        local blocked = function(...)
            warn("⚠️ AntiProtect: Blocked Teleport call.")
            return nil
        end
        for _, fn in ipairs({"Teleport", "TeleportToPrivateServer", "TeleportPartyAsync", "TeleportAsync"}) do
            if TeleportService[fn] then
                TeleportService[fn] = blocked
            end
        end
    end)

    -- Redundant __namecall hook for Teleport
    local success_mt, mt = pcall(getrawmetatable, game)
    if success_mt and mt then
        safe(function()
            setreadonly(mt, false)
            local oldNC = mt.__namecall
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method:lower():find("teleport") and self == LocalPlayer then
                    warn("⚠️ AntiProtect: Blocked Teleport namecall on LocalPlayer.")
                    return nil
                end
                return oldNC(self, ...)
            end)
            setreadonly(mt, true)
        end)
    end
end

-- ============================
-- ====== ANTI - CRASH ========
-- ============================
local function enableAntiCrash()
    if not CONFIG.ANTI_CRASH then return end

    -- Heuristics: instance spike, memory, FPS (if available)
    local lastCount = #workspace:GetDescendants()
    local lastMemory = collectgarbage and collectgarbage("count") or 0
    local spikeWindow = CONFIG.CRASH_THRESHOLD.window_seconds or 2
    local threshold = CONFIG.CRASH_THRESHOLD.instance_count_spike or 150

    task.spawn(function()
        while true do
            task.wait(spikeWindow)
            local nowCount = #workspace:GetDescendants()
            local diff = nowCount - lastCount
            if diff >= threshold then
                warn(("⚠️ AntiProtect: Instance spike detected (%d new instances). Possible crash attempt."):format(diff))
                -- Try to clean up suspicious GUIs
                pcall(function()
                    for _, v in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
                        if v.Name:lower():find("flood") or v.Name:lower():find("exploit") or (v.ClassName == "ScreenGui" and #v:GetDescendants() > 1000) then
                            v:Destroy()
                            warn("🧹 AntiProtect: Destroyed suspicious GUI: "..v.Name)
                        end
                    end
                end)
                tryRejoin("Crash spike")
            end
            lastCount = nowCount

            -- Optional: memory spike detection
            if CONFIG.CRASH_THRESHOLD.memory_mb_spike then
                local nowMem = collectgarbage and collectgarbage("count") or 0
                local memDiff = (nowMem - lastMemory) / 1024
                if memDiff >= CONFIG.CRASH_THRESHOLD.memory_mb_spike then
                    warn(("⚠️ AntiProtect: Memory spike detected (+%dMB). Possible crash attempt."):format(memDiff))
                    tryRejoin("Memory spike")
                end
                lastMemory = nowMem
            end
        end
    end)

    -- Monitor high-frequency errors; rejoin on error flood
    local errCount, errResetTick = 0, tick()
    local ERR_RESET_INTERVAL, ERR_THRESHOLD = 3, 20
    local function trackError()
        errCount = errCount + 1
        if tick() - errResetTick > ERR_RESET_INTERVAL then
            errCount = 1
            errResetTick = tick()
        end
        if errCount >= ERR_THRESHOLD then
            warn("⚠️ AntiProtect: Error flood detected. Attempting to rejoin.")
            tryRejoin("Error flood")
            errCount = 0
        end
    end
    pcall(function()
        local oldWarn = warn
        warn = function(...)
            trackError()
            oldWarn(...)
        end
    end)
end

-- ================================
-- ====== ANTI - LOGGER / DATA =====
-- ================================
local function enableAntiLogger()
    if not CONFIG.ANTI_LOGGER then return end
    -- Scan getgc for functions with suspicious keywords, hook/neutralize
    local gc = safe(getgc, true)
    if not gc then return end

    local keywords = {
        "ip", "hwid", "hardware", "username", "user id", "userid",
        "log", "clipboard", "writefile", "httppost", "token", "cookie",
        "webhook", "discord", "exploit", "send", "save", "getfenv",
        "request", "key", "auth", "password"
    }
    local function isSuspicious(s)
        s = s:lower()
        for _, k in ipairs(keywords) do
            if s:find(k) then return true end
        end
        return false
    end

    for _, item in ipairs(gc) do
        if typeof(item) == "function" then
            local ok, info = pcall(function() return debug.getinfo(item) end)
            if ok and info then
                local combined = (tostring(info.name or "").."\n"..tostring(info.short_src or ""))
                if isSuspicious(combined) then
                    local successHook = pcall(function()
                        hookfunction(item, function(...)
                            if CONFIG.LOG_SUSPICIOUS_HITS then
                                warn("⚠️ AntiProtect: Hooked suspicious GC function:", info.name, info.short_src)
                            end
                            return nil
                        end)
                    end)
                    if not successHook and CONFIG.LOG_SUSPICIOUS_HITS then
                        warn("ℹ️ AntiProtect: Could not hook function:", info.name, info.short_src)
                    end
                end
            end
        end
    end

    -- Hide LocalPlayer sensitive properties if requested
    pcall(function()
        if LocalPlayer then
            if rawget(LocalPlayer, "GetUserId") then
                LocalPlayer.GetUserId = function() return 0 end
            end
            if rawget(LocalPlayer, "Name") then
                local mt = getrawmetatable(LocalPlayer)
                if mt and mt.__tostring then
                    local oldToString = mt.__tostring
                    setreadonly(mt, false)
                    mt.__tostring = newcclosure(function(self)
                        if self == LocalPlayer then return "Player" end
                        return oldToString(self)
                    end)
                    setreadonly(mt, true)
                end
            end
        end
    end)
end

-- ============================
-- ====== STARTUP / HOOKS ====
-- ============================
local function init()
    print("🔰 AntiProtect: Initializing All-in-One Protection...")

    enableAntiKick()
    enableAntiTeleport()
    enableAntiCrash()
    enableAntiLogger()

    -- Watch LocalPlayer.Parent — if removed, assume forced removal and attempt rejoin
    task.spawn(function()
        while true do
            task.wait(1)
            if not LocalPlayer or not LocalPlayer.Parent then
                warn("⚠️ AntiProtect: LocalPlayer not parented. Possible forced removal.")
                tryRejoin("Not parented")
            end
        end
    end)

    print("✅ AntiProtect: Activated. Config:", HttpService:JSONEncode(CONFIG))
end

-- Run
init()
