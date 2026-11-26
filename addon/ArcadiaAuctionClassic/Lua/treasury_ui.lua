local TEXT=AAC.TreasuryText or TEXT
local T=AAC.Treasury
local function n(v) return tonumber(v) or 0 end
local function fmt(v) return AAC.UX.Number(math.floor(n(v)),false) end
local function money(v) return fmt(v) end
local function txt(k) return TEXT(k) end
function T.Close()
 T.open=false;T.preview=nil;StaticPopup_Hide('AAC_TREASURY_PAY');AAC_TreasuryFrame:Hide()
 if AAC_AuctionFrame:IsVisible() then AAC.Main.ClickTab(3) end
end
function T.Open()
 if not T.Visible() then return end
 T.guild=GuildHub.GuildInfo().GuildID;T.open=true;T.history=false;T.page=1;T.status=nil
 AAC_SellFrame:Hide();AAC_SellEditBox:Hide();AAC_TreasuryFrame:SetFrameLevel(AAC_SellFrame:GetFrameLevel()+5);AAC_TreasuryFrame:Show();T.Request();T.Render()
end
function T.ChangeMode(mode)
 local p=T.Plan(GuildHouses_GetTreasury(),T.picked,T.mode,T.value)
 T.status=nil;T.mode=mode;T.value=mode=='per' and p.each or p.total;AAC_TreAmount:SetText(T.value>0 and tostring(T.value) or '');T.Render()
end
function T.ToggleHistory() T.history=not T.history;T.page=1;T.Render() end
function T.Pick(i)
 if T.pending or T.history or not T.CanPay(GuildHouses_GetTreasury()) then return end
 local m=T.rows and T.rows[i];if not m then return end
 if not(m.TenureOK==true or m.TenureOK==1) then return end
 T.status=nil;T.picked[m.DBID]=not T.picked[m.DBID];T.Render()
end
function T.Render()
 if AAC_TreEntry then AAC_TreEntry:SetVisible(T.Visible()) end
 if not T.open or not AAC_TreasuryFrame then return end
 local info=GuildHouses_GetTreasury();local loaded=info and n(info.Result)==0 and IsFunctionEnable(9123) and T.Visible()
 local can=loaded and T.CanPay(info) and not T.pending
 local height=math.max(420,AAC_AuctionFrame:GetHeight()-90)
 T.height=height;AAC_TreasuryFrame:SetSize(800,height)
 local count=math.min(16,math.max(4,math.floor((height-280)/32)))
 T.count=count
 AAC_TreTitle:SetText(txt('UI_GUILDTREASURY_TITLE'));AAC_TreTitle:ClearAllAnchors();AAC_TreTitle:SetAnchor('TOPLEFT','TOPLEFT',AAC_TreasuryFrame,30,0);AAC_TreTitleIcon:ClearAllAnchors();AAC_TreTitleIcon:SetAnchor('TOPLEFT','TOPLEFT',AAC_TreasuryFrame,8,6)
 AAC_TreBack:SetText(AAC.TradingTranslations.back or 'Back');AAC_TreHistory:SetText(txt(T.history and 'UI_GUILDTREASURY_PAY_TO' or 'UI_GUILDTREASURY_LOG'))
 AAC_TreSummary:SetText(loaded and (txt('UI_GUILDTREASURY_BALANCE')..': '..money(info.Balance)..'     '..txt('UI_GUILDTREASURY_INCOME7')..': '..money(info.Income7d)..'\n'..txt('UI_GUILDTREASURY_PAID_WEEK')..': '..money(info.WeekPaid)..' / '..money(info.GuildWeekLimit)) or txt('AF_HOUSES_LOADING'))
 local reset=loaded and math.max(0,n(info.WeekResetTime)-(GuildHub.Now and GuildHub.Now() or 0)) or 0
 AAC_TreLimits:SetText(loaded and (string.format(txt('UI_GUILDTREASURY_LIMITS'),fmt(info.MemberWeekLimit),n(info.MinTenureDays))..'  '..string.format(txt('UI_GUILDTREASURY_RESETS'),GuildHub.Age and GuildHub.Age(reset) or fmt(reset))) or '')
 AAC_TrePer:SetText(txt('UI_GUILDTREASURY_PER_MEMBER'));AAC_TreSplit:SetText(txt('UI_GUILDTREASURY_SPLIT'));AAC_TrePay:SetText(txt('UI_GUILDTREASURY_PAYOUT'))
 AAC_TrePer:SetEnable(can and T.mode~='per');AAC_TreSplit:SetEnable(can and T.mode~='split');AAC_TreAmount:SetEnable(can)
 for _,f in ipairs({AAC_TrePer,AAC_TreSplit,AAC_TreAmount,AAC_TrePay}) do f:SetVisible(not T.history and loaded and T.CanPay(info)) end
 AAC_TreSearchLabel:SetText(txt('UI_GUILDTREASURY_SEARCH'))
 AAC_TreSearch:SetVisible(not T.history);AAC_TreSearchLabel:SetVisible(not T.history)
 local p=T.Plan(loaded and info or nil,T.picked,T.mode,T.value)
 local data={};local search=string.lower(AAC_TreSearch:GetText() or '')
 if loaded then
  if T.history then data=GuildHouses_GetTreasuryLog() or {}
  else for _,m in ipairs(info.Members or {}) do if search=='' or string.find(string.lower(m.Name or ''),search,1,true) then data[#data+1]=m end end end
 end
 T.page=math.max(1,math.min(T.page,math.max(1,math.ceil(#data/count))))
 T.rows={}
 local all=#data>0;for _,m in ipairs(data) do if not T.history and (m.TenureOK==true or m.TenureOK==1) and not T.picked[m.DBID] then all=false end end;AAC_TreAll:SetChecked(all and not T.history)
 AAC_TreColumns:SetText(T.history and (txt('RANKING_STR_TIME')..' / '..txt('UI_GUILDHUB_COL_ACTION')) or txt('IM_SORT_NAME'));AAC_TreWeekHead:SetText(T.history and '' or txt('AF_RESETHUB_SUM_WEEK'));AAC_TreShareHead:SetText(T.history and '' or txt('UI_GUILDTREASURY_PAYOUT'));AAC_TreAmountHead:SetText(txt('SYS_MONEY_TYPE_1'));AAC_TreAmountHead:SetVisible(not T.history and loaded and T.CanPay(info))
 local byid={};for _,m in ipairs(p.list) do byid[m.DBID]=m.Amount end
 for i=1,16 do
  local row=_G['AAC_TreRow'..i];local label=_G[row:GetName()..'Text'];local check=_G[row:GetName()..'Check']
  local m=i<=count and data[(T.page-1)*count+i] or nil;row:SetVisible(m~=nil);T.rows[i]=m
  if m then
   _G[row:GetName()..'Week']:SetVisible(not T.history);_G[row:GetName()..'Share']:SetVisible(not T.history);_G[row:GetName()..'Icon']:SetVisible(not T.history);label:SetWidth(T.history and 748 or 255)
   check:SetVisible(not T.history and T.CanPay(info));check:SetChecked(not T.history and T.picked[m.DBID]==true);check:SetEnable(can)
   if T.history then
    local kind=n(m.Type);local detail=m.TargetName or ''
    if kind==1 and n(m.ItemID)>0 then detail=txt('Sys'..m.ItemID..'_name')..' x'..fmt(m.ItemCount) end
    label:SetText((GuildHub.Age and GuildHub.Age(math.max(0,(GuildHub.Now and GuildHub.Now() or 0)-n(m.Time))) or '')..'  '..txt('UI_GUILDTREASURY_LOG_'..kind)..'  '..(m.ActorName or '')..'  '..detail..'  '..(kind==1 and '+' or '-')..money(m.Amount))
   else
    local reason=''
    if not(m.TenureOK==true or m.TenureOK==1) then reason=string.format(txt('UI_GUILDTREASURY_UNDER_DAYS'),n(info.MinTenureDays))
    elseif n(m.WeekReceived)+(p.each>0 and p.each or 1)>n(info.MemberWeekLimit) then reason=txt('UI_GUILDTREASURY_WEEKLY_LIMIT') end
    label:SetText(m.Name or '');_G[row:GetName()..'Week']:SetText(money(m.WeekReceived));_G[row:GetName()..'Share']:SetText(reason~='' and reason or (byid[m.DBID] and money(byid[m.DBID]) or '-'))
   end
  end
 end
 AAC_TrePage:SetText(T.page..' / '..math.max(1,math.ceil(#data/count)))
 AAC_TrePrev:SetEnable(T.page>1);AAC_TreNext:SetEnable(T.page*count<#data)
 local bottom=206+count*32
 if loaded and #data==0 then AAC_TreStatus:SetText(txt(T.history and 'UI_GUILDTREASURY_LOG_EMPTY' or 'UI_GUILDTREASURY_NO_MEMBERS')) end
 for _,v in ipairs({{AAC_TrePrev,8},{AAC_TrePage,60},{AAC_TreNext,140}}) do v[1]:ClearAllAnchors();v[1]:SetAnchor('TOPLEFT','TOPLEFT',AAC_TreasuryFrame,v[2],bottom) end
 AAC_TreStatus:ClearAllAnchors();AAC_TreStatus:SetAnchor('TOPLEFT','TOPLEFT',AAC_TreasuryFrame,8,bottom+30)
 AAC_TreAll:SetVisible(not T.history and can);local status=T.status or ''
 if not T.Visible() then status=txt('UI_GUILDTREASURY_ERR_2')
 elseif not IsFunctionEnable(9123) then status=txt('UI_GUILDHUB_CURRENTLY_UNAVAILABLE')
 elseif info and n(info.Result)~=0 then status=txt('UI_GUILDTREASURY_ERR_'..n(info.Result))
 elseif T.pending then status=txt('AF_HOUSES_LOADING')
 elseif loaded and not T.CanPay(info) then status=txt('UI_GUILDTREASURY_VIEW_ONLY')
 elseif T.status then status=T.status
 elseif loaded and not T.history then
  status=p.error or string.format(txt('UI_GUILDTREASURY_CONFIRM'),fmt(p.each),#p.list,fmt(p.total))
  if p.remainder>0 and not p.error then status=status..'  '..txt('UI_GUILDTREASURY_BALANCE')..': '..money(n(info.Balance)-p.total) end
 end
 if loaded and #data==0 then status=txt(T.history and 'UI_GUILDTREASURY_LOG_EMPTY' or 'UI_GUILDTREASURY_NO_MEMBERS') end
 AAC_TreStatus:SetText(status);AAC_TrePay:SetEnable(can and not p.error)
end
function T.SelectAll()
 local info=GuildHouses_GetTreasury();if T.pending or not T.CanPay(info) then return end
 local on=AAC_TreAll:IsChecked();local search=string.lower(AAC_TreSearch:GetText() or '')
 for _,m in ipairs(info.Members or {}) do
  if (m.TenureOK==true or m.TenureOK==1) and n(m.WeekReceived)<n(info.MemberWeekLimit) and (search=='' or string.find(string.lower(m.Name or ''),search,1,true)) then T.picked[m.DBID]=on end
 end
 T.Render()
end
function T.Load(frame)
 for _,e in ipairs({'GUILD_TREASURY_INFO','GUILD_TREASURY_LOG','GUILD_TREASURY_PAYOUT_RESULT','UPDATE_GUILD_INFO','GUILDHOUSES_SUMMARY_UPDATED'}) do frame:RegisterEvent(e) end
 local old=AAC.Sell.OnShow
 AAC.Sell.OnShow=function(...) local r=old(...);if not T.open then T.Render() end;return r end
 local click=AAC.Main.ClickTab
 AAC.Main.ClickTab=function(...)
  T.open=false;T.preview=nil;StaticPopup_Hide('AAC_TREASURY_PAY');frame:Hide();return click(...)
 end
 local elapsed=0
 frame:SetScript('OnUpdate',function(_,dt)
  elapsed=elapsed+(tonumber(dt) or 0.1);if elapsed<0.5 then return end;elapsed=0
  if T.open and (not AAC_AuctionFrame:IsVisible() or AAC_SellFrame:IsVisible()) then T.open=false;frame:Hide()
  elseif T.open and T.height~=math.max(420,AAC_AuctionFrame:GetHeight()-90) then T.Render() end
 end)
end
