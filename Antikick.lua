--[[
    ZenDreamProtect v1.1 (No GUI Edition)
    Features: Anti-Kick | Anti-Logger | Anti-Remote | Anti-Username Grabber | Anti-IP Logger | Custom GUI Destroyer
    For exploit use only. Edit CONFIG below to toggle features.
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ===== SETTINGS =====
local CONFIG = {
    ANTI_KICK = true,
    ANTI_LOGGER = true,
    ANTI_REMOTE = true,
    ANTI_USERNAME_GRABBER = true,
    ANTI_IP_LOGGER = true,
    DESTROY_CUSTOM_GUI = true,
    CUSTOM_GUI_NAME = "AnnoyingPopup",
    LOG_GUI_DESTROY = true,
}

-- ====== NOTIFICATION ======
local function notify(title, text)
    print("[ZenDreamProtect] " .. title .. ": " .. text)
end

-- ====== ANTI-KICK ======
local function enableAntiKick()
    if not CONFIG.ANTI_KICK then return end
    if LocalPlayer and rawget(LocalPlayer, "Kick") ~= nil then
        LocalPlayer.Kick = function()
            notify("Anti-Kick", "Blocked direct Kick()")
            return
        end
    end

    local mtSuccess, mt = pcall(getrawmetatable, game)
    if mtSuccess and mt then
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if (method == "Kick" or method == "kick") and self == LocalPlayer then
                notify("Anti-Kick", "Blocked __namecall Kick")
                return nil
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
end

-- ====== ANTI-LOGGER (Includes IP/Username logger protection) ======
local function enableAntiLogger()
    if not CONFIG.ANTI_LOGGER and not CONFIG.ANTI_IP_LOGGER and not CONFIG.ANTI_USERNAME_GRABBER then return end
    local keywords = {
        "ip", "http", "request", "webhook", "discord", "log", "logger",
        "username", "name", "userid", "save", "clipboard", "cookie",
        "hwid", "hardware", "writefile", "httppost", "token", "auth", "password", "send", "exploit", "getfenv"
    }
    local function isSuspicious(s)
        s = s:lower()
        for _, k in ipairs(keywords) do
            if s:find(k) then return true end
        end
        return false
    end

    local gc = (getgc and getgc(true)) or {}
    for _, item in ipairs(gc) do
        if typeof(item) == "function" then
            local ok, info = pcall(function() return debug.getinfo(item) end)
            if ok and info then
                local combined = (tostring(info.name or "").."\n"..tostring(info.short_src or ""))
                if isSuspicious(combined) then
                    pcall(function()
                        hookfunction(item, function(...)
                            notify("Anti-Logger", "Blocked suspicious logger/IP/username function: "..(info.name or "unknown"))
                            return nil
                        end)
                    end)
                end
            end
        end
    end
end

-- ====== ANTI-USERNAME GRABBER ======
local function enableAntiUsernameGrabber()
    if not CONFIG.ANTI_USERNAME_GRABBER then return end
    pcall(function()
        local oldName = LocalPlayer.Name
        local mt = getrawmetatable(LocalPlayer)
        if mt and mt.__index then
            setreadonly(mt, false)
            local oldIndex = mt.__index
            mt.__index = newcclosure(function(self, key)
                if self == LocalPlayer and (key == "Name" or key == "Username") then
                    notify("Anti-Username Grabber", "Blocked attempt to read username.")
                    return "ProtectedUser"
                end
                return oldIndex(self, key)
            end)
            setreadonly(mt, true)
        end
    end)
end

-- ====== ANTI-REMOTE ======
local function enableAntiRemote()
    if not CONFIG.ANTI_REMOTE then return end

    local remoteTypes = {"RemoteEvent", "RemoteFunction"}
    local function hookRemote(obj)
        if obj:IsA("RemoteEvent") and obj.FireServer then
            pcall(function()
                local oldFS = obj.FireServer
                obj.FireServer = function(self, ...)
                    notify("Anti-Remote", "Blocked FireServer on " .. obj.Name)
                    return nil
                end
            end)
        end
        if obj:IsA("RemoteFunction") and obj.InvokeServer then
            pcall(function()
                local oldIS = obj.InvokeServer
                obj.InvokeServer = function(self, ...)
                    notify("Anti-Remote", "Blocked InvokeServer on " .. obj.Name)
                    return nil
                end
            end)
        end
    end
    for _, obj in ipairs(game:GetDescendants()) do
        if table.find(remoteTypes, obj.ClassName) then
            hookRemote(obj)
        end
    end
    game.DescendantAdded:Connect(function(obj)
        if table.find(remoteTypes, obj.ClassName) then
            hookRemote(obj)
        end
    end)
end

-- ====== CUSTOM GUI DESTROYER ======
local function enableCustomGUIDestroyer()
    if not CONFIG.DESTROY_CUSTOM_GUI then return end
    local function checkGUIs()
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            if gui.Name == CONFIG.CUSTOM_GUI_NAME then
                gui:Destroy()
                notify("Custom GUI Destroyed", CONFIG.CUSTOM_GUI_NAME .. " was destroyed.")
                if CONFIG.LOG_GUI_DESTROY then
                    print("[ZenDreamProtect] Destroyed GUI: " .. gui.Name)
                end
            end
        end
    end
    checkGUIs()
    LocalPlayer.PlayerGui.ChildAdded:Connect(function(gui)
        if gui.Name == CONFIG.CUSTOM_GUI_NAME then
            gui:Destroy()
            notify("Custom GUI Destroyed", CONFIG.CUSTOM_GUI_NAME .. " was destroyed.")
            if CONFIG.LOG_GUI_DESTROY then
                print("[ZenDreamProtect] Destroyed GUI: " .. gui.Name)
            end
        end
    end)
end

-- ====== INIT ======
local function init()
    notify("ZenDreamProtect", "Initializing...")

    enableAntiKick()
    enableAntiLogger()
    enableAntiUsernameGrabber()
    enableAntiRemote()
    enableCustomGUIDestroyer()

    notify("ZenDreamProtect", "All protections active! (No GUI Edition)")
end

init()
