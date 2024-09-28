
ISWhitelistViewer.receiveDBSchema = function(schema)
    --    print("GOT SCHEMA")
        ISWhitelistViewer.instance.schema = schema;
        ISWhitelistViewer.instance:refresh();
    end
    
    function ISWhitelistViewer:closeSelf()
        self:setVisible(false)
        self:removeFromUIManager()
    end
    
    function ISWhitelistViewer:new (x, y, width, height)
        local o = {};
        x = (getCore():getScreenWidth() / 2) - (width / 2);
        y = (getCore():getScreenHeight() / 2) - (height / 2);
        o = ISPanel:new(x, y, width, height);
        setmetatable(o, self);
        o.schema = {};
        o.buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=0.5};
        o.backgroundColor = {r=0, g=0, b=0, a=0.8};
    
        self.__index = self;
        o.moveWithMouse = true;
        o.canModify = getAccessLevel() == "admin";
        getDBSchema();
        getTableResult("vehicles"); -- aggiunto qui ma non sono sicuro
        ISWhitelistViewer.instance = o;
        return o;
    end
    
    Events.OnGetDBSchema.Add(ISWhitelistViewer.receiveDBSchema);
    Events.OnGetTableResult.Add( QUI COSA? );
    