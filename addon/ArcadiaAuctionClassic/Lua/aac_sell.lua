local Sell={
    AUTOFILLSTATES = {
        AAC_SELL_NONE,
        AAC_SELL_LAST,
        AAC_GENERAL_AVERAGE,
        AAC_SELL_FORMULA,
    },
    DURATION_TIMES= {
        string.format(TEXT("PRESTIGE_BENEFIT_AUCTION_DAY"), 1),
        string.format(TEXT("PRESTIGE_BENEFIT_AUCTION_DAY"), 2),
        string.format(TEXT("PRESTIGE_BENEFIT_AUCTION_DAY"), 3),
        string.format(TEXT("PRESTIGE_BENEFIT_AUCTION_DAY"), 7),
    },
	PROMOTION_STATUS = {
		AAC_SELL_NONE,
		AUCTION_PROMOTETYPE_1,
		AUCTION_PROMOTETYPE_2,
		AUCTION_PROMOTETYPE_3,
	},
	PROMOTION_STATUS_EXPLANATION = {
		AUCTION_PROMOTETYPE_0_EXPLANATION,
		AUCTION_PROMOTETYPE_1_EXPLANATION,
		AUCTION_PROMOTETYPE_2_EXPLANATION,
		AUCTION_PROMOTETYPE_3_EXPLANATION,
	},

    MAXITEMS = 3,
    SortMode = 0,
    internal_money_update = nil,

	MoneyType = 1,
	MoneyAuction = false,
	SellMoneyMode = "copper",
	PayMoneyMode = "copper",
	SellMoneyType = 1,
	PayMoneyType = 1,
	ItemTexture = "",
	HistoryButton_Clicked = 0,
}
AAC.Sell=Sell
AAC_AuctionSellList = {}

local function colorizeText(text, color)
	return string.format("|cff%02X%02X%02X%s|r", color.R, color.G, color.B, text)
end

local FONT_PROMOTE_TYPE_COLORS = {
	[1] = { R = 255, G = 255, B = 255 },
	[2] = { R = 205, G = 127, B = 50 },
	[3] = { R = 192, G = 192, B = 192 },
	[4] = { R = 253, G = 214, B = 0 },
}

local ownRevision, slotRevision = 0, 0

local INVALID_AUCTION_ITEM_WARNING = "Exclusive items and soulbound equipment cannot be auctioned!"

local function GetItemIdFromLink(link)
	if not link then return nil end

	local _, data = ParseHyperlink(link)
	if not data then return nil end

	return tonumber(data:match("(.-) ") or data, 16)
end

local NEW_AUCTION_IDS = {}
AAC_SELL_SORT_MODE = 3;
AAC_CTRL_PRESSED = false;

function Sell.OnLoad(this)
	-- PLAYER_MONEY is only needed while the auction house is open (see Sell.OnEvent)
	this:RegisterEvent("AUCTION_OPEN");
	this:RegisterEvent("AUCTION_CLOSE");
--@non-alpha@
	AAC_SellItemBrowse:Hide()
--@end-non-alpha@
	AAC_SellMoneyAuctionLabel:SetText(TEXT("AUCTION_SELL_MONEY_TAB"))
	Sell.ChangeAuctionType(false)

	AAC_SellAutoPriceLabel:SetText(AAC_SELL_AUTO_PRICE_HEADER)
	AAC_SellAutoFillPercentBidLabel:SetText(AAC_SELL_PERCENT)
	AAC_SellAutoFillPercentBuyoutLabel:SetText(AAC_SELL_PERCENT)
	AAC_SellPriceBidLabel:SetText(TEXT("AUCTION_FIRST_PRICE_COLON"))
	AAC_SellPriceBidPPULabel:SetText(AAC_GENERAL_PRICE_PER_UNIT_HEADER..":")
	
	AAC_SellPriceBuyoutLabel:SetText( TEXT( "AAH_BUYOUT" ) )
	AAC_SellPriceBuyoutPPULabel:SetText( TEXT( "AAH_BUYOUT_PPU" ) )

	UIDropDownMenu_SetWidth(AAC_SellAutoFillBidDropDown, 70)
	UIDropDownMenu_SetWidth(AAC_SellAutoFillBuyoutDropDown, 70)
	UIDropDownMenu_SetWidth(AAC_SellDurationDropDown, 80)
	UIDropDownMenu_SetWidth(AAC_SellPromoteDropDown, 100)
	UIDropDownMenu_SetWidth(AAC_SellPromoteTimeDropDown, 100)

	UIDropDownMenu_Initialize(AAC_SellDurationDropDown, Sell.DurationDropDown_Show)
	UIDropDownMenu_Initialize(AAC_SellAutoFillBidDropDown, Sell.AutoFillBidDropDown_Show)
	UIDropDownMenu_Initialize(AAC_SellAutoFillBuyoutDropDown, Sell.AutoFillBuyoutDropDown_Show)
	UIDropDownMenu_Initialize(AAC_SellPromoteDropDown, Sell.SellPromoteDropDown_Show)
	UIDropDownMenu_Initialize(AAC_SellPromoteTimeDropDown, Sell.SellPromoteTimeDropDown_Show)

    AAC.MoneyFrame.SetFocusOrder(AAC_SellMoneyAmount, AAC_SellPriceBid, AAC_SellPriceBuyoutPPU)
    AAC.MoneyFrame.SetFocusOrder(AAC_SellPriceBid, AAC_SellPriceBidPPU, AAC_SellMoneyAmount)
    AAC.MoneyFrame.SetFocusOrder(AAC_SellPriceBidPPU, AAC_SellPriceBuyout, AAC_SellPriceBid)
    AAC.MoneyFrame.SetFocusOrder(AAC_SellPriceBuyout, AAC_SellPriceBuyoutPPU, AAC_SellPriceBidPPU)
    AAC.MoneyFrame.SetFocusOrder(AAC_SellPriceBuyoutPPU, AAC_SellMoneyAmount, AAC_SellPriceBuyout)

    MoneyInputFrame_SetOnvalueChangedFunc(AAC_SellMoneyAmount, Sell.OnOfferChange)
    MoneyInputFrame_SetOnvalueChangedFunc(AAC_SellPriceBid, Sell.OnOfferChange1)
    MoneyInputFrame_SetOnvalueChangedFunc(AAC_SellPriceBidPPU, Sell.OnOfferChange2)
    MoneyInputFrame_SetOnvalueChangedFunc(AAC_SellPriceBuyout, Sell.OnOfferChange3)
    MoneyInputFrame_SetOnvalueChangedFunc(AAC_SellPriceBuyoutPPU, Sell.OnOfferChange4)

    getglobal("AAC_SellPayMoneyModeButton2"):SetVisible(IsAuctionItemAccountMoneyTrade() or IsAuctionAccountMoneyTrade())
    MoneyModeFrame_SetSelected(AAC_SellPayMoneyMode, 1)
    MoneyModeFrame_SetOnValueChangeFunc(AAC_SellPayMoneyMode, AAC.Sell.AuctionPayMoneyTypeChanged)
end

-- Charges remain stored after Prestige expires. Match the current native Sell window.
function Sell.PrestigeExtraDays()
    if type(Prestige_PrestigeAvailable) ~= "function" or not Prestige_PrestigeAvailable() then return 0 end
    return math.max(tonumber(Prestige_GetChargeCount(PrestigeBenefitType_AuctionHouse_Time)) or 0, 0)
end

local function GetPrestigeExtraDays()
	local prestigeAddDay = Sell.PrestigeExtraDays()
	if prestigeAddDay > 0 then
		local prestigeDays = 7 + prestigeAddDay
		return string.format(TEXT("PRESTIGE_BENEFIT_AUCTION_DAY"), prestigeDays);
	end
	return ""
end

function Sell.OnShow()
    Sell.InitNetPrices()
    if not AAC.CanRequest() then return end
    AAC_SellMoneyAuction:SetVisible(IsAuctionAccountMoneyTrade() == true)
    getglobal("AAC_SellPayMoneyModeButton2"):SetVisible(IsAuctionItemAccountMoneyTrade() or IsAuctionAccountMoneyTrade())
    if Sell.MoneyAuction and not IsAuctionAccountMoneyTrade() then
        Sell.ChangeAuctionType(false)
    end
	AAC_SellFrame:RegisterEvent("PLAYER_MONEY")
	Sell.List_Update()
	Sell.AutoFillBidEditBox_CheckVisibility()
	Sell.AutoFillBuyoutEditBox_CheckVisibility()

    Sell.Item_Update( true )
	Sell.HistoryButton_Clicked = 0;
end

function Sell.OnHide()

end

function Sell.OnInit()

	if Sell.PrestigeExtraDays() == 0 then
		AAC_SavedSettings.SellDurationSelected = AAC_SavedSettings.SellDurationSelected == 5 and 1 or AAC_SavedSettings.SellDurationSelected;
		AAC_SavedSettings.SellPromoteTimeDropDown = AAC_SavedSettings.SellPromoteTimeDropDown == 5 and 1 or AAC_SavedSettings.SellPromoteTimeDropDown;
	end

	AAC.Tools.SetDropDown(AAC_SellDurationDropDown, AAC_SavedSettings.SellDurationSelected, Sell.DURATION_TIMES[AAC_SavedSettings.SellDurationSelected] or GetPrestigeExtraDays())
	AAC.Tools.SetDropDown(AAC_SellAutoFillBidDropDown, AAC_SavedSettings.AutoFillBidSelected, Sell.AUTOFILLSTATES[AAC_SavedSettings.AutoFillBidSelected])
	AAC.Tools.SetDropDown(AAC_SellAutoFillBuyoutDropDown, AAC_SavedSettings.AutoFillBuyoutSelected, Sell.AUTOFILLSTATES[AAC_SavedSettings.AutoFillBuyoutSelected])
	AAC.Tools.SetDropDown(AAC_SellPromoteDropDown, AAC_SavedSettings.SellPromoteDropDown, colorizeText(Sell.PROMOTION_STATUS[AAC_SavedSettings.SellPromoteDropDown], FONT_PROMOTE_TYPE_COLORS[AAC_SavedSettings.SellPromoteDropDown]))
	AAC.Tools.SetDropDown(AAC_SellPromoteTimeDropDown, AAC_SavedSettings.SellPromoteTimeDropDown, Sell.DURATION_TIMES[AAC_SavedSettings.SellPromoteTimeDropDown] or GetPrestigeExtraDays())
	
	if Prestige_GetChargeCount(PrestigeBenefitType_AuctionHouse_Auctioneer) > 0 and AAC_SavedSettings.SellPromoteDropDown == 4 then
		local benefitBonus = Prestige_GetChargeCount(PrestigeBenefitType_AuctionHouse_Auctioneer);
		local dropDownType =  AAC_SavedSettings.SellPromoteDropDown;
		local text = colorizeText(Sell.PROMOTION_STATUS[dropDownType], FONT_PROMOTE_TYPE_COLORS[dropDownType]);
		text = colorizeText(text .. " (" .. TEXT("WEEKINSTANCE_FREE") .. " " .. benefitBonus .. ")", FONT_PROMOTE_TYPE_COLORS[dropDownType]);
		AAC.Tools.SetDropDown(AAC_SellPromoteDropDown, AAC_SavedSettings.SellPromoteDropDown, text)

		if AAC_SavedSettings.SellPromoteTimeDropDown <= 4 then
			text = Sell.DURATION_TIMES[AAC_SavedSettings.SellPromoteTimeDropDown] or GetPrestigeExtraDays();
			text = text .. " (" .. TEXT("WEEKINSTANCE_FREE") .. " " .. benefitBonus .. ")";
			AAC.Tools.SetDropDown(AAC_SellPromoteTimeDropDown, AAC_SavedSettings.SellPromoteTimeDropDown, text)
		end
	end
	
	AAC_SellAutoFillPercentBid:SetText(AAC_SavedSettings.SellAutoFillPercentBidValue)
	AAC_SellAutoFillFormulaBid:SetText(AAC_SavedSettings.FormulaBid)
	AAC_SellAutoFillPercentBuyout:SetText(AAC_SavedSettings.SellAutoFillPercentBuyoutValue)
	AAC_SellAutoFillFormulaBuyoutout:SetText(AAC_SavedSettings.FormulaBuyout)

    Sell.AutoFillBuyoutEditBox_CheckVisibility()
    Sell.AutoFillBidEditBox_CheckVisibility()
end

function Sell.OnEvent(this, event)
    if not AAC.CanRequest() and event ~= "AUCTION_CLOSE" then return end
	if (event == "PLAYER_MONEY") then
		Sell.TestIsAuctionValid();
	elseif (event == "AUCTION_OPEN") then
		this:RegisterEvent("PLAYER_MONEY");
		Sell.TestIsAuctionValid();
	elseif (event == "AUCTION_CLOSE") then
		this:UnregisterEvent("PLAYER_MONEY");
	end
end

function Sell.Resize(num, value)
	Sell.MAXITEMS = 3 + num
	AAC_SellList:SetSize(800, 179 + value)
	AAC_SellItemBrowse:SetSize(178, 179 + value)

	for i = Sell.MAXITEMS + 1, 11 do
		getglobal("AAC_SellListItem"..i):Hide()
	end
	for i = (Sell.MAXITEMS * 2) + 1, 22 do
		getglobal("AAC_SellItemBrowseItem"..i):Hide()
	end
	Sell.List_Update()
end

function Sell.ChangeAuctionType(state)

	AAC_SellMoneyAuction:SetChecked(state)
	Sell.MoneyAuction = state

	if state then
		AAC_SellPlaceItemButton:Disable()
		AAC_SellPayMoneyModeButton1:Disable()
		AAC_SellPayMoneyModeButton2:Disable()
		AAC_SellPlaceItemButtonName:Hide()
		AAC_SellPlaceItemButtonCount:Hide()
		AAC_SellMoneyModeButton1:Enable()
		AAC_SellMoneyModeButton2:Enable()
		AAC_SellMoneyAmount:Show()

		Sell.AuctionMoneyTypeChanged()
	else
		AAC_SellPlaceItemButton:Enable()
		AAC_SellPayMoneyModeButton1:Enable()
		AAC_SellPayMoneyModeButton2:Enable()
		AAC_SellPlaceItemButtonName:Show()
		AAC_SellPlaceItemButtonCount:Show()
		AAC_SellMoneyModeButton1:Disable()
		AAC_SellMoneyModeButton2:Disable()
		AAC_SellMoneyAmount:Hide()
		AAC_SellPriceBidPPULabel:SetText(AAC_GENERAL_PRICE_PER_UNIT_HEADER..": ")
		AAC_SellPriceBuyoutPPULabel:SetText(AAC_GENERAL_PRICE_PER_UNIT_HEADER..": ")

		Sell.AuctionPayMoneyTypeChanged()
	end
end

function Sell.AAC_SellMoneyMode_OnShow( this )
    if AAC.TradingUI and AAC.TradingUI.restoringContents then return end

	getglobal(this:GetName().."Button2"):Show()							
	MoneyFrameTemplate_SetMode(AAC_SellFeeFrame, "copper")
	local checkbox = getglobal( "AAC_SellMoneyAuction" );
	local moneyShell = checkbox:IsChecked();
	if( moneyShell ) then 
		checkbox:SetChecked( false );
		Sell.ChangeAuctionType( false );
	end

end

function Sell.AuctionMoneyTypeChanged()
	Sell.MoneyType = MoneyModeFrame_GetSelected(AAC_SellMoneyMode)
    local PPULabel
	if Sell.MoneyType == 1 then --"copper"
		Sell.SellMoneyMode = "copper"
		Sell.PayMoneyMode = "account"
		Sell.SellMoneyType = 1
		Sell.PayMoneyType = 2
		Sell.ItemTexture = "Interface/Icons/coin_03.dds"
        PPULabel = AAC_GENERAL_UNITS_PER_PRICE_HEADER..": "
		AAC.MoneyFrame.SetMode(AAC_SellPriceBuyout, "account")
		AAC.MoneyFrame.SetMode(AAC_SellPriceBuyoutPPU, "account")
	else --"account"
		Sell.SellMoneyMode = "account"
		Sell.PayMoneyMode = "copper"
		Sell.SellMoneyType = 2
		Sell.PayMoneyType = 1
		Sell.ItemTexture = "Interface/Icons/crystal_01.dds"
        PPULabel = AAC_GENERAL_PRICE_PER_UNIT_HEADER..": "
		AAC.MoneyFrame.SetMode(AAC_SellPriceBuyout, "copper")
		AAC.MoneyFrame.SetMode(AAC_SellPriceBuyoutPPU, "copper")
	end

	if AAC_SellMoneyAuction:IsChecked() == false then
		Sell.PayMoneyMode = "copper";
	end

	AAC.MoneyFrame.SetMode(AAC_SellPriceBid, Sell.PayMoneyMode)
	--AAC.MoneyFrame.SetMode(AAC_SellPriceBuyout, Sell.PayMoneyMode)
	AAC.MoneyFrame.SetMode(AAC_SellPriceBidPPU, "copper")
	--AAC.MoneyFrame.SetMode(AAC_SellPriceBuyoutPPU, "copper")
	AAC.MoneyFrame.SetMode(AAC_SellMoneyAmount, Sell.SellMoneyMode)
	MoneyFrameTemplate_SetMode(AAC_SellFeeFrame, Sell.PayMoneyMode)
	--MoneyFrameTemplate_SetMode(AAC_SellProfitBuyoutFrame, Sell.PayMoneyMode)
    AAC_SellPriceBidPPULabel:SetText(PPULabel)
    AAC_SellPriceBuyoutPPULabel:SetText(PPULabel)
	AAC_SellPlaceItemButtonTexture:SetFile(Sell.ItemTexture)

	Sell.Item_Update()
end

function Sell.AuctionPayMoneyTypeChanged()
	Sell.MoneyType = MoneyModeFrame_GetSelected(AAC_SellPayMoneyMode)
	if Sell.MoneyType == 1 then --"copper"
		Sell.SellMoneyMode = "copper"
		Sell.PayMoneyMode = "copper"
		Sell.SellMoneyType = 1
		Sell.PayMoneyType = 1
	else --"account"
		Sell.SellMoneyMode = "account"
		Sell.PayMoneyMode = "account"
		Sell.SellMoneyType = 2
		Sell.PayMoneyType = 2
	end
	Sell.ItemTexture = ""

	AAC.MoneyFrame.SetMode(AAC_SellPriceBid, Sell.PayMoneyMode)
	AAC.MoneyFrame.SetMode(AAC_SellPriceBidPPU, Sell.PayMoneyMode)
	AAC.MoneyFrame.SetMode(AAC_SellPriceBuyout, Sell.PayMoneyMode)
	AAC.MoneyFrame.SetMode(AAC_SellPriceBuyoutPPU, Sell.PayMoneyMode)
	MoneyFrameTemplate_SetMode(AAC_SellFeeFrame, "copper") -- don't know about fees of diamond auctions on inofficial servers, left as is
	--MoneyFrameTemplate_SetMode(AAC_SellProfitBuyoutFrame, "copper")

	Sell.Item_Update()
end

function Sell.ClearItem()
	if GetAuctionItem() then
		ClickAuctionItemButton()
		PickupBagItem(GetCursorItemInfo())
	end
end

function Sell.GetAuctionItem()
    local name, itemTexture, stackCount, itemPrice = GetAuctionItem()
	local moneyMode
	if Sell.MoneyAuction then
		if Sell.MoneyType == 1 then --"copper"
			moneyMode = "copper"
			name = TEXT("Sys200000_name_plural")
			itemTexture = "Interface/Icons/coin_03.dds"
		else --"account"
			moneyMode = "account"
			name = TEXT("Sys200003_name")
			itemTexture = "Interface/Icons/crystal_01.dds"
		end
		stackCount = AAC.MoneyFrame.GetMoney(AAC_SellMoneyAmount, moneyMode)
	end

    return name, itemTexture, stackCount, itemPrice, moneyMode
end

function Sell.ListHeader_OnClick(this)
	local id = this:GetID()

	AAC_SellHeaderNameSortIcon:SetFile("")
	AAC_SellHeaderLevelSortIcon:SetFile("")
	AAC_SellHeaderLeftTimeSortIcon:SetFile("")
	AAC_SellHeaderBuyerSortIcon:SetFile("")
	AAC_SellHeaderPriceSortIcon:SetFile("")


	if AAC_AuctionSellList.sortIndex == id or AAC_AuctionSellList.sortIndex == -id then
		Sell.SortMode = (Sell.SortMode + 1) % 4
	else
		Sell.SortMode = 0
	end
	if id == 6 then
        AAC.Tools.SetSortIcon(_G[this:GetName().."SortIcon"], Sell.SortMode)
	else
		if AAC_AuctionSellList.sortIndex == id then
			id = -id
            AAC.Tools.SetSortIcon(_G[this:GetName().."SortIcon"], 1)
		else
            AAC.Tools.SetSortIcon(_G[this:GetName().."SortIcon"], 0)
		end
	end
	Sell.List_Sort(id)
end

function Sell.List_Sort(index)
	local hasFilter = AAC_SellEditBox:GetText() ~= "";
	AAC_SELL_SORT_MODE = index;
	AAC_AuctionSellList.sortIndex = index;

	if hasFilter then
		Sell.RefreshSellList();
		return;
	end

	if math.abs(index) == 6 then
		if Sell.SortMode == 0 then
			table.sort(AAC_AuctionSellList.list, AAC.Tools.SortBidLess)
		elseif Sell.SortMode == 1 then
			table.sort(AAC_AuctionSellList.list, AAC.Tools.SortBidMore)
		elseif Sell.SortMode == 2 then
			table.sort(AAC_AuctionSellList.list, AAC.Tools.SortBuyoutLess)
		elseif Sell.SortMode == 3 then
			table.sort(AAC_AuctionSellList.list, AAC.Tools.SortBuyoutMore)
		end
	else
		if index == 1 or index == -1 then
			AAC.Tools.CurrentSortItem = "name"
		elseif index == 2 or index == -2 then
			AAC.Tools.CurrentSortItem = "level"
		elseif index == 3 or index == -3 then
			AAC.Tools.CurrentSortItem = "leftTime"
		-- elseif index == 4 or index == -4 then
		-- 	AAC.Tools.CurrentSortItem = "bidder"
		elseif index == 5 or index == -5 then
			AAC.Tools.CurrentSortItem = "status"
		end
		if AAC_AuctionSellList.sortIndex > 0 then
			table.sort(AAC_AuctionSellList.list, AAC.Tools.SortLess)
		else
			table.sort(AAC_AuctionSellList.list, AAC.Tools.SortMore)
		end
	end

	Sell.List_UpdateItems();

end

function Sell.AutoFillBidDropDown_Show()
	local buttonInfo
	for i = 1, 4 do
		buttonInfo = {}
		buttonInfo.text = Sell.AUTOFILLSTATES[i]
		buttonInfo.func = Sell.AutoFillBidDropDown_Click
		UIDropDownMenu_AddButton(buttonInfo)
	end
end

function Sell.AutoFillBidDropDown_Click(button)
	AAC.Tools.SetDropDown(AAC_SellAutoFillBidDropDown, button:GetID(), button:GetText())
	AAC_SavedSettings.AutoFillBidSelected = button:GetID()
	Sell.AutoFillBidEditBox_CheckVisibility()
	Sell.AutoFillPriceFields()
end

function Sell.AutoFillBidEditBox_CheckVisibility()
    AAC_SellAutoFillPercentBid:Hide()
    AAC_SellAutoFillFormulaBid:Hide()

	if UIDropDownMenu_GetSelectedID(AAC_SellAutoFillBidDropDown) == 3 then
		AAC_SellAutoFillPercentBid:Show()
	elseif UIDropDownMenu_GetSelectedID(AAC_SellAutoFillBidDropDown) == 4 then
		AAC_SellAutoFillFormulaBid:Show()
	end
end

function Sell.AutoFillBuyoutDropDown_Show()
	local buttonInfo
	for i = 1, 4 do
		buttonInfo = {}
		buttonInfo.text = Sell.AUTOFILLSTATES[i]
		buttonInfo.func = Sell.AutoFillBuyoutDropDown_Click
		UIDropDownMenu_AddButton(buttonInfo)
	end
end

function Sell.AutoFillBuyoutDropDown_Click(button)
	AAC.Tools.SetDropDown(AAC_SellAutoFillBuyoutDropDown, button:GetID(), button:GetText())
	AAC_SavedSettings.AutoFillBuyoutSelected = button:GetID()
	Sell.AutoFillBuyoutEditBox_CheckVisibility()
	Sell.AutoFillPriceFields()
end

function Sell.AutoFillBuyoutEditBox_CheckVisibility()
    AAC_SellAutoFillPercentBuyout:Hide()
    AAC_SellAutoFillFormulaBuyoutout:Hide()

	if UIDropDownMenu_GetSelectedID(AAC_SellAutoFillBuyoutDropDown) == 3 then
		AAC_SellAutoFillBuyoutDropDown:ClearAllAnchors()
		AAC_SellAutoFillBuyoutDropDown:SetAnchor("TOPLEFT", "TOPLEFT", "$parent", 502, 30)
		AAC_SellAutoFillPercentBuyout:Show()
	elseif UIDropDownMenu_GetSelectedID(AAC_SellAutoFillBuyoutDropDown) == 4 then
		AAC_SellAutoFillBuyoutDropDown:ClearAllAnchors()
		AAC_SellAutoFillBuyoutDropDown:SetAnchor("TOPLEFT", "TOPLEFT", "$parent", 502, 30)
		AAC_SellAutoFillFormulaBuyoutout:Show()
	else
		AAC_SellAutoFillBuyoutDropDown:ClearAllAnchors()
		AAC_SellAutoFillBuyoutDropDown:SetAnchor("TOPLEFT", "TOPLEFT", "$parent", 502, 30)
	end
end


function AAC.Events.AUCTION_AUCTION_INFO_UPDATE(this)
    slotRevision = slotRevision + 1
    Sell.CurrentItem = AAC.Tools.ParseLink(AAC.HookItemLink)
	Sell.Item_Update()
end

function Sell.OnDroppedItem(key)
	if key == "LBUTTON" and IsShiftKeyDown() then
		local link = GetAuctionItemLink()
		if ChatEdit_AddItemLink(link) then
			return
		end
	end

	if Sell.TryPlaceCursorItem() and key == "RBUTTON" then
		ItemClipboard_Clear()
	end
end

function Sell.Item_Update( NoHistory )
    local itemTexture
	if Sell.MoneyAuction then
		if Sell.MoneyType == 1 then
			itemTexture = "Interface/Icons/coin_03.dds"
            local _ = NoHistory or AAC.History.UpdateSellItemHistory(200000)
		else
			itemTexture = "Interface/Icons/crystal_01.dds"
            local _ = NoHistory or AAC.History.UpdateSellItemHistory(200003)
		end

		AAC_SellHistoryButton:Enable()

		AAC_SellPlaceItemButtonTexture:SetTexture(itemTexture)
		AAC_SellPlaceItemButtonName:SetText("")
		AAC_SellPlaceItemButtonCount:SetText("")
		AAC.MoneyFrame.ResetMoney(AAC_SellMoneyAmount)
		AAC.MoneyFrame.ResetMoney(AAC_SellPriceBid)
		AAC.MoneyFrame.ResetMoney(AAC_SellPriceBuyout)
	else
		local name, itemTexture, stackCount, itemPrice = GetAuctionItem()
		local link = GetAuctionItemLink()

		if stackCount and stackCount <= 1 then
			stackCount = ""
		end
		AAC_SellPlaceItemButtonName:SetText( "" )
		AAC_SellPlaceItemButtonTexture:SetTexture(itemTexture)
		AAC_SellPlaceItemButtonCount:SetText(stackCount)
		AAC.MoneyFrame.ResetMoney(AAC_SellPriceBid)
		AAC.MoneyFrame.ResetMoney(AAC_SellPriceBuyout)
		if link then
			local _, data = ParseHyperlink( link )
			local ID = tonumber( data:match( "(.-) " ) or data, 16 )
			
			AAC_SellPlaceItemButtonName:SetText( GetReplaceSystemKeyword( "[" .. ID .. "]" ) )
			
			local _ = NoHistory or AAC.History.UpdateSellItemHistory(Sell.CurrentItem)
			AAC_SellHistoryButton:Enable()
		else
			AAC_SellHistoryButton:Disable()
		end
	end

	-- Fill now; the history reply refills, but it never comes for items without sales or throttled requests
	Sell.AutoFillPriceFields(true)
    Sell.FeeFrame_Update()
	Sell.TestIsAuctionValid()
end

function Sell.FeeFrame_Update()
    local _, _, stackCount, price, _ = Sell.GetAuctionItem()
	MoneyFrame_Update("AAC_SellFeeFrame", Sell.GetAuctionFee(price,stackCount) )
    Sell.UpdateSaleIncome()
end

-- Current native SaleFee uses basis points, floor, and a cap at gross.
-- Unknown server rates are displayed as unknown, never as a guessed zero.
function Sell.GetSaleFee(gross, mode, lot)
    if type(gross) ~= "number" or gross < 0 or gross ~= gross or gross == math.huge then return end
    if type(IsFunctionEnable) ~= "function" or not IsFunctionEnable(9107)
        or type(GetAuctionFeeRates) ~= "function" then return end
    local ok, gold, diamonds, _, currency = pcall(GetAuctionFeeRates)
    if not ok then return end
    local rate = mode == "account" and diamonds or gold
    if lot and type(currency) == "number" and currency >= 0 then rate = currency end
    if type(rate) ~= "number" or rate < 0 or rate ~= rate or rate == math.huge then return end
    return math.min(gross, math.floor(gross * rate / 10000)), rate
end

function Sell.SaleIncomeText(gross, mode, lot)
    local fee, rate = Sell.GetSaleFee(gross, mode, lot)
    if not fee then return AAC_SALE_UNKNOWN or "Sale fee / net proceeds: unavailable" end
    local money = TEXT(mode == "account" and "SYS_MONEY_TYPE_1" or "SYS_MONEY_TYPE_0")
    return string.format(AAC_SALE_INCOME or "Sale fee %.2f%%: %d %s | Net: %d %s",
        rate / 100, fee, money, gross - fee, money)
end

function Sell.UpdateSaleIncome()
    if not AAC_SellIncomeText or not AAC_SavedSettings then return end
    Sell.UpdateNetPrices()
    local name, _, _, _, lot = Sell.GetAuctionItem()
    local gross = AAC.MoneyFrame.GetMoney(AAC_SellPriceBuyout, Sell.PayMoneyMode) or 0
    AAC_SellIncomeText:SetText(name and Sell.SaleIncomeText(gross, Sell.PayMoneyMode, lot) or "")
end

function Sell.GetAuctionFee(price,stackCount)
    if Sell.MoneyAuction or not price or not stackCount then return 0 end

    local times={24,48,72,168}
	local prestigeAddDay = Sell.PrestigeExtraDays(); 
	if prestigeAddDay > 0 then
		local addHours = (7 + prestigeAddDay) * 24;
		table.insert(times, addHours);
	end

	local duration = times[AAC_SavedSettings.SellDurationSelected] or 0
	--return math.floor((duration / 4) * (price * stackCount * 0.006))
	return Auction_GetTax(price, stackCount, duration);
end

local function currencyName(mode)
    return TEXT(mode == "account" and "SYS_MONEY_TYPE_1" or "SYS_MONEY_TYPE_0")
end

local function listing()
    if not AAC.CanRequest() or not AAC_SavedSettings then return end
    local name, _, count, itemPrice, lotMode = Sell.GetAuctionItem()
    local buyout = AAC.MoneyFrame.GetMoney(AAC_SellPriceBuyout, Sell.PayMoneyMode)
    local duration = AAC_SavedSettings.SellDurationSelected
    local promote = AAC_SavedSettings.SellPromoteDropDown - 1
    local promoteTime = promote > 0 and AAC_SavedSettings.SellPromoteTimeDropDown or 0
    local mode = Sell.PayMoneyMode
    if not name or not count or count <= 0 or count ~= math.floor(count)
        or not buyout or buyout <= 0 or buyout ~= math.floor(buyout)
        or not duration or duration < 1 or duration > 5
        or not AAC.MoneyFrame.IsValueValid(AAC_SellPriceBuyout)
        or not AAC.MoneyFrame.IsValueValid(AAC_SellPriceBuyoutPPU) then return end
    if duration == 5 and Sell.GetDurationMinutes(duration) <= 0 then return end
    if promote > 0 and (not AAC.Market.Feature("Promotion") or promote > 3
        or not promoteTime or promoteTime > duration or Sell.GetDurationMinutes(promoteTime) <= 0) then return end
    if lotMode and not IsAuctionAccountMoneyTrade() then return end
    if not lotMode and mode == "account" and not IsAuctionItemAccountMoneyTrade()
        and not IsAuctionAccountMoneyTrade() then return end

    local link = not lotMode and GetAuctionItemLink() or nil
    local itemID = lotMode and (lotMode == "copper" and 200000 or 200003) or GetItemIdFromLink(link)
    if not itemID or (not lotMode and not Sell.CanAuctionItemLink(link)) then return end
    if GetAuctionNumSellItems() >= 100 + Prestige_GetChargeCount(PrestigeBenefitType_AuctionHouse_Slots) then return end
    local fee = Sell.GetAuctionFee(itemPrice, count)
    local promotionCost = promote > 0 and Auction_PromotePrice(buyout, Sell.PayMoneyType, promote, promoteTime) or 0
    local gold = fee + (lotMode == "copper" and count or 0)
    local diamonds = promotionCost + (lotMode == "account" and count or 0)
    if gold > GetPlayerMoney("copper") or diamonds > GetPlayerMoney("account") then return end
    return {
        itemID = itemID, link = link, name = name, count = count, buyout = buyout,
        mode = mode, payType = Sell.PayMoneyType, lotMode = lotMode, lotType = Sell.MoneyType,
        duration = duration, promote = promote, promoteTime = promoteTime,
        fee = fee, promotionCost = promotionCost, revision = slotRevision,
        saleFee = Sell.GetSaleFee(buyout, mode, lotMode),
    }
end

local function sameListing(a, b)
    if not b then return false end
    for key, value in pairs(a) do
        if b[key] ~= value then return false end
    end
    return a.link == b.link and a.lotMode == b.lotMode and a.saleFee == b.saleFee
end

local function countAuctionOffers(item)
    local matches = 0
    for i = 1, GetAuctionNumSellItems() do
        local _, stack, _, _, _, _, _, mode, _, buyout = GetAuctionSellItemInfo(i)
        local link = GetAuctionSellItemLink(i)
        local match = (item.lotMode and GetItemIdFromLink(link) == item.itemID) or link == item.link
        if link and match and mode == item.mode and buyout == item.buyout
            and stack == (item.lotMode and 1 or item.count) then matches = matches + 1 end
    end
    return matches
end

function Sell.TestIsAuctionValid()
    Sell.UpdateSaleIncome()
    AAC_SellConfirmButton:SetEnable(listing() ~= nil)
end

function Sell.ConfirmButton_OnClick()
    local offer = listing()
    if not offer or AAC.Market.TransactionPending() then return end
    if offer.lotMode == "account" and not CheckPasswordState(Sell.ConfirmButton_OnClick) then return end

    local days = Sell.GetDurationText(offer.duration)
    local description = string.format("%dx %s\n%d %s | %s", offer.count, offer.link or offer.name,
        offer.buyout, currencyName(offer.mode), days)
    local commission, rate = Sell.GetSaleFee(offer.buyout, offer.mode, offer.lotMode)
    if commission then
        description = description .. string.format(AAC_SALE_CONFIRM_INCOME or
            "\nFee (%g%%): %d %s\nYou receive: %d %s", rate / 100, commission,
            currencyName(offer.mode), offer.buyout - commission, currencyName(offer.mode))
    else
        description = description .. "\n" .. (AAC_SALE_UNKNOWN or "Sale fee / proceeds: unavailable")
    end
    if offer.fee > 0 then
        description = description .. string.format("\n%s: %d %s", AAC_LISTING_COST or "Listing", offer.fee, currencyName("copper"))
    end
    if offer.promote > 0 then
        description = description .. string.format("\n%s: %d %s", AAC_PROMOTION_COST or "Promotion",
            offer.promotionCost, currencyName("account"))
    end
    AAC.Market.Confirm("AAC_MARKET_SELL", description, function()
        if not sameListing(offer, listing()) then AAC.Market.Changed(); return end
        local previous = countAuctionOffers(offer)
        local revision = ownRevision
        AAC.Market.Submit("sell", function()
            if revision == ownRevision or countAuctionOffers(offer) <= previous then return false end
            if not offer.lotMode and GetAuctionItemLink() == offer.link then return false end
            local unit = offer.itemID == 200000 and offer.count / offer.buyout or offer.buyout / offer.count
            Sell.UpdateLastPrice(offer.itemID, unit, unit)
            if AAC.SellerTools then AAC.SellerTools.Record(offer) end
            return true
        end, function()
            if offer.lotMode then
                CreateAuctionMoney(offer.duration, offer.lotType, offer.count, offer.buyout, offer.payType,
                    offer.buyout, offer.promote, offer.promoteTime)
            else
                CreateAuctionItem(offer.duration, offer.buyout, offer.payType, offer.buyout,
                    offer.promote, offer.promoteTime)
            end
        end)
    end)
end

function Sell.RequestHistory( id, inherent, sell)
	Sell.HistoryButton_Clicked = 1;
	if not id then
		id = Sell.CurrentItem
		if Sell.MoneyAuction then
			id = (Sell.MoneyType==1) and 200000 or 200003
		end
	end

    AAC.History.RequestHistoryPopup(nil,id, inherent, sell == nil and true or sell)
end

function AAC.Events.AUCTION_SELL_UPDATE(this)
    ownRevision = ownRevision + 1
    Sell.List_Update()
end

function Sell.List_Update()
    local rows = {}
    for index = 1, GetAuctionNumSellItems() do
        local name, count, rarity, texture, level, leftTime, bidder, moneyMode, bidPrice, buyoutPrice,
            promoteType, promoteTime = GetAuctionSellItemInfo(index)
        local link = GetAuctionSellItemLink(index)
        local itemid = GetItemIdFromLink(link)
        if itemid and name and count then
            local row = {
                revision = ownRevision,
                auctionid = index,
                realPosition = index,
                name = name,
                count = count,
                rarity = rarity or 0,
                texture = texture,
                level = level or 0,
                leftTime = leftTime or 0,
                bidder = bidder,
                moneyMode = moneyMode,
                bidPrice = bidPrice or 0,
                buyoutPrice = buyoutPrice or 0,
                promoteType = promoteType or 0,
                promoteTime = promoteTime or 0,
                link = link,
                itemid = itemid,
            }
            if itemid >= 204476 and itemid <= 204508 then
                AAC_Tooltip:SetHyperLink(link)
                AAC_Tooltip:Hide()
                for line = 1, 10 do
                    local text = AAC.Tools.NormalizeTooltipText(_G["AAC_TooltipTextLeft" .. line]:GetText())
                    local petLevel = tonumber(text:match(TEXT("SYS_LEVEL") .. ": (%d+)"))
                    if petLevel then
                        row.level = petLevel
                        break
                    end
                end
            end
            rows[#rows + 1] = row
        end
    end
    AAC_AuctionSellList.list = rows
    AAC_AuctionSellList.maxNums = #rows

	if AAC_AuctionSellList.sortIndex then
		Sell.List_Sort(AAC_AuctionSellList.sortIndex)
	end
	-- Update ScrollBar
	local maxValue = AAC_AuctionSellList.maxNums - Sell.MAXITEMS
	if maxValue > 0 then
		AAC_SellListScrollBar:SetMinMaxValues(0, maxValue)
		AAC_SellListScrollBar:Show()
	else
		AAC_SellListScrollBar:SetMinMaxValues(0, 0)
		--AAC_SellListScrollBar:Hide()
	end
	
	if AAC_SellEditBox:GetText() == "" then
		Sell.List_UpdateItems()
	else
		Sell.RefreshSellList()
	end

	if Prestige_GetChargeCount(PrestigeBenefitType_AuctionHouse_Auctioneer) > 0 and AAC_SavedSettings.SellPromoteDropDown == 4 then
		local benefitBonus = Prestige_GetChargeCount(PrestigeBenefitType_AuctionHouse_Auctioneer);
		local dropDownType =  AAC_SavedSettings.SellPromoteDropDown;
		local text = colorizeText(Sell.PROMOTION_STATUS[dropDownType], FONT_PROMOTE_TYPE_COLORS[dropDownType]);
		text = colorizeText(text .. " (" .. TEXT("WEEKINSTANCE_FREE") .. " " .. benefitBonus .. ")", FONT_PROMOTE_TYPE_COLORS[dropDownType]);
		AAC.Tools.SetDropDown(AAC_SellPromoteDropDown, AAC_SavedSettings.SellPromoteDropDown, text)

		if AAC_SavedSettings.SellPromoteTimeDropDown <= 4 then
			text = Sell.DURATION_TIMES[AAC_SavedSettings.SellPromoteTimeDropDown] or GetPrestigeExtraDays();
			text = text .. " (" .. TEXT("WEEKINSTANCE_FREE") .. " " .. benefitBonus .. ")";
			AAC.Tools.SetDropDown(AAC_SellPromoteTimeDropDown, AAC_SavedSettings.SellPromoteTimeDropDown, text)
		end
	end
end

function Sell.List_UpdateItems()
	local index = AAC_SellListScrollBar:GetValue() + 1
	local button, buttonName
	local info, r, g, b
	for i = 1, Sell.MAXITEMS do
		button = getglobal("AAC_SellListItem"..i)
		info = AAC_AuctionSellList.list[index]
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
			-- `button.index` is the current list position, which may change due to sorting/filtering.
			-- Store the stable auction index separately so tooltips/linking always reference the correct offer.
			button.index = index
			button.auctionid = info.auctionid
			buttonName = button:GetName()
			r,g,b = GetItemQualityColor(GetQualityByGUID(info.itemid))
			local color = "|cff"..string.format("%02x",r*255)..string.format("%02x",g*255)..string.format("%02x",b*255)
			getglobal(buttonName.."Name"):SetText(info.stat and color..info.name.."|r\n"..info.stat or color..info.name.."|r")
			getglobal(buttonName.."Level"):SetText(AAC.Tools.getLevelColor(info.level)..info.level.."|r")
			getglobal(buttonName.."LeftTime"):SetText(SecondsToTime(info.leftTime * 60))
			if (info.promoteTime ~= 0) then
				getglobal(buttonName.."PromotionLeftTime"):SetText(SecondsToTime(info.promoteTime * 60))
			else
				getglobal(buttonName.."PromotionLeftTime"):SetText("-")
			end
			--getglobal(buttonName.."Bidder"):SetText(info.bidder)
			SetItemButtonCount(getglobal(buttonName.."Icon"), info.count)
			SetItemButtonTexture(getglobal(buttonName.."Icon"), info.texture)
			MoneyFrame_Update(buttonName.."BidMoney", info.bidPrice, info.moneyMode or "copper")
			if info.buyoutPrice > 0 then
				MoneyFrame_Update(buttonName.."BuyoutMoney", info.buyoutPrice, info.moneyMode or "copper")
				getglobal(buttonName.."BuyoutMoney"):Show()
			else
				getglobal(buttonName.."BuyoutMoney"):Hide()
			end
			button:Show()
		else
			button.auctionid = nil
			button:Hide()
		end
		index = index + 1
	end
	AAC_SellNumberLabel:SetText(AAC_SELL_NUM_AUCTION)
	AAC_SellNumber:SetText(GetAuctionNumSellItems() .. "/" .. (100 + Prestige_GetChargeCount(PrestigeBenefitType_AuctionHouse_Slots)))
	Sell.List_SetSelected(AAC_AuctionSellList.selected)
end

function Sell.List_IconClick(this,key)
    if IsShiftKeyDown() and key == "LBUTTON" then
		local parent = this:GetParent()
		local auctionid = parent and parent.auctionid
		local link = auctionid and GetAuctionSellItemLink(auctionid) or nil
		if link then
			AAC.Tools.ChatEdit_AddItemLink(link)
		end
    end

    Sell.List_SetSelected(this:GetParent().index)
end

function Sell.OwnOfferLive(info)
    if not AAC.CanRequest() or not info or info.revision ~= ownRevision or not info.link then return false end
    local name, count, _, _, _, _, bidder, mode, bid, buyout, promote =
        GetAuctionSellItemInfo(info.realPosition)
    return name == info.name and count == info.count and bidder == info.bidder and (not bidder or bidder == "")
        and mode == info.moneyMode and (bid or 0) == info.bidPrice and (buyout or 0) == info.buyoutPrice
        and (promote or 0) == info.promoteType and GetAuctionSellItemLink(info.realPosition) == info.link
end

function Sell.GetSelectedListInfo()
	local selected = AAC_AuctionSellList.selected
	if not selected then
		return nil
	end

	if AAC_SellEditBox:GetText() == "" then
		return AAC_AuctionSellList.list[selected]
	end

	return NEW_AUCTION_IDS[selected]
end

function Sell.GetDurationChoiceCount()
	local durationCount = #Sell.DURATION_TIMES
	if Sell.PrestigeExtraDays() > 0 then
		durationCount = durationCount + 1
	end
	return durationCount
end

function Sell.GetDurationText(durationType)
	return Sell.DURATION_TIMES[durationType] or GetPrestigeExtraDays()
end

function Sell.GetDurationMinutes(durationType)
	local durationMinutes = {
		24 * 60,
		48 * 60,
		72 * 60,
		168 * 60,
	}

	if durationType == 5 then
		local prestigeAddDay = Sell.PrestigeExtraDays()
		if prestigeAddDay > 0 then
			return (7 + prestigeAddDay) * 24 * 60
		end
	end

	return durationMinutes[durationType] or 0
end

function Sell.GetPromoteDurationMinutes(info, durationType)
	if durationType == 0 then
		return (info and info.promoteTime) or 0
	end

	return Sell.GetDurationMinutes(durationType)
end

function Sell.GetPromoteDurationText(info, durationType)
	if durationType == 0 then
		return SecondsToTime(((info and info.promoteTime) or 0) * 60)
	end

	return Sell.GetDurationText(durationType)
end

function Sell.GetMaxDurationMinutes()
	return Sell.GetDurationMinutes(Sell.GetDurationChoiceCount())
end

function Sell.GetAvailableExtendDurations(info)
	local durationTypes = {}
	if not info then
		return durationTypes
	end

	local maxDuration = Sell.GetMaxDurationMinutes()
	for durationType = 1, Sell.GetDurationChoiceCount() do
		local duration = Sell.GetDurationMinutes(durationType)
		if duration > 0 and info.leftTime + duration <= maxDuration then
			table.insert(durationTypes, durationType)
		end
	end

	return durationTypes
end

function Sell.HasAvailableExtendDuration(info)
	return #Sell.GetAvailableExtendDurations(info) > 0
end

function Sell.CanPromoteListInfo(info, promoteType)
	if not info then
		return false
	end

	return promoteType > 0 and (info.promoteType == 0 or promoteType > info.promoteType)
end

function Sell.CanPromoteSelection(info, promoteType, promoteTimeType)
	if not info or promoteType <= 0 or not promoteTimeType then
		return false
	end

	local promoteTime = Sell.GetPromoteDurationMinutes(info, promoteTimeType)
	if promoteTime > (info.leftTime or 0) then
		return false
	end

	if promoteTime < (info.promoteTime or 0) then
		return false
	end

	return info.promoteType == 0 or promoteType > info.promoteType or (promoteType == info.promoteType and promoteTime > (info.promoteTime or 0))
end

function Sell.GetAvailablePromoteDurations(info)
	local durationTypes = {}
	if not info then
		return durationTypes
	end

	if (info.promoteTime or 0) > 0 and (info.promoteTime or 0) <= (info.leftTime or 0) then
		table.insert(durationTypes, 0)
	end

	for durationType = 1, Sell.GetDurationChoiceCount() do
		local duration = Sell.GetDurationMinutes(durationType)
		if duration > (info.promoteTime or 0) and duration <= (info.leftTime or 0) then
			table.insert(durationTypes, durationType)
		end
	end

	return durationTypes
end

function Sell.GetAvailablePromoteTypes(info)
	local promoteTypes = {}
	for promoteType = 1, 3 do
		if Sell.CanPromoteListInfo(info, promoteType) or (info and promoteType == info.promoteType and #Sell.GetAvailablePromoteDurations(info) > 1) then
			table.insert(promoteTypes, promoteType)
		end
	end

	return promoteTypes
end

function Sell.HasAvailablePromoteType(info)
	return #Sell.GetAvailablePromoteTypes(info) > 0
end

function Sell.GetPromoteText(promoteType)
	local promoteIndex = promoteType + 1
	return colorizeText(Sell.PROMOTION_STATUS[promoteIndex], FONT_PROMOTE_TYPE_COLORS[promoteIndex])
end

Sell.StaticPopup = {}

function Sell.GetMoneyTypeFromMode(moneyMode)
	if moneyMode == "account" then
		return 2
	end
	return 1
end

function Sell.GetPromotePrice(info, promoteType, promoteTimeType)
	if not info then
		return 0
	end

	return Auction_PromoteSellPrice(info.realPosition, promoteType or 0, promoteTimeType or 0)
end

function Sell.GetExtendPrice(info, durationType)
	if not info or not durationType then
		return 0
	end

	return Auction_ExtendPrice(info.realPosition, durationType)
end

function Sell.ConfigureSliderDialog(which, minValue, defaultValue, maxValue, description, lowText, highText)
	local dialogInfo = StaticPopupDialogs[which]
	dialogInfo.sliderMinValue = minValue
	dialogInfo.sliderDefaultValue = defaultValue
	dialogInfo.sliderMaxValue = maxValue
	dialogInfo.sliderDescription = description or ""
	dialogInfo.sliderLowText = lowText or ""
	dialogInfo.sliderHighText = highText or ""
end

function Sell.ConfigureSlider2Dialog(which, minValue, defaultValue, maxValue, description, lowText, highText)
	local dialogInfo = StaticPopupDialogs[which]
	dialogInfo.hasSlider2 = 1
	dialogInfo.slider2MinValue = minValue
	dialogInfo.slider2DefaultValue = defaultValue
	dialogInfo.slider2MaxValue = maxValue
	dialogInfo.slider2Description = description or ""
	dialogInfo.slider2LowText = lowText or ""
	dialogInfo.slider2HighText = highText or ""
end

function Sell.SetStaticPopupSliderValue(slider, text)
	local value = _G[slider:GetName() .. "Value"]
	if value then
		value:SetText(text or "")
	end
end

function Sell.UpdateExtendPopup(dialog)
	local state = Sell.StaticPopup or {}
	local durationType = state.DurationTypes and state.DurationTypes[state.DurationTypeIndex]
	state.ShownPrice = Sell.GetExtendPrice(state.Info, durationType)
    MoneyFrame_Update(dialog:GetName() .. "MoneyFrame", state.ShownPrice, "copper")
end

function Sell.UpdatePromotePopup(dialog)
	local state = Sell.StaticPopup or {}
	local promoteType = state.PromoteTypes and state.PromoteTypes[state.PromoteTypeIndex]
	local promoteTimeType = state.PromoteTimeTypes and state.PromoteTimeTypes[state.PromoteTimeTypeIndex]
	state.ShownPrice = Sell.GetPromotePrice(state.Info, promoteType, promoteTimeType)
    MoneyFrame_Update(dialog:GetName() .. "MoneyFrame", state.ShownPrice, "account")

	local button = _G[dialog:GetName() .. "Button1"]
	if not button then
		return
	end

	if Sell.CanPromoteSelection(state.Info, promoteType, promoteTimeType) then
		button:Enable()
	else
		button:Disable()
	end
end

function Sell.HideAuctionStaticPopups()
	StaticPopup_Hide("AAC_EXTEND_SELL_ITEM")
	StaticPopup_Hide("AAC_PROMOTE_SELL_ITEM_TYPE")
end

function Sell.OpenProlongPopup()
    local info = Sell.GetSelectedListInfo()
    if AAC.Market.TransactionPending() or not Sell.OwnOfferLive(info) then return end
	local durationTypes = Sell.GetAvailableExtendDurations(info)
	if #durationTypes == 0 then
		Sell.HideAuctionStaticPopups()
		return
	end

	local selectedDurationType = AAC_SavedSettings.SellDurationSelected or 1
	local selectedDurationTypeIndex = 1
	for index, durationType in ipairs(durationTypes) do
		if durationType == selectedDurationType then
			selectedDurationTypeIndex = index
			break
		end
	end

	Sell.HideAuctionStaticPopups()
	Sell.StaticPopup = {
		Info = info,
		DurationTypes = durationTypes,
		DurationTypeIndex = selectedDurationTypeIndex,
	}

	Sell.ConfigureSliderDialog("AAC_EXTEND_SELL_ITEM", 1, selectedDurationTypeIndex, #durationTypes, AUCTION_DURATION, Sell.GetDurationText(durationTypes[1]), Sell.GetDurationText(durationTypes[#durationTypes]))
	StaticPopup_Show("AAC_EXTEND_SELL_ITEM", info.link or info.name or "")
end

function Sell.OpenPromotePopup()
    local info = Sell.GetSelectedListInfo()
    if AAC.Market.TransactionPending() or not AAC.Market.Feature("Promotion") or not Sell.OwnOfferLive(info) then return end
	local promoteTypes = Sell.GetAvailablePromoteTypes(info)
	local promoteTimeTypes = Sell.GetAvailablePromoteDurations(info)
	if #promoteTypes == 0 or #promoteTimeTypes == 0 then
		Sell.HideAuctionStaticPopups()
		return
	end

	local selectedPromoteType = AAC_SavedSettings.SellPromoteDropDown - 1
	if info.promoteType and info.promoteType > 0 and #promoteTimeTypes > 1 then
		selectedPromoteType = info.promoteType
	end
	local selectedPromoteTypeIndex = 1
	for index, promoteType in ipairs(promoteTypes) do
		if promoteType == selectedPromoteType then
			selectedPromoteTypeIndex = index
			break
		end
	end

	local selectedPromoteTimeType = AAC_SavedSettings.SellPromoteTimeDropDown or 1
	local selectedPromoteTimeTypeIndex = 1
	for index, promoteTimeType in ipairs(promoteTimeTypes) do
		if promoteTimeType == selectedPromoteTimeType then
			selectedPromoteTimeTypeIndex = index
			break
		end
	end

	Sell.HideAuctionStaticPopups()
	Sell.StaticPopup = {
		Info = info,
		PromoteTypes = promoteTypes,
		PromoteTypeIndex = selectedPromoteTypeIndex,
		PromoteTimeTypes = promoteTimeTypes,
		PromoteTimeTypeIndex = selectedPromoteTimeTypeIndex,
	}

	Sell.ConfigureSliderDialog("AAC_PROMOTE_SELL_ITEM_TYPE", 1, selectedPromoteTypeIndex, #promoteTypes, AUCTION_PROMOTETYPES, Sell.GetPromoteText(promoteTypes[1]), Sell.GetPromoteText(promoteTypes[#promoteTypes]))
	Sell.ConfigureSlider2Dialog("AAC_PROMOTE_SELL_ITEM_TYPE", 1, selectedPromoteTimeTypeIndex, #promoteTimeTypes, AUCTION_PROMOTETIME, Sell.GetPromoteDurationText(info, promoteTimeTypes[1]), Sell.GetPromoteDurationText(info, promoteTimeTypes[#promoteTimeTypes]))
	StaticPopup_Show("AAC_PROMOTE_SELL_ITEM_TYPE", info.link or info.name or "", Sell.PROMOTION_STATUS[(info.promoteType or 0) + 1] or "")
end

StaticPopupDialogs["AAC_EXTEND_SELL_ITEM"] = {
	text = AUCTION_PROLONG_SELL .. "\n%s",
	button1 = TEXT("ACCEPT"),
	button2 = TEXT("CANCEL"),
	hasSlider = 1,
	hasMoneyFrame = 1,
	hideOnEscape = 1,
	hasSlider2 = nil,
	OnShow = function(this)
		AAC.Sell.UpdateExtendPopup(this)
	end,
	OnSliderValueChanged = function(this, slider, value)
		local state = AAC.Sell.StaticPopup or {}
		local durationType = state.DurationTypes and state.DurationTypes[value]
		state.DurationTypeIndex = value
		local desc = _G[slider:GetName() .. "Desc"]
		if desc then
			desc:SetText(AUCTION_DURATION)
		end
		AAC.Sell.SetStaticPopupSliderValue(slider, durationType and AAC.Sell.GetDurationText(durationType) or "")
		AAC.Sell.UpdateExtendPopup(this)
	end,
	OnAccept = function(this)
		local state = AAC.Sell.StaticPopup or {}
		local info = state.Info
		local durationType = state.DurationTypes and state.DurationTypes[state.DurationTypeIndex]
        Sell.StaticPopup = {}
        if AAC.Market.TransactionPending() or not Sell.OwnOfferLive(info) or not durationType then return end
        local price = Sell.GetExtendPrice(info, durationType)
        local minutes = Sell.GetDurationMinutes(durationType)
        if price ~= state.ShownPrice or price > GetPlayerMoney("copper") or minutes <= 0
            or info.leftTime + minutes > Sell.GetMaxDurationMinutes() then AAC.Market.Changed(); return end
        local revision = ownRevision
        AAC.Market.Submit("extend", function()
            local _, _, _, _, _, left = GetAuctionSellItemInfo(info.realPosition)
            return ownRevision ~= revision and GetAuctionSellItemLink(info.realPosition) == info.link
                and left and left > info.leftTime
        end, function()
            AuctionExtendSell(info.realPosition, durationType)
        end)
	end,
	OnCancel = function(this)
		AAC.Sell.StaticPopup = {}
	end,
	OnHide = function(this)
		AAC.Sell.StaticPopup = {}
	end,
	timeout = 0,
}

StaticPopupDialogs["AAC_PROMOTE_SELL_ITEM_TYPE"] = {
	text = AUCTION_PROMOTE_SELL .. "\n%s\n" .. AUCTION_PROMOTETYPES .. ": %s",
	button1 = TEXT("ACCEPT"),
	button2 = TEXT("CANCEL"),
	hasSlider = 1,
	hasSlider2 = 1,
	hasMoneyFrame = 1,
	hasMoneyAccount = 1,
	hideOnEscape = 1,
	OnShow = function(this)
		AAC.Sell.UpdatePromotePopup(this)
	end,
	OnSliderValueChanged = function(this, slider, value)
		local state = AAC.Sell.StaticPopup or {}
		local promoteType = state.PromoteTypes and state.PromoteTypes[value]
		state.PromoteTypeIndex = value
		local desc = _G[slider:GetName() .. "Desc"]
		if desc then
			desc:SetText(AUCTION_PROMOTETYPES)
		end
		AAC.Sell.SetStaticPopupSliderValue(slider, promoteType and AAC.Sell.GetPromoteText(promoteType) or "")
		AAC.Sell.UpdatePromotePopup(this)
	end,
	OnSlider2ValueChanged = function(this, slider, value)
		local state = AAC.Sell.StaticPopup or {}
		local promoteTimeType = state.PromoteTimeTypes and state.PromoteTimeTypes[value]
		state.PromoteTimeTypeIndex = value
		local desc = _G[slider:GetName() .. "Desc"]
		if desc then
			desc:SetText(AUCTION_PROMOTETIME)
		end
		AAC.Sell.SetStaticPopupSliderValue(slider, promoteTimeType and AAC.Sell.GetPromoteDurationText(state.Info, promoteTimeType) or "")
		AAC.Sell.UpdatePromotePopup(this)
	end,
	OnAccept = function(this)
		local state = AAC.Sell.StaticPopup or {}
		local info = state.Info
		local promoteType = state.PromoteTypes and state.PromoteTypes[state.PromoteTypeIndex]
		local promoteTimeType = state.PromoteTimeTypes and state.PromoteTimeTypes[state.PromoteTimeTypeIndex]
        Sell.StaticPopup = {}
        if AAC.Market.TransactionPending() or not AAC.Market.Feature("Promotion") or not Sell.OwnOfferLive(info)
            or not promoteType or not Sell.CanPromoteSelection(info, promoteType, promoteTimeType) then return end
        local price = Sell.GetPromotePrice(info, promoteType, promoteTimeType)
        if price ~= state.ShownPrice or price > GetPlayerMoney("account") then AAC.Market.Changed(); return end
        local revision = ownRevision
        AAC.Market.Submit("promote", function()
            local _, _, _, _, _, _, _, _, _, _, currentType, remaining = GetAuctionSellItemInfo(info.realPosition)
            return ownRevision ~= revision and GetAuctionSellItemLink(info.realPosition) == info.link
                and currentType == promoteType and (currentType ~= info.promoteType or remaining > info.promoteTime)
        end, function()
            AuctionPromoteSell(info.realPosition, promoteType, promoteTimeType)
        end)
	end,
	OnCancel = function(this)
		AAC.Sell.StaticPopup = {}
	end,
	OnHide = function(this)
		AAC.Sell.StaticPopup = {}
	end,
	timeout = 0,
}

function Sell.ListProlongButton_OnClick()
	Sell.OpenProlongPopup()
end

function Sell.ListPromoteButton_OnClick()
	Sell.OpenPromotePopup()
end

function Sell.ListCancelButton_OnClick()
    local info = Sell.GetSelectedListInfo()
    if not info or (info.bidder and info.bidder ~= "") then return end
    local description = string.format("%dx %s\n%d %s", info.count, info.link or info.name,
        info.buyoutPrice, currencyName(info.moneyMode))
    AAC.Market.Confirm("AAC_MARKET_CANCEL", description, function()
        if not Sell.OwnOfferLive(info) then AAC.Market.Changed(); return end
        local offer = { link = info.link, count = info.count, mode = info.moneyMode, buyout = info.buyoutPrice }
        local previous = countAuctionOffers(offer)
        local revision = ownRevision
        AAC.Market.Submit("cancel", function()
            return revision ~= ownRevision and countAuctionOffers(offer) < previous
        end, function()
            AuctionCancelSell(info.realPosition)
        end)
    end)
end

function Sell.ListProlongButton_OnEnter(this)
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOM", 0, 0)
	GameTooltip:SetText(AUCTION_PROLONG_SELL, 1, 1, 1)
	GameTooltip:AddLine(AUCTION_DURATION, 0, 0.75, 0.95)
	GameTooltip:Show()
end

function Sell.ListPromoteButton_OnEnter(this)
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOM", 0, 0)
	GameTooltip:SetText(AUCTION_PROMOTE_SELL, 1, 1, 1)

	local info = Sell.GetSelectedListInfo()
	if info and Sell.HasAvailablePromoteType(info) then
		GameTooltip:AddLine(AUCTION_PROMOTETYPES, 0, 0.75, 0.95)
		GameTooltip:AddLine(AUCTION_PROMOTETIME, 0, 0.75, 0.95)
	elseif info then
		GameTooltip:AddLine(Sell.PROMOTION_STATUS_EXPLANATION[info.promoteType + 1] or "", 1, 0.25, 0.25)
	end

	GameTooltip:Show()
end

function Sell.List_SetSelected(auctionid)
	AAC_SellListCancelButton:Disable()
	AAC_SellListProlongButton:Disable()
	AAC_SellListPromoteButton:Disable()
	AAC_AuctionSellList.selected = auctionid

	local button, info;
	if AAC_SellEditBox:GetText() == "" then
		for i = 1, Sell.MAXITEMS do
			button = getglobal("AAC_SellListItem"..i)
			info = AAC_AuctionSellList.list[button.index]
			if info and button.index == auctionid then
                AAC_SellListCancelButton:SetEnable(not info.bidder or info.bidder == "")
				if Sell.HasAvailableExtendDuration(info) then
					AAC_SellListProlongButton:Enable()
				end
				if AAC.Market.Feature("Promotion") and Sell.HasAvailablePromoteType(info) then
					AAC_SellListPromoteButton:Enable()
				end
				button:LockHighlight()
			else
				button:UnlockHighlight()
			end
		end
	else
		for i = 1, Sell.MAXITEMS do
			button = getglobal("AAC_SellListItem"..i)
			info = NEW_AUCTION_IDS[button.index]
			if info and button.index == auctionid then
                AAC_SellListCancelButton:SetEnable(not info.bidder or info.bidder == "")
				if Sell.HasAvailableExtendDuration(info) then
					AAC_SellListProlongButton:Enable()
				end
				if AAC.Market.Feature("Promotion") and Sell.HasAvailablePromoteType(info) then
					AAC_SellListPromoteButton:Enable()
				end
				button:LockHighlight()
			else
				button:UnlockHighlight()
			end
		end
	end
end

function Sell.DurationDropDown_Show()
	local info
	for _,v in ipairs(Sell.DURATION_TIMES) do
		info = {}
		info.text = v
		info.func = function(button)
			AAC.Tools.SetDropDown(AAC_SellDurationDropDown, button:GetID(), button:GetText())
			AAC_SavedSettings.SellDurationSelected = button:GetID()
			Sell.FeeFrame_Update()
			if AAC_SavedSettings.SellDurationSelected < AAC_SavedSettings.SellPromoteTimeDropDown then
				AAC.Tools.SetDropDown(AAC_SellPromoteTimeDropDown, AAC_SavedSettings.SellDurationSelected, v)
				AAC_SavedSettings.SellPromoteTimeDropDown = AAC_SavedSettings.SellDurationSelected
				Sell.PromotePriceFrame_Update()
			end
			Sell.TestIsAuctionValid()
		end
		UIDropDownMenu_AddButton(info)
	end

	local prestigeAddDay = Sell.PrestigeExtraDays(); 
	if prestigeAddDay > 0 then
		local prestigeDays = 7 + prestigeAddDay;
		info = {}
		info.text = string.format(TEXT("PRESTIGE_BENEFIT_AUCTION_DAY"), prestigeDays);
		info.func = function(button)
			AAC.Tools.SetDropDown(AAC_SellDurationDropDown, button:GetID(), button:GetText())
			AAC_SavedSettings.SellDurationSelected = button:GetID()
			Sell.FeeFrame_Update()
			if AAC_SavedSettings.SellDurationSelected < AAC_SavedSettings.SellPromoteTimeDropDown then
				AAC.Tools.SetDropDown(AAC_SellPromoteTimeDropDown, AAC_SavedSettings.SellDurationSelected, info.text)
				AAC_SavedSettings.SellPromoteTimeDropDown = AAC_SavedSettings.SellDurationSelected
				Sell.PromotePriceFrame_Update()
			end
			Sell.TestIsAuctionValid()
		end
		UIDropDownMenu_AddButton(info)
	end
end

function Sell.UpdateLastPrice(itemid, bid, buyout)
	if not AAC_LastSellPrice[itemid] then
		AAC_LastSellPrice[itemid] = {}
	end
	AAC_LastSellPrice[itemid].bid = bid
	AAC_LastSellPrice[itemid].buyout = buyout
end

function Sell.AutoFillPriceFields(automatic)
    if AAC.SellerTools then
        if automatic and AAC.SellerTools.RepeatProtects(GetAuctionItemLink()) then return end
        if not automatic then AAC.SellerTools.repeatAppliedLink=nil end
    end
	local linkid = AAC.Tools.ParseLink(AAC.HookItemLink)
	local linkname
	if linkid then
		_,_,linkname = ParseHyperlink(AAC.HookItemLink)
	end
    local name, _, _, _, moneyMode = Sell.GetAuctionItem()
	linkname = linkname and linkname:gsub(" ?%+%d+","") or nil
	if moneyMode=="copper" then
		linkid = 200000
		linkname = name
	elseif moneyMode=="account" then
        linkid = 200003
        linkname = name
    end

	if not name or name == "" or linkname ~= name then
		AAC_SellHistoryButton:Disable()
		return
	end
	AAC_SellHistoryButton:Enable()

    local white = AAC.Tools.GetWhiteValue(linkid)

   -- local ppu = Sell.AutoCalcPPU("bid", UIDropDownMenu_GetSelectedID(AAC_SellAutoFillBidDropDown), linkid, white,  AAC_SellAutoFillPercentBid:GetText(), AAC_SellAutoFillFormulaBid:GetText() )
    --AAC.MoneyFrame.SetMoney(AAC_SellPriceBidPPU, ppu)

    local ppu = Sell.AutoCalcPPU("buyout", UIDropDownMenu_GetSelectedID(AAC_SellAutoFillBuyoutDropDown), linkid, white,  AAC_SellAutoFillPercentBuyout:GetText(), AAC_SellAutoFillFormulaBuyoutout:GetText() )
    AAC.MoneyFrame.SetMoney(AAC_SellPriceBuyoutPPU, ppu)
end

function Sell.AutoCalcPPU(field, method, linkid, white, percent, formula)

    -- none
    if method ==1 then
        return nil
    -- last
    elseif method ==2 then
        if AAC_LastSellPrice[linkid] and AAC_LastSellPrice[linkid][field] then
			return AAC_LastSellPrice[linkid][field] / white
        elseif AAC_SavedSettings.AvgSuggest then
            avg = AAC.History.GetAveragePrice(linkid)
    		if avg then
	    		return (avg / white)
		    end
        end
    -- percent
    elseif method ==3 then
		if tonumber(percent)==nil then
			percent = 100
		end
		percent=percent/100
        local avg = AAC.History.GetAveragePrice(linkid)
		if avg then
			return (avg / white) * percent
		end
    --formula
	elseif method == 4 then
    	formula = string.lower(formula)
	    AAC_SavedSettings.FormulaBuyout = formula
        local avg,min,max,median = AAC.History.GetPriceStatistic(linkid)
        if avg then
			formula = string.gsub(formula, "avg", avg / white)
			formula = string.gsub(formula, "min", min / white)
			formula = string.gsub(formula, "max", max / white)
			formula = string.gsub(formula, "median", median / white)
		end
		local value = tonumber(AAC.Tools.EvaluateString(formula))
		if value then
			return value
		end
    end
end

function Sell.UpdateProfit()
    if Sell.MoneyAuction then
	    --MoneyFrame_Update("AAC_SellProfitBuyoutFrame",0)
    else
       -- local money= math.max(AAC.MoneyFrame.GetMoney(AAC_SellPriceBuyout),AAC.MoneyFrame.GetMoney(AAC_SellPriceBid))
       -- local tax = math.floor(money*0.06)+1
	   -- MoneyFrame_Update("AAC_SellProfitBuyoutFrame", tax)
	   Sell.FeeFrame_Update()
    end
end

function Sell.OnOfferChange(this)
    Sell.PriceInput_OnTextChange(AAC_SellPriceBidPPU, AAC_SellPriceBid, true)
    Sell.PriceInput_OnTextChange(AAC_SellPriceBuyoutPPU, AAC_SellPriceBuyout, true)
    Sell.TestIsAuctionValid()
end

function Sell.OnOfferChange1(this)
    Sell.PriceInput_OnTextChange(AAC_SellPriceBidPPU, AAC_SellPriceBid, false)
    Sell.TestIsAuctionValid()
end

function Sell.OnOfferChange2(this)
    Sell.PriceInput_OnTextChange(AAC_SellPriceBidPPU, AAC_SellPriceBid, true)
    Sell.TestIsAuctionValid()
end

function Sell.OnOfferChange3(this)
    Sell.PriceInput_OnTextChange(AAC_SellPriceBuyoutPPU, AAC_SellPriceBuyout, false)
    Sell.TestIsAuctionValid()
end

function Sell.OnOfferChange4(this)
    Sell.PriceInput_OnTextChange(AAC_SellPriceBuyoutPPU, AAC_SellPriceBuyout, true)
    Sell.TestIsAuctionValid()
end

function Sell.PriceInput_OnTextChange(money_ppu, money_total, ppuToFull)
    if Sell.internal_money_update then
        return
    end

    -- Don't derive the paired price from a malformed number (e.g. wrong decimal separator).
    if not AAC.MoneyFrame.IsValueValid(ppuToFull and money_ppu or money_total) then
        return
    end

    local _, _, stackCount = Sell.GetAuctionItem()
	local white = AAC.Tools.GetWhiteValue(Sell.CurrentItem)
	if not stackCount or stackCount < 1 then
		stackCount = 1
	end

    local inverse
    if Sell.MoneyAuction and Sell.PayMoneyMode == "account" then
        inverse = true
    end

    Sell.internal_money_update = true
	if ppuToFull then
        local ppu = AAC.MoneyFrame.GetMoney(money_ppu)
        if inverse and ppu~=0 then ppu=1/ppu end
        AAC.MoneyFrame.SetMoney(money_total, math.ceil(ppu * stackCount * white))
	else
        local total = AAC.MoneyFrame.GetMoney(money_total)
        local ppu = total / (stackCount * white)
        if inverse and ppu~=0 then ppu=1/ppu end

        AAC.MoneyFrame.SetMoney(money_ppu, ppu)
	end

    Sell.UpdateProfit()
    Sell.internal_money_update = nil
end

function Sell.HistoryEditbox_OnEditFocusGain(this)
	AAC_HistoryItemList:ClearAllAnchors();

	AAC_HistoryItemList:SetAnchor("BOTTOM", "TOP", this, 0, 0);
	AAC_HistoryItemList:Show();
	
	_G["AAC_HistoryItemListItem1"]:Show()
	_G["AAC_HistoryItemListItem1_Icon"]:SetFile( "" )
	_G["AAC_HistoryItemListItem1Name"]:SetText( TEXT( "AAH_LOADING" ) )
	_G["AAC_HistoryItemListItem1Name"]:SetColor( 1, 1, 1 )
	
	--UIParent:SetAlpha( 0.7 )
	
	for i = 2, AAC_HISTORY_MAX_ITEM_COUNT do
		_G["AAC_HistoryItemListItem" .. i]:Hide()
	end
	Sell.HistoryItemUpdater()
end

function Sell.HistoryItemUpdater( noScroll ) 
	TimerQueue["AAC_Sell_HistoryEditbox_OnTextChanged"] = { GetTime() + 0.2, 
		function()
			Sell.HistoryEditbox_OnTextChanged( noScroll )
			--UIParent:SetAlpha( 1 )
		end
	}
end

AAC_HISTORY_MAX_ITEM_COUNT = 8

function Sell.HistoryEditbox_OnTextChanged( noScroll, ItemID )
	if ItemID and not string.match((TEXT( "Sys" .. ItemID .. "_name" )), "^Sys%d+_name$") then
		Sell.HistoryList = { ItemID }
		AAC_HistoryItemList_ScrollBar:SetValue( 0 )
	elseif not noScroll then
		AAC_HistoryItemList_ScrollBar:SetValue( 0 )
		Sell.HistoryList = Sell.History_GetFilteredItemList( AAC_HistoryEditBox:GetText() )
		AAC_HistoryItemList_ScrollBar.ItemList = Sell.HistoryList
	else
		Sell.HistoryList = AAC_HistoryItemList_ScrollBar.ItemList or Sell.History_GetFilteredItemList( AAC_HistoryEditBox:GetText() )
	end
	local ItemCount = #Sell.HistoryList
	local Index = AAC_HistoryItemList.index;
	local SliderIndex;
		
	if ( ( AAC_HISTORY_MAX_ITEM_COUNT ) < ItemCount) then
		AAC_HistoryItemList_ScrollBar:SetMaxValue( ItemCount - AAC_HISTORY_MAX_ITEM_COUNT )
		AAC_HistoryItemList_ScrollBar:Show()
	else
		AAC_HistoryItemList_ScrollBar:SetMaxValue( ItemCount )
		AAC_HistoryItemList_ScrollBar:Hide()
	end
	
	for  i = 1, AAC_HISTORY_MAX_ITEM_COUNT do	
		local Item = _G["AAC_HistoryItemListItem" .. i]
		local ItemHL = _G["AAC_HistoryItemListItem" .. i .. "_Select"]
		ItemHL:Hide()
		Item:Hide();
	end
	
	AAC_HistoryEditBox.ID = nil
	AAC_HistoryItemListHistoryCheckButton:Disable()
	if ItemCount == 1 then
		AAC_HistoryEditBox.ID = Sell.HistoryList[1]
		AAC_HistoryItemListHistoryCheckButton:Enable()
	end
		   
	for i = 1, AAC_HISTORY_MAX_ITEM_COUNT do
		SliderIndex = Index + i	
		local ItemID = Sell.HistoryList[SliderIndex]
		if ItemID then
			local Item = _G["AAC_HistoryItemListItem" .. i]
			local Name = _G[Item:GetName() .. "Name"]
			local Icon = _G[Item:GetName() .. "_Icon"]
			Name:SetColor( GetItemQualityColor( GetQualityByGUID( ItemID ) ) )			
			Name:SetText( TEXT( "Sys" .. ItemID .. "_name" ) )
			Icon:SetFile( GetObjectInfo( GetObjectInfo( ItemID, "ImageID" ), "ActField" ) or "" )
			Item.ID = ItemID
			Item:Show();
		end
	end
	
end

function Sell.SortFilteredList(matches)
	local sortMode = AAC_SELL_SORT_MODE;
	local matches = matches

	if math.abs( sortMode ) == 6 then
		if Sell.SortMode == 0 then
			table.sort( matches, function(a, b)
				return a.bidPrice < b.bidPrice
			end)
		elseif Sell.SortMode == 1 then
			table.sort( matches, function(a, b)
				return a.bidPrice > b.bidPrice
			end)
		elseif Sell.SortMode == 2 then
			table.sort( matches, function(a, b)
				return a.buyoutPrice < b.buyoutPrice
			end)
		elseif Sell.SortMode == 3 then
			table.sort( matches, function(a, b)
				return a.buyoutPrice > b.buyoutPrice
			end)
		end
	else
		if sortMode == 1 or sortMode == -1 then
			table.sort(matches, function(a, b)
				return sortMode == 1 and a.name < b.name or sortMode == -1 and a.name > b.name
			end)
		elseif sortMode == 2 or sortMode == -2 then
			table.sort(matches, function(a, b)
				return sortMode == 2 and a.level < b.level or sortMode == -2 and a.level > b.level
			end)
			elseif sortMode == 3 or sortMode == -3 then
				table.sort(matches, function(a, b)
					return sortMode == 3 and a.leftTime < b.leftTime or sortMode == -3 and a.leftTime > b.leftTime
				end)
		elseif sortMode == 6 or sortMode == -6 then
			table.sort(matches, function(a, b)
				return sortMode == 6 and a.bidPrice < b.bidPrice or sortMode == -6 and a.bidPrice > b.bidPrice
			end)
		end
	end
end

function Sell.MyOffers_OnTextChanged( text )
	local button, buttonName, itemBG;
	local info;
	local r, g, b;
	local matches = {};
	local sortedList = AAC_AuctionSellList.list;
	NEW_AUCTION_IDS = {};
	local hasFilter = text ~= "";

	for i = 1, Sell.MAXITEMS do 
		button = _G["AAC_SellListItem" .. i]
		button:Hide()
		AAC_SellListScrollBar:SetValue(0)
	end

	if hasFilter then
		Sell.SortFilteredList( sortedList );
	end

	for i = 1, AAC_AuctionSellList.maxNums do
		local info = hasFilter and sortedList[i] or AAC_AuctionSellList.list[i];
		if info ~= nil then
			if string.find(string.lower(info.name), string.lower(text), 1, true) then
				table.insert(matches, i)
			end
		end
	end

	for i = 1, Sell.MAXITEMS do

		button = _G["AAC_SellListItem" .. i]
		buttonName = button:GetName()
		itemBG = _G[buttonName.."Highlight"]

		local info = AAC_AuctionSellList.list[matches[i]];

		if info then

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

			button.index = i
			button.auctionid = info.auctionid
			NEW_AUCTION_IDS[button.index] = info

			if info.promoteType ~= 0 then
				itemBG:Show()
				itemBG:SetColor(AAC_PROMOTE_TYPE_COLORS_MAIN[info.promoteType].R, 
								AAC_PROMOTE_TYPE_COLORS_MAIN[info.promoteType].G, 
								AAC_PROMOTE_TYPE_COLORS_MAIN[info.promoteType].B)
			else
				itemBG:Hide()
			end

			r, g, b = GetItemQualityColor(GetQualityByGUID(info.itemid))
			local color = "|cff"..string.format("%02x",r*255)..string.format("%02x",g*255)..string.format("%02x",b*255)

			_G[buttonName.."Name"]:SetText(info.stat and color..info.name.."|r\n"..info.stat or color..info.name.."|r")
			_G[buttonName.."Level"]:SetText(AAC.Tools.getLevelColor(info.level)..info.level.."|r")
			_G[buttonName.."LeftTime"]:SetText(SecondsToTime(info.leftTime * 60))

			if (info.promoteTime ~= 0) then
				_G[buttonName.."PromotionLeftTime"]:SetText(SecondsToTime(info.promoteTime * 60))
			else
				_G[buttonName.."PromotionLeftTime"]:SetText("-")
			end

			SetItemButtonCount(_G[buttonName.."Icon"], info.count)
			SetItemButtonTexture(_G[buttonName.."Icon"], info.texture)
			MoneyFrame_Update(buttonName.."BidMoney", info.bidPrice, info.moneyMode or "copper")

			if info.buyoutPrice > 0 then
				MoneyFrame_Update(buttonName.."BuyoutMoney", info.buyoutPrice, info.moneyMode or "copper")
				_G[buttonName.."BuyoutMoney"]:Show()
			else
				_G[buttonName.."BuyoutMoney"]:Hide()
			end

			button:Show()
		else
			button.auctionid = nil
			button:Hide()
		end

	end

	local maxValue = #matches - Sell.MAXITEMS
	if maxValue > 0 then
		AAC_SellListScrollBar:SetMinMaxValues(0, maxValue)
	else
		AAC_SellListScrollBar:SetMinMaxValues(0, 0)
	end

	if text == "" then 
		Sell.List_Update()
		AAC_SellListScrollBar:SetValue(0) 
	else
		Sell.RefreshSellList()
	end

end

function Sell.RefreshSellList()
	local index = AAC_SellListScrollBar:GetValue() + 1;
	local button, buttonName, itemBG;
	local info;
	local r, g, b;
	local matches = {};
	NEW_AUCTION_IDS = {};
	local hasFilter = AAC_SellEditBox:GetText() ~= "";

	for i = 1, AAC_AuctionSellList.maxNums do
		local info = AAC_AuctionSellList.list[i];
		if string.find(string.lower(info.name), string.lower(AAC_SellEditBox:GetText()), 1, true) then
			table.insert(matches, info)
		end
	end

	if hasFilter and #matches > 0 then
		Sell.SortFilteredList( matches );
	end

	for i = 1, Sell.MAXITEMS do

		button = _G["AAC_SellListItem" .. i]
		buttonName = button:GetName()
		itemBG = _G[buttonName.."Highlight"]

		local info = matches[index];

		if info then

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

			button.index = not hasFilter and index or info.realPosition;
			button.auctionid = info.auctionid
			NEW_AUCTION_IDS[button.index] = info;

			if info.promoteType ~= 0 then
				itemBG:Show()
				itemBG:SetColor(AAC_PROMOTE_TYPE_COLORS_MAIN[info.promoteType].R, 
								AAC_PROMOTE_TYPE_COLORS_MAIN[info.promoteType].G, 
								AAC_PROMOTE_TYPE_COLORS_MAIN[info.promoteType].B)
			else
				itemBG:Hide()
			end

			r, g, b = GetItemQualityColor(GetQualityByGUID(info.itemid))
			local color = "|cff"..string.format("%02x",r*255)..string.format("%02x",g*255)..string.format("%02x",b*255)

			_G[buttonName.."Name"]:SetText(info.stat and color..info.name.."|r\n"..info.stat or color..info.name.."|r")
			_G[buttonName.."Level"]:SetText(AAC.Tools.getLevelColor(info.level)..info.level.."|r")
			_G[buttonName.."LeftTime"]:SetText(SecondsToTime(info.leftTime * 60))

			if (info.promoteTime ~= 0) then
				_G[buttonName.."PromotionLeftTime"]:SetText(SecondsToTime(info.promoteTime * 60))
			else
				_G[buttonName.."PromotionLeftTime"]:SetText("-")
			end

			SetItemButtonCount(_G[buttonName.."Icon"], info.count)
			SetItemButtonTexture(_G[buttonName.."Icon"], info.texture)
			MoneyFrame_Update(buttonName.."BidMoney", info.bidPrice, info.moneyMode or "copper")

			if info.buyoutPrice > 0 then
				MoneyFrame_Update(buttonName.."BuyoutMoney", info.buyoutPrice, info.moneyMode or "copper")
				_G[buttonName.."BuyoutMoney"]:Show()
			else
				_G[buttonName.."BuyoutMoney"]:Hide()
			end

			button:Show()
		else
			button.auctionid = nil
			button:Hide()
		end

		index = index + 1
		
	end

	local maxValue = #matches - Sell.MAXITEMS
	if maxValue > 0 then
		AAC_SellListScrollBar:SetMinMaxValues(0, maxValue)
	else
		AAC_SellListScrollBar:SetMinMaxValues(0, 0)
	end
	Sell.List_SetSelected(AAC_AuctionSellList.selected)
	AAC_SellNumberLabel:SetText(AAC_SELL_NUM_AUCTION)
	AAC_SellNumber:SetText(GetAuctionNumSellItems() .. "/" .. (100 + Prestige_GetChargeCount(PrestigeBenefitType_AuctionHouse_Slots)))
end

function Sell.GenerateSellableItemIDs()
	local ItemList = {}
	
	for _, Range in pairs( {
		{ 200000, 250000 },
		{ 770000, 780000 },
		{ 510000, 519999 },
		{ 520000, 530000 },
		{ 550000, 560000 },
		{ 1200000, 1300000 },
	} ) do
		for ID = Range[1], Range[2] do
			local GUID = GetObjectInfo( ID, "GUID" )
			
			if GUID then
				if IsCard( GUID ) or IsAttribute( GUID ) or Sell.IsSellable( GUID ) then
					table.insert( ItemList, GUID )
				end
			end
		end
	end
	
	return ItemList
end

function Sell.ShowInvalidAuctionItemWarning()
	SendWarningMsg(INVALID_AUCTION_ITEM_WARNING)
end

function Sell.CanAuctionItemLink(link)
	local itemID = GetItemIdFromLink(link)
	if not itemID then return nil end

	local GUID = GetObjectInfo(itemID, "GUID")
	if not GUID then return false end

	return IsCard(GUID) or IsAttribute(GUID) or Sell.IsSellable(GUID)
end

function Sell.CanAuctionBagItem(index)
	if not index then return nil end
	return Sell.CanAuctionItemLink(GetBagItemLink(index))
end

function Sell.TryPlaceCursorItem()
    if not AAC.CanRequest() or AAC.Market.TransactionPending() then return false end
	if GetCursorItemType() == "bag" and GetCursorItemInfo() then
		local isAuctionable = Sell.CanAuctionItemLink(GetCursorItemLink())
		if isAuctionable == false then
			Sell.ShowInvalidAuctionItemWarning()
			return false
		end
	end

	ClickAuctionItemButton()
	return true
end

function Sell.History_GetFilteredItemList( Filter )
	Sell.ItemList = Sell.ItemList or Sell.GenerateSellableItemIDs()
	local ItemList = {}
	for _, ItemID in pairs( Sell.ItemList ) do
		if not Filter or EscapeRegex( TEXT( "Sys" .. tostring( ItemID ) .. "_name" ) ):lower():find( EscapeRegex( Filter ):lower() ) or tostring( ItemID ):find( tostring( tonumber( Filter ) ) ) then
			if not string.match((TEXT( "Sys" .. ItemID .. "_name" )), "^Sys%d+_name$") then
				table.insert(ItemList, ItemID)
			end
		end
	end

	return ItemList
end

function Sell.LoadQueue()

end

function Sell.HistoryEditbox_TabCheck( this )
	local ItemList = Sell.HistoryList or {}
		
	if not this.TabQueue then
		this.TabQueue = 1
	else
		local MaxValue = math.min( AAC_HISTORY_MAX_ITEM_COUNT, #ItemList )
		if this.TabQueue < MaxValue then
			this.TabQueue = this.TabQueue + 1
		elseif AAC_HistoryItemList.index < AAC_HistoryItemList_ScrollBar:GetMaxValue() then
			AAC_HistoryItemList_ScrollBar:SetValue( AAC_HistoryItemList_ScrollBar:GetValue() + 1 )
		else
			this.TabQueue = 1
			AAC_HistoryItemList_ScrollBar:SetValue( 0 )
		end
	end
	
	local QueuedItemHL = getglobal( "AAC_HistoryItemListItem" .. this.TabQueue .. "_Select" )
	QueuedItemHL:Show()
	for  i = 1, AAC_HISTORY_MAX_ITEM_COUNT do			
		local ItemHL = getglobal( "AAC_HistoryItemListItem" .. i .. "_Select" )
		if ItemHL ~= QueuedItemHL then
			ItemHL:Hide()
		end
	end
end

function Sell.HistoryEditbox_Complete( this )
	if this.TabQueue then
		local Name = _G["AAC_HistoryItemListItem" .. this.TabQueue .. "Name"]:GetText()
		
		if Name ~= "" then
			if AAC_HistoryEditBox:GetText() == Name then
				Sell.HistoryEditbox_OnTextChanged()
			else
				AAC_HistoryEditBox:SetText( Name )
				Sell.HistoryEditbox_OnTextChanged()
			end
		else
			Sell.HistoryEditbox_OnTextChanged()
		end
	else
		Sell.HistoryEditbox_OnTextChanged()
	end
end

function Sell.HistoryItem_OnClick(this)
	local pern = AAC_HistoryItemList.pern
	local ID = this:GetID();
	local Item = _G["AAC_HistoryItemListItem" .. pern]
		
	local PreviousSelection = _G[Item:GetName() .. "_Select"]
	PreviousSelection:Hide();
	
	local CurrentSelection= _G[this:GetName() .. "_Select"]
	CurrentSelection:Show()
	
	local Name = _G[this:GetName() .. "Name"]
	--AAC_HistoryEditBox.noChange = true
	--AAC_HistoryEditBox:SetText( Name:GetText())
	--AAC_HistoryEditBox.noChange = nil
	AAC_HistoryEditBox.ID = this.ID
	AAC_HistoryEditBox.TabQueue = ID
	
	AAC_HistoryItemList.pern = ID

	local SearchID = this.ID;
	local Inherent = 0;
	if ( IsAttribute( SearchID ) ) then
		Inherent = AAC_HistoryEditBox.ID;
		SearchID = -1;
	end

	AAC.Sell.RequestHistory( SearchID, Inherent, false )
end

function Sell.HistoryItem_OnEnter( this )
	if this.ID then
		GameTooltip:SetHyperLink( CreateHyperlink( "item", ( "%x" ):format( this.ID ), TEXT( "Sys" .. this.ID .. "_name" ) ) )
		GameTooltip:SetOwner( this, "ANCHOR_LEFT", -10, 0 )
		FixOutOfScreenAndGapClose()
	end
end

function Sell.HistoryItem_OnMouseWheel(this, delta)
	local ScrollBar = AAC_HistoryItemList_ScrollBar
	local NewValue = ScrollBar:GetValue() - ( delta / 120 )
	if NewValue <= ScrollBar:GetMaxValue() and AAC_HISTORY_MAX_ITEM_COUNT >= ScrollBar:GetMinValue() then
		ScrollBar:SetValue( ScrollBar:GetValue() - ( delta / 120 ) )
	end
end

function Sell.HistoryItem_OnChange(this,arg1)
	AAC_HistoryItemList.index = AAC_HistoryItemList_ScrollBar:GetValue()
	Sell.HistoryEditbox_OnTextChanged( true )
end

function Sell.IsSellable( GUID )
	local ItemMode, ArmorType, WeaponType = GetObjectInfo( GUID, "Mode", "ArmorType", "WeaponType" )
	if not ItemMode then return false end
	
	local Array = {}
	while ItemMode > 0 do
		local RestBit = math.fmod( ItemMode, 2 )
		table.insert( Array, RestBit )
		ItemMode = ( ItemMode - RestBit ) / 2
	end

	local Bits = table.concat( Array )
	local RequiredBinariesForSale = {
		[9] = false, -- PickupBound
		[11] = false, -- LogoutDel
		[17] = false, -- ChangeZoneDel
	}
	
	if ArmorType or WeaponType then
		RequiredBinariesForSale = {
			[11] = false, -- LogoutDel
			[17] = false, -- ChangeZoneDel
			[31] = false, -- DisableUnbind
		}
	end
	
	for RequestedBit, Result in pairs( RequiredBinariesForSale ) do
		local TargetBinary = Bits:sub( RequestedBit, RequestedBit )
		TargetBinary = TargetBinary == "" and "0" or TargetBinary
		if Result == true and RequestedBit > Bits:len() then return false end
		if TargetBinary ~= ( Result and "1" or "0" ) then
			return false
		end
	end
	
	return true
end

function Sell.HistoryFrame_OnLoad(this)	
	AAC_HistoryItemList.pern = 1
	AAC_HistoryItemList.index = 0
	AAC_HistoryItemList_ScrollBar:SetMinValue( 0 )
end

function Sell.BuyoutMoney_OnEnter(this)
	local itemNumberName = this:GetName()
	local itemNumber = string.match(itemNumberName, "%d+")
	local button = getglobal("AAC_SellListItem"..itemNumber)
	if AAC_AuctionSellList.selected ~= button.index then
		button:LockHighlight()
	end
end

function Sell.BuyoutMoney_OnLeave(this)
	local itemNumberName = this:GetName()
	local itemNumber = string.match(itemNumberName, "%d+")
	local button = getglobal("AAC_SellListItem"..itemNumber)
	if AAC_AuctionSellList.selected ~= button.index then
		button:UnlockHighlight()
	end
end


function Sell.SellPromoteDropDown_Show()
	local buttonInfo
	for i = 1, 4 do
		buttonInfo = {}
		buttonInfo.text = colorizeText(Sell.PROMOTION_STATUS[i], FONT_PROMOTE_TYPE_COLORS[i]);

		if Prestige_GetChargeCount(PrestigeBenefitType_AuctionHouse_Auctioneer) > 0 and i == 4 then
			local benefitBonus = Prestige_GetChargeCount(PrestigeBenefitType_AuctionHouse_Auctioneer);
			buttonInfo.text = colorizeText(buttonInfo.text .. " (" .. TEXT("WEEKINSTANCE_FREE") .. " " .. benefitBonus .. ")", FONT_PROMOTE_TYPE_COLORS[i]);
		end

		buttonInfo.tooltipText = Sell.PROMOTION_STATUS_EXPLANATION[i]
		buttonInfo.func = function(button)
			AAC.Tools.SetDropDown(AAC_SellPromoteDropDown, button:GetID(), button:GetText())
			AAC_SavedSettings.SellPromoteDropDown = button:GetID()
			if button:GetID() == 1 then
				_G["AAC_SellPromoteTimeDropDown"]:Hide()
				_G["AAC_SellPromoteTimeDropDownTooltip"]:Hide()
				_G["AAC_PromotePriceFrame"]:Hide()
				_G["AAC_SellPromoteDropDown"]:ClearAllAnchors()
				_G["AAC_SellPromoteDropDown"]:SetAnchor("TOPLEFT", "TOPLEFT", "$parent", 502, 110)
			else
				_G["AAC_SellPromoteTimeDropDown"]:ClearAllAnchors()
				_G["AAC_SellPromoteDropDown"]:ClearAllAnchors()
				_G["AAC_PromotePriceFrame"]:ClearAllAnchors()
				_G["AAC_SellPromoteDropDown"]:SetAnchor("TOPLEFT", "TOPLEFT", "$parent", 502, 110)
				_G["AAC_SellPromoteTimeDropDown"]:SetAnchor("TOPLEFT", "BOTTOMLEFT", "AAC_SellPromoteDropDown", 0, 5)
				_G["AAC_PromotePriceFrame"]:SetAnchor("TOP", "BOTTOM", "AAC_SellPromoteTimeDropDown", 20, 3)
				_G["AAC_SellPromoteTimeDropDown"]:Show()
				_G["AAC_SellPromoteTimeDropDownTooltip"]:Show()
				_G["AAC_PromotePriceFrame"]:Show()

				if Prestige_GetChargeCount(PrestigeBenefitType_AuctionHouse_Auctioneer) > 0 and AAC_SavedSettings.SellPromoteDropDown == 4 then
					local benefitBonus = Prestige_GetChargeCount(PrestigeBenefitType_AuctionHouse_Auctioneer);
					if AAC_SavedSettings.SellPromoteTimeDropDown <= 4 then
						local text = Sell.DURATION_TIMES[AAC_SavedSettings.SellPromoteTimeDropDown] or GetPrestigeExtraDays();
						text = text .. " (" .. TEXT("WEEKINSTANCE_FREE") .. " " .. benefitBonus .. ")";
						AAC.Tools.SetDropDown(AAC_SellPromoteTimeDropDown, AAC_SavedSettings.SellPromoteTimeDropDown, text)
					end
				else
					local text = Sell.DURATION_TIMES[AAC_SavedSettings.SellPromoteTimeDropDown] or GetPrestigeExtraDays();
					AAC.Tools.SetDropDown(AAC_SellPromoteTimeDropDown, AAC_SavedSettings.SellPromoteTimeDropDown, text)		
				end				
			end
			Sell.PromotePriceFrame_Update()
			Sell.ShowPromoBG()
			Sell.TestIsAuctionValid();
		end
		UIDropDownMenu_AddButton(buttonInfo)
	end
end

function Sell.SellPromoteTimeDropDown_Show()
	local buttonInfo
	for i = 1, 4 do
		buttonInfo = {}
		buttonInfo.text = Sell.DURATION_TIMES[i]

		if AAC_SavedSettings ~= nil then
			if AAC_SavedSettings.SellDurationSelected < i then buttonInfo.disabled = true end

			if Prestige_GetChargeCount(PrestigeBenefitType_AuctionHouse_Auctioneer) > 0 and AAC_SavedSettings.SellPromoteDropDown == 4 then
				local benefitBonus = Prestige_GetChargeCount(PrestigeBenefitType_AuctionHouse_Auctioneer);
				buttonInfo.text = buttonInfo.text .. " (" .. TEXT("WEEKINSTANCE_FREE") .. " " .. benefitBonus .. ")";
			end
		end
		buttonInfo.func = function(button)
			if AAC_SavedSettings.SellDurationSelected >= button:GetID() then
				AAC.Tools.SetDropDown(AAC_SellPromoteTimeDropDown, button:GetID(), button:GetText())
				AAC_SavedSettings.SellPromoteTimeDropDown = button:GetID()
				Sell.PromotePriceFrame_Update()
			end
			Sell.TestIsAuctionValid();
		end
		UIDropDownMenu_AddButton(buttonInfo)
	end

	local prestigeAddDay = Sell.PrestigeExtraDays()
	if prestigeAddDay > 0 then
		local prestigeDays = 7 + prestigeAddDay
		buttonInfo = {}
		buttonInfo.text = string.format(TEXT("PRESTIGE_BENEFIT_AUCTION_DAY"), prestigeDays);
		if AAC_SavedSettings ~= nil then
			if AAC_SavedSettings.SellDurationSelected < 5 then buttonInfo.disabled = true end
		end
		buttonInfo.func = function(button)
			if AAC_SavedSettings.SellDurationSelected >= button:GetID() then
				AAC.Tools.SetDropDown(AAC_SellPromoteTimeDropDown, button:GetID(), button:GetText())
				AAC_SavedSettings.SellPromoteTimeDropDown = button:GetID()
				Sell.PromotePriceFrame_Update()
			end
			Sell.TestIsAuctionValid();
		end
		UIDropDownMenu_AddButton(buttonInfo)
	end
end

function Sell.PromotePriceFrame_Update()
	local promoteType = AAC_SavedSettings.SellPromoteDropDown - 1
	local promoteTime = 0
	if promoteType ~= 0 then
		promoteTime = AAC_SavedSettings.SellPromoteTimeDropDown
	end
	MoneyFrame_Update("AAC_PromotePriceFrame", Auction_PromotePrice(AAC.MoneyFrame.GetMoney(AAC_SellPriceBuyout, Sell.PayMoneyMode), Sell.PayMoneyType, AAC_SavedSettings.SellPromoteDropDown - 1, promoteTime))
end

function Sell.ShowPromoBG()
	local itemBG = _G["AAC_SellItemFramePromoBG"];
	local promoteType = AAC_SavedSettings.SellPromoteDropDown - 1;
	if promoteType ~= 0 then
		itemBG:Show()
		itemBG:SetAlpha(0.5)
		itemBG:SetColor(AAC_PROMOTE_TYPE_COLORS_MAIN[promoteType].R, AAC_PROMOTE_TYPE_COLORS_MAIN[promoteType].G, AAC_PROMOTE_TYPE_COLORS_MAIN[promoteType].B)
	else
		itemBG:Hide()
	end
end


-- Seller prices use the native auction fee API, not buy-order fee estimates.
function Sell.GrossForNet(net, mode, lot)
    if type(net) ~= "number" or net < 0 or net ~= net or net == math.huge then return end
    local _, rate = Sell.GetSaleFee(0, mode, lot)
    if not rate or rate >= 10000 then return end
    net = math.ceil(net)
    local lo, hi = net, 9007199254740991
    if hi - Sell.GetSaleFee(hi, mode, lot) < net then return end
    while lo < hi do
        local mid = lo + math.floor((hi-lo)/2)
        if mid - Sell.GetSaleFee(mid, mode, lot) >= net then hi=mid else lo=mid+1 end
    end
    return lo
end

local function saleUnits()
    local name, _, count, _, lot = Sell.GetAuctionItem()
    local white = AAC.Tools.GetWhiteValue(Sell.CurrentItem) or 1
    return name, math.max((count or 1)*white,1), lot
end

function Sell.UpdateNetPrices()
    if not AAC_SellPriceNet or Sell.netUpdating then return end
    Sell.netUpdating=true
    local name, units, lot = saleUnits()
    local gross=AAC.MoneyFrame.GetMoney(AAC_SellPriceBuyout, Sell.PayMoneyMode) or 0
    local fee, rate=Sell.GetSaleFee(gross, Sell.PayMoneyMode,lot)
    local available=fee ~= nil and rate < 10000
    local net=available and name and (gross-fee) or 0
    local per=net/units
    -- Preserve the existing Gold/Diamond rate convention for legacy money lots.
    if Sell.MoneyAuction and Sell.PayMoneyMode=="account" and per>0 then per=1/per end
    for _,entry in ipairs({{AAC_SellPriceNet,net},{AAC_SellPriceNetPPU,per}}) do
        local frame=entry[1]
        AAC.MoneyFrame.SetMode(frame,Sell.PayMoneyMode)
        for _,suffix in ipairs({"Gold","Account"}) do
            _G[frame:GetName()..suffix]:SetEnable(available)
        end
        if Sell.netEditing ~= frame then AAC.MoneyFrame.SetMoney(frame,entry[2]) end
    end
    local t=AAC.TradingTranslations or {}
    AAC_SellPriceBuyoutLabel:SetText(t.grossTotal or "Total price (gross)")
    AAC_SellPriceBuyoutPPULabel:SetText(t.grossPrice or "Price / unit (gross)")
    AAC_SellPriceNetLabel:SetText(t.netTotal or "Total price (net)")
    AAC_SellPriceNetPPULabel:SetText(t.netPrice or "Price / unit (net)")
    Sell.netUpdating=nil
end

function Sell.NetPriceChanged(frame)
    if Sell.netUpdating or Sell.internal_money_update then return end
    if not AAC.MoneyFrame.IsValueValid(frame) then return end
    local name,units,lot=saleUnits()
    if not name then return end
    local net=AAC.MoneyFrame.GetMoney(frame,Sell.PayMoneyMode)
    if frame==AAC_SellPriceNetPPU then
        if Sell.MoneyAuction and Sell.PayMoneyMode=="account" and net>0 then net=1/net end
        net=net*units
    end
    local gross=Sell.GrossForNet(net,Sell.PayMoneyMode,lot)
    if not gross then return end
    Sell.netEditing=frame
    AAC.MoneyFrame.SetMoney(AAC_SellPriceBuyout,gross)
    Sell.OnOfferChange3()
    Sell.netEditing=nil
end

function Sell.InitNetPrices()
    if not AAC_SellPriceNet then return end
    local names={"AAC_SellPriceBuyout","AAC_SellPriceNet","AAC_SellPriceBuyoutPPU","AAC_SellPriceNetPPU"}
    for i,name in ipairs(names) do
        local f=_G[name]
        f:ClearAllAnchors(); f:SetAnchor("TOPLEFT","TOPLEFT",AAC_SellItemFrame,174+((i-1)%2)*164,i<=2 and 72 or 120)
        f:SetSize(138,20)
        for _,suffix in ipairs({"Gold","Account"}) do _G[name..suffix]:SetSize(138,20) end
        local label=_G[name.."Label"]
        label:ClearAllAnchors();label:SetAnchor("BOTTOMLEFT","TOPLEFT",f,0,-3)
        label:SetSize(157,26);label:SetJustifyHType("LEFT")
    end
    if not Sell.netInitialized then
        MoneyInputFrame_SetOnvalueChangedFunc(AAC_SellPriceNet,Sell.NetPriceChanged)
        MoneyInputFrame_SetOnvalueChangedFunc(AAC_SellPriceNetPPU,Sell.NetPriceChanged)
        AAC.MoneyFrame.SetFocusOrder(AAC_SellPriceBuyout,AAC_SellPriceNet,AAC_SellPriceNetPPU)
        AAC.MoneyFrame.SetFocusOrder(AAC_SellPriceNet,AAC_SellPriceBuyoutPPU,AAC_SellPriceBuyout)
        AAC.MoneyFrame.SetFocusOrder(AAC_SellPriceBuyoutPPU,AAC_SellPriceNetPPU,AAC_SellPriceNet)
        AAC.MoneyFrame.SetFocusOrder(AAC_SellPriceNetPPU,AAC_SellPriceBuyout,AAC_SellPriceBuyoutPPU)
        Sell.netInitialized=true
    end
    Sell.UpdateNetPrices()
end
