-- // Zen Anti Hub v1.0 Public Release ✨
-- By Zen & Jack
-- Stable base release

-- // Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")

-- // Game Info
local PlaceId   = game.PlaceId
local JobId     = game.JobId
local GameId    = game.GameId or "Unknown"

print("🌀 Zen Anti Hub v1.0")
print("📌 PlaceId:", PlaceId, "| JobId:", JobId, "| GameId:", GameId)

-- // Config
local CONFIG = {
    ANTI_KICK   = true,
    AUTO_REJOIN = true,
    DEBUG_MODE  = true,
}

-- // Utils
local function log(msg)
    if CONFIG.DEBUG_MODE then warn("[Zen Anti Hub] "..msg) end
end

-- ========================
--   Protections
-- ========================

-- Anti Kick
local function protectKick()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        if getnamecallmethod() == "Kick" and self == LocalPlayer then
            log("Kick attempt blocked.")
            return nil
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)

    LocalPlayer.Kick = function()
        log("Direct Kick blocked.")
        return
    end
end

-- Auto Rejoin
local function enableRejoin()
    LocalPlayer.OnTeleport:Connect(function(State)
        if State == Enum.TeleportState.Failed then
            log("Teleport failed. Retrying...")
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end
    end)
end

-- ========================
--   Forsaken Profile
-- ========================
local function forsakenProfile()
    if PlaceId == 18687417158 then
        log("Forsaken detected → Forsaken profile active.")
        -- Placeholder: custom Forsaken features will be added here
    end
end

-- ========================
--   Init
-- ========================
local function init()
    log("Initializing Zen Anti Hub v1.0...")

    if CONFIG.ANTI_KICK then protectKick() end
    if CONFIG.AUTO_REJOIN then enableRejoin() end
    forsakenProfile()

    log("Zen Anti Hub v1.0 Active ✅")
end

init()
