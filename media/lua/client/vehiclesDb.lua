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
    if self.activeView.tableName == "vehicles" then 
        if button.internal == "FETCH_DB" then
            self.activeView:clear();
            self.activeView:clearFilters();
            if self.vehiclesDb then
                self.vehiclesDb = false
                self.database:setTitle("FETCH DB")
                ISWhitelistTable.getVehiclesTable(0, self.activeView.tableName)
                return
            else
                self.vehiclesDb = true
                self.database:setTitle("FETCH CELL")
                getTableResult(self.activeView.tableName, self.activeView.entriesPerPages)
                return
            end
        end
        if button.internal == "REFRESH" then
            self.activeView:clear();
            self.activeView:clearFilters();
            if self.vehiclesDb then
                getTableResult(self.activeView.tableName, self.activeView.entriesPerPages);
            else
                ISWhitelistTable.getVehiclesTable(0, self.activeView.tableName)
            end
        end
    else
        original_ISWhitelistViewer_onOptionMouseDown(self, button, x, y)
    end
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


