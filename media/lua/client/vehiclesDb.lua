-- ISWhitelistViewer Section

local original_ISWhitelistViewer_refreshButtons = ISWhitelistViewer.refreshButtons
function ISWhitelistViewer:refreshButtons()
    original_ISWhitelistViewer_refreshButtons(self)
    if self.activeView and self.activeView.tableName == "vehicles" then
        self.delete.enable = false;
        self.modify.enable = false;
    end
end

function ISWhitelistTable.getVehiclesTable(rowId, tableName)
    print("inside getVehiclesTable")
    local view = ISWhitelistViewer.instance.panel:getView(tableName)
    view.loading = false

    -- Ottieni i veicoli dalla funzione globale
    local vehicles = getCell():getVehicles()
    local datas = ArrayList.new()

    -- Itera attraverso i veicoli e formatta i dati
    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        local dataRow = {}

        -- Supponendo che tu voglia ottenere alcune proprietà del veicolo
        dataRow["id"] = vehicle:getId()
        dataRow["x"] = vehicle:getX()
        dataRow["y"] = vehicle:getY()
        -- Aggiungi altre proprietà se necessario

        datas:add(dataRow)
    end

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
            view:computeResult(datas)
        end
        view:doPagesButtons()
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
            if i == "vehicles" then
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


        if tableName == "vehicles" then
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


-- local original_ISWhitelistViewer_drawDatas = ISWhitelistTable.drawDatas
-- function ISWhitelistTable:drawDatas(y, item, alt)
--     original_ISWhitelistViewer_drawDatas(self, y, item, alt)

-- end

-- ISWhitelistTable Section


-- local original_ISWhitelistTable_createChildren = ISWhitelistTable.createChildren
-- function ISWhitelistTable:createChildren()
--     original_ISWhitelistTable_createChildren(self)

-- end



