-- Zen Anti-Kick Hub v1.1
-- Anti-Kick Protection: LocalScript & Metatable
-- Full client-side protection

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")

-- ===============================
-- 🔒 Anti Kick / Ban (Metatable + LocalScript)
-- ===============================
local mt = getrawmetatable(game)
setreadonly(mt,false)
local oldNamecall = mt.__namecall

mt.__namecall = newcclosure(function(self,...)
    local method = getnamecallmethod()
    if method == "Kick" or method == "Destroy" or tostring(self):lower():find("kick") or tostring(self):lower():find("ban") then
        warn("⚠️ Zen Anti-Kick v1.1: Blocked Kick/Ban attempt!")
        return nil
    end
    return oldNamecall(self,...)
end)

-- __index / __newindex protection
local oldIndex = mt.__index
local oldNewIndex = mt.__newindex

mt.__index = newcclosure(function(self,key)
    if key=="Kick" or key=="Destroy" then
        warn("⚠️ Zen Anti-Kick v1.1: __index Kick/Destroy blocked!")
        return function() return end
    end
    return oldIndex(self,key)
end)

mt.__newindex = newcclosure(function(self,key,value)
    if key=="Kick" or key=="Destroy" then
        warn("⚠️ Zen Anti-Kick v1.1: __newindex Kick/Destroy blocked!")
        return
    end
    return oldNewIndex(self,key,value)
end)

-- Direct overrides for LocalPlayer
LocalPlayer.Kick = function() warn("⚠️ Zen Anti-Kick v1.1: Direct Kick blocked!") return end
LocalPlayer.Destroy = function() warn("⚠️ Zen Anti-Kick v1.1: Direct Destroy blocked!") return end

-- Scan getgc() for LocalScript functions attempting kick/ban
for _,v in pairs(getgc(true)) do
    if typeof(v)=="function" then
        local info = debug.getinfo(v)
        if info.name and (info.name:lower():find("kick") or info.name:lower():find("ban")) then
            hookfunction(v,function(...) warn("⚠️ Zen Anti-Kick v1.1: LocalScript kick/ban blocked!") return end)
        end
    end
end

-- ===============================
-- 🔎 Anti Disconnect Monitoring
-- ===============================
for _,v in pairs(getgc(true)) do
    if typeof(v) == "function" and debug.getinfo(v).name == "Disconnect" then
        hookfunction(v, function(...)
            warn("⚠️ Zen Anti-Kick v1.1: Disconnect attempt blocked!")
            return
        end)
    end
end

-- ===============================
-- 🔄 Auto Rejoin / Player Check
-- ===============================
task.spawn(function()
    while true do
        if not LocalPlayer or not LocalPlayer.Parent then
            warn("⚠️ Zen Anti-Kick v1.1: Player removed, possible kick detected!")
            -- Optional: auto-rejoin for your own game
            -- pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
        end
        task.wait(3)
    end
end)

print("✅ Zen Anti-Kick Hub v1.1 activated: LocalScript & Metatable protection live!")
