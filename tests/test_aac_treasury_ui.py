from pathlib import Path
import unittest
import xml.etree.ElementTree as ET
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]/'addon/ArcadiaAuctionClassic'
class TreasuryUI(unittest.TestCase):
 def runtime(self):
  l=LuaRuntime();l.execute("""
   TEXT=function(k)return k end
   AAC={Treasury={},Sell={OnShow=function()return 12 end},Main={ClickTab=function()return 13 end},UX={}}
   events={};frame={RegisterEvent=function(self,e)events[#events+1]=e end,Hide=function()hidden=true end}
   StaticPopup_Hide=function()end
   AAC_AuctionFrame={IsVisible=function()return visible end,GetHeight=function()return 600 end}
   AAC_SellFrame={IsVisible=function()return sellVisible end}
  """)
  l.execute((ROOT/'Lua/treasury_ui.lua').read_text(encoding='utf-8-sig'))
  return l
 def test_load_without_setscript_and_xml_dispatch(self):
  l=self.runtime();l.execute('AAC.Treasury.Load(frame);assert(#events==5)')
  tree=ET.parse(ROOT/'Xml/treasury.xml')
  handlers=[e.text for e in tree.iter() if e.tag.split('}')[-1]=='OnUpdate']
  self.assertIn('AAC.Treasury.Update(this,elapsedTime)',handlers)
 def test_update_hide_resize_and_throttle(self):
  l=self.runtime();l.execute("""
   AAC.Treasury.Load(frame);local T=AAC.Treasury
   T.Render=function()renders=(renders or 0)+1;T.height=510 end
   visible=true;sellVisible=false;T.open=true;T.height=420
   T.Update(frame,.2);assert(not renders)
   T.Update(frame,.3);assert(renders==1 and T.open)
   T.Update(frame,.5);assert(renders==1)
   visible=false;T.Update(frame,.5);assert(hidden and not T.open)
   visible=true;sellVisible=true;hidden=false;T.open=true
   T.Update(frame,.5);assert(hidden and not T.open)
  """)
if __name__=='__main__':unittest.main()
