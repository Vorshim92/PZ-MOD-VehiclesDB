
-- if string.match(vehicle:getScript():getName(), "Burnt") or string.match(vehicle:getScript():getName(), "Smashed") then
-- function ISVehicleMenu.getVehicleDisplayName(vehicle)
-- 	local name = getText("IGUI_VehicleName" .. vehicle:getScript():getName())
-- 	if string.match(vehicle:getScript():getName(), "Burnt") then
-- 		local unburnt = string.gsub(vehicle:getScript():getName(), "Burnt", "")
-- 		if getTextOrNull("IGUI_VehicleName" .. unburnt) then
-- 			name = getText("IGUI_VehicleName" .. unburnt)
-- 		end
-- 		name = getText("IGUI_VehicleNameBurntCar", name)
-- 	end
-- 	return name
-- end



-- function ISVehicleMenu.onMechanic(playerObj, vehicle)
-- 	local ui = getPlayerMechanicsUI(playerObj:getPlayerNum())
-- 	if ui:isReallyVisible() then
-- 		ui:close()
-- 		return
-- 	end

-- 	local engineHood = nil;
-- 	local cheat = getCore():getDebug() and getDebugOptions():getBoolean("Cheat.Vehicle.MechanicsAnywhere")
-- 	if ISVehicleMechanics.cheat or (isClient() and isAdmin()) or cheat then
-- 		ISTimedActionQueue.add(ISOpenMechanicsUIAction:new(playerObj, vehicle))
-- 		return;
-- 	end
