local Bid = {
	DisplayedItems = 8,
	SortMode = 0,
	SortItem = {
		[1] = "name",
		[2] = "level",
		[3] = "leftTime",
		[4] = "seller",
		[5] = "status",
	},
	SortFunc = {
		["60"] = "SortBidLess",
		["61"] = "SortBidMore",
		["62"] = "SortBuyoutLess",
		["63"] = "SortBuyoutMore",
		["70"] = "SortBidPPULess",
		["71"] = "SortBidPPUMore",
		["72"] = "SortBuyoutPPULess",
		["73"] = "SortBuyoutPPUMore",
	},
	List = {},
}
AAC.Bid = Bid

function Bid.OnLoad(this)
	AAC_BidHeaderPPU:SetText(AAC_GENERAL_PRICE_PER_UNIT_HEADER)
    AAC.MoneyFrame.ResetMoney(AAC_BidListBidMoneyInput)
end

function Bid.Resize(num)
	AAC_BidList:SetSize(803, 380 + 44 * num)
	Bid.DisplayedItems = 8 + num
	for i = Bid.DisplayedItems + 1, 13 do
		getglobal("AAC_BidListItem"..i):Hide()
	end
	Bid.ReadList()
end

function Bid.ChangeSortMode(this)
	local id = this:GetID()
	Bid.ClearSortIcons()
	if Bid.List.sortIndex == id or Bid.List.sortIndex == -id then
		Bid.SortMode = (Bid.SortMode + 1) % 4
	else
		Bid.SortMode = 0
	end
	if id == 6 or id == 7 then
        AAC.Tools.SetSortIcon(_G[this:GetName().."SortIcon"], Bid.SortMode)
	else
		if Bid.List.sortIndex == id then
			id = -id
            AAC.Tools.SetSortIcon(_G[this:GetName().."SortIcon"], 1)
		else
            AAC.Tools.SetSortIcon(_G[this:GetName().."SortIcon"], 0)
		end
	end
	Bid.SortList(id)
end

function Bid.ClearSortIcons()
	for _, name in ipairs({"Name", "Level", "LeftTime", "Seller", "Status", "PPU", "Price"}) do
		getglobal("AAC_BidHeader"..name.."SortIcon"):SetFile("")
	end
end

function Bid.SortList(index)
	Bid.List.sortIndex = index
	local i = math.abs(index)
	if i == 6 or i == 7 then
		table.sort(Bid.List.Items, AAC.Tools[Bid.SortFunc[i..Bid.SortMode]])
	else
		AAC.Tools.CurrentSortItem = Bid.SortItem[i]

		if index > 0 then
			table.sort(Bid.List.Items, AAC.Tools.SortLess)
		else
			table.sort(Bid.List.Items, AAC.Tools.SortMore)
		end
	end
	Bid.DrawList()
end

local function selected()
    local button = Bid.Selection and _G["AAC_BidListItem" .. Bid.Selection]
    return button and Bid.List.Items[button.index]
end

function Bid.BidSelection()
    local offer = selected()
    if offer then
        AAC.Pay.PayAuction(offer, AAC.MoneyFrame.GetMoney(AAC_BidListBidMoneyInput), false, AAC.Pay.AuctionType.Bid)
    end
end

function Bid.BuySelection()
    local offer = selected()
    if offer then
        AAC.Pay.PayAuction(offer, 0, true, AAC.Pay.AuctionType.Bid)
    end
end

function AAC.Events.AUCTION_BUY_UPDATE(this)
	AAC.Bid.ReadList()
end


function Bid.ReadList()
    Bid.Revision = (Bid.Revision or 0) + 1
	local num = AAC.CanRequest() and AAC.Market.Feature("ItemBids") and GetAuctionNumBidItems() or 0
	Bid.List.Items = {}
	for i = 1, num do
		local name, count, rarity, texture, level, leftTime, seller, status, moneyMode, bidPrice, buyoutPrice, promoteType = GetAuctionBidItemInfo(i)
		local link = GetAuctionBidItemLink(i)
        local itemid = link and AAC.Tools.ParseLink(link)
        if itemid and name and count then
            bidPrice, buyoutPrice = bidPrice or 0, buyoutPrice or 0
            local cacheCount = count

            for _, id in pairs({200000, 200003}) do
                local moneycount = name:gsub("%"..COMMA, ""):match("(%d*) "..TEXT("Sys"..id.."_name_plural").."$")
                if moneycount then
                    count = tonumber(moneycount)
                    itemid = id
                end
            end

            if itemid >= 204476 and itemid <= 204508 then
                AAC_Tooltip:SetHyperLink( link or "" )
                AAC_Tooltip:Hide()

                for i = 1, 10 do
                    local Text = AAC.Tools.NormalizeTooltipText(_G["AAC_TooltipTextLeft" .. i]:GetText())
                    local Level = Text:match( TEXT("SYS_LEVEL") .. ": (%d+)" )

                    if Level then
                        level = tonumber( Level )
                        break
                    end
                end
            end

            local listing = {
                auctionid = i,
                revision = Bid.Revision,
                cacheCount = cacheCount,
                itemid = itemid,
                name = name,
                rarity = rarity,
                count = count,
                texture = texture,
                level = level,
                leftTime = leftTime,
                seller = seller,
                status = status,
                moneyMode = moneyMode,
                bidPrice = bidPrice,
                buyoutPrice = buyoutPrice,
                link = link,
            }

            if itemid == 200000 then
                listing.bidppu = (count / bidPrice)
                listing.buyppu = (count / buyoutPrice)
            else
                local white = AAC.Tools.GetWhiteValue(itemid)
                listing.bidppu = (bidPrice / count) / white
                listing.buyppu = (buyoutPrice / count) / white
            end
            Bid.List.Items[#Bid.List.Items + 1] = listing
        end
    end
    Bid.List.maxNums = #Bid.List.Items
	if Bid.List.sortIndex then
		Bid.SortList(Bid.List.sortIndex)
	end
	local maxValue = Bid.List.maxNums - Bid.DisplayedItems
	if maxValue > 0 then
		AAC_BidListScrollBar:SetMinMaxValues(0, maxValue)
		AAC_BidListScrollBar:Show()
	else
		AAC_BidListScrollBar:SetMinMaxValues(0, 0)
		AAC_BidListScrollBar:Hide()
	end
	Bid.DrawList()
end

function Bid.DrawList()
	local value = AAC_BidListScrollBar:GetValue()
	local button, buttonName, info

	for i = 1, Bid.DisplayedItems do
		button = getglobal("AAC_BidListItem"..i)
		info = Bid.List.Items[value + i]
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
			button.index = value + i
			buttonName = button:GetName()

			local inversecoloring = false
			local count = info.count
			if info.name:gsub("%"..COMMA, ""):match("%d* "..TEXT("Sys200000_name_plural").."$") then
				inversecoloring = true
				count = 0
			elseif info.name:gsub("%"..COMMA, ""):match("%d* "..TEXT("Sys200003_name_plural").."$") then
				count = 0
			end
			local r,g,b = GetItemQualityColor(GetQualityByGUID(info.itemid or 0))
			local color = "|cff"..string.format("%02x",r*255)..string.format("%02x",g*255)..string.format("%02x",b*255)
			getglobal(buttonName.."Name"):SetText(info.stat and color..info.name.."|r\n"..info.stat or color..info.name.."|r")
			getglobal(buttonName.."Name"):SetColor(GetItemQualityColor(info.rarity))
			SetItemButtonCount(getglobal(buttonName.."Icon"), count)
			SetItemButtonTexture(getglobal(buttonName.."Icon"), info.texture)

			getglobal(buttonName.."Level"):SetText(info.level)
			getglobal(buttonName.."LeftTime"):SetText(SecondsToTime(info.leftTime * 60))
			getglobal(buttonName.."Seller"):SetText(info.seller)

			if info.count > 0 and info.bidPrice > 0 then
				getglobal(buttonName.."PPUBid"):SetText(AAC.Tools.FormatThousands(math.floor(info.bidppu)), 1, 1, 1)
				if info.buyoutPrice > 0 then
					getglobal(buttonName.."PPUBuy"):SetText(AAC.Tools.FormatThousands(math.floor(info.buyppu)), 1, 1, 1)
				else
					getglobal(buttonName.."PPUBuy"):SetText("", 1, 1, 1)
				end
			end

            local avg = info.itemid and AAC.History.GetAveragePrice(info.itemid)
            if avg then
 				AAC.Tools.GetAvgPriceColor(info.bidPrice / info.count, avg, buttonName.."PPUBid", inversecoloring)
 				AAC.Tools.GetAvgPriceColor(info.buyoutPrice / info.count, avg, buttonName.."PPUBuy", inversecoloring)
 			end

			if info.status then
				getglobal(buttonName.."Status"):SetText(AUCTION_HIGHEST_PRICE, 0, 1, 0)
			else
				getglobal(buttonName.."Status"):SetText(AUCTION_BID_EXCEED, 1, 0, 0)
			end

			MoneyFrame_Update(buttonName.."BidMoney", info.bidPrice, info.moneyMode or "copper")
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
	Bid.Select(Bid.Selection)
end

function Bid.List_IconClick(this,key)
    if IsShiftKeyDown() and key == "LBUTTON" then
		local link = GetAuctionBidItemLink(Bid.List.Items[this:GetParent().index].auctionid)
        AAC.Tools.ChatEdit_AddItemLink(link)
    end

    Bid.Select(this:GetParent():GetID())
end

function Bid.Select(auctionid)
	AAC_BidListBidButton:Disable()
	AAC_BidListBuyoutButton:Disable()
	AAC_BidListHistoryButton:Disable()
	Bid.Selection = auctionid

	for i = 1, Bid.DisplayedItems do
		getglobal("AAC_BidListItem"..i):UnlockHighlight()
	end

	if auctionid then
		local button = getglobal("AAC_BidListItem"..auctionid)
		local info = Bid.List.Items[button.index]

		if info then
			AAC.MoneyFrame.SetMode(AAC_BidListBidMoneyInput, info.moneyMode)
			AAC.MoneyFrame.SetMoney(AAC_BidListBidMoneyInput, AAC.Tools.CalcBidPrice(info.bidPrice))

			if not info.status and AAC.Market.Feature("ItemBids") then
				AAC_BidListBidButton:Enable()
			end
			if info.buyoutPrice > 0 then
				AAC_BidListBuyoutButton:Enable()
			end
			AAC_BidListHistoryButton:Enable()
			button:LockHighlight()
		end
	end
end