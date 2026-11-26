local TEXT=AAC.TreasuryText or TEXT
local T={picked={},mode="per",value=0,page=1,history=false}
AAC.Treasury=T
local function yes(v) return v==true or v==1 end
local function num(v) return tonumber(v) or 0 end
local function err(n) return TEXT("UI_GUILDTREASURY_ERR_"..n) end
function T.Visible()
 local r=GuildHub and GuildHub.RankRoles and GuildHub.RankRoles() or {}
 return IsInGuild() and (r.GuildSales or r.TreasuryView) and true or false
end
function T.CanPay(info)
 local r=GuildHub and GuildHub.RankRoles and GuildHub.RankRoles() or {}
 return T.Visible() and r.GuildSales==true and IsFunctionEnable(9123) and info~=nil and num(info.Result)==0 and yes(info.CanPay) or false
end
function T.ParseAmount(s)
 s=tostring(s or ''):match('^%s*(.-)%s*$')
 if s:match('^%d+$') then return tonumber(s) end
 local head,sep,tail=s:match('^(%d%d?%d?)([., ])(.+)$')
 if not head then return 0 end
 for part in (tail..sep):gmatch('(.-)'..(sep=='.' and '%.' or sep)) do if not part:match('^%d%d%d$') then return 0 end end
 return tonumber(head..tail:gsub('[., ]','')) or 0
end
function T.Plan(info,picked,mode,value)
 local p={list={},each=0,total=0,remainder=0,excluded={}}
 if not info or num(info.Result)~=0 then p.error=err(info and num(info.Result) or 8);return p end
 value=math.floor(num(value));if value<1 then p.error=TEXT("UI_GUILDTREASURY_PICK");return p end
 if value>9007199254740991 or value~=value then p.error=err(10);return p end
 local members={};local limit=num(info.MemberWeekLimit)
 for _,m in ipairs(info.Members or {}) do
  if picked[m.DBID] then
   if yes(m.TenureOK) then members[#members+1]=m else p.excluded[#p.excluded+1]=m.Name end
  end
 end
 while true do
  local each=mode=="split" and (#members>0 and math.floor(value/#members) or 0) or math.min(value,limit)
  local keep={}
  for _,m in ipairs(members) do
   if num(m.WeekReceived)+each<=limit then keep[#keep+1]=m else p.excluded[#p.excluded+1]=m.Name end
  end
  if #keep==#members then p.each=each;break end
  members=keep
 end
 for _,m in ipairs(members) do p.list[#p.list+1]={DBID=m.DBID,Amount=p.each,Name=m.Name} end
 p.total=#p.list*p.each;p.remainder=mode=="split" and value-p.total or 0
 if #p.list==0 or p.each<1 then p.error=TEXT("UI_GUILDTREASURY_PICK")
 elseif #p.list>100 then p.error=err(10)
 elseif p.total>num(info.Balance) then p.error=err(3)
 elseif num(info.WeekPaid)+p.total>num(info.GuildWeekLimit) then p.error=err(5) end
 return p
end
local function guild() return GuildHub and GuildHub.GuildInfo and GuildHub.GuildInfo().GuildID end
local function key(p)
 local s={};for _,m in ipairs(p.list) do s[#s+1]=tostring(m.DBID)..":"..m.Amount end;table.sort(s);return table.concat(s,";")
end
function T.Review()
 local info=GuildHouses_GetTreasury()
 if T.pending or not T.CanPay(info) then return end
 local p=T.Plan(info,T.picked,T.mode,T.value);if p.error then return end
 T.preview={plan=p,guild=guild()};StaticPopup_Show("AAC_TREASURY_PAY")
end
function T.Confirm()
 local q=T.preview;T.preview=nil
 if not q or T.pending or q.guild~=guild() then return end
 local info=GuildHouses_GetTreasury();if not T.CanPay(info) then return end
 local p=T.Plan(info,T.picked,T.mode,T.value)
 if p.error or key(p)~=key(q.plan) then if SendWarningMsg then SendWarningMsg(AAC_MARKET_CHANGED or err(9)) end;return end
 T.pending={guild=q.guild,plan=p};local payload={}
 for _,m in ipairs(p.list) do payload[#payload+1]={DBID=m.DBID,Amount=m.Amount} end
 GuildHouses_TreasuryPayout(payload)
 if T.Render then T.Render() end
end
StaticPopupDialogs.AAC_TREASURY_PAY={text="%s",button1=TEXT("ACCEPT"),button2=TEXT("CANCEL"),hideOnEscape=1,timeout=0,
 OnShow=function(f)
  local p=T.preview and T.preview.plan;if not p then return end
  local names={};for i,m in ipairs(p.list) do if i<=8 then names[#names+1]=m.Name end end;if #p.list>8 then names[#names+1]="… (+"..(#p.list-8)..")" end
  _G[f:GetName().."Text"]:SetText(string.format(TEXT("UI_GUILDTREASURY_CONFIRM"),tostring(p.each),#p.list,tostring(p.total)).."\n"..table.concat(names,", "))
 end,OnAccept=function() T.Confirm() end,OnCancel=function() T.preview=nil end}
function T.Request()
 if not T.Visible() or not IsFunctionEnable(9123) then return end
 GuildHouses_RequestTreasury();GuildHouses_RequestTreasuryLog()
end
function T.Event(event,a,b,c)
 if event=="GUILD_TREASURY_PAYOUT_RESULT" then
  if T.pending then
   if tonumber(a)==nil then return end
   if num(a)==0 and (num(b)~=#T.pending.plan.list or num(c)~=T.pending.plan.total) then return end
   if num(a)==0 then T.picked={};T.value=0;if AAC_TreAmount then AAC_TreAmount:SetText("") end end
   T.pending=nil
   T.status=num(a)==0 and string.format(TEXT("UI_GUILDTREASURY_OK"),tostring(c),num(b)) or err(num(a))
  end
  T.Request()
 end
 if T.open and T.guild~=guild() then T.Close();return end
 if T.Render then T.Render() end
end
