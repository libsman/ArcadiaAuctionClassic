from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

SOURCE = Path(__file__).resolve().parents[1] / 'addon/ArcadiaAuctionClassic/Lua/seller_tools.lua'

class SellerToolsTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
            opened=true; sends=0; own={}; offers={}; bag={}; now=0
            AAC={CanRequest=function() return opened end,SessionGeneration=1,UX={Number=tostring},
                Market={Blocked=function() return false end,HasConfirmation=function() return false end,
                    StartSearch=function(owner,send,finish,publish) job={owner=owner,send=send,finish=finish,publish=publish};send();return true end,
                    StopSearch=function() stopped=true end, SearchEvent=function() end},
                Sell={CanAuctionBagItem=function() return true end}}
            function GetTime() return now end
            function GetLanguage() return 'ENUS' end
            function GetObjectInfo(id,k) if k=='maxheap' then return id==100 and 100 or 1 end end
            function ParseHyperlink(link) local n=tonumber((link or ''):match('item:(%d+)'));if n then return 'item',string.format('%x',n),'Food' end end
            function UnitName() return 'Me' end
            function GetAuctionNumSellItems() return #own end
            function GetAuctionSellItemInfo(i) local o=own[i];return o.name,o.count,0,'icon',1,500,nil,o.mode,0,o.price,0,0 end
            function GetAuctionSellItemLink(i) return own[i].link end
            function GetAuctionBrowseItemInfo(p,i) local o=offers[i];return i,o.name,o.count,0,'icon',1,400,o.seller,false,o.mode,0,o.price,0,i,o.anon end
            function GetAuctionBrowseItemLink(i) return offers[i].link end
            function AuctionBrowseSearchItem() sends=sends+1 end
            function GetBagCount() return 1,1,60 end
            function GetBagPageLetTime() return false end
            function GetBagItemInfo(i) local b=bag[i];if b then return i,'icon',b.name,b.count,b.locked,nil,b.id end end
            function GetBagItemLink(i) return bag[i] and bag[i].link end
            function CursorHasItem() return false end
            function GetAuctionItemLink() return staged end
            function PickupBagItem(i) picked=i end
            function ClickAuctionItemButton() staged=bag[picked].link end
            function ItemClipboard_Clear() end
            function SaveVariablesPerCharacter() end
        ''')
        self.lua.execute(SOURCE.read_text(encoding='utf-8'))

    def test_native_hyperlinks_without_invented_global(self):
        self.lua.execute('''
            assert(GetItemIdFromLink==nil)
            function ParseHyperlink(link)
                if link=='invalid' then return nil end
                if link=='empty' then return 'item','' end
                if link=='skill' then return 'skill','64' end
                return 'item','31a66 abcdef 000000','Mana Stone'
            end
            assert(AAC.SellerTools.ItemIDFromLink('|Hitem:31a66 abcdef|h[Stone]|h')==203366)
            assert(AAC.SellerTools.ItemIDFromLink(nil)==nil)
            assert(AAC.SellerTools.ItemIDFromLink('invalid')==nil)
            assert(AAC.SellerTools.ItemIDFromLink('empty')==nil)
            assert(AAC.SellerTools.ItemIDFromLink('skill')==nil)
        ''')

    def test_checks_only_comparable_items_and_excludes_own_anonymous_stack(self):
        self.lua.execute('''
            own={{name='Food',count=10,mode='account',price=50,link='item:100'},
                 {name='Sword',count=1,mode='account',price=100,link='item:200'}}
            offers={{name='Food',count=10,mode='account',price=50,link='item:100',anon=true},
                    {name='Food',count=20,mode='account',price=80,link='item:100',seller='Other'},
                    {name='Food',count=1,mode='copper',price=1,link='item:100',seller='Other'}}
            assert(AAC.SellerTools.CheckPrices()); AAC.SellerTools.Tick()
            job.publish(1,3,1);job.finish();AAC.SellerTools.Tick()
            assert(sends==1)
            assert(AAC.SellerTools.rows[1].state=='cheaper' and AAC.SellerTools.rows[1].market==4)
            assert(AAC.SellerTools.rows[2].state=='uncomparable')
        ''')

    def test_incomplete_or_failed_search_never_shows_lowest(self):
        self.lua.execute('''
            own={{name='Food',count=10,mode='account',price=50,link='item:100'}}
            AAC.SellerTools.CheckPrices();AAC.SellerTools.Tick()
            job.finish('timeout');AAC.SellerTools.Tick()
            assert(AAC.SellerTools.rows[1].state=='unknown')
        ''')

    def test_replaced_search_without_published_pages_stays_unknown(self):
        self.lua.execute('''
            own={{name='Food',count=10,mode='account',price=50,link='item:100'}}
            AAC.SellerTools.CheckPrices();AAC.SellerTools.Tick();job.finish()
            assert(AAC.SellerTools.rows[1].state=='unknown')
        ''')

    def test_anonymous_competitor_before_named_own_offer_is_not_removed(self):
        self.lua.execute('''
            own={{name='Food',count=10,mode='account',price=50,link='item:100'}}
            offers={{name='Food',count=10,mode='account',price=50,link='item:100',anon=true},
                    {name='Food',count=10,mode='account',price=50,link='item:100',seller='Me'}}
            AAC.SellerTools.CheckPrices();AAC.SellerTools.Tick()
            job.publish(1,2,1);job.finish()
            assert(AAC.SellerTools.rows[1].market==5)
        ''')

    def test_own_sale_during_scan_invalidates_comparison(self):
        self.lua.execute('''
            own={{name='Food',count=10,mode='account',price=50,link='item:100'}}
            AAC.SellerTools.CheckPrices();AAC.SellerTools.Tick()
            job.publish(1,0,0);own={};job.finish()
            assert(AAC.SellerTools.rows[1].state=='unknown')
        ''')

    def test_late_reply_is_forwarded_after_close(self):
        self.lua.execute('''
            function AAC.Market.SearchEvent(owner,event) forwarded=event end
            AAC.SellerTools.Close();AAC.SellerTools.Event('AUCTION_SEARCH_RESULT')
            assert(forwarded=='AUCTION_SEARCH_RESULT')
        ''')

    def test_repeat_protection_lasts_until_different_item_is_staged(self):
        self.lua.execute('''
            AAC.SellerTools.repeatAppliedLink='item:100'
            assert(AAC.SellerTools.RepeatProtects('item:100'))
            assert(not AAC.SellerTools.RepeatProtects('item:200'))
            assert(not AAC.SellerTools.RepeatProtects('item:100'))
        ''')

    def test_repeat_preserves_integer_total_despite_fractional_unit_price(self):
        self.lua.execute('''
            AAC.SellerTools.Record({itemID=100,name='Food',link='item:100',count=50,buyout=7,mode='account',duration=4})
            local e=AAC.SellerTools.Recent()[1]
            assert(AAC.SellerTools.RepeatPrice(e,50)==7)
            assert(AAC.SellerTools.RepeatPrice(e,25)==4)
        ''')

    def test_close_and_changed_session_ignore_late_results(self):
        self.lua.execute('''
            own={{name='Food',count=10,mode='account',price=50,link='item:100'}}
            AAC.SellerTools.CheckPrices();AAC.SellerTools.Tick();AAC.SellerTools.Close()
            AAC.SessionGeneration=2;job.finish();assert(not AAC.SellerTools.checking)
            assert(AAC.SellerTools.rows[1].state~='lowest')
        ''')

    def test_recent_only_records_confirmed_and_preserves_currency(self):
        self.lua.execute('''
            AAC.SellerTools.Init()
            assert(#AAC.SellerTools.Recent()==0)
            AAC.SellerTools.Record({itemID=100,name='Food',link='item:100',count=10,buyout=50,mode='account',duration=4,promote=0,promoteTime=0})
            local r=AAC.SellerTools.Recent()[1];assert(r.unit==5 and r.mode=='account' and r.count==10)
            AAC.SellerTools.Record({itemID=200000,lotMode='copper',count=100,buyout=5})
            assert(#AAC.SellerTools.Recent()==1)
        ''')

    def test_repeat_matches_exact_variant_and_never_posts(self):
        self.lua.execute('''
            bag[1]={id=200,name='Sword',count=1,link='item:200:other'}
            local r={itemID=200,link='item:200:exact',count=1,unit=30,mode='account',duration=4}
            assert(not AAC.SellerTools.StageRepeat(r)); assert(not picked)
            bag[2]={id=200,name='Sword',count=1,link='item:200:exact'}
            assert(AAC.SellerTools.StageRepeat(r));assert(picked==2 and sends==0)
            assert(AAC.SellerTools.repeatPending.entry.unit==30)
        ''')

if __name__=='__main__':unittest.main()
