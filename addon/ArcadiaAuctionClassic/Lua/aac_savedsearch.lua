local SavedSearch={
    Options = {
        TEXT("C_SEARCH"),					--Search
        AAC_BROWSE_RENAME,	--Rename
        TEXT("C_DEL"),					--Delete
    },
	Expand = {},
	NewItem = {},
	DragDrop = {},
	RenameItem = {},
}
AAC.SavedSearch = SavedSearch

function SavedSearch.OnLoad()
	AAC_BrowseSavedSearchTitle:SetText(AAC_BROWSE_SAVED_SEARCH_TITLE)
end

function SavedSearch.ExpandButton_OnClick()
    AAC_BrowseSavedSearchExpandButton:Hide()
    AAC_BrowseSavedSearchMinimizeButton:Show()
    AAC_BrowseSavedSearchPlusButton:Enable()
    AAC_BrowseSavedSearch:Show()
	if AAC and AAC.Browse and AAC.Browse.Queue_SetVisible then
		AAC.Browse.Queue_SetVisible(false)
	end
end

function SavedSearch.MinimizeButton_OnClick()
    AAC_BrowseSavedSearchExpandButton:Show()
    AAC_BrowseSavedSearchMinimizeButton:Hide()
    AAC_BrowseSavedSearchPlusButton:Disable()
    AAC_BrowseSavedSearch:Hide()
end

function SavedSearch.ScrollBar_Update()
	local maxValue = #(AAC_SavedSearch)
	if SavedSearch.Expand[1] then
		maxValue = maxValue + #(AAC_SavedSearch[SavedSearch.Expand[1]]["contents"])
		if SavedSearch.Expand[2] then
			maxValue = maxValue + #(SavedSearch.Options)
		end
	end
	maxValue = maxValue - ((AAC.Browse.DisplayedItems * 2) + 5)
	if maxValue > 0 then
		AAC_BrowseSavedSearchScrollBar:Show()
		AAC_BrowseSavedSearchScrollBar:SetMinMaxValues(0, maxValue)
	else
		AAC_BrowseSavedSearchScrollBar:Hide()
		AAC_BrowseSavedSearchScrollBar:SetMinMaxValues(0, 0)
	end
	SavedSearch.UpdateList()
end

function SavedSearch.UpdateList()
	local layer = 1
	local index = 1
	local text
	local folder = 1
	local item = 0
	local option = 0
	local count = 1
	local scroll = AAC_BrowseSavedSearchScrollBar:GetValue()
	while AAC_SavedSearch[folder] do
		if count > (AAC.Browse.DisplayedItems * 2) + 6 then
			return
		end
		if scroll > 0 then
			scroll = scroll - 1
		else
			local button = getglobal("AAC_BrowseSavedSearchButton"..count)
			local normalText = getglobal(button:GetName().."NormalText")
			local highlightText = getglobal(button:GetName().."HighlightText")
			local lineTexture = getglobal(button:GetName().."Line")
			local backgoundTexture = getglobal(button:GetName().."Backgound")
			local width = button:GetWidth()
			if option > 0 then
				layer = 3
				index = option
				text = SavedSearch.Options[index]
			elseif item > 0 then
				layer = 2
				index = item
				text = AAC_SavedSearch[folder]["contents"][item]["name"]
			else
				layer = 1
				index = folder
				text = AAC_SavedSearch[folder]["name"]
			end
			button.layer = layer
			button.index = index
			if layer == 1 then
				backgoundTexture:Show()
				backgoundTexture:SetAlpha(1.0)
				lineTexture:Hide()
				normalText:ClearAllAnchors()
				normalText:SetAnchor("LEFT", "LEFT", button:GetName(), 10, 0)
				normalText:SetWidth(width - 20)
				normalText:SetColor(1, 1, 0)
				highlightText:ClearAllAnchors()
				highlightText:SetAnchor("LEFT", "LEFT", button:GetName(), 10, 0)
				highlightText:SetWidth(width - 20)
				highlightText:SetColor(1, 1, 0)
			elseif layer == 2 then
				backgoundTexture:Show()
				backgoundTexture:SetAlpha(0.5)
				lineTexture:Hide()
				normalText:ClearAllAnchors()
				normalText:SetAnchor("LEFT", "LEFT", button:GetName(), 15, 0)
				normalText:SetWidth(width - 25)
				normalText:SetColor(1, 1, 1)
				highlightText:ClearAllAnchors()
				highlightText:SetAnchor("LEFT", "LEFT", button:GetName(), 15, 0)
				highlightText:SetWidth(width - 25)
				highlightText:SetColor(1, 1, 1)
			else
				backgoundTexture:Hide()
				lineTexture:Show()
				if index == #(SavedSearch.Options) then
					lineTexture:SetTexCoord(0, 1, 0.5, 0.8125)
				else
					lineTexture:SetTexCoord(0, 1, 0, 0.3125)
				end
				normalText:ClearAllAnchors()
				normalText:SetAnchor("LEFT", "LEFT", button:GetName(), 20, 0)
				normalText:SetWidth(width - 30)
				normalText:SetColor(1, 1, 1)
				highlightText:ClearAllAnchors()
				highlightText:SetAnchor("LEFT", "LEFT", button:GetName(), 20, 0)
				highlightText:SetWidth(width - 30)
				highlightText:SetColor(1, 1, 1)
			end
			button:SetText(text)
			if SavedSearch.Expand[layer] == index then
				button:LockHighlight()
			else
				button:UnlockHighlight()
			end
			button:Show()
			count = count + 1
		end
		if option > 0 then
			if option == #(SavedSearch.Options) then
				option = 0
				if item == #(AAC_SavedSearch[folder]["contents"]) then
					item = 0
					folder = folder + 1
				else
					item = item + 1
				end
			else
				option = option + 1
			end
		elseif item > 0 then
			if item == SavedSearch.Expand[2] then
				option = 1
			elseif item == #(AAC_SavedSearch[folder]["contents"]) then
				item = 0
				folder = folder + 1
			else
				item = item + 1
			end
		elseif folder == SavedSearch.Expand[1] then
			item = 1
		else
			folder = folder + 1
		end
	end
	for i = count, (AAC.Browse.DisplayedItems * 2) + 6 do
		getglobal("AAC_BrowseSavedSearchButton"..i):Hide()
	end
end

function SavedSearch.Button_OnClick(this, key)
	for index, value in pairs(SavedSearch.Expand) do
		if index > this.layer then
			SavedSearch.Expand[index] = nil
		end
	end
	if this.layer == 3 then
		if key == "LBUTTON" then
			if this.index == 1 then
				SavedSearch.Search(SavedSearch.Expand[1], SavedSearch.Expand[2])
			elseif this.index == 2 then
				SavedSearch.RenameItem = SavedSearch.Expand
				StaticPopup_Show("AAC_SAVEDSEARCH_RENAMEITEM")
			elseif this.index == 3 then
				table.remove(AAC_SavedSearch[SavedSearch.Expand[1]]["contents"], SavedSearch.Expand[2])
				SavedSearch.Expand[2] = nil
				if #(AAC_SavedSearch[SavedSearch.Expand[1]]["contents"]) == 0 then
					SavedSearch.RemoveFolder(SavedSearch.Expand[1], nil)
				end
			end
		elseif key == "RBUTTON" then
			--???
		end
	elseif this.layer == 2 then
		if key == "LBUTTON" then
			if SavedSearch.Expand[2] == this.index then
				SavedSearch.Expand[2] = nil
				--Make Double Click Search
			else
				SavedSearch.Expand[this.layer] = this.index
			end
		elseif key == "RBUTTON" then
			--When Double Click Searches, then this expands
		end
	elseif this.layer == 1 then
		if key == "LBUTTON" then
			if SavedSearch.Expand[1] == this.index then
				SavedSearch.Expand[this.layer] = nil
			else
				SavedSearch.Expand[this.layer] = this.index
			end
		elseif key == "RBUTTON" then
			--Find way to have folder options
		end
	end
	SavedSearch.ScrollBar_Update()
end

function SavedSearch.Button_OnDragStart(this)
	SavedSearch.DragDrop = {}
	if this.layer == 1 then
		SavedSearch.DragDrop["folder"] = this.index
	elseif this.layer == 2 then
		SavedSearch.DragDrop["folder"] = SavedSearch.Expand[1]
		SavedSearch.DragDrop["item"] = this.index
	end
end

function SavedSearch.Button_OnReceiveDrag(this)
	local offset = 0
	if SavedSearch.DragDrop["folder"] and this.layer ~= 3 then
		if SavedSearch.DragDrop["item"] then
			if this.layer == 2 then
				table.insert(AAC_SavedSearch[SavedSearch.Expand[1]]["contents"], this.index, AAC_SavedSearch[SavedSearch.DragDrop["folder"]]["contents"][SavedSearch.DragDrop["item"]])
				if this.index < SavedSearch.DragDrop["item"] then
					offset = 1
				end
				table.remove(AAC_SavedSearch[SavedSearch.DragDrop["folder"]]["contents"], SavedSearch.DragDrop["item"] + offset)
			elseif this.layer == 1 then
				table.insert(AAC_SavedSearch[this.index]["contents"], AAC_SavedSearch[SavedSearch.DragDrop["folder"]]["contents"][SavedSearch.DragDrop["item"]])
				table.remove(AAC_SavedSearch[SavedSearch.DragDrop["folder"]]["contents"], SavedSearch.DragDrop["item"])
				if #(AAC_SavedSearch[SavedSearch.DragDrop["folder"]]["contents"]) == 0 then
					SavedSearch.RemoveFolder(SavedSearch.DragDrop["folder"], this.index)
				else
					SavedSearch.Expand[1] = this.index
				end
			end
			SavedSearch.Expand[2] = nil
		elseif this.layer == 1 then
			table.insert(AAC_SavedSearch, this.index, AAC_SavedSearch[SavedSearch.DragDrop["folder"]])
			if this.index < SavedSearch.DragDrop["folder"] then
				offset = 1
			end
			table.remove(AAC_SavedSearch, SavedSearch.DragDrop["folder"] + offset)
			SavedSearch.Expand = {}
		elseif not this.layer then
			table.insert(AAC_SavedSearch, AAC_SavedSearch[SavedSearch.DragDrop["folder"]])
			table.remove(AAC_SavedSearch, SavedSearch.DragDrop["folder"])
			SavedSearch.Expand = {}
		end
	end
	SavedSearch.ScrollBar_Update()
end

function SavedSearch.CreateItem(itemname)
	local temp = {}
	temp.name = itemname
	temp.data = {}
	temp.data.Keyword = AAC_BrowseNameEditBox:GetText()
	temp.data.MinLvl = AAC_BrowseMinLvlEditBox:GetText()
	temp.data.MaxLvl = AAC_BrowseMaxLvlEditBox:GetText()
	temp.data.Rarity = UIDropDownMenu_GetSelectedID(AAC_BrowseRarityDropDown)
	temp.data.Rune = UIDropDownMenu_GetSelectedID(AAC_BrowseRuneDropDown)
	temp.data.Usable = AAC_BrowseUsableButton:IsChecked()
	temp.data.Category1 = AAC.Browse.SelectedCategory[1]
	temp.data.Category2 = AAC.Browse.SelectedCategory[2]
	temp.data.Category3 = AAC.Browse.SelectedCategory[3]
	temp.data.PPU = AAC_BrowseFilterPPUButton:IsChecked()
	temp.data.Bid = AAC_BrowseFilterBidButton:IsChecked()
	temp.data.MinPrice = AAC_BrowseFilterMinPriceEditBox:GetText()
	temp.data.MaxPrice = AAC_BrowseFilterMaxPriceEditBox:GetText()
	temp.data.Filter1 = AAC_BrowseFilter1EditBox:GetText()
	temp.data.Filter2 = AAC_BrowseFilter2EditBox:GetText()
	temp.data.Filter3 = AAC_BrowseFilter3EditBox:GetText()
	temp.data.Or2 = AAC_BrowseFilter2OrButton:IsChecked()
	temp.data.Or3 = AAC_BrowseFilter3OrButton:IsChecked()
	if SavedSearch.Expand[1] then
		SavedSearch.Expand[2] = nil
		SavedSearch.Expand[3] = nil
		table.insert(AAC_SavedSearch[SavedSearch.Expand[1]]["contents"], temp)
		SavedSearch.ScrollBar_Update()
	else
		SavedSearch.NewItem = temp
		StaticPopup_Show("AAC_SAVEDSEARCH_CREATEFOLDER")
	end
end

function SavedSearch.Search(folder, item)
	local temp = AAC_SavedSearch[folder]["contents"][item]["data"]
	AAC_BrowseNameEditBox:SetText(temp.Keyword)
	AAC_BrowseMinLvlEditBox:SetText(temp.MinLvl)
	AAC_BrowseMaxLvlEditBox:SetText(temp.MaxLvl)
	AAC.Tools.SetDropDown(AAC_BrowseRarityDropDown, temp.Rarity, AAC.Browse.RarityInfo[temp.Rarity], {GetItemQualityColor(temp.Rarity - 1)})
	AAC.Tools.SetDropDown(AAC_BrowseRuneDropDown, temp.Rune, AAC.Browse.RuneInfo[temp.Rune])
	AAC_BrowseUsableButton:SetChecked(temp.Usable)
	AAC.Browse.SelectedCategory[1] = temp.Category1
	AAC.Browse.SelectedCategory[2] = temp.Category2
	AAC.Browse.SelectedCategory[3] = temp.Category3
	AAC_BrowseFilterPPUButton:SetChecked(temp.PPU)
	AAC_BrowseFilterBidButton:SetChecked(temp.Bid)
	AAC_BrowseFilterMinPriceEditBox:SetText(temp.MinPrice)
	AAC_BrowseFilterMaxPriceEditBox:SetText(temp.MaxPrice)
	AAC_BrowseFilter1EditBox:SetText(temp.Filter1)
	AAC_BrowseFilter2EditBox:SetText(temp.Filter2)
	AAC_BrowseFilter3EditBox:SetText(temp.Filter3)
	AAC_BrowseFilter2OrButton:SetChecked(temp.Or2)
	AAC_BrowseFilter3OrButton:SetChecked(temp.Or3)
	AAC.Browse.CategoryScrollBar_Update()
	AAC.Browse.SearchButton_OnClick()
end

function SavedSearch.RemoveFolder(folder, expand)
	if expand and expand > folder then
		expand = expand - 1
	end
	table.remove(AAC_SavedSearch, folder)
	SavedSearch.Expand[1] = expand
end

StaticPopupDialogs["AAC_SAVEDSEARCH_CREATEFOLDER"] = {
	text = AAC_BROWSE_CREATE_FOLDER_POPUP,
	button1 = TEXT("ACCEPT"),
	button2 = TEXT("CANCEL"),
	OnShow = function(this)
		getglobal(this:GetName().."EditBox"):SetText("")
	end,
	OnAccept = function(this)
        table.insert(AAC_SavedSearch, {["name"] = getglobal(this:GetName().."EditBox"):GetText(), ["contents"] = {},})
        table.insert(AAC_SavedSearch[#(AAC_SavedSearch)]["contents"], SavedSearch.NewItem)
        SavedSearch.ScrollBar_Update()
	end,
	OnCancel = function(this)
		SavedSearch.NewItem = {}
	end,
	hasEditBox = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["AAC_SAVEDSEARCH_CREATEITEM"] = {
	text = AAC_BROWSE_NAME_SEARCH_POPUP,
	button1 = TEXT("ACCEPT"),
	button2 = TEXT("CANCEL"),
	OnShow = function(this)
		getglobal(this:GetName().."EditBox"):SetText("")
	end,
	OnAccept = function(this)
		SavedSearch.CreateItem(getglobal(this:GetName().."EditBox"):GetText())
	end,
	hasEditBox = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["AAC_SAVEDSEARCH_RENAMEITEM"] = {
	text = AAC_BROWSE_RENAME_SAVED_SEARCH_POPUP,
	button1 = TEXT("ACCEPT"),
	button2 = TEXT("CANCEL"),
	OnShow = function(this)
		getglobal(this:GetName().."EditBox"):SetText("")
	end,
	OnAccept = function(this)
		AAC_SavedSearch[SavedSearch.RenameItem[1]]["contents"][SavedSearch.RenameItem[2]]["name"] = getglobal(this:GetName().."EditBox"):GetText()
		SavedSearch.ScrollBar_Update()
	end,
	hasEditBox = 1,
	hideOnEscape = 1,
}