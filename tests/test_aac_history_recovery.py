import unittest
from pathlib import Path
from lupa.lua51 import LuaRuntime
LUA=Path(__file__).resolve().parents[1]/"addon/ArcadiaAuctionClassic/Lua"
class HistoryRecoveryTests(unittest.TestCase):
 def setUp(self):
  self.l=LuaRuntime()
  self.l.execute("""
  now=0;open=true;closing=false;sent={};saved={};shown={};notices={};links={}
  GetTime=function() return now end
  AAC={Events={},CanRequest=function() return open end,Market={
   IsClosing=function() return closing end,Feature=function() return true end,
   Active=function() return false end,Notice=function(s) table.insert(notices,s) end}}
  AuctionItemHistoryRequestByID=function(id) table.insert(sent,id) end
  GetAuctionHistoryItemNums=function() return #links end
  GetAuctionHistoryItemLink=function(i) return links[i] end
  """)
  self.l.execute((LUA/'aac_history.lua').read_text(encoding='utf-8-sig'))
  self.l.execute("""H=AAC.History
  H.Queue_AddHistory=function(id) table.insert(saved,id) end
  H.List_Show=function() table.insert(shown,H.curItem) end
  function ask(id) H.RequestHistoryPopup(0,id);H.Tick(now) end
  function reply(id) links={string.format('|Hitem:%x 0|h[Item]|h',id)};AAC.Events.AUCTION_HISTORY_SHOW() end
  """)
 def test_timeout_retries_once_then_releases(self):
  self.l.execute("""ask(1001);now=5;H.Tick(now);assert(#sent==2)
  now=10;H.Tick(now);assert(not H.RequestPending and #notices==1)
  ask(1002);reply(1002);assert(shown[1]==1002)""")
 def test_late_foreign_or_mixed_rows_leave_current_request_pending(self):
  self.l.execute("""ask(1001);now=4;ask(1002);now=5;H.Tick(now)
  assert(sent[2]==1002);reply(1001);assert(#saved==0 and H.RequestPending.itemid==1002)
  links={'|Hitem:3ea|h[B]|h','|Hitem:3e9|h[A]|h'};AAC.Events.AUCTION_HISTORY_SHOW()
  assert(#saved==0 and H.RequestPending.itemid==1002)
  reply(1002);assert(saved[1]==1002 and shown[1]==1002)""")
 def test_close_without_reply_recovers_without_resending(self):
  self.l.execute("""ask(1001);H.PrepareClose();open=false;now=6;H.Tick(now)
  assert(not H.RequestPending and #sent==1 and #notices==0)
  open=true;ask(1002);reply(1001);reply(1002);assert(shown[1]==1002)""")
 def test_empty_and_unreadable_replies_never_publish_prices(self):
  self.l.execute("""ask(1001);links={'garbage'};AAC.Events.AUCTION_HISTORY_SHOW()
  assert(H.RequestPending and #saved==0)
  links={};AAC.Events.AUCTION_HISTORY_HIDE();assert(not H.RequestPending and #saved==0)
  now=2;ask(1002);reply(1002);assert(shown[1]==1002)""")
 def test_background_timeout_is_silent_and_continues(self):
  self.l.execute("""H.Queue_Insertitem(0,'A','link',1001);H.Queue_Insertitem(0,'B','link',1002)
  H.Tick(0);now=5;H.Tick(now);assert(sent[2]==1002 and #notices==0)
  reply(1002);assert(saved[1]==1002)""")
 def test_browse_specific_history_checks_original_link_before_request(self):
  self.l.execute("""local link='|Hitem:3e9 0|h[A]|h'
  GetAuctionBrowseItemLink=function() return link end
  AuctionBrowseHistoryRequest=function(index,stats) assert(index==7 and stats);specific=true end
  H.RequestHistoryPopup(7,1001,nil,false,link);H.Tick(now);assert(specific and #sent==0)
  AAC.Events.AUCTION_HISTORY_HIDE();now=2;specific=false
  H.RequestHistoryPopup(7,1001,nil,false,link);link='|Hitem:3ea|h[B]|h';H.Tick(now)
  assert(not specific and sent[1]==1001)""")
 def test_sell_specific_history_does_not_follow_changed_slot_on_retry(self):
  self.l.execute("""AAC.Sell={};slot='|Hitem:3e9|h[A]|h'
  GetAuctionItemLink=function() return slot end
  AuctionItemHistoryRequest=function() specific=(specific or 0)+1 end
  H.RequestHistoryPopup(nil,1001,nil,true);H.Tick(now);assert(specific==1)
  slot='|Hitem:3ea|h[B]|h';now=5;H.Tick(now)
  assert(specific==1 and sent[1]==1001)""")
 def test_same_base_id_different_stat_reply_is_rejected(self):
  self.l.execute("""local a='|Hitem:3e9 0 abc 123 0 0 0 0 0 0 0 def 3e9|h[Stone]|h'
  local b='|Hitem:3e9 0 abc 456 0 0 0 0 0 0 0 def 3e9|h[Stone]|h'
  GetObjectInfo=function() return 0,1 end
  GetAuctionBrowseItemLink=function() return a end
  AuctionBrowseHistoryRequest=function() end
  H.RequestHistoryPopup(7,1001,nil,false,a);H.Tick(now)
  links={b};AAC.Events.AUCTION_HISTORY_SHOW();assert(H.RequestPending and #saved==0)
  links={a};AAC.Events.AUCTION_HISTORY_SHOW();assert(not H.RequestPending and saved[1]==1001)
  """)
if __name__=='__main__': unittest.main()
