-- ============================================================================================
-- VehicleDistanceOptimizer.lua
--
-- Autor: LimnedMoonlight
-- Version: 1.0.0.0
--  Initial Release
-- ============================================================================================
-- Changelog:
--  1.0.0.5
--      implement function to create global "modsettings.xml in documents/farmingsimulator 25"
-- ============================================================================================

VehicleOptimizer = {}
VehicleOptimizer.name = "FS25_vehicleDistanceOptimizer"

-- Pfade für den modSettings-Ordner und die XML-Datei generieren
VehicleOptimizer.settingsDir = getUserProfileAppPath() .. "modSettings/" .. VehicleOptimizer.name .. "/"
VehicleOptimizer.settingsFile = VehicleOptimizer.settingsDir .. "settings.xml"

-- Standardwerte (Defaults)
VehicleOptimizer.CHECK_INTERVAL = 4000
VehicleOptimizer.CLIP_PARKED = 175
VehicleOptimizer.CLIP_AI     = 225
VehicleOptimizer.CLIP_PLAYER = 285
VehicleOptimizer.dbg         = false

local timer = 0

function VehicleOptimizer:loadMap(name) self:initSettings() end

function VehicleOptimizer:initSettings()
    createFolder(self.settingsDir)

    if fileExists(self.settingsFile) then
        local xmlFile = loadXMLFile("VehicleOptimizerSettings", self.settingsFile)
        if xmlFile ~= 0 then
            self.CHECK_INTERVAL = Utils.getNoNil(getXMLInt(xmlFile, "settings.optimizer.checkInterval"), self.CHECK_INTERVAL)
            self.CLIP_PARKED    = Utils.getNoNil(getXMLInt(xmlFile, "settings.optimizer.clipParked"), self.CLIP_PARKED)
            self.CLIP_AI        = Utils.getNoNil(getXMLInt(xmlFile, "settings.optimizer.clipAI"), self.CLIP_AI)
            self.CLIP_PLAYER    = Utils.getNoNil(getXMLInt(xmlFile, "settings.optimizer.clipPlayer"), self.CLIP_PLAYER)
            self.dbg            = Utils.getNoNil(getXMLBool(xmlFile, "settings.optimizer.debug"), self.dbg)
            delete(xmlFile)
        end
    else
        -- XML existiert nicht: Neue Datei mit Standardwerten generieren
        local xmlFile = createXMLFile("VehicleOptimizerSettings", self.settingsFile, "settings")
        if xmlFile ~= 0 then
            setXMLInt(xmlFile, "settings.optimizer.checkInterval", self.CHECK_INTERVAL)
            setXMLInt(xmlFile, "settings.optimizer.clipParked", self.CLIP_PARKED)
            setXMLInt(xmlFile, "settings.optimizer.clipAI", self.CLIP_AI)
            setXMLInt(xmlFile, "settings.optimizer.clipPlayer", self.CLIP_PLAYER)
            setXMLBool(xmlFile, "settings.optimizer.debug", self.dbg)
            saveXMLFile(xmlFile)
            delete(xmlFile)
        end
    end
end

function VehicleOptimizer:update(dt)
    timer = timer + dt

    if timer >= self.CHECK_INTERVAL then
        local count = 0
        local pool = g_currentMission.nodeToObject

        if pool ~= nil then
            for _, object in pairs(pool) do
                if type(object) == "table" and object.rootNode ~= nil and (object.getIsMotorStarted ~= nil or object.getAttacherVehicle ~= nil or object.wheels ~= nil) then

                    local node = object.rootNode
                    local targetDist = self.CLIP_PARKED -- Standard-Distanzwert
                    local rootVehicle = object -- Hauptfahrzeug ermitteln

                    if object.getHitchedRootVehicle ~= nil then
                        rootVehicle = object:getHitchedRootVehicle() -- Zugfahrzeug finden, an dem Gerät hängt
                    end

                    -- Sichtweite basierend auf dem Status des Hauptfahrzeugs setzen
                    if rootVehicle.getIsControlled ~= nil and rootVehicle:getIsControlled() then 
                        targetDist = self.CLIP_PLAYER -- Spieler
                    elseif rootVehicle.getIsAiActive ~= nil and rootVehicle:getIsAiActive() then 
                        targetDist = self.CLIP_AI -- KI-Helfer
                    elseif rootVehicle.getIsMotorStarted ~= nil and rootVehicle:getIsMotorStarted() then 
                        targetDist = self.CLIP_AI -- Laufender Motor
                    end

                    setClipDistance(node, targetDist)
                    count = count + 1
                end
            end
        end

        if self.dbg then Logging.warning(string.format("[%s] Check: %d Fahrzeuge & Geräte optimiert.", self.name, count)) end
        timer = 0 
    end
end

addModEventListener(VehicleOptimizer)
