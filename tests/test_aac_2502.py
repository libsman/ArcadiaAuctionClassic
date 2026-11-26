from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]/"addon/ArcadiaAuctionClassic"
class PatchTests(unittest.TestCase):
 def runtime(self):
  lua=LuaRuntime()
  lua.execute("AAC={}; StaticPopupDialogs={}; function TEXT(k)return k end")
  path=ROOT/"Lua/own_batch.lua"
  self.assertTrue(path.exists(), "own-auction batch module missing")
  lua.execute(path.read_bytes())
  lua.execute("""
rows={
 {name='A',count=2,link='a',bidder='',mode='copper',bid=0,price=100,left=100,promote=0,promoteTime=0,fee=0,relist=500},
 {name='B',count=1,link='b',bidder='',mode='account',bid=0,price=20,left=100,promote=0,promoteTime=0,fee=500,relist=500}}
GetAuctionNumSellItems=function()return #rows end
GetAuctionSellItemInfo=function(i)local r=rows[i];if r then return r.name,r.count,0,'icon',1,r.left,r.bidder,r.mode,r.bid,r.price,r.promote,r.promoteTime,false,r.fee,r.relist end end
GetAuctionSellItemLink=function(i)return rows[i] and rows[i].link end
Auction_ExtendPrice=function(i,t)return 10 end
Auction_PromoteSellPrice=function(i,t,d)return 3 end
CanAuctionPromoteSell=function()return true end
GetPlayerMoney=function()return 10000 end
AAC.CanRequest=function()return true end
AAC.SessionGeneration=1
AAC.Sell={GetDurationMinutes=function(t)return t*1440 end,GetMaxDurationMinutes=function()return 100000 end,
 CanPromoteSelection=function()return true end}
AAC.Market={Blocked=function()return false end,HasConfirmation=function()return false end,
 TransactionPending=function()return pending~=nil end,Changed=function()changed=true end,
 Feature=function()return true end,Submit=function(kind,observe,send)pending=observe;send();return true end}
AuctionCancelSell=function(i)sent=(sent or 0)+1;table.remove(rows,i)end
AuctionExtendSell=function(i,t)sent=(sent or 0)+1; rows[i].left=rows[i].left+t*1440 end
AuctionPromoteSell=function(i,t,d)sent=(sent or 0)+1;rows[i].promote=t;rows[i].promoteTime=d*1440 end
function acknowledge()assert(pending());pending=nil;AAC.OwnBatch.Tick()end
""")
  return lua
 def test_cancel_reverse_order_only_selected_and_no_send_before_confirm(self):
  l=self.runtime();l.execute("""
local b=AAC.OwnBatch;b.selected={[1]=true,[2]=true};b.selectionRows=b.Read();local q=b.Quote('cancel',1,1)
assert(#q.items==2 and sent==nil);assert(q.warningCount==1)
b.Start(q);assert(sent==1 and rows[1].name=='A');acknowledge();assert(sent==2 and #rows==0);acknowledge();assert(not b.running)
""")
 def test_changed_quote_never_sends(self):
  l=self.runtime();l.execute("""
local b=AAC.OwnBatch;b.selected={[1]=true};b.selectionRows=b.Read();local q=b.Quote('cancel',1,1);rows[1].price=999;b.Start(q);assert(not sent)
""")
 def test_bid_arrival_stops_remaining_batch(self):
  l=self.runtime();l.execute("""
local b=AAC.OwnBatch;b.selected={[1]=true,[2]=true};b.selectionRows=b.Read();local q=b.Quote('extend',1,1);b.Start(q);assert(sent==1)
rows[1].bidder='another player';assert(not pending());pending=nil;b.Tick();assert(sent==1 and not b.running)
""")
 def test_timeout_does_not_send_next_and_close_stops(self):
  l=self.runtime();l.execute("""
local b=AAC.OwnBatch;b.selected={[1]=true,[2]=true};b.selectionRows=b.Read();local q=b.Quote('extend',1,1);b.Start(q);pending=nil;b.Tick();assert(sent==1 and not b.running)
b.selected={[1]=true};b.selectionRows=b.Read();b.Start(b.Quote('extend',1,1));b.Close();if pending then pending()end;pending=nil;b.Tick();assert(sent==2)
""")
 def test_price_increase_and_insufficient_balance(self):
  l=self.runtime();l.execute("""
local b=AAC.OwnBatch;b.selected={[1]=true};b.selectionRows=b.Read();local q=b.Quote('extend',1,1)
Auction_ExtendPrice=function()return 11 end;b.Start(q);assert(not sent)
GetPlayerMoney=function()return 0 end;b.Start(b.Quote('extend',1,1));assert(not sent)
""")
 def test_fee_warning_and_unknown_rates(self):
  l=self.runtime();l.execute("""
local b=AAC.OwnBatch;assert(b.FeeRises({feeRate=0,relistFeeRate=500}));assert(not b.FeeRises({feeRate=-1,relistFeeRate=500}));assert(not b.FeeRises({feeRate=500,relistFeeRate=500}))
""")

 def test_shifted_list_rejected_before_quote_and_slider_requote(self):
  l=self.runtime();l.execute("""
local b=AAC.OwnBatch;local shown=b.Read();assert(b.Select(1,true,shown));table.remove(rows,1)
assert(b.Quote('cancel',1,1)==nil);assert(not b.Select(1,true,shown));assert(not sent)
""")
 def test_missing_extension_price_cannot_fall_back_to_promotion(self):
  l=self.runtime();l.execute("""
local b=AAC.OwnBatch;b.selected={[1]=true};b.selectionRows=b.Read()
Auction_ExtendPrice=function()return nil end;local q=b.Quote('extend',1,1)
assert(#q.items==0 and q.skipped==1);b.Start(q);assert(not sent)
""")
 def test_server_promotion_denial_excludes_row(self):
  l=self.runtime();l.execute("""
local b=AAC.OwnBatch;b.selected={[1]=true};b.selectionRows=b.Read()
CanAuctionPromoteSell=function()return false end;local q=b.Quote('promote',1,1);assert(#q.items==0)
""")
 def test_identical_cancellations_cannot_be_observed_unambiguously(self):
  l=self.runtime();l.execute("""
local b=AAC.OwnBatch;local c={};for k,v in pairs(rows[1])do c[k]=v end;rows[2]=c
b.selected={[1]=true,[2]=true};b.selectionRows=b.Read();local q=b.Quote('cancel',1,1)
assert(#q.items==0 and q.skipped==2)
""")
 def test_same_tier_promotion_must_change_remaining_time(self):
  l=self.runtime();l.execute("""
local b=AAC.OwnBatch;rows[1].promote=1;rows[1].promoteTime=20
assert(not b.SameList(b.Read(),b.Read(),'promote',1,1,1))
""")

 def test_live_tooltip_link_flags_do_not_change_offer_identity(self):
  l=self.runtime();l.execute("""
local b=AAC.OwnBatch
rows[1].link='|Hitem:386af 3 76000a6a d64d 0 0 0 0 0 0 19e10 e1d4 386af 000000|h|cffc805f8[Krynors Schuhe]|r|h'
local shown=b.Read()
rows[1].link='|Hitem:386af 3 3000a6a d64d 0 0 0 0 0 0 19e10 d2ed 386af 000000|h|cffc805f8[Krynors Schuhe]|r|h'
assert(b.Select(1,true,shown))
rows[1].link=rows[1].link:gsub('d64d','d64e');assert(not b.SameList(shown,b.Read()))
""")
