local vehicleFn = require("vehiclesFn")

local original_ISWhitelistTable_createChildren = ISWhitelistTable.createChildren
function ISWhitelistTable:createChildren()
    original_ISWhitelistTable_createChildren(self)
    self.datas.onRightMouseDown = ISWhitelistTable.onRightMouseDownList;
end

-- function ISWhitelistTable:onListMouseDown(x, y)
-- print("onListMouseDown")
-- 	self.parent.datas.selected = 0;
	
-- 	local row = self:rowAt(x, y)
-- 	if row < 1 or row > #self.items then return end
-- 	if not self.items[row].item.cat then
-- 		self.selected = row;
--         print("row: ", row)
-- 	end
-- end

function ISWhitelistTable:onRightMouseDownList(x, y)
    -- ISWhitelistTable:onListMouseDown(x, y)
    print("onRightMouseDownList")
    local row = self:rowAt(x, y)
    if row < 1 or row > #self.items then
        return
    end
    if not self.items[row].item.cat then
		self.selected = row;
        print("row: ", row)
        local item = self.items[row]
        print("item: ", item)
	    if not item then
            return
        else 
	    	self.parent:onRightMouseUp(self:getX() + x, self:getY() + self:getYScroll() + y, item)
	    end
	end
	
end

function ISWhitelistTable:onRightMouseUp(x, y, item)
    print("onRightMouseUp")
	local playerObj = getPlayer()
	self.context = nil
	if item then
		local vehicleId = tonumber(item.item.datas["id_vehicle"])
        if vehicleId then
            local vehicle = getVehicleById(vehicleId)
            self.context = ISContextMenu.get(0, x + self:getAbsoluteX(), y + self:getAbsoluteY())
            if vehicle then
		        if vehicle:getScript() then
		        	if vehicle:getPartById("Engine") then
		        		self.context:addOption("CHEAT: Get Key", playerObj, ISVehicleMechanics.onCheatGetKey, vehicle)
		        		if vehicle:isHotwired() then
		        			self.context:addOption("CHEAT: Remove Hotwire", playerObj, ISVehicleMechanics.onCheatHotwire, vehicle, false, false)
		        		else
		        			self.context:addOption("CHEAT: Hotwire", playerObj, ISVehicleMechanics.onCheatHotwire, vehicle, true, false)
		        		end
		        	end
		        	self.context:addOption("CHEAT: Repair Vehicle", playerObj, ISVehicleMechanics.onCheatRepair, vehicle)
		        	self.context:addOption("CHEAT: Set Rust", playerObj, ISVehicleMechanics.onCheatSetRust, vehicle)
		        end
                self.context:addOption("Teleport to Vehicle", playerObj, vehicleFn.teleportToVehicle, vehicle)
		        self.context:addOption("CHEAT: Remove Vehicle", playerObj, vehicleFn.onCheatRemove, vehicle) -- to do, refresh list after remove
		        self.context:addOption("Meccanica Veicolo", playerObj, ISVehicleMenu.onMechanic, vehicle)
            else
                print("Vehicle not found: ", vehicleId)
                local x,y = tonumber(item.item.datas["x"]), tonumber(item.item.datas["y"])
                self.context:addOption("Teleport to Vehicle", playerObj, vehicleFn.teleportToNoVehicle, x, y)
            end
        end
	end
end


function ISWhitelistTable.getVehiclesTable(rowId, tableName)
    print("getVehiclesTable called with rowId:", rowId, "tableName:", tableName)
    local view = ISWhitelistViewer.instance.panel:getView(tableName)
    view.loading = false

    local vehicles = getCell():getVehicles()
    local datas = ArrayList.new()

    -- Create columns as a Lua table with custom methods
    local columns = {
        "id_vehicle",
        "x",
        "y",
        "script_name",
        "real_name",
        -- Add other columns as needed
    }
    function columns:get(index)
        return self[index + 1] -- Adjust for Lua's 1-based indexing
    end
    function columns:size()
        return #self
    end

    -- Iterate through the vehicles and format the data
    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        print("Processing vehicle index: ", i, " ID: ", vehicle:getId())

        -- Create a table to represent the dbResult
        local dbResult = {}

        dbResult.columns = columns
        dbResult.tableName = "vehicles"

        local script_name = vehicle:getScript():getName()
        -- Create values as a Lua table with custom methods
        local values = {
            ["id_vehicle"] = tostring(vehicle:getId()),
            ["x"] = tostring(vehicle:getX()),
            ["y"] = tostring(vehicle:getY()),
            ["script_name"] = ("Base." .. script_name),
            ["real_name"] = getText("IGUI_VehicleName" .. script_name),
            -- Add other properties if necessary
        }
        function values:get(key)
            return self[key]
        end

        dbResult.values = values

        -- Define methods getColumns() and getValues()
        function dbResult:getColumns()
            return self.columns
        end

        function dbResult:getValues()
            return self.values
        end

        datas:add(dbResult)
    end

    print("Total datas size: ", datas:size())

    if datas:size() > 0 then
        if rowId == 0 then
            view.totalResult = 0
            view.datas:clear()
            view.columnSize = {}
            view.pages = {}
        end
        view.totalResult = view.totalResult + datas:size()
        table.insert(view.pages, datas)
        table.insert(view.fullPages, datas)
        view.pageLbl.name = "1/" .. #view.pages
        if rowId == 0 then
            print("Calling computeResult with datas")
            view:computeResult(datas)
            print("computeResult returned")
        end
        view:doPagesButtons()
    else
        print("No data to display")
    end
end

local orig_ISWhitelistTable_computeResult = ISWhitelistTable.computeResult
function ISWhitelistTable:computeResult(datas)
    local tableName = self.tableName
    print("[VehiclesDb]\tReceived Data from table:", tableName)
    if ISWhitelistViewer.instance.vehiclesDb == true then --do this only for fetch from DB(fetch from cell has his own function)
        if tableName == "vehicles" then
            for i = 0, datas:size() - 1 do
                local dbResult = datas:get(i)
                local script_name = dbResult:getValues():get("script_name")
                dbResult:getValues():put("real_name", getText("IGUI_VehicleName" .. script_name))
            end
        end
    end
    
    -- Call the original computeResult function
    orig_ISWhitelistTable_computeResult(self, datas)
end