"""Focused Lua51 integration reproductions; no client or network transactions.

Reuses fixtures, but executes actual coordinator/history/money callbacks.
Run: python tests/trading_integration_cases.py
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
LUA = ROOT / 'addon/ArcadiaAuctionClassic/Lua'
sys.path.insert(0, str(ROOT / 'tests'))
from test_aac_seller_tools import SellerToolsTests
from test_aac_buyorders import BuyOrderTests


def source(name):
    return (LUA / name).read_text(encoding='utf-8')


def market_fixture():
    t = SellerToolsTests()
    t.setUp()
    t.lua.execute("""
        AAC.Events={};StaticPopupDialogs={};function TEXT(k)return k end
        function GetAuctionBrowseMaxItems()return 0 end
        function GetAuctionBrowseMaxPages()return 0 end
    """)
    t.lua.execute(source('aac_custompay.lua'))
    t.lua.execute("""
        own={{name='Food',count=10,mode='account',price=50,link='item:100'}}
        assert(AAC.SellerTools.CheckPrices());AAC.SellerTools.Tick();AAC.Market.Tick()
    """)
    return t


x = market_fixture()
x.lua.execute("""
    AAC.SellerTools.Close()
    AAC.SellerTools.Event('AUCTION_SEARCH_RESULT')
    AAC.SellerTools.Event('AUCTION_BROWSE_UPDATE');AAC.Market.Tick()
    assert(not AAC.Market.Blocked())
""")
print('PASS retired real coordinator request drains')
x = market_fixture()
x.lua.execute("""
    AAC.Market.StartSearch({},function()end,function()end,function()end)
    assert(AAC.SellerTools.rows[1].state=='unknown')
""")
print('PASS interrupted real coordinator search stays unknown')
x = SellerToolsTests()
x.setUp()
x.lua.execute("""
    own={{name='Food',count=10,mode='account',price=50,link='item:100'}}
    offers={{name='Food',count=10,mode='account',price=50,link='item:100',anon=true},
      {name='Food',count=10,mode='account',price=50,link='item:100',seller='Me'}}
    AAC.SellerTools.CheckPrices();AAC.SellerTools.Tick();job.publish(1,2,1);job.finish()
    assert(AAC.SellerTools.rows[1].state=='lowest')
""")
print('PASS identical anonymous competitor before named own is retained')

# Retain actual SetMoney and the actual paired OnTextChanged conversion.
x = SellerToolsTests()
x.setUp()
x.lua.execute("""
    AAC_SavedSettings={}
    AAC.Tools={SetDropDown=function()end,GetWhiteValue=function()return 1 end,FormatNumber=tostring}
    AAC.Sell.AuctionPayMoneyTypeChanged=function()end
    AAC.Sell.GetDurationText=function()return '' end;AAC.Sell.PROMOTION_STATUS={'none'}
    AAC.Sell.TestIsAuctionValid=function()end;AAC.Sell.UpdateSaleIncome=function()end
    AAC.Sell.UpdateProfit=function()end
    function MoneyModeFrame_SetSelected()end
    function GetAuctionItem()return 'Food','icon',50,0 end
    AAC.Sell.GetAuctionItem=GetAuctionItem
    AAC.MoneyFrame={IsValueValid=function()return true end}
    AAC_SellPriceBuyoutPPU={name='ppu',mode='account',GetName=function(s)return s.name end}
    AAC_SellPriceBuyout={name='total',mode='account',GetName=function(s)return s.name end}
    ppuAccount={text='',SetText=function(s,v)s.text=v
      AAC.Sell.PriceInput_OnTextChange(AAC_SellPriceBuyoutPPU,AAC_SellPriceBuyout,true)
      end,GetText=function(s)return s.text end}
    totalAccount={text='',SetText=function(s,v)s.text=v
      AAC.Sell.PriceInput_OnTextChange(AAC_SellPriceBuyoutPPU,AAC_SellPriceBuyout,false)
      end,GetText=function(s)return s.text end}
    function AAC.MoneyFrame.GetMoney(f)return tonumber(_G[f.name..'Account'].text) or 0 end
""")
money = source('moneyframe.lua')
sell = source('aac_sell.lua')
x.lua.execute('local MoneyFrame=AAC.MoneyFrame\n' + money[
    money.index('function MoneyFrame.SetMoney('):money.index('function MoneyFrame.GetMoney(')])
x.lua.execute('local Sell=AAC.Sell\n' + sell[
    sell.index('function Sell.PriceInput_OnTextChange('):sell.index('function Sell.HistoryEditbox_OnEditFocusGain(')])
x.lua.execute("""
    AAC.SellerTools.Record({itemID=100,name='Food',link='item:100',count=50,buyout=7,
      mode='account',duration=4})
    bag[1]={id=100,name='Food',count=50,link='item:100'}
    assert(AAC.SellerTools.StageRepeat(AAC.SellerTools.Recent()[1]));AAC.SellerTools.Tick()
    assert(tonumber(ppuAccount.text)==0.14 and tonumber(totalAccount.text)==7)
    assert(not AAC.Sell.internal_money_update)
""")
print('PASS real SetMoney/OnTextChanged callbacks preserve PPU 0.14 and total 7')

# Actual AutoFill implementation: delayed automatic calls must stop before
# parsing; explicit UI calls must release protection and reach normal parsing.
x.lua.execute('local Sell=AAC.Sell\n' + sell[
    sell.index('function Sell.AutoFillPriceFields('):sell.index('function Sell.AutoCalcPPU(')])
x.lua.execute("""
    parses=0;AAC.Tools.ParseLink=function()parses=parses+1;return nil end
    AAC.Sell.GetAuctionItem=function()return nil end
    AAC_SellHistoryButton={Disable=function()end}
    AAC.Sell.AutoFillPriceFields(true)
    assert(parses==0 and AAC.SellerTools.repeatAppliedLink=='item:100')
    AAC.Sell.AutoFillPriceFields()
    assert(parses==1 and AAC.SellerTools.repeatAppliedLink==nil)
""")
print('PASS actual AutoFill distinguishes delayed automation and explicit user input')
x.lua.execute('local Sell=AAC.Sell\n' + sell[
    sell.index('function Sell.RequestHistory('):sell.index('function AAC.Events.AUCTION_SELL_UPDATE(')])
x.lua.execute("""
    staged='item:101';mode=nil
    function GetAuctionItemLink()return staged end
    AAC.Tools.ParseLink=function(link)return link and tonumber(link:match(':(%d+)')) end
    AAC.Sell.GetAuctionItem=function()return staged and 'Sword +20',nil,1,0,mode end
    AAC_SellHistoryButton={Enable=function()enabled=true end,Disable=function()enabled=false end}
    AAC.Sell.AutoCalcPPU=function(_,_,id)pricedID=id;return 2 end
    function UIDropDownMenu_GetSelectedID()return 1 end
    AAC_SellAutoFillPercentBuyout={GetText=function()return '' end}
    AAC_SellAutoFillFormulaBuyoutout=AAC_SellAutoFillPercentBuyout
    AAC.HookItemLink='item:999';AAC.Sell.CurrentItem=999
    AAC.History={};AAC.History.RequestHistoryPopup=function(_,id)requestedID=id end
    AAC.Sell.AutoFillPriceFields();assert(enabled and pricedID==101)
    AAC.Sell.RequestHistory();assert(requestedID==101)
    staged='item:102';AAC.Sell.RequestHistory();assert(requestedID==102)
    staged=nil;AAC.Sell.AutoFillPriceFields();assert(not enabled)
    staged='item:103';mode='copper';AAC.Sell.AutoFillPriceFields();assert(enabled and pricedID==200000)
    mode='account';AAC.Sell.AutoFillPriceFields();assert(enabled and pricedID==200003)
""")
print('PASS staged item drives history and pricing independently of obsolete hook and upgraded name')


x = BuyOrderTests()
x.setUp()
x.lua.execute("""
    AAC.SellerTools={Close=function()end}
    AAC_TradingPanel={Show=function()end,Hide=function()end}
    AAC_TradingQuantity={SetText=function()end};AAC_TradingPrice={SetText=function()end}
    AAC.SellerTools.ItemIDFromLink=function()return 100 end
    function ParseHyperlink()return 'item','64','Food' end
""")
x.lua.execute(source('trading_ui.lua'))
x.lua.execute("""
    AAC.TradingUI.Render=function()end
    assert(AAC.TradingUI.Open('recent'));assert(B.closed)
    assert(not AAC.TradingUI.PickItem('item:100'));assert(B.closed)
    assert(AAC.TradingUI.mode=='recent')
    assert(AAC.TradingUI.Open('create'))
    assert(AAC.TradingUI.PickItem('item:100'));assert(not B.closed)
    assert(B.PreviewCreate(100,100,10,'copper'));assert(sends==0)
""")
print('PASS selling tools reject buy-order input; create accepts without sending')
