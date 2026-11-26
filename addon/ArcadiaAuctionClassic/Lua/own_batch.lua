-- Own-auction APIs expose row indexes, not persistent auction IDs.
-- Keep the complete ordered snapshot; only our confirmed change may advance it.
local B = { selected = {} }
AAC.OwnBatch = B
function B.FeeRises(row)
    return type(row.feeRate)=="number" and row.feeRate>=0
        and type(row.relistFeeRate)=="number" and row.relistFeeRate>row.feeRate
end
function B.Read()
    local rows={}
    for i=1,GetAuctionNumSellItems() do
        local name,count,_,_,_,left,bidder,mode,bid,price,promote,promoteTime,guild,fee,relist=GetAuctionSellItemInfo(i)
        if not name then return nil end
        rows[i]={realPosition=i,name=name,count=count,link=GetAuctionSellItemLink(i),leftTime=left or 0,
            bidder=bidder or "",moneyMode=mode,bidPrice=bid or 0,buyoutPrice=price or 0,
            promoteType=promote or 0,promoteTime=promoteTime or 0,isGuild=guild==true,
            feeRate=fee,relistFeeRate=relist}
    end
    return rows
end
-- Tooltip/cache flags change on display (client-verified 2026-11-26).
-- Same normalization as purchase identity; all actual item/stat fields remain.
function B.LinkKey(link)
    if type(link)~="string" then return link end
    local payload=link:match("^|Hitem:([^|]+)|h")
    if not payload then return link end
    local fields={}
    for value in payload:gmatch("%S+") do fields[#fields+1]=value end
    local packed=tonumber(fields[3] or "",16)
    if #fields<13 or not packed then return link end
    fields[3]=string.format("%x",packed%16777216)
    fields[12]="0"
    return "item:"..table.concat(fields," ")
end
local identity={"name","count","bidder","moneyMode","bidPrice","buyoutPrice","isGuild","feeRate","relistFeeRate"}
local function same(a,b)
    if not a or not b or B.LinkKey(a.link)~=B.LinkKey(b.link) then return false end
    for _,key in ipairs(identity) do if a[key]~=b[key] then return false end end
    return true
end
function B.SameList(a,b,kind,index,arg,duration)
    if not a or not b or #b~=#a-(kind=="cancel" and 1 or 0) then return false end
    for i,row in ipairs(a) do
        if not (kind=="cancel" and i==index) then
            local other=b[kind=="cancel" and i>index and i-1 or i]
            if not same(row,other) then return false end
            if kind=="extend" and i==index then
                if other.leftTime<row.leftTime+AAC.Sell.GetDurationMinutes(arg)-2 then return false end
            elseif other.leftTime>row.leftTime or other.leftTime<row.leftTime-2 then return false end
            if kind=="promote" and i==index then
                if other.promoteType~=arg or other.promoteTime<AAC.Sell.GetDurationMinutes(duration)-2
                    or (row.promoteType==arg and other.promoteTime<=row.promoteTime) then return false end
            elseif other.promoteType~=row.promoteType or other.promoteTime>row.promoteTime then return false end
        end
    end
    return true
end
function B.Select(index,checked,displayed)
    local rows=B.Read()
    if B.running or not B.SameList(displayed,rows)
        or (B.selectionRows and not B.SameList(B.selectionRows,rows)) then
        B.selected={};B.selectionRows=nil;return false
    end
    local row=rows[index]
    if not row or row.bidder~="" then return false end
    B.selectionRows=B.selectionRows or displayed
    B.selected[index]=checked or nil
    if not next(B.selected) then B.selectionRows=nil end
    return true
end
local function eligible(row,kind,arg,duration)
    if not row.link or row.bidder~="" then return false end
    if kind=="cancel" then return true end
    if kind=="extend" then return arg and arg>=1 and arg<=4
        and row.leftTime+AAC.Sell.GetDurationMinutes(arg)<=AAC.Sell.GetMaxDurationMinutes() end
    return kind=="promote" and AAC.Market.Feature("Promotion") and arg and arg>=1 and arg<=3
        and type(CanAuctionPromoteSell)=="function" and CanAuctionPromoteSell(row.realPosition,arg)
        and AAC.Sell.CanPromoteSelection(row,arg,duration)
end
local function price(row,kind,arg,duration)
    if kind=="cancel" then return 0 end
    if kind=="extend" then return Auction_ExtendPrice(row.realPosition,arg) end
    return Auction_PromoteSellPrice(row.realPosition,arg,duration)
end
function B.Quote(kind,arg,duration)
    local rows=B.Read(); if not B.SameList(B.selectionRows,rows) then return end
    local q={kind=kind,arg=arg,duration=duration,rows=rows,items={},total=0,skipped=0,warningCount=0,
        mode=kind=="promote" and "account" or "copper",session=AAC.SessionGeneration}
    local free=0
    if type(Prestige_PrestigeAvailable)=="function" and Prestige_PrestigeAvailable() then
        free=math.max(0,Prestige_GetChargeCount(PrestigeBenefitType_AuctionHouse_Auctioneer) or 0)
    end
    for i=#rows,1,-1 do
        if B.selected[i] then
            local row=rows[i];local ambiguous=false
            if kind=="cancel" then
                for j,other in ipairs(rows) do if j~=i and same(row,other) then ambiguous=true;break end end
            end
            local cost=not ambiguous and eligible(row,kind,arg,duration) and price(row,kind,arg,duration)
            -- Never quote unlimited free promotions from a finite number of charges.
            if kind=="promote" and cost==0 then
                if free>0 then free=free-1 else cost=nil end
            end
            if type(cost)=="number" and cost>=0 then
                q.items[#q.items+1]={index=i,cost=cost};q.total=q.total+cost
                if kind=="cancel" and B.FeeRises(row) then q.warningCount=q.warningCount+1 end
            else q.skipped=q.skipped+1 end
        end
    end
    return q
end
function B.Close()
    B.running=nil; B.selected={}; B.selectionRows=nil; B.preview=nil
end
local function stop(changed)
    B.running=nil; B.selected={}
    if changed then AAC.Market.Changed() end
    if B.Render then B.Render() end
end
local function sendNext(q)
    if B.running~=q then return end
    local item=q.items[q.next]
    if not item then stop(false);return end
    local rows=B.Read();local row=rows and rows[item.index]
    if not AAC.CanRequest() or q.session~=AAC.SessionGeneration or not B.SameList(q.rows,rows)
        or not row or not eligible(row,q.kind,q.arg,q.duration)
        or price(row,q.kind,q.arg,q.duration)~=item.cost or item.cost>GetPlayerMoney(q.mode) then stop(true);return end
    q.rows=rows;q.confirmed=false
    local submitted=AAC.Market.Submit("own-batch",function()
        if B.running~=q then return false end
        local latest=B.Read()
        if not B.SameList(q.rows,latest,q.kind,item.index,q.arg,q.duration) then return false end
        q.confirmed=true;q.after=latest;return true
    end,function()
        if q.kind=="cancel" then AuctionCancelSell(item.index)
        elseif q.kind=="extend" then AuctionExtendSell(item.index,q.arg)
        else AuctionPromoteSell(item.index,q.arg,q.duration) end
    end)
    if not submitted then stop(true) end
end
function B.Start(q)
    if B.running or not q or #q.items==0 or q.session~=AAC.SessionGeneration
        or not AAC.CanRequest() or AAC.Market.Blocked() then return false end
    if not B.SameList(q.rows,B.Read()) or q.total>GetPlayerMoney(q.mode) then AAC.Market.Changed();return false end
    -- Revalidate every quoted price before spending anything.
    for _,item in ipairs(q.items) do
        local row=q.rows[item.index]
        if not eligible(row,q.kind,q.arg,q.duration) or price(row,q.kind,q.arg,q.duration)~=item.cost then
            AAC.Market.Changed();return false
        end
    end
    B.selected={};q.next=1;B.running=q;sendNext(q);return B.running~=nil
end
function B.Tick()
    local q=B.running;if not q then return end
    if not AAC.CanRequest() or q.session~=AAC.SessionGeneration then stop(false);return end
    if AAC.Market.TransactionPending() then return end
    if not q.confirmed then stop(true);return end
    q.rows=q.after;q.next=q.next+1;sendNext(q)
end
