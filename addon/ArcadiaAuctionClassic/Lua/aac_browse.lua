local Browse = {
	DisplayedItems = 7,
	SortMode = 0,
	CustomSortItem1 = "level",
	CustomSortItem2 = "tier",
	CurrentCustomHeaderID = 0,
	Cache = {},
	Results = {},
	LastSearch = {},
	LastCached = 0,
	MaxPageItems = 250,
	CurrentCachePage = 1,
	CurrentFilterPage = 0,
	CurrentFilterItem = 0,
	MaxPages = 0,
	Queue = {
		Items = {},
		Map = {},
		DisplayedItems = 7,
		UserToggledOpen = false,
	},
	FilteringActive = false,
    selected_auctionid=nil,
	SelectedCategory = {},
    CategoryButtonNums = 0,
    CategoryScrollValue = 0,
	Update = {},
	HistoryButton_Clicked = 0,
	RarityInfo = {
		ITEM_QUALITY0_DESC .. "+",
		ITEM_QUALITY1_DESC .. "+",
		ITEM_QUALITY2_DESC .. "+",
		ITEM_QUALITY3_DESC .. "+",
		ITEM_QUALITY4_DESC .. "+",
		ITEM_QUALITY5_DESC .. "+",
		ITEM_QUALITY6_DESC .. "+",
		ITEM_QUALITY7_DESC .. "+",
		ITEM_QUALITY8_DESC .. "+",
		ITEM_QUALITY9_DESC .. "+",
	},
	RuneInfo = {
		"0+",
		"1+",
		"2+",
		"3+",
		"4+",
	},
}
AAC.Browse = Browse
local browseButtons = {};

local FILTER_DELAY = 2
local QUEUE_MAX = 20

local FilterChanged
local CachingActive

local FilterDelay = FILTER_DELAY

local ColoredAttributeArray = {
	[1] = nil,
	[2] = "[SC_SKILLTIPS_STR]",
	[3] = "[SC_SKILLTIPS_STA]",
	[4] = "[SC_SKILLTIPS_INT]",
	[5] = "[SC_SKILLTIPS_MND]",
	[6] = "[SC_SKILLTIPS_AGI]",
	[7] = nil,
	[8] = "[SC_SKILLTIPS_HP]",
	[9] = "[SC_SKILLTIPS_MP]",
	[10] = nil,
	[11] = nil,
	[12] = "[SC_SKILLTIPS_01]",
	[13] = "[SC_SKILLTIPS_DEF]",
	[14] = "[SC_SKILLTIPS_MDEF]",
	[15] = "[SC_SKILLTIPS_02]",
}

local HeaderList = {
    -- Menu text, colum header text, internal value, category
    --General
    {C_LEVEL, C_LEVEL, "level", "GENERAL"},
    {AAC_GENERAL_TIER_HEADER, AAC_GENERAL_TIER_HEADER, "tier", "GENERAL"},
    {AAC_GENERAL_PLUS_HEADER, AAC_GENERAL_PLUS_HEADER, "plus", "GENERAL"},
    {AAC_GENERAL_WORTH_HEADER, AAC_GENERAL_WORTH_HEADER, "worth", "GENERAL"},
    {TEXT("SYS_ITEM_DURABLE"),    AAC_GENERAL_DURA_HEADER, "dura", "GENERAL"},
    {TEXT("SYS_WEAPON_MDMG"),     AAC_GENERAL_MDAM_HEADER, "mdam", "GENERAL"},
    {TEXT("SYS_WEAPON_DMG"),      AAC_GENERAL_PDAM_HEADER, "pdam", "GENERAL"},
    {TEXT("SYS_WEAPON_ATKSPEED"), AAC_GENERAL_SPEED_HEADER, "speed", "GENERAL"},
    {AAC_GENERAL_DPS_HEADER, AAC_GENERAL_DPS_HEADER, "dps", "GENERAL"},
    --Stats
    {GetReplaceSystemKeyword(ColoredAttributeArray[3]), AAC_GENERAL_STAM_HEADER, "sta", "STATS"},
    {GetReplaceSystemKeyword(ColoredAttributeArray[2]), AAC_GENERAL_STR_HEADER,  "str", "STATS"},
    {GetReplaceSystemKeyword(ColoredAttributeArray[6]), AAC_GENERAL_DEX_HEADER,  "dex", "STATS"},
    {GetReplaceSystemKeyword(ColoredAttributeArray[5]), AAC_GENERAL_WIS_HEADER,  "wis", "STATS"},
    {GetReplaceSystemKeyword(ColoredAttributeArray[4]), AAC_GENERAL_INTEL_HEADER,"int", "STATS"},
    {GetReplaceSystemKeyword(ColoredAttributeArray[8]), AAC_GENERAL_HP_HEADER,   "hp",  "STATS"},
    {GetReplaceSystemKeyword(ColoredAttributeArray[9]), AAC_GENERAL_MP_HEADER,   "mp",  "STATS"},
    {GetReplaceSystemKeyword(ColoredAttributeArray[12]), AAC_GENERAL_PATT_HEADER, "patt","STATS"},
    {GetReplaceSystemKeyword(ColoredAttributeArray[15]), AAC_GENERAL_MATT_HEADER, "matt","STATS"},
    {GetReplaceSystemKeyword(ColoredAttributeArray[13]), AAC_GENERAL_PDEF_HEADER, "pdef","STATS"},
    {GetReplaceSystemKeyword(ColoredAttributeArray[14]), AAC_GENERAL_MDEF_HEADER, "mdef","STATS"},
    --Attributes
    {TEXT("SYS_WEAREQTYPE_18"), AAC_GENERAL_PCRIT_HEADER, "pcrit","ATTRIBUTES"},
    {TEXT("SYS_WEAREQTYPE_20"), AAC_GENERAL_MCRIT_HEADER, "mcrit","ATTRIBUTES"},
    {TEXT("SYS_WEAREQTYPE_16"), AAC_GENERAL_PACC_HEADER,  "pacc", "ATTRIBUTES"},
    {TEXT("SYS_WEAREQTYPE_195"),AAC_GENERAL_MACC_HEADER,  "macc", "ATTRIBUTES"},
    {TEXT("SYS_WEAREQTYPE_17"), AAC_GENERAL_PDOD_HEADER,  "pdod", "ATTRIBUTES"},
    {TEXT("SYS_WEAREQTYPE_22"), AAC_GENERAL_PARRY_HEADER, "parry","ATTRIBUTES"},
    {TEXT("SYS_WEAREQTYPE_150"),AAC_GENERAL_HEAL_HEADER,  "heal", "ATTRIBUTES"},
    --Other
}
local HeaderFrames = {
	"AAC_BrowseHeaderName",
	"AAC_BrowseHeaderCustom1",
	"AAC_BrowseHeaderCustom2",
	"AAC_BrowseHeaderLeftTime",
	"AAC_BrowseHeaderSeller",
	"AAC_BrowseHeaderPPU",
	"AAC_BrowseHeaderPrice",
}

local function ToNum(str)
	local n = tonumber(string.match(str, "[%d%.]+"))
	if not n then
		n = tonumber(string.match(str, "%d+%.%d+"))
	end
	return n or 0
end


Browse.KeyFinderTable = { -- resolve strings in tooltips to their types
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
}

function Browse.Resize(num, value)
	AAC_BrowseList:SetSize(666, 340 + value)
	AAC_BrowseCategory:SetSize(142, 340 + value)
	Browse.DisplayedItems = 7 + num
	for i = Browse.DisplayedItems + 1, 12 do
		getglobal("AAC_BrowseListItem"..i):Hide()
	end
	for i = (Browse.DisplayedItems * 2) + 1, 24 do
		getglobal("AAC_BrowseCategoryButton"..i):Hide()
	end
	for i = (Browse.DisplayedItems * 2) + 7, 30 do
		getglobal("AAC_BrowseSavedSearchButton"..i):Hide()
	end

	Browse.List_Update()
	Browse.CategoryScrollBar_Update()
	AAC.SavedSearch.ScrollBar_Update()
end

function Browse.Frame_OnLoad(this)
	this:RegisterEvent("AUCTION_BROWSE_UPDATE")
	this:RegisterEvent("AUCTION_SEARCH_RESULT")
	this:RegisterEvent("AUCTION_BROWSE_PAGE_REFUSED")
	this:RegisterEvent("AUCTION_BORWSE_PRICE_UPDATE")

	AAC_BrowseHeaderPPU:SetText(AAC_GENERAL_PRICE_PER_UNIT_HEADER)
	AAC_BrowseHeaderCustom2:SetText(AAC_GENERAL_TIER_HEADER)

	for _, Header in pairs(HeaderFrames) do
		_G[Header]:SetWidth(_G[Header]:GetTextWidth() + 12)
	end

	UIDropDownMenu_Initialize(AAC_BrowseHeaderCustom1Menu, Browse.HeaderCustomMenu, "MENU")
	UIDropDownMenu_Initialize(AAC_BrowseHeaderCustom2Menu, Browse.HeaderCustomMenu, "MENU")

	AAC_BrowseUsableButtonLabel:SetText(AAC_BROWSE_USABLE)
	AAC_BrowseRaritySwitchLabel:SetText(AAC_BROWSE_RARITYSWITCH)
	AAC_BrowseResetButton:SetText(AAC_BROWSE_CLEAR_BUTTON)
	AAC_BrowseFilterPPUButtonLabel:SetText(AAC_BROWSE_PPU)
	AAC_BrowseFilterMinPriceEditBoxLabel:SetText(AAC_BROWSE_MIN)
	AAC_BrowseFilterMaxPriceButtonLabel:SetText(AAC_BROWSE_MAX)
	AAC_BrowseFilter1EditBoxLabel:SetText(AAC_BROWSE_FILTER)
	AAC_BrowseFilter2OrButtonLabel:SetText(AAC_BROWSE_OR)
	AAC_BrowseFilter3OrButtonLabel:SetText(AAC_BROWSE_OR)
	if AAC_BrowseQueueButton then
		AAC_BrowseQueueButton:SetText(AAC_BROWSE_QUEUE_ADD)
	end
	if AAC_BrowseQueueTitle then
		AAC_BrowseQueueTitle:SetText(AAC_BROWSE_QUEUE_TITLE)
	end
	if AAC_BrowseQueueBuyButton then
		AAC_BrowseQueueBuyButton:SetText(AAC_BROWSE_QUEUE_TITLE)
	end
	if AAC_BrowseQueueClearButton then
		AAC_BrowseQueueClearButton:SetText(AAC_BROWSE_QUEUE_CLEAR)
	end
	Browse.Queue_UpdateTotal()
	Browse.Queue_UpdateList()
	Browse.Queue_UpdateAddButton()
	Browse.Queue_SetVisible(false)
	
	AAC_BrowseRuneDropDownLabel:SetText( AAC_RUNEHOLE )
	AAC_BrowseFilterBidButtonLabel:SetText( AAC_AUCTION_BID )
	-- AAC_BrowseSearchLabel:SetText(AACLocale.Messages.BROWSE_SEARCH_PARAMETERS)

    UIDropDownMenu_SetWidth(AAC_BrowseRuneDropDown, 32)
    UIDropDownMenu_Initialize(AAC_BrowseRuneDropDown, Browse.RuneDropDown_Show)
    UIDropDownMenu_SetWidth(AAC_BrowseRarityDropDown, 80)
    UIDropDownMenu_Initialize(AAC_BrowseRarityDropDown, Browse.RarityDropDown_Show)

	Browse.PrepareCachedSearch()
end

function Browse.Frame_OnUpdate(this, elapsedTime)
    if AAC.Exchange and AAC.Exchange.context=="browse" then return end
    if not AAC.CanRequest() then return end
    if Browse.FilteringActive then Browse.DoFilteringStep() end

    if FilterChanged then
        FilterDelay = FilterDelay - elapsedTime
        if FilterDelay <= 0 then
            FilterChanged = false
            Browse.List_Update()
        end
    end
    AAC_BrowseHistoryButton:SetEnable(not CachingActive and Browse.selected_auctionid ~= nil and AAC.Market.Feature("PriceHistory"))
end

function Browse.Frame_OnEvent(this, event)
    AAC.Market.SearchEvent(Browse, event)
    if AAC.CanRequest() and event == "AUCTION_BORWSE_PRICE_UPDATE" and AAC.Main.CurrentTab == "BROWSE" then
        Browse.AUCTION_BORWSE_PRICE_UPDATE(arg1, arg2, arg3)
    end
end

function Browse.RemovePurchased(auctionid)
	local idx, info
	if auctionid then
		idx, info = Browse.List_FindAuctionIndex(auctionid)
	else
		idx, info = Browse.List_GetSelected()
	end
	if not idx or not info then
		return
	end

	auctionid = info.auctionid
	table.remove(Browse.Results.list, idx)
	Browse.Cache_ClearAuction(auctionid)
	Browse.Queue_Remove(auctionid)

	local size = #Browse.Results.list
	local maxValue = size - Browse.DisplayedItems
	if maxValue > 0 then
		AAC_BrowseListScrollBar:SetMinMaxValues(0, maxValue)
	end

	if Browse.selected_auctionid == auctionid then
		if idx > size then
			idx = idx - 1
		end
		Browse.List_SetSelected(Browse.Results.list[idx] and Browse.Results.list[idx].auctionid)
	end
	Browse.List_UpdateItems()
	Browse.Queue_UpdateAddButton()
end



function Browse.AUCTION_BORWSE_PRICE_UPDATE(auctionid,bidprice,buyer)
    local cache = Browse.Cache_FindAuction(auctionid)
    if cache then
        cache.bidPrice = bidprice or cache.bidPrice
        cache.isBuyer = buyer
        Browse.Cache_CalculatePPU(cache)
    end
    Browse.List_UpdateItems()
end

function Browse.DoFilteringStep()

    local old_count = #Browse.Results.list
    local old_sel_index = Browse.List_GetSelected()

    -- The client profiler clock returns nanoseconds; yield after 5 ms of scanning.
    local filterStart = debugprofilestop()
    for i = 1, AAC_SavedSettings.FilterSpeed do
        if i > 1 and debugprofilestop() - filterStart >= 5000000 then
            break
        end
        while (not(Browse.Cache.PAGEREADY and Browse.Cache.PAGEREADY[Browse.CurrentFilterPage] == true and
	        Browse.Cache.CACHEDDATA[Browse.CurrentFilterPage][Browse.CurrentFilterItem] and
	        Browse.Cache.CACHEDDATA[Browse.CurrentFilterPage][Browse.CurrentFilterItem].auctionid
	        or (Browse.CurrentFilterPage > Browse.LastCached)))
        do
            Browse.CurrentFilterItem = Browse.CurrentFilterItem + 1
            if Browse.CurrentFilterItem > Browse.MaxPageItems then
                Browse.CurrentFilterItem = 1
                Browse.CurrentFilterPage = Browse.CurrentFilterPage + 1
            end
        end
        if Browse.CurrentFilterPage > Browse.LastCached then
            Browse.FilteringActive = false
            break
        else
            Browse.AddItemToList(Browse.CurrentFilterPage, Browse.CurrentFilterItem)

            Browse.CurrentFilterItem = Browse.CurrentFilterItem + 1
            if Browse.CurrentFilterItem > Browse.MaxPageItems then
                Browse.CurrentFilterItem = 1
                Browse.CurrentFilterPage = Browse.CurrentFilterPage + 1
            end
        end
    end


    Browse.InfoLabelUpdate()

    if old_count ~= #Browse.Results.list then

        if Browse.Results.sortIndex then
            Browse.List_Sort(Browse.Results.sortIndex)
        end

        local maxValue = #(Browse.Results.list) - Browse.DisplayedItems
        if maxValue > 0 or (Browse.Results.pageNum > 1 and maxValue == 0) then
            AAC_BrowseListScrollBar:SetMinMaxValues(0, maxValue)
            AAC_BrowseListScrollBar:Show()
        else
            AAC_BrowseListScrollBar:SetMinMaxValues(0, 0)
            --AAC_BrowseListScrollBar:Hide()
        end

        local new_sel_index = Browse.List_GetSelected()
        if old_sel_index and new_sel_index then
            local first_index = AAC_BrowseListScrollBar:GetValue()

            if old_sel_index>=first_index and old_sel_index < first_index + Browse.DisplayedItems then
                AAC_BrowseListScrollBar:SetValue(first_index+new_sel_index-old_sel_index)
            end
        end

        Browse.List_UpdateItems()
    end
end

function Browse.UpdateScrollBar()

	AAC_BrowseProgressLabel:Hide();
	Browse.HistoryButton_Clicked = 0;
	local maxValue = #(Browse.Results.list) - Browse.DisplayedItems
	if maxValue ~= nil and Browse.Results.pageNum ~= nil then
		if maxValue > 0 or (Browse.Results.pageNum > 1 and maxValue == 0) then
			AAC_BrowseListScrollBar:SetMinMaxValues(0, maxValue)
			AAC_BrowseListScrollBar:Show()
		else
			AAC_BrowseListScrollBar:SetMinMaxValues(0, 0)
		end
	end
end

function Browse.Frame_StopUpdates()
    AAC.Market.StopSearch(Browse)
    CachingActive = false
    FilterChanged = false
    Browse.FilteringActive = false
    Browse.PrepareCachedSearch()
end

function Browse.Header_OnClick(this, key)
	local id = this:GetID()
	if key == "LBUTTON" then
		Browse.ClearSortIcons()
		if Browse.Results.sortIndex == id or Browse.Results.sortIndex == -id then
			Browse.SortMode = (Browse.SortMode + 1) % 4
		else
			Browse.SortMode = 0
		end
		if Browse.Results.sortIndex == id then
			id = -id
            AAC.Tools.SetSortIcon(_G[this:GetName().."SortIcon"], 1)
		else
            AAC.Tools.SetSortIcon(_G[this:GetName().."SortIcon"], 0)
		end
        if math.abs(id)==6 and Browse.GoldPriceView then
            AAC.Tools.SetSortIcon(_G[this:GetName().."SortIcon"],Browse.SortMode%2==0 and 1 or 0)
        end
		Browse.List_Sort(id)
	elseif key == "RBUTTON" then
		if id == 2 then
			Browse.CurrentCustomHeaderID = 1
			ToggleDropDownMenu(AAC_BrowseHeaderCustom1Menu)
		elseif id == 3 then
			Browse.CurrentCustomHeaderID = 2
			ToggleDropDownMenu(AAC_BrowseHeaderCustom2Menu)
		end
	end
end

local SortFunc = {
	["70"] = "SortBuyoutLess",
	["71"] = "SortBuyoutMore",
	["72"] = "SortBuyoutLess",
	["73"] = "SortBuyoutMore",
	["60"] = "SortUnitLess",
	["61"] = "SortUnitMore",
	["62"] = "SortUnitLess",
	["63"] = "SortUnitMore",
}

function Browse.ClearSortIcons()
	for _, name in ipairs({"Name", "Custom1", "Custom2", "LeftTime", "Seller", "PPU", "Price"}) do
		_G["AAC_BrowseHeader"..name.."SortIcon"]:SetFile("")
	end
end

function Browse.List_Sort(index)
	Browse.Results.sortIndex = index
	local i = math.abs(index)
	if i == 7 or i == 6 then
		table.sort(Browse.Results.list, AAC.Tools[SortFunc[i..Browse.SortMode]])
	else
		if i == 1 then
			AAC.Tools.CurrentSortItem = "name"
		elseif i == 2 then
			AAC.Tools.CurrentSortItem = Browse.CustomSortItem1
		elseif i == 3 then
			AAC.Tools.CurrentSortItem = Browse.CustomSortItem2
		elseif i == 4 then
			AAC.Tools.CurrentSortItem = "leftTime"
		elseif i == 5 then
			AAC.Tools.CurrentSortItem = "seller"
		end
		if Browse.Results.sortIndex > 0 then
			table.sort(Browse.Results.list, AAC.Tools.SortLess)
		else
			table.sort(Browse.Results.list, AAC.Tools.SortMore)
		end
	end
	Browse.List_UpdateItems()
end

function Browse.HeaderCustomMenu()
	local info = {}
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		info.text = AAC_BROWSE_HEADER_CUSTOM_TITLE
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, 1)
		info = {}
		info.text = AAC_GENERAL_GENERAL
		info.value = "GENERAL"
		info.notCheckable = true
		info.hasArrow = true
		UIDropDownMenu_AddButton(info, 1)
		info = {}
		info.text = AAC_GENERAL_STATS
		info.value = "STATS"
		info.notCheckable = true
		info.hasArrow = true
		UIDropDownMenu_AddButton(info, 1)
		info = {}
		info.text = AAC_GENERAL_ATTRIBUTES
		info.value = "ATTRIBUTES"
		info.notCheckable = true
		info.hasArrow = true
		UIDropDownMenu_AddButton(info, 1)
--		info = {}
--		info.text = AACLocale.Messages.GENERAL_OTHER
--		info.value = "OTHER"
--		info.notCheckable = true
--		info.hasArrow = true
--		UIDropDownMenu_AddButton(info, 1)
	elseif UIDROPDOWNMENU_MENU_LEVEL == 2 then
		for i = 1, #(HeaderList) do
			if HeaderList[i][4] == UIDROPDOWNMENU_MENU_VALUE then
				info = {}
				info.text = HeaderList[i][1]
				info.arg1 = HeaderList[i][2]
				info.value = HeaderList[i][3]
				info.arg2 = Browse.CurrentCustomHeaderID
				info.notCheckable = true
				info.func = function(button)
					Browse["CustomSortItem"..button.arg2] = button.value
					local header = getglobal("AAC_BrowseHeaderCustom"..button.arg2)
					header:SetText(button.arg1)
					header:SetWidth(header:GetTextWidth() + 12)
					if Browse.Results.sortIndex == button.arg2 + 1 or Browse.Results.sortIndex == -(button.arg2 + 1) then
						Browse.ClearSortIcons()
					end
					CloseDropDownMenus()
					Browse.List_UpdateItems()
				end
				UIDropDownMenu_AddButton(info, 2)
			end
		end
	end
end

function Browse.BidButton_OnClick(this)
	local money = AAC.MoneyFrame.GetMoney(AAC_BrowseBidMoneyInput)

    local idx, entry = Browse.List_GetSelected()
	if idx then
        AAC.Pay.PayAuction(entry, money, false, AAC.Pay.AuctionType.Browse)
	end
end

function Browse.HistoryButton_OnClick(this)
	Browse.HistoryButton_Clicked = 1;
    local idx, entry = Browse.List_GetSelected()
    if idx then
        AAC.History.RequestHistoryPopup(entry.auctionid,entry.itemid)
    end
end

function Browse.BuyoutButton_OnClick(this)
	local idx, entry = Browse.List_GetSelected()
	if idx then
		AAC.Pay.PayAuction(entry, 0, true, AAC.Pay.AuctionType.Browse)
	end
end

function Browse.CategoryScrollBar_Update()
	local maxValue = GetAuctionBrowseFilterMaxItems(Browse.SelectedCategory[1], Browse.SelectedCategory[2]) - (Browse.DisplayedItems * 2)
    if Browse.SelectedCategory[1]==13 then maxValue=maxValue+1 end
	if maxValue > 0 then
		AAC_BrowseCategoryScrollBar:Show()
		AAC_BrowseCategoryScrollBar:SetMinMaxValues(0, maxValue)
	else
		AAC_BrowseCategoryScrollBar:Hide()
		AAC_BrowseCategoryScrollBar:SetMinMaxValues(0, 0)
	end
	Browse.Category_UpdateList()
end

function Browse.Category_UpdateList()
	Browse.CategoryButtonNums = 0
	Browse.CategoryScrollValue = AAC_BrowseCategoryScrollBar:GetValue()
	Browse.Category_SetItemInfo(1, GetAuctionBrowseFilterList())
	for i = Browse.CategoryButtonNums + 1, Browse.DisplayedItems * 2 do
		_G["AAC_BrowseCategoryButton"..i]:Hide()
	end
end

function Browse.Category_SetItemInfo(layer, ...)
    local exchangeIndex
    if layer==2 and Browse.SelectedCategory[1]==13 and AAC.Exchange then
        -- UI-only row first; never pass its position to the native category API.
        local native=arg
        arg={n=native.n+1,[1]=AAC.Exchange.UIText(1)}
        for j=1,native.n do arg[j+1]=native[j] end
        exchangeIndex=1
    end
	for i = 1, arg.n do
        local nativeIndex=exchangeIndex and i-1 or i
        local isExchange=exchangeIndex==i
		if Browse.CategoryButtonNums >= Browse.DisplayedItems * 2 then
			return
		end
		if Browse.CategoryScrollValue > 0 then
			Browse.CategoryScrollValue = Browse.CategoryScrollValue - 1
		else
			local count = Browse.CategoryButtonNums + 1
			local bname = "AAC_BrowseCategoryButton"..count
			local button = _G[bname]
			local normalText = _G[bname.."NormalText"]
			local highlightText = _G[bname.."HighlightText"]
			local lineTexture = _G[bname.."Line"]
			local backgoundTexture = _G[bname.."Backgound"]
			local expandArrow = _G[bname.."ExpandArrow"]

			local width = 116
			button.layer = layer
			button.index = nativeIndex
            button.isExchange=isExchange
			local hasSubItems = false

			if layer == 1 then
				hasSubItems = GetAuctionBrowseFilterList(i) and #GetAuctionBrowseFilterList(i) > 0
				if hasSubItems then
					getglobal(bname).sublist = true;
				else
					getglobal(bname).sublist = false;
				end
			elseif layer == 2 and not isExchange then
                local children=GetAuctionBrowseFilterList(Browse.SelectedCategory[1], nativeIndex)
                hasSubItems=children and #children>0
			end

			if hasSubItems then
				expandArrow:Show()
			else
				expandArrow:Hide()
			end

			if layer == 1 then
				backgoundTexture:Show()
				backgoundTexture:SetAlpha(1.0)
				lineTexture:Hide()
				normalText:ClearAllAnchors()
				normalText:SetAnchor("LEFT", "LEFT", button:GetName(), 10, -1)
				normalText:SetWidth(width - 30)
				normalText:SetColor(1, 1, 0)
				highlightText:ClearAllAnchors()
				highlightText:SetAnchor("LEFT", "LEFT", button:GetName(), 10, -1)
				highlightText:SetWidth(width - 30)
				highlightText:SetColor(1, 1, 0)
			elseif layer == 2 then
				backgoundTexture:Show()
				backgoundTexture:SetAlpha(0.5)
				lineTexture:Hide()
				normalText:ClearAllAnchors()
				normalText:SetAnchor("LEFT", "LEFT", button:GetName(), 15, -1)
				normalText:SetWidth(width - 30)
				normalText:SetColor(1, 1, 1)
				highlightText:ClearAllAnchors()
				highlightText:SetAnchor("LEFT", "LEFT", button:GetName(), 15, -1)
				highlightText:SetWidth(width - 30)
				highlightText:SetColor(1, 1, 1)
			else
				backgoundTexture:Hide()
				lineTexture:Show()
				if i == arg.n then
					lineTexture:SetTexCoord(0, 1, 0.5, 0.8125)
				else
					lineTexture:SetTexCoord(0, 1, 0, 0.3125)
				end
				normalText:ClearAllAnchors()
				normalText:SetAnchor("LEFT", "LEFT", button:GetName(), 20, -1)
				normalText:SetWidth(width - 35)
				normalText:SetColor(1, 1, 1)
				highlightText:ClearAllAnchors()
				highlightText:SetAnchor("LEFT", "LEFT", button:GetName(), 20, -1)
				highlightText:SetWidth(width - 35)
				highlightText:SetColor(1, 1, 1)
			end
			button:SetText(arg[i])
			if (button.isExchange and AAC.Exchange.context=="browse") or (not button.isExchange and Browse.SelectedCategory[layer] == nativeIndex) then
				button:LockHighlight()
			else
				button:UnlockHighlight()
			end
			button:Show()
			Browse.CategoryButtonNums = count
		end
		if layer == 1 then
			if Browse.SelectedCategory[1] == i then
				Browse.Category_SetItemInfo(layer + 1, GetAuctionBrowseFilterList(i))
			end
		elseif layer == 2 and not isExchange then
			if Browse.SelectedCategory[2] == nativeIndex then
				Browse.Category_SetItemInfo(layer + 1, GetAuctionBrowseFilterList(Browse.SelectedCategory[1], nativeIndex))
			end
		end
	end
end


function Browse.CategoryButton_OnClick(this, key)
    if this.isExchange then
        Browse.SelectedCategory[2]=nil; Browse.SelectedCategory[3]=nil
        AAC.Exchange.Open("browse"); Browse.CategoryScrollBar_Update(); return
    end
    if AAC.Exchange and AAC.Exchange.context=="browse" then AAC.Exchange.Leave() end

	local browse_button = this:GetText();
	local alignButton = getglobal("AAC_BrowseCategoryButton1")
	local _, _, _, _, _, _, _, _, _, _, Quest_Items, Others, _ = GetAuctionBrowseFilterList()
	if not AAC_BrowseCategoryScrollBar:IsVisible() and not (this:GetText() == Quest_Items or this:GetText() == Others) then
		alignButton:ClearAllAnchors()
		alignButton:SetAnchor("TOP", "TOP", "$parent", -7, 27)
	elseif AAC_BrowseCategoryScrollBar:IsVisible() and this.layer == 1 and Browse.SelectedCategory[this.layer] == this.index then
		alignButton:ClearAllAnchors()
		alignButton:SetAnchor("TOP", "TOP", "$parent", 0, 27)
	elseif (this:GetText() == Quest_Items or this:GetText() == Others) and this.layer == 1 and Browse.SelectedCategory[this.layer] ~= this.index then
		alignButton:ClearAllAnchors()
		alignButton:SetAnchor("TOP", "TOP", "$parent", 0, 27)
	end
	for index, value in pairs(Browse.SelectedCategory) do
		if index > this.layer then
			Browse.SelectedCategory[index] = nil
		end
	end
	if Browse.SelectedCategory[this.layer] == this.index then
		Browse.SelectedCategory[this.layer] = nil
	else
		Browse.SelectedCategory[this.layer] = this.index
	end
	Browse.CategoryScrollBar_Update()
		
	AAC_Browse_CorrectPos( browse_button );
end

function AAC_BrowseGetList()

	for i = 1, 14 do 
		browseButtons[i] = getglobal( "AAC_BrowseCategoryButton" .. i ):GetText();
	end

end

function AAC_Browse_CorrectPos( browse_button )

	local scrollbar = getglobal("AAC_BrowseCategoryScrollBar");
	local isVisible = false;
	
	for i = 1, 14 do 
		local _text = getglobal( "AAC_BrowseCategoryButton" .. i ):GetText();
		if( browse_button == _text ) then
			isVisible = true;
		end
	end

	for i = 1, 14 do 
		if( isVisible == false ) then	
			if( browse_button == browseButtons[i] ) then
				scrollbar:SetValue( i - 1);
			end
		end
	end

	
end

function Browse.RuneDropDown_Show()
	for i = 1, 5 do
		info= {}
		info.text = Browse.RuneInfo[i]
		info.func = function(button)
			AAC.Tools.SetDropDown(AAC_BrowseRuneDropDown, button:GetID(), button:GetText())
		end
		UIDropDownMenu_AddButton(info)
	end
end

function Browse.RarityDropDown_Show()
	local info
	for i = 1, 10 do
		info = {}
		info.text = AAC_BrowseRaritySwitch:IsChecked() and Browse.RarityInfo[i]:match( "(.+)%+$" ) or Browse.RarityInfo[i]
		info.textR, info.textG, info.textB = GetItemQualityColor(i - 1)
		info.func = function(button)
			AAC.Tools.SetDropDown(AAC_BrowseRarityDropDown, button:GetID(), button:GetText(), {GetItemQualityColor(button:GetID() - 1)})
		end
		UIDropDownMenu_AddButton(info)
	end
end

function Browse.SwitchRarity( this )
	local Text = AAC_BrowseRarityDropDownText:GetText()
	
	if this:IsChecked() then
		Text = Text:match( "(.+)%+$" )
	else
		Text = Text .. "+"
	end
	AAC.Tools.SetDropDown( AAC_BrowseRarityDropDown, AAC_BrowseRarityDropDown.selectedID or 1, Text, {GetItemQualityColor( ( AAC_BrowseRarityDropDown.selectedID or 1 ) - 1) } )
end

function Browse.ResetButton_OnClick()
	AAC_BrowseNameEditBox:SetText("")
	AAC_BrowseMinLvlEditBox:SetText("")
	AAC_BrowseMaxLvlEditBox:SetText("")
	AAC.Tools.SetDropDown(AAC_BrowseRarityDropDown, 1, Browse.RarityInfo[1], {1, 1, 1})
	AAC.Tools.SetDropDown(AAC_BrowseRuneDropDown, 1, Browse.RuneInfo[1])
	AAC_BrowseUsableButton:SetChecked(false)
	AAC_BrowseRaritySwitch:SetChecked(false)
	Browse.SelectedCategory = {}
	Browse.CategoryScrollBar_Update()
	AAC_BrowseFilter1EditBox:SetText("")
	AAC_BrowseFilter2EditBox:SetText("")
	AAC_BrowseFilter3EditBox:SetText("")
	AAC_BrowseFilter2OrButton:SetChecked(false)
	AAC_BrowseFilter3OrButton:SetChecked(false)
	AAC_BrowseFilterPPUButton:SetChecked(false)
	AAC_BrowseFilterBidButton:SetChecked(false)
	AAC_BrowseFilterMinPriceEditBox:SetText("")
	AAC_BrowseFilterMaxPriceEditBox:SetText("")
end

function Browse.SearchButton_OnClick()
    Browse.ExecuteSearch()
end

function Browse.Name_TooltipDisplay(this)
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT", 0, -50)
	GameTooltip:SetText(C_KEYWORDS or "Keyword(s)", 1, 1, 1)
	GameTooltip:AddLine(AAC_BROWSE_NAME_TOOLTIP_TEXT1 or "Keyword(s) used as main search filter.", 0, 0.75, 0.95) --Do not edit before generation. This would wrap lines to early.
	GameTooltip:Show()
end

function Browse.ExecuteSearch()
	local name = AAC_BrowseNameEditBox:GetText()
	local minlvl = AAC_BrowseMinLvlEditBox:GetNumber()
	local maxlvl = AAC_BrowseMaxLvlEditBox:GetNumber()
	local rarity = UIDropDownMenu_GetSelectedID(AAC_BrowseRarityDropDown)
	local rune = UIDropDownMenu_GetSelectedID(AAC_BrowseRuneDropDown)
	local usable = AAC_BrowseUsableButton:IsChecked()
    local cat1=Browse.SelectedCategory[1]
    local cat2=Browse.SelectedCategory[2]
    local cat3=Browse.SelectedCategory[3]

	Browse.DoSearch(name, minlvl, maxlvl, rarity, rune, usable, cat1,cat2,cat3, false)
end

function Browse.DoSearch(name, minlvl, maxlvl, rarity, rune, usable, cat1, cat2, cat3, isDashboard)

    if not AAC.CanRequest() then return end
    minlvl, maxlvl = minlvl or 0, maxlvl or 0
    name = (name or ""):gsub("'", "%%")
    local searchRarity = (rarity or 1) + (AAC_BrowseRaritySwitch:IsChecked() and 1000 or 0)
    local started = AAC.Market.StartSearch(Browse, function()
        AuctionBrowseSearchItem(name ~= "" and name or nil, minlvl > 0 and minlvl or nil,
            maxlvl > 0 and maxlvl or nil, searchRarity, 1, rune, usable and true or nil,
            cat1, cat2, cat3, isDashboard and true or nil)
    end, function(message)
        CachingActive = false
        AAC_BrowseSearchButton:Enable()
        Browse.InfoLabelUpdate()
        if message then
            Browse.PrepareCachedSearch()
            Browse.List_Update()
            AAC_BrowseProgressLabel:SetText(message)
            AAC_BrowseProgressLabel:Show()
        end
    end, function(page, total, pages)
        Browse.MaxPages = pages
        Browse.Total = total
        if total == 0 then
            AAC_BrowseProgressLabel:SetText(AAC_BROWSE_NO_RESULTS)
            AAC_BrowseProgressLabel:Show()
        else
            Browse.CachePage(page, total)
        end
    end)
    if not started then return end

	if Browse.LastSearch.name ~= name or
		Browse.LastSearch.minlvl ~= minlvl or
		Browse.LastSearch.maxlvl ~= maxlvl or
		Browse.LastSearch.rarity ~= rarity or
		Browse.LastSearch.rune ~= rune or
		Browse.LastSearch.usable ~= usable or
		Browse.LastSearch.cat1 ~= cat1 or
		Browse.LastSearch.cat2 ~= cat2 or
		Browse.LastSearch.cat3 ~= cat3
	then
		Browse.Results.sortIndex = nil
		Browse.SortMode = 0
		Browse.ClearSortIcons()
	end
	Browse.LastSearch = {
		name = name,
		minlvl = minlvl,
		maxlvl = maxlvl,
		rarity = rarity,
		rune = rune,
		usable = usable,
		cat1 = cat1,
		cat2 = cat2,
		cat3 = cat3,
	}

	AAC_BrowseProgressLabel:Hide()
	AAC_BrowseInfoLabel:SetText("")
    if (cat1 == 13 and cat2 == 1) then
        AAC_BrowseHeaderPPU:SetText(AAC.UX.text.goldRate)
        if not Browse.Results.sortIndex then
            Browse.Results.sortIndex=6
            Browse.SortMode=0
            AAC.Tools.SetSortIcon(AAC_BrowseHeaderPPUSortIcon,1)
        end
    else
        AAC_BrowseHeaderPPU:SetText(AAC_GENERAL_PRICE_PER_UNIT_HEADER)
    end

    AAC.History.ClearQueue()
    Browse.Queue_Clear()
    Browse.Results.pageNum = 1
    Browse.PrepareCachedSearch()
    Browse.List_Update()
    CachingActive = true
    Browse.Total = 0
    Browse.InfoLabelUpdate()
    AAC_BrowseSearchButton:Disable()
end

function Browse.PrepareCachedSearch()
	Browse.Cache.PAGEREADY = {}
	Browse.Cache.CACHEDDATA = {}
	for i = 1, 40 do
		Browse.Cache.PAGEREADY[i] = false
		Browse.Cache.CACHEDDATA[i] = {}
	end
	Browse.CurrentCachePage = 1
	Browse.LastCached = 0
    Browse.MaxPages = 0
    Browse.Total = 0
end

function Browse.Filter_TooltipDisplay(this, num)
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

function Browse.FilterChange()
	FilterChanged = true
	FilterDelay = FILTER_DELAY
end

function Browse.EnterPress()
	FilterChanged = true
	FilterDelay = 0
end

function Browse.CachePage(page, total)
    local last = math.min(Browse.MaxPageItems, total - (page - 1) * Browse.MaxPageItems)
    local rows = {}
    for slot = 1, last do
        local auctionid, name, count, rarity, texture, level, leftTime, seller, isBuyer, moneyMode,
            bidPrice, buyoutPrice, promoteType, dbid, anonymous, linkedSeller = GetAuctionBrowseItemInfo(page, slot)
        local link = GetAuctionBrowseItemLink(auctionid)
        local itemid, itemname = AAC.Tools.ParseLink(link)
        if itemid == 200000 or itemid == 200003 then itemname = name end
        rows[slot] = {
            auctionid = auctionid,
            dbid = dbid,
            linkedSeller = linkedSeller == true,
            owner = Browse,
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
    Browse.Cache.CACHEDDATA[page] = rows
    Browse.Cache.PAGEREADY[page] = true
    Browse.LastCached = page
    Browse.CurrentCachePage = page + 1
    Browse.InfoLabelUpdate()
    if page == 1 then
        Browse.List_Update()
    else
        Browse.List_Update_AddPage(page)
    end
end

function Browse.List_Update()
	Browse.Results.nextPage = nil
    Browse.Results.maxNums = Browse.Total or 0
    Browse.Results.list = {}
    if Browse.Results.maxNums > 0 then
        Browse.CurrentFilterPage = 1
        Browse.CurrentFilterItem = 1
        Browse.FilteringActive = true
        AAC_BrowseProgressLabel:SetText("")
        if Browse.Results.sortIndex then
            Browse.List_Sort(Browse.Results.sortIndex)
        end
    end
    Browse.List_UpdateItems()
end

function Browse.List_Update_AddPage(addPage)
	Browse.Results.nextPage = nil
    if Browse.FilteringActive == false then
        Browse.CurrentFilterPage = addPage
        Browse.CurrentFilterItem = 1
        Browse.FilteringActive = true
    end
    Browse.InfoLabelUpdate()
end

function Browse.Cache_FindAuction(auctionid)
    for j = 1, Browse.MaxPages do
		for i = 1, Browse.MaxPageItems do
			local item = Browse.Cache.CACHEDDATA[j][i]
			if item and item.auctionid == auctionid then
				return item
			end
		end
	end
end

function Browse.Cache_ClearAuction(auctionid)
    for j = 1, Browse.MaxPages do
        for i = 1, Browse.MaxPageItems do
			local item = Browse.Cache.CACHEDDATA[j][i]
	        if item and item.auctionid == auctionid then
                Browse.Cache.CACHEDDATA[j][i] = {}
                return true
            end
        end
    end
end

function Browse.Cache_CalculatePPU(item)
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

	local key1 = Browse.KeyFinderTable[prefix]
	local key2 = Browse.KeyFinderTable[suffix]
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
    Browse.KeyFinderTable[listing.name.." +"] = "plus"
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

function Browse.AddItemToList(pageNumber, itemIndex)
	if Browse.Cache.PAGEREADY and Browse.Cache.PAGEREADY[pageNumber] == true then
		local listing = Browse.Cache.CACHEDDATA[pageNumber][itemIndex]
		if not listing or not listing.auctionid or not listing.itemid then return end

        if listing.itemid == 200000 or listing.itemid == 200003 then -- Get Count from "itemname" for gold and diamonds
            listing.count = tonumber(string.match(listing.name:gsub( "%.", "" ):gsub( ",", "" ), "(%d+)" ) or "1") or 1
        end

        Browse.Cache_CalculatePPU(listing)
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
            table.insert(Browse.Results.list, listing)
        end
	end
end

function Browse.InfoLabelUpdate()
    AAC_BrowseInfoLabel:Show()
    local total=Browse.Total or 0
    local cached=math.min(total,(Browse.LastCached or 0)*Browse.MaxPageItems)
    local checked=math.max(0,math.min(cached,((Browse.CurrentFilterPage or 1)-1)*Browse.MaxPageItems+(Browse.CurrentFilterItem or 1)-1))
    AAC_BrowseInfoLabel:SetText(AAC.UX.Status(CachingActive, Browse.FilteringActive,
        cached,total,checked,#Browse.Results.list))
end

function Browse.List_UpdateItems()
	Browse.GoldPriceView = #Browse.Results.list>0
    for _,row in ipairs(Browse.Results.list) do
        if not AAC.UX.GoldLot(row) then Browse.GoldPriceView=false; break end
    end
    if #Browse.Results.list==0 then Browse.GoldPriceView=Browse.LastSearch.cat1==13 and Browse.LastSearch.cat2==1 end
    AAC_BrowseHeaderPPU:SetText(Browse.GoldPriceView and AAC.UX.text.goldRate or AAC.UX.text.header)
	local first_index = AAC_BrowseListScrollBar:GetValue()

	for i = 1, Browse.DisplayedItems do
		local button = getglobal("AAC_BrowseListItem"..i)
		local info = Browse.Results.list[first_index+i]
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
				if not info[Browse["CustomSortItem"..k]] or info[Browse["CustomSortItem"..k]] == 0 or info[Browse["CustomSortItem"..k]] == "" then
					getglobal(buttonName.."Custom"..k):SetText(WHITE_FONT_COLOR_CODE.."-".."|r")
				elseif Browse["CustomSortItem"..k] == "level" then
					info.levelcolor = AAC.Tools.getLevelColor(info.level)
					getglobal(buttonName.."Custom"..k):SetText(info.levelcolor..info.level.."|r")
				else
					getglobal(buttonName.."Custom"..k):SetText(WHITE_FONT_COLOR_CODE..tonumber(string.format("%.2f", info[Browse["CustomSortItem"..k]])).."|r")
				end
			end
			getglobal(buttonName.."LeftTime"):SetText(SecondsToTime(info.leftTime * 60))
			if info.seller ~= "" then
				getglobal(buttonName.."Seller"):SetText(info.seller)
			else
				getglobal(buttonName.."Seller"):SetText(GRAY_FONT_COLOR_CODE..AUCTION_ANONYMOUS.."|r")
			end

            AAC.UX.PaintUnit(getglobal(buttonName.."PPUBuy"),getglobal(buttonName.."PPUBuyCurrencyIcon"),info,Browse.GoldPriceView)

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

	Browse.List_SetSelected(Browse.selected_auctionid)
end

function Browse.List_ItemIcon_OnClick(this,key)
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
			AAC.Browse.List_Select(this:GetParent().auctionid)
		end
	end
end

function Browse.List_FindAuctionIndex(auctionid)
	if not Browse.Results or not Browse.Results.list then
		return
	end
	for i, entry in ipairs(Browse.Results.list) do
		if entry.auctionid == auctionid then
			return i, entry
		end
	end
end

function Browse.List_Select(auctionid)
	Browse.List_SetSelected(auctionid)
end

function Browse.List_Item_OnClick(this, key)
	Browse.List_SetSelected(this.auctionid)
end

function Browse.Queue_UpdateAddButton()
	if not AAC_BrowseQueueButton then
		return
	end
	AAC_BrowseQueueButton:Disable()
	local _, entry = Browse.List_GetSelected()
	if entry
        and AAC.Market.Feature("BuyQueue")
		and entry.buyoutPrice > 0
		and not Browse.Queue.Map[entry.auctionid]
		and #Browse.Queue.Items < QUEUE_MAX
	then
		AAC_BrowseQueueButton:Enable()
	end
end

function Browse.Queue_FindIndex(auctionid)
	for i, entry in ipairs(Browse.Queue.Items) do
		if entry.auctionid == auctionid then
			return i, entry
		end
	end
end

function Browse.Queue_AddItem(entry)
	if not entry or entry.buyoutPrice <= 0 or not AAC.Market.Feature("BuyQueue") then
		return
	end
	if Browse.Queue.Map[entry.auctionid] then
		return
	end
	if #Browse.Queue.Items >= QUEUE_MAX then
		local message = AACLocale.Messages.AAC_BROWSE_QUEUE_LIMIT_REACHED or "Queue limit reached."
		SendWarningMsg(message:gsub("<MAX>", QUEUE_MAX))
		return
	end
	Browse.Queue.Map[entry.auctionid] = true
    local snapshot = {}
    for key, value in pairs(entry) do snapshot[key] = value end
    table.insert(Browse.Queue.Items, snapshot)
	Browse.Queue_UpdateList()
	Browse.Queue_UpdateTotal()
	Browse.Queue_UpdateAddButton()
	Browse.Queue_UpdateButtons()
	Browse.Queue_SetVisible(true, false)
end

function Browse.Queue_AddSelected()
	local _, entry = Browse.List_GetSelected()
	if entry then
		Browse.Queue_AddItem(entry)
	end
end

function Browse.Queue_Remove(auctionid, silent)
	if not Browse.Queue.Map[auctionid] then
		return
	end
	local index = Browse.Queue_FindIndex(auctionid)
	if index then
		table.remove(Browse.Queue.Items, index)
	end
	Browse.Queue.Map[auctionid] = nil
	if #Browse.Queue.Items == 0 then
	end
	if not silent then
		Browse.Queue_UpdateList()
		Browse.Queue_UpdateTotal()
		Browse.Queue_UpdateAddButton()
		Browse.Queue_UpdateButtons()
	end
end

function Browse.Queue_Clear()
	Browse.Queue.Items = {}
	Browse.Queue.Map = {}
	Browse.Queue_UpdateList()
	Browse.Queue_UpdateTotal()
	Browse.Queue_UpdateAddButton()
	Browse.Queue_UpdateButtons()
end

function Browse.Queue_UpdateButtons()
	local hasItems = #Browse.Queue.Items > 0
	if AAC_BrowseQueueBuyButton then
		if hasItems then
			AAC_BrowseQueueBuyButton:Enable()
		else
			AAC_BrowseQueueBuyButton:Disable()
		end
	end
	if AAC_BrowseQueueClearButton then
		if hasItems then
			AAC_BrowseQueueClearButton:Enable()
		else
			AAC_BrowseQueueClearButton:Disable()
		end
	end
	if not hasItems and not Browse.Queue.UserToggledOpen then
		Browse.Queue_SetVisible(false, false)
	end
end

function Browse.Queue_GetItems()
	return Browse.Queue.Items
end

function Browse.Queue_UpdateTotal()
	if AAC_BrowseQueueLimitLabel then
		local limitLabel = AACLocale.Messages.AAC_BROWSE_QUEUE_LIMIT or "Queue: <COUNT>/<MAX>"
		AAC_BrowseQueueLimitLabel:SetText(
			limitLabel:gsub("<COUNT>", #Browse.Queue.Items):gsub("<MAX>", QUEUE_MAX)
		)
	end
	if not AAC_BrowseQueueTotalLabel or not AAC_BrowseQueueTotalGoldText or not AAC_BrowseQueueTotalDiamondText then
		return
	end
	local totalGold = 0
	local totalDiamond = 0
	local totalCount = 0
	for _, entry in ipairs(Browse.Queue.Items) do
		totalCount = totalCount + (entry.count or 0)
		if entry.moneyMode == "account" then
			totalDiamond = totalDiamond + (entry.buyoutPrice or 0)
		else
			totalGold = totalGold + (entry.buyoutPrice or 0)
		end
	end
	local label = AAC_BROWSE_QUEUE_TOTAL
	AAC_BrowseQueueTotalLabel:SetText(label:gsub("<COUNT>", totalCount))
	AAC_BrowseQueueTotalGoldText:SetText(AAC.Tools.FormatThousands(totalGold))
	AAC_BrowseQueueTotalGoldIcon:Show()
	AAC_BrowseQueueTotalGoldText:Show()
	AAC_BrowseQueueTotalDiamondText:SetText(AAC.Tools.FormatThousands(totalDiamond))
	AAC_BrowseQueueTotalDiamondIcon:Show()
	AAC_BrowseQueueTotalDiamondText:Show()
end

function Browse.Queue_UpdateList()
	local scroll = AAC_BrowseQueueListScrollBar:GetValue()
	local maxValue = #Browse.Queue.Items - Browse.Queue.DisplayedItems
	if maxValue < 0 then
		maxValue = 0
	end
	if maxValue > 0 then
		AAC_BrowseQueueListScrollBar:SetMinMaxValues(0, maxValue)
		AAC_BrowseQueueListScrollBar:Show()
	else
		AAC_BrowseQueueListScrollBar:SetMinMaxValues(0, 0)
		AAC_BrowseQueueListScrollBar:Hide()
	end
	if scroll > maxValue then
		scroll = maxValue
		AAC_BrowseQueueListScrollBar:SetValue(scroll)
	end

	for i = 1, Browse.Queue.DisplayedItems do
		local button = getglobal("AAC_BrowseQueueItem"..i)
		local entry = Browse.Queue.Items[scroll + i]
		if entry then
			button.index = scroll + i
			button.link = entry.link
			local buttonName = button:GetName()
			local nameLabel = getglobal(buttonName.."Name")
			nameLabel:SetWidth(150)
			nameLabel:SetText(string.format("%sx %s", entry.count or 0, entry.name or ""))
			local r, g, b = GetItemQualityColor(GetQualityByGUID(entry.itemid or 0))
			nameLabel:SetColor(r or 1, g or 1, b or 1)
			nameLabel:Show()
			SetItemButtonTexture(getglobal(buttonName.."Icon"), entry.texture)
			SetItemButtonCount(getglobal(buttonName.."Icon"), entry.count or 0)
			local priceIcon = getglobal(buttonName.."PriceIcon")
			local priceText = getglobal(buttonName.."PriceText")
			priceText:SetText(AAC.Tools.FormatThousands(entry.buyoutPrice or 0))
			priceText:SetColor(1, 1, 1)
			priceText:Show()
			if entry.moneyMode == "account" then
				priceIcon:SetTexCoord(0.015625, 0.03125, 0, 1)
			else
				priceIcon:SetTexCoord(0, 0.015625, 0, 1)
			end
			button:Show()
		else
			button:Hide()
		end
	end
	for i = Browse.Queue.DisplayedItems + 1, 8 do
		local button = getglobal("AAC_BrowseQueueItem"..i)
		if button then
			button:Hide()
		end
	end
	Browse.Queue_UpdateButtons()
end

function Browse.Queue_SetVisible(show, userAction)
	if not AAC_BrowseQueueFrame then
		return
	end

	if userAction then
		Browse.Queue.UserToggledOpen = show
	end

	local hasItems = #Browse.Queue.Items > 0
	local allowEmpty = Browse.Queue.UserToggledOpen or userAction
	if show and not hasItems and not allowEmpty then
		show = false
	end

	if show then
		if AAC_BrowseSavedSearch and AAC_BrowseSavedSearch:IsVisible() then
			AAC.SavedSearch.MinimizeButton_OnClick()
		end
		AAC_BrowseQueueFrame:Show()
	else
		AAC_BrowseQueueFrame:Hide()
	end

	if AAC_BrowseQueueExpandButton then
		if show then
			AAC_BrowseQueueExpandButton:Hide()
		else
			AAC_BrowseQueueExpandButton:Show()
		end
	end
	if AAC_BrowseQueueMinimizeButton then
		if show then
			AAC_BrowseQueueMinimizeButton:Show()
		else
			AAC_BrowseQueueMinimizeButton:Hide()
		end
	end
end

function Browse.Queue_ToggleButton_OnClick()
	local isVisible = AAC_BrowseQueueFrame and AAC_BrowseQueueFrame:IsVisible()
	Browse.Queue_SetVisible(not isVisible, true)
end

function Browse.Queue_ItemIcon_OnEnter(this)
	local link = this:GetParent().link
	if not link then
		return
	end
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:SetHyperLink(link)
end

function Browse.Queue_ItemIcon_OnLeave(this)
	GameTooltip:Hide()
end

function Browse.Queue_ItemIcon_OnClick(this, key)
	local link = this:GetParent().link
	if not link then
		return
	end
	if IsShiftKeyDown() and key == "LBUTTON" then
		AAC.Tools.ChatEdit_AddItemLink(link, true)
	elseif IsCtrlKeyDown() and key == "LBUTTON" then
		ItemPreviewFrame_SetItemLink(ItemPreviewFrame, link)
	end
end

function Browse.QueueButton_OnClick(this)
	Browse.Queue_AddSelected()
end

function Browse.Queue_RemoveButton_OnClick(this)
	local index = this:GetParent().index
	local entry = Browse.Queue.Items[index]
	if entry then
		Browse.Queue_Remove(entry.auctionid)
	end
end

function Browse.Queue_BuyButton_OnClick(this)
	local items = Browse.Queue_GetItems()
	if #items > 0 then
		AAC.Pay.PayMultiAuction(items, AAC.Pay.AuctionType.Browse)
	end
end

function Browse.Queue_ClearButton_OnClick(this)
	Browse.Queue_Clear()
end



function Browse.List_GetSelected()
    local idx,entry = Browse.List_FindAuctionIndex(Browse.selected_auctionid)
    return idx,entry
end

function Browse.List_SetSelected(auctionid)
	AAC_BrowseBidButton:Disable()
	AAC_BrowseBuyoutButton:Disable()
	AAC_BrowseHistoryButton:Disable()

	for i = 1, Browse.DisplayedItems do
        local button = getglobal("AAC_BrowseListItem"..i)
    	button:UnlockHighlight()
	end

    Browse.selected_auctionid = auctionid
    local index = Browse.List_FindAuctionIndex(auctionid)
    if not index then
        Browse.selected_auctionid = nil
		Browse.Queue_UpdateAddButton()
        return
    end

    local first_index = AAC_BrowseListScrollBar:GetValue()
    local but_idx = index-first_index
    local button = _G["AAC_BrowseListItem"..but_idx]
    if not button or but_idx>Browse.DisplayedItems then return end

    local _,info = Browse.List_GetSelected()
    AAC.MoneyFrame.SetMode(AAC_BrowseBidMoneyInput, info.moneyMode)
    AAC.MoneyFrame.SetMoney(AAC_BrowseBidMoneyInput, AAC.Tools.CalcBidPrice(info.bidPrice))
    if not info.isBuyer and AAC.Market.Feature("ItemBids") then
        AAC_BrowseBidButton:Enable()
    end
    if info.buyoutPrice > 0 then
        AAC_BrowseBuyoutButton:Enable()
    end
    AAC_BrowseHistoryButton:Enable()
    button:LockHighlight()
	Browse.Queue_UpdateAddButton()
end

function Browse.Seller_OnEnter(this)
	local editBoxes = {
		"AAC_BrowseNameEditBox",
		"AAC_BrowseMinLvlEditBox",
		"AAC_BrowseMaxLvlEditBox",
		"AAC_BrowseFilter1EditBox",
		"AAC_BrowseFilter2EditBox",
		"AAC_BrowseFilter3EditBox",
		"AAC_BrowseFilterMinPriceEditBox",
		"AAC_BrowseFilterMaxPriceEditBox",
	};
	for i = 1, #editBoxes do
		_G[editBoxes[i]]:ClearFocus();
	end

	local itemNumberName = this:GetName()
	local itemNumber = string.match(itemNumberName, "%d+")
	local button = getglobal("AAC_BrowseListItem"..itemNumber)
	if Browse.selected_auctionid ~= this:GetParent().auctionid then
		button:LockHighlight()
	end
	
	local text = this:GetText();
	if text == UnitName("player") then this:SetTextColor(1,1,1) end
	if text == (GRAY_FONT_COLOR_CODE .. AUCTION_ANONYMOUS .. "|r") or text == UnitName("player") then return end;
	this:SetTextColor(0,1,0)
end

function Browse.Seller_OnLeave(this)
	local itemNumberName = this:GetName()
	local itemNumber = string.match(itemNumberName, "%d+")
	local button = getglobal("AAC_BrowseListItem"..itemNumber)
	if Browse.selected_auctionid ~= this:GetParent().auctionid then
		button:UnlockHighlight()
	end

	local text = this:GetText();
	if text == UnitName("player") then this:SetTextColor(1,1,1) end
	if text == (GRAY_FONT_COLOR_CODE .. AUCTION_ANONYMOUS .. "|r") or text == UnitName("player") then return end;
	this:SetTextColor(1,1,1)
end

function Browse.BuyoutMoney_OnEnter(this)
	local itemNumberName = this:GetName()
	local itemNumber = string.match(itemNumberName, "%d+")
	local button = getglobal("AAC_BrowseListItem"..itemNumber)
	if Browse.selected_auctionid ~= this:GetParent():GetParent().auctionid then
		button:LockHighlight()
	end
end

function Browse.BuyoutMoney_OnLeave(this)
	local itemNumberName = this:GetName()
	local itemNumber = string.match(itemNumberName, "%d+")
	local button = getglobal("AAC_BrowseListItem"..itemNumber)
	if Browse.selected_auctionid ~= this:GetParent():GetParent().auctionid then
		button:UnlockHighlight()
	end
end

local function CalculatePricePerUnit(item)
    return (item.buyoutPrice / item.count)
end

function Browse.PricePerUnit_OnEnter(this)
	local itemNumberName = this:GetName()
	local itemNumber = string.match(itemNumberName, "%d+")
	local button = getglobal("AAC_BrowseListItem"..itemNumber)
	if Browse.selected_auctionid ~= this:GetParent().auctionid then
		button:LockHighlight()
	end
    local item = Browse.Cache_FindAuction(this:GetParent().auctionid)
    if item then
        GameTooltip:SetOwner(this, "ANCHOR_TOP", 0, 0)
        GameTooltip:SetText((AAC.UX.GoldLot(item) and AAC.UX.text.goldRate or AAC.UX.text.header)..": "..AAC.UX.UnitText(item,true))
        GameTooltip:AddLine(AAC.UX.GoldLot(item) and AAC.UX.text.goldHint or AAC.UX.text.hint)
        GameTooltip:Show()
    end
end

function Browse.PricePerUnit_OnLeave(this)
	local itemNumberName = this:GetName()
	local itemNumber = string.match(itemNumberName, "%d+")
	local button = getglobal("AAC_BrowseListItem"..itemNumber)
	if Browse.selected_auctionid ~= this:GetParent().auctionid then
		button:UnlockHighlight()
	end
	GameTooltip:Hide()
end
