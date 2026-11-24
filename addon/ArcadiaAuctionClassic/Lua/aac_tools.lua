local Tools={
	CurrentSortItem = nil,
}
AAC.Tools=Tools

function AACDebug(msg)
--[===[@alpha@
	DEFAULT_CHAT_FRAME:AddMessage(msg)
--@end-alpha@]===]
end

function Tools.SortPromoteType(item1, item2)
    if item1.promoteType >= 2 and item2.promoteType >= 2 then
		return item1.promoteType > item2.promoteType;
	elseif item1.promoteType >= 2 then
		return true;
	elseif item2.promoteType >= 2 then
		return false;
	else
		return item1.auctionid < item2.auctionid;
	end
end

function Tools.SortBidLess(item1, item2)
    if item1.bidPrice == item2.bidPrice then
		return Tools.SortPromoteType(item1, item2)
    end
	return item1.bidPrice < item2.bidPrice
end

function Tools.SortBidMore(item1, item2)
	if item1.bidPrice == item2.bidPrice then
		return Tools.SortPromoteType(item1, item2)
    end
	return item1.bidPrice > item2.bidPrice
end

function Tools.SortBuyoutLess(item1, item2)

	local moneyModePriority = {["copper"] = 1, ["account"] = 2}
	
	local function getMoneyModePriority( item )
		return moneyModePriority[ item.moneyMode ] or 0
	end;

	local moneyMode1 = getMoneyModePriority( item1 );
	local moneyMode2 = getMoneyModePriority( item2 );

	if( moneyMode1 == moneyMode2 ) then

		if( item1.buyoutPrice == item2.buyoutPrice ) then
			return Tools.SortPromoteType( item1, item2 );
		else
			return item1.buyoutPrice < item2.buyoutPrice;
		end;
	else
		return moneyMode1 < moneyMode2;
	end;
	
end

function Tools.SortBuyoutMore(item1, item2)--63

	local moneyModePriority = {["copper"] = 1, ["account"] = 2}
	
	local function getMoneyModePriority( item )
		return moneyModePriority[ item.moneyMode ] or 0
	end;

	local moneyMode1 = getMoneyModePriority( item1 );
	local moneyMode2 = getMoneyModePriority( item2 );

	if( moneyMode1 == moneyMode2 ) then

		if( item1.buyoutPrice == item2.buyoutPrice ) then
			return Tools.SortPromoteType( item1, item2 );
		else
			return item1.buyoutPrice > item2.buyoutPrice;
		end;
	else
		return moneyMode1 > moneyMode2;
	end;

end

function Tools.SortBidPPULess(item1, item2)
	local white1 = Tools.GetWhiteValue(item1.name)
	local white2 = Tools.GetWhiteValue(item2.name)
	local PPU1 = item1.bidppu or (item1.bidPrice / item1.count)
	local PPU2 = item2.bidppu or (item2.bidPrice / item2.count)

    local v1 = PPU1/white1
    local v2 = PPU2/white2
    if v1==v2 then
		return Tools.SortPromoteType(item1, item2)
    end

	return v1 < v2
end

function Tools.SortBidPPUMore(item1, item2)
	local white1 = Tools.GetWhiteValue(item1.name)
	local white2 = Tools.GetWhiteValue(item2.name)
	local PPU1 = item1.bidppu or (item1.bidPrice / item1.count)
	local PPU2 = item2.bidppu or (item2.bidPrice / item2.count)

    local v1 = PPU1/white1
    local v2 = PPU2/white2
    if v1==v2 then
		return Tools.SortPromoteType(item1, item2)
    end

	return v1 > v2
    -- return not Tools.SortBidPPULess(item1, item2)
end

function Tools.SortBuyoutPPULess(item1, item2)
	if item1.buyoutPrice == 0 then
        if item2.buyoutPrice == 0 then
            return Tools.SortBidLess(item1, item2)
        end
		return false
	elseif item2.buyoutPrice == 0 then
		return true
	else
		local white1 = Tools.GetWhiteValue(item1.name)
		local white2 = Tools.GetWhiteValue(item2.name)
		local PPU1 = item1.buyppu or (item1.buyoutPrice / item1.count)
		local PPU2 = item2.buyppu or (item2.buyoutPrice / item2.count)

        local v1 = PPU1/white1
        local v2 = PPU2/white2
        if v1==v2 then
			return Tools.SortPromoteType(item1, item2)
        end

        return v1 < v2
	end
end

function Tools.SortBuyoutPPUMore(item1, item2)
	if item1.buyoutPrice == 0 then
        if item2.buyoutPrice == 0 then
            return Tools.SortBidMore(item1, item2)
        end
		return true
	elseif item2.buyoutPrice == 0 then
		return false
	else
		local white1 = Tools.GetWhiteValue(item1.name)
		local white2 = Tools.GetWhiteValue(item2.name)
		local PPU1 = item1.buyppu or (item1.buyoutPrice / item1.count)
		local PPU2 = item2.buyppu or (item2.buyoutPrice / item2.count)

        local v1 = PPU1/white1
        local v2 = PPU2/white2
        if v1==v2 then
			return Tools.SortPromoteType(item1, item2)
        end

        return v1 > v2
	end
	--return Tools.SortBuyoutPPULess(item2, item1)
end

function Tools.SortLess(item1, item2)
	if Tools.CurrentSortItem == "status" then
		if item1[Tools.CurrentSortItem] == false and item2[Tools.CurrentSortItem] == true then
			return true
		else
			return false
		end
	elseif Tools.CurrentSortItem == "seller" or Tools.CurrentSortItem == "bidder" then
		if item1[Tools.CurrentSortItem] == item2[Tools.CurrentSortItem] then return Tools.SortPromoteType(item1, item2) end
		return Tools.StringLower(item1[Tools.CurrentSortItem]) < Tools.StringLower(item2[Tools.CurrentSortItem])
	elseif Tools.CurrentSortItem == "name" then
		for _, id in pairs({200000, 200003}) do
			local count1, name1 = item1[Tools.CurrentSortItem]:gsub("%"..COMMA, ""):match("(%d*) "..TEXT("Sys"..id.."_name_plural").."$")
			local count2, name2 = item2[Tools.CurrentSortItem]:gsub("%"..COMMA, ""):match("(%d*) "..TEXT("Sys"..id.."_name_plural").."$")
			if count1 and count2 then
				if item1[Tools.CurrentSortItem] == item2[Tools.CurrentSortItem] then return Tools.SortPromoteType(item1, item2) end
				return tonumber(count1) < tonumber(count2)
			end
		end
		if item1[Tools.CurrentSortItem] == item2[Tools.CurrentSortItem] then return Tools.SortPromoteType(item1, item2) end
		return item1[Tools.CurrentSortItem]:gsub("%"..COMMA, "") < item2[Tools.CurrentSortItem]:gsub("%"..COMMA, "")
	else
		if item1[Tools.CurrentSortItem] == item2[Tools.CurrentSortItem] then return Tools.SortPromoteType(item1, item2) end
		return item1[Tools.CurrentSortItem] < item2[Tools.CurrentSortItem]
	end
end

function Tools.SortMore(item1, item2)
	if Tools.CurrentSortItem == "status" then
		if item1[Tools.CurrentSortItem] == true and item2[Tools.CurrentSortItem] == false then
			return true
		else
			return false
		end
	elseif Tools.CurrentSortItem == "seller" or Tools.CurrentSortItem == "bidder" then
		if item1[Tools.CurrentSortItem] == item2[Tools.CurrentSortItem] then return Tools.SortPromoteType(item1, item2) end
		return Tools.StringLower(item1[Tools.CurrentSortItem]) > Tools.StringLower(item2[Tools.CurrentSortItem])
	elseif Tools.CurrentSortItem == "name" then
		for _, id in pairs({200000, 200003}) do
			local count1, name1 = item1[Tools.CurrentSortItem]:gsub("%"..COMMA, ""):match("(%d*) "..TEXT("Sys"..id.."_name_plural").."$")
			local count2, name2 = item2[Tools.CurrentSortItem]:gsub("%"..COMMA, ""):match("(%d*) "..TEXT("Sys"..id.."_name_plural").."$")
			if count1 and count2 then
				if item1[Tools.CurrentSortItem] == item2[Tools.CurrentSortItem] then return Tools.SortPromoteType(item1, item2) end
				return tonumber(count1) > tonumber(count2)
			end
		end
		if item1[Tools.CurrentSortItem] == item2[Tools.CurrentSortItem] then return Tools.SortPromoteType(item1, item2) end
		return item1[Tools.CurrentSortItem]:gsub("%"..COMMA, "") > item2[Tools.CurrentSortItem]:gsub("%"..COMMA, "")
	else
		if item1[Tools.CurrentSortItem] == item2[Tools.CurrentSortItem] then return Tools.SortPromoteType(item1, item2) end
		return item1[Tools.CurrentSortItem] > item2[Tools.CurrentSortItem]
	end
end

function Tools.CalcBidPrice(money)
	local price = math.floor(money * 1.05)
	if price == money then
		price = price + 1
	end
	return price
end

function Tools.LunaReceive(Name, Message)
--@non-alpha@
	if string.find(Message, "Build: [%d]+") then
		if AAC.Manifest.Build < tonumber(string.match(Message, "[%d]+")) and not AAC.Updated then
			DEFAULT_CHAT_FRAME:AddMessage(AAC_LUNA_NEW_VERSION_FOUND)
			AAC.Updated = true
		end
	end
--@end-non-alpha@
end

function Tools.LocalTimeString(leftTime)
	local days, hours, minutes
	local temptime
	days = math.floor(leftTime / 1440)
	temptime = leftTime - (days * 1440)
	hours = string.format("%2s", math.floor(temptime / 60))
	temptime = temptime - (hours * 60)
	minutes = string.format("%02s", temptime)
	if days == 0 then
		days = "   "
	else
		hours = string.format("%02d", hours)
		days = days..AAC_TOOLS_DAY_ABV
	end
	if days == "   " and hours == 0 then
		hours = "   "
	else
		hours = hours..AAC_TOOLS_HOUR_ABV
	end
	return days.." "..hours.." "..minutes..AAC_TOOLS_MIN_ABV
end

function Tools.EvaluateString(str)
	str = string.gsub(str, ",", ".")
	local func, _error = loadstring("return " .. str, str)
    if _error then return _error end

	local _,result = pcall( func, str )
	return result
end

function Tools.ChatEdit_AddItemLink(link, insert_in_self)
    if AAC.TrySearchItemLink and AAC.TrySearchItemLink(link) then return true end
	if link == nil then
		return
	end
	local RarestIndex = 1
	local IDOfRarestIndex
	local rarityList
	local isDirtyTier = true
	local IsPvP = false
	local _,_data,_name = ParseHyperlink(link)
	if not _data then return link end

	local Start, End = 202840, 202859
	local ItemID = tonumber(_data:gsub("(.-) .+","%1"),16)
	if CheckBit( GetObjectInfo( ItemID, "Mode" ), 30 ) then
		Start, End = 1248061, 1248080
		IsPvP = true
	end

	for i = Start, End do
		if tonumber(_data:gsub("(.-) .+","%1"),16) == i then
			rarityList = rarityList or {}
			for index = 1, 6 do
				local IDOfCurrentIndex = GetItemInherent(link, index) or 0
				if IDOfCurrentIndex ~= 0 then
					local inherentvalue = GetObjectInfo(IDOfCurrentIndex, "inherentvalue")
					if inherentvalue ~= 10 then
						isDirtyTier = false
					end
					table.insert(rarityList,GetQualityByGUID(IDOfCurrentIndex))
					IDOfRarestIndex = GetItemInherent(link, RarestIndex) or 0
					if GetQualityByGUID(IDOfCurrentIndex) > GetQualityByGUID(IDOfRarestIndex) then
						RarestIndex = index
					end
				end
			end
			break;
		end
	end
	if rarityList then
		local rarity = GetQualityByGUID(IDOfRarestIndex or 0)
		if #rarityList < 6 and #rarityList > 1 then rarity = 0 end
		local r, g, b = GetInherentAttributeColor(IDOfRarestIndex or 0)
		if r == 1 and g == 1 and b == 1 then
			r,g,b = GetItemQualityColor(rarity)
		end
		local totalRarity = 0
		for i,v in pairs(rarityList) do
			totalRarity = totalRarity + v
		end
		local name = _name
		local id = tonumber(_data:gsub("(.-) .+","%1"),16)
		local tier = id - ( Start - 1 )
		if totalRarity/6 == 2 and isDirtyTier then
			if IsPvP then
				name = string.format(TEXT("SYS_DIRTY_PVP_2"),tier)
			else
				name = string.format(TEXT("SYS_DIRTY_2"),tier)
			end
			r,g,b = 1,1,0
		elseif totalRarity/6 == 4 and isDirtyTier then
			if IsPvP then
				name = string.format(TEXT("SYS_DIRTY_PVP_3"),tier)
			else
				name = string.format(TEXT("SYS_DIRTY_3"),tier)
			end
			r,g,b = 0.94,0.08,0.88
		elseif #rarityList == 0 then
			if IsPvP then
				name = string.format(TEXT("SYS_CLEAN_PVP"),tier)
			else
				name = string.format(TEXT("SYS_CLEAN"),tier)
			end
			r,g,b = 0.42,0.80,0.96
		elseif totalRarity/6 < 2 and #rarityList == 6 then
			if IsPvP then
				name = string.format(TEXT("SYS_DIRTY_PVP"),tier)
			else
				name = string.format(TEXT("SYS_DIRTY"),tier)
			end
			r,g,b = 0.1,1,0.1
		elseif rarityList[1] == totalRarity then
			name = TEXT("Sys"..IDOfRarestIndex.."_name")
		end
		link = link:gsub("(%|c..)......%[.+%]","%1"..string.format("%02x%02x%02x",r*0xFF,g*0xFF,b*0xFF).."%["..name.."%]")
	end
	if ITEMLINK_EDITBOX ~= nil then
		ITEMLINK_EDITBOX:InsertText(link)
		return true
	elseif insert_in_self and AAC_AuctionFrame:IsVisible() and AAC_BrowseFrame:IsVisible() then
		local _type, _data, _name = ParseHyperlink(link)
		AAC_BrowseNameEditBox:SetText(_name)
		return true
	else
		local editbox = GetKeyboardFocus()
		if editbox then
			local _type, _data, _name = ParseHyperlink(link)
			editbox:InsertText(_name)
			return true
        end
	end
	return false
end

function Tools.GetVendorPrice()
	local temp
	for i = 1, 40 do
		local label = getglobal("AAC_TooltipTextLeft"..i)
		if label:IsVisible() then
			temp = label:GetText()
			if temp and string.find(temp, TEXT("SYS_ITEM_COST")) then
				temp = string.gsub(temp, "%"..COMMA, "")
				return tonumber(string.match(temp, "%d+"))
			end
		end
	end
	return nil
end

function Tools.SetDropDown(frame, id, name, color)
	if name then
		getglobal(frame:GetName().."Text"):SetText(name)
		if color then
			getglobal(frame:GetName().."Text"):SetColor(color[1], color[2], color[3])
		end
	end
	if id then
		frame.selectedID = id
	end
end

function Tools.ParseLink(link)
	local data, name
	if link and link ~= "" then
		_, data, name = ParseHyperlink(link)
		if data then
			return tonumber((data:match("(.-) .*") or data), 16), name
		else
			AACDebug("ToolsParseLink: Bad Link: link = "..link)
		end
	end
	return nil, nil
end

function Tools.ClickPlayerName(this, key)
	local Seller = this:GetText()
	if Seller == nil or Seller == "" or Seller == (GRAY_FONT_COLOR_CODE .. AUCTION_ANONYMOUS .. "|r") then return end
	Hyperlink_Assign(string.format("|Hplayer:%s|h[%s]|h", Seller, Seller), key)
end

function Tools.FormatDynDecimals(number)
	if type(number) ~= "number" then
		AACDebug("ToolsDynamicDecimalPlaces: Bad number")
		return 0
	elseif number < 0 then
		return 0
	elseif number < 0.001 then
		return tonumber(string.format("%.6f", number))
	elseif number < 0.01 then
		return tonumber(string.format("%.5f", number))
	elseif number < 0.1 then
		return tonumber(string.format("%.4f", number))
	elseif number < 1 then
		return tonumber(string.format("%.3f", number))
	elseif number < 10 then
		return tonumber(string.format("%.2f", number))
	elseif number < 100 then
		return tonumber(string.format("%.1f", number))
	else
		return tonumber(string.format("%.0f", number))
	end
end

-- Some locales define the same decimal point as the client's thousands separator (COMMA),
-- which made "0,5" parse as 5. Fall back to the other separator in that case.
function Tools.GetDecimalPoint()
	if AAC_GENERAL_DECIMAL_POINT ~= COMMA then
		return AAC_GENERAL_DECIMAL_POINT
	end
	return COMMA == "." and "," or "."
end

function Tools.FormatNumber(num)
	if num < 1 and num > -1 and num ~= 0 then
        return (string.format("%.15f",num):gsub("0+$",""):gsub("%.",Tools.GetDecimalPoint()))
	end

	local n =  Tools.FormatDynDecimals(num)
    return Tools.FormatThousands(n)
end

function Tools.FormatForceDecimals(num)
	if num < 1 and num > -1 and num ~= 0 then
		return string.format("%.15f",num):gsub("0+$","")
	end
	return num
end

function Tools.FormatThousands(number)
    local left,num,right = string.match(tostring(number),'^([^%d]*%d)(%d*)(.-)$')
    num = num:reverse():gsub('(%d%d%d)','%1'..COMMA)
    right = right:gsub("^%.",Tools.GetDecimalPoint())
    return left..(num:reverse())..right
end

function Tools.ParseMoney(t)
    t = string.match(t,"^%s*(.*)%s*$")
    t = string.gsub(t,"%"..COMMA,"")
    t = string.gsub(t,"%"..Tools.GetDecimalPoint(),".")

    if string.find(t,"e[%+%-%d]*$") then
        return tonumber(t)
    end

    local _,_,v,k = string.find(t,"^([%d%.]-)([kK]+)$")
    if k then
        t=v * math.pow(10, k:len()*3)
    end

    local _,_,v,k = string.find(t,"^([%d%.]-)([mM]+)$")
    if k then
        t=v * math.pow(10, k:len()*6)
    end

    return tonumber(t)
end

function Tools.IsValidMoneyFormat(t)

    t = string.match(t,"^%s*(.*)%s*$")

    -- misplaced thousend point
    if string.find(t,"%"..COMMA.."%d[^%d]") or
        string.find(t,"%"..COMMA.."%d%d[^%d]") or
        string.find(t,"%"..COMMA.."%d$") or
        string.find(t,"%"..COMMA.."%d%d$") or
        string.find(t,"%"..COMMA.."%d%d%d%d") then return false end

    -- illegal ending
    if string.find(t,"[^%d^k^K^m^M]$") then return false end

    -- multiple decimal points
    local decimalPoint = Tools.GetDecimalPoint()
    if string.find(t,"%"..decimalPoint..".*[%"..decimalPoint.."%"..COMMA.."]") then
        return false end

    return Tools.ParseMoney(t)
end

function Tools.SetSortIcon(frame, icon)
    if icon == 0 then
        frame:SetFile("Interface\\AddOns\\_BuiltIn\\AdvancedAuctionhouse\\Textures\\full_arrow_up")
    elseif icon== 1 then
        frame:SetFile("Interface\\AddOns\\_BuiltIn\\AdvancedAuctionhouse\\Textures\\full_arrow_down")
    elseif icon == 2 then
        frame:SetFile("Interface\\AddOns\\_BuiltIn\\AdvancedAuctionhouse\\Textures\\hollow_arrow_up")
    elseif icon == 3 then
        frame:SetFile("Interface\\AddOns\\_BuiltIn\\AdvancedAuctionhouse\\Textures\\hollow_arrow_down")
    else
        frame:SetFile("")
    end
end

function Tools.GetWhiteValue(itemid)
	if AAC_SavedSettings.UseMatWhiteValue then
		return AAC.Data.MatWhiteValue[itemid] or 1
	else
		return 1
	end
end


local Gradient = {
--  value   r    g    b    a
    {0.50, 0.0, 1.0, 0.5, 1.0},
    {0.75, 0.0, 1.0, 0.0, 1.0},
    {1.00, 1.0, 1.0, 1.0, 1.0},
    {1.50, 1.0, 1.0, 0.0, 1.0},
    {2.00, 1.0, 0.0, 0.0, 1.0},
}
local InvGradient = {
--  value   r    g    b    a
    {2.00, 0.0, 1.0, 0.5, 1.0},
    {1.50, 0.0, 1.0, 0.0, 1.0},
    {1.00, 1.0, 1.0, 1.0, 1.0},
    {0.75, 1.0, 1.0, 0.0, 1.0},
    {0.50, 1.0, 0.0, 0.0, 1.0},
}
function Tools.GetAvgPriceColorNew(price, average, widget, inverse)
	if inverse then
		getglobal(widget):SetColor(Tools.ColFromGradient(price/average, InvGradient))
	else
		getglobal(widget):SetColor(Tools.ColFromGradient(price/average, Gradient))
	end
end
function Tools.GetAvgPriceColorOld(price, average, widget, inverse)
	local buyPPUColor = 0
	if inverse then
		if price / average < 1 then
			buyPPUColor = price / average
			getglobal(widget):SetColor(1,buyPPUColor,buyPPUColor)
		else
			buyPPUColor = 2 - math.min(price / average, 2)
			getglobal(widget):SetColor(buyPPUColor,1,buyPPUColor)
		end
	else
		if price / average < 1 then
			buyPPUColor = price / average
			getglobal(widget):SetColor(buyPPUColor,1,buyPPUColor)
		else
			buyPPUColor = 2 - math.min(price / average, 2)
			getglobal(widget):SetColor(1,buyPPUColor,buyPPUColor)
		end
	end
end
--Make new function the working one (A config option to activate the old one might follow if people don't like it)
Tools.GetAvgPriceColor = Tools.GetAvgPriceColorNew

function Tools.FindColorType(r, g, b)
	r,g,b = tonumber(string.format("%0.2f",r)),tonumber(string.format("%0.2f",g)),tonumber(string.format("%0.2f",b))
	if r == 1 and g == 1 and b == 1 then
		return "white"
	elseif r == 0 and g == 1 and b == 0 then
		return "green"
	elseif r == 1 and g == 1 and b == 0 then
		return "yellow"
	elseif r == 1 and g == 0 and b == 0 then
		return "red"
	elseif r == 0.94 and g == 0.08 and b == 0.88 then
		return "purple"
	elseif string.format("%.2f", r) == "0.94" and string.format("%.2f", g) == "0.38" and string.format("%.2f", b) == "0.05" then
		return "orange"
	elseif string.format("%.2f", r) == "0.74" and string.format("%.2f", g) == "0.18" and string.format("%.2f", b) == "1.00" then
		return "rune"
	elseif string.format("%.2f", r) == "0.62" and string.format("%.2f", g) == "0.46" and string.format("%.2f", b) == "0.30" then
		return "set"
	else
		return "other"
	end
end

-- Copyright notice: This function has been copied BY NOGUAI! from ZZLibrary.
function Tools.ColFromGradient(val, gradient)
	--Return white on missing parameter
	if not val or not gradient then return 1, 1, 1, 1 end
	--Sort gradient table
	table.sort(gradient, function(a,b) return a[1] < b[1] end)
	--Return color on gradients border if value exceeds one
	if val <= gradient[1][1] then return gradient[1][2], gradient[1][3], gradient[1][4], gradient[1][5] end
	if val >= gradient[#gradient][1] then return gradient[#gradient][2], gradient[#gradient][3], gradient[#gradient][4], gradient[#gradient][5] end

	for i = 1, #gradient-1 do
		--find nearest gradient points
		if val >= gradient[i][1] and val <= gradient[i+1][1] then
			--load differences
			local temp = {}
			for j = 1, 5 do
				temp[j] = gradient[i+1][j] - gradient[i][j]
			end
			--calculate relative position
			local pct = (val - gradient[i][1]) / temp[1]
			--calculate new color
			for j = 2, 5 do
				temp[j] = gradient[i][j] + (temp[j] * pct)
			end
			--return color
			return temp[2], temp[3], temp[4], temp[5]
		end
	end
end


function Tools.StringLower(text)
	text = Tools.NormalizeTooltipText(text)
	local id = text:match("Stat: (%d+)") or text:match("Rune: (%d+)")
	if id then
		id = tonumber(id)
		text = TEXT("Sys"..id.."_name")
	end
	if stripAccents then
		text = stripAccents(text)
	end
	text = string.lower(text)
	return text
end

function Tools.NormalizeTooltipText(text)
	if type(text) ~= "string" then
		return ""
	end

	-- Client tooltips can wrap any visible field in a hyperlink. AAC reads the
	-- visible text, so discard link metadata while preserving labels and values.
	text = text:gsub("|H[^|]*|h", "")
	text = text:gsub("|h", "")
	text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
	text = text:gsub("|r", "")
	return text
end

function Tools.Trim(str)
	local baseNumber = string.format("%.10f",tostring(str)):match("(%d+)%.")
	local decimalLimit = 2
	if tonumber(baseNumber) >= 1000000000 then
        local billions = tonumber(baseNumber) / 1000000000
        return string.format("%.1fKKK", billions)
	elseif tonumber( baseNumber ) == 0 and not AAC_SavedSettings.PPUDisplaySettings then
		return "<1"
	elseif tonumber( baseNumber ) == 0 and AAC_SavedSettings.PPUDisplaySettings then
		return string.format("%." .. tostring(AAC_SavedSettings.DecimalDigits) .. "f", str)
	end
	return CutLongDecimals(str,decimalLimit,true)
end

function Tools.getLevelColor(itemLevel)
	local characterLevel = UnitLevel("player")	

	if characterLevel ~= nil and itemLevel ~= nil then
		if(itemLevel <= characterLevel) then return WHITE_FONT_COLOR_CODE end
	end
	return RED_FONT_COLOR_CODE
end