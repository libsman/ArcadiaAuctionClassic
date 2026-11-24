from pathlib import Path
import unittest
import xml.etree.ElementTree as ET
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]/'addon/ArcadiaAuctionClassic/Lua'
class ItemLinkTests(unittest.TestCase):
 def test_selling_tools_cannot_become_buy_orders_through_item_hooks(self):
  l=LuaRuntime()
  l.execute("""calls=0;picks=0;AAC={Main={CurrentTab='SELL'},CanRequest=function()return true end,
   TradingUI={mode='recent',AcceptsItem=function()return false end,PickItem=function()picks=picks+1;return true end}}
   AAC_AuctionFrame={IsVisible=function()return true end};AAC_SellFrame=AAC_AuctionFrame
   function IsShiftKeyDown()return true end
   function ChatEdit_AddItemLink()calls=calls+1;return 'chat' end
   function UseBagItem()error('must not consume a bag item from a selling tool')end
   function GetBagItemLink()return 'item' end
  """)
  l.execute((ROOT/'aac_hooks.lua').read_text(encoding='utf-8'))
  l.execute("""AAC_HookFunctions()
   assert(ChatEdit_AddItemLink('item')=='chat' and picks==0)
   UseBagItem(1);assert(picks==0)
  """)
 def test_search_uses_base_name_without_trailing_equipment_upgrade(self):
  l=LuaRuntime(unpack_returned_tuples=True)
  l.execute("""AAC={Main={CurrentTab='BROWSE'}}
   AAC_AuctionFrame={IsVisible=function() return true end};AAC_BrowseFrame=AAC_AuctionFrame
   AAC_BrowseNameEditBox={SetText=function(s,n) result=n end}
   function IsShiftKeyDown() return true end
   function ParseHyperlink(link) return 'item','ab',link end
  """)
  l.execute((ROOT/'aac_hooks.lua').read_text(encoding='utf-8-sig'))
  l.execute('AAC_HookFunctions()')
  for item,expected in [('Lanze der Fraktur +20','Lanze der Fraktur'),('Armor +12','Armor'),
                        ('Ring +1','Ring'),('Épée +30','Épée'),('Waffe +20  ','Waffe'),
                        ('Manastein-Grad 7','Manastein-Grad 7'),('Rune +20 Bonus','Rune +20 Bonus'),
                        ('A+B','A+B'),('Lanze der Fraktur','Lanze der Fraktur')]:
   with self.subTest(item=item):
    self.assertTrue(l.globals().AAC.TrySearchItemLink(item))
    self.assertEqual(l.globals().result,expected)
 def test_link_action_only_fills_visible_search_and_preserves_fallback(self):
  l=LuaRuntime(unpack_returned_tuples=True)
  l.execute("""visible=true;shift=true;calls=0;AAC={Main={CurrentTab='BROWSE'}}
   AAC_AuctionFrame={IsVisible=function() return visible end};AAC_BrowseFrame={IsVisible=function() return visible end}
   AAC_BrowseNameEditBox={SetText=function(s,n) name=n end}
   function IsShiftKeyDown() return shift end
   function ParseHyperlink(link) if link=='item' then return 'item','ab','Test Item' end return 'player','','Player' end
   function ChatEdit_AddItemLink(...) calls=calls+1;return 'fallback' end
  """)
  l.execute((ROOT/'aac_hooks.lua').read_text(encoding='utf-8-sig'))
  l.execute("""AAC_HookFunctions(); assert(ChatEdit_AddItemLink('item')==true and name=='Test Item' and calls==0)
   AAC_HookFunctions();assert(ChatEdit_AddItemLink('player')=='fallback' and calls==1)
   shift=false;assert(ChatEdit_AddItemLink('item')=='fallback' and calls==2)
   shift=true;visible=false;assert(ChatEdit_AddItemLink('item')=='fallback' and calls==3)
   visible=true;AAC.Main.CurrentTab='SELL';assert(ChatEdit_AddItemLink('item')=='fallback' and calls==4)
   AAC.Main.CurrentTab='BROWSE';ITEMLINK_EDITBOX={};assert(ChatEdit_AddItemLink('item')=='fallback' and calls==5)
  """)
 def test_sell_price_is_anchored_to_its_moving_form(self):
  root=ET.parse(ROOT.parent/'Xml/aac_sell.xml').getroot();ns={'u':'https://chroniclesofarcadia.com/'}
  field=next(e for e in root.iter() if e.get('name')=='AAC_SellPriceBuyout')
  anchor=field.find('u:Anchors/u:Anchor',ns)
  self.assertEqual(anchor.get('relativeTo'),'AAC_SellItemFrame')
  offset=anchor.find('u:Offset/u:AbsDimension',ns)
  self.assertEqual((offset.get('x'),offset.get('y')),('209','68'))
if __name__=='__main__':unittest.main()
