import unittest
from pathlib import Path
from lupa.lua51 import LuaRuntime
class TreasuryTests(unittest.TestCase):
 def setUp(self):
  self.l=LuaRuntime(unpack_returned_tuples=True);self.l.execute("AAC={}; TEXT=function(k) return k end; StaticPopupDialogs={}; IsInGuild=function() return true end; IsFunctionEnable=function() return true end; GuildHub={RankRoles=function() return {GuildSales=true} end,GuildInfo=function() return {GuildID=42} end}; info={Result=0,CanPay=true,Balance=1000,MemberWeekLimit=100,GuildWeekLimit=1000,WeekPaid=0,Members={{DBID=1,Name='A',TenureOK=true,WeekReceived=0},{DBID=2,Name='B',TenureOK=true,WeekReceived=80}}}; GuildHouses_GetTreasury=function() return info end; GuildHouses_TreasuryPayout=function(v) sent=v end; StaticPopup_Show=function() end")
  self.l.execute(Path('addon/ArcadiaAuctionClassic/Lua/treasury.lua').read_text(encoding='utf-8'))
 def test_split_excludes_and_recalculates(self):
  self.assertEqual(self.l.execute("local p=AAC.Treasury.Plan(info,{[1]=true,[2]=true},'split',100);return #p.list,p.each,p.total"),(1,100,100))
 def test_remainder(self):
  self.assertEqual(self.l.execute("info.Members[2].WeekReceived=0;local p=AAC.Treasury.Plan(info,{[1]=true,[2]=true},'split',101);return p.each,p.total,p.remainder"),(50,100,1))
 def test_insufficient(self):
  self.assertTrue(self.l.execute("info.Balance=5;return AAC.Treasury.Plan(info,{[1]=true},'per',10).error~=nil"))
 def test_no_right(self):
  self.assertFalse(self.l.execute("info.CanPay=false;return AAC.Treasury.CanPay(info)"))
 def test_confirmation_stale(self):
  self.assertIsNone(self.l.execute("local T=AAC.Treasury;T.picked={[1]=true};T.value=10;T.Review();info.Members[1].WeekReceived=100;T.Confirm();return sent"))
 def test_no_double_submission(self):
  self.assertTrue(self.l.execute("local T=AAC.Treasury;T.picked={[1]=true};T.value=10;T.Review();T.Confirm();local a=sent;sent=nil;T.Confirm();return a~=nil and sent==nil"))
 def test_tenure_and_week_limit(self):
  self.assertTrue(self.l.execute("info.Members[1].TenureOK=false;return AAC.Treasury.Plan(info,{[1]=true},'per',10).error~=nil"))
 def test_guild_limit(self):
  self.assertTrue(self.l.execute("info.WeekPaid=999;return AAC.Treasury.Plan(info,{[1]=true},'per',10).error~=nil"))
 def test_guild_change_cancels(self):
  self.assertIsNone(self.l.execute("local T=AAC.Treasury;T.picked={[1]=true};T.value=10;T.Review();GuildHub.GuildInfo=function() return {GuildID=99} end;T.Confirm();return sent"))
 def test_right_revoked_after_preview(self):
  self.assertIsNone(self.l.execute("local T=AAC.Treasury;T.picked={[1]=true};T.value=10;T.Review();info.CanPay=false;T.Confirm();return sent"))
 def test_recipient_cap(self):
  self.assertTrue(self.l.execute("local picked={};info.Members={};for i=1,101 do info.Members[i]={DBID=i,TenureOK=true};picked[i]=true end;return AAC.Treasury.Plan(info,picked,'per',1).error~=nil"))
 def test_missing_reply_keeps_pending(self):
  self.assertTrue(self.l.execute("local T=AAC.Treasury;T.picked={[1]=true};T.value=10;T.Review();T.Confirm();T.Event('GUILD_TREASURY_PAYOUT_RESULT',nil);return T.pending~=nil"))
 def test_wrong_response_keeps_pending(self):
  self.assertTrue(self.l.execute("local T=AAC.Treasury;T.picked={[1]=true};T.value=10;T.Review();T.Confirm();T.Event('GUILD_TREASURY_PAYOUT_RESULT',0,9,900);return T.pending~=nil"))
 def test_amount_input(self):
  self.assertEqual(self.l.execute("local p=AAC.Treasury.ParseAmount;return p('1000'),p('1.000'),p('1,000'),p('1 000'),p('1.5'),p('1.00'),p('-1')"),(1000,1000,1000,1000,0,0,0))
 def test_locale_formats(self):
  source=Path('addon/ArcadiaAuctionClassic/Lua/treasury_locale.lua').read_text(encoding='utf-8-sig')
  for lang in ['EN','DE','FR','ES','PL','RU','TR','JP','KR','CN','TW']:
   self.l.execute('GetLanguage=function() return "'+lang+'" end');self.l.execute(source)
   self.assertTrue(self.l.execute("return string.format(AAC.TreasuryText('UI_GUILDTREASURY_CONFIRM'),'100',2,'200')~=nil"))
if __name__=='__main__' :unittest.main()
