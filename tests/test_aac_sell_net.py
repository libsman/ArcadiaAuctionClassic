from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]/'addon/ArcadiaAuctionClassic'
class SellNetTests(unittest.TestCase):
 def setUp(self):
  self.lua=LuaRuntime()
  self.lua.execute('AAC={Events={}};StaticPopupDialogs={};function TEXT(k)return k end;AUCTION_PROLONG_SELL="p";AUCTION_PROMOTE_SELL="p";AUCTION_PROMOTE_SELL_ITEM="p";AUCTION_PROMOTETYPES="p"')
  self.lua.execute((ROOT/'Lua/aac_sell.lua').read_text(encoding='utf-8-sig'))
 def test_inverse_uses_actual_currency_rate_no_buyorder_minimum(self):
  self.lua.execute('''
  IsFunctionEnable=function()return true end
  GetAuctionFeeRates=function()return 500,700,0,250 end
  assert(AAC.Sell.GrossForNet(100,'copper',false)==105)
  assert(AAC.Sell.GrossForNet(100,'account',false)==107)
  assert(AAC.Sell.GrossForNet(100,'account',true)==102)
  assert(AAC.Sell.GrossForNet(1,'account',false)==1)
  for _,r in ipairs({0,250,500,700,9999}) do
   GetAuctionFeeRates=function()return r,r,0,r end
   for n=1,200 do
    local g=AAC.Sell.GrossForNet(n,'copper',false)
    assert(g-AAC.Sell.GetSaleFee(g,'copper',false)>=n)
    assert(g-1-AAC.Sell.GetSaleFee(g-1,'copper',false)<n)
   end
  end
  GetAuctionFeeRates=function()return 10000,10000,0,10000 end
  assert(AAC.Sell.GrossForNet(100,'copper',false)==nil)
  GetAuctionFeeRates=nil
  assert(AAC.Sell.GrossForNet(100,'copper',false)==nil)
  ''')
 def test_editing_net_updates_gross_and_paired_fields_without_recursion(self):
  self.lua.execute("""
  local S=AAC.Sell
  IsFunctionEnable=function()return true end
  GetAuctionFeeRates=function()return 500,500,0,250 end
  local count=10
  S.GetAuctionItem=function()return 'Food',nil,count,nil,S.MoneyAuction and 'account' or nil end
  AAC.Tools={GetWhiteValue=function()return 1 end}
  AAC_SavedSettings={}
  function widget(name)
   local f={value=0,mode='account',GetName=function()return name end,SetText=function()end}
   _G[name]=f;_G[name..'Label']={SetText=function()end}
   for _,suffix in ipairs({'Gold','Account'})do _G[name..suffix]={SetEnable=function(self,v)self.enabled=v end}end
   return f
  end
  for _,n in ipairs({'AAC_SellPriceBuyout','AAC_SellPriceBuyoutPPU','AAC_SellPriceNet','AAC_SellPriceNetPPU'})do widget(n)end
  AAC_SellIncomeText={SetText=function()end}
  AAC.MoneyFrame={GetMoney=function(f)return f.value end,IsValueValid=function()return true end,
   SetMode=function(f,m)f.mode=m end,
   SetMoney=function(f,n)
    f.value=n
    if f==AAC_SellPriceBuyout then S.OnOfferChange3() elseif f==AAC_SellPriceBuyoutPPU then S.OnOfferChange4() else S.NetPriceChanged(f)end
   end}
  S.UpdateProfit=function()S.UpdateSaleIncome()end
  S.TestIsAuctionValid=function()S.UpdateSaleIncome()end
  S.PayMoneyMode='account'
  AAC_SellPriceNet.value=100;S.NetPriceChanged(AAC_SellPriceNet)
  assert(AAC_SellPriceBuyout.value==105 and AAC_SellPriceNetPPU.value==10)
  assert(AAC_SellPriceBuyoutPPU.value==10.5)
  AAC_SellPriceNetPPU.value=20;S.NetPriceChanged(AAC_SellPriceNetPPU)
  assert(AAC_SellPriceBuyout.value==210 and AAC_SellPriceNet.value==200)
  AAC.MoneyFrame.SetMoney(AAC_SellPriceBuyout,100)
  assert(AAC_SellPriceNet.value==95 and AAC_SellPriceNetPPU.value==9.5)
  S.MoneyAuction=true;count=1000
  AAC_SellPriceNet.value=100;S.NetPriceChanged(AAC_SellPriceNet)
  assert(AAC_SellPriceBuyout.value==102 and AAC_SellPriceNetPPU.value==10)
  GetAuctionFeeRates=nil;S.UpdateNetPrices()
  assert(not AAC_SellPriceNetAccount.enabled and AAC_SellPriceNet.value==0)
  assert(AAC_SellPriceBuyout.value==102)
  """)
if __name__=='__main__':unittest.main()
