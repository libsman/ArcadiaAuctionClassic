-- Reuse the Classic list and horizontal selling-form layout. No automatic transactions.
AAC.TradingUI = { page=1, currency="account" }
local U=AAC.TradingUI
local copy={
    tools={"Selling tools","Verkaufshilfen"}, buyers={"Buyers for my bag","Käufer für meinen Rucksack"}, orders={"Buy orders","Kaufaufträge"},
    mine={"My buy orders","Meine Kaufaufträge"}, all={"All requests","Alle Gesuche"}, prices={"Check prices","Preise prüfen"},
    recent={"List again","Erneut anbieten"}, create={"Create buy order","Kaufauftrag erstellen"}, back={"Back","Zurück"},
    item={"Item","Gegenstand"}, amount={"Quantity","Menge"}, unit={"Price / unit","Preis / Stück"}, info={"Details","Details"},
    sell={"Sell…","Verkaufen …"}, cancel={"Cancel order…","Auftrag stornieren …"}, review={"Review order…","Auftrag prüfen …"},
    prepare={"Prepare listing","Verkauf vorbereiten"}, choose={"Select a row first.","Zuerst eine Zeile auswählen."},
    empty={"No entries.","Keine Einträge."}, drop={"Drag an item here or Shift-click an item link.","Gegenstand hierher ziehen oder einen Itemlink mit Shift anklicken."},
    quantity={"Wanted quantity","Gesuchte Menge"}, price={"Maximum price per unit","Höchstpreis pro Stück"},
    reserved={"Reserved","Reserviert"}, fee={"Listing fee","Einstellgebühr"}, total={"Total required","Gesamt benötigt"},
    checking={"Checking prices…","Preise werden geprüft …"}, checked={"Price check complete. Different item variants are not compared.","Preisprüfung abgeschlossen. Unterschiedliche Gegenstandsvarianten werden nicht verglichen."},
    waiting={"Waiting…","Wartet …"}, unknown={"Not checked","Nicht geprüft"}, uncomparable={"Individual attributes — compare manually","Individuelle Werte – manuell vergleichen"},
    alone={"No competing offer","Kein Konkurrenzangebot"}, cheaper={"Other sellers are cheaper","Andere Anbieter günstiger"}, lowest={"No cheaper offer found","Kein günstigeres Angebot gefunden"},
    noStack={"No matching item in your bag.","Kein passender Gegenstand im Rucksack."},
    emptySlot={"Finish the current action and clear cursor / selling slot first.","Zuerst die aktuelle Aktion beenden und Cursor / Verkaufsfeld leeren."},
    prepared={"Listing prepared. Check the quantity and confirm in the normal selling form.","Verkauf vorbereitet. Menge prüfen und im normalen Verkaufsformular bestätigen."},
    busy={"An auction request is still running.","Eine AH-Anfrage läuft noch."},
    received={"You receive","Du erhältst"}, buyer={"Buyer","Käufer"}, filled={"Filled","Erfüllt"},
    recentHint={"Recent confirmed listings. Preparing an item does not list it for sale.","Zuletzt bestätigte Verkäufeinstellungen. Vorbereiten stellt noch nichts ins AH."},
    buyerHint={"Existing buy orders for your bag. Select an item to see your net proceeds.","Kaufaufträge für deinen Rucksack. Gegenstand auswählen, um deinen Nettoerlös zu sehen."},
    orderHint={"Select an item in Search or drag one here to create a buy order.","Gegenstand unter Suchen auswählen oder hierher ziehen, um einen Kaufauftrag zu erstellen."},
}
function U.Text(key)
    if AAC.TradingTranslations and AAC.TradingTranslations[key] then return AAC.TradingTranslations[key] end
    local row=copy[key];return row and row[(type(GetLanguage)=="function" and tostring(GetLanguage()):sub(1,2):upper()=="DE") and 2 or 1] or key
end
local function f(name) return _G["AAC_Trading"..name] end
local function set(name,value) local w=f(name);if w then w:SetText(value or "") end end
local function visible(name,yes) local w=f(name);if w then if yes then w:Show() else w:Hide() end end end
local function enable(name,yes) local w=f(name);if w then if yes then w:Enable() else w:Disable() end end end
local function number(n) return AAC.UX.Number(n or 0) end
local function money(n,mode) return AAC.BuyOrders.Money(n or 0,mode or "copper") end
local function busy() return AAC.Market.Blocked() or AAC.Market.HasConfirmation() end
-- Keep the native parent alive (its show/hide events manage auction state).
-- Only hide visible contents; never show a control that was already hidden.
local contentNames={"AAC_BidFrame","AAC_BrowseFrame","AAC_DashboardFrame","AAC_SellAuctionContent","AAC_SellMoneyAuction",
    "AAC_SellExchange","AAC_SellEditBox","AAC_HistoryEditBox","AAC_TradingSellPrices",
    "AAC_TradingSellRecent","AAC_TradingSellOrders"}
local function hideContents()
    U.hiddenContents={}
    for _,name in ipairs(contentNames) do
        local w=_G[name]
        if w and w:IsVisible() then U.hiddenContents[#U.hiddenContents+1]=w;w:Hide() end
    end
end
function U.PurchaseTabChanged(tab)
    visible("PurchasesNav",tab==2)
    if tab==2 then
        set("Bids",TEXT("BIDS"));set("Orders",U.Text("orders"))
        if U.mode then f("Orders"):LockHighlight();f("Bids"):UnlockHighlight()
        else f("Bids"):LockHighlight();f("Orders"):UnlockHighlight() end
    end
end
function U.ShowBids()
    U.Close();AAC_BidFrame:Show();U.PurchaseTabChanged(2)
end
function U.ShowOrders()
    if U.Open("mine") and AAC.Main and AAC.Main.CurrentTab=="BUY" then U.PurchaseTabChanged(2) end
end
function U.Back()
    if U.mode=="create" then U.ShowOrders() else U.Close() end
end
function U.Close()
    U.mode=nil;U.selected=nil;U.pendingOpen=nil;U.needMine=nil
    if AAC_TradingPanel then AAC_TradingPanel:Hide() end
    local restore=U.hiddenContents;U.hiddenContents=nil
    if restore then
        U.restoringContents=true
        for _,w in ipairs(restore) do w:Show() end
        U.restoringContents=nil
    end
    if AAC.BuyOrders then AAC.BuyOrders.Close() end
    if AAC.SellerTools then AAC.SellerTools.Close() end
    if AAC.Main and AAC.Main.CurrentTab=="BUY" then U.PurchaseTabChanged(2) end
end
function U.Open(mode,itemID)
    if not AAC.CanRequest() then return false end
    if AAC.Market.HasConfirmation() then return false end
    if AAC.Exchange and AAC.Exchange.context then AAC.Exchange.Leave() end
    if not U.mode then hideContents() end
    AAC.BuyOrders.Close();AAC.SellerTools.Close()
    if AAC.History then AAC.History.ClearQueue() end
    U.mode=mode or "sellable";U.page=1;U.message=nil;U.queryItemID=itemID;U.selected=nil
    U.needMine=nil;U.pendingOpen=U.mode~="recent" and U.mode or nil
    AAC_TradingPanel:Show()
    if U.mode=="create" then U.findQuery="";U.findItems={};set("FindText","") end
    U.StartPending()
    U.Render();if AAC.Main and AAC.Main.CurrentTab=="BUY" then U.PurchaseTabChanged(2) end;return true
end
function U.StartPending()
    if not U.pendingOpen or not U.mode then return end
    if busy() then U.message=U.Text("waiting");return end
    local mode=U.pendingOpen;U.pendingOpen=nil;U.message=nil
    if mode=="create" then AAC.BuyOrders.Open();U.needMine=true
    elseif mode=="prices" then AAC.SellerTools.CheckPrices()
    else AAC.BuyOrders.Search(mode,U.queryItemID or 0) end
    U.Render()
end
function U.Rows()
    if U.mode=="prices" then return AAC.SellerTools.rows or {} end
    if U.mode=="recent" then return AAC.SellerTools.Recent() end
    return AAC.BuyOrders.rows or {}
end
function U.NewOrder()
    local row=U.selected or U.searchItem
    if not U.Open("create") then return end
    U.itemID=nil;U.itemName=nil;U.itemLink=nil
    set("Quantity","1");set("Price","");set("OrderTotal","")
    if row and row.itemID then
        U.PickItem(row.link or string.format("|Hitem:%x|h[%s]|h",row.itemID,row.name or ""))
    end
    U.Render()
end
function U.OrdersFromSearch()
    local _,row=AAC.Browse.List_GetSelected()
    U.searchItem=row and {itemID=row.itemid,name=row.name,link=row.link or row.hyperlink} or nil
    U.Open("all",U.searchItem and U.searchItem.itemID)
end
function U.CreateFromSearch()
    local _,row=AAC.Browse.List_GetSelected()
    if not row then return end
    if not U.Open("create") then return end
    U.itemID=nil;U.itemName=nil
    if row then U.PickItem(row.link or row.hyperlink or (row.itemid and string.format("|Hitem:%x|h[%s]|h",row.itemid,row.name or ""))) end
    U.Render()
end
function U.AcceptsItem()
    return U.mode=="create" or U.mode=="mine" or U.mode=="all" or U.mode=="sellable"
end
function U.PickItem(link)
    if not U.AcceptsItem() or busy() then return false end
    local id=AAC.SellerTools.ItemIDFromLink(link)
    if not id then return false end
    if not AAC.BuyOrders.Open() then return false end
    AAC.SellerTools.Close()
    local _,_,name=ParseHyperlink(link)
    if U.mode~="create" then U.needMine=true;U.findQuery="";U.findItems={};set("FindText","") end
    U.itemID=id;U.itemLink=link;U.itemName=name or GetObjectInfo(id,"name") or tostring(id)
    U.mode="create";U.message=nil
    set("Quantity","1");set("Price","");set("OrderTotal","");U.Render();return true
end
function U.Drop()
    if busy() or not CursorHasItem() then return end
    local kind=type(CursorItemType)=="function" and CursorItemType() or GetCursorItemType()
    if kind~="bag" then return end
    local link=GetCursorItemLink()
    if U.PickItem(link) then ItemClipboard_Clear() end
end
-- Extend the native catalogue with the rest of the Arcadia item range.
local extra={nextID=1210000,items={}}
function U.CatalogStep()
    local hub=AuctionHub
    if hub and hub.ItemIndex_Start then hub.ItemIndex_Start() end
    if hub and hub.ItemIndex and not hub.ItemIndex.Done then hub.ItemIndex_Step();return false end
    if extra.nextID>1299999 then return true end
    local last=math.min(1299999,extra.nextID+249)
    for id=extra.nextID,last do
        local class,kind,heap,mode,life,rare=GetObjectInfo(id,"Class","ItemType","MaxHeap","Mode","LiveTimeType","Rare")
        local valid=class==0 and kind~=23 and (heap or 0)>1 and (life or 0)==0
        if valid then
            for _,bit in ipairs({8,10,16,18}) do if math.floor((mode or 0)/2^bit)%2==1 then valid=false end end
            local key="Sys"..id.."_name";local name=TEXT(key)
            if valid and name and name~="" and name~=key then
                extra.items[#extra.items+1]={ID=id,Name=name,Lower=string.lower(name),Rare=rare or 0}
            end
        end
    end
    extra.nextID=last+1
    return extra.nextID>1299999
end
function U.FindMatches(query)
    query=string.lower((query or ""):gsub("^%s*(.-)%s*$","%1"))
    local result,seen={},{}
    for _,items in ipairs({AuctionHub and AuctionHub.ItemIndex and AuctionHub.ItemIndex.Items or {},extra.items}) do
        for _,item in ipairs(items) do
            local at=string.find(item.Lower or string.lower(item.Name),query,1,true)
            if at and not seen[item.ID] then result[#result+1]=item;seen[item.ID]=true end
        end
    end
    table.sort(result,function(a,b)
        local ap=(a.Lower or string.lower(a.Name)):sub(1,#query)==query
        local bp=(b.Lower or string.lower(b.Name)):sub(1,#query)==query
        if ap~=bp then return ap end
        if #a.Name~=#b.Name then return #a.Name<#b.Name end
        return a.Name<b.Name
    end)
    return result
end
function U.FindChanged()
    U.findQuery=f("FindText"):GetText() or "";U.findDirty=true;U.findPage=1
    U.findItems={};U.Render()
end
function U.FindTick()
    U.StartPending()
    if U.mode=="create" and U.needMine and not busy() then
        U.needMine=nil;AAC.BuyOrders.Search("mine",0)
    end
    if U.mode~="create" or not U.findDirty then return end
    if #(U.findQuery or "")<3 then U.findDirty=nil;U.Render();return end
    local done=U.CatalogStep()
    if not done then set("FindStatus",U.Text("waiting"));return end
    U.findDirty=nil;U.findItems=U.FindMatches(U.findQuery);U.Render()
end
function U.PickFound(index)
    if GameTooltip then GameTooltip:Hide() end
    local item=U.findItems and U.findItems[((U.findPage or 1)-1)*4+index]
    if item and U.PickItem(string.format("|Hitem:%x|h[%s]|h",item.ID,item.Name)) then
        set("FindText","");set("FindStatus","");f("FindText"):ClearFocus();U.findQuery="";U.findDirty=nil;U.findItems={};U.Render()
    end
end
-- Editing the total never raises the requested budget: the server uses integer unit prices.
function U.UpdateNet(editing)
    local rate=AAC.BuyOrders.NetRate and AAC.BuyOrders.NetRate(U.currency)
    local n=tonumber(f("Quantity"):GetText());local price=tonumber(f("Price"):GetText())
    local net=rate and n and n>0 and price and AAC.BuyOrders.NetAmount(n*price,rate,U.currency)
    U.updatingPrice=true
    if editing~="NetPrice" then set("NetPrice",net and string.format("%.2f",net/n) or "") end
    if editing~="NetTotal" then set("NetTotal",net and tostring(net) or "") end
    U.updatingPrice=nil
    enable("NetPrice",rate~=nil);enable("NetTotal",rate~=nil)
    set("NetHint",rate and U.Text("netHint") or U.Text("netUnknown"))
end
function U.PriceChanged(source)
    if U.updatingPrice then return end
    U.updatingPrice=true
    local n=tonumber(f("Quantity"):GetText())
    local price=tonumber(f("Price"):GetText())
    if source=="NetPrice" or source=="NetTotal" then
        local wanted=tonumber(f(source):GetText())
        if source=="NetPrice" then wanted=wanted and n and wanted*n end
        local rate=AAC.BuyOrders.NetRate and AAC.BuyOrders.NetRate(U.currency)
        price=AAC.BuyOrders.GrossUnitForNet and AAC.BuyOrders.GrossUnitForNet(wanted,n,rate,U.currency)
        set("Price",price and tostring(price) or "")
        set("OrderTotal",price and tostring(price*n) or "")
    elseif source=="OrderTotal" then
        local total=tonumber(f("OrderTotal"):GetText())
        price=n and n>0 and n==math.floor(n) and total and math.floor(total/n) or nil
        set("Price",price and price>0 and tostring(price) or "")
    else
        set("OrderTotal",n and price and tostring(n*price) or "")
    end
    U.updatingPrice=nil
    U.netEditing=(source=="NetPrice" or source=="NetTotal") and source or nil
    U.Render()
    U.netEditing=nil
end
function U.SettleTotal()
    U.PriceChanged("Price")
end
function U.Currency(mode)
    U.currency=mode;U.Render()
end
function U.Select(row)
    U.selected=row;U.Render()
end
function U.Refresh()
    if U.mode and not busy() then AAC.BuyOrders.Search(U.mode,U.queryItemID or 0) end
end
function U.Page(delta)
    if U.mode=="create" and #(U.findQuery or "")>=3 then U.findPage=(U.findPage or 1)+delta;U.Render();return end
    U.page=U.page+delta;U.selected=nil;U.Render()
end
function U.Tooltip(row,frame)
    if not row then return end
    GameTooltip:SetOwner(frame,"ANCHOR_RIGHT",0,0)
    if row.link then GameTooltip:SetHyperLink(row.link)
    elseif row.itemID then GameTooltip:SetHyperLink(string.format("|Hitem:%x|h[%s]|h",row.itemID,row.name or "")) end
    GameTooltip:Show()
end
function U.ListAction()
    if U.mode=="create" then U.CancelSelected() else U.Action() end
end
function U.CancelSelected()
    if U.selected then AAC.BuyOrders.PreviewCancel(U.selected.id) end
end
function U.Action()
    local r=U.selected
    if U.mode=="create" then
        AAC.BuyOrders.PreviewCreate(U.itemID,tonumber(f("Quantity"):GetText()),tonumber(f("Price"):GetText()),U.currency)
    elseif r and U.mode=="mine" then AAC.BuyOrders.PreviewCancel(r.id)
    elseif r and U.mode=="recent" then
        -- Leave the child panel before staging; never close the pending repeat afterwards.
        local entry=r
        U.Close();AAC.Main.ClickTab(3)
        if AAC.Exchange then AAC.Exchange.UseMoneyAuction(false) end
        if not AAC.SellerTools.StageRepeat(entry) then
            local message=AAC.SellerTools.status
            U.Open("recent");U.message=message
        end
    elseif r and (U.mode=="sellable" or U.mode=="all") then AAC.BuyOrders.PreviewSell(r.id) end
    U.Render()
end
function U.Render()
    if not U.mode or not AAC_TradingPanel or not AAC_TradingPanel:IsVisible() then return end
    for _,pair in ipairs({{"Back","back"},{"BuyersCaption","buyers"},{"MineCaption","mine"},{"AllCaption","all"},{"New","create"}}) do set(pair[1],U.Text(pair[2])) end
    local create=U.mode=="create"
    local finding=create and #(U.findQuery or "")>=3
    visible("List",not finding);visible("Form",create)
    f("List"):ClearAllAnchors();f("List"):SetAnchor("TOPLEFT","TOPLEFT",AAC_TradingPanel,0,create and 286 or 64)
    f("List"):SetHeight(create and 110 or 310)
    visible("OwnHeading",create and not finding);set("OwnHeading",U.Text("mine"))
    for i=1,4 do
        local item=finding and U.findItems and U.findItems[((U.findPage or 1)-1)*4+i]
        visible("Pick"..i,not not item)
        if item then
            f("Pick"..i).row={itemID=item.ID,name=item.Name}
            set("Pick"..i.."Name",item.Name)
            f("Pick"..i.."Icon"):SetTexture(GetObjectInfo(GetObjectInfo(item.ID,"ImageID") or 0,"ActField") or "")
        end
    end
    visible("FindStatus",finding and (U.findDirty or #(U.findItems or {})==0))
    set("FindStatus",U.Text(U.findDirty and "waiting" or "empty"))
    visible("Prev",false);visible("Next",false);visible("Page",false)
    local orders=U.mode=="sellable" or U.mode=="all" or U.mode=="mine"
    for name,mode in pairs({All="all",Buyers="sellable",Mine="mine"}) do
        visible(name,orders);f(name):SetChecked(U.mode==mode)
    end
    visible("New",orders);visible("FormHelp",false)
    set("FormHelp",U.Text("drop"));visible("Finder",create);set("FindLabel",U.Text("findItem"))
    visible("Title",not (AAC.Main and AAC.Main.CurrentTab=="BUY"))
    set("Title",U.Text(({sellable="buyers",all="orders",mine="mine",prices="prices",recent="recent",create="create"})[U.mode]))
    if U.mode=="all" and U.queryItemID and U.searchItem then set("Title",U.Text("orders")..": "..(U.searchItem.name or "")) end
    set("Hint",U.message or (U.mode=="prices" and AAC.SellerTools.status or U.mode=="recent" and "" or AAC.BuyOrders.status or ""))
    local locked=busy()
    for _,n in ipairs({"Buyers","Mine","All","New","Reload"}) do enable(n,not locked) end
    visible("Action",false)
    visible("Reload",U.mode=="sellable" or U.mode=="all" or U.mode=="mine")
    set("Reload",U.Text("refresh"))
    if create then
        set("ItemLabel",U.Text("item"));set("OrderTotalLabel",U.Text("grossTotal"))
        set("NetPriceLabel",U.Text("netPrice"));set("NetTotalLabel",U.Text("netTotal"))
        set("ItemName",U.itemName or U.Text("chooseItem"));set("QuantityLabel",U.Text("amount"));set("PriceLabel",U.Text("grossPrice"))
        visible("ItemIcon",U.itemID~=nil)
        if U.itemID then f("ItemIcon"):SetTexture(GetObjectInfo(GetObjectInfo(U.itemID,"ImageID") or 0,"ActField") or "") end
        set("GoldCaption",TEXT("SYS_MONEY_TYPE_0"));set("DiamondCaption",TEXT("SYS_MONEY_TYPE_1"))
        f("Gold"):SetChecked(U.currency=="copper");f("Diamond"):SetChecked(U.currency=="account")
        local dias=type(IsAuctionItemAccountMoneyTrade)=="function" and IsAuctionItemAccountMoneyTrade()
        visible("Diamond",dias);if not dias then U.currency="copper";f("Gold"):SetChecked(true) end
        local n=tonumber(f("Quantity"):GetText());local price=tonumber(f("Price"):GetText());local fee,reserve
        if n and n>0 and n<=9999 and n==math.floor(n) and price and price>0 and price==math.floor(price) and type(Auction_BuyOrderPlacementFee)=="function" then
            fee,reserve=Auction_BuyOrderPlacementFee(n,price,U.currency=="account" and 2 or 1)
        end
        set("Totals",fee and reserve and (U.Text("reserved")..": "..money(reserve,U.currency).."  |  "..U.Text("fee")..": "..money(fee,U.currency).."  |  "..U.Text("total")..": "..money(reserve+fee,U.currency)) or "—")
        U.UpdateNet(U.netEditing)
        set("FormAction",U.Text("review"));enable("FormAction",not locked and U.itemID and fee and reserve)
        set("Detail","");visible("Detail",false);visible("Hint",true)
        if finding then
            local pages=math.max(1,math.ceil(#(U.findItems or {})/4))
            U.findPage=math.max(1,math.min(pages,U.findPage or 1))
            visible("Prev",pages>1);visible("Next",pages>1);visible("Page",pages>1)
            set("Page",U.findPage.." / "..pages);enable("Prev",U.findPage>1);enable("Next",U.findPage<pages)
            return
        end
    end
    local rows=U.Rows();local perPage=create and 2 or 7;local pages=math.max(1,math.ceil(#rows/perPage));U.page=math.min(pages,math.max(1,U.page))
    if U.selected and U.mode~="prices" and U.mode~="recent" then
        local id=U.selected.id;U.selected=nil
        for _,r in ipairs(rows) do if r.id==id then U.selected=r;break end end
    end
    visible("Prev",pages>1);visible("Next",pages>1);visible("Page",pages>1)
    set("Page",U.page.." / "..pages);enable("Prev",U.page>1);enable("Next",U.page<pages)
    set("ItemHead",U.Text("item"));set("QuantityHead",U.Text("amount"));set("PriceHead",U.Text("unit"));set("InfoHead",U.Text("info"))
    for i=1,7 do
        local r=i<=perPage and rows[(U.page-1)*perPage+i] or nil;local widget=f("Row"..i);widget.row=r;visible("Row"..i,i<=perPage)
        set("Row"..i.."Name",r and (r.name or "") or i==1 and U.Text(U.mode=="recent" and "recentEmpty" or "empty") or "")
        set("Row"..i.."Quantity",r and number(r.wanted or r.count or r.quantity) or "")
        AAC.UX.PaintUnit(f("Row"..i.."Price"),f("Row"..i.."PriceIcon"),r and {count=1,buyoutPrice=r.unit or r.unitPrice,moneyMode=r.mode})
        local info=""
        if r then
            if U.mode=="prices" then info=U.Text(r.state)
            elseif U.mode=="mine" or create then info=U.Text("filled")..": "..number(r.filled).." / "..number(r.quantity)
            elseif U.mode=="recent" then info=AAC.Sell.GetDurationText(r.duration)
            else info=r.buyer or "" end
            widget:Enable();if r==U.selected then widget:LockHighlight() else widget:UnlockHighlight() end
        else widget:Disable();widget:UnlockHighlight() end
        set("Row"..i.."Info",info)
        visible("Row"..i.."Icon",r~=nil)
        if r then f("Row"..i.."Icon"):SetTexture(r.texture or GetObjectInfo(GetObjectInfo(r.itemID,"ImageID") or 0,"ActField") or "") end
    end
    local r=U.selected;local detail=""
    if r then
        if U.mode=="prices" then detail=U.Text(r.state)..(r.market and " — "..money(r.market,r.mode).." / "..U.Text("item") or "")
        elseif U.mode=="recent" then detail=""
        elseif U.mode=="mine" or create then detail=(r.name or "").." — "..U.Text("filled")..": "..number(r.filled).." / "..number(r.quantity)
        else detail=U.Text("received")..": "..money(r.net,r.mode).." ("..number(r.sellCount).."×)" end
    end
    set("Detail",detail)
    local status=U.message or (orders and AAC.BuyOrders.status)
    local hasStatus=status and status~=""
    visible("Hint",r==nil or hasStatus);visible("Detail",not hasStatus)
    visible("Action",r~=nil and U.mode~="prices")
    set("Action",U.Text(U.mode=="recent" and "prepare" or (U.mode=="mine" or create) and "cancel" or "sell"))
    enable("Action",not locked and r and (U.mode=="recent" or U.mode=="mine" or create or (not r.isMine and (r.sellCount or 0)>0)))
end
function U.Init()
    if AAC_AuctionFrameTab2 then
        AAC_AuctionFrameTab2:SetText(U.Text("purchases"))
        PanelTemplates_TabResize(AAC_AuctionFrameTab2,20)
    end
    AAC.BuyOrders.OnChanged=U.Render;AAC.SellerTools.OnChanged=U.Render
    AAC_SellPromotionLabel:SetText(U.Text("promotion"))
    AAC_SellHeaderPromotionLeftTime:SetText(U.Text("promotionTime"))
    set("SellPrices",U.Text("prices"));set("SellRecent",U.Text("recent"))
end
