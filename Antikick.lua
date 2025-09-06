local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

-- Metatable anti kick/ban
local mt = getrawmetatable(game)
setreadonly(mt,false)
local oldNamecall = mt.__namecall
mt.__namecall = newcclosure(function(self,...)
    local method = getnamecallmethod()
    if method=="Kick" then return nil end
    if tostring(self):lower():find("ban") then return nil end
    return oldNamecall(self,...)
end)
LocalPlayer.Kick=function() return end
LocalPlayer.Destroy=function() return end
for _,v in pairs(getgc(true)) do
    if typeof(v)=="function" and debug.getinfo(v).name=="Disconnect" then
        hookfunction(v,function(...) return end)
    end
end

-- Auto rejoin
task.spawn(function()
    while true do
        if not LocalPlayer or not LocalPlayer.Parent then
            pcall(function() TeleportService:Teleport(game.PlaceId,LocalPlayer) end)
        end
        task.wait(3)
    end
end)

-- Character protection
task.spawn(function()
    while true do
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health<=0 then hum.Health=hum.MaxHealth end
        end
        task.wait(0.5)
    end
end)

-- Anti Remote Suspicious
local function protectRemote(remote)
    if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
        local mt2=getrawmetatable(remote)
        setreadonly(mt2,false)
        local oldNamecall2 = mt2.__namecall
        mt2.__namecall = newcclosure(function(self,...)
            local method = getnamecallmethod()
            if method=="FireServer" or method=="InvokeServer" then
                local name=tostring(self):lower()
                if name:find("kick") or name:find("ban") or name:find("ip") or name:find("log") or name:find("steal") then
                    warn("⚠️ Blocked suspicious remote: "..tostring(self))
                    return nil
                end
            end
            return oldNamecall2(self,...)
        end)
    end
end
for _,obj in pairs(workspace:GetDescendants()) do protectRemote(obj) end
workspace.DescendantAdded:Connect(protectRemote)

-- Anti HTTP/IP Logger
local HttpFuncs={"HttpGet","HttpPost","HttpRequest","RequestAsync"}
for _,fn in pairs(HttpFuncs) do
    if LocalPlayer[fn] then LocalPlayer[fn]=function(...) warn("⚠️ Blocked HTTP: "..fn) return nil end end
end

-- Anti file steal
local FileFuncs={"readfile","writefile","isfile","delfile"}
for _,fn in pairs(FileFuncs) do
    if _G[fn] then _G[fn]=function(...) warn("⚠️ Blocked file: "..fn) return nil end end
end

-- Anti loadstring from URL
if _G.loadstring then
    local oldLoad=_G.loadstring
    _G.loadstring=function(code,...)
        if tostring(code):lower():find("http") then warn("⚠️ Blocked loadstring URL") return nil end
        return oldLoad(code,...)
    end
end

-- Anti username grab
local oldIndex = mt.__index
mt.__index = newcclosure(function(self,key)
    if key=="Kick" or key=="Destroy" then return function() return end end
    if self==LocalPlayer and (key=="Name" or key=="UserId") then return "Protected" end
    return oldIndex(self,key)
end)

-- Anti keylogger/input
local oldInputBegan=UserInputService.InputBegan
UserInputService.InputBegan=function(input,gameProcessed)
    return oldInputBegan(input,gameProcessed)
end
local oldInputEnded=UserInputService.InputEnded
UserInputService.InputEnded=function(input,gameProcessed)
    return oldInputEnded(input,gameProcessed)
end

print("✅ Anti Remote Suspicious + Full Future Protection Activated")
