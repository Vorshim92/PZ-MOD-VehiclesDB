local VehicleFn = {}
function VehicleFn.teleportToVehicle(playerObj, vehicle)
    if vehicle then
        playerObj:setX(vehicle:getX())
        playerObj:setY(vehicle:getY())
        playerObj:setZ(vehicle:getZ())
        playerObj:setLx(vehicle:getX())
        playerObj:setLy(vehicle:getY())
        playerObj:setLz(vehicle:getZ())
    end
end

function VehicleFn.teleportToNoVehicle(playerObj, x,y)
    if x and y then
        playerObj:setX(x)
        playerObj:setY(y)
        playerObj:setZ(0)
        playerObj:setLx(x)
        playerObj:setLy(y)
        playerObj:setLz(0)
    end
end

return VehicleFn