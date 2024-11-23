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
    self.vehiclesDb = false -- false = in cell, true = in db
    self.database = ISButton:new(startX, self:getHeight() - btnHgt - padBottom, btnWid, btnHgt, "FETCH DB", self, ISWhitelistViewer.onOptionMouseDown)
    self.database.internal = "FETCH_VEHICLES"
    self.database:initialise()
    self.database:instantiate()
    self.database.borderColor = self.buttonBorderColor
    self.database.enable = false
    self:addChild(self.database)
end

local original_ISWhitelistViewer_onOptionMouseDown = ISWhitelistViewer.onOptionMouseDown
function ISWhitelistViewer:onOptionMouseDown(button, x, y)
    if button.internal == "FETCH_VEHICLES" and self.activeView.tableName == "vehicles" then
        self.activeView:clear()
        self.activeView:clearFilters()
        if self.vehiclesDb then
            self.vehiclesDb = false
            self.database:setTitle("FETCH DB")
            ISWhitelistTable.getVehiclesTable(0, self.activeView.tableName) -- fetch vehicles from cell
        else
            self.vehiclesDb = true
            self.database:setTitle("FETCH CELL")
            getTableResult(self.activeView.tableName, self.activeView.entriesPerPages) -- fetch vehicles from db
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

local original_ISWhitelistViewer_refresh = ISWhitelistViewer.refresh
function ISWhitelistViewer:refresh() -- TODO: qui per aggiungere una nuova tabella vehicles.
    -- print("[VehiclesDb]\tReceived Schema:")
    -- for tableName, columns in pairs(self.schema) do
    --     print("[VehiclesDb]\tTable:", tableName)
    --     for columnIndex, columnData in ipairs(columns) do
    --         print("[VehiclesDb]\t  Column Index:", columnIndex, "Type:", type(columnData))
    --         for key, value in pairs(columnData) do
    --             print("[VehiclesDb]\t    ", key, ":", value)
    --         end
    --     end
    -- end
    original_ISWhitelistViewer_refresh(self)
     -- Add the 'vehicles' table after the loop
     if not self.schema["vehicles"] then
        self.schema["vehicles"] = {
            { name = "id_vehicle", type = "string" }, -- id vehicles is different in cell and db. luamanager script only work with id_vehicle from the cell. so from the db we can't get the vehicle object. we can just acquire his position. 
            { name = "x", type = "float" },
            { name = "y", type = "float" },
            { name = "script_name", type = "string" },
            { name = "real_name", type = "string" },
            -- Add other columns as needed
        }
    end
     -- Now, create the vehicles tab
    local vehiclesTab = ISWhitelistTable:new(0, 0, self.panel.width, self.panel.height - self.panel.tabHeight, "vehicles")
    vehiclesTab.columns = self.schema["vehicles"]
    vehiclesTab:initialise()
    self.panel:addView("vehicles", vehiclesTab)
    vehiclesTab.parent = self

    -- Set the active view if not already set
    if not self.activeView then
        self.activeView = vehiclesTab
        if not self.vehiclesDb then
            ISWhitelistTable.getVehiclesTable(0, "vehicles") -- Fetch data from the CELL
        else
            getTableResult("vehicles", vehiclesTab.entriesPerPages) -- Fetch from Java vehicles.db
        end
        vehiclesTab.loading = true
    end
end


local original_ISWhitelistViewer_onActivateView = ISWhitelistViewer.onActivateView
function ISWhitelistViewer:onActivateView()
    local tableName = self.panel.activeView.view.tableName
    if tableName == "vehicles" and not self.vehiclesDb then -- se self.vehiclesDb e' false,fetch cell
        ISWhitelistTable.getVehiclesTable(0, tableName)
        -- Aggiorna la vista attiva e pulisci i dati
        self.activeView = self.panel.activeView.view
    else
        original_ISWhitelistViewer_onActivateView(self)
    end
end