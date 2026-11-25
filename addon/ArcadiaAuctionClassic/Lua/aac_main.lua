local VERSION = "1.0.0"
-- Recover missing optional TOC data before capturing references. Never retry per frame.
local function dataTable(name, file)
    if type(_G[name]) ~= "table" and type(dofile) == "function" then
        pcall(dofile, "Interface/AddOns/ArcadiaAuctionClassic/Data/" .. file .. ".lua")
    end
    if type(_G[name]) ~= "table" then
        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("AAC: Optional metadata unavailable: " .. file) end
        _G[name] = {}
    end
    return _G[name]
end
local frameLoaded = false;
local DEFAULT_SETTINGS = { -- NB: all settings without default value will be deleted!
	HistoryMaxSaved = 1,
	PriceHistoryAutoshow = false,
	Resize = 0,
	SellDurationSelected = 1,
	AutoFillBidSelected = 1,
	AutoFillBuyoutSelected = 1,
	SellPromoteDropDown = 1,
	SellPromoteTimeDropDown = 1,
	SellAutoFillPercentBidValue = 100,
	FormulaBid = "",
	SellAutoFillPercentBuyoutValue = 100,
	FormulaBuyout = "",
	UseMatWhiteValue = false,
	FilterSpeed = 6,
	DecimalDigits = 5,
	AdvancedSettings = false,
	PPUSettings = true,
    UnitPriceRevision = 0,
	PPUDisplaySettings = true;
    AvgSuggest=false,
    BidAlertLimit=100000,
	DisableSave = false,
	WindowScale = 1,
}

ArcadiaAuctionClassicLoaded = true

AAC = {
	Manifest = {
		Name = "Arcadia Auction Classic",
		Author = "Blackkid (AAC); Mavoc, TellTod, Noguai, Graves, Byte (AAH)",
        Maintainer = "Blackkid",
        OriginalAuthors = "Mavoc, TellTod, Noguai, Graves, Byte",
		Source = "https://www.curseforge.com/chronicles-of-arcadia/addons/advancedauctionhouse",
		Root = "Interface/Addons/ArcadiaAuctionClassic",
		Licence = "GNU General Public License version 3 (GPLv3)",
		Build = 2026112301,
		Version = VERSION,
	},
	Data = {
		MatWhiteValue = dataTable("AAC_MatWhiteValue", "matwhitevalue"),
		PetEggs = dataTable("AAC_PetEggs", "peteggs"),
		Recipes = dataTable("AAC_Recipes", "recipes"),
		StatValues = dataTable("AAC_StatValues", "statstoattributes"),
	},
	Settings = {
		HistoryMin = 1,
		HistoryMax = 500,
		FilterSpeedMin = 1,
		FilterSpeedMax = 50,
		MinWarningPriceMin = 0,
		MinWarningPriceMax = 25000000,
		DecimalDigitsMin = 1,
		DecimalDigitsMax = 8,
	},
	Events = {},
	Updated = false;
}
AACFunc = AAC -- required for 3rd Party Addons (example: DailyNotes, yaCit)

local Main = {
	Active = true,
	FoundUpdate = false,
	CurrentTab = "DASHBOARD",
	FrameEvents = {
        "AUCTION_BUYORDER_LIST_UPDATE", "AUCTION_BUYORDER_RESULT", "AUCTION_BUYORDER_FILLED", "BAG_ITEM_UPDATE",
        "AUCTION_BROWSE_UPDATE", "AUCTION_SEARCH_RESULT", "AUCTION_BROWSE_PAGE_REFUSED",
		"AUCTION_AUCTION_INFO_UPDATE",
		"AUCTION_AUCTION_MONEY_UPDATE",
		"AUCTION_BUY_UPDATE",
		"AUCTION_SELL_UPDATE",
		--"AUCTION_BROWSE_UPDATE",
		--"AUCTION_SEARCH_RESULT",
		"AUCTION_HISTORY_SHOW",
		"AUCTION_HISTORY_HIDE",
		"AUCTION_OPEN",
		"AUCTION_CLOSE",
		--"AUCTION_BORWSE_PRICE_UPDATE",
	},
}
AAC.Main = Main

AAC_PROMOTE_TYPE_COLORS_MAIN = {
	[3] = { R = 0.99609375, G = 0.83984375, B = 0 },
	[2] = { R = 192/255, G = 192/255, B = 192/255 },
	[1] = { R = 205/255, G = 127/255, B = 50/255 },
}

local AAC_DefaultPosition = {
	point = "CENTER",
	relativePoint = "CENTER",
	relativeTo = "UIParent",
	x = 0,
	y = 0,
}

AAC_LAST_POSITION = {
	point = "CENTER",
	relativePoint = "CENTER",
	relativeTo = "UIParent",
	x = 0,
	y = 0,
}

function Main.OnLoad(this)
    for _, event in pairs(Main.FrameEvents) do this:RegisterEvent(event) end
    this:RegisterEvent("VARIABLES_LOADED")
    this:RegisterEvent("CHAT_MSG_SYSTEM")
    this:RegisterEvent("WARNING_MESSAGE")
end
function AAC_PrestigeFuncUpdate()
	if Prestige_IsBenefitActive(PrestigeBenefitType_AuctionHouse_HideName) then
		AAC_AnonymousSale:SetEnable(true);
	else
		AAC_AnonymousSale:SetEnable(false);
	end

	AAC_AnonymousSale:SetChecked(Prestige_IsAnonymousSale());

	-- if AAC_AnonymousSale:IsChecked() then
	-- 	AAC_AnonymousSale.On:Show();
	-- 	AAC_AnonymousSale.Off:Hide();

	-- 	AAC_AnonymousSale.Label:SetText(TEXT("PRESTIGE_BENEFIT_ANONYM_ON"));
	-- else
	-- 	AAC_AnonymousSale.On:Hide();
	-- 	AAC_AnonymousSale.Off:Show();

	-- 	AAC_AnonymousSale.Label:SetText(TEXT("PRESTIGE_BENEFIT_ANONYM_OFF"));
	-- end
end
--[[
function Main.Toggle(mode)
	Main.Active = ((mode ~= nil) and mode) or (not Main.Active)

	if Main.Active then
		for _, event in pairs(Main.FrameEvents) do
			AuctionFrame:UnregisterEvent(event)
			AAC_AuctionFrame:RegisterEvent(event)
		end
	else
		for _, event in pairs(Main.FrameEvents) do
			AuctionFrame:RegisterEvent(event)
			AAC_AuctionFrame:UnregisterEvent(event)
		end
		AUCTION_HEADER_SORT_ITEM = "name"
	end

    DEFAULT_CHAT_FRAME:AddMessage("AdvancedAuctionHouse toggled. State is now: "..(Main.Active and "|cff00ff00ON" or "|cffff0000OFF").."|r")
end
]]


function AAC.Events.AUCTION_AUCTION_MONEY_UPDATE(this)
end


function AAC.Events.AUCTION_CLOSE(this)
	HideUIPanel(this)
	AAC.Browse.Queue_Clear()
end

function AAC.Events.AUCTION_OPEN(this)
	ShowUIPanel(this)
	PlaySoundByPath("Sound\\Interface\\shop_open.mp3")
	AAC_PrestigeFuncUpdate();
	AAC.Browse.Queue_Clear()
end

function AAC.Events.VARIABLES_LOADED(this)
    AAC.Session.Init()
end

function Main.InitSaveVariables()
    AAC_SavedSearch = AAC_SavedSearch or {}
	SaveVariables("AAC_SavedSearch")

    AAC_LastSellPrice = AAC_LastSellPrice or {}
	if not AAC_LastSellPrice._TABLEBUILD or AAC_LastSellPrice._TABLEBUILD < 89 then
		AAC_LastSellPrice._TABLEBUILD = AAC.Manifest.Build
	end
	SaveVariables("AAC_LastSellPrice")
	SaveVariables("AAC_LAST_POSITION")

    AAC_SavedSettings = AAC_SavedSettings or {}
    for i, v in pairs(DEFAULT_SETTINGS) do
        if AAC_SavedSettings[i] == nil then
            AAC_SavedSettings[i] = v
        end
    end
    for i, v in pairs(AAC_SavedSettings) do
        if DEFAULT_SETTINGS[i] == nil then
            AAC_SavedSettings[i] = nil
        end
	end
    if AAC_SavedSettings.UnitPriceRevision < 1 then
        AAC_SavedSettings.PPUSettings = true
        AAC_SavedSettings.UnitPriceRevision = 1
    end
	if AAC_SavedSettings and AAC_SavedSettings.WindowScale then
		_G["AAC_AuctionFrame"]:SetScale( AAC_SavedSettings.WindowScale )
		_G["AAC_SettingsScaleSlider"]:SetValue( AAC_SavedSettings.WindowScale * 100 )
	else
		AAC_SavedSettings.WindowScale = DEFAULT_SETTINGS.WindowScale;
		_G["AAC_SettingsScaleSlider"]:SetValue( 100 )
	end
	
	SaveVariables("AAC_SavedSettings")
	frameLoaded = true;
end

function AAC.WindowScale_OnValueChanged(this)
	if not frameLoaded then return end
	if AAC_SavedSettings then
		AAC_SavedSettings.WindowScale = this:GetValue() / 100
	end
	_G["AAC_AuctionFrame"]:SetScale( this:GetValue() / 100 )
	getglobal(this:GetName().."Value"):SetText(this:GetValue().."%")
end

function Main.InitGUI(this)
    for _,name in ipairs({"AAC_BrowseHistoryButton","AAC_DashboardHistoryButton"}) do
        if _G[name] then _G[name]:SetText(AAC.TradingUI.Text("historyShort")) end
    end
    AAC_SettingsUseWhiteValueLabel:SetText(AAC.TradingUI.Text("materialUnit"))
    AAC_SettingsAvgDefaultLastPriceLabel:SetText(AAC.TradingUI.Text("averageFallback"))
    AAC_SettingsFilterSpeedLabel:SetText(AAC.TradingUI.Text("filterTempo"))
	PanelTemplates_SetNumTabs(this, 7)
    AAC.Sell.OnInit()

	Main.ResizeFrame(AAC_SavedSettings.Resize)
	AAC_SettingsUseWhiteValue:SetChecked(AAC_SavedSettings.UseMatWhiteValue)
	AAC_SettingsAvgDefaultLastPrice:SetChecked(AAC_SavedSettings.AvgSuggest)
	AAC_SettingsAlwaysShowPriceHistory:SetChecked(AAC_SavedSettings.PriceHistoryAutoshow)
	AAC_SettingsMaxHistory:SetValue(AAC_SavedSettings.HistoryMaxSaved)
	AAC_SettingsFilterSpeed:SetValue(AAC_SavedSettings.FilterSpeed)
	AAC_SettingsDecimalDigits:SetValue(AAC_SavedSettings.DecimalDigits)
	AAC_SettingsAdvancedSettings:SetChecked(AAC_SavedSettings.AdvancedSettings)
	AAC_SettingsPPUSettings:SetChecked(AAC_SavedSettings.PPUSettings)
	AAC_SettingsPPUDisplaySettings:SetChecked(AAC_SavedSettings.PPUDisplaySettings)
	AAC_SettingsMinWarningPrice:SetValue(AAC_SavedSettings.BidAlertLimit)
		
	AAC_DisableSaveSystem:SetChecked(AAC_SavedSettings.DisableSave)
	if AAC_SavedSettings.DisableSave then
		AAC_SavedSearch = {}
		AAC_LastSellPrice = {}
	end
end

function Main.OnShow(this)
	MoneyModeFrame_SetSelected(AAC_SellPayMoneyMode, 2) -- diamonds as default
	Main.ClickTab(6)
	AAC_BrowseRaritySwitch:SetChecked( false )
	AAC.Tools.SetDropDown(AAC_BrowseRarityDropDown, 1, AAC.Browse.RarityInfo[1], {1, 1, 1})
	AAC.Tools.SetDropDown(AAC_BrowseRuneDropDown, 1, AAC.Browse.RuneInfo[1])
	AAC.Browse.Results.pageNum = 1
	AAC.Browse.SelectedCategory = {}
	AAC.SavedSearch.Expand = {}
	AAC.MoneyFrame.ResetMoney(AAC_BrowseBidMoneyInput)
	AAC.Browse.CategoryScrollBar_Update()
	AAC.SavedSearch.ScrollBar_Update()
	AAC.Browse.List_Update()
	AAC.Bid.ReadList()
	AAC_BrowseSearchButton:Enable()
	AAC.Dashboard.Results.pageNum = 1
	AAC.Dashboard.SelectedCategory = {}
	AAC.Dashboard.List_Update()
	Main.RePlaceElements()
	AAC.Browse.Queue_UpdateList()
	AAC.Browse.Queue_UpdateTotal()
	AAC.Browse.Queue_SetVisible(false)
	this:ClearAllAnchors();
	this:SetAnchor(AAC_LAST_POSITION.point, AAC_LAST_POSITION.relativePoint, AAC_LAST_POSITION.relativeTo, AAC_LAST_POSITION.x, AAC_LAST_POSITION.y);

	local listingsString = string.format( AUCTION_ACTIVE_LISTINGS, GetAuctionActiveListingCount() );
	AAC_AuctionFrameTitleFrameText:SetText( string.format("%s - %s", "Arcadia Auction Classic by Blackkid", listingsString ) );
end

function AAC.Main.RePlaceElements()
	--Settings for Advanced Settings
	if AAC_SavedSettings.AdvancedSettings == true then
		AAC_BrowseRuneDropDown:Show()
		AAC_BrowseUsableButton:Show()
		AAC_BrowseFilter:Show()
		AAC_BrowseSavedSearchExpandButton:Show()
		AAC_BrowseSavedSearchPlusButton:Show()
		if AAC_BrowseQueueExpandButton then
			AAC_BrowseQueueExpandButton:Show()
		end
		if AAC_BrowseQueueMinimizeButton then
			AAC_BrowseQueueMinimizeButton:Hide()
		end
		
		--AAC_BrowseRarityDropDown:ClearAllAnchors()
		--AAC_BrowseRarityDropDown:SetAnchor( "LEFT", "RIGHT", AAC_BrowseRuneDropDown, 6, 0 )
		
		AAC_BrowseSearch:SetWidth( 316 )
		
		AAC_BrowseCurrency:ClearAllAnchors()
		AAC_BrowseCurrency:SetAnchor( "LEFT", "RIGHT", "AAC_BrowseFilter", -7, 0)
		AAC_BrowseRaritySwitch:ClearAllAnchors();
		AAC_BrowseRaritySwitch:SetAnchor( "TOP", "BOTTOM", "AAC_BrowseUsableButton", -44, 0)
		AAC_AuctionFrameTab5:SetText(AAC_MODE_ADVANCED)
		AAC_AuctionFrameTab5:SetTextColor(0.6,0.94,0.98)
		PanelTemplates_TabResize(AAC_AuctionFrameTab5, 20)
	else
		AAC_BrowseRuneDropDown:Hide()
		AAC_BrowseUsableButton:Hide()
		AAC_BrowseFilter:Hide()
		AAC_BrowseSavedSearchExpandButton:Hide()
		AAC_BrowseSavedSearchPlusButton:Hide()
		if AAC_BrowseQueueExpandButton then
			AAC_BrowseQueueExpandButton:Hide()
		end
		if AAC_BrowseQueueMinimizeButton then
			AAC_BrowseQueueMinimizeButton:Hide()
		end
		
		--AAC_BrowseRarityDropDown:ClearAllAnchors()
		--AAC_BrowseRarityDropDown:SetAnchor( "LEFT", "RIGHT", AAC_BrowseRuneDropDown, -56, 0 )
		
		--AAC_BrowseSearch:SetWidth( math.max( 220, ( AAC_BrowseRaritySwitchLabel:GetRight() - AAC_BrowseRarityDropDown:GetLeft() + 20 ) / GetUIScale() ) )
		
		AAC_BrowseCurrency:ClearAllAnchors()
		AAC_BrowseCurrency:SetAnchor( "TOPRIGHT", "TOPRIGHT", "AAC_AuctionFrame", -17, 32)
		AAC_BrowseRaritySwitch:ClearAllAnchors();
		AAC_BrowseRaritySwitch:SetAnchor( "LEFT", "RIGHT", "AAC_BrowseRarityDropDown", -2, 0)
		
		
		AAC_AuctionFrameTab5:SetText(AAC_MODE_BASIC)
		AAC_AuctionFrameTab5:SetTextColor(0,1,0)
		PanelTemplates_TabResize(AAC_AuctionFrameTab5, 20)
	end

	-- Settings for Price per Unit 
	if AAC_SavedSettings.PPUSettings then
		_G["AAC_BrowseHeaderPPU"]:Show()
		for i = 1, AAC.Browse.DisplayedItems do
			_G["AAC_BrowseListItem"..i.."PPUBuy"]:Show()
		end
		_G["AAC_BrowseHeaderPrice"]:ClearAllAnchors()
		_G["AAC_BrowseHeaderPrice"]:SetAnchor("TOP", "TOPLEFT", "$parent", 610, 5)

		_G["AAC_DashboardHeaderPPU"]:Show()
		for i = 1, AAC.Browse.DisplayedItems do
			_G["AAC_DashboardListItem"..i.."PPUBuy"]:Show()
		end
		_G["AAC_DashboardHeaderPrice"]:ClearAllAnchors()
		_G["AAC_DashboardHeaderPrice"]:SetAnchor("TOP", "TOPLEFT", "$parent", 744, 5)
	else
		_G["AAC_BrowseHeaderPPU"]:Hide()
		_G["AAC_BrowseHeaderPrice"]:ClearAllAnchors()
		_G["AAC_BrowseHeaderPrice"]:SetAnchor("TOP", "TOPLEFT", "$parent", 566, 5)
		for i = 1, AAC.Browse.DisplayedItems do
			_G["AAC_BrowseListItem"..i.."PPUBuy"]:Hide()
		end

		_G["AAC_DashboardHeaderPPU"]:Hide()
		_G["AAC_DashboardHeaderPrice"]:ClearAllAnchors()
		_G["AAC_DashboardHeaderPrice"]:SetAnchor("TOP", "TOPLEFT", "$parent", 675, 5)
		for i = 1, AAC.Browse.DisplayedItems do
			_G["AAC_DashboardListItem"..i.."PPUBuy"]:Hide()
		end
	end
end

function Main.OnHide(this)
	AAC_HistoryList:Hide()
	AAC_BrowseInfoLabel:SetText("")
	AAC_BrowseProgressLabel:SetText("")
	AAC.SavedSearch.MinimizeButton_OnClick()
	AAC.Browse.Queue_SetVisible(false)

    AAC.Browse.Frame_StopUpdates()
	AAC.Browse.Results.list = {}
	AAC.History.ClearQueue()


    AAC.CloseSession()
	local point, relativePoint, relativeTo, x, y = this:GetAnchor();
	AAC_LAST_POSITION = {
		point = point,
		relativePoint = relativePoint,
		relativeTo = "UIParent",
		x = x,
		y = y,
	}
end

local function SetupFiltersExplainedTab(frame)
	AAC.Main.CurrentTab = "FILTERS";
	frame:Show();
end

local function SetFiltersExplainedTitles(frame)
	local explainFrame = frame.ExplainFrame;
	local commandFrame = frame.CommandFrame;
	explainFrame.Label:SetText(AAC.TradingUI.Text("helpTitle"));
	commandFrame.Label:SetText(AAC.TradingUI.Text("commandsTitle"));
end

local function SetExplainFrameTextAnchors(frame, maxBulletPointsTop, maxBulletPointsBot)
	local explainFrame = frame.ExplainFrame;
	local firstAddonDesc = explainFrame.Description1;
	firstAddonDesc:ClearAllAnchors();
	firstAddonDesc:SetAnchor("TOPLEFT", "BOTTOMLEFT", explainFrame.DescriptionTitle, 0, 5);

	for i = 2, maxBulletPointsTop do
		local prevDesc = explainFrame["Description" .. i - 1];
		local currDesc = explainFrame["Description" .. i];
		currDesc:ClearAllAnchors();
		currDesc:SetAnchor("TOPLEFT", "BOTTOMLEFT", prevDesc, 0, 6);
	end

    explainFrame.Description4:SetText("Arcadia Auction Classic — Blackkid")
    explainFrame.Description5:SetText("AdvancedAuctionHouse: Mavoc, TellTod, Noguai, Graves, Byte")
    explainFrame.Description6:SetText("GPLv3 — LICENSE / AUTHORS / NOTICE")
    for i=4,6 do
        local f=explainFrame["Description"..i];f:ClearAllAnchors();f:SetAnchor("TOPLEFT","TOPLEFT",explainFrame,10,315+(i-4)*25);f:SetHeight(25);f:SetColor(0.65,0.65,0.65)
    end
	local firstFilterDesc = explainFrame.Description7;
	firstFilterDesc:ClearAllAnchors();
	firstFilterDesc:SetAnchor("TOPLEFT", "BOTTOMLEFT", explainFrame.FilterTitle, 0, 5);

	for i = 8, maxBulletPointsBot do
		local prevDesc = explainFrame["Description" .. i - 1];
		local currDesc = explainFrame["Description" .. i];
		currDesc:ClearAllAnchors();
		currDesc:SetAnchor("TOPLEFT", "BOTTOMLEFT", prevDesc, 0, 6);
	end
end

local function SetExplainFrameText(frame)
	local explainFrame = frame.ExplainFrame;
	explainFrame.DescriptionTitle:SetText("Arcadia Auction Classic — by Blackkid");
	explainFrame.DescriptionTitle:SetHeight(explainFrame.DescriptionTitle:GetDisplayHeight());
	explainFrame.FilterTitle:SetText(AAC.TradingUI.Text("stepsTitle"));
	explainFrame.FilterTitle:SetHeight(explainFrame.FilterTitle:GetDisplayHeight());
    explainFrame.FilterTitle:ClearAllAnchors()
    explainFrame.FilterTitle:SetAnchor("TOPLEFT","TOPLEFT",explainFrame,10,158)

	local addonDescriptions = {
        "• "..AAC.TradingUI.Text("sortStep"),
        "• "..AAC.TradingUI.Text("buysStep"),
        "• "..AAC.TradingUI.Text("salesStep"),
        "Arcadia Auction Classic — Blackkid",
        "AdvancedAuctionHouse: Mavoc, TellTod, Noguai, Graves, Byte",
        "GPLv3 — LICENSE / AUTHORS / NOTICE",
    };
    local filterDescriptions = {
        AAC.TradingUI.Text("searchStep"), AAC.TradingUI.Text("filterStep"),
        AAC.TradingUI.Text("excludeStep"), "", AAC.TradingUI.Text("exampleStep"), "",
    };

	for i = 1, #addonDescriptions do
		explainFrame["Description" .. i]:SetText(addonDescriptions[i]);
		explainFrame["Description" .. i]:SetHeight(explainFrame["Description" .. i]:GetDisplayHeight());
	end

	for i = 7, #filterDescriptions + 6 do
		explainFrame["Description" .. i]:SetText(filterDescriptions[i - 6]);
		explainFrame["Description" .. i]:SetHeight(explainFrame["Description" .. i]:GetDisplayHeight());
	end
end

local function SetCommandFrameTextAnchors(frame, maxCommands)
	local commandFrame = frame.CommandFrame;
	local firstCommand = commandFrame.Command1;
	local firstCommandDesc = commandFrame.Description1;
	firstCommand:ClearAllAnchors();
	firstCommand:SetAnchor("TOPLEFT", "BOTTOMLEFT", commandFrame.Title, 0, 5);
	firstCommandDesc:ClearAllAnchors();
	firstCommandDesc:SetAnchor("TOPRIGHT", "BOTTOMRIGHT", commandFrame.Title, 0, 5);

	for i = 2, maxCommands do
		local prevCmd = commandFrame["Command" .. i - 1];
		local currCmd = commandFrame["Command" .. i];
		local prevDesc = commandFrame["Description" .. i - 1];
		local currDesc = commandFrame["Description" .. i];
		currCmd:ClearAllAnchors();
		currCmd:SetAnchor("TOPLEFT", "BOTTOMLEFT", prevCmd, 0, 6);
		currDesc:ClearAllAnchors();
		currDesc:SetAnchor("TOPRIGHT", "BOTTOMRIGHT", prevDesc, 0, 6);
	end
end

local function SetCommandFrameText(frame)
	local commandFrame = frame.CommandFrame;
	commandFrame.Title:SetText("");
	commandFrame.Title:SetHeight(commandFrame.Title:GetDisplayHeight());

	local commands = {
		AAC_COMMAND_ZERO,
		AAC_COMMAND_ONE,
		AAC_COMMAND_TWO,
		AAC_COMMAND_THREE,
		AAC_COMMAND_FOUR,
		AAC_COMMAND_FIVE,
		AAC_COMMAND_SIX,
		AAC_COMMAND_GREEN,
		AAC_COMMAND_YELLOW,
		AAC_COMMAND_ORANGE,
		AAC_COMMAND_PURPLE
	};
	
	local descriptions = {
		AAC_COMMAND_ZERO_DESCRIPTION,
		AAC_COMMAND_ONE_DESCRIPTION,
		AAC_COMMAND_TWO_DESCRIPTION,
		AAC_COMMAND_THREE_DESCRIPTION,
		AAC_COMMAND_FOUR_DESCRIPTION,
		AAC_COMMAND_FIVE_DESCRIPTION,
		AAC_COMMAND_SIX_DESCRIPTION,
		AAC_COMMAND_GREEN_DESCRIPTION,
		AAC_COMMAND_YELLOW_DESCRIPTION,
		AAC_COMMAND_ORANGE_DESCRIPTION,
		AAC_COMMAND_PURPLE_DESCRIPTION
	};

	for i = 1, #commands do
		commandFrame["Command" .. i]:SetText(commands[i]);
		commandFrame["Description" .. i]:SetText(descriptions[i]);
	end

	commandFrame.Usage1:SetText("");
	commandFrame.Usage1:SetHeight(commandFrame.Usage1:GetDisplayHeight());
	commandFrame.Usage2:SetText(AAC.TradingUI.Text("cardsStep"));
	commandFrame.Usage2:SetHeight(commandFrame.Usage2:GetDisplayHeight());

	commandFrame.Example1:SetText("");
	commandFrame.Example1:SetHeight(commandFrame.Example1:GetDisplayHeight());
end

function Main.ClickTab(tab)
    if AAC.TradingUI then AAC.TradingUI.Close() end
    if AAC.Exchange then AAC.Exchange.Leave() end
    if tab~=1 and tab~=6 and AAC.History then AAC.History.ClearQueue() end
	if tab ~= 5 then
		PanelTemplates_SetTab(AAC_AuctionFrame, tab)
	end
	AAC_BrowseFrame:Hide()
	AAC_BidFrame:Hide()
	AAC_SellFrame:Hide()
	AAC_SettingsFrame:Hide()
	AAC_HistoryEditBox:Hide()
	AAC_SellEditBox:Hide()
	AAC_DashboardFrame:Hide()
	AAC_FiltersExplainedFrame:Hide()
	if tab == 1 then
	
		AAC_BrowseFrame:Show()

		if AAC.Main.CurrentTab == "DASHBOARD" then
			AAC.Browse.Results.pageNum = 1;
			AAC.Browse.SelectedCategory = {};
			AAC.Browse.Results.list = {};
			AAC.Browse.List_UpdateItems();
			AAC.Browse.CategoryScrollBar_Update();
			AAC_BrowseInfoLabel:Hide();
			AAC_BrowseSearchButton:Enable();
			AAC.Browse.Frame_StopUpdates();
			AAC_BrowseListScrollBar:SetMinMaxValues(0, 0)
		elseif AAC.Main.CurrentTab == "MODES" then
			AAC_BrowseSearchButton:Enable();
		end

		AAC.Main.CurrentTab = "BROWSE";

		AAC_HistoryEditBox:ClearAllAnchors()
		AAC_HistoryEditBox:SetAnchor( "BOTTOMLEFT", "BOTTOMLEFT", AAC_AuctionFrame, 450, -19 )
		AAC_HistoryEditBox:Show()		

	elseif tab == 2 then
		AAC.Main.CurrentTab = "BUY"
		AAC_BidFrame:Show()
	elseif tab == 3 then
		AAC.Main.CurrentTab = "SELL"
		AAC_SellFrame:Show()

		AAC_SellEditBox:ClearAllAnchors()
		AAC_SellEditBox:SetAnchor( "BOTTOMLEFT", "BOTTOMLEFT", AAC_AuctionFrame, 200, -19 )
		AAC_SellEditBox:Show()

		if AAC_SavedSettings.SellPromoteDropDown == 1 then
			_G["AAC_SellPromoteTimeDropDown"]:Hide()
			_G["AAC_SellPromoteTimeDropDownTooltip"]:Hide()
			_G["AAC_PromotePriceFrame"]:Hide()
			_G["AAC_SellPromoteDropDown"]:ClearAllAnchors()
			_G["AAC_SellPromoteDropDown"]:SetAnchor("TOPLEFT", "TOPLEFT", "AAC_SellExtras", 250, 30)
		else
			_G["AAC_SellPromoteTimeDropDown"]:ClearAllAnchors()
			_G["AAC_SellPromoteDropDown"]:ClearAllAnchors()
			_G["AAC_PromotePriceFrame"]:ClearAllAnchors()
			_G["AAC_SellPromoteDropDown"]:SetAnchor("TOPLEFT", "TOPLEFT", "AAC_SellExtras", 250, 30)
			_G["AAC_SellPromoteTimeDropDown"]:SetAnchor("TOPLEFT", "TOPLEFT", "AAC_SellExtras", 440, 30)
			_G["AAC_PromotePriceFrame"]:SetAnchor("TOPLEFT", "TOPLEFT", "AAC_SellExtras", 680, 15)
			_G["AAC_SellPromoteTimeDropDown"]:Show()
			_G["AAC_SellPromoteTimeDropDownTooltip"]:Show()
			_G["AAC_PromotePriceFrame"]:Show()
		end

		if AAC_SavedSettings.SellDurationSelected < AAC_SavedSettings.SellPromoteTimeDropDown then
			AAC.Tools.SetDropDown(AAC_SellPromoteTimeDropDown, AAC_SavedSettings.SellDurationSelected, AAC.Sell.DURATION_TIMES[AAC_SavedSettings.SellDurationSelected])
		end
		AAC.Sell.ShowPromoBG()
		AAC.Sell.PromotePriceFrame_Update()
	elseif tab == 4 then
		AAC.Main.CurrentTab = "SETTINGS"
		AAC_SettingsFrame:Show()
	elseif tab == 5 then
		AAC.Main.CurrentTab = "MODES"
		AAC_SavedSettings.AdvancedSettings = not AAC_SavedSettings.AdvancedSettings;
		AAC_SettingsAdvancedSettings:SetChecked(AAC_SavedSettings.AdvancedSettings);
		AAC.Main.RePlaceElements();
		Main.ClickTab(1);
	elseif tab == 6 then
		AAC_DashboardFrame:Show();
		AAC.Main.CurrentTab = "DASHBOARD";
		AAC_HistoryEditBox:Hide();
	elseif (tab == 7) then
		-- Configuration
		local frame = AAC_FiltersExplainedFrame;
		SetupFiltersExplainedTab(frame);
		SetFiltersExplainedTitles(frame);
		-- Explain Frame
		SetExplainFrameTextAnchors(frame, 6, 12);
		SetExplainFrameText(frame);
		-- Command Frame
		SetCommandFrameTextAnchors(frame, 11);
		SetCommandFrameText(frame);
	end
    if AAC.Exchange then AAC.Exchange.TabChanged(tab) end
    if AAC.TradingUI then AAC.TradingUI.PurchaseTabChanged(tab) end
end

function Main.SettingsResize(value)
	AAC_SettingsFrame1:SetSize(340, 440 + value)
	AAC_SettingsFrame2:SetSize(477, 440 + value)
	AAC_SettingsFrame3:SetSize(274, 440 + value)
end

function Main.ResizeFrame(num)
	local value = 44 * num
	if num == 0 then
		AAC_AuctionEnlargeButton:Enable()
		AAC_AuctionReduceButton:Disable()
	elseif num == 5 then
		AAC_AuctionEnlargeButton:Disable()
		AAC_AuctionReduceButton:Enable()
	else
		AAC_AuctionEnlargeButton:Enable()
		AAC_AuctionReduceButton:Enable()
	end
	AAC_AuctionFrame:SetSize(846, 489 + value)

	AAC.Browse.Resize(num, value)
	AAC.Bid.Resize(num, value)
    AAC.Sell.Resize(num, value)
    AAC.Dashboard.Resize(num, value)
    if AAC.TradingUI and AAC.TradingUI.Resize then AAC.TradingUI.Resize(num,value) end
	Main.SettingsResize(value)
	Main.RePlaceElements()
end
