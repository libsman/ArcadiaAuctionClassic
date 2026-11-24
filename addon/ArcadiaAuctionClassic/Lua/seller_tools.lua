-- Read-only market comparison and preparation of a repeat listing.
AAC.SellerTools = { rows = {} }
local S = AAC.SellerTools
-- ParseHyperlink is the client API; GetItemIdFromLink is only a private Sell helper.
function S.ItemIDFromLink(link)
    if type(link) ~= "string" then return nil end
    local kind, data = ParseHyperlink(link)
    if kind ~= "item" or type(data) ~= "string" then return nil end
    local hex = data:match("^([%x]+)")
    return hex and tonumber(hex, 16) or nil
end
local function changed() if S.OnChanged then S.OnChanged() end end
local function text(key)
    return AAC.TradingUI and AAC.TradingUI.Text(key) or key
end
local function idle()
    return AAC.CanRequest() and not AAC.Market.Blocked() and not AAC.Market.HasConfirmation()
end
local function ownFingerprint()
    local rows={}
    for i=1,GetAuctionNumSellItems() do
        local _,count,_,_,_,_,_,mode,_,price=GetAuctionSellItemInfo(i)
        rows[#rows+1]=table.concat({GetAuctionSellItemLink(i) or "",tostring(count),tostring(mode),tostring(price)},";")
    end
    table.sort(rows);return table.concat(rows,"\n")
end
function S.Comparable(id)
    -- Rolled equipment and stat-bearing mana stones cannot be priced by base ID.
    return type(id)=="number" and not (id>=202840 and id<=202859)
        and not (id>=1248061 and id<=1248080)
        and id~=200000 and id~=200003 and (tonumber(GetObjectInfo(id,"maxheap")) or 0)>1
end
function S.Init()
    AAC_RecentListings = AAC_RecentListings or {}
    SaveVariablesPerCharacter("AAC_RecentListings")
end
function S.Recent() return AAC_RecentListings or {} end
function S.Record(o)
    if o.lotMode or not o.itemID or not o.link or not o.count or o.count<=0 then return end
    AAC_RecentListings = AAC_RecentListings or {}
    local row={itemID=o.itemID,name=o.name,link=o.link,count=o.count,total=o.buyout,unit=o.buyout/o.count,
        mode=o.mode,duration=o.duration,promote=o.promote,promoteTime=o.promoteTime}
    table.insert(AAC_RecentListings,1,row)
    while #AAC_RecentListings>20 do table.remove(AAC_RecentListings) end
    changed()
end
function S.RepeatPrice(entry,count)
    if entry.total and entry.count and entry.count>0 then
        if count==entry.count then return entry.total end
        return math.ceil(entry.total*count/entry.count)
    end
    return math.ceil(entry.unit*count)
end
function S.CheckPrices()
    if S.checking or not idle() then return false end
    S.rows={}; S.queue={}; S.status=text("checking"); S.generation=AAC.SessionGeneration
    S.fingerprint=ownFingerprint()
    local seen={}
    for i=1,GetAuctionNumSellItems() do
        local name,count,_,texture,_,_,_,mode,_,price=GetAuctionSellItemInfo(i)
        local link=GetAuctionSellItemLink(i);local id=S.ItemIDFromLink(link)
        if id and count and count>0 and price and price>0 then
            local r={itemID=id,name=name,count=count,texture=texture,mode=mode,price=price,link=link,
                unit=price/count,state=S.Comparable(id) and "waiting" or "uncomparable"}
            S.rows[#S.rows+1]=r
            if r.state=="waiting" and not seen[id] then
                seen[id]=true;S.queue[#S.queue+1]={itemID=id,name=(name or ""):gsub("%s+%+%d+%s*$","")}
            end
        end
    end
    S.checking=true;changed();return true
end
local function key(count,price,mode) return tostring(count)..":"..tostring(price)..":"..tostring(mode) end
local function complete(entry,message)
    if not S.checking or S.current~=entry or S.generation~=AAC.SessionGeneration then return end
    message=message or (not entry.complete and "incomplete" or nil)
    message=message or (S.fingerprint~=ownFingerprint() and "changed" or nil)
    -- Named own offers may be on a later page than identical anonymous offers.
    -- Resolve anonymous matches only after all pages have arrived.
    if not message then
        for _,o in ipairs(entry.anonymous) do
            if (entry.own[o.key] or 0)>0 then entry.own[o.key]=entry.own[o.key]-1
            else entry.market[o.mode]=math.min(entry.market[o.mode] or o.unit,o.unit) end
        end
    end
    for _,r in ipairs(S.rows) do
        if r.itemID==entry.itemID then
            r.market=not message and entry.market[r.mode] or nil
            r.state=message and "unknown" or (not r.market and "alone" or (r.unit>r.market and "cheaper" or "lowest"))
        end
    end
    S.current=nil;changed()
end
local function collect(entry,page,total,pages)
    if S.current~=entry or S.generation~=AAC.SessionGeneration then return end
    for i=1,math.min(250,total-(page-1)*250) do
        local index,_,count,_,_,_,_,seller,_,mode,_,price,_,_,anonymous=GetAuctionBrowseItemInfo(page,i)
        local id=S.ItemIDFromLink(GetAuctionBrowseItemLink(index))
        if id==entry.itemID and count and count>0 and price and price>0 then
            local k=key(count,price,mode)
            if seller==UnitName("player") then
                entry.own[k]=math.max(0,(entry.own[k] or 0)-1)
            elseif anonymous then
                entry.anonymous[#entry.anonymous+1]={key=k,mode=mode,unit=price/count}
            else
                local unit=price/count
                entry.market[mode]=math.min(entry.market[mode] or unit,unit)
            end
        end
    end
    entry.complete=total==0 or (pages and page>=pages)
end
function S.Event(event)
    -- Also drain the coordinator's retired request after close or timeout.
    AAC.Market.SearchEvent(S,event)
end
function S.Close()
    S.checking=nil;S.queue=nil;S.current=nil;S.repeatPending=nil
    AAC.Market.StopSearch(S)
end
function S.RepeatProtects(link)
    if S.repeatPending and S.repeatPending.link==link then return true end
    if S.repeatAppliedLink==link and link~=nil then return true end
    S.repeatAppliedLink=nil
    return false
end
function S.StageRepeat(entry)
    if not entry or not idle() or S.repeatPending or CursorHasItem() or GetAuctionItemLink() then
        S.status=text("emptySlot");changed();return false
    end
    local _,_,slots=GetBagCount();local chosen,largest
    for pos=1,slots or 0 do
        local page=math.ceil(pos/30)
        local rented,left=GetBagPageLetTime(page)
        if not rented or (left and left>=0) then
            local index,_,_,count,locked,_,id=GetBagItemInfo(pos)
            if id==entry.itemID and not locked and count and count>0 then
                local link=GetBagItemLink(index)
                if (S.Comparable(id) or link==entry.link) and AAC.Sell.CanAuctionBagItem(index)==true then
                    local b={index=index,count=count,link=link}
                    if count==entry.count then chosen=b;break end
                    if not largest or count>largest.count then largest=b end
                end
            end
        end
    end
    chosen=chosen or largest
    if not chosen then S.status=text("noStack");changed();return false end
    S.repeatPending={entry=entry,link=chosen.link,count=chosen.count,session=AAC.SessionGeneration,deadline=GetTime()+5}
    PickupBagItem(chosen.index)
    if AAC.Sell.TryPlaceCursorItem then AAC.Sell.TryPlaceCursorItem() else ClickAuctionItemButton() end
    S.status=text("prepared");changed();return true
end
local function applyRepeat()
    local p=S.repeatPending
    if not p then return end
    if p.session~=AAC.SessionGeneration or not AAC.CanRequest() or GetTime()>p.deadline then S.repeatPending=nil;return end
    if GetAuctionItemLink()~=p.link then return end
    local _,_,count=GetAuctionItem()
    if count~=p.count then S.repeatPending=nil;return end
    S.repeatPending=nil;S.repeatAppliedLink=p.link
    local e=p.entry;local sell=AAC.Sell
    MoneyModeFrame_SetSelected(AAC_SellPayMoneyMode,e.mode=="account" and 2 or 1)
    sell.AuctionPayMoneyTypeChanged()
    local duration=e.duration
    if duration==5 and sell.GetDurationMinutes(5)<=0 then duration=4 end
    AAC_SavedSettings.SellDurationSelected=duration
    AAC.Tools.SetDropDown(AAC_SellDurationDropDown,duration,sell.GetDurationText(duration))
    -- Repeating never silently purchases promotion; the user can choose it in the form.
    AAC_SavedSettings.SellPromoteDropDown=1
    AAC.Tools.SetDropDown(AAC_SellPromoteDropDown,1,sell.PROMOTION_STATUS[1])
    local prior=sell.internal_money_update
    sell.internal_money_update=true
    local white=AAC.Tools.GetWhiteValue(e.itemID) or 1
    AAC.MoneyFrame.SetMoney(AAC_SellPriceBuyoutPPU,e.unit/math.max(white,1))
    AAC.MoneyFrame.SetMoney(AAC_SellPriceBuyout,S.RepeatPrice(e,count))
    sell.internal_money_update=prior
    sell.TestIsAuctionValid();sell.UpdateSaleIncome()
end
function S.Tick()
    applyRepeat()
    if not S.checking or S.current then return end
    if S.generation~=AAC.SessionGeneration or not AAC.CanRequest() then S.Close();return end
    if not S.queue or #S.queue==0 then S.checking=nil;S.status=text(#S.rows==0 and "noOwnOffers" or "checked");changed();return end
    if not idle() then return end
    local e=table.remove(S.queue,1);e.own={};e.market={};e.anonymous={};S.current=e
    for _,r in ipairs(S.rows) do
        if r.itemID==e.itemID then local k=key(r.count,r.price,r.mode);e.own[k]=(e.own[k] or 0)+1 end
    end
    local ok=AAC.Market.StartSearch(S,function()
        AuctionBrowseSearchItem(e.name,nil,nil,nil,1,nil,nil,nil,nil,nil,false)
    end,function(message) complete(e,message) end,function(page,total,pages) collect(e,page,total,pages) end)
    if not ok then S.current=nil;table.insert(S.queue,1,e) end
end
