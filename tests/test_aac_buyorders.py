from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

SOURCE = Path(__file__).resolve().parents[1] / 'addon/ArcadiaAuctionClassic/Lua/buyorders.lua'


class BuyOrderTests(unittest.TestCase):
    def test_gross_net_inverse_respects_actual_rounding_and_diamond_minimum(self):
        self.lua.execute('''
          assert(B.NetAmount(105,500,'copper')==100)
          assert(B.GrossUnitForNet(100,1,500,'copper')==105)
          assert(B.NetAmount(1,0,'account')==0)
          assert(B.GrossUnitForNet(1,1,0,'account')==2)
          assert(B.GrossUnitForNet(100,3,500,'copper')==35)
          assert(B.GrossUnitForNet(1,0,500,'copper')==nil)
          assert(B.GrossUnitForNet(1,1,nil,'copper')==nil)
          assert(B.GrossUnitForNet(1,1,10000,'copper')==nil)
          for _,mode in ipairs({'copper','account'}) do
            for _,rate in ipairs({0,250,500,1500}) do
              for _,count in ipairs({1,3,100}) do
                for wanted=1,150 do
                  local p=B.GrossUnitForNet(wanted,count,rate,mode)
                  assert(B.NetAmount(p*count,rate,mode)>=wanted)
                  assert(p==1 or B.NetAmount((p-1)*count,rate,mode)<wanted)
                end
              end
            end
          end
          assert(sends==0)
        ''')

    def test_money_text_uses_client_currency_and_supported_colour_markup(self):
        self.lua.execute('''
            function TEXT(k) return k=='SYS_MONEY_TYPE_1' and 'Diamonds' or 'Gold' end
            assert(B.Money(1500,'account')=='|cff70cfff1500 Diamonds|r')
            assert(B.Money(50,'copper')=='|cffffd45c50 Gold|r')
            assert(not B.Money(10,'account'):find('|T',1,true))
        ''')

    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
            now=0; opened=true; enabled=true; funds=100000; placement=7; escrow=1000
            sends=0; searches=0; pickups=0; feeRate=250; blocked=false; otherDialog=false
            mode='copper'; filled=0; own=false; stackCount=40; stackLink='|Hitem:64:abc|h[Ore]|h'
            bags={[1]={11,40,false,100},[2]={12,70,false,100},[61]={71,200,false,100}}
            AAC={SessionGeneration=1,CanRequest=function() return opened end,
                FeatureEnabled=function() return enabled end,UX={Number=tostring,language='EN'},
                Market={Blocked=function() return blocked end,HasConfirmation=function() return otherDialog end,
                    IsClosing=function() return false end}}
            StaticPopupDialogs={}
            function TEXT(k) return k end
            function GetTime() return now end
            function GetPlayerMoney() return funds end
            function StaticPopup_Show(key,text) dialog=key;dialogText=text end
            function StaticPopup_Hide() end
            function IsAuctionItemAccountMoneyTrade() return true end
            function Auction_BuyOrderPlacementFee(n,p,t) feeType=t;return placement,escrow end
            function AuctionBuyOrderSearch(item,mine,sellable)
                searches=searches+1;queryItem=item;queryMine=mine;querySellable=sellable
            end
            function GetAuctionNumBuyOrders(mine) return 1,1 end
            function GetAuctionBuyOrderInfo(i,mine)
                return 91,100,'Ore','ore.dds',100,filled,10,mode,feeRate,7,600,'Buyer',own
            end
            function GetBagCount() return 0,0,90 end
            function GetBagPageLetTime(page) return page>2,-1 end
            function GetBagItemInfo(pos)
                local b=bags[pos];if b then return b[1],'ore.dds','Ore',b[2],b[3],0,b[4] end
            end
            function GetBagItemLink(index) return stackLink end
            function CursorHasItem() return cursor~=nil end
            function GetAuctionItem() if staged then return 'Ore','ore.dds',staged[2],0 end end
            function GetAuctionItemLink() if staged then return staged.link end end
            function PickupBagItem(index)
                pickups=pickups+1; picked=index
                for pos,b in pairs(bags) do if b[1]==index then cursor=b;cursor.link=stackLink end end
            end
            function ClickAuctionItemButton() staged=cursor;cursor=nil end
            function AuctionBuyOrderSell(id) sends=sends+1;sentID=id;return sendResult end
            function AuctionBuyOrderCreate(item,n,p,t) sends=sends+1;sentItem=item;sentN=n;sentP=p;sentType=t;return sendResult end
            function AuctionBuyOrderCancel(id) sends=sends+1;sentID=id;return sendResult end
            function GetObjectInfo(id,key) if key=='name' then return 'Ore' end end
        ''')
        if SOURCE.exists():
            self.lua.execute(SOURCE.read_text(encoding='utf-8-sig'))
        self.lua.execute("assert(AAC.BuyOrders, 'Buy orders controller is missing'); B=AAC.BuyOrders")

    def runlua(self, code):
        self.lua.execute(code)

    def ready(self, mode='sellable'):
        mine, sellable = str(mode == 'mine').lower(), str(mode == 'sellable').lower()
        self.runlua(f"assert(B.Search('{mode}',0)); B.Event('AUCTION_BUYORDER_LIST_UPDATE',{mine},0,{sellable})")

    def test_search_signature_and_matching_reply(self):
        self.runlua("""assert(B.Search('all',100));assert(queryItem==100 and not queryMine and not querySellable)
            B.Event('AUCTION_BUYORDER_LIST_UPDATE',false,101,false);assert(B.Busy() and #B.rows==0)
            B.Event('AUCTION_BUYORDER_LIST_UPDATE',true,100,false);assert(B.Busy())
            B.Event('AUCTION_BUYORDER_LIST_UPDATE',false,100,false);assert(not B.Busy() and #B.rows==1)
            assert(B.rows[1].wanted==100 and B.rows[1].unitPrice==10 and B.rows[1].sellCount==70)
            assert(B.Search('mine',0)); assert(queryMine and not querySellable)
        """)

    def test_list_timeout_retries_once_then_releases_without_transaction(self):
        self.runlua("""B.Search('sellable',0);now=16;B.Tick();assert(searches==2 and B.Busy())
        now=32;B.Tick();assert(not B.Busy() and sends==0)
        assert(B.Search('all',123));B.Event('AUCTION_BUYORDER_LIST_UPDATE',false,0,true)
        assert(B.query and #B.rows==0)
        B.Event('AUCTION_BUYORDER_LIST_UPDATE',false,123,false);assert(not B.Busy())""")

    def test_closed_list_timeout_releases_without_retry(self):
        self.runlua("""B.Search('sellable',0);B.Close();now=16;B.Tick()
        assert(not B.Busy() and searches==1 and sends==0);assert(B.Open())""")

    def test_create_only_after_popup_accept_uses_engine_fee(self):
        self.runlua("""local q=B.PreviewCreate(100,100,10,'copper');assert(q and sends==0 and B.HasConfirmation())
            assert(q.fee==7 and q.escrow==1000 and q.total==1007 and feeType==1)
            StaticPopupDialogs[dialog].OnAccept();assert(sends==1 and sentItem==100 and sentN==100 and sentP==10 and sentType==1)
            B.Accept();assert(sends==1 and B.pending)
            B.Event('AUCTION_BUYORDER_RESULT','SELL',0,91,70,700,17);assert(B.pending)
            B.Event('AUCTION_BUYORDER_RESULT','CREATE',0,101);assert(not B.pending)
        """)

    def test_create_rejects_changed_fee_escrow_balance_session_or_capability(self):
        for change in ('placement=8','escrow=1001','funds=1006','opened=false','enabled=false',
                       'AAC.SessionGeneration=2','now=31','B.Close()','blocked=true','otherDialog=true'):
            with self.subTest(change=change):
                self.setUp()
                self.runlua("assert(B.PreviewCreate(100,100,10,'copper'));"+change+";B.Accept();assert(sends==0)")

    def test_create_input_and_currency_validation(self):
        self.runlua("""for _,n in ipairs({0,-1,1.5,10000,math.huge}) do assert(not B.PreviewCreate(100,n,10,'copper')) end
            assert(not B.PreviewCreate(100,1,1.5,'copper'));assert(not B.PreviewCreate(0,1,10,'copper'))
            assert(not B.PreviewCreate(100,1,10,'unknown'))
            assert(B.PreviewCreate(100,100,10,'account'));assert(feeType==2);B.Dismiss()
            function IsAuctionItemAccountMoneyTrade() return false end
            assert(not B.PreviewCreate(100,100,10,'account') and sends==0)
        """)

    def test_create_blocks_missing_or_invalid_engine_quote(self):
        for change in ('placement=nil','placement=-1','escrow=nil','escrow=math.huge','escrow=999','placement=0/0'):
            with self.subTest(change=change):
                self.setUp()
                self.runlua(change+";assert(not B.PreviewCreate(100,100,10,'copper') and sends==0)")

    def test_sell_largest_accessible_unlocked_stack_and_result_matching(self):
        self.ready()
        self.runlua("""local q=B.PreviewSell(91);assert(q and q.count==70 and q.gross==700 and q.fee==17 and q.net==683)
            assert(pickups==0 and sends==0);B.Accept();assert(picked==12 and sends==1 and sentID==91)
            B.Event('AUCTION_BUYORDER_RESULT','SELL',0,92,70,700,17);assert(B.pending)
            B.Event('AUCTION_BUYORDER_RESULT','SELL',0,91,70,700,17);assert(not B.pending)
            assert(B.status:find('683',1,true))
        """)

    def test_sell_filters_locked_and_closed_pages_and_caps_quantity(self):
        self.runlua('bags[2][3]=true;filled=80')
        self.ready()
        self.runlua("assert(B.rows[1].inBag==40);local q=B.PreviewSell(91);assert(q.count==20);B.Accept();assert(picked==11)")

    def test_sell_revalidates_every_stock_and_order_identity_component(self):
        for change in ('bags[2][2]=69','bags[2][3]=true','bags[2][4]=101','bags[2][1]=13',
                       "stackLink='different'",'filled=1','feeRate=300',"mode='account'",'own=true',
                       'cursor={}',"staged={70,70,link=stackLink}"):
            with self.subTest(change=change):
                self.setUp(); self.ready()
                self.runlua('assert(B.PreviewSell(91));'+change+';B.Accept();assert(sends==0 and pickups==0)')

    def test_sell_diamond_minimum_fee(self):
        self.runlua("mode='account';feeRate=0;filled=99")
        self.ready()
        self.runlua('local q=B.PreviewSell(91);assert(q.count==1 and q.fee==1 and q.net==9)')

    def test_cancel_only_own_exact_order_and_show_fee_retained(self):
        self.ready()
        self.runlua('assert(not B.PreviewCancel(91));own=true')
        self.ready('mine')
        self.runlua("""local q=B.PreviewCancel(91);assert(q and q.refund==1000 and q.placementFee==7 and sends==0)
            filled=1;B.Accept();assert(sends==0);B.Read()
            assert(B.PreviewCancel(91));B.Accept();assert(sentID==91 and sends==1)
            B.Event('AUCTION_BUYORDER_RESULT','CANCEL',0,92);assert(B.pending)
            B.Event('AUCTION_BUYORDER_RESULT','CANCEL',0,91);assert(not B.pending)
        """)

    def test_cancel_refreshes_remaining_orders_without_resending_transaction(self):
        self.runlua("""own=true; ids={91,92}
            function GetAuctionNumBuyOrders() return #ids,#ids end
            function GetAuctionBuyOrderInfo(i,mine)
                return ids[i],100,'Ore','ore.dds',100,0,10,'copper',250,7,600,'Buyer',true
            end
        """)
        self.ready('mine')
        self.runlua("""assert(#B.rows==2);B.PreviewCancel(91);B.Accept()
            ids={92};B.Event('AUCTION_BUYORDER_RESULT','CANCEL',0,91,nil,nil,nil,true)
            assert(searches==2 and queryMine and B.query, 'successful cancel must refresh own orders')
            B.Event('AUCTION_BUYORDER_LIST_UPDATE',true,0,false)
            assert(#B.rows==1 and B.rows[1].id==92 and not B.Busy())
            assert(B.status:find('cancelled',1,true) and B.status:find('mail',1,true))
            B.Tick();assert(sends==1 and searches==2)
        """)

    def test_transaction_timeout_close_reopen_keeps_ownership_without_false_success(self):
        self.runlua("""B.PreviewCreate(100,100,10,'copper');B.Accept();now=16;B.Tick()
            assert(B.pending and B.Busy());B.Close();AAC.SessionGeneration=2
            assert(not B.PreviewCreate(100,100,10,'copper') and not B.Search('all',0))
            B.Event('AUCTION_BUYORDER_RESULT','CREATE',0,500);assert(not B.pending and #B.rows==0)
            assert(not B.status or not B.status:find('created',1,true));assert(sends==1)
        """)

    def test_result_failures_and_zero_fill_are_never_success(self):
        for result,count in ((0,0),(7,70)):
            with self.subTest(result=result,count=count):
                self.setUp(); self.ready()
                self.runlua(f"""B.PreviewSell(91);B.Accept();B.Event('AUCTION_BUYORDER_RESULT','SELL',{result},91,{count},700,17)
                    assert(not B.pending and not B.status:find('Sold',1,true));assert(sends==1)
                """)

    def test_local_rejection_does_not_wait_or_retry(self):
        self.runlua("sendResult=false;B.PreviewCreate(100,100,10,'copper');B.Accept();assert(not B.pending and sends==1);now=100;B.Tick();assert(sends==1)")

    def test_result_with_nil_or_mismatching_id_cannot_release_cancel(self):
        self.runlua('own=true');self.ready('mine')
        self.runlua("B.PreviewCancel(91);B.Accept();B.Event('AUCTION_BUYORDER_RESULT','CANCEL',0,nil);assert(B.pending)")

    def test_market_self_lock_does_not_block_confirmation_accept(self):
        self.runlua("""function AAC.Market.Blocked() return B.Busy() end
            function AAC.Market.HasConfirmation() return B.HasConfirmation() end
            assert(B.PreviewCreate(100,100,10,'copper'));B.Accept();assert(sends==1)
        """)

    def test_unowned_cache_update_does_not_enable_actions(self):
        self.runlua("B.Event('AUCTION_BUYORDER_LIST_UPDATE',false,0,true);B.Read();assert(#B.rows==0 and not B.PreviewSell(91))")

    def test_missing_api_and_global_block_prevent_new_flows(self):
        self.runlua("""blocked=true;assert(not B.Search('all',0) and not B.PreviewCreate(100,100,10,'copper'))
            blocked=false;otherDialog=true;assert(not B.Search('all',0));otherDialog=false
            AuctionBuyOrderSell=nil;assert(not B.Available() and not B.Search('all',0));assert(searches==0 and sends==0)
        """)

    def test_staging_hooks_cannot_submit_after_session_or_order_changes(self):
        for change in ('opened=false','AAC.SessionGeneration=2','filled=1','feeRate=300','blocked=true','B.Close()'):
            with self.subTest(change=change):
                self.setUp(); self.ready()
                self.runlua("assert(B.PreviewSell(91));local stage=ClickAuctionItemButton;function ClickAuctionItemButton() stage();"+change+" end;B.Accept();assert(sends==0)")

    def test_staging_mismatch_does_not_send(self):
        self.ready()
        self.runlua("""B.PreviewSell(91)
            function ClickAuctionItemButton() staged={11,40,link='other'};cursor=nil end
            B.Accept();assert(sends==0 and pickups==1)
        """)

    def test_throwing_send_preserves_ambiguous_request_ownership(self):
        self.runlua("""function AuctionBuyOrderCreate() sends=sends+1;error('after write') end
            B.PreviewCreate(100,100,10,'copper');B.Accept();assert(B.pending and sends==1)
            now=50;B.Tick();assert(not B.PreviewCreate(100,100,10,'copper') and sends==1)
        """)

    def test_external_cache_replacement_invalidates_confirmed_order(self):
        self.ready()
        self.runlua("""B.PreviewSell(91);B.Event('AUCTION_BUYORDER_LIST_UPDATE',false,900,false)
            B.Accept();assert(sends==0 and pickups==0 and #B.rows==0)
        """)

    def test_open_allows_create_after_close_without_releasing_outstanding_requests(self):
        self.runlua("""B.Close();assert(B.Open());assert(B.PreviewCreate(100,100,10,'copper'))
            B.Accept();B.Close();assert(not B.Open() and B.pending)
            B.Event('AUCTION_BUYORDER_RESULT','CREATE',0,100);assert(B.Open())
            B.Search('all',0);B.Close();assert(not B.Open() and B.query)
        """)

    def test_successful_create_opens_own_orders_without_resending(self):
        self.runlua("""AAC.TradingUI={mode='create',page=5,selected={}}
            assert(B.PreviewCreate(100,100,10,'copper'));B.Accept();assert(sends==1)
            B.Event('AUCTION_BUYORDER_RESULT','CREATE',0,501)
            assert(AAC.TradingUI.mode=='create' and AAC.TradingUI.page==1)
            assert(AAC.TradingUI.selected==nil and B.query.mine and sends==1)
        """)

    def test_locales_cover_ui_and_controller_keys_with_matching_placeholders(self):
        import re
        ui = (SOURCE.parent / 'trading_ui.lua').read_text(encoding='utf-8-sig')
        backend = SOURCE.read_text(encoding='utf-8-sig')
        ui_keys = set(re.findall(r'(\w+)=\{', ui.split('local copy={',1)[1].split('function U.Text',1)[0]))
        backend_keys = set(re.findall(r'(\w+)=\"', backend.split(' EN = {',1)[1].split(' DE = {',1)[0]))
        self.lua.execute((SOURCE.parent / 'trading_locale.lua').read_text(encoding='utf-8-sig'))
        self.lua.execute('AACLocale={Messages={}}')
        self.lua.execute((SOURCE.parent / 'frontend_locale.lua').read_text(encoding='utf-8'))
        expected = None
        for lang in ('EN','DE','ES','FR','PL','RU','TR','JP','KR','CN','TW'):
            with self.subTest(lang=lang):
                self.lua.globals().AAC.TradingLocale.Apply(lang)
                self.lua.globals().AAC.FrontendLocale.Apply(lang)
                for key in self.lua.globals().AAC.FrontendLocale['keys'].split():
                    self.assertTrue(self.lua.globals().AAC.TradingTranslations[key].strip(), (lang,key))
                tables = (self.lua.globals().AAC.TradingTranslations, self.lua.globals().AAC.BuyOrderTranslations)
                actual = []
                for keys, table in zip((ui_keys,backend_keys),tables):
                    self.assertTrue(keys.issubset(set(table.keys())), (lang, keys-set(table.keys())))
                    actual.append({k:re.findall(r'%[sdif]', table[k]) for k in keys})
                    for key in keys:
                        self.assertTrue(table[key].strip())
                if expected is None:
                    expected = actual
                else:
                    self.assertEqual(actual,expected)
                self.assertEqual(self.lua.globals().B.Text('created'), tables[1]['created'])


if __name__ == '__main__':
    unittest.main()
