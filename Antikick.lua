-- Zen Anti Hub v1.2 (Concept Build)
-- By Zen & Jack
-- Focus: Logger++, Username, File Steal, Suspicious Remote

-- // Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- // Config
local CONFIG = {
    ANTI_LOGGER_PLUS   = true,
    ANTI_USERNAME      = true,
    ANTI_FILE_STEAL    = true,
    ANTI_SUSPICIOUS    = true,
    DEBUG_MODE         = true,
}

-- // Utils
local function log(msg)
    if CONFIG.DEBUG_MODE then warn("[Zen Anti Hub] "..msg) end
end

-- ========================
--   Protections v1.2
-- ========================

-- 🔒 Anti Logger++
local function protectLoggerPlus()
    log("Anti Logger++ loaded.")

    -- Hook request functions
    local blockFuncs = {"game:HttpGet", "game.HttpGet", "syn.request", "http_request", "request"}
    for _, fn in pairs(blockFuncs) do
        local f = getfenv()[fn] or getrenv()[fn]
        if f and type(f) == "function" then
            hookfunction(f, function(...)
                log("🚫 Blocked external HTTP request: "..fn)
                return nil
            end)
        end
    end

    -- Block GC based loggers again
    for _,v in pairs(getgc(true)) do
        if typeof(v) == "function" then
            local info = debug.getinfo(v)
            local src = tostring(info.short_src):lower()
            if src:find("logger") or src:find("grab") then
                hookfunction(v, function(...)
                    log("🚫 Suspicious logger blocked (GC).")
                    return nil
                end)
            end
        end
    end
end

-- 🔒 Anti Username Grabber
local function protectUsername()
    log("Anti Username Grabber loaded.")

    -- Fake name when accessed by suspicious functions
    local fakeName = "ZenUser"..tostring(math.random(1000,9999))

    hookmetamethod(game, "__index", function(self, key)
        if self == LocalPlayer and key == "Name" then
            local trace = debug.traceback()
            if trace:lower():find("logger") or trace:lower():find("grab") then
                log("🚫 Username grab attempt blocked. Returned fake username.")
                return fakeName
            end
        end
        return getrawmetatable(game).__index(self, key)
    end)
end

-- 🔒 Anti File Steal
local function protectFileSteal()
    log("Anti File Steal loaded.")

    local funcs = {"readfile", "writefile", "appendfile", "delfile", "listfiles", "loadfile"}
    for _, fn in pairs(funcs) do
        local f = getfenv()[fn] or getrenv()[fn]
        if f and type(f) == "function" then
            hookfunction(f, function(...)
                log("🚫 File access attempt blocked: "..fn)
                return nil
            end)
        end
    end
end

-- 🔒 Anti Suspicious Remote
local function protectSuspiciousRemote()
    log("Anti Suspicious Remote loaded.")

    -- Hook remotes globally
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if (method == "FireServer" or method == "InvokeServer") then
            local lname = tostring(self.Name):lower()
            if lname:find("logger") or lname:find("grab") or lname:find("ban") or lname:find("moderator") then
                log("🚫 Blocked suspicious remote: "..self.Name)
                return nil
            end
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end

-- ========================
--   Init
-- ========================
local function init()
    log("Zen Anti Hub v1.2 initializing...")

    if CONFIG.ANTI_LOGGER_PLUS then protectLoggerPlus() end
    if CONFIG.ANTI_USERNAME then protectUsername() end
    if CONFIG.ANTI_FILE_STEAL then protectFileSteal() end
    if CONFIG.ANTI_SUSPICIOUS then protectSuspiciousRemote() end

    log("Zen Anti Hub v1.2 Active ✅")
end

init()
