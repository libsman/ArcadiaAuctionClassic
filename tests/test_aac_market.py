import unittest
from pathlib import Path

from lupa.lua51 import LuaRuntime


LUA = Path(__file__).resolve().parents[1] / "addon" / "ArcadiaAuctionClassic" / "Lua"


class ClassicMarketTests(unittest.TestCase):
    def test_bid_requires_current_five_percent_increment(self):
        self.lua.execute('''
            local item={dbid=99, auctionid=1, link="item", count=1, name="Item",
                moneyMode="copper", bidPrice=100, buyoutPrice=200}
            AAC.Pay.PayAuction(item, 104, false, AAC.Pay.AuctionType.Browse)
            assert(popup==nil and sent==nil)
        ''')

    def setUp(self):
        self.lua = LuaRuntime()
        self.lua.execute('''
            now = 0
            AAC = { Events = {}, CanRequest = function() return open end }
            open = true
            TEXT = function(key) return key end
            StaticPopupDialogs = {}
            StaticPopup_Show = function(key) popup = key end
            GetPlayerMoney = function() return 10000 end
            GetTime = function() return now end
            GetAuctionBrowseMaxItems = function() return 251 end
            GetAuctionBrowseMaxPages = function() return 2 end
            GetAuctionBrowseItemInfo = function(p, i)
                return i, "Item", 2, 1, "", 1, 100, "Seller", false, "copper", price, 200, 0, id + (p - 1) * 250 + i - 1
            end
            GetAuctionBrowseItemLink = function() return "|Hitem:123|h[Item]|h" end
            AuctionBrowseBuyItemByID = function(id, amount) sent = { id, amount } end
            AuctionBrowseNextPage = function(page) nextPage = page; return true end
            id = 99
            price = 100
        ''')
        self.lua.execute((LUA / "aac_custompay.lua").read_text(encoding="utf-8-sig"))

    def test_buyout_needs_confirmation_and_uses_dbid_with_confirmed_price(self):
        self.lua.execute('''
            local M = AAC.Market
            GetAuctionBrowseMaxItems = function() return 1 end
            GetAuctionBrowseMaxPages = function() return 1 end
            owner = { CurrentCachePage = 1 }
            M.StartSearch(owner, function() end, function() end, function() cached = true end)
            M.Tick()
            M.SearchEvent(owner, "AUCTION_BROWSE_UPDATE")
            M.SearchEvent(owner, "AUCTION_SEARCH_RESULT")
            M.Tick()
            assert(cached)
            offer = { auctionid = 1, dbid = 99, page = 1, slot = 1, owner = owner,
                epoch = M.Epoch, itemid = 123, name = "Item", count = 2, seller = "Seller",
                cacheCount = 2, link = GetAuctionBrowseItemLink(1), moneyMode = "copper",
                bidPrice = 100, buyoutPrice = 200 }
            AAC.Pay.PayAuction(offer, 0, true, AAC.Pay.AuctionType.Browse)
            assert(not sent)
            price = 101
            StaticPopupDialogs[popup].OnAccept()
            assert(not sent)
            price = 100
            -- The client can regenerate gear hyperlink fields while the auction is unchanged.
            GetAuctionBrowseItemLink = function() return "|Hitem:123 1 20106f|h[Item]|h" end
            AAC.Pay.PayAuction(offer, 0, true, AAC.Pay.AuctionType.Browse)
            StaticPopupDialogs[popup].OnAccept()
            assert(sent[1] == 99 and sent[2] == 200)
            sent = nil
            StaticPopupDialogs[popup].OnAccept()
            assert(not sent)
        ''')

    def test_page_waits_for_events_and_server_pacing(self):
        self.lua.execute('''
            local M = AAC.Market
            owner = {}
            pages = 0
            assert(M.StartSearch(owner, function() search = true end, function() end,
                function(page) pages = pages + 1 end))
            M.Tick()
            assert(search and pages == 0)
            M.SearchEvent(owner, "AUCTION_SEARCH_RESULT")
            M.Tick()
            assert(pages == 0)
            M.SearchEvent(owner, "AUCTION_BROWSE_UPDATE")
            M.Tick()
            assert(pages == 1 and not nextPage)
            now = 3.19
            M.Tick()
            assert(not nextPage)
            now = 3.21
            M.Tick()
            assert(nextPage == 2 and pages == 1)
            M.SearchEvent(owner, "AUCTION_SEARCH_RESULT")
            M.Tick()
            assert(pages == 2)
        ''')

    def test_unresolved_search_cannot_feed_next_tab(self):
        self.lua.execute('''
            local M = AAC.Market
            owner = {}
            other = {}
            assert(M.StartSearch(owner, function() end, function() end,
                function() error("a cancelled search published data") end))
            M.Tick()
            M.StopSearch(owner)
            assert(M.StartSearch(other, function() nextSearch = true end, function() end, function() end))
            now = 10
            M.Tick()
            assert(not nextSearch)
            M.SearchEvent(other, "AUCTION_BROWSE_UPDATE")
            M.SearchEvent(other, "AUCTION_SEARCH_RESULT")
            M.Tick()
            assert(not nextSearch)
            M.SearchEvent(owner, "AUCTION_BROWSE_UPDATE")
            M.SearchEvent(owner, "AUCTION_SEARCH_RESULT")
            M.Tick()
            assert(nextSearch)
        ''')

    def test_history_timeout_does_not_assign_late_response_to_next_item(self):
        self.lua.execute((LUA / "aac_history.lua").read_text(encoding="utf-8-sig"))
        self.lua.execute('''
            local H, M = AAC.History, AAC.Market
            received = {}
            AuctionItemHistoryRequestByID = function(id, variant)
                assert(variant == 0)
                request = id
            end
            GetAuctionHistoryItemNums = function() return 1 end
            replyID = 1001
            GetAuctionHistoryItemLink = function() return string.format("|Hitem:%x|h[Item]|h", replyID) end
            H.Queue_AddHistory = function(id) received[#received + 1] = id end
            H.List_Show = function() displayed = H.curItem end
            H.RequestHistoryPopup(41, 1001)
            M.Tick()
            assert(request == 1001)
            now = 4
            H.RequestHistoryPopup(42, 1002)
            now = 5
            M.Tick()
            assert(request == 1002)
            AAC.Events.AUCTION_HISTORY_SHOW()
            assert(#received == 0 and not displayed)
            M.Tick()
            assert(request == 1002)
            replyID = 1002
            AAC.Events.AUCTION_HISTORY_SHOW()
            assert(displayed == 1002 and #received == 1 and received[1] == 1002)
        ''')

    def test_own_bid_uses_selected_visible_row_and_requires_confirm(self):
        self.lua.execute((LUA / "aac_bid.lua").read_text(encoding="utf-8-sig"))
        self.lua.execute('''
            local B, M = AAC.Bid, AAC.Market
            local link = "|Hitem:123|h[Item]|h"
            B.Revision = 1
            B.Selection = 2
            AAC_BidListItem2 = { index = 3 }
            AAC.MoneyFrame = { GetMoney = function() return 120 end }
            B.List.Items = {
                {}, {},
                { auctionid = 19, revision = 1, cacheCount = 2, name = "Item", seller = "Seller",
                  status = false, bidPrice = 100, buyoutPrice = 200, link = link,
                  moneyMode = "copper", count = 2 }
            }
            GetAuctionBidItemInfo = function(i)
                assert(i == 19)
                return "Item", 2, 1, "", 1, 40, "Seller", false, "copper", 100, 200, 0
            end
            GetAuctionBidItemLink = function(i) return link end
            AuctionBidBuyItem = function(index, amount) sent = { index, amount } end
            B.BidSelection()
            assert(popup == "AAC_MARKET_BID" and not sent)
            B.Revision = 2
            StaticPopupDialogs[popup].OnAccept()
            assert(not sent)
            B.List.Items[3].revision = 2
            B.BidSelection()
            StaticPopupDialogs[popup].OnAccept()
            assert(sent[1] == 19 and sent[2] == 120 and M.TransactionPending())
            B.Revision = 3
            B.List.Items[3].status = true
            B.List.Items[3].bidPrice = 120
            M.Tick()
            assert(not M.TransactionPending())
        ''')

    def install_sell_mock(self):
        self.lua.execute('''
            AAC_SavedSettings = { SellDurationSelected = 4, SellPromoteDropDown = 1 }
            AAC.MoneyFrame = {
                GetMoney = function() return sellPrice end,
                IsValueValid = function() return true end,
            }
            GetAuctionItem = function()
                if staged then return "Item", "texture", 2, 100 end
            end
            GetAuctionItemLink = function() return staged end
            ParseHyperlink = function(link) return "item", link:match("item:(%x+)"), "Item" end
            Prestige_GetChargeCount = function() return 0 end
            Auction_GetTax = function() return 25 end
            GetAuctionNumSellItems = function() return own and 1 or 0 end
            GetAuctionSellItemLink = function() if own then return link end end
            GetAuctionSellItemInfo = function()
                if own then
                    return "Item", 2, 1, "", 1, 40, "", "copper", ownPrice, ownPrice, 0, 0
                end
            end
            AUCTION_PROLONG_SELL = "Prolong"
            AUCTION_PROMOTE_SELL = "Promote"
            AUCTION_PROMOTE_SELL_ITEM = "Promote"
            AUCTION_PROMOTETYPES = "Promotion"
            sellPrice = 900
            ownPrice = 900
            link = "|Hitem:ab|h[Item]|h"
            staged = link
            CreateAuctionItem = function(...) sent = {...} end
            AuctionCancelSell = function(i) cancelIndex = i end
        ''')
        self.lua.execute((LUA / "aac_sell.lua").read_text(encoding="utf-8-sig"))
        self.lua.execute('''
            AAC.Sell.CanAuctionItemLink = function() return true end
            AAC.Sell.List_Update = function() end
            AAC.Sell.UpdateLastPrice = function(...) saved = {...} end
        ''')

    def test_guild_sale_rechecks_right_and_sends_native_flag(self):
        self.install_sell_mock()
        self.lua.execute("""
            IsInGuild=function()return true end
            IsFunctionEnable=function()return true end
            right=true; GuildHub={RankRoles=function()return {GuildSales=right} end}
            IsAuctionItemAccountMoneyTrade=function()return true end
            GetAuctionFeeRates=function()return 500,500,500,500 end
            local S=AAC.Sell;S.PayMoneyMode="account";S.PayMoneyType=2;S.ForGuild=true
            assert(S.GuildSaleAllowed())
            S.ConfirmButton_OnClick();right=false
            StaticPopupDialogs[popup].OnAccept();assert(not sent)
            right=true;S.ForGuild=true;S.ConfirmButton_OnClick()
            StaticPopupDialogs[popup].OnAccept();assert(sent and sent[7]==true)
        """)

    def test_guild_sale_never_falls_back_to_private_or_currency_sale(self):
        self.install_sell_mock()
        self.lua.execute("""
            IsInGuild=function()return true end
            IsFunctionEnable=function()return true end
            GuildHub={RankRoles=function()return {GuildSales=true} end}
            local S=AAC.Sell;S.ForGuild=true
            assert(not S.GuildSaleAllowed());S.ConfirmButton_OnClick();assert(not popup and not sent)
            S.PayMoneyMode="account";S.MoneyAuction=true
            assert(not S.GuildSaleAllowed())
            S.MoneyAuction=false;GuildHub=nil;assert(not S.GuildSaleAllowed())
        """)

    def test_sell_confirms_current_form_and_waits_for_owned_offer(self):
        self.install_sell_mock()
        self.lua.execute('''
            local S, M = AAC.Sell, AAC.Market
            S.ConfirmButton_OnClick()
            assert(popup == "AAC_MARKET_SELL" and not sent)
            sellPrice = 1200
            StaticPopupDialogs[popup].OnAccept()
            assert(not sent)
            sellPrice = 900
            S.ConfirmButton_OnClick()
            StaticPopupDialogs[popup].OnAccept()
            assert(sent[1] == 4 and sent[2] == 900 and sent[3] == 1 and sent[4] == 900)
            assert(not saved and M.TransactionPending())
            own = true
            AAC.Events.AUCTION_SELL_UPDATE()
            M.Tick()
            assert(saved and not M.TransactionPending())
            staged = nil
            M.Tick()
            assert(saved[1] == 171 and saved[2] == 450 and not M.TransactionPending())
        ''')

    def test_sell_confirmation_accepts_regenerated_link_and_native_early_own_update(self):
        self.install_sell_mock()
        self.lua.execute('''local S,M=AAC.Sell,AAC.Market
        S.ConfirmButton_OnClick();StaticPopupDialogs[popup].OnAccept()
        link="|Hitem:ab 1 changed|h[Item]|h";own=true
        AAC.Events.AUCTION_SELL_UPDATE();M.Tick()
        assert(saved and not M.TransactionPending())
        ''')

    def test_sell_accepts_unchanged_slot_refresh_during_confirmation(self):
        self.install_sell_mock()
        self.lua.execute('''
            AAC.Sell.ConfirmButton_OnClick()
            AAC.Sell.Item_Update=function() end
            AAC.Tools={ParseLink=function() return 171 end}
            AAC.Events.AUCTION_AUCTION_INFO_UPDATE()
            StaticPopupDialogs[popup].OnAccept()
            assert(sent and sent[2]==900, "Unchanged slot refresh must not invalidate confirmation")
        ''')

    def test_sell_rejects_changed_live_commission_and_updates_net_preview(self):
        self.install_sell_mock()
        self.lua.execute('''
            IsFunctionEnable=function() return true end
            rate=500
            GetAuctionFeeRates=function() return rate,rate,0,rate end
            AAC_SellIncomeText={SetText=function(self,t) preview=t end}
            AAC.Sell.UpdateSaleIncome()
            assert(preview:find("855",1,true) and preview:find("45",1,true))
            assert(not sent)
            AAC.Sell.ConfirmButton_OnClick()
            rate=700
            StaticPopupDialogs[popup].OnAccept()
            assert(not sent)
            AAC.Sell.ConfirmButton_OnClick()
            StaticPopupDialogs[popup].OnAccept()
            assert(sent and sent[2]==900)
        ''')

    def test_short_sale_confirmation_and_silent_normal_progress(self):
        self.install_sell_mock()
        self.lua.execute('''
            IsFunctionEnable=function() return true end
            GetAuctionFeeRates=function() return 500,500,500,500 end
            StaticPopup_Show=function(key,text) popup=key; description=text end
            notices={}
            AAC.Market.Notice=function(text) notices[#notices+1]=text end
            AAC.Sell.ConfirmButton_OnClick()
            assert(description:find("Fee (5%)",1,true))
            assert(description:find("You receive: 855",1,true))
            assert(description:find("Listing: 25",1,true))
            assert(not description:find("AUCTION_TAX",1,true))
            assert(not description:find("costs are separate",1,true))
            StaticPopupDialogs[popup].OnAccept()
            assert(sent and #notices==0)
            AAC.Market.Confirmed()
            assert(#notices==0)
            AAC.Market.Changed()
            assert(#notices==1)
        ''')

    def test_cancel_revalidates_own_row_at_confirmation(self):
        self.install_sell_mock()
        self.lua.execute('''
            local S, M = AAC.Sell, AAC.Market
            own = true
            local record = { revision = 0, realPosition = 1, name = "Item", count = 2,
                link = link, bidder = "", moneyMode = "copper", buyoutPrice = 900,
                bidPrice = 900, promoteType = 0 }
            S.GetSelectedListInfo = function() return record end
            S.ListCancelButton_OnClick()
            ownPrice = 1000
            StaticPopupDialogs[popup].OnAccept()
            assert(not cancelIndex)
            ownPrice = 900
            S.ListCancelButton_OnClick()
            assert(popup == "AAC_MARKET_CANCEL" and not cancelIndex)
            StaticPopupDialogs[popup].OnAccept()
            assert(cancelIndex == 1 and M.TransactionPending())
            own = nil
            AAC.Events.AUCTION_SELL_UPDATE()
            M.Tick()
            assert(not M.TransactionPending())
        ''')

    def test_confirmed_batch_waits_for_actual_buyout_success_before_second_request(self):
        self.lua.execute('''
            local M = AAC.Market
            TEXT = function(key)
                if key == "SYS_AC_BUYOUT_SUCCESS" then return "Bought %s." end
                return key
            end
            GetAuctionBrowseMaxItems = function() return 2 end
            GetAuctionBrowseMaxPages = function() return 1 end
            owner = { RemovePurchased = function(index) removed = index end }
            assert(M.StartSearch(owner, function() end, function() end, function() end))
            M.Tick()
            M.SearchEvent(owner, "AUCTION_BROWSE_UPDATE")
            M.SearchEvent(owner, "AUCTION_SEARCH_RESULT")
            M.Tick()
            local function offer(i)
                return { auctionid = i, dbid = 98 + i, page = 1, slot = i,
                    owner = owner, epoch = M.Epoch, cacheCount = 2, count = 2, seller = "Seller",
                    itemid = 123, name = "Item", link = GetAuctionBrowseItemLink(i), moneyMode = "copper",
                    bidPrice = 100, buyoutPrice = 200 }
            end
            offer1, offer2 = offer(1), offer(2)
            AAC.Pay.PayMultiAuction({offer1, offer2}, AAC.Pay.AuctionType.Browse)
            assert(popup == "AAC_MARKET_MULTI" and not sent)
            StaticPopupDialogs[popup].OnAccept()
            assert(sent[1] == 99 and M.TransactionPending() and not removed)
            M.Tick()
            assert(sent[1] == 99)
            M.SystemMessage("Bought 1x " .. offer1.link .. ".")
            M.Tick()
            assert(sent[1] == 99 and not removed)
            M.SystemMessage("Bought 2x " .. offer1.link .. ".")
            assert(removed == 1 and sent[1] == 99 and M.TransactionPending())
            M.Tick()
            assert(sent[1] == 100)
            M.SystemMessage("Bought 2x " .. offer2.link .. ".")
            assert(removed == 2 and not M.TransactionPending())
        ''')

    def test_gear_receipt_with_regenerated_link_confirms_and_unblocks_next_purchase(self):
        self.lua.execute('''
            local M=AAC.Market
            TEXT=function(k) if k=="SYS_AC_BUYOUT_SUCCESS" then return 'Kauf von "%s" war erfolgreich.' end return k end
            GetAuctionBrowseMaxItems=function()return 1 end
            GetAuctionBrowseMaxPages=function()return 1 end
            local suffix=" 00000000000000000000000000000000000000000000000000|h|cffffffff[Darstellerlangrobe]|r|h"
            local listed="|Hitem:35cc8 1 56000a64 d1ef 0 0 0 0 0 0 186a0 36a1 35cc8"..suffix
            local received="|Hitem:35cc8 1 ff000a64 d1ef 0 0 0 0 0 0 186a0 175d 35cc8"..suffix
            GetAuctionBrowseItemLink=function()return listed end
            owner={RemovePurchased=function(i)removed=(removed or 0)+1 end}
            M.StartSearch(owner,function()end,function()end,function()end);M.Tick()
            M.SearchEvent(owner,"AUCTION_BROWSE_UPDATE");M.SearchEvent(owner,"AUCTION_SEARCH_RESULT");M.Tick()
            local item={auctionid=1,dbid=99,page=1,slot=1,owner=owner,epoch=M.Epoch,
                cacheCount=2,count=2,seller="Seller",link=listed,moneyMode="copper",bidPrice=100,buyoutPrice=200}
            AAC.Pay.PayAuction(item,0,true,AAC.Pay.AuctionType.Browse);StaticPopupDialogs[popup].OnAccept()
            local function receipt(link,count) M.SystemMessage('Kauf von "'..count..'x '..link..'" war erfolgreich.') end
            receipt(received,1);assert(M.TransactionPending() and not removed)
            receipt(received:gsub('d1ef','d1ee'),2);assert(M.TransactionPending() and not removed)
            receipt(received:gsub('ff000a64','ff000a65'),2);assert(M.TransactionPending() and not removed)
            receipt(received,2);assert(not M.TransactionPending() and removed==1)
            receipt(received,2);assert(removed==1)
            -- A later explicit purchase remains possible without waiting for the timeout.
            id=100; item.dbid=100
            AAC.Pay.PayAuction(item,0,true,AAC.Pay.AuctionType.Browse);StaticPopupDialogs[popup].OnAccept()
            assert(sent[1]==100 and M.TransactionPending())
        ''')

    def test_reused_page_rows_are_rejected(self):
        self.lua.execute('''
            local M = AAC.Market
            local get = GetAuctionBrowseItemInfo
            GetAuctionBrowseItemInfo = function(page, row) return get(1, row) end
            owner = {}
            pages = 0
            M.StartSearch(owner, function() end, function(message) failed = message end,
                function() pages = pages + 1 end)
            M.Tick()
            M.SearchEvent(owner, "AUCTION_BROWSE_UPDATE")
            M.SearchEvent(owner, "AUCTION_SEARCH_RESULT")
            M.Tick()
            now = 3.3
            M.Tick()
            M.SearchEvent(owner, "AUCTION_SEARCH_RESULT")
            M.Tick()
            assert(pages == 1 and not failed)
            now = 19
            M.Tick()
            assert(pages == 1 and failed)
        ''')

    def test_no_result_warning_does_not_publish_old_cached_rows(self):
        self.lua.execute('''
            local M = AAC.Market
            owner = {}
            M.StartSearch(owner, function() end, function() end,
                function(page, total, pages) assert(total == 0 and pages == 0); empty = true end)
            M.Tick()
            M.WarningMessage(TEXT("SYS_AC_SEARCH_EMPTY"))
            M.SearchEvent(owner, "AUCTION_SEARCH_RESULT")
            M.Tick()
            assert(empty and not M.Active())
        ''')

    def test_search_timeout_releases_abandoned_query_and_sends_new_query(self):
        self.lua.execute('''
            local M = AAC.Market
            owner, other = {}, {}
            M.StartSearch(owner, function() end, function(message) failed = message end, function() end)
            M.Tick()
            M.StartSearch(other, function() second = true end, function(message) timeout = message end, function() end)
            now = 16
            M.Tick()
            assert(second and not timeout)
        ''')

    def test_missing_search_reply_retries_once_and_then_unblocks(self):
        self.lua.execute('''local M=AAC.Market
            count=0; published=0
            M.StartSearch({},function() count=count+1 end,function(msg) failed=msg end,function() published=published+1 end)
            M.Tick();now=16;M.Tick();assert(count==2 and published==0)
            now=32;M.Tick();assert(failed and not M.Active() and not M.NeedsRestart() and count==2)
            assert(M.StartSearch({},function() count=count+1 end,function() end,function() end))
            now=36;M.Tick();assert(count==3)
        ''')

    def test_search_retry_only_publishes_after_events_and_valid_cache(self):
        self.lua.execute('''local M=AAC.Market
            local owner={};local published=0;local sends=0
            GetAuctionBrowseMaxItems=function() return 1 end
            GetAuctionBrowseMaxPages=function() return 1 end
            M.StartSearch(owner,function() sends=sends+1 end,function() end,function() published=published+1 end)
            M.Tick();now=16;M.Tick();assert(sends==2 and published==0)
            M.SearchEvent(owner,'AUCTION_BROWSE_UPDATE');M.Tick();assert(published==0)
            M.SearchEvent(owner,'AUCTION_SEARCH_RESULT');M.Tick();assert(published==1 and not M.Active())
        ''')

    def test_reopen_cannot_adopt_previous_session_browse_reply(self):
        self.lua.execute('''
            local M = AAC.Market
            old, fresh = {}, {}
            M.StartSearch(old, function() end, function() end, function() error("old page") end)
            M.Tick()
            open = false
            M.Reset()
            open = true
            M.Reset()
            now = 4
            M.StartSearch(fresh, function() sentFresh = true end, function() end,
                function() publishedFresh = true end)
            M.Tick()
            assert(not sentFresh)
            M.SearchEvent(old, "AUCTION_BROWSE_UPDATE")
            M.SearchEvent(old, "AUCTION_SEARCH_RESULT")
            M.Tick()
            assert(sentFresh and not publishedFresh)
            M.SearchEvent(fresh, "AUCTION_BROWSE_UPDATE")
            M.SearchEvent(fresh, "AUCTION_SEARCH_RESULT")
            M.Tick()
            assert(publishedFresh)
        ''')

    def test_reopen_blocks_identical_buy_until_unlabelled_reply_drains(self):
        self.lua.execute('''
            local M, P = AAC.Market, AAC.Pay
            TEXT = function(key)
                if key == "SYS_AC_BUYOUT_SUCCESS" then return "Bought %s." end
                return key
            end
            GetAuctionBrowseMaxItems = function() return 1 end
            GetAuctionBrowseMaxPages = function() return 1 end
            owner = { RemovePurchased = function() removed = true end }
            local function load()
                M.StartSearch(owner, function() end, function() end, function() end)
                M.Tick()
                M.SearchEvent(owner, "AUCTION_BROWSE_UPDATE")
                M.SearchEvent(owner, "AUCTION_SEARCH_RESULT")
                M.Tick()
                return { auctionid = 1, dbid = id, page = 1, slot = 1,
                    owner = owner, epoch = M.Epoch, cacheCount = 2, count = 2, seller = "Seller",
                    itemid = 123, name = "Item", link = GetAuctionBrowseItemLink(1), moneyMode = "copper",
                    bidPrice = 100, buyoutPrice = 200 }
            end
            oldOffer = load()
            P.PayAuction(oldOffer, 0, true, P.AuctionType.Browse)
            StaticPopupDialogs[popup].OnAccept()
            assert(sent[1] == 99)
            sent, popup = nil, nil
            open = false
            M.Reset()
            open = true
            id, now = 100, 4
            freshOffer = load()
            P.PayAuction(freshOffer, 0, true, P.AuctionType.Browse)
            assert(not popup and not sent)
            M.SystemMessage("Bought 2x " .. oldOffer.link .. ".")
            assert(not removed and not M.TransactionPending())
            P.PayAuction(freshOffer, 0, true, P.AuctionType.Browse)
            StaticPopupDialogs[popup].OnAccept()
            assert(sent[1] == 100 and M.TransactionPending())
        ''')

    def test_prepare_close_drains_search_and_history_without_sending_queue(self):
        self.lua.execute((LUA / "aac_history.lua").read_text(encoding="utf-8-sig"))
        self.lua.execute('''
            local M, H = AAC.Market, AAC.History
            AuctionItemHistoryRequestByID = function(id) historyRequest = id end
            H.Queue_Insertitem(1, "Item", "link", 100)
            H.Queue_Insertitem(2, "Item", "link", 200)
            M.Tick()
            assert(historyRequest == 100)
            local old = {}
            M.StartSearch(old, function() sent = true end, function() end,
                function() error("published while closing") end)
            M.Tick()
            assert(sent)
            M.PrepareClose()
            assert(M.IsClosing() and M.Blocked())
            M.SearchEvent(old, "AUCTION_SEARCH_RESULT")
            M.SearchEvent(old, "AUCTION_BROWSE_UPDATE")
            M.Tick()
            assert(M.Blocked())
            AAC.Events.AUCTION_HISTORY_HIDE()
            now = 20
            M.Tick()
            assert(not M.Blocked() and historyRequest == 100)
            assert(not M.StartSearch({}, function() end, function() end, function() end))
        ''')

    def test_bid_confirmation_rejects_an_already_highest_twin(self):
        self.lua.execute((LUA / "aac_bid.lua").read_text(encoding="utf-8-sig"))
        self.lua.execute('''
            local B, M, P = AAC.Bid, AAC.Market, AAC.Pay
            local link = "|Hitem:123|h[Item]|h"
            local function offer(index, price, status)
                return { auctionid = index, revision = 1, cacheCount = 2, name = "Item",
                    seller = "Seller", status = status, bidPrice = price, buyoutPrice = 200,
                    link = link, moneyMode = "copper", count = 2 }
            end
            local requested = offer(19, 100, false)
            B.Revision = 1
            B.List.Items = { requested, offer(21, 120, true) }
            GetAuctionBidItemInfo = function(i)
                assert(i == 19)
                return "Item", 2, 1, "", 1, 40, "Seller", false, "copper", 100, 200, 0
            end
            GetAuctionBidItemLink = function(i) return link end
            AuctionBidBuyItem = function(index, amount) sent = { index, amount } end
            P.PayAuction(requested, 120, false, P.AuctionType.Bid)
            StaticPopupDialogs[popup].OnAccept()
            assert(sent[1] == 19)
            B.Revision = 2
            M.Tick()
            assert(M.TransactionPending())
        ''')

    def test_retired_search_releases_fence_from_events_while_inactive(self):
        self.lua.execute('''
            local M = AAC.Market
            owner = {}
            M.StartSearch(owner, function() end, function() end, function() error("published old rows") end)
            M.Tick()
            open = false
            M.Reset()
            assert(M.Blocked())
            M.SearchEvent(owner, "AUCTION_SEARCH_RESULT")
            assert(M.Blocked())
            M.SearchEvent(owner, "AUCTION_BROWSE_UPDATE")
            assert(not M.Blocked())
        ''')
