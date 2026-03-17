-- ===========================================================================
-- VehicleOptimizer.lua
--
-- Autor: LimnedMoonlight
-- Version: 1.0.0.0
--  Initial Release
-- ===========================================================================
-- Changelog:
--
-- ===========================================================================
VehicleOptimizer = {}

local timer = 0
local CHECK_INTERVAL = 4000 -- Intervall in Ms
local CLIP_PARKED = 175     -- Sichtweite für Fahrzeuge, die geparkt sind.
local CLIP_AI     = 225     -- Sichtweite für Fahrzeuge mit Helfer oder laufendem Motor.
local CLIP_PLAYER = 285     -- Sichtweite für das Fahrzeug, in dem ein Spieler gerade sitzt.
local dbg = false           -- Debug-Ausgabe

function VehicleOptimizer:update(dt)
    timer = timer + dt

    if timer >= CHECK_INTERVAL then
        local count = 0
        local pool = g_currentMission.nodeToObject

        if pool ~= nil then
            for _, object in pairs(pool) do
                if type(object) == "table" and object.rootNode ~= nil and (object.getIsMotorStarted ~= nil or object.getAttacherVehicle ~= nil or object.wheels ~= nil) then

                    local node = object.rootNode
                    local targetDist = CLIP_PARKED -- Standard-Distanzwert
                    local rootVehicle = object -- Hauptfahrzeug ermitteln

                    if object.getHitchedRootVehicle ~= nil then
                        rootVehicle = object:getHitchedRootVehicle() -- Zugfahrzeug finden, an dem Gerät hängt
                    end

                    -- Sichtweite basierend auf dem Status des Hauptfahrzeugs setzen
                    if rootVehicle.getIsControlled ~= nil and rootVehicle:getIsControlled() then targetDist = CLIP_PLAYER -- Spieler
                        elseif rootVehicle.getIsAiActive ~= nil and rootVehicle:getIsAiActive() then targetDist = CLIP_AI -- KI-Helfer
                        elseif rootVehicle.getIsMotorStarted ~= nil and rootVehicle:getIsMotorStarted() then targetDist = CLIP_AI -- KI-Helfer
                    end

                    setClipDistance(node, targetDist)
                    count = count + 1
                end
            end
        end

        if dbg then Logging.warning(string.format("[VehicleOptimizer] Check: %d Fahrzeuge & Geräte optimiert.", count)) timer = 0 end
    end
end

addModEventListener(VehicleOptimizer)
