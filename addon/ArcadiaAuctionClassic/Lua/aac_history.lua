local History = {
    PriceHistoryQueue={},

	TooltipHeight = 0,
	TooltipWidth = 0,
	Processing = true,


    BrowseItemLink = nil,
}
AAC.History = History
AAC_HISTORY_SORTMODE = "DATE_DES"
HISTORYDATA_AAC = {}
AAC_SavedHistoryTable = {}

-- CONSTANTS
local MAX_ITEM_DISPLAY = 10

-- DB Version
local DB_REV_V1 = 20121119130745 -- removed unused data
local DB_REV_V2 = 20140517161524 -- converted to indexed based

-- DB Index
 -- if changed, change: convertOldDB
local DB_HASH   =1
local DB_ICON   =2
local DB_HISTORY=3
local DB_MONEYTYPE =4
local DB_AVG =5 -- only valid if 'DontSaveHistory'
local DB_MIN =6 -- only valid if 'DontSaveHistory'
local DB_MAX =7 -- only valid if 'DontSaveHistory'
local DB_MED =8 -- only valid if 'DontSaveHistory'
local DB_COUNT=9-- only valid if 'DontSaveHistory'

 -- if changed, change: convertOldDB, Queue_AddHistory and init too
local DB_HISTORY_DATE   =1
local DB_HISTORY_PRICE  =2
local DB_HISTORY_SELLER =3
local DB_HISTORY_BUYER  =4
local DB_HISTORY_COUNT  =5
local DB_HISTORY_ICON   =6
local DB_HISTORY_MONEYTYPE =7
local DB_HISTORY_RARITY =8


local function DontSaveHistory()
    return (AAC_SavedSettings.HistoryMaxSaved <= 10)
end


function History.Init()

    -- see constant comment
    assert( DB_HISTORY_DATE ==1 and
            DB_HISTORY_PRICE ==2 and
            DB_HISTORY_SELLER ==3 and
            DB_HISTORY_BUYER  ==4 and
            DB_HISTORY_COUNT  ==5 and
            DB_HISTORY_ICON   ==6 and
            DB_HISTORY_MONEYTYPE ==7 and
            DB_HISTORY_RARITY ==8)

    assert( DB_HASH    ==1 and
            DB_ICON    ==2 and
            DB_HISTORY ==3 and
            DB_MONEYTYPE ==4 and
            DB_AVG ==5)


    local build = (AAC_SavedHistoryTable._TABLEBUILD or 0)

	if build < DB_REV_V2 then
        History.convertOldDB()
		build = DB_REV_V2
    end

   -- AAC_SavedHistoryTable._TABLEBUILD = build
	--SaveVariables("AAC_SavedHistoryTable")

    AAC_SavedHistoryTable = {};

    History.SetMaxEntries(AAC_SavedSettings.HistoryMaxSaved)
end

function History.convertOldDB()

    local newdb = {}
    for id,info in pairs(AAC_SavedHistoryTable) do
        if id~="_TABLEBUILD" then

            if DontSaveHistory() then
                newdb[id]= {
                    info.hash, -- [DB_HASH]
                    info.icon,  -- [DB_ICON]
                    nil,
                    nil,
                    info.avg, -- [DB_AVG]
                    info.min, -- [DB_MIN]
                    info.max, -- [DB_MAX]
                    info.median, --[DB_MED]
                    info.history_count -- [DB_COUNT]
                }
            else

                if info.history and #info.history>0 then

                    newdb[id]= {
                        info.hash, -- [DB_HASH]
                        info.icon, -- [DB_ICON]
                        {},        -- [DB_HISTORY]
                    }
                    for _,dat in pairs(info.history or {}) do
                        table.insert(newdb[id][DB_HISTORY],
                            {
                                dat.date, --[DB_HISTORY_DATE]
                                dat.price, --[DB_HISTORY_PRICE]
                                dat.seller,--[DB_HISTORY_SELLER]
                                dat.buyer,-- [DB_HISTORY_BUYER]
                                dat.count,--[DB_HISTORY_COUNT]
                                dat.icon, -- [DB_HISTORY_ICON]
                                nil, -- [DB_HISTORY_MONEYTYPE]
                                dat.rarity, -- [DB_HISTORY_RARITY]
                            })
                    end
                end
            end
         end
    end

    AAC_SavedHistoryTable = newdb
    AAC_SavedHistoryTable._TABLEBUILD = DB_REV_V2
end

function History.SetMaxEntries(max)
    if max < AAC.Settings.HistoryMin then max = AAC.Settings.HistoryMin end
    if max > AAC.Settings.HistoryMax then max = AAC.Settings.HistoryMax end

	AAC_SavedSettings.HistoryMaxSaved = max

    History.UpdateHistoryEntries()
end

function History.Reset()
    AAC_SavedHistoryTable = {}
end

function History.RemoveItem(itemid)
    if AAC_SavedHistoryTable[itemid] then
		AAC_SavedHistoryTable[itemid] = nil
        return true
    end
end

-- Native AuctionHub expires unanswered history requests after five seconds.
-- SHOW rows carry item links: validate all of them before consuming a request.
local HISTORY_TIMEOUT = 5
local historyReadyAt = 0
local foreground
local backgroundSeen = {}
local MAX_HISTORY_QUEUE = 40

-- Native AuctionHub StatKey layout for basic items (including mana stones).
-- Ignore creation time/checksum; preserve inherent and serialized stats.
local function statKey(link)
    local hex = type(link)=="string" and link:match("|Hitem:(%x+)")
    if not hex or type(GetObjectInfo)~="function" then return nil end
    local class, kind = GetObjectInfo(tonumber(hex,16), "Class", "ItemType")
    if class~=0 or kind==23 then return nil end
    local data = link:match("|Hitem:([^|]+)|h")
    local values, n = {}, 0
    for word in (data or ""):gmatch("%S+") do
        n=n+1
        if (n>=4 and n<=11) or n>=14 then values[#values+1]=word end
    end
    return table.concat(values," ")
end

function History.RequestHistoryPopup(auctionid, itemid, inherent, sell, link)
    itemid = tonumber(itemid)
    if itemid == -1 then itemid = tonumber(inherent) end
    if not AAC.Market.IsClosing() and AAC.CanRequest() and AAC.Market.Feature("PriceHistory") and itemid and itemid > 0 then
        foreground = { itemid = itemid, popup = true, auctionid = auctionid,
            browseLink = link, sell = sell == true,
            stagedLink = sell and GetAuctionItemLink() or nil }
    end
end

function History.UpdateSellItemHistory(itemid)
    if AAC.SellerTools and AAC.SellerTools.RepeatProtects(GetAuctionItemLink()) then return end
    if not AAC.Market.IsClosing() and AAC.CanRequest() and AAC.Market.Feature("PriceHistory") and tonumber(itemid) then
        foreground = {
            itemid = tonumber(itemid), stagedLink = GetAuctionItemLink(), autofill = true, sell = true,
            moneyAuction = AAC.Sell.MoneyAuction, moneyType = AAC.Sell.MoneyType,
        }
    end
end

local function receiveHistory(hasRows)
    local request = History.RequestPending
    if not request then return end
    -- HIDE has no identity and cannot prove which item has no sales. It may
    -- end this wait, but never stores empty results or publishes prices.
    if hasRows and GetAuctionHistoryItemNums() > 0 then
        for i = 1, GetAuctionHistoryItemNums() do
            local link = GetAuctionHistoryItemLink(i)
            local hex = type(link) == "string" and link:match("|Hitem:(%x+)")
            if not hex or tonumber(hex, 16) ~= request.itemid then return end
            if request.statKey~=nil and statKey(link)~=request.statKey then return end
        end
    end
    History.RequestPending = nil
    if request.discard or not AAC.CanRequest() then return end
    if not hasRows or GetAuctionHistoryItemNums() == 0 then return end
    -- Native history displays the fresh response. Never merge a previous
    -- stat variant of this base item into the newly requested variant.
    AAC_SavedHistoryTable[request.itemid] = nil
    History.Queue_AddHistory(request.itemid)
    if request.popup then
        History.curItem = request.itemid
        History.List_Show()
    elseif request.autofill and AAC.Sell.MoneyAuction == request.moneyAuction
        and GetAuctionItemLink() == request.stagedLink
        and (not request.moneyAuction or AAC.Sell.MoneyType == request.moneyType) then
        AAC.Sell.AutoFillPriceFields(true)
    end
end

function AAC.Events.AUCTION_HISTORY_SHOW()
    receiveHistory(true)
end

function AAC.Events.AUCTION_HISTORY_HIDE()
    receiveHistory(false)
end

function History.ClearQueue()
    History.PriceHistoryQueue = {}
    backgroundSeen = {}
end

function History.PrepareClose()
    History.ClearQueue()
    foreground = nil
    if History.RequestPending then History.RequestPending.discard = true end
end

function History.ResetRequests()
    History.PrepareClose()
    History.curItem = nil
end

function History.Queue_Insertitem(auctionid, name, link, itemid)
    if not itemid or not link or backgroundSeen[itemid] or #History.PriceHistoryQueue >= MAX_HISTORY_QUEUE then return end
    backgroundSeen[itemid] = true
    History.PriceHistoryQueue[#History.PriceHistoryQueue + 1] = { itemid = itemid }
end

function History.Tick(now)
    -- Expire even while closed/busy; only sending requires an open idle AH.
    local request = History.RequestPending
    if request and now >= request.deadline then
        History.RequestPending = nil
        if not request.discard and AAC.CanRequest() and not AAC.Market.IsClosing()
            and not foreground and (request.popup or request.autofill) then
            if not request.retried then
                request.retried = true
                foreground = request
            elseif request.popup then
                AAC.Market.Notice(AAC_MARKET_HISTORY_STALLED or "History could not be loaded. Please try again.")
            end
        end
    end
    if AAC.BuyOrders and (AAC.BuyOrders.Busy() or AAC.BuyOrders.HasConfirmation()) then return end
    if not AAC.CanRequest() or not AAC.Market.Feature("PriceHistory") then return end
    if History.RequestPending then return end
    if AAC.Market.IsClosing() or now < historyReadyAt or AAC.Market.Active() then return end
    -- The history list itself reads the client cache while open.
    if AAC_HistoryList and AAC_HistoryList:IsVisible() and not (foreground and foreground.popup) then return end
    if not foreground and not History.Processing then return end
    local request = foreground or table.remove(History.PriceHistoryQueue, 1)
    foreground = nil
    if not request then return end
    if request.popup and AAC_HistoryList then AAC_HistoryList:Hide() end
    request.deadline = now + HISTORY_TIMEOUT
    History.RequestPending = request
    historyReadyAt = now + 1.1
    if request.auctionid and request.browseLink and type(AuctionBrowseHistoryRequest) == "function"
        and GetAuctionBrowseItemLink(request.auctionid) == request.browseLink then
        request.statKey=statKey(request.browseLink)
        AuctionBrowseHistoryRequest(request.auctionid, true)
    elseif request.sell and request.stagedLink and type(AuctionItemHistoryRequest) == "function"
        and GetAuctionItemLink() == request.stagedLink then
        request.statKey=statKey(request.stagedLink)
        AuctionItemHistoryRequest()
    else
        request.statKey=nil
        AuctionItemHistoryRequestByID(request.itemid, 0)
    end
end

local function getSummary(itemid)
    local history = AAC_SavedHistoryTable[itemid]

    local res = {
        totalcost = 0,
        totalcount = 0,
        avg = 0,
        median = 0,
        min=0,
        max=0,
        count = 0
    }

    if not history then
        return res
    end

    if not history[DB_HISTORY] or #history[DB_HISTORY]<=0 then
        res.avg = history[DB_AVG] or 0
        res.median = history[DB_MED] or 0
        res.min = history[DB_MIN] or 0
        res.max = history[DB_MAX] or 0
        res.count = history[DB_COUNT] or 10
        return res
    end

    local ppu = history[DB_HISTORY][1][DB_HISTORY_PRICE] / (history[DB_HISTORY][1][DB_HISTORY_COUNT] or 1)
    res.min = ppu
    res.max = ppu

    local all_ppu = {}
    for _,dat in ipairs(history[DB_HISTORY]) do
        res.totalcost = res.totalcost + dat[DB_HISTORY_PRICE]
        res.totalcount = res.totalcount + (dat[DB_HISTORY_COUNT] or 1)

        local ppu = dat[DB_HISTORY_PRICE] / (dat[DB_HISTORY_COUNT] or 1)
        if res.min > ppu then
            res.min = ppu
        end
        if res.max < ppu then
            res.max = ppu
        end
        table.insert(all_ppu, ppu)
    end

    table.sort(all_ppu)
    local mid = #(all_ppu) / 2 + 0.5
    res.median = (all_ppu[math.floor(mid)] + all_ppu[math.ceil(mid)]) / 2
    res.avg = res.totalcost / res.totalcount

    if itemid==200000 then
        res.avg = 1/res.avg
        res.min = 1/res.min
        res.max = 1/res.max
        res.median = 1/res.median
    end

    return res
end

local function AuctionHistorySort( sortMode )
	if sortMode == "DATE_DES" then
		table.sort(HISTORYDATA_AAC, function(a, b)
			return a[9] < b[9] or (a[9] == b[9] and a[10] < b[10]) or (a[9] == b[9] and a[10] == b[10] and a[11] < b[11])
		end)
	elseif sortMode == "DATE_ASC" then
		table.sort(HISTORYDATA_AAC, function(a, b)
			return a[9] > b[9] or (a[9] == b[9] and a[10] > b[10]) or (a[9] == b[9] and a[10] == b[10] and a[11] > b[11])
		end)
	elseif sortMode == "PRICE_DES" then
		table.sort(HISTORYDATA_AAC, function(a, b)
			return a[8] < b[8]
		end)
	elseif sortMode == "PRICE_ASC" then
		table.sort(HISTORYDATA_AAC, function(a, b)
			return a[8] > b[8]
		end)
	elseif sortMode == "SELLER_DES" then
		table.sort(HISTORYDATA_AAC, function(a, b)
			return a[5] < b[5]
		end)
	elseif sortMode == "SELLER_ASC" then
		table.sort(HISTORYDATA_AAC, function(a, b)
			return a[5] > b[5]
		end)
	elseif sortMode == "BUYER_DES" then
		table.sort(HISTORYDATA_AAC, function(a, b)
			return a[6] < b[6]
		end)
	elseif sortMode == "BUYER_ASC" then
		table.sort(HISTORYDATA_AAC, function(a, b)
			return a[6] > b[6]
		end)
	end
end

function History.Sort_OnEnter( this )
	local titles = {[1] = "AAC_HistoryHeaderDate", [2] = "AAC_HistoryHeaderSeller", [3] = "AAC_HistoryHeaderBuyer", [4] = "AAC_HistoryHeaderPrice"}
	getglobal( titles[this:GetID()]):SetColor( 0, 1, 0 );
end

function History.Sort_OnLeave( this )
	local titles = {[1] = "AAC_HistoryHeaderDate", [2] = "AAC_HistoryHeaderSeller", [3] = "AAC_HistoryHeaderBuyer", [4] = "AAC_HistoryHeaderPrice"}
	getglobal( titles[this:GetID()]):SetColor( 1, 1, 0 );
end

function History.Sort_OnClick(this)
	local id = this:GetID()
	local sortModes = {
		[1] = { "DATE_ASC", "DATE_DES", AAC_HistorySort_DateSort },
		[2] = { "SELLER_ASC", "SELLER_DES", AAC_HistorySort_SellerSort },
		[3] = { "BUYER_ASC", "BUYER_DES", AAC_HistorySort_BuyerSort },
		[4] = { "PRICE_ASC", "PRICE_DES", AAC_HistorySort_PriceSort }
	}
	
	local currentSort = sortModes[id]

	AAC_HistorySort_DateSort:SetFile("")
	AAC_HistorySort_SellerSort:SetFile("")
	AAC_HistorySort_BuyerSort:SetFile("")
	AAC_HistorySort_PriceSort:SetFile("")

	AAC_HISTORY_SORTMODE = AAC_HISTORY_SORTMODE == currentSort[2] and currentSort[1] or currentSort[2]

	local function setIcon(frame, icon)
		if icon == "ASC" then
			frame:SetFile("Interface\\AddOns\\_BuiltIn\\AdvancedAuctionhouse\\Textures\\full_arrow_up")
		elseif icon == "DES" then
			frame:SetFile("Interface\\AddOns\\_BuiltIn\\AdvancedAuctionhouse\\Textures\\full_arrow_down")
		end
	end

	if AAC_HISTORY_SORTMODE == currentSort[1] then
		setIcon(this.Sort, "ASC")
	else
		setIcon(this.Sort, "DES")
	end

	AuctionHistorySort(AAC_HISTORY_SORTMODE)
	History.List_UpdateItems()
end

local function getSortedAuctionHistoryInfo()
	HISTORYDATA_AAC = {}
	local numhistory = GetAuctionHistoryItemNums();
	for i = 1, numhistory do
		local item = { GetAuctionHistoryItemInfo(i) }
		item.index = numhistory - i + 1;
		table.insert( HISTORYDATA_AAC, item );
	end
	local sortMode = AAC_HISTORY_SORTMODE
	AuctionHistorySort( sortMode );
	return HISTORYDATA_AAC
end

local function getAuctionHistoryInfo(itemid, index, items)
	local e = {}
	local year, month, day, hour, minute, second
	local item = items[index]
	e.name = item[1]
	e.count = item[2]
	e.rarity = item[3]
	e.icon = item[4] 
	e.seller = item[5]
	e.buyer = item[6]
	e.moneyType = item[7]
	e.price = item[8]
	e.newIndex = item.index
	year, month, day, hour, minute, second = item[9], item[10], item[11], item[12], item[13], item[14]

    if itemid==200000 or itemid==200003 then
		e.count = tonumber(string.match(e.name:gsub( "%.", "" ):gsub( ",", "" ), "(%d+)" ) or "1") or 1
        e.name = TEXT("Sys"..itemid.."_name")
    end

    local hash = ""
    hash = hash.. month
    hash = hash.. day
    hash = hash.. hour
    hash = hash.. minute
    hash = hash.. year
    hash = hash.. second
    hash = hash.. e.count
    hash = hash.. e.seller
    hash = hash.. e.buyer
    hash = hash.. e.price

    e.date = string.format("%02d-%02d-%02d\n%02d:%02d:%02d", day,month,year,hour,minute,second)
    e.ppu = e.price / e.count
    if itemid==200000 then e.ppu = 1/e.ppu end

    return e, hash
end

local function getAuctionHistoryFromHistory(itemid, index)

    local base = AAC_SavedHistoryTable[itemid]

    local e={
        date = base[DB_HISTORY][index][DB_HISTORY_DATE],
        price = base[DB_HISTORY][index][DB_HISTORY_PRICE],
        seller = base[DB_HISTORY][index][DB_HISTORY_SELLER],
        buyer = base[DB_HISTORY][index][DB_HISTORY_BUYER],
        count = base[DB_HISTORY][index][DB_HISTORY_COUNT]   or 1,
        rarity = base[DB_HISTORY][index][DB_HISTORY_RARITY] or GetQualityByGUID(itemid),
        icon = base[DB_HISTORY][index][DB_HISTORY_ICON]     or base[DB_ICON],
        moneyType = base[DB_HISTORY][index][DB_HISTORY_MONEYTYPE] or base[DB_MONEYTYPE] or "copper",
    }

    e.ppu = e.price / e.count
    if itemid==200000 then e.ppu = 1/e.ppu end

    return e
end

local function removeHistory(itemid)

    local curitem = AAC_SavedHistoryTable[itemid]
    if not curitem then return end

    curitem[DB_HASH] = nil
    if curitem[DB_HISTORY] and #curitem[DB_HISTORY]>0 then
        local stats = getSummary(itemid)

        curitem[DB_AVG] = stats.avg
        curitem[DB_MIN] = stats.min
        curitem[DB_MAX] = stats.max
        curitem[DB_MED] = stats.median

        if #curitem[DB_HISTORY]<10 then
            curitem[DB_COUNT] = #curitem[DB_HISTORY]
        else
            curitem[DB_COUNT] = nil
        end
    end

    curitem[DB_HISTORY] = nil
end

function History.Queue_AddHistory(itemid)
    --assert(itemid,"no history item")
    if itemid == nil then return; end

    local cur_item = AAC_SavedHistoryTable[itemid]

	-- Snapshot and sort once per response, not once per history row.
	local items = getSortedAuctionHistoryInfo()
	local maxnums = #items
	local startplace = 1
    if cur_item then
        for i = maxnums, 1, -1 do
            local _, hash = getAuctionHistoryInfo(itemid, i, items)
            if hash == cur_item[DB_HASH] then
                startplace = i + 1
                break
            end
        end
    else

        AAC_SavedHistoryTable[itemid] = {0,0,{} }
        cur_item = AAC_SavedHistoryTable[itemid]
        local _,_,_,icon,_,_,moneyType = GetAuctionHistoryItemInfo(1)
        cur_item[DB_ICON] = icon
        if moneyType~='copper' then
            cur_item[DB_MONEYTYPE] = moneyType
        end
    end

    cur_item[DB_HISTORY] = cur_item[DB_HISTORY] or {}
    local history = cur_item[DB_HISTORY]
    for i = startplace, maxnums do

        local entry,hash = getAuctionHistoryInfo(itemid, i, items)
        local newent=
        {
            entry.date, --[DB_HISTORY_DATE]
            entry.price, -- [DB_HISTORY_PRICE]
            entry.seller, -- [DB_HISTORY_SELLER]
            entry.buyer, -- [DB_HISTORY_BUYER]
        }

        if entry.count ~= 1 then newent[DB_HISTORY_COUNT] = entry.count end
        if entry.icon ~= cur_item[DB_ICON] then newent[DB_HISTORY_ICON] = entry.icon end
        if entry.moneyType ~= (cur_item[DB_MONEYTYPE] or "copper") then newent[DB_HISTORY_MONEYTYPE] = entry.moneyType end
        if entry.rarity ~= GetQualityByGUID(itemid) then newent[DB_HISTORY_RARITY] = entry.rarity end

        -- while #history >= AAC_SavedSettings.HistoryMaxSaved do
        --     table.remove(history, #history)
        -- end
        table.insert(history, 1, newent)
        cur_item[DB_HASH] = hash
    end
end

----------------------------------
function History.UpdateHistoryEntries()

    if DontSaveHistory() then
        for id, h in pairs(AAC_SavedHistoryTable) do
            if id~="_TABLEBUILD" then
                removeHistory(id)
            end
        end
    else
        for id, h in pairs(AAC_SavedHistoryTable) do
            if id~="_TABLEBUILD" then
                while h[DB_HISTORY] and #h[DB_HISTORY] >= AAC_SavedSettings.HistoryMaxSaved do
                    table.remove(h[DB_HISTORY], #h[DB_HISTORY])
                end

                while #h>DB_MONEYTYPE do
                    table.remove(h,DB_MONEYTYPE+1)
                end
            end
        end
    end

end

----------------------------------
function History.List_Show()

    local itemid = History.curItem
	local white = AAC.Tools.GetWhiteValue(itemid)

    if (itemid == 200000) then
        AAC_HistoryHeaderPPU:SetText(AAC_GENERAL_UNITS_PER_PRICE_HEADER)
    else
        AAC_HistoryHeaderPPU:SetText(AAC_GENERAL_PRICE_PER_UNIT_HEADER)
    end

    local base = AAC_SavedHistoryTable[itemid]
    if base == nil then return; end

    local numhistory = GetAuctionHistoryItemNums()
    if numhistory == 0 then
        --SendSystemMsg("no history available") -- TODO: localize
        AAC_HistoryList:Hide()
        return
    end

    --local stats = getSummary(itemid)

    -- local summary = AACLocale.Messages.HISTORY_SUMMARY_MINMAX
    -- summary = string.gsub(summary, "<MINIMUM>", "|cffffd200"..AAC.Tools.FormatNumber(stats.min / white).."|r")
    -- summary = string.gsub(summary, "<MAXIMUM>", "|cffffd200"..AAC.Tools.FormatNumber(stats.max / white).."|r")
    -- AAC_HistoryMinMaxLabel:SetText(summary)

    -- local summary = AACLocale.Messages.HISTORY_SUMMARY_AVERAGE
    -- summary = string.gsub(summary, "<MEDIAN>", "|cffffd200"..AAC.Tools.FormatNumber(stats.median / white).."|r")
    -- summary = string.gsub(summary, "<AVERAGE>", "|cffffd200"..AAC.Tools.FormatNumber(stats.avg / white).."|r")
    -- AAC_HistoryAverageLabel:SetText(summary)

    -- local summary = AACLocale.Messages.HISTORY_SUMMARY_NUMHISTORY
    -- summary = string.gsub(summary, "<NUMHISTORY>", numhistory)
    -- AAC_HistoryNumHistoryLabel:SetText(summary)

    local maxvalue = numhistory - MAX_ITEM_DISPLAY
    if maxvalue > 0 then
        AAC_HistoryListScrollBar:SetMinMaxValues(0, maxvalue)
        AAC_HistoryListScrollBar:Show()
    else
        AAC_HistoryListScrollBar:SetMinMaxValues(0, 0)
        AAC_HistoryListScrollBar:Hide()
    end
    History.List_UpdateItems()
    AAC_HistoryList:Show()
end

local function GetStatByParsingHyperlink(itemId, itemLink)
    local result = nil;
    if (itemId and ((itemId >= 202840 and itemId <= 202859) or (itemId >= 1248061 and itemId <= 1248080))) then
        local _, data, name = ParseHyperlink(itemLink);
        local hasSingleStat = data:sub(7, data:len()):match("%d+ %x+ (%x%x%x%x) 0");
        if (hasSingleStat) then
            local statId = tonumber(hasSingleStat, 16) + 500000;
            local r, g, b = GetInherentAttributeColor(statId);
            local color = "|off" .. string.format("%02x" , r * 255) .. string.format("%02x", g * 255) .. string.format("%02x", b * 255);
            result = color .. TEXT("Sys" .. statId .. "_name") .. "|r";
        else
            local link = ChatEdit_GenerateTierLink(itemLink);
            local _, _, prevName = ParseHyperlink(itemLink);
            local _, _, newName = ParseHyperlink(link);
            if (newName ~= prevName) then
                local color, name = link:match("(%|cff.+)%[(.+)%]");
                if (color) then
                    color = color:gsub("%|cff","%|off");
                    result = color .. name .. "|r";
                else
                    result = newName;
                end
            end
        end
    end
    return result;
end

function History.List_UpdateItems()

    local itemid = History.curItem
    local stats = getSummary(itemid)
	local name = GetAuctionHistoryItemInfo(1)
	local white = AAC.Tools.GetWhiteValue(itemid)

	local hidecount = false
	local inversecoloring = false

    if itemid==200000 or itemid==200003 then
        name =TEXT("Sys"..itemid.."_name")
        hidecount = true
	    inversecoloring = (itemid==200000)
    end

    local base = AAC_SavedHistoryTable[itemid]
    local numhistory = GetAuctionHistoryItemNums()
    local first_line = AAC_HistoryListScrollBar:GetValue()
    local items = getSortedAuctionHistoryInfo()

    for i = 1, MAX_ITEM_DISPLAY do
        local index = first_line+i
        local frame_name = "AAC_HistoryListItem"..i
        if index <= numhistory then

            local e
            if index <= GetAuctionHistoryItemNums() then
                e = getAuctionHistoryInfo(itemid, 1+GetAuctionHistoryItemNums()-index, items)
            else
                e = getAuctionHistoryFromHistory(itemid, index)
            end

            local button = _G[frame_name.."Icon"]
            button.index = e.newIndex or 0--index
            SetItemButtonTexture(button, e.icon)

            local link = GetAuctionHistoryItemLink(GetAuctionHistoryItemNums() + 1 - button.index);
            local itemId, itemName = AAC.Tools.ParseLink(link);
            local stat = GetStatByParsingHyperlink(itemId, link);

            if hidecount then
                itemName = string.format("%s %s",AAC.Tools.FormatNumber(e.count),name)
                SetItemButtonCount(button, 0)
            else
                SetItemButtonCount(button, e.count)
            end

            if index <= GetAuctionHistoryItemNums() then
                _G[button:GetName().."Red"]:Hide()
            else
                _G[button:GetName().."Red"]:Show()
            end

            local r, g, b = GetItemQualityColor(GetQualityByGUID(itemid))
            if e.seller == "" then e.seller = (GRAY_FONT_COLOR_CODE .. AUCTION_ANONYMOUS .. "|r"); end
            _G[frame_name.."Name"]:SetText(itemName)
            _G[frame_name.."Name"]:SetText(stat and itemName .. "\n" .. stat or itemName)
            _G[frame_name.."Name"]:SetColor(r, g, b)
            _G[frame_name.."DateText"]:SetText(e.date)
            _G[frame_name.."SellerText"]:SetText(e.seller)
            _G[frame_name.."BuyerText"]:SetText(e.buyer)
            _G[frame_name.."PPU"]:SetText(AAC.Tools.Trim(e.ppu / white))
            _G[frame_name.."PPU"]:SetColor(1,1,1)
            --AAC.Tools.GetAvgPriceColor(e.ppu, stats.avg, frame_name.."PPU", inversecoloring)
            MoneyFrame_Update(frame_name.."Price", e.price, e.moneyType)

            _G[frame_name]:Show()
        else
            _G[frame_name]:Hide()
        end
    end
end

function History.List_OnClose()
    History.BrowseItemLink = nil
    History.Processing = true
end

----------------------------------
function History.GetAveragePrice(itemid)
    local stats = getSummary(itemid)
    if stats.avg==0 then return end
    --debug
    return stats.avg
end

function History.GetPriceStatistic(itemid)
    local data = AAC_SavedHistoryTable[itemid]
    if not data then return end

    local stats = getSummary(itemid)
    return stats.avg, stats.min, stats.max, stats.median
end

function AAC.ToolsShowPriceHistoryTooltip(tooltip, itemid)
	if AAC_SavedSettings.DisableSave then AAC_PriceHistoryTooltip:Hide() return end
	local tempString = ""
	local white = AAC.Tools.GetWhiteValue(itemid)
	AAC_PriceHistoryTooltip:SetText(AAC_TOOLS_PRICE_HISTORY, 0, 0.75, 0.95)
	AAC_PriceHistoryTooltip:AddDoubleLine(AAC_TOOLS_POWERED_BY, "", 0, 0.75, 0.95)

    local history = AAC_SavedHistoryTable[itemid]

	if history then
		local numhistory = history[DB_HISTORY] and #(history[DB_HISTORY]) or (history[DB_COUNT] or 10)
		if numhistory > 0 then
            local stats = getSummary(itemid)
			AAC_PriceHistoryTooltip:AddLine(" ")
			tempString = "|cffffd200"..AAC.Tools.FormatNumber(stats.avg / white).."|r"
			AAC_PriceHistoryTooltip:AddDoubleLine(AAC_GENERAL_AVERAGE_PRICE_PER_UNIT, tempString)
			tempString = "|cffffd200"..AAC.Tools.FormatNumber(stats.median / white).."|r"
			AAC_PriceHistoryTooltip:AddDoubleLine(AAC_GENERAL_MEDIAN_PRICE_PER_UNIT, tempString)
			tempString = string.gsub(AAC_TOOLS_GOLD_BASED, "<SCANNED>", numhistory)
			AAC_PriceHistoryTooltip:AddDoubleLine(tempString)
		end
	else
		AAC_PriceHistoryTooltip:AddLine(" ")
		AAC_PriceHistoryTooltip:AddLine(AAC_TOOLS_NO_HISTORY_DATA)
	end

	History.TooltipWidth = AAC_PriceHistoryTooltip:GetWidth()
	History.TooltipHeight = AAC_PriceHistoryTooltip:GetHeight()
	AAC_PriceHistoryTooltip:Show()
end

function AAC.ToolsPriceHistoryTooltip_OnUpdate(tooltip, elapsedTime)
	if ((not GameTooltip:IsVisible()) and HistoryForGameTooltip) or
        ((not GameTooltipHyperLink:IsVisible()) and HistoryForGameTooltipHyperLink) or
        ((not GameTooltip:IsVisible()) and (not GameTooltipHyperLink:IsVisible())) then
		tooltip:Hide()
	else
		if HistoryForGameTooltip then
			tooltip:ClearAllAnchors()
			tooltip:SetAnchor("TOPLEFT", "BOTTOMLEFT", GameTooltip, 0, 0)
		elseif HistoryForGameTooltipHyperLink then
			tooltip:ClearAllAnchors()
			tooltip:SetAnchor("TOPLEFT", "BOTTOMLEFT", GameTooltipHyperLink, 0, 0)
		end
		tooltip:SetWidth(History.TooltipWidth)
		tooltip:SetHeight(History.TooltipHeight)
	end
end

function History.HidePPU()
    if AAC_SavedSettings.PPUSettings then
		_G["AAC_HistoryHeaderPPU"]:Show()
		for i = 1, MAX_ITEM_DISPLAY do
			_G["AAC_HistoryListItem"..i.."PPU"]:Show()
		end
		_G["AAC_HistoryHeaderPPU"]:ClearAllAnchors()
        _G["AAC_HistoryHeaderPrice"]:ClearAllAnchors()
		_G["AAC_HistoryHeaderPPU"]:SetAnchor("CENTER", "TOPLEFT", "$parent", 490, 38)
        _G["AAC_HistoryHeaderPrice"]:SetAnchor("CENTER", "TOPLEFT", "$parent", 555, 38)
	else
		_G["AAC_HistoryHeaderPPU"]:Hide()
		_G["AAC_HistoryHeaderPrice"]:ClearAllAnchors()
		_G["AAC_HistoryHeaderPrice"]:SetAnchor("CENTER", "TOPLEFT", "$parent", 525, 38)
		for i = 1, MAX_ITEM_DISPLAY do
			_G["AAC_HistoryListItem"..i.."PPU"]:Hide()
		end
	end
end

function History.List_ItemIcon_OnClick(this,key)
	if key == "MBUTTON" then
		local link = GetAuctionHistoryItemLink(this.index)
		local itemid, itemname = AAC.Tools.ParseLink(link)
		if itemid then
			Chat_CopyToClipboard( itemid );
			SendSystemMsg(TEXT("SYS_COPIED_ID"));
		end
	else
		local link = GetAuctionHistoryItemLink(this.index)
		if IsShiftKeyDown() and key == "LBUTTON" then
			AAC.Tools.ChatEdit_AddItemLink(link,true)
		elseif IsCtrlKeyDown() and key == "LBUTTON" then
			ItemPreviewFrame_SetItemLink(ItemPreviewFrame, link)
		end
	end
end