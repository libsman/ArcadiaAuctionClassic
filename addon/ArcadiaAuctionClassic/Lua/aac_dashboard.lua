local Dashboard = {
	DisplayedItems = 7,
	CustomSortItem1 = "level",
	CustomSortItem2 = "tier",
	Cache = {},
	Results = {},
	LastSearch = {},
	LastCached = 0,
	MaxPageItems = 250,
	CurrentCachePage = 1,
	CurrentFilterPage = 0,
	CurrentFilterItem = 0,
	MaxPages = 0,
	FilteringActive = false,
    selected_auctionid = nil,
	SelectedCategory = {},
    CategoryButtonNums = 0,
    CategoryScrollValue = 0,
	Update = {},
	RollNewDashboard = true,
	HistoryButton_Clicked = 0,
    KeyFinderTable = { -- resolve strings in tooltips to their types
        [(TEXT("PET_LEVEL"))] = "level",
        [string.gsub(TEXT("SYS_TOOLTIP_RUNE_LEVEL"), " %%.", "")] = "tier", -- fix the " %d" pattern placement in this loca string
        [(TEXT("SYS_ITEM_COST"))] = "worth",
        [(TEXT("SYS_WEAPON_DMG"))] = "pdam",
        [(TEXT("SYS_WEAPON_MDMG"))] = "mdam",
        [(TEXT("SYS_ARMOR_DEF"))] = "pdef",
        [(TEXT("SYS_ARMOR_MDEF"))] = "mdef",
        [(TEXT("SYS_WEAREQTYPE_3"))] = "sta",
        [(TEXT("SYS_WEAREQTYPE_2"))] = "str",
        [(TEXT("SYS_WEAREQTYPE_6"))] = "dex",
        [(TEXT("SYS_WEAREQTYPE_5"))] = "wis",
        [(TEXT("SYS_WEAREQTYPE_4"))] = "int",
        [(TEXT("SYS_WEAREQTYPE_13"))] = "pdef",
        [(TEXT("SYS_WEAREQTYPE_14"))] = "mdef",
        [(TEXT("SYS_WEAREQTYPE_12"))] = "patt",
        [(TEXT("SYS_WEAREQTYPE_15"))] = "matt",
        [(TEXT("SYS_WEAREQTYPE_8"))] = "hp",
        [(TEXT("SYS_WEAREQTYPE_9"))] = "mp",
        [(TEXT("SYS_WEAREQTYPE_18"))] = "pcrit",
        [(TEXT("SYS_WEAREQTYPE_20"))] = "mcrit",
        [(TEXT("SYS_WEAREQTYPE_16"))] = "pacc",
        [(TEXT("SYS_WEAREQTYPE_195"))] = "macc",
        [(TEXT("SYS_WEAREQTYPE_17"))] = "pdod",
        [(TEXT("SYS_WEAREQTYPE_150"))] = "heal",
        [(TEXT("SYS_WEAREQTYPE_22"))] = "parry",
        [(TEXT("SYS_WEAREQTYPE_25"))] = "pdam",
        [(TEXT("SYS_WEAREQTYPE_191"))] = "mdam",
        [(TEXT("SYS_WEAPON_ATKSPEED"))] = "speed",
        [(TEXT("SYS_ITEM_DURABLE"))] = "dura",
    },
}

AAC.Dashboard = Dashboard

local FILTER_DELAY = 2

local FilterChanged
local CachingActive

local FilterDelay = FILTER_DELAY

local HeaderFrames = {
	"AAC_DashboardHeaderName",
	"AAC_DashboardHeaderCustom1",
	"AAC_DashboardHeaderCustom2",
	"AAC_DashboardHeaderLeftTime",
	"AAC_DashboardHeaderSeller",
	"AAC_DashboardHeaderPPU",
	"AAC_DashboardHeaderPrice",
}

local function ToNum(str)
	local n = tonumber(string.match(str, "[%d%.]+"))
	if not n then
		n = tonumber(string.match(str, "%d+%.%d+"))
	end
	return n or 0
end

function Dashboard.Resize(num, value)
	AAC_DashboardList:SetSize(800, 340 + value)
	Dashboard.DisplayedItems = 7 + num
	for i = Dashboard.DisplayedItems + 1, 12 do
		_G["AAC_DashboardListItem"..i]:Hide()
	end
	
	Dashboard.List_Update()
	AAC.SavedSearch.ScrollBar_Update()
end

function Dashboard.Frame_OnLoad(this)

	this:RegisterEvent("AUCTION_BROWSE_UPDATE")
	this:RegisterEvent("AUCTION_SEARCH_RESULT")
	this:RegisterEvent("AUCTION_BROWSE_PAGE_REFUSED")
	this:RegisterEvent("AUCTION_BORWSE_PRICE_UPDATE")
	
	for _, Header in pairs(HeaderFrames) do
		_G[Header]:SetWidth(_G[Header]:GetTextWidth() + 12)
	end

	UIDropDownMenu_Initialize(AAC_DashboardHeaderCustom1Menu, Dashboard.HeaderCustomMenu, "MENU")
	UIDropDownMenu_Initialize(AAC_DashboardHeaderCustom2Menu, Dashboard.HeaderCustomMenu, "MENU")

	AAC_DashboardHeaderName:SetMouseEnable(false);
	AAC_DashboardHeaderCustom1:SetMouseEnable(false);
	AAC_DashboardHeaderCustom2:SetMouseEnable(false);
	AAC_DashboardHeaderLeftTime:SetMouseEnable(false);
	AAC_DashboardHeaderSeller:SetMouseEnable(false);
	AAC_DashboardHeaderPPU:SetMouseEnable(false);
	AAC_DashboardHeaderPrice:SetMouseEnable(false);

    AAC_DashboardHeaderPPU:SetText(AAC_GENERAL_PRICE_PER_UNIT_HEADER)
	AAC_DashboardHeaderCustom2:SetText(AAC_GENERAL_TIER_HEADER)
	
	Dashboard.PrepareCachedSearch()
end

function Dashboard.Frame_OnUpdate(this, elapsedTime)
    if not AAC.CanRequest() then return end
    if Dashboard.FilteringActive then Dashboard.DoFilteringStep() end
    if AAC_DashboardEmpty then
        local empty=#Dashboard.Results.list==0
        local label=AAC.TradingUI.Text((CachingActive or Dashboard.FilteringActive) and "waiting" or "empty")
        if Dashboard.emptyLabel~=label then AAC_DashboardEmpty:SetText(label);Dashboard.emptyLabel=label end
        AAC_DashboardEmpty:SetVisible(empty)
    end
end

function Dashboard.Frame_OnEvent(this, event)
    AAC.Market.SearchEvent(Dashboard, event)
    if AAC.CanRequest() and event == "AUCTION_BORWSE_PRICE_UPDATE" and AAC.Main.CurrentTab == "DASHBOARD" then
        Dashboard.AUCTION_BORWSE_PRICE_UPDATE(arg1, arg2, arg3)
    end
end

function Dashboard.RemovePurchased(auctionid)
    local idx, info = Dashboard.List_FindAuctionIndex(auctionid)
    if not idx or not info then return end
    local auctionid = info.auctionid
    table.remove(Dashboard.Results.list, idx)
    Dashboard.Cache_ClearAuction(auctionid)

	local size = #Dashboard.Results.list
	local maxValue = size - Dashboard.DisplayedItems
	if maxValue > 0 then
		AAC_DashboardListScrollBar:SetMinMaxValues(0, maxValue)
	end

	-- if size > 0 then
	-- 	Dashboard.selected_auctionid = idx
    -- 	Dashboard.List_UpdateItems()
	-- end
	--Dashboard.List_Update()

	if idx > size then idx = idx - 1 end
    Dashboard.List_SetSelected(Dashboard.Results.list[idx] and Dashboard.Results.list[idx].auctionid)
    Dashboard.List_UpdateItems()

end

function Dashboard.AUCTION_BORWSE_PRICE_UPDATE(auctionid,bidprice,buyer)
    local cache = Dashboard.Cache_FindAuction(auctionid)
    if cache then
        cache.bidPrice = bidprice or cache.bidPrice
        cache.isBuyer = buyer
        Dashboard.Cache_CalculatePPU(cache)
    end
    Dashboard.List_UpdateItems()
end

function Dashboard.DoFilteringStep()

    local old_count = #Dashboard.Results.list
    local old_sel_index = Dashboard.List_GetSelected()

    -- The client profiler clock returns nanoseconds; yield after 5 ms of scanning.
    local filterStart = debugprofilestop()
    for i = 1, AAC_SavedSettings.FilterSpeed do
        if i > 1 and debugprofilestop() - filterStart >= 5000000 then
            break
        end
        while (not(Dashboard.Cache.PAGEREADY and Dashboard.Cache.PAGEREADY[Dashboard.CurrentFilterPage] == true and
            Dashboard.Cache.CACHEDDATA[Dashboard.CurrentFilterPage][Dashboard.CurrentFilterItem] and
            Dashboard.Cache.CACHEDDATA[Dashboard.CurrentFilterPage][Dashboard.CurrentFilterItem].auctionid
	        or (Dashboard.CurrentFilterPage > Dashboard.LastCached)))
        do
            Dashboard.CurrentFilterItem = Dashboard.CurrentFilterItem + 1
            if Dashboard.CurrentFilterItem > Dashboard.MaxPageItems then
                Dashboard.CurrentFilterItem = 1
                Dashboard.CurrentFilterPage = Dashboard.CurrentFilterPage + 1
            end
        end
        if Dashboard.CurrentFilterPage > Dashboard.LastCached then
            Dashboard.FilteringActive = false
            break
        else
            Dashboard.AddItemToList(Dashboard.CurrentFilterPage, Dashboard.CurrentFilterItem)

            Dashboard.CurrentFilterItem = Dashboard.CurrentFilterItem + 1
            if Dashboard.CurrentFilterItem > Dashboard.MaxPageItems then
                Dashboard.CurrentFilterItem = 1
                Dashboard.CurrentFilterPage = Dashboard.CurrentFilterPage + 1
            end
        end
    end


    Dashboard.InfoLabelUpdate()

    if old_count ~= #Dashboard.Results.list then


        local maxValue = #(Dashboard.Results.list) - Dashboard.DisplayedItems
        if maxValue > 0 or (Dashboard.Results.pageNum > 1 and maxValue == 0) then
            AAC_DashboardListScrollBar:SetMinMaxValues(0, maxValue)
            AAC_DashboardListScrollBar:Show()
        else
            AAC_DashboardListScrollBar:SetMinMaxValues(0, 0)
            --AAC_DashboardListScrollBar:Hide()
        end

        local new_sel_index = Dashboard.List_GetSelected()
        if old_sel_index and new_sel_index then
            local first_index = AAC_DashboardListScrollBar:GetValue()

            if old_sel_index>=first_index and old_sel_index < first_index + Dashboard.DisplayedItems then
                AAC_DashboardListScrollBar:SetValue(first_index+new_sel_index-old_sel_index)
            end
        end

        Dashboard.List_UpdateItems()
    end
end

function Dashboard.UpdateScrollBar()
	AAC_DashboardRefreshButton:SetText(AAC.TradingUI.Text("otherOffers"))
    AAC_DashboardRefreshButton:SetWidth(140)

	AAC_DashboardRefreshButton:Disable();
	AAC_DashboardProgressLabel:Hide();
	Dashboard.RollNewDashboard = true;
	Dashboard.HistoryButton_Clicked = 0;
	local maxValue = #(Dashboard.Results.list) - Dashboard.DisplayedItems
	if maxValue ~= nil and Dashboard.Results.pageNum ~= nil then
		if maxValue > 0 or (Dashboard.Results.pageNum > 1 and maxValue == 0) then
			AAC_DashboardListScrollBar:SetMinMaxValues(0, maxValue)
			AAC_DashboardListScrollBar:Show()
		else
			AAC_DashboardListScrollBar:SetMinMaxValues(0, 0)
		end
	end
end

function Dashboard.Frame_StopUpdates()
    AAC.Market.StopSearch(Dashboard)
    CachingActive = false
    FilterChanged = false
    Dashboard.FilteringActive = false
    Dashboard.PrepareCachedSearch()
end

function Dashboard.HistoryButton_OnClick(this)
	Dashboard.HistoryButton_Clicked = 1;
    local idx, entry = Dashboard.List_GetSelected()
    if idx then
        AAC.History.RequestHistoryPopup(entry.auctionid,entry.itemid,nil,false,entry.link)
    end
end

function Dashboard.BuyoutButton_OnClick(this)
    local idx, entry = Dashboard.List_GetSelected()
	if idx then
		AAC.Pay.PayAuction(entry, 0, true, AAC.Pay.AuctionType.Browse)
	end
end

function Dashboard.Refresh_OnClick()
    Dashboard.RollNewDashboard = true
    Dashboard.ExecuteSearch()
end

function Dashboard.ResetFilters()
	AAC_BrowseFilter1EditBox:SetText("");
	AAC_BrowseFilter2EditBox:SetText("");
	AAC_BrowseFilter3EditBox:SetText("");
	AAC_BrowseFilter2OrButton:SetChecked(false);
	AAC_BrowseFilter3OrButton:SetChecked(false);
	AAC_BrowseFilterPPUButton:SetChecked(false);
	AAC_BrowseFilterBidButton:SetChecked(false);
	AAC_BrowseFilterMinPriceEditBox:SetText("");
	AAC_BrowseFilterMaxPriceEditBox:SetText("");
end

function Dashboard.ShowDashboard()
    Dashboard.ExecuteSearch()
end

function Dashboard.ExecuteSearch()
	Dashboard.DoSearch("", 0, 0, 1, 1, false, nil, nil, nil, true)
end

function Dashboard.DoSearch(name, minlvl, maxlvl, rarity, rune, usable, cat1, cat2, cat3, isDashboard)
    if not AAC.CanRequest() then return end
    if not AAC.Market.Feature("Overview") then
        Dashboard.Frame_StopUpdates()
        Dashboard.List_Update()
        AAC_DashboardProgressLabel:SetText(AAC_NO_GOLDEN_OFFERS)
        AAC_DashboardProgressLabel:Show()
        AAC_DashboardRefreshButton:Disable()
        return
    end
    minlvl, maxlvl = minlvl or 0, maxlvl or 0
    name = (name or ""):gsub("'", "%%")
    local searchRarity = rarity or 1
    local started = AAC.Market.StartSearch(Dashboard, function()
        AuctionBrowseSearchItem(name ~= "" and name or nil, minlvl > 0 and minlvl or nil,
            maxlvl > 0 and maxlvl or nil, searchRarity, 1, rune, usable and true or nil,
            cat1, cat2, cat3, isDashboard and true or nil)
    end, function(message)
        CachingActive = false
        AAC_DashboardRefreshButton:Enable()
        if message then
            Dashboard.PrepareCachedSearch()
            Dashboard.List_Update()
            AAC_DashboardProgressLabel:SetText(message)
            AAC_DashboardProgressLabel:Show()
        end
    end, function(page, total, pages)
        Dashboard.MaxPages = pages
        Dashboard.Total = total
        if total == 0 then
            AAC_DashboardProgressLabel:SetText(AAC_NO_GOLDEN_OFFERS)
            AAC_DashboardProgressLabel:Show()
        else
            Dashboard.CachePage(page, total)
        end
    end)
    if not started then return end


	AAC_DashboardProgressLabel:SetText(AAC_BROWSE_SEARCHING)
	AAC_DashboardInfoLabel:SetText("")

    AAC.History.ClearQueue()
    
    Dashboard.Results.pageNum = 1
    Dashboard.PrepareCachedSearch()
    Dashboard.List_Update()
    CachingActive = true
    AAC_DashboardRefreshButton:Disable()
end

function Dashboard.PrepareCachedSearch()
	Dashboard.Cache.PAGEREADY = {}
	Dashboard.Cache.CACHEDDATA = {}
	for i = 1, 40 do
		Dashboard.Cache.PAGEREADY[i] = false
		Dashboard.Cache.CACHEDDATA[i] = {}
	end
	Dashboard.CurrentCachePage = 1
	Dashboard.LastCached = 0
    Dashboard.MaxPages = 0
    Dashboard.Total = 0
end

function Dashboard.Filter_TooltipDisplay(this, num)
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT", 0, -50)
	GameTooltip:SetText(AAC_BROWSE_FILTER_TOOLTIP_HEADER .. num, 1, 1, 1)
	for _, filter in ipairs(AAC.Filters.List) do
		if filter.coms == "-" then
			GameTooltip:AddSeparator()
		else
			GameTooltip:AddDoubleLine(filter.coms, filter.desc, 1, 0.82, 0, 0, 0.75, 0.95)
		end
	end

	GameTooltip:AddDoubleLine( " ", TEXT("AAH_BROWSE_FILTER_STRING_STAT" ), 0, 0, 0, 0, 0.75, 0.95)
	GameTooltip:AddSeparator()
	GameTooltip:AddLine(AAC_BROWSE_FILTER_TOOLTIP_TEXT1, 0, 0.75, 0.95) --Do not edit before generation. This would wrap lines to early.
	GameTooltip:Show()
end

function Dashboard.FilterChange()
	FilterChanged = true
	FilterDelay = FILTER_DELAY
end

function Dashboard.CachePage(page, total)
    local last = math.min(Dashboard.MaxPageItems, total - (page - 1) * Dashboard.MaxPageItems)
    local rows = {}
    for slot = 1, last do
        local auctionid, name, count, rarity, texture, level, leftTime, seller, isBuyer, moneyMode,
            bidPrice, buyoutPrice, promoteType, dbid = GetAuctionBrowseItemInfo(page, slot)
        local link = GetAuctionBrowseItemLink(auctionid)
        local itemid, itemname = AAC.Tools.ParseLink(link)
        if itemid == 200000 or itemid == 200003 then itemname = name end
        rows[slot] = {
            auctionid = auctionid,
            dbid = dbid,
            owner = Dashboard,
            epoch = AAC.Market.Epoch,
            page = page,
            slot = slot,
            cacheCount = count,
            itemid = itemid,
            link = link,
            name = itemname or name,
            count = count,
            rarity = rarity,
            texture = texture,
            level = level,
            levelcolor = NORMAL_FONT_COLOR_CODE,
            leftTime = leftTime or 0,
            seller = seller,
            isBuyer = isBuyer,
            moneyMode = moneyMode,
            bidPrice = bidPrice or 0,
            buyoutPrice = buyoutPrice or 0,
            promoteType = promoteType or 0,
        }
        AAC.History.Queue_Insertitem(auctionid, name, link, itemid)
    end
    Dashboard.Cache.CACHEDDATA[page] = rows
    Dashboard.Cache.PAGEREADY[page] = true
    Dashboard.LastCached = page
    Dashboard.CurrentCachePage = page + 1
    Dashboard.InfoLabelUpdate()
    if page == 1 then
        Dashboard.List_Update()
    else
        Dashboard.List_Update_AddPage(page)
    end
end

function Dashboard.List_Update()
	Dashboard.Results.nextPage = nil
    Dashboard.Results.maxNums = Dashboard.Total or 0
    Dashboard.Results.list = {}
    if Dashboard.Results.maxNums > 0 then
        Dashboard.CurrentFilterPage = 1
        Dashboard.CurrentFilterItem = 1
        Dashboard.FilteringActive = true
        AAC_DashboardProgressLabel:SetText("")
		  AAC_DashboardListScrollBar:Show();
	else
        AAC_DashboardProgressLabel:SetText(AAC_NO_GOLDEN_OFFERS);
		  AAC_DashboardListScrollBar:Hide();
    end
    Dashboard.List_UpdateItems()
end

function Dashboard.List_Update_AddPage(addPage)
	Dashboard.Results.nextPage = nil
    if Dashboard.FilteringActive == false then
        Dashboard.CurrentFilterPage = addPage
        Dashboard.CurrentFilterItem = 1
        Dashboard.FilteringActive = true
    end
    Dashboard.InfoLabelUpdate()
end

function Dashboard.Cache_FindAuction(auctionid)
    for j = 1, Dashboard.MaxPages do
		for i = 1, Dashboard.MaxPageItems do
			local item = Dashboard.Cache.CACHEDDATA[j][i]
			if item and item.auctionid == auctionid then
				return item
			end
		end
	end
end

function Dashboard.Cache_ClearAuction(auctionid)
    for j = 1, Dashboard.MaxPages do
        for i = 1, Dashboard.MaxPageItems do
			local item = Dashboard.Cache.CACHEDDATA[j][i]
	        if item and item.auctionid == auctionid then
                Dashboard.Cache.CACHEDDATA[j][i] = {}
                return true
            end
        end
    end
end

function Dashboard.Cache_CalculatePPU(item)
    -- Same unit as the Sell tab: per white material when Price/Unit/White is enabled (bundles count as several units).
    local white = AAC.Tools.GetWhiteValue(item.itemid)
    if item.buyoutPrice > 0 then
        item.buyppu = item.buyoutPrice / item.count / white
    else
        item.buyppu = -1
    end

    item.bidppu = item.bidPrice / item.count / white
end

local function ResetAttributes(listing)
	listing.tier = 0		--Tier
	listing.plus = 0		--Plus
	listing.dura = 0		--Max Durability
	listing.worth = 0		--Vendor Value
	listing.mdam = 0		--Magical Damage
	listing.pdam = 0		--Physical Damage
	listing.speed = 0		--Attack Speed
	listing.dps = 0			--DPS
	listing.sta = 0			--Stamina
	listing.str = 0			--Strength
	listing.dex = 0			--Dexterity
	listing.wis = 0			--Wisdom
	listing.int = 0			--Intelligence
	listing.hp = 0			--Maximum HP
	listing.mp = 0			--Maximum MP
	listing.patt = 0		--Physical Attack
	listing.matt = 0		--Magical Attack
	listing.pdef = 0		--Physical Defense
	listing.mdef = 0		--Magical Defense
	listing.pcrit = 0		--Physical Crit Rate
	listing.mcrit = 0		--Magical Crit Rate
	listing.pacc = 0		--Physical Accuracy
	listing.macc = 0		--Magical Accuracy
	listing.pdod = 0		--Physical Dodge Rate
	listing.parry = 0		--Parry Rate
	listing.heal = 0		--Healing Bonus
end

local function ParseLine(listing, line)
	line = AAC.Tools.NormalizeTooltipText(line)
	local prefix, value, suffix = string.match(line, "^%s*(.-)%s*([%d%.]+)%s*(.-)%s*$")

	local key1 = Dashboard.KeyFinderTable[prefix]
	local key2 = Dashboard.KeyFinderTable[suffix]
	if key1 then
		if key1 == "worth" then --additional code for price
			value = string.gsub(value, "%"..COMMA, "") --added "%" to comma because in german this is a point instead of comma!
			listing["worth"] =  ToNum(value)
		elseif key1 == "level" then --additional code for pet eggs
			if AAC.Data.PetEggs[listing.itemid] then
				listing.levelcolor = AAC.Tools.getLevelColor(ToNum(value))
				listing["level"] = ToNum(value)
			end
		elseif key1 == "dura" then --use suffix on dura to get max dura
			listing[key1] = (listing[key1] or 0) + ToNum(string.gsub(suffix, "/", ""))
		else
			listing[key1] = (listing[key1] or 0) + ToNum(value)
		end
	elseif key2 then
		listing[key2] = (listing[key2] or 0) + ToNum(value)
	end
end

local function ParseToolTip(listing)
    Dashboard.KeyFinderTable[listing.name.." +"] = "plus"
    ResetAttributes(listing)
    AAC_Tooltip:SetHyperLink(listing.link, true)
    AAC_Tooltip:Hide()
    GameTooltip1:Hide()
    GameTooltip2:Hide()
    local left, leftVis, right, rightVis

    for i = 1, 40 do
        leftVis = getglobal("AAC_TooltipTextLeft"..i):IsVisible()
        rightVis = getglobal("AAC_TooltipTextRight"..i):IsVisible()
        if not leftVis and not rightVis then
            break
        end

        left = getglobal("AAC_TooltipTextLeft"..i):GetText()
        if left and left ~= "" and leftVis then
	        ParseLine(listing, left)
        end
        right = getglobal("AAC_TooltipTextRight"..i):GetText()
        if right and right ~= "" and rightVis then
	        ParseLine(listing, right)
        end
    end
    if listing.mdam > 0 then
        listing.heal = listing.heal + (listing.mdam * 0.5)
    end
    if listing.speed > 0 and listing.pdam > 0 then
        listing.dps = listing.pdam / listing.speed
    end
end

function Dashboard.AddItemToList(pageNumber, itemIndex)
	if Dashboard.Cache.PAGEREADY and Dashboard.Cache.PAGEREADY[pageNumber] == true then
		local listing = Dashboard.Cache.CACHEDDATA[pageNumber][itemIndex]
		if not listing or not listing.auctionid or not listing.itemid then return end

        if listing.itemid == 200000 or listing.itemid == 200003 then -- Get Count from "itemname" for gold and diamonds
            listing.count = tonumber(string.match(listing.name:gsub( "%.", "" ):gsub( ",", "" ), "(%d+)" ) or "1") or 1
        end

        Dashboard.Cache_CalculatePPU(listing)
        ParseToolTip(listing)

        if AAC.Data.Recipes[listing.itemid] then
            listing.levelcolor = AAC.Tools.getLevelColor(AAC.Data.Recipes[listing.itemid])
            listing.level = AAC.Data.Recipes[listing.itemid]
        end
		
		if listing.itemid >= 204476 and listing.itemid <= 204508 then
			for i = 1, 10 do
				local Text = AAC.Tools.NormalizeTooltipText(_G["AAC_TooltipTextLeft" .. i]:GetText())
				local Level = Text:match( TEXT("SYS_LEVEL") .. ": (%d+)" )
				
				if Level then
					listing.level = tonumber( Level )
					break
				end
			end
		end

        local class = UnitClass("player")
        if AAC.Data.StatValues[class] then
            for stat, t in pairs(AAC.Data.StatValues[class]) do
                for attribute, value in pairs(t) do
                    listing[attribute] = listing[attribute] + (listing[stat] * value)
                end
            end
        else
            --DEFAULT_CHAT_FRAME:AddMessage("ERROR: please report your language and class to the AAC Forums")
        end

        if AAC.Filters.CheckFilter(listing, true) then
            table.insert(Dashboard.Results.list, listing)
        end

	end
end

function Dashboard.InfoLabelUpdate()
    local pages = math.max(Dashboard.MaxPages or 0, 1)
    local labelInfo = {
		SCANPERCENT = math.ceil(100 / pages * Dashboard.LastCached),
		MAXITEMS = Dashboard.Total == 5000 and "> 5000" or Dashboard.Total or 0,
	}
	
	local labeltext = AAC_DASHBOARD_INFO_LABEL:gsub("<(%w+)>", labelInfo)
	AAC_DashboardInfoLabel:SetText(labeltext)
end

function AAC.Dashboard.InfoLabelOnLoad(infoLabel)
	infoLabel:ClearAllAnchors()
	infoLabel:SetAnchor("TOPLEFT", "BOTTOMLEFT", AAC_DashboardList, 5, 0)

	infoLabel.NormalText:ClearAllAnchors()
	infoLabel.NormalText:SetAnchor("LEFT", "LEFT", infoLabel, 0, 0)
		
	infoLabel.NormalText:SetColor(1, 1, 1)
	infoLabel.NormalText:SetJustifyHType("LEFT")
	infoLabel.NormalText:SetJustifyVType("MIDDLE")
end

function Dashboard.InfoLabelOnEnter(infoLabel)
	GameTooltip:SetOwner(infoLabel, "ANCHOR_BOTTOM", 0, 0)
	GameTooltip:SetText(AACLocale.Messages.BROWSE_INFO_LABEL_TOOLTIP_HEADER, 1, 1, 1)
	GameTooltip:AddLine(AACLocale.Messages.BROWSE_INFO_LABEL_TOOLTIP_TEXT, 0, 0.75, 0.95)
		
	local labelText = infoLabel:GetText()
	GameTooltip:AddSeparator()
	GameTooltip:AddLine(labelText)
end

function Dashboard.InfoLabelOnLeave(infoLabel)
	GameTooltip:Hide()
end

local function shuffle(rows)
    for i = #rows, 2, -1 do
        local j = math.random(i)
        rows[i], rows[j] = rows[j], rows[i]
    end
end

function Dashboard.List_UpdateItems()
	local first_index = AAC_DashboardListScrollBar:GetValue()
	if not Dashboard.FilteringActive and Dashboard.LastCached > 0 and Dashboard.LastCached == Dashboard.MaxPages
        and Dashboard.RollNewDashboard then
        shuffle(Dashboard.Results.list)
		Dashboard.RollNewDashboard = false;
	end
	for i = 1, Dashboard.DisplayedItems do
		local button = getglobal("AAC_DashboardListItem"..i)
		local info = Dashboard.Results.list[first_index+i]
		local itemBG = getglobal(button:GetName().."Highlight");
		if info then
			if info.promoteType ~= 0 then
				itemBG:Show()
				itemBG:SetColor(AAC_PROMOTE_TYPE_COLORS_MAIN[info.promoteType].R, AAC_PROMOTE_TYPE_COLORS_MAIN[info.promoteType].G, AAC_PROMOTE_TYPE_COLORS_MAIN[info.promoteType].B)
			else
				itemBG:Hide()
			end
			if info.itemid >= 202840 and info.itemid <= 202859 or info.itemid >= 1248061 and info.itemid <= 1248080 then
				local _, data, name = ParseHyperlink(info.link)
				local hasSingleStat = data:sub(7,data:len()):match("%d+ %x+ (%x%x%x%x) 0")
				if hasSingleStat then
					local statId = (tonumber(hasSingleStat,16)+500000)
					local r, g, b = GetInherentAttributeColor(statId)
					local color = "|off"..string.format("%02x",r*255)..string.format("%02x",g*255)..string.format("%02x",b*255)
					info.stat = color..TEXT("Sys"..statId.."_name").."|r"
				else
					local link = ChatEdit_GenerateTierLink(info.link)
					local _,_,prevName = ParseHyperlink(info.link)
					local _,_,newName = ParseHyperlink(link)
					if newName ~= prevName then
						local color,name = link:match("(%|cff.+)%[(.+)%]")
						if color then
							color = color:gsub("%|cff","%|off")
							info.stat = color..name.."|r"
						else
							info.stat = newName
						end
					end
				end
			end
			button.auctionid = info.auctionid
			local buttonName = button:GetName()


			local inversecoloring = false
            local count = info.count
            if info.itemid == 200000 then
				inversecoloring = true
			    count = 0
			elseif info.itemid == 200003 then
				count = 0
            end
			local r,g,b = GetItemQualityColor(GetQualityByGUID(info.itemid))
			local color = "|cff"..string.format("%02x",r*255)..string.format("%02x",g*255)..string.format("%02x",b*255)
			getglobal(buttonName.."Name"):SetText(info.stat and color..info.name.."|r\n"..info.stat or color..info.name.."|r")
            SetItemButtonCount(getglobal(buttonName.."Icon"), count)

			SetItemButtonTexture(getglobal(buttonName.."Icon"), info.texture)
			for k = 1, 2 do
				if not info[Dashboard["CustomSortItem"..k]] or info[Dashboard["CustomSortItem"..k]] == 0 or info[Dashboard["CustomSortItem"..k]] == "" then
					getglobal(buttonName.."Custom"..k):SetText(WHITE_FONT_COLOR_CODE.."-".."|r")
				elseif Dashboard["CustomSortItem"..k] == "level" then
					info.levelcolor = AAC.Tools.getLevelColor(info.level)
					getglobal(buttonName.."Custom"..k):SetText(info.levelcolor..info.level.."|r")
				else
					getglobal(buttonName.."Custom"..k):SetText(WHITE_FONT_COLOR_CODE..tonumber(string.format("%.2f", info[Dashboard["CustomSortItem"..k]])).."|r")
				end
			end
			getglobal(buttonName.."LeftTime"):SetText(SecondsToTime(info.leftTime * 60))
			if info.seller ~= "" then
				getglobal(buttonName.."Seller"):SetText(info.seller)
			else
				getglobal(buttonName.."Seller"):SetText(GRAY_FONT_COLOR_CODE..AUCTION_ANONYMOUS.."|r")
			end

            AAC.UX.PaintUnit(getglobal(buttonName.."PPUBuy"),getglobal(buttonName.."PPUBuyCurrencyIcon"),info)

			MoneyFrame_Update(buttonName.."BidMoney", info.bidPrice, info.moneyMode or "copper")
			if info.isBuyer then
				getglobal(buttonName.."BidMoneyText"):SetText(AAC_AUCTION_SELF_BID) -- TEXT("AUCTION_SELF_BID")
			else
				getglobal(buttonName.."BidMoneyText"):SetText("")
			end
			if info.buyoutPrice > 0 then
				getglobal(buttonName.."BuyoutMoney"):Show()
				MoneyFrame_Update(buttonName.."BuyoutMoney", info.buyoutPrice, info.moneyMode or "copper")
			else
				getglobal(buttonName.."BuyoutMoney"):Hide()
			end
			button:Show()
		else
			button:Hide()
		end
	end

	Dashboard.List_SetSelected(Dashboard.selected_auctionid)
end

function Dashboard.List_ItemIcon_OnClick(this,key)
	if key == "MBUTTON" then
		local link = GetAuctionBrowseItemLink(this:GetParent().auctionid)
		local itemid, itemname = AAC.Tools.ParseLink(link)
		if itemid then
			Chat_CopyToClipboard( itemid );
			SendSystemMsg(TEXT("SYS_COPIED_ID"));
		end
	else
		local link = GetAuctionBrowseItemLink(this:GetParent().auctionid)
		if IsShiftKeyDown() and key == "LBUTTON" then
			AAC.Tools.ChatEdit_AddItemLink(link,true)
		elseif IsCtrlKeyDown() and key == "LBUTTON" then
			ItemPreviewFrame_SetItemLink(ItemPreviewFrame, link)
		else
			AAC.Dashboard.List_SetSelected(this:GetParent().auctionid)
		end
	end
end

function Dashboard.List_FindAuctionIndex(auctionid)
    for i,entry in ipairs(Dashboard.Results.list) do
        if entry.auctionid == auctionid then
            return i,entry
        end
    end
end

function Dashboard.List_GetSelected()
    local idx,entry = Dashboard.List_FindAuctionIndex(Dashboard.selected_auctionid)
    return idx,entry
end

function Dashboard.List_SetSelected(auctionid)
	AAC_DashboardBuyoutButton:Disable()
	AAC_DashboardHistoryButton:Disable()

	for i = 1, Dashboard.DisplayedItems do
        local button = getglobal("AAC_DashboardListItem"..i)
    	button:UnlockHighlight()
	end

    Dashboard.selected_auctionid = auctionid
    local index = Dashboard.List_FindAuctionIndex(auctionid)
    if not index then
        Dashboard.selected_auctionid = nil
        return
    end

    local first_index = AAC_DashboardListScrollBar:GetValue()
    local but_idx = index-first_index
    local button = _G["AAC_DashboardListItem"..but_idx]
    if not button or but_idx>Dashboard.DisplayedItems then return end

    local _,info = Dashboard.List_GetSelected()
    if info.buyoutPrice > 0 then
        AAC_DashboardBuyoutButton:Enable()
    end
    AAC_DashboardHistoryButton:Enable()
    button:LockHighlight()
end

function Dashboard.Seller_OnEnter(this)
	local itemNumberName = this:GetName()
	local itemNumber = string.match(itemNumberName, "%d+")
	local button = getglobal("AAC_DashboardListItem"..itemNumber)
	if Dashboard.selected_auctionid ~= this:GetParent().auctionid then
		button:LockHighlight()
	end
	
	local text = this:GetText();
	if text == UnitName("player") then this:SetTextColor(1,1,1) end
	if text == (GRAY_FONT_COLOR_CODE .. AUCTION_ANONYMOUS .. "|r") or text == UnitName("player") then return end;
	this:SetTextColor(0,1,0)
end

function Dashboard.Seller_OnLeave(this)
	local itemNumberName = this:GetName()
	local itemNumber = string.match(itemNumberName, "%d+")
	local button = getglobal("AAC_DashboardListItem"..itemNumber)
	if Dashboard.selected_auctionid ~= this:GetParent().auctionid then
		button:UnlockHighlight()
	end

	local text = this:GetText();
	if text == UnitName("player") then this:SetTextColor(1,1,1) end
	if text == (GRAY_FONT_COLOR_CODE .. AUCTION_ANONYMOUS .. "|r") or text == UnitName("player") then return end;
	this:SetTextColor(1,1,1)
end

function Dashboard.BuyoutMoney_OnEnter(this)
	local itemNumberName = this:GetName()
	local itemNumber = string.match(itemNumberName, "%d+")
	local button = getglobal("AAC_DashboardListItem"..itemNumber)
	if Dashboard.selected_auctionid ~= this:GetParent():GetParent().auctionid then
		button:LockHighlight()
	end
end

function Dashboard.BuyoutMoney_OnLeave(this)
	local itemNumberName = this:GetName()
	local itemNumber = string.match(itemNumberName, "%d+")
	local button = getglobal("AAC_DashboardListItem"..itemNumber)
	if Dashboard.selected_auctionid ~= this:GetParent():GetParent().auctionid then
		button:UnlockHighlight()
	end
end

local function CalculatePricePerUnit(item)
    return (item.buyoutPrice / item.count)
end

function Dashboard.PricePerUnit_OnEnter(this)
	local itemNumberName = this:GetName()
	local itemNumber = string.match(itemNumberName, "%d+")
	local button = getglobal("AAC_DashboardListItem"..itemNumber)
	if Dashboard.selected_auctionid ~= this:GetParent().auctionid then
		button:LockHighlight()
	end
    local item = Dashboard.Cache_FindAuction(this:GetParent().auctionid)
    if item then
        GameTooltip:SetOwner(this, "ANCHOR_TOP", 0, 0)
        GameTooltip:SetText(AAC.UX.text.header..": "..AAC.UX.UnitText(item,true))
        GameTooltip:Show()
    end
end

function Dashboard.PricePerUnit_OnLeave(this)
	local itemNumberName = this:GetName()
	local itemNumber = string.match(itemNumberName, "%d+")
	local button = getglobal("AAC_DashboardListItem"..itemNumber)
	if Dashboard.selected_auctionid ~= this:GetParent().auctionid then
		button:UnlockHighlight()
	end
	GameTooltip:Hide()
end

function Dashboard.ShowDescription()
	local DescLabel = _G["AAC_DashboardDescriptionFrameDesc"];
    DescLabel:SetText(AAC.TradingUI.Text("dashboard"));
    DescLabel:SetTextColor(AAC_PROMOTE_TYPE_COLORS_MAIN[3].R, AAC_PROMOTE_TYPE_COLORS_MAIN[3].G, AAC_PROMOTE_TYPE_COLORS_MAIN[3].B);
end