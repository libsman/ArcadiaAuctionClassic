from pathlib import Path
import unittest
import xml.etree.ElementTree as ET
from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]/'addon/ArcadiaAuctionClassic'

class TradingUITests(unittest.TestCase):
    def widgets(self,lua):
        lua.execute('''
            function widget(name)
                return {text='',visible=true,name=name,
                    ClearAllAnchors=function()end, SetAnchor=function(s,...)s.anchor={...}end, SetHeight=function(s,h)s.height=h end, ClearFocus=function()end, SetText=function(s,t)s.text=t end, GetText=function(s)return s.text end,
                    Show=function(s)s.visible=true end, Hide=function(s)s.visible=false end,
                    IsVisible=function(s)return s.visible end, SetChecked=function(s,v)s.checked=v end,
                    Enable=function(s)s.enabled=true end,Disable=function(s)s.enabled=false end,
                    LockHighlight=function(s)s.selected=true end,UnlockHighlight=function(s)s.selected=false end,
                    SetTexCoord=function(s,...)s.coords={...}end, SetTexture=function(s,t)s.texture=t end,SetFile=function(s,t)s.texture=t end}
            end
        ''')
        for e in ET.parse(ROOT/'Xml/aac_trading.xml').iter():
            if e.get('name'):
                name=e.get('name');lua.globals()[name]=lua.eval('widget')(name)

    def test_render_modes_and_fractional_prices_keep_actions_consistent(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
            function GetLanguage()return 'DE' end
            function TEXT(k)return ({SYS_MONEY_TYPE_0='Gold',SYS_MONEY_TYPE_1='Diamanten'})[k] or k end
            function IsAuctionItemAccountMoneyTrade()return true end
            function Auction_BuyOrderPlacementFee(n,p,t)return 1,n*p end
            function GetObjectInfo() return 'icon' end
            AAC={UX={Number=tostring,UnitText=function(r)return tostring(r.buyoutPrice)..' '..r.moneyMode end},Market={Blocked=function()return false end,HasConfirmation=function()return false end},
              BuyOrders={rows={},status='',Money=function(n,m)return tostring(n)..' '..m end},
              Sell={GetDurationText=function()return '7 Tage' end},
              SellerTools={rows={},status='',Recent=function()return {} end}}
        ''')
        lua.execute("AAC.Tools=AAC.Tools or {}")
        lua.execute((ROOT/'Lua/ux.lua').read_text(encoding='utf-8'))
        lua.execute((ROOT/'Lua/trading_ui.lua').read_text(encoding='utf-8'))
        self.widgets(lua)
        lua.execute('''
            AAC.TradingUI.mode='prices';AAC.TradingUI.Render();assert(not AAC_TradingAction.visible)
            AAC.TradingUI.mode='create';AAC.TradingUI.itemID=100
            AAC_TradingQuantity:SetText('50');AAC_TradingPrice:SetText('3');AAC.TradingUI.Render()
            assert(AAC_TradingFormAction.visible and AAC_TradingFormAction.enabled)
            assert(not AAC_TradingPick1.visible and AAC_TradingList.visible and AAC_TradingOwnHeading.visible)
            assert(AAC_TradingList.height==150 and not AAC_TradingRow4.visible)
            assert(AAC_TradingTotals.text:find('150',1,true))
            local r={id=1,itemID=100,name='Food',wanted=50,unitPrice=0.14,mode='account',sellCount=10,net=1}
            AAC.BuyOrders.rows={r};AAC.TradingUI.mode='sellable';AAC.TradingUI.selected=r;AAC.TradingUI.Render()
            assert(AAC_TradingRow1Price.text=='|cff70cfff0,14|r' and AAC_TradingAction.enabled)
            assert(not AAC_TradingRow2Icon.visible)
            assert(not AAC_TradingPrev.visible and not AAC_TradingNext.visible)
            AAC.BuyOrders.status='Item changed';AAC.TradingUI.Render()
            assert(AAC_TradingHint.visible and not AAC_TradingDetail.visible)
            AAC.BuyOrders.status='';AAC.TradingUI.selected=nil;AAC.TradingUI.Render()
            assert(not AAC_TradingAction.visible and AAC_TradingDetail.text=='')
        ''')
    def test_native_layout_and_runtime_texts(self):
        xml=ET.parse(ROOT/'Xml/aac_trading.xml');ns={'u':'https://chroniclesofarcadia.com/'}
        names={e.get('name'):e for e in xml.iter() if e.get('name')}
        self.assertEqual(len([n for n in names if n.startswith('AAC_TradingRow') and n[14:].isdigit()]),7)
        self.assertEqual(names['AAC_TradingGold'].get('inherits'),'MoneyModeRadioButtonTemplate')
        self.assertNotIn('AAC_TradingSearchOrders',names)
        self.assertEqual(names['AAC_TradingSellPrices'].get('parent'),'AAC_SellFrame')
        self.assertNotIn('AAC_TradingSellOrders',names)
        self.assertEqual(names['AAC_TradingPurchasesNav'].get('parent'),'AAC_AuctionFrame')
        self.assertEqual(names['AAC_TradingPanel'].get('parent'),'AAC_AuctionFrame')
        self.assertEqual(names['AAC_TradingPanel'].get('hidden'),'true')
        self.assertNotEqual(names['AAC_TradingPanel'].get('frameStrata'),'HIGH')
        self.assertNotIn('AAC_TradingPrices',names)
        self.assertNotIn('AAC_TradingRecent',names)
        self.assertEqual(names['AAC_TradingBuyers'].tag.split('}')[-1],'CheckButton')
        self.assertIsNotNone(names['AAC_TradingForm'].find('.//u:Button[@name="AAC_TradingFormAction"]',ns))
        self.assertEqual(names['AAC_TradingRow1'].find('u:Size/u:AbsDimension',ns).get('y'),'40')

    def test_drop_area_receives_mouse_and_owns_its_label(self):
        ns={'u':'https://chroniclesofarcadia.com/'}
        root=ET.parse(ROOT/'Xml/aac_trading.xml')
        slot=root.find('.//u:Button[@name="AAC_TradingItemSlot"]',ns)
        self.assertEqual(slot.get('enableMouse'),'true')
        self.assertIsNotNone(slot.find('.//u:FontString[@name="AAC_TradingItemName"]',ns))

    def test_purchases_navigation_keeps_bid_parent_isolated(self):
        lua=LuaRuntime(unpack_returned_tuples=True);self.widgets(lua)
        lua.execute("""function TEXT(k)return k end
            AAC={Main={CurrentTab='BUY'},CanRequest=function()return true end,
            Market={Blocked=function()return blocked or false end,HasConfirmation=function()return false end},
            BuyOrders={Close=function()end,Search=function(mode)searched=mode end},SellerTools={Close=function()end}}
            AAC_BidFrame=widget('bid')
        """)
        lua.execute("AAC.Tools=AAC.Tools or {}")
        lua.execute((ROOT/'Lua/ux.lua').read_text(encoding='utf-8'))
        lua.execute((ROOT/'Lua/trading_ui.lua').read_text(encoding='utf-8'))
        lua.execute("""AAC.TradingUI.Render=function()end
            AAC.TradingUI.PurchaseTabChanged(2)
            assert(AAC_TradingPurchasesNav.visible and AAC_BidFrame.visible)
            AAC.TradingUI.ShowOrders()
            assert(searched=='mine' and not AAC_BidFrame.visible and AAC_TradingPurchasesNav.visible)
            AAC.TradingUI.mode='create';AAC.TradingUI.selected={id=123}
            AAC.TradingUI.Back()
            assert(AAC.TradingUI.mode=='mine' and searched=='mine' and not AAC_BidFrame.visible)
            assert(AAC.TradingUI.selected==nil)
            AAC.TradingUI.ShowBids()
            assert(AAC_BidFrame.visible and not AAC_TradingPanel.visible)
            AAC.TradingUI.PurchaseTabChanged(3)
            assert(not AAC_TradingPurchasesNav.visible)
            blocked=true;searched=nil
            assert(AAC.TradingUI.Open('mine'))
            assert(AAC_TradingPanel.visible and searched==nil)
            AAC.TradingUI.ShowBids()
            assert(AAC_BidFrame.visible and not AAC_TradingPanel.visible)
            blocked=false;AAC.TradingUI.FindTick();assert(searched==nil)
            blocked=true;assert(AAC.TradingUI.Open('mine'))
            blocked=false;AAC.TradingUI.FindTick();assert(searched=='mine')
        """)

    def test_catalog_includes_arcadia_items_beyond_native_range(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute("""AAC={};AuctionHub={ItemIndex={Done=true,Items={}},ItemIndex_Start=function()end}
          function GetObjectInfo(id,...)if id==1250790 then return 0,1,100,0,0,1 end end
          function TEXT(key)if key=='Sys1250790_name' then return 'Konzentrierter Helden-Trank' end return key end
        """)
        lua.execute("AAC.Tools=AAC.Tools or {}")
        lua.execute((ROOT/'Lua/ux.lua').read_text(encoding='utf-8'))
        lua.execute((ROOT/'Lua/trading_ui.lua').read_text(encoding='utf-8'))
        lua.execute("""for i=1,400 do AAC.TradingUI.CatalogStep() end
          local rows=AAC.TradingUI.FindMatches('Konzent')
          assert(#rows==1 and rows[1].ID==1250790)
          for i=1,8 do table.insert(AuctionHub.ItemIndex.Items,{ID=i,Name='Konzent '..i,Lower='konzent '..i}) end
          assert(#AAC.TradingUI.FindMatches('Konzent')==9)
        """)

    def test_item_search_uses_client_index_without_server_trade(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute("""AAC={};AuctionHub={ItemIndex={Done=true,Items={{ID=200001,Name='Helden-Trank',Lower='helden-trank'}}},ItemIndex_Start=function()end}
          function GetObjectInfo()return nil end
          function TEXT(k)return k end
        """)
        lua.execute("AAC.Tools=AAC.Tools or {}")
        lua.execute((ROOT/'Lua/ux.lua').read_text(encoding='utf-8'))
        lua.execute((ROOT/'Lua/trading_ui.lua').read_text(encoding='utf-8'))
        self.widgets(lua)
        lua.execute("""
          AAC.TradingUI.Render=function()end
          AAC.TradingUI.mode='create';AAC_TradingFindText.text='He'
          AAC.TradingUI.FindChanged();AAC.TradingUI.FindTick();assert(not AAC.TradingUI.findDirty)
          AAC_TradingFindText.text='Hel';AAC.TradingUI.FindChanged()
          for i=1,400 do AAC.TradingUI.FindTick() end
          assert(#AAC.TradingUI.findItems==1 and AAC.TradingUI.findItems[1].Name=='Helden-Trank')
          AAC.TradingUI.PickItem=function(link)picked=link;return true end
          AAC.TradingUI.PickFound(1);assert(picked:find('Helden-Trank',1,true))
          assert(AAC.TradingUI.findQuery=='')
        """)

    def test_drop_reads_cursor_link_when_bag_slot_is_empty(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute("""
          AAC={Market={Blocked=function()return false end,HasConfirmation=function()return false end}}
          function CursorHasItem()return true end
          function CursorItemType()return 'bag' end
          function GetCursorItemInfo()return 76 end
          function GetBagItemLink()return nil end
          function GetCursorItemLink()return 'cursor-link' end
          function ItemClipboard_Clear()cleared=true end
        """)
        lua.execute("AAC.Tools=AAC.Tools or {}")
        lua.execute((ROOT/'Lua/ux.lua').read_text(encoding='utf-8'))
        lua.execute((ROOT/'Lua/trading_ui.lua').read_text(encoding='utf-8'))
        lua.execute("""AAC.TradingUI.PickItem=function(link) picked=link;return link=='cursor-link' end
          AAC.TradingUI.Drop();assert(picked=='cursor-link' and cleared)
          cleared=false;AAC.TradingUI.PickItem=function()return false end
          AAC.TradingUI.Drop();assert(not cleared)
        """)

    def test_create_and_select_never_send_and_reopens_controller(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
            calls=0; closed=false; selected=nil
            AAC={CanRequest=function()return true end,Market={Blocked=function()return false end,HasConfirmation=function()return false end},
            BuyOrders={Close=function()closed=true end,Open=function()closed=false;return true end,Search=function()calls=calls+1 end},
            SellerTools={Close=function()end},Browse={List_GetSelected=function()return 1,{itemid=100,name='Food'} end}}
            AAC_TradingPanel={Show=function()end,Hide=function()end}
            AAC.SellerTools.ItemIDFromLink=function(link) return 100 end
            function ParseHyperlink()return 'item','64','Food' end
            AAC_TradingQuantity={SetText=function()end};AAC_TradingPrice={SetText=function()end}
        ''')
        lua.execute("AAC.Tools=AAC.Tools or {}")
        lua.execute((ROOT/'Lua/ux.lua').read_text(encoding='utf-8'))
        lua.execute((ROOT/'Lua/trading_ui.lua').read_text(encoding='utf-8'))
        lua.execute('''AAC.TradingUI.Render=function()end
            AAC.TradingUI.OrdersFromSearch();assert(AAC.TradingUI.searchItem.itemID==100);calls=0
            AAC.TradingUI.NewOrder()
            assert(not closed and AAC.TradingUI.itemID==100 and calls==0)
            AAC.TradingUI.Select({id=5});assert(calls==0)
        ''')

    def test_context_restores_only_visible_contents_and_never_reopens_native_parent(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        self.widgets(lua)
        lua.execute('''
            searches=0
            AAC={CanRequest=function()return true end,
                Market={Blocked=function()return false end,HasConfirmation=function()return false end},
                BuyOrders={Close=function()end,Search=function()searches=searches+1 end},
                SellerTools={Close=function()end,CheckPrices=function()end}}
            AAC_SellFrame=widget('parent');AAC_SellFrame.Show=function()error('must not reopen native parent')end
            AAC_SellAuctionContent=widget('content');AAC_SellMoneyAuction=widget('money')
            AAC_SellExchange=widget('exchange');AAC_SellEditBox=widget('editor')
            AAC_HistoryEditBox=widget('history');AAC_HistoryEditBox:Hide()
            AAC_BrowseFrame=widget('browse');AAC_BrowseFrame:Hide()
        ''')

        lua.execute("AAC.Tools=AAC.Tools or {}")
        lua.execute((ROOT/'Lua/ux.lua').read_text(encoding='utf-8'))
        lua.execute((ROOT/'Lua/trading_ui.lua').read_text(encoding='utf-8'))
        lua.execute('''
            AAC.TradingUI.Render=function()end
            assert(AAC.TradingUI.Open('mine'))
            assert(not AAC_SellAuctionContent.visible and not AAC_TradingSellPrices.visible)
            assert(AAC_SellFrame.visible and AAC_TradingPanel.visible)
            AAC.TradingUI.Close()
            assert(AAC_SellAuctionContent.visible and AAC_TradingSellPrices.visible)
            assert(not AAC_BrowseFrame.visible and not AAC_HistoryEditBox.visible)
            assert(searches==1 and not AAC_TradingPanel.visible)
        ''')

    def test_restoring_native_form_does_not_reset_currency_or_search(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        self.widgets(lua)
        lua.execute('''
            AAC={TradingUI={restoringContents=true},Sell={}}
            Sell=AAC.Sell
            function getglobal(n)return _G[n]end
            function MoneyFrameTemplate_SetMode()end
            AAC_SellMoneyAuction=widget('money');AAC_SellMoneyAuction.checked=true
            AAC_SellMoneyAuction.IsChecked=function(s)return s.checked end
            AAC_SellMoneyModeButton2=widget('mode')
            function Sell.ChangeAuctionType(state) Sell.MoneyAuction=state end
            Sell.MoneyAuction=true
        ''')
        text=(ROOT/'Lua/aac_sell.lua').read_text(encoding='utf-8')
        body=text.split('function Sell.AAC_SellMoneyMode_OnShow',1)[1].split('function Sell.AuctionMoneyTypeChanged',1)[0]
        lua.execute('function Sell.AAC_SellMoneyMode_OnShow'+body)
        lua.execute('''
            Sell.AAC_SellMoneyMode_OnShow({GetName=function()return 'AAC_SellMoneyMode'end})
            assert(Sell.MoneyAuction and AAC_SellMoneyAuction.checked)
        ''')
        ns={'u':'https://chroniclesofarcadia.com/'}
        root=ET.parse(ROOT/'Xml/aac_sell.xml')
        script=root.find('.//u:EditBox[@name="AAC_SellEditBox"]/u:Scripts/u:OnShow',ns).text
        lua.execute('''this=widget('search');this.text='My filter';Sell.MyOffers_OnTextChanged=function()end''')
        lua.execute(script)
        lua.execute("assert(this.text=='My filter')")
    def test_coordinator_and_toc_wire_new_controllers(self):
        toc=(ROOT/'ArcadiaAuctionClassic.toc').read_text()
        for name in ['Lua\\buyorders.lua','Lua\\seller_tools.lua','Lua\\trading_ui.lua','Xml\\aac_trading.xml']:
            self.assertIn(name,toc)
        source=(ROOT/'Lua/session.lua').read_text()
        self.assertIn('AAC.BuyOrders.Event(event, ...)',source)
        self.assertIn('AAC.SellerTools.Event(event)',source)
        self.assertIn('AAC.BuyOrders.Tick()',source)
        self.assertIn('AAC.SellerTools.Tick()',source)
        market=(ROOT/'Lua/aac_custompay.lua').read_text()
        self.assertIn('AAC.BuyOrders.Busy()',market)
        self.assertIn('AAC.BuyOrders.HasConfirmation()',market)

if __name__=='__main__':unittest.main()
