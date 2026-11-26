local B=AAC.OwnBatch
local t=AAC.Patch2502.text
function B.Count()
    local n=0;for _ in pairs(B.selected) do n=n+1 end;return n
end
function B.Toggle(frame)
    if B.running then return end
    local index=frame:GetParent().auctionid
    local displayed={}
    for _,row in ipairs(AAC_AuctionSellList.list or {}) do displayed[row.realPosition]=row end
    if not B.Select(index,frame:IsChecked(),displayed) then AAC.Market.Changed() end
    AAC.Sell.List_SetSelected(AAC_AuctionSellList.selected)
end
function B.Render()
    local n=B.Count()
    local displayed={}
    for _,row in ipairs(AAC_AuctionSellList.list or {}) do displayed[row.realPosition]=row end
    for i=1,AAC.Sell.MAXITEMS do
        local button=_G["AAC_SellListItem"..i]
        local check=_G["AAC_SellListItem"..i.."Batch"]
        if check and button then
            check:SetChecked(B.selected[button.auctionid]==true)
            local row=displayed[button.auctionid]
            check:SetEnable(not B.running and row~=nil and (not row.bidder or row.bidder==""))
        end
    end
    if AAC_SellNumberLabel then AAC_SellNumberLabel:SetText(n>0 and string.format(t.selected,n) or AAC_SELL_NUM_AUCTION) end
    if n>0 or B.running then
        AAC_SellListCancelButton:SetEnable(not B.running)
        AAC_SellListProlongButton:SetEnable(not B.running)
        AAC_SellListPromoteButton:SetEnable(not B.running and AAC.Market.Feature("Promotion"))
    end
end
local actions={cancel=AUCTION_CANCEL_SELL,extend=AUCTION_PROLONG_SELL,promote=AUCTION_PROMOTE_SELL}
function B.UpdateDialog(dialog)
    local p=B.preview;if not p then return end
    local q=B.Quote(p.kind,p.arg,p.duration);p.quote=q
    if not q then
        _G[dialog:GetName().."Text"]:SetText(AAC_MARKET_CHANGED)
        _G[dialog:GetName().."Button1"]:Disable();return
    end
    local lines={actions[p.kind],string.format(t.selected,#q.items)}
    if p.kind~="cancel" then lines[#lines+1]=t.cost..": "..AAC.BuyOrders.Money(q.total,q.mode) end
    if q.skipped>0 then lines[#lines+1]=string.format(t.skipped,q.skipped) end
    if q.warningCount>0 then lines[#lines+1]=string.format(t.feeWarning,q.warningCount) end
    _G[dialog:GetName().."Text"]:SetText(table.concat(lines,"\n"))
    _G[dialog:GetName().."Button1"]:SetEnable(#q.items>0 and q.total<=GetPlayerMoney(q.mode))
end
function B.Open(kind)
    if B.Count()==0 or B.running or B.preview or AAC.Market.Blocked() or AAC.Market.HasConfirmation() then return end
    B.preview={kind=kind,arg=1,duration=1,opened=GetTime()}
    local key="AAC_OWN_BATCH"
    local config=StaticPopupDialogs[key]
    config.hasSlider=kind~="cancel" and 1 or nil
    config.hasSlider2=kind=="promote" and 1 or nil
    if kind=="extend" then
        AAC.Sell.ConfigureSliderDialog(key,1,1,4,AUCTION_DURATION,AAC.Sell.GetDurationText(1),AAC.Sell.GetDurationText(4))
    elseif kind=="promote" then
        AAC.Sell.ConfigureSliderDialog(key,1,1,3,AUCTION_PROMOTETYPES,AAC.Sell.GetPromoteText(1),AAC.Sell.GetPromoteText(3))
        AAC.Sell.ConfigureSlider2Dialog(key,1,1,4,AUCTION_DURATION,AAC.Sell.GetDurationText(1),AAC.Sell.GetDurationText(4))
    end
    StaticPopup_Show(key)
end
StaticPopupDialogs.AAC_OWN_BATCH={text=t.review,button1=TEXT("ACCEPT"),button2=TEXT("CANCEL"),hideOnEscape=1,timeout=0,
    OnShow=function(dialog) B.UpdateDialog(dialog) end,
    OnSliderValueChanged=function(dialog,slider,value)
        if not B.preview then return end
        B.preview.arg=value
        AAC.Sell.SetStaticPopupSliderValue(slider,B.preview.kind=="extend" and AAC.Sell.GetDurationText(value) or AAC.Sell.GetPromoteText(value))
        B.UpdateDialog(dialog)
    end,
    OnSlider2ValueChanged=function(dialog,slider,value)
        if not B.preview then return end
        B.preview.duration=value;AAC.Sell.SetStaticPopupSliderValue(slider,AAC.Sell.GetDurationText(value));B.UpdateDialog(dialog)
    end,
    OnAccept=function()
        local p=B.preview;B.preview=nil
        if p and GetTime()-p.opened<=30 then B.Start(p.quote) end
    end,
    OnCancel=function() B.preview=nil end,OnHide=function() B.preview=nil end}
local oldUpdate=AAC.Sell.List_Update
AAC.Sell.List_Update=function(...)
    if not B.running then B.selected={};B.selectionRows=nil end
    return oldUpdate(...)
end
local oldSelect=AAC.Sell.List_SetSelected
AAC.Sell.List_SetSelected=function(...)
    oldSelect(...);B.Render()
end
for fn,kind in pairs({ListCancelButton_OnClick="cancel",ListProlongButton_OnClick="extend",ListPromoteButton_OnClick="promote"}) do
    local original=AAC.Sell[fn];local action=kind
    AAC.Sell[fn]=function(...)
        if B.running then return end
        if B.Count()>0 then B.Open(action) else return original(...) end
    end
end
local oldTick=AAC.Market.Tick
AAC.Market.Tick=function(...)
    if B.preview and GetTime()-B.preview.opened>30 then
        B.preview=nil;StaticPopup_Hide("AAC_OWN_BATCH")
    end
    oldTick(...);B.Tick()
end
local oldClose=AAC.Market.PrepareClose
AAC.Market.PrepareClose=function(...)
    B.Close();StaticPopup_Hide("AAC_OWN_BATCH");return oldClose(...)
end
local oldReset=AAC.Market.Reset
AAC.Market.Reset=function(...) B.Close();return oldReset(...) end

function AAC.Patch2502.Tooltip(index)
    local row=AAC.Browse.Cache_FindAuction(index)
    if row and row.linkedSeller and (row.buyoutPrice or 0)>0
        and (row.moneyMode=="copper" or row.moneyMode=="account") and IsFunctionEnable(9109) then GameTooltip:AddLine(t.linked,0.4,0.9,0.6) end
end

function AAC.Patch2502.OwnTooltip(index)
    local _,_,_,_,_,_,_,mode,_,gross,_,_,_,rate,relist=GetAuctionSellItemInfo(index)
    if type(rate)=="number" and rate>=0 and type(gross)=="number" and gross>0 then
        local fee=math.min(gross,math.floor(gross*rate/10000))
        GameTooltip:AddLine(AAC.UX.text.fee..": "..string.format("%g%%",rate/100),1,0.85,0.3)
        GameTooltip:AddLine(AAC.UX.text.income..": "..AAC.BuyOrders.Money(gross-fee,mode),1,1,1)
        if B.FeeRises({feeRate=rate,relistFeeRate=relist}) then GameTooltip:AddLine(string.format(t.relist,relist/100),1,0.6,0.3) end
    end
end
