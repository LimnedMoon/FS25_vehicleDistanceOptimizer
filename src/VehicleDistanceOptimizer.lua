-- ============================================================================================
-- VehicleDistanceOptimizer.lua
--
-- Autor: LimnedMoonlight
-- Version: 1.0.0.0
--  Initial Release
-- ============================================================================================
-- Changelog:
--  1.0.0.1
--      implement function to create global "modsettings.xml in documents/farmingsimulator 25"
-- ============================================================================================

VehicleOptimizer = {}
VehicleOptimizer.name = "FS25_vehicleDistanceOptimizer"

-- Generate paths for the modSettings folder and the XML file
VehicleOptimizer.settingsDir = getUserProfileAppPath() .. "modSettings/" .. VehicleOptimizer.name .. "/"
VehicleOptimizer.settingsFile = VehicleOptimizer.settingsDir .. "settings.xml"

-- Defaultvalues
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
        -- XML does not exist: Generate a new file with default values
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
                    local targetDist = self.CLIP_PARKED -- Standard-distancevalue
                    local rootVehicle = object -- Find Main-Vehicle

                    if object.getHitchedRootVehicle ~= nil then
                        rootVehicle = object:getHitchedRootVehicle() -- Find the towing vehicle, the device is attached to it
                    end

                    -- Set visibility based on the status of the lead vehicle
                    if rootVehicle.getIsControlled ~= nil and rootVehicle:getIsControlled() then 
                        targetDist = self.CLIP_PLAYER -- Player/s
                    elseif rootVehicle.getIsAiActive ~= nil and rootVehicle:getIsAiActive() then 
                        targetDist = self.CLIP_AI -- Ai-Helper
                    elseif rootVehicle.getIsMotorStarted ~= nil and rootVehicle:getIsMotorStarted() then 
                        targetDist = self.CLIP_AI -- Running Engine
                    end

                    setClipDistance(node, targetDist)
                    count = count + 1
                end
            end
        end

        if self.dbg then print(string.format("[%s] Check: %d Optimized vehicles & equipment.", self.name, count)) end
        timer = 0 
    end
end

addModEventListener(VehicleOptimizer)
