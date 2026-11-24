-- Classic buy-order controller. Server replies own completion; UI only requests previews.
local B = { rows = {}, status = "", mode = "sellable", total = 0, revision = 0 }
AAC.BuyOrders = B
local POPUP, RESPONSE_TIMEOUT, CONFIRM_TIMEOUT = "AAC_BUYORDER_CONFIRM", 15, 30
local epoch, cache = 0, nil
local text = {
 EN = {
  disabled="Buy orders are unavailable.", busy="Wait for the current request or confirmation.",
  data="Check item, quantity and unit price.", changed="The order, inventory or fee changed. Review it again.",
  money="Insufficient balance.", noStack="No accessible unlocked bag stack.", slot="Empty the cursor and auction item slot first.",
  waiting="Waiting for server…", timeout="No reply yet. Further requests stay blocked until the reply arrives.",
  create="Create this buy order?", sell="Sell into this buy order?", cancel="Cancel this buy order?",
  item="Item", quantity="Quantity", unit="Unit price", reserved="Reserved balance", fee="Fee", total="Total",
  receive="You receive", refund="Refund", kept="Placement fee retained", created="Buy order created.",
  cancelled="Buy order cancelled.", sold="Sold %s. You receive %s; fee %s.", rejected="Request rejected.",
  returned="Taken items are returned by mail.", refundMail="Any refund arrives by mail.",
  own="You cannot sell into your own order.", owner="Only your own order can be cancelled.",
  limit="Active order limit reached.", tooFast="Please wait before trying again.", invalidItem="This item cannot be ordered.",
  small="Amount too small after fees.", failed="Request failed. Check the auction item slot and refresh before retrying.",
 },
 DE = {
  disabled="Kaufaufträge sind nicht verfügbar.", busy="Aktuelle Anfrage oder Bestätigung abwarten.",
  data="Gegenstand, Menge und Stückpreis prüfen.", changed="Auftrag, Inventar oder Gebühr geändert. Erneut prüfen.",
  money="Nicht genug Guthaben.", noStack="Kein zugänglicher, ungesperrter Rucksackstapel.", slot="Mauszeiger und Auktionsplatz zuerst leeren.",
  waiting="Warte auf Server…", timeout="Noch keine Antwort. Weitere Anfragen bleiben bis zur Antwort gesperrt.",
  create="Diesen Kaufauftrag erstellen?", sell="In diesen Kaufauftrag verkaufen?", cancel="Diesen Kaufauftrag stornieren?",
  item="Gegenstand", quantity="Menge", unit="Stückpreis", reserved="Reservierter Betrag", fee="Gebühr", total="Gesamt",
  receive="Du erhältst", refund="Erstattung", kept="Einbehaltene Einstellgebühr", created="Kaufauftrag erstellt.",
  cancelled="Kaufauftrag storniert.", sold="%s verkauft. Du erhältst %s; Gebühr %s.", rejected="Anfrage abgelehnt.",
  returned="Entnommene Gegenstände kommen per Post zurück.", refundMail="Eine Erstattung erfolgt gegebenenfalls per Post.",
  own="In eigene Aufträge kann nicht verkauft werden.", owner="Nur eigene Aufträge können storniert werden.",
  limit="Maximale Anzahl aktiver Aufträge erreicht.", tooFast="Vor dem nächsten Versuch kurz warten.", invalidItem="Dieser Gegenstand kann nicht bestellt werden.",
  small="Betrag nach Gebühren zu klein.", failed="Anfrage fehlgeschlagen. Auktionsplatz prüfen und vor erneutem Versuch aktualisieren.",
 },
}
function B.Text(key)
 if AAC.BuyOrderTranslations and AAC.BuyOrderTranslations[key] then return AAC.BuyOrderTranslations[key] end
 local lang = AAC.UX and AAC.UX.language or "EN"
 return (text[lang] or text.EN)[key] or text.EN[key] or key
end
local function number(n) return AAC.UX and AAC.UX.Number(n,false) or tostring(n) end
function B.Money(amount, mode)
 -- FontStrings in this client do not support WoW's inline texture markup.
 local diamond = mode == "account"
 local currency = TEXT(diamond and "SYS_MONEY_TYPE_1" or "SYS_MONEY_TYPE_0")
 return (diamond and "|cff70cfff" or "|cffffd45c")..number(amount).." "..currency.."|r"
end
local function integer(n, zero)
 return type(n)=="number" and n==n and n >= (zero and 0 or 1) and n<=9007199254740991 and n==math.floor(n)
end
local function changed()
 B.busy = B.query~=nil or B.pending~=nil
 if B.OnChanged then B.OnChanged() end
end
local function status(key)
 B.status = B.Text(key)
 changed()
 return false
end
function B.Busy() return B.query~=nil or B.pending~=nil end
function B.HasConfirmation() return B.confirmation~=nil end
function B.Available()
 if not AAC.FeatureEnabled or not AAC.FeatureEnabled(9097) then return false end
 for _, name in ipairs({"AuctionBuyOrderSearch","GetAuctionNumBuyOrders","GetAuctionBuyOrderInfo",
  "Auction_BuyOrderPlacementFee","AuctionBuyOrderCreate","AuctionBuyOrderSell","AuctionBuyOrderCancel",
  "GetBagCount","GetBagPageLetTime","GetBagItemInfo","GetBagItemLink","GetAuctionItem","GetAuctionItemLink",
  "PickupBagItem","ClickAuctionItemButton","CursorHasItem","GetPlayerMoney"}) do
  if type(_G[name])~="function" then return false end
 end
 return true
end
local function free(reopen)
 if not B.Available() or not AAC.CanRequest() or (B.closed and not reopen) then return status("disabled") end
 local m = AAC.Market
 if B.Busy() or B.HasConfirmation() or (m and ((m.IsClosing and m.IsClosing())
  or (m.Blocked and m.Blocked()) or (m.HasConfirmation and m.HasConfirmation()))) then return status("busy") end
 return true
end
function B.Open()
 if not free(true) then return false end
 B.closed=false
 changed()
 return true
end
local function current(request)
 return request and not request.retired and request.epoch==epoch and request.session==AAC.SessionGeneration
  and not B.closed and AAC.CanRequest()
end
local function stamp(q)
 q.epoch, q.session = epoch, AAC.SessionGeneration
 return q
end
local function copy(t)
 local result = {}
 for k,v in pairs(t) do result[k]=v end
 return result
end
local function stock()
 local result, pages = {}, {}
 local _,_,slots = GetBagCount()
 for pos=1,math.min(360, tonumber(slots) or 0) do
  local page=math.ceil(pos/30)
  if pages[page]==nil then
   local rented,remaining=GetBagPageLetTime(page)
   pages[page]=not rented or (type(remaining)=="number" and remaining>=0)
  end
  if pages[page] then
   local index,_,_,count,locked,_,id=GetBagItemInfo(pos)
   if integer(id) and integer(count) and index and not locked then
    local entry=result[id] or {total=0,count=0}
    result[id]=entry; entry.total=entry.total+count
    if count>entry.count then
     entry.index,entry.pos,entry.count,entry.link=index,pos,count,GetBagItemLink(index)
    end
   end
  end
 end
 return result
end
local function saleFee(gross,rate,mode)
 local fee=math.floor(gross*rate/10000)
 if mode=="account" and gross>0 then fee=math.max(1,fee) end
 return math.min(gross,fee)
end
-- A fresh server list supplies the fee rate. Never invent a default percentage.
function B.NetRate(mode)
 if not current(cache) or B.query then return nil end
 local rate
 for _,row in ipairs(B.rows or {}) do
  if row.mode==mode then
   if not integer(row.feeRate,true) or row.feeRate>=10000 then return nil end
   if rate and rate~=row.feeRate then return nil end
   rate=row.feeRate
  end
 end
 return rate
end
function B.NetAmount(gross,rate,mode)
 if not integer(gross,true) or not integer(rate,true) or rate>=10000 then return nil end
 return gross-saleFee(gross,rate,mode)
end
function B.GrossUnitForNet(wanted,quantity,rate,mode)
 if not integer(wanted) or not integer(quantity) or quantity>9999 or not integer(rate,true) or rate>=10000 then return nil end
 local lo,hi=1,math.floor(9007199254740991/quantity)
 if B.NetAmount(hi*quantity,rate,mode)<wanted then return nil end
 while lo<hi do
  local mid=lo+math.floor((hi-lo)/2)
  if B.NetAmount(mid*quantity,rate,mode)>=wanted then hi=mid else lo=mid+1 end
 end
 return lo
end
local function readRows(mine)
 local rows, bag = {}, stock()
 local count,total=GetAuctionNumBuyOrders(mine)
 if not integer(count,true) or count>5000 then return rows,0 end
 for i=1,count do
  local id,itemID,name,texture,quantity,filled,unitPrice,mode,rate,placement,remaining,buyer,isMine=GetAuctionBuyOrderInfo(i,mine)
  if id and integer(itemID) and integer(quantity) and integer(filled,true) and filled<=quantity
   and integer(unitPrice) and (mode=="copper" or mode=="account") and integer(rate,true) and rate<=10000
   and integer(placement,true) and type(remaining)=="number" and remaining>0 then
   local entry=bag[itemID]
   local wanted=quantity-filled
   local sellCount=entry and math.min(entry.count,wanted) or 0
   local gross=sellCount*unitPrice
   local fee=saleFee(gross,rate,mode)
   rows[#rows+1]={id=id,itemID=itemID,name=name or tostring(itemID),texture=texture,quantity=quantity,
    filled=filled,wanted=wanted,unitPrice=unitPrice,mode=mode,feeRate=rate,placementFee=placement,
    remaining=remaining,buyer=buyer,isMine=isMine==true,inBag=entry and entry.total or 0,
    sellCount=sellCount,gross=gross,fee=fee,net=gross-fee}
  end
 end
 return rows,integer(total,true) and total or count
end
function B.Read()
 if not B.Available() or not current(cache) or B.query then B.rows={};B.total=0
 else B.rows,B.total=readRows(B.mode=="mine") end
 B.revision=B.revision+1
 changed()
 return B.rows
end
function B.Search(mode,itemID)
 if mode~="sellable" and mode~="all" and mode~="mine" then return status("data") end
 itemID=mode=="all" and (itemID or 0) or 0
 if not integer(itemID,true) then return status("data") end
 if not free(true) then return false end
 B.closed=false; B.mode=mode; B.itemID=itemID; B.rows={};B.total=0;cache=nil
 B.query=stamp({mode=mode,itemID=itemID,mine=mode=="mine",sellable=mode=="sellable",deadline=GetTime()+RESPONSE_TIMEOUT})
 B.status=B.Text("waiting")
 local ok,result=pcall(AuctionBuyOrderSearch,itemID,B.query.mine,B.query.sellable)
 if result==false and ok then B.query=nil;status("rejected")
 elseif not ok then status("timeout") end -- a thrown API may already have sent: retain ownership
 changed()
 return ok and result~=false
end
local function find(id)
 if not current(cache) or B.query then return end
 for _,row in ipairs(readRows(B.mode=="mine")) do if tostring(row.id)==tostring(id) then return row end end
end
local orderKeys={"id","itemID","quantity","filled","unitPrice","mode","feeRate","placementFee","buyer","isMine"}
local function sameOrder(a,b)
 if not a or not b then return false end
 for _,key in ipairs(orderKeys) do if a[key]~=b[key] then return false end end
 return b.remaining>0
end
local function createQuote(itemID,quantity,unitPrice,mode)
 if not integer(itemID) or not integer(quantity) or quantity>9999 or not integer(unitPrice)
  or not integer(quantity*unitPrice) or (mode~="copper" and mode~="account") then return nil,"data" end
 if mode=="account" and (type(IsAuctionItemAccountMoneyTrade)~="function" or not IsAuctionItemAccountMoneyTrade()) then return nil,"disabled" end
 local _,total=GetAuctionNumBuyOrders(true)
 if type(total)=="number" and total>=20 then return nil,"limit" end
 local moneyType=mode=="account" and 2 or 1
 local fee,escrow=Auction_BuyOrderPlacementFee(quantity,unitPrice,moneyType)
 if not integer(fee,true) or not integer(escrow) or escrow~=quantity*unitPrice or not integer(fee+escrow) then return nil,"data" end
 if fee+escrow>(GetPlayerMoney(mode) or 0) then return nil,"money" end
 return {itemID=itemID,quantity=quantity,unitPrice=unitPrice,mode=mode,moneyType=moneyType,fee=fee,escrow=escrow,total=fee+escrow}
end
local function emptySlot() return not CursorHasItem() and not GetAuctionItem() end
local function confirm(kind,q,lines)
 B.confirmation=stamp({kind=kind,q=q,deadline=GetTime()+CONFIRM_TIMEOUT})
 B.status=""
 StaticPopup_Show(POPUP,B.Text(kind).."\n"..table.concat(lines,"\n"))
 changed()
 return q
end
function B.Dismiss()
 B.confirmation=nil
 changed()
end
function B.PreviewCreate(itemID,quantity,unitPrice,mode)
 if not free() then return false end
 local q,err=createQuote(itemID,quantity,unitPrice,mode)
 if not q then return status(err) end
 local name=type(GetObjectInfo)=="function" and GetObjectInfo(itemID,"name") or nil
 return confirm("create",q,{B.Text("item")..": "..(name or tostring(itemID)),
  B.Text("quantity")..": "..number(quantity),B.Text("unit")..": "..B.Money(unitPrice,mode),
  B.Text("reserved")..": "..B.Money(q.escrow,mode),B.Text("fee")..": "..B.Money(q.fee,mode),B.Text("total")..": "..B.Money(q.total,mode)})
end
function B.PreviewSell(id)
 if not free() then return false end
 local order=find(id)
 if not order or order.wanted<=0 then return status("changed") end
 if order.isMine then return status("own") end
 if not emptySlot() then return status("slot") end
 local s=stock()[order.itemID]
 if not s or not s.link then return status("noStack") end
 local q=copy(order); q.order=copy(order);q.stock=copy(s);q.count=math.min(s.count,order.wanted)
 q.gross=q.count*q.unitPrice;q.fee=saleFee(q.gross,q.feeRate,q.mode);q.net=q.gross-q.fee
 return confirm("sell",q,{q.name.." × "..number(q.count),B.Text("unit")..": "..B.Money(q.unitPrice,q.mode),
  B.Text("total")..": "..B.Money(q.gross,q.mode),B.Text("fee")..": "..B.Money(q.fee,q.mode),B.Text("receive")..": "..B.Money(q.net,q.mode)})
end
function B.PreviewCancel(id)
 if not free() then return false end
 local order=find(id)
 if not order or not order.isMine or order.wanted<=0 then return status("owner") end
 local q=copy(order);q.order=copy(order);q.refund=q.wanted*q.unitPrice
 return confirm("cancel",q,{q.name.." × "..number(q.wanted),B.Text("refund")..": "..B.Money(q.refund,q.mode),
  B.Text("kept")..": "..B.Money(q.placementFee,q.mode),B.Text("refundMail")})
end
function B.Accept()
 local request=B.confirmation
 if not request then return false end
 -- Remove only our confirmation before coordinator checks (the coordinator includes this controller).
 B.confirmation=nil
 StaticPopup_Hide(POPUP)
 if not current(request) or GetTime()>=request.deadline then return status("changed") end
 if not free() then return false end
 local q=request.q
 if request.kind=="create" then
  local latest=createQuote(q.itemID,q.quantity,q.unitPrice,q.mode)
  if not latest or latest.fee~=q.fee or latest.escrow~=q.escrow then return status("changed") end
 else
  if not sameOrder(q.order,find(q.id)) then return status("changed") end
  if request.kind=="sell" then
   local latest=stock()[q.itemID]
   if not latest or not emptySlot() then return status("changed") end
   for _,key in ipairs({"pos","index","count","link"}) do if latest[key]~=q.stock[key] then return status("changed") end end
   -- Re-read the exact native slot immediately before moving it; no name-only matches.
   local index,_,_,count,locked,_,itemID=GetBagItemInfo(q.stock.pos)
   if index~=q.stock.index or count~=q.stock.count or locked or itemID~=q.itemID
    or GetBagItemLink(index)~=q.stock.link then return status("changed") end
   PickupBagItem(index)
   ClickAuctionItemButton()
   local _,_,stagedCount=GetAuctionItem()
   if CursorHasItem() or stagedCount~=q.stock.count or GetAuctionItemLink()~=q.stock.link then return status("changed") end
   -- Staging can run addon hooks and synchronous events. Recheck session/order after them as well.
   if not current(request) or not sameOrder(q.order,find(q.id)) then return status("changed") end
   if not free() then return false end
  end
 end
 B.pending=stamp({action=string.upper(request.kind),id=q.id,q=q,deadline=GetTime()+RESPONSE_TIMEOUT})
 B.status=B.Text("waiting")
 local ok,result
 if request.kind=="create" then ok,result=pcall(AuctionBuyOrderCreate,q.itemID,q.quantity,q.unitPrice,q.moneyType)
 elseif request.kind=="sell" then ok,result=pcall(AuctionBuyOrderSell,q.id)
 else ok,result=pcall(AuctionBuyOrderCancel,q.id) end
 if ok and result==false then B.pending=nil;cache=nil;B.rows={};status("failed")
 elseif not ok then status("timeout") end
 changed()
 return ok and result~=false
end
function B.Close()
 epoch=epoch+1; B.closed=true; cache=nil; B.rows={};B.total=0;B.status=""
 if B.query then B.query.retired=true end
 if B.pending then B.pending.retired=true end
 B.confirmation=nil
 StaticPopup_Hide(POPUP)
 changed()
end
function B.Tick()
 local now=GetTime()
 if B.confirmation and (now>=B.confirmation.deadline or not current(B.confirmation)) then
  B.confirmation=nil;StaticPopup_Hide(POPUP);status("changed")
 end
 local wait=B.pending or B.query
 if wait and not wait.timedOut and now>=wait.deadline then
  wait.timedOut=true
  if current(wait) then status("timeout") end
 end
end
local errors={[1]="disabled",[2]="data",[3]="invalidItem",[4]="money",[5]="limit",[6]="tooFast",[7]="changed",[8]="own",[9]="small",[10]="owner"}
function B.Event(event,a,b,c,d,e,f,g)
 if event=="AUCTION_CLOSE" then B.Close();return end
 if event=="AUCTION_BUYORDER_LIST_UPDATE" then
  local query=B.query
  local mine,sellable=a==true,c==true
  if query and query.mine==mine and (mine or (query.itemID==(b or 0) and query.sellable==sellable)) then
   B.query=nil
   if current(query) then cache=query; B.status=query.completionStatus or "";B.Read() else changed() end
  elseif not mine or B.mode=="mine" then
   -- Another consumer replaced the cache: its rows cannot authorize our transaction.
   cache=nil;B.rows={};B.total=0;changed()
  end
 elseif event=="AUCTION_BUYORDER_RESULT" then
  local p=B.pending
  if not p or p.action~=a or (p.id and (c==nil or tostring(p.id)~=tostring(c))) then return end
  if type(b)~="number" then return end
  B.pending=nil
  if not current(p) then changed();return end
  cache=nil;B.rows={};B.total=0 -- explicit refresh obtains fresh order ownership; never retry a transaction
  if b==0 and a=="SELL" and integer(d) and integer(e,true) and integer(f,true) and f<=e then
   B.status=string.format(B.Text("sold"),number(d),B.Money(e-f,p.q.mode),B.Money(f,p.q.mode))
  elseif b==0 and a=="CREATE" and c~=nil then
   B.status=B.Text("created")
   if AAC.TradingUI and AAC.TradingUI.mode=="create" then
    AAC.TradingUI.selected=nil;AAC.TradingUI.page=1
    B.Search("mine",0)
   end
  elseif b==0 and a=="CANCEL" then
   B.status=B.Text("cancelled")
  else B.status=B.Text(errors[b] or "changed") end
  if a=="SELL" and b~=0 and (tonumber(d) or 0)>0 then B.status=B.status.." "..B.Text("returned") end
  if a=="CANCEL" and g==true then B.status=B.status.." "..B.Text("refundMail") end
  if b==0 and a=="CANCEL" then
   -- Refresh only the list; preserve the confirmed result through its reply.
   local completion=B.status
   if B.Search(B.mode,B.itemID) then
    if B.query then B.query.completionStatus=completion else B.status=completion end
   end
  end
  changed()
 elseif event=="BAG_ITEM_UPDATE" or event=="AUCTION_BUYORDER_FILLED" then
  if current(cache) and not B.Busy() then B.Read() end
 end
end
StaticPopupDialogs[POPUP]={text="%s",button1=TEXT("ACCEPT"),button2=TEXT("CANCEL"),hideOnEscape=1,
 OnAccept=function() B.Accept() end,OnCancel=function() B.Dismiss() end,OnHide=function() B.Dismiss() end}
