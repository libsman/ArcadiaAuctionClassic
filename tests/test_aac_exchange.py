from pathlib import Path
import unittest
import xml.etree.ElementTree as ET
from lupa.lua51 import LuaRuntime

SOURCE=Path(__file__).resolve().parents[1]/'addon/ArcadiaAuctionClassic/Lua/exchange.lua'
class ExchangeTests(unittest.TestCase):
    def setUp(self):
        self.lua=LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
            now=0; opened=true; sends=0; money=100000; price=100; fee=2; enabled=true
            AAC={SessionGeneration=1,Market={Blocked=function() return false end,HasConfirmation=function() return false end},
             CanRequest=function() return opened end,FeatureEnabled=function() return enabled end,
             UX={Number=tostring},Tools={}}; StaticPopupDialogs={}
            function TEXT(k) return k end
            function GetTime() return now end
            function GetPlayerMoney() return money end
            function StaticPopup_Show(k,text) dialog=k; dialogText=text end
            function StaticPopup_Hide() end
            function GetAuctionExchangeInfo() return price,0,100,250,true,1,10000,1000000 end
            function AuctionExchangeQuote(side,n,limit) return 1,n,price,n*price,fee,side=='ask' and 'account' or 'copper',side=='ask' and n*(limit or price) or n end
            function AuctionExchangeRequest() end
            function GetAuctionExchangeNumOffers() return 0 end
            function GetAuctionExchangeOffer() end
            function AuctionExchangeTrade(side,n,limit) sends=sends+1; sentSide=side; sentN=n; sentLimit=limit; return true end
            function AuctionExchangeCreate(side,n,limit) sends=sends+1; sentSide=side; sentN=n; sentLimit=limit; return true end
            function AuctionExchangeCancel(id) sends=sends+1; sentID=id; return true end
            function GetAuctionExchangeNumMyOrders() return 1 end
            function GetAuctionExchangeMyOrder(i) if i==1 then return 71,'ask',100,100,20,500 end end
            function GetAuctionExchangeNumAltOrders() return 1,1 end
            function GetAuctionExchangeAltOrder() return 72,'bid',100,200,10,600,'Other' end
        ''')
        self.lua.execute(SOURCE.read_text(encoding='utf-8-sig'))
        self.lua.execute('AAC.Exchange.ready=true')

    def runlua(self,s): self.lua.execute(s)

    def test_trade_confirmation_and_duplicate_guard(self):
        self.runlua('''assert(AAC.Exchange.Preview('trade','ask',100,100)); assert(sends==0)
            AAC.Exchange.Accept(); assert(sends==1 and sentN==100 and sentSide=='ask')
            assert(not AAC.Exchange.Preview('trade','ask',100,100)); assert(sends==1)
            AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE'); assert(AAC.Exchange.pending)
            AAC.Exchange.Event('AUCTION_EXCHANGE_RESULT','CREATE',0,1); assert(AAC.Exchange.pending)
            AAC.Exchange.Event('AUCTION_EXCHANGE_RESULT','TRADE',0,1,100,98,2,0)
            assert(not AAC.Exchange.pending)
        ''')

    def test_partial_result_reports_filled_resting_and_mail(self):
        self.runlua('''local X=AAC.Exchange
        X.Preview('create','bid',100,100);X.Accept()
        X.Event('AUCTION_EXCHANGE_RESULT','CREATE',0,81,40,39,1,500,'bid',60,true)
        assert(not X.pending and X.status:find('60',1,true) and X.status:find('39',1,true))
        assert(X.status:find(X.T('BO_REFUND_BY_MAIL'),1,true))
        local before=X.status;X.Event('AUCTION_EXCHANGE_UPDATE');assert(X.status==before)
        ''')

    def test_error_result_honours_mail_flag_without_numeric_refund(self):
        self.runlua('''local X=AAC.Exchange
        X.Preview('trade','ask',100,100);X.Accept()
        X.Event('AUCTION_EXCHANGE_RESULT','TRADE',2,0,0,0,0,0,'bid',0,true)
        assert(not X.pending and X.status:find(X.T('BO_REFUND_BY_MAIL'),1,true))
        ''')

    def test_changed_quote_fee_or_closed_session_never_sends(self):
        for change in ('price=101','fee=3','opened=false','AAC.SessionGeneration=2','now=31','money=1'):
            with self.subTest(change=change):
                self.setUp()
                self.runlua("AAC.Exchange.Preview('trade','ask',100,100);"+change+";AAC.Exchange.Accept();assert(sends==0)")

    def test_create_cancel_and_alt_orders(self):
        self.runlua('''assert(AAC.Exchange.Preview('create','bid',100,100)); AAC.Exchange.Accept(); assert(sends==1)
            AAC.Exchange.Event('AUCTION_EXCHANGE_RESULT','CREATE',0,81)
            assert(not AAC.Exchange.Preview('cancel',nil,72))
            assert(AAC.Exchange.Preview('cancel',nil,71)); AAC.Exchange.Accept(); assert(sends==2 and sentID==71)
            AAC.Exchange.Event('AUCTION_EXCHANGE_RESULT','CANCEL',0,72); assert(AAC.Exchange.pending)
            AAC.Exchange.Event('AUCTION_EXCHANGE_RESULT','CANCEL',0,71); assert(not AAC.Exchange.pending)
        ''')

    def test_changed_order_and_missing_api(self):
        self.runlua('''assert(AAC.Exchange.Preview('cancel',nil,71))
            function GetAuctionExchangeMyOrder() return 71,'ask',100,100,30,500 end
            AAC.Exchange.Accept(); assert(sends==0)
            AuctionExchangeQuote=nil
            assert(not AAC.Exchange.Preview('trade','ask',100,100))
        ''')

    def test_minimum_maximum_integer_limits_and_escrow(self):
        self.runlua('''assert(not AAC.Exchange.Preview('trade','ask',0,100))
            assert(not AAC.Exchange.Preview('create','ask',1.5,100))
            assert(not AAC.Exchange.Preview('create','ask',10001,100))
            assert(not AAC.Exchange.Preview('create','ask',100,0))
            money=10000
            assert(not AAC.Exchange.Preview('trade','ask',100,101))
        ''')

    def test_zero_fill_is_not_reported_as_a_trade(self):
        self.runlua('''AAC.Exchange.Preview('trade','ask',100,100); AAC.Exchange.Accept()
            AAC.Exchange.Event('AUCTION_EXCHANGE_RESULT','TRADE',0,1,0,0,0,10000)
            assert(not AAC.Exchange.status:find('Trade confirmed',1,true))
        ''')

    def test_partial_fill_is_requoted_and_sent_at_confirmed_quantity(self):
        self.runlua('''function AuctionExchangeQuote(side,n,limit)
                local actual=math.min(40,n)
                return 1,actual,100,actual*100,1,'account',actual*100
            end
            assert(AAC.Exchange.Preview('trade','ask',100,100))
            assert(AAC.Exchange.confirmation.q.quantity==40)
            AAC.Exchange.Accept(); assert(sentN==40)
        ''')

    def test_close_keeps_sent_ownership_and_discards_confirmation(self):
        self.runlua('''AAC.Exchange.Preview('trade','ask',100,100); AAC.Exchange.Close(); AAC.Exchange.Accept(); assert(sends==0)
            AAC.Exchange.ready=true; AAC.Exchange.Preview('trade','ask',100,100); AAC.Exchange.Accept()
            AAC.Exchange.Close(); assert(AAC.Exchange.pending and sends==1)
            now=100; AAC.Exchange.Tick(); assert(AAC.Exchange.pending and sends==1)
        ''')

    def test_classic_market_is_blocked_by_exchange_confirmation_and_pending(self):
        self.runlua('AAC.Events={}')
        self.lua.execute((SOURCE.parent/'aac_custompay.lua').read_text(encoding='utf-8-sig'))
        self.runlua('''assert(AAC.Exchange.Preview('trade','ask',100,100))
            assert(not AAC.Market.Confirm('test','test',function() error('sent') end))
            assert(not AAC.Market.StartSearch({},function() error('sent') end,function() end,function() end))
            AAC.Exchange.Accept(); assert(sends==1)
            assert(AAC.Market.Blocked() and AAC.Market.TransactionPending())
            assert(not AAC.Market.Submit('buy',function() end,function() error('sent') end))
        ''')

    def make_widgets(self):
        self.runlua('''function widget()
            return {text='',SetTexture=function(s,t) s.texture=t end,SetWidth=function(s,w) s.width=w end,SetChecked=function(s,v) s.checked=v end,ClearAllAnchors=function() end,SetAnchor=function() end,SetTexCoord=function() end,Show=function(s) s.visible=true end,Hide=function(s) s.visible=false end,GetName=function(s) return s.name end,SetText=function(s,t) s.text=t end,GetText=function(s) return s.text end,
                Enable=function(s) s.enabled=true end,Disable=function(s) s.enabled=false end,
                IsVisible=function() return true end,LockHighlight=function(s) s.selected=true end,
                UnlockHighlight=function(s) s.selected=false end}
            end
            function SecondsToTime(n) return tostring(n) end
        ''')
        for elem in ET.parse(SOURCE.parent.parent/'Xml/aac_exchange.xml').iter():
            name=elem.attrib.get('name','')
            if name.startswith('AAC_'):
                self.lua.globals()[name]=self.lua.eval('widget()')
                self.lua.globals()[name].name=name
    def test_full_view_renders_pages_and_alt_orders_are_read_only(self):
        self.make_widgets()
        self.runlua('''AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE')
            AAC.Exchange.SetOrders(false)
            AAC.Exchange.Select('orders',AAC_Exchangeorders1); assert(AAC_ExchangeCancel.enabled)
            AAC.Exchange.Select('orders',AAC_Exchangeorders2); assert(not AAC_ExchangeCancel.enabled)
            assert(AAC_Exchangeorders2.details:find('Other'))
            assert(AAC_ExchangeOrdersPanel.visible and not AAC_ExchangeOfferPanel.visible)
            AAC.Exchange.Manage(); assert(AAC_ExchangeOfferPanel.visible and not AAC_ExchangeOrdersPanel.visible)
        ''')

    def test_simple_landing_and_navigation_preserve_advanced_orders(self):
        self.make_widgets()
        self.runlua("""AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE')
            assert(AAC.Exchange.view=='home', 'Exchange should open the simple landing page')
            assert(AAC_ExchangeQuickPanel.visible and not AAC_ExchangeOfferPanel.visible)
            AAC.Exchange.Manage(); assert(not AAC_ExchangeQuickPanel.visible and AAC_ExchangeOfferPanel.visible)
            AAC.Exchange.SetOrders(false); assert(AAC_ExchangeOrdersPanel.visible)
            AAC.Exchange.Show(); assert(AAC_ExchangeQuickPanel.visible and not AAC_ExchangeOrdersPanel.visible)
            assert(sends==0)
        """)

    def test_simple_quotes_are_net_and_presets_never_trade(self):
        self.make_widgets()
        self.runlua("""AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE')
            assert(type(AAC.Exchange.Preset)=='function', 'Simple amount presets missing')
            AAC.Exchange.SetDirection('bid'); AAC.Exchange.Preset(25)
            assert(AAC_ExchangeQuickbidAmount:GetText()=='25')
            
            assert(AAC_ExchangeQuickbidReceive.text:find('2498',1,true))
            
            assert(sends==0)
            AAC.Exchange.Trade(); assert(sends==0 and AAC.Exchange.confirmation.q.quantity==25)
            assert(not dialogText:find('AUCTION_PRICE',1,true))
            AAC.Exchange.Accept(); assert(sends==1 and sentSide=='bid' and sentN==25)
        """)

    def test_simple_partial_fill_and_missing_liquidity_are_visible(self):
        self.make_widgets()
        self.runlua("""AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE')
            assert(type(AAC.Exchange.Preset)=='function', 'Simple amount presets missing')
            function AuctionExchangeQuote(side,n,limit)
                local actual=math.min(n,40)
                return 1,actual,100,actual*100,2,'account',actual*100
            end
            AAC.Exchange.SetDirection('ask'); AAC.Exchange.Preset(100)
            assert(AAC_ExchangeQuickaskNote.text:find('40',1,true))
            assert(AAC_ExchangeQuickaskReceive.text:find('38',1,true))
            function AuctionExchangeQuote() return 0,0,0,0,0,'account',0 end
            AAC.Exchange.Render()
            assert(not AAC_ExchangeQuickaskTrade.enabled)
            assert(AAC_ExchangeQuickaskReceive.text=='—')
            AAC.Exchange.Trade(); assert(not AAC.Exchange.confirmation and sends==0)
        """)

    def test_indivisible_lot_explains_actual_larger_exchange(self):
        self.make_widgets()
        self.runlua("""AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE')
            function AuctionExchangeQuote(side,n,limit) return 1,150,100,15000,2,'account',15000 end
            AAC.Exchange.SetDirection('ask'); AAC.Exchange.Preset(100)
            assert(AAC_ExchangeQuickaskNote.text:find('150',1,true))
            assert(not AAC_ExchangeQuickaskNote.text:find('Only',1,true), 'Larger lot must not claim only a smaller amount is available')
            AAC.Exchange.Trade(); assert(sends==0)
            assert(AAC.Exchange.confirmation.q.quantity==150)
            AAC.Exchange.Accept(); assert(sentN==150)
        """)

    def test_gold_offer_budget_uses_whole_diamonds_and_confirmation(self):
        self.make_widgets()
        self.runlua("""assert(type(AAC.Exchange.Manage)=='function', 'Simple offer management missing')
            AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE'); AAC.Exchange.Manage()
            AAC_ExchangeOfferbidAmount:SetText('10000'); AAC_ExchangeOfferbidRate:SetText('100')
            AAC.Exchange.Render()
            assert(AAC_ExchangeOfferbidPay.text:find('10000',1,true))
            assert(AAC_ExchangeOfferbidReceive.text:find('100',1,true))
            assert(AAC_ExchangeOfferbidCreate.enabled and sends==0)
            AAC.Exchange.CreateOffer('bid')
            assert(sends==0 and AAC.Exchange.confirmation.q.escrow==10000)
            AAC.Exchange.Accept(); assert(sends==1 and sentSide=='bid' and sentN==100 and sentLimit==100)
        """)

    def test_diamond_offer_and_invalid_amounts(self):
        self.make_widgets()
        self.runlua("""assert(type(AAC.Exchange.Manage)=='function', 'Simple offer management missing')
            AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE'); AAC.Exchange.Manage()
            AAC_ExchangeOfferaskAmount:SetText('25'); AAC_ExchangeOfferaskRate:SetText('100')
            AAC.Exchange.Render(); assert(AAC_ExchangeOfferaskReceive.text:find('2500',1,true))
            AAC.Exchange.CreateOffer('ask'); assert(sends==0 and AAC.Exchange.confirmation.q.quantity==25)
            AAC.Exchange.Dismiss()
            for _,bad in ipairs({'0','1.5','-1','invalid',''}) do
                AAC_ExchangeOfferaskAmount:SetText(bad); AAC.Exchange.Render()
                assert(not AAC_ExchangeOfferaskCreate.enabled)
                AAC.Exchange.CreateOffer('ask'); assert(sends==0 and not AAC.Exchange.confirmation)
            end
            AAC_ExchangeOfferbidAmount:SetText('10'); AAC_ExchangeOfferbidRate:SetText('100')
            AAC.Exchange.Render(); assert(not AAC_ExchangeOfferbidCreate.enabled)
        """)

    def test_simple_texts_available_in_every_supported_language(self):
        self.runlua("assert(type(AAC.Exchange.SimpleText)=='function', 'Simple labels missing')")
        for lang in ('EN','DE','ES','FR','PL','RU','TR','JP','KR','CN','TW'):
            self.lua.globals().AAC.UX.language=lang
            self.lua.execute(SOURCE.read_text(encoding='utf-8-sig'))
            for key in ('gold','diamonds','manage','home','give','receive','included','amount','partial','intro','trade'):
                self.assertNotEqual(self.lua.eval(f"AAC.Exchange.SimpleText('{key}')"), key)

    def test_offer_total_unit_and_grouping_both_directions(self):
        self.make_widgets()
        self.runlua('''AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE'); AAC.Exchange.Manage()
            AAC_ExchangeOfferaskAmount:SetText('1000'); AAC.Exchange.OfferChanged('ask','Amount',true)
            AAC_ExchangeOfferaskTotal:SetText('100000000'); AAC.Exchange.OfferChanged('ask','Total',true)
            assert(AAC_ExchangeOfferaskAmount.text=='1.000')
            assert(AAC_ExchangeOfferaskTotal.text=='100.000.000')
            assert(AAC_ExchangeOfferaskRate.text=='100.000')
            AAC.Exchange.CreateOffer('ask'); assert(sends==0)
            assert(AAC.Exchange.confirmation.q.quantity==1000 and AAC.Exchange.confirmation.q.limit==100000)
            AAC.Exchange.Dismiss()
            AAC_ExchangeOfferaskRate:SetText('120000'); AAC.Exchange.OfferChanged('ask','Rate')
            assert(AAC_ExchangeOfferaskTotal.text=='120.000.000')
            AAC_ExchangeOfferaskAmount:SetText('2000'); AAC.Exchange.OfferChanged('ask','Amount')
            assert(AAC_ExchangeOfferaskTotal.text=='240.000.000')
            money=1000000000
            AAC_ExchangeOfferbidAmount:SetText('100000000'); AAC.Exchange.OfferChanged('bid','Amount')
            AAC_ExchangeOfferbidTotal:SetText('1000'); AAC.Exchange.OfferChanged('bid','Total')
            assert(AAC_ExchangeOfferbidRate.text=='100.000')
            AAC.Exchange.CreateOffer('bid'); assert(sends==0)
            assert(AAC.Exchange.confirmation.q.quantity==1000 and AAC.Exchange.confirmation.q.escrow==100000000)
            AAC.Exchange.Dismiss()
            AAC_ExchangeOfferbidRate:SetText('50000'); AAC.Exchange.OfferChanged('bid','Rate')
            assert(AAC_ExchangeOfferbidTotal.text=='2.000')
            AAC.Exchange.CreateOffer('bid'); AAC.Exchange.Accept()
            assert(sends==1 and sentN==2000 and sentLimit==50000)
        ''')

    def test_offer_cannot_silently_round_or_ignore_entered_total(self):
        self.make_widgets()
        self.runlua('''AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE'); AAC.Exchange.Manage()
            AAC_ExchangeOfferaskAmount:SetText('3'); AAC.Exchange.OfferChanged('ask','Amount')
            AAC_ExchangeOfferaskTotal:SetText('100'); AAC.Exchange.OfferChanged('ask','Total')
            assert(AAC_ExchangeOfferaskRate.text=='')
            assert(not AAC_ExchangeOfferaskCreate.enabled)
            AAC.Exchange.CreateOffer('ask'); assert(not AAC.Exchange.confirmation and sends==0)
            AAC_ExchangeOfferaskRate:SetText('33'); AAC.Exchange.Render()
            AAC.Exchange.CreateOffer('ask'); assert(not AAC.Exchange.confirmation and sends==0)
            AAC_ExchangeOfferbidAmount:SetText('10050'); AAC_ExchangeOfferbidRate:SetText('100')
            AAC.Exchange.Render(); assert(not AAC_ExchangeOfferbidCreate.enabled)
            AAC.Exchange.CreateOffer('bid'); assert(not AAC.Exchange.confirmation and sends==0)
        ''')

    def test_grouped_input_handles_typing_and_recursive_text_events(self):
        self.make_widgets()
        self.runlua('''AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE'); AAC.Exchange.Manage()
            local input=AAC_ExchangeOfferaskAmount; local count=0
            function input:SetText(t)
                count=count+1; assert(count<15, 'Recursive text event loop')
                self.text=t; AAC.Exchange.OfferChanged('ask','Amount')
            end
            input:SetText('1000'); assert(input.text=='1000'); AAC.Exchange.OfferChanged('ask','Amount',true); assert(input.text=='1.000')
            input:SetText('1.0000'); assert(input.text=='1.0000'); AAC.Exchange.OfferChanged('ask','Amount',true); assert(input.text=='10.000')
            assert(AAC.Exchange.ParseNumber('100.000.000')==100000000)
            assert(not AAC.Exchange.ParseNumber('1.5'))
            AAC_ExchangeQuickbidAmount:SetText('1000'); AAC.Exchange.QuickAmountChanged('bid'); assert(AAC_ExchangeQuickbidAmount.text=='1000')
            AAC.Exchange.QuickAmountChanged('bid',true); assert(AAC_ExchangeQuickbidAmount.text=='1.000')
        ''')

    def test_typing_never_rewrites_active_field_and_groups_on_finish(self):
        self.make_widgets()
        self.runlua('''AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE'); AAC.Exchange.Manage()
            AAC_ExchangeOfferaskAmount:SetText('1000')
            local input=AAC_ExchangeOfferaskRate; local rewrites=0
            function input:SetText(t) rewrites=rewrites+1; self.text=t; AAC.Exchange.OfferChanged('ask','Rate') end
            input.text=''
            for digit in ('150000'):gmatch('.') do input.text=input.text..digit; AAC.Exchange.OfferChanged('ask','Rate') end
            assert(rewrites==0 and input.text=='150000', 'Typing must not reset the active edit field')
            assert(AAC_ExchangeOfferaskTotal.text=='150.000.000')
            AAC.Exchange.OfferChanged('ask','Rate',true)
            assert(input.text=='150.000' and rewrites==1)
            assert(sends==0)
        ''')

    def test_quick_rows_show_net_cost_and_require_confirmation(self):
        self.make_widgets()
        self.runlua('''AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE')
            assert(AAC_ExchangeQuickbidRow1.visible and AAC_ExchangeQuickaskRow1.visible)
            assert(not AAC_ExchangeQuickbidAmount.visible)
            assert(AAC_ExchangeQuickbidNetHead.visible and AAC_ExchangeQuickbidCostHead.visible)
            assert(AAC_ExchangeQuickbidRow1Buy.text=='Buy')
            assert(AAC_ExchangeQuickbidRow1Net.text=='99998')
            assert(AAC_ExchangeQuickbidRow1Cost.text=='1000')
            assert(AAC_ExchangeQuickaskRow1Net.text=='998')
            assert(AAC_ExchangeQuickaskRow1Cost.text=='100000')
            AAC.Exchange.QuickRow('bid',25); assert(sends==0)
            assert(AAC.Exchange.confirmation.q.net==2498)
            AAC.Exchange.Dismiss()
            AAC.Exchange.Custom('bid'); assert(AAC_ExchangeQuickbidAmount.visible and not AAC_ExchangeQuickbidRow1.visible)
            assert(not AAC_ExchangeQuickbidNetHead.visible and not AAC_ExchangeQuickbidCostHead.visible)
            AAC.Exchange.Custom('bid'); assert(not AAC_ExchangeQuickbidAmount.visible and AAC_ExchangeQuickbidRow1.visible)
            AAC.Exchange.QuickRow('ask',25); assert(sends==0)
            AAC.Exchange.Accept(); assert(sends==1 and sentSide=='ask' and sentN==25)
        ''')

    def test_partial_quote_rows_are_not_repeated_and_keep_actual_amount(self):
        self.make_widgets()
        self.runlua('''AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE')
            function AuctionExchangeQuote(side,n,limit) local f=math.min(n,20); return 1,f,100,f*100,2,'account',f*100 end
            AAC.Exchange.Render()
            assert(AAC_ExchangeQuickaskRow1.visible)
            for i=2,4 do assert(not _G['AAC_ExchangeQuickaskRow'..i].visible) end
            AAC.Exchange.QuickRow('ask',25); assert(sends==0)
            assert(AAC.Exchange.confirmation.q.quantity==20)
            AAC.Exchange.Accept(); assert(sentN==20 and sends==1)
        ''')

    def test_public_books_sort_scroll_and_select_without_sending(self):
        self.make_widgets()
        self.runlua("""
            function GetAuctionExchangeNumOffers() return 9 end
            function GetAuctionExchangeOffer(side,i) return i*100,20,1,false end
            AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE'); AAC.Exchange.Books()
            assert(AAC.Exchange.rows.bid[1].price==900)
            assert(AAC_ExchangeRate1Quantity.text:find('18000',1,true))
            AAC.Exchange.SetDirection('ask'); assert(AAC.Exchange.rows.ask[1].price==100)
            AAC.Exchange.Scroll(7); assert(AAC.Exchange.offset==2)
            AAC.Exchange.SelectRate(AAC_ExchangeRate1); assert(sends==0 and AAC.Exchange.limit==300)
        """)

    def test_combined_orders_deduplicate_and_protect_alt_cancel(self):
        self.make_widgets()
        self.runlua("""AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE'); AAC.Exchange.SetOrders()
            assert(#AAC.Exchange.rows.orders==2, 'Own and alt orders should be combined')
            AAC.Exchange.Select('orders',AAC_Exchangeorders2); assert(not AAC_ExchangeCancel.enabled)
            AAC.Exchange.Action('cancel'); assert(not AAC.Exchange.confirmation and sends==0)
            function GetAuctionExchangeAltOrder() return 71,'ask',100,100,20,500,'Me' end
            AAC.Exchange.Render(); assert(#AAC.Exchange.rows.orders==1)
            AAC.Exchange.Select('orders',AAC_Exchangeorders1); assert(AAC_ExchangeCancel.enabled)
            AAC.Exchange.Action('cancel'); assert(sends==0 and AAC.Exchange.confirmation.q.id==71)
        """)

    def test_market_empty_quote_does_not_allow_trade(self):
        self.make_widgets()
        self.runlua("""AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE')
            function AuctionExchangeQuote() return 0,0,0,0,0,'account',0 end
            AAC.Exchange.Render(); assert(not AAC_ExchangeQuickbidTrade.enabled)
            AAC.Exchange.Trade(); assert(sends==0 and not AAC.Exchange.confirmation)
        """)

    def test_offer_labels_in_all_eleven_languages(self):
        for lang in ('EN','DE','ES','FR','PL','RU','TR','JP','KR','CN','TW'):
            self.lua.globals().AAC.UX.language=lang
            for key in ('gold','diamonds','goldAmount','diamondAmount','rate','give','receive','fee','review','own','alt','new','reserve'):
                self.assertNotEqual(self.lua.eval(f"AAC.Exchange.OfferText('{key}')"),key)

    def test_selected_book_rate_becomes_confirmed_limit(self):
        self.make_widgets()
        self.runlua("""assert(type(AAC.Exchange.SelectRate)=='function', 'Integrated rate selection missing')
            AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE')
            AAC.Exchange.SelectRate({row={price=120,quantity=500}})
            AAC.Exchange.Trade(); assert(sends==0 and AAC.Exchange.confirmation.q.limit==120)
            AAC.Exchange.Accept(); assert(sends==1 and sentLimit==120)
        """)

    def test_direction_change_clears_limit_and_does_not_send(self):
        self.make_widgets()
        self.runlua("""assert(type(AAC.Exchange.SetDirection)=='function')
            AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE')
            AAC.Exchange.SelectRate({row={price=120,quantity=500}})
            AAC.Exchange.SetDirection('bid'); assert(AAC.Exchange.limit==nil and sends==0)
        """)

    def test_host_navigation_preserves_pending_and_restores_browse(self):
        self.make_widgets()
        self.runlua("""
            local function layout(f)
              f.SetWidth=function(s,w) s.width=w end
              f.ClearAllAnchors=function() end
              f.SetAnchor=function(s,p,r,to,x,y) s.x=x;s.y=y end
              f.SetFrameLevel=function(s,n) s.level=n end
              f.GetFrameLevel=function(s) return s.level or 1 end
            end
            for k,v in pairs(_G) do if type(k)=='string' and k:find('AAC_Exchange',1,true)==1 and type(v)=='table' then layout(v) end end
            for _,k in ipairs({'AAC_AuctionFrame','AAC_DashboardFrame','AAC_DashboardDescriptionFrame','AAC_SellFrame','AAC_SellAuctionContent','AAC_HistoryEditBox','AAC_SellEditBox','AAC_BrowseList','AAC_BrowseSearch'}) do _G[k]=widget();layout(_G[k]) end
            AAC.Browse={Frame_StopUpdates=function() stopped=true end}
            AAC.Main={ClickTab=function(tab) lastTab=tab;AAC.Exchange.Leave();AAC.Exchange.TabChanged(tab) end}
            AAC_ExchangeFrame.Show=function(s) s.visible=true;AAC.Exchange.Show() end
            AAC.Exchange.TabChanged(6); assert(not AAC_ExchangeNavigation.visible); AAC.Exchange.OpenFromNavigation()
            assert(AAC.Exchange.context=='dashboard' and AAC.Exchange.view=='home')
            assert(not AAC_DashboardFrame.visible)
            AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE'); AAC.Exchange.Trade(); AAC.Exchange.Accept()
            AAC.Exchange.Legacy(); assert(lastTab==6 and AAC.Exchange.pending, 'Leaving must not release a sent transaction')
            AAC.Exchange.Event('AUCTION_EXCHANGE_RESULT','TRADE',0,1,100,9998,2,0)
            AAC_SellAuctionContent.visible=true; AAC_SellEditBox.visible=true
            AAC_SellEditBox.IsVisible=function(s) return s.visible and AAC_SellAuctionContent.visible end
            AAC.Exchange.TabChanged(3); AAC.Exchange.OpenFromNavigation()
            assert(AAC.Exchange.view=='sell' and AAC.Exchange.context=='sell' and not AAC_SellAuctionContent.visible)
            AAC.Exchange.Legacy(); assert(lastTab==3 and not AAC.Exchange.context)
            assert(AAC_SellEditBox.visible, 'Ordinary offers filter must return after leaving exchange')
            AAC.Exchange.Open('browse'); assert(stopped and not AAC_BrowseList.visible and AAC_ExchangeFrame.width==650)
            AAC.Exchange.Leave(); assert(AAC_BrowseList.visible and not AAC.Exchange.context)
            assert(AAC_HistoryEditBox.visible and AAC_SellEditBox.visible)
            assert(sends==1)
        """)

    def test_sell_checkbox_mode_is_exclusive_and_does_not_submit(self):
        self.make_widgets()
        self.runlua("""
            assert(type(AAC.Exchange.SetSellMode)=='function')
            AAC_SellExchange=widget(); AAC_SellExchange.SetChecked=function(s,v) s.checked=v end
            AAC_SellAuctionContent=widget()
            AAC_SellMoneyAuction=widget(); AAC_SellMoneyAuction.SetChecked=function(s,v) s.checked=v end
            AAC.Sell={ChangeAuctionType=function(v) AAC_SellMoneyAuction.checked=v end}
            local open=AAC.Exchange.Open
            AAC.Exchange.Open=function(c) AAC.Exchange.context=c;AAC.Exchange.view='sell' end
            AAC.Exchange.SetSellMode(true)
            assert(AAC_SellExchange.checked and not AAC_SellMoneyAuction.checked)
            assert(AAC.Exchange.context=='sell')
            AAC.Exchange.UseMoneyAuction(true)
            assert(not AAC_SellExchange.checked and AAC_SellMoneyAuction.checked)
            assert(not AAC.Exchange.context and AAC_SellAuctionContent.visible and sends==0)
            AAC.Exchange.Open=open
        """)

    def test_integrated_sell_shows_form_and_orders_with_separate_count(self):
        self.make_widgets()
        self.runlua("""
            AAC.Exchange.context='sell'; AAC.Exchange.Show()
            assert(AAC.Exchange.view=='sell')
            assert(AAC_ExchangeOfferPanel.visible and AAC_ExchangeOrdersPanel.visible)
            assert(not AAC_ExchangeQuickPanel.visible)
            assert(AAC_ExchangeOfferaskCard.visible and not AAC_ExchangeOfferbidCard.visible)
            AAC.Exchange.OfferDirection('bid')
            assert(AAC_ExchangeOfferbidCard.visible and not AAC_ExchangeOfferaskCard.visible)
            assert(AAC_ExchangeOrdersCount.text:find('2',1,true))
            assert(not AAC_ExchangeNew.visible and not AAC_ExchangeBack.visible and sends==0)
        """)

    def test_ui_labels_available_in_all_locales(self):
        for lang in ('EN','DE','ES','FR','PL','RU','TR','JP','KR','CN','TW'):
            self.lua.globals().AAC.UX.language=lang
            for i in range(1,8):
                self.assertTrue(self.lua.eval(f'AAC.Exchange.UIText({i})'))

    def test_exchange_paging_four_rows_keeps_cancel_owner_checks(self):
        self.make_widgets()
        self.runlua('''function GetAuctionExchangeNumMyOrders() return 6 end
            function GetAuctionExchangeMyOrder(i) return 100+i,'bid',5000,100,20,500 end
            function GetAuctionExchangeNumAltOrders() return 0 end
            AAC.Exchange.context='sell'; AAC.Exchange.Show()
            assert(AAC_Exchangeorders1.row.id==101 and AAC_Exchangeorders4.row.id==104)
            assert(AAC_Exchangeorders1Quantity.text=='400000')
            AAC.Exchange.Page('orders',1)
            assert(AAC_Exchangeorders1.row.id==105 and AAC_Exchangeorders2.row.id==106)
            assert(not AAC_Exchangeorders3.row and not AAC_Exchangeorders3Icon.visible)
            AAC.Exchange.Select('orders',AAC_Exchangeorders1); AAC.Exchange.Action('cancel')
            assert(sends==0 and AAC.Exchange.confirmation.q.id==105)
            AAC.Exchange.Accept(); assert(sends==1 and sentID==105)
        ''')

    def test_custom_amount_columns_and_buttons_fit_compact_cards(self):
        self.make_widgets()
        self.runlua('''for k,v in pairs(_G) do
                if type(v)=='table' and type(k)=='string' and k:find('AAC_Exchange',1,true)==1 then
                    v.SetAnchor=function(s,p,r,rel,x,y) s.x=x;s.y=y end
                end
            end
            AAC.Exchange.quickWidth=317;AAC.Exchange.Show();AAC.Exchange.Custom('bid')
            local b,t=AAC_ExchangeQuickbidCustom,AAC_ExchangeQuickbidTrade
            assert(b.y==t.y and b.x+b.width<t.x and t.x+t.width<=299)
            local n,c=AAC_ExchangeQuickbidReceive,AAC_ExchangeQuickbidPay
            assert(n.y==c.y and n.x+n.width<c.x and c.x+c.width<=299)
            assert(AAC_ExchangeQuickbidPayIcon.visible and sends==0)
        ''')

    def test_bag_click_in_exchange_mode_is_not_hidden_auction_staging(self):
        self.runlua('''
            used=0; staged=0
            AAC_SellFrame={IsVisible=function() return true end}
            AAC_SellAuctionContent={IsVisible=function() return AAC.Exchange.context~='sell' end}
            function UseBagItem(i) used=used+1; return i end
            function ClickAuctionItemButton() staged=staged+1 end
            function ItemClipboard_Clear() end
            function PickupBagItem() end
            AAC.Sell={CanAuctionBagItem=function() return true end,TryPlaceCursorItem=function() end}
        ''')
        self.lua.execute((SOURCE.parent/'aac_hooks.lua').read_text(encoding='utf-8'))
        self.runlua('''AAC_HookFunctions(); AAC.Exchange.context='sell'
            assert(UseBagItem(12)==12 and used==1 and staged==0)
            AAC.Exchange.context=nil; UseBagItem(12); assert(staged==1 and used==1)
        ''')

    def test_money_category_is_virtual_and_does_not_change_native_indices(self):
        self.make_widgets()
        self.runlua("""
            AAC.Browse={SelectedCategory={[1]=13},DisplayedItems=20,CategoryButtonNums=0,CategoryScrollValue=0}
            function GetAuctionBrowseFilterList(cat,sub)
              if sub then assert(sub>=1 and sub<=3, 'Synthetic category reached native API: '..sub); return nil end
              if cat==13 then return 'Gold','Diamonds','Other' end
            end
            function getglobal(n)
              if not _G[n] then local f=widget();f.name=n;f.SetAlpha=function() end;f.ClearAllAnchors=function() end;f.SetAnchor=function() end;f.SetWidth=function() end;f.SetColor=function() end;f.SetTexCoord=function() end;_G[n]=f end
              return _G[n]
            end
            for i=1,40 do for _,suffix in ipairs({'','NormalText','HighlightText','Line','Backgound','ExpandArrow'}) do getglobal('AAC_BrowseCategoryButton'..i..suffix) end end
        """)
        src=(SOURCE.parent/'aac_browse.lua').read_text(encoding='utf-8-sig')
        a=src.index('function Browse.Category_SetItemInfo('); b=src.index('function AAC_BrowseGetList()',a)
        self.lua.execute('local Browse=AAC.Browse;'+src[a:b])
        self.runlua("""
            AAC.Browse.Category_SetItemInfo(2,GetAuctionBrowseFilterList(13))
            assert(AAC.Browse.CategoryButtonNums==4)
            assert(AAC_BrowseCategoryButton2.index==1 and not AAC_BrowseCategoryButton2.isExchange)
            assert(AAC_BrowseCategoryButton3.index==2 and not AAC_BrowseCategoryButton3.isExchange)
            assert(AAC_BrowseCategoryButton4.index==3 and not AAC_BrowseCategoryButton4.isExchange)
            assert(AAC_BrowseCategoryButton1.isExchange)
            AAC.Exchange.Open=function(c) openedContext=c;AAC.Exchange.context=c end
            AAC.Browse.CategoryScrollBar_Update=function() end
            AAC.Browse.SelectedCategory[2]=2
            AAC.Browse.CategoryButton_OnClick(AAC_BrowseCategoryButton1,'LBUTTON')
            assert(openedContext=='browse' and AAC.Browse.SelectedCategory[2]==nil)
            AAC_BrowseCategoryScrollBar=getglobal('AAC_BrowseCategoryScrollBar')
            function AAC_Browse_CorrectPos() end
            AAC.Exchange.Leave=function() AAC.Exchange.context=nil end
            AAC.Browse.CategoryButton_OnClick(AAC_BrowseCategoryButton3,'LBUTTON')
            assert(AAC.Browse.SelectedCategory[2]==2, 'Diamonds must keep native category 2')
            AAC.Browse.CategoryButtonNums=0
            AAC.Browse.Category_SetItemInfo(2,GetAuctionBrowseFilterList(13))
            AAC.Browse.SelectedCategory[1]=1; AAC.Browse.CategoryButtonNums=0
            AAC.Browse.Category_SetItemInfo(2,'Sword')
            assert(not AAC_BrowseCategoryButton1.isExchange)
        """)

    def test_home_has_two_independent_net_quotes_and_no_refresh_or_best_button(self):
        self.make_widgets()
        self.runlua("""AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE')
            assert(AAC_ExchangeQuickPanel.visible and not AAC_ExchangeMarketPanel.visible)
            assert(AAC_ExchangeQuickbidReceive.text:find('9998',1,true))
            assert(AAC_ExchangeQuickaskReceive.text:find('98',1,true))
            AAC.Exchange.Preset(25,'bid'); assert(AAC_ExchangeQuickaskAmount:GetText()=='100')
            AAC.Exchange.Trade('ask'); assert(sends==0 and AAC.Exchange.confirmation.q.side=='ask')
            AAC.Exchange.Accept(); assert(sentSide=='ask' and sentN==100)
            assert(AAC_ExchangeRefresh==nil and AAC_ExchangeBest==nil)
        """)

    def test_empty_rate_rows_hide_their_currency_icons(self):
        self.make_widgets()
        self.runlua("""AAC.Exchange.Show(); AAC.Exchange.Event('AUCTION_EXCHANGE_UPDATE'); AAC.Exchange.Books()
            assert(not AAC_ExchangeRate1.visible and AAC_ExchangeEmptyBook.text~='')
            function GetAuctionExchangeNumOffers() return 1 end
            function GetAuctionExchangeOffer() return 5000,8000,1 end
            AAC.Exchange.Render(); assert(AAC_ExchangeRate1.visible and not AAC_ExchangeRate2.visible)
        """)

if __name__=='__main__': unittest.main()
