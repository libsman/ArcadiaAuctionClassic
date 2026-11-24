-- Scoped inventory/search convenience; item links outside visible Browse retain native behavior.
local function TrySearchItemLink(link)
    if not link or ITEMLINK_EDITBOX or not IsShiftKeyDown() or not AAC.Main or AAC.Main.CurrentTab~="BROWSE"
        or not AAC_AuctionFrame or not AAC_AuctionFrame:IsVisible()
        or not AAC_BrowseFrame or not AAC_BrowseFrame:IsVisible() then return false end
    local kind,_,name=ParseHyperlink(link)
    if kind~="item" or not name or name=="" then return false end
    if AAC.Exchange and AAC.Exchange.context=="browse" then AAC.Exchange.Leave() end
    AAC_BrowseNameEditBox:SetText(name)
    return true
end
function AAC_HookFunctions()
    AAC.TrySearchItemLink=TrySearchItemLink
    if not AAC.linkHooked and type(ChatEdit_AddItemLink)=="function" then
        local originalLink=ChatEdit_AddItemLink
        ChatEdit_AddItemLink=function(link,...)
            if AAC.TrySearchItemLink(link) then return true end
            return originalLink(link,...)
        end
        AAC.linkHooked=true
    end
    if AAC.bagHooked or type(UseBagItem) ~= "function" then return end
    local original = UseBagItem
    UseBagItem = function(index, ...)
        if AAC.CanRequest() and AAC_SellFrame and AAC_SellFrame:IsVisible() then
            if AAC.Sell.CanAuctionBagItem(index) == false then
                AAC.Sell.ShowInvalidAuctionItemWarning()
                return
            end
            if AAC.Market and AAC.Market.TransactionPending and AAC.Market.TransactionPending() then return end
            ClickAuctionItemButton()
            ItemClipboard_Clear()
            PickupBagItem(index)
            AAC.Sell.TryPlaceCursorItem()
            return
        end
        return original(index, ...)
    end
    AAC.bagHooked = true
end
