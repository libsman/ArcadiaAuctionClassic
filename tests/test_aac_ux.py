from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1] / 'addon/ArcadiaAuctionClassic'

class UXTests(unittest.TestCase):
    def runtime(self, language='ENEU'):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().language = language
        lua.execute('AAC={Tools={}}; function GetLanguage() return language end; function TEXT(k) return k end')
        lua.execute((ROOT/'Lua/ux.lua').read_text(encoding='utf-8-sig'))
        return lua

    def test_sale_estimates_and_help_do_not_claim_guaranteed_net(self):
        for lang in ('EN','DE','ES','FR','PL','RU','TR','JP','KR','CN','TW'):
            lua=self.runtime(lang)
            self.assertTrue(lua.eval('AAC_SALE_INCOME').startswith(lua.eval('AAC.UX.text.standardFee') or 'MISSING'))
            self.assertIn('/aac classic',lua.eval('AAC_HELP'))
            self.assertNotIn('/aah',lua.eval('AAC_HELP'))
            self.assertIn('100',lua.eval('AAC_SALE_NOTE'))
        self.assertIn('Voraussichtlich',self.runtime('DE').eval('AAC_SALE_CONFIRM_INCOME'))

    def test_real_unit_price_sort_currency_groups_and_missing_buyout(self):
        lua = self.runtime()
        lua.execute('''
            a={auctionid=1,count=17,buyoutPrice=3,moneyMode="account",buyppu=999}
            b={auctionid=2,count=29,buyoutPrice=5,moneyMode="account",buyppu=1}
            assert(AAC.Tools.SortUnitLess(b,a))
            assert(AAC.Tools.SortUnitMore(a,b))
            gold={auctionid=3,count=1,buyoutPrice=100000,moneyMode="copper"}
            assert(AAC.Tools.SortUnitLess(gold,b) and AAC.Tools.SortUnitMore(gold,b))
            missing={auctionid=4,count=1,buyoutPrice=0,moneyMode="account"}
            assert(AAC.Tools.SortUnitLess(a,missing) and AAC.Tools.SortUnitMore(a,missing))
            assert(not AAC.Tools.SortUnitLess(a,a))
            invalid={auctionid=5,count=0,buyoutPrice=100,moneyMode="account"}
            assert(AAC.UX.UnitPrice(invalid)==nil)
        ''')

    def test_all_languages_and_fractional_prices(self):
        for lang in ('EN','DE','ES','FR','PL','RU','TR','JP','KR','CN','TW'):
            lua=self.runtime(lang)
            self.assertEqual(lua.eval('AAC.UX.language'),lang)
            for key in ('header','loading','filtering','done','buy','hint','fee','income'):
                self.assertTrue(lua.eval(f'AAC.UX.text.{key}'))
            self.assertNotEqual(lua.eval('AAC.UX.Number(0.000008,false)'), '0')
        self.assertEqual(self.runtime('DE').eval('AAC.UX.Number(5/29,false)'), '0,17241379')

    def test_loading_and_filter_progress_remain_distinct(self):
        lua=self.runtime()
        lua.execute('''
            assert(AAC.UX.Status(true,false,250,500,100,23):find("250"))
            assert(AAC.UX.Status(false,true,500,500,100,23):find("100"))
            assert(AAC.UX.Status(false,false,500,500,500,23):find("23"))
        ''')

    def test_gold_rate_best_first_and_regular_items_unchanged(self):
        lua=self.runtime('DE')
        lua.execute('''
          a={itemid=200000,count=1000000,buyoutPrice=13,moneyMode='account',auctionid=1}
          b={itemid=200000,count=50000000,buyoutPrice=5000,moneyMode='account',auctionid=2}
          assert(AAC.UX.GoldLot(a))
          assert(AAC.UX.Value(a)==1000000/13)
          assert(AAC.Tools.SortUnitLess(a,b))
          assert(AAC.Tools.SortUnitMore(b,a))
          assert(AAC.UX.UnitText(a,true):find('76.923',1,true))
          assert(AAC.UX.UnitText(a,true):find('Gold/Dia',1,true))
          assert(AAC.UX.UnitText(a,false):find('G/D',1,true))
          assert(not AAC.UX.UnitText(a,false,true):find('G/D',1,true))
          assert(AAC.UX.Value({itemid=123,count=29,buyoutPrice=5,moneyMode='account'})==5/29)
        ''')

    def test_no_scientific_notation_at_any_price(self):
        lua=self.runtime('DE')
        for value in (0.000013,0.000000001,0.1724137931,76923.07692,5000000000):
            for compact in (True,False):
                result=lua.globals().AAC.UX.Number(value,compact)
                self.assertNotIn('e',result.lower())
                self.assertNotEqual(result,'0')

    def test_actual_status_label_is_shown_after_dashboard_hid_it(self):
        lua=self.runtime()
        code=(ROOT/'Lua/aac_browse.lua').read_text(encoding='utf-8-sig')
        body=code[code.index('function Browse.InfoLabelUpdate()'):code.index('function Browse.List_UpdateItems()')]
        lua.execute('''Browse={Total=500,LastCached=1,MaxPageItems=250,CurrentFilterPage=1,CurrentFilterItem=20,Results={list={}}}
            CachingActive=true; AAC_BrowseInfoLabel={SetText=function(s,t) s.text=t end,Show=function(s) s.shown=true end}''')
        lua.execute(body)
        lua.execute('Browse.InfoLabelUpdate(); assert(AAC_BrowseInfoLabel.shown)')

if __name__ == '__main__': unittest.main()

