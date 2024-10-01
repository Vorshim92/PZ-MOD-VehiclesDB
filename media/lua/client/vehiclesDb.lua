-- ISWhitelistViewer Section


local original_ISWhitelistViewer_createChildren = ISWhitelistViewer.createChildren
function ISWhitelistViewer:createChildren()
    local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
    original_ISWhitelistViewer_createChildren(self)

    local btnWid = 100
    local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
    local padBottom = 10

    local existingButtonsWidth = (btnWid + 5) * 2
    local startX = 10 + existingButtonsWidth
    self.vehiclesDb = true -- false = in cell, true = in db
    self.database = ISButton:new(startX, self:getHeight() - btnHgt - padBottom, btnWid, btnHgt, "FETCH CELL", self, ISWhitelistViewer.onOptionMouseDown)
    self.database.internal = "FETCH_DB"
    self.database:initialise()
    self.database:instantiate()
    self.database.borderColor = self.buttonBorderColor
    self.database.enable = false
    self:addChild(self.database)
end

local original_ISWhitelistViewer_onOptionMouseDown = ISWhitelistViewer.onOptionMouseDown
function ISWhitelistViewer:onOptionMouseDown(button, x, y)
    if button.internal == "FETCH_DB" and self.activeView.tableName == "vehicles" then
        self.activeView:clear()
        self.activeView:clearFilters()
        if self.vehiclesDb then
            self.vehiclesDb = false
            self.database:setTitle("FETCH DB")
            ISWhitelistTable.getVehiclesTable(0, self.activeView.tableName)
        else
            self.vehiclesDb = true
            self.database:setTitle("FETCH CELL")
            getTableResult(self.activeView.tableName, self.activeView.entriesPerPages)
        end
        return
    end

    if button.internal == "REFRESH" and self.activeView.tableName == "vehicles" then
        self.activeView:clear()
        self.activeView:clearFilters()
        if self.vehiclesDb then
            getTableResult(self.activeView.tableName, self.activeView.entriesPerPages)
        else
            ISWhitelistTable.getVehiclesTable(0, self.activeView.tableName)
        end
        return
    end

    -- For all other cases, call the original handler
    original_ISWhitelistViewer_onOptionMouseDown(self, button, x, y)
end


local original_ISWhitelistViewer_refreshButtons = ISWhitelistViewer.refreshButtons
function ISWhitelistViewer:refreshButtons()
    original_ISWhitelistViewer_refreshButtons(self)
    if self.activeView and self.activeView.tableName == "vehicles" then
        self.delete.enable = false;
        self.modify.enable = false;
        self.database.enable = true;
    else
        self.database.enable = false;
    end
end

function ISWhitelistTable.getVehiclesTable(rowId, tableName)
    print("getVehiclesTable called with rowId:", rowId, "tableName:", tableName)
    local view = ISWhitelistViewer.instance.panel:getView(tableName)
    view.loading = false

    local vehicles = getCell():getVehicles()
    print("Number of vehicles:", vehicles:size())
    local datas = ArrayList.new()

    -- Create columns as a Lua table with custom methods
    local columns = {
        "id_vehicle",
        "x",
        "y",
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

        -- Create values as a Lua table with custom methods
        local values = {
            ["id_vehicle"] = tostring(vehicle:getId()),
            ["x"] = tostring(vehicle:getX()),
            ["y"] = tostring(vehicle:getY()),
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

local original_ISWhitelistViewer_refresh = ISWhitelistViewer.refresh
function ISWhitelistViewer:refresh()
    for i, l in pairs(self.schema) do
        local cat1 = ISWhitelistTable:new(0, 0, self.panel.width, self.panel.height - self.panel.tabHeight, i)
        cat1.columns = l
        cat1:initialise()
        self.panel:addView(i, cat1)
        cat1.parent = self
        if not self.activeView then
            self.activeView = cat1
            if i == "vehicles" and not self.vehiclesDb then
                ISWhitelistTable.getVehiclesTable(0, i)
            else
                getTableResult(i, cat1.entriesPerPages)
            end
            cat1.loading = true
        end
    end
end

local original_ISWhitelistViewer_onActivateView = ISWhitelistViewer.onActivateView
function ISWhitelistViewer:onActivateView()
    if self.panel.activeView and self.panel.activeView.view then
        local tableName = self.panel.activeView.view.tableName


        if tableName == "vehicles" and not self.vehiclesDb then -- se self.vehiclesDb e' false, fetch cell
            ISWhitelistTable.getVehiclesTable(0, tableName)
        else
            getTableResult(self.panel.activeView.view.tableName, self.panel.activeView.view.entriesPerPages)
        end

        -- Aggiorna la vista attiva e pulisci i dati
        self.activeView = self.panel.activeView.view
        self.activeView:clear()
    else
        -- Se activeView o view sono nil, stampa un avviso
        print("Warning: activeView or activeView.view is nil in onActivateView")
    end
end

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

-- maybe
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

local function teleportToVehicle(playerObj, vehicle)
    if vehicle then
        playerObj:setX(vehicle:getX())
        playerObj:setY(vehicle:getY())
        playerObj:setZ(vehicle:getZ())
        playerObj:setLx(vehicle:getX())
        playerObj:setLy(vehicle:getY())
        playerObj:setLz(vehicle:getZ())
    end
end

local function teleportToNoVehicle(playerObj, x,y)
    if x and y then
        playerObj:setX(x)
        playerObj:setY(y)
        playerObj:setZ(0)
        playerObj:setLx(x)
        playerObj:setLy(y)
        playerObj:setLz(0)
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
		        if vehicle:getScript() and vehicle:getScript():getWheelCount() > 0 then
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
                self.context:addOption("Teleport to Vehicle", playerObj, teleportToVehicle, vehicle)
		        self.context:addOption("CHEAT: Remove Vehicle", playerObj, ISVehicleMechanics.onCheatRemove, vehicle)
		        self.context:addOption("Meccanica Veicolo", playerObj, ISVehicleMenu.onMechanic, vehicle)
            else
                print("Vehicle not found: ", vehicleId)
                local x,y = tonumber(item.item.datas["x"]), tonumber(item.item.datas["y"])
                self.context:addOption("Teleport to Vehicle", playerObj, teleportToNoVehicle, x, y)
            end
        end
	end
end


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
