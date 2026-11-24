from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1] / 'addon/ArcadiaAuctionClassic'

class FeeTests(unittest.TestCase):
    def test_live_rates_rounding_currency_and_unavailable(self):
        lua = LuaRuntime()
        lua.execute('AAC={Events={}}; StaticPopupDialogs={}; AUCTION_PROLONG_SELL="Prolong"; function TEXT(k) return k end')
        lua.execute('AUCTION_PROMOTE_SELL="Promote"; AUCTION_PROMOTE_SELL_ITEM="Promote"; AUCTION_PROMOTETYPES="Promote"')
        lua.execute((ROOT/'Lua/aac_sell.lua').read_text(encoding='utf-8-sig'))
        lua.execute('''
            IsFunctionEnable=function(id) assert(id==9107); return true end
            GetAuctionFeeRates=function() return 500,700,900,1100 end
            local f,r=AAC.Sell.GetSaleFee(199,"account",false)
            assert(f==13 and r==700)
            assert(AAC.Sell.GetSaleFee(19,"copper",false)==0)
            assert(AAC.Sell.GetSaleFee(100,"account",true)==11)
            GetAuctionFeeRates=function() return 200,300,0,-1 end
            assert(AAC.Sell.GetSaleFee(100,"account",true)==3)
            GetAuctionFeeRates=nil
            assert(AAC.Sell.GetSaleFee(100,"account",false)==nil)
            IsFunctionEnable=function() return false end
            assert(AAC.Sell.GetSaleFee(100,"account",false)==nil)
        ''')

    def test_inactive_prestige_cannot_add_days_or_tax_hours(self):
        lua=LuaRuntime()
        lua.execute('AAC={Events={}}; StaticPopupDialogs={}; function TEXT(k) return k end; AUCTION_PROLONG_SELL="Prolong"; AUCTION_PROMOTE_SELL="Promote"; AUCTION_PROMOTE_SELL_ITEM="Promote"; AUCTION_PROMOTETYPES="Promote"')
        lua.execute((ROOT/'Lua/aac_sell.lua').read_text(encoding='utf-8-sig'))
        lua.execute("""
            PrestigeBenefitType_AuctionHouse_Time=1
            Prestige_GetChargeCount=function() return 12 end
            Prestige_PrestigeAvailable=function() return false end
            AAC_SavedSettings={SellDurationSelected=4}
            Auction_GetTax=function(price,count,hours) taxHours=hours; return 99999 end
            assert(AAC.Sell.GetDurationMinutes(5)==0, 'Expired Prestige must not grant days')
            assert(AAC.Sell.GetDurationChoiceCount()==4)
            assert(AAC.Sell.GetAuctionFee(100,2)==99999 and taxHours==168)
            Prestige_PrestigeAvailable=function() return true end
            assert(AAC.Sell.GetDurationMinutes(5)==19*24*60)
            assert(AAC.Sell.GetDurationChoiceCount()==5)
            AAC_SavedSettings.SellDurationSelected=5
            AAC.Sell.GetAuctionFee(100,2); assert(taxHours==19*24)
        """)

    def test_missing_data_is_recovered_before_main_captures_tables(self):
        lua=LuaRuntime()
        lua.execute('function TEXT(k) return k end')
        def load(path):
            rel=path.split('ArcadiaAuctionClassic/')[1]
            lua.execute((ROOT/rel).read_text(encoding='utf-8-sig'))
        lua.globals().load_file=load
        lua.execute('function dofile(p) return load_file(p) end')
        lua.execute((ROOT/'Lua/aac_main.lua').read_text(encoding='utf-8-sig'))
        lua.execute('assert(AAC.Data.Recipes[550389]==1); assert(type(AAC.Data.StatValues)=="table")')

    def test_failed_optional_data_load_does_not_leave_nil_tables(self):
        lua=LuaRuntime()
        lua.execute('function dofile() error("unavailable") end')
        lua.execute((ROOT/'Lua/aac_main.lua').read_text(encoding='utf-8-sig'))
        lua.execute('''
            for _,key in ipairs({"Recipes","PetEggs","MatWhiteValue","StatValues"}) do
                assert(type(AAC.Data[key])=="table")
                for i=1,100 do assert(AAC.Data[key][550389]==nil) end
            end
        ''')

if __name__ == '__main__': unittest.main()
