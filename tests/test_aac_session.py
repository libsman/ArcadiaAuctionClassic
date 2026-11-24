from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]

class ClassicSessionTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime()
        self.lua.execute('''
            closes=0; nativeEvents=0; marketResets=0; ticks=0; messages=0
            function frame()
              return {visible=false, RegisterEvent=function() end,
                IsVisible=function(s) return s.visible end,
                Show=function(s) s.visible=true end,
                Hide=function(s) if s.visible then s.visible=false; AAC.CloseSession() end end}
            end
            AAC_AuctionFrame=frame(); AuctionHubFrame=frame()
            AAC={Main={InitSaveVariables=function() end, InitGUI=function() end},
                 History={Init=function() end}, Events={},
                 Market={Reset=function() marketResets=marketResets+1 end,
                   Tick=function() ticks=ticks+1 end,
                   SystemMessage=function() messages=messages+1 end}}
            AuctionHub={FE={Hub=9095}, Enabled=function() return featureEnabled~=false end}
            function AuctionHubFrame_OnEvent() nativeEvents=nativeEvents+1 end
            function ShowUIPanel(f) f:Show() end
            function HideUIPanel(f) f:Hide() end
            function AuctionClose() closes=closes+1 end
            function SaveVariablesPerCharacter() end
            function GetTime() return 10 end
            DEFAULT_CHAT_FRAME={AddMessage=function(s,t) lastMessage=t end}
            SlashCmdList={}; StaticPopupDialogs={}
            function AAC_HookFunctions() end
        ''')
        self.lua.execute((ROOT/'addon/ArcadiaAuctionClassic/Lua/session.lua').read_text())
        self.lua.execute('AAC.Session.Init()')

    def test_classic_owns_open_native_is_untouched_when_disabled(self):
        self.lua.execute('''
          AuctionHubFrame_OnEvent(AuctionHubFrame,"AUCTION_OPEN")
          assert(nativeEvents==0)
          AAC.Session.Event(AAC_AuctionFrame,"AUCTION_OPEN")
          assert(AAC.CanRequest() and AAC_AuctionFrame:IsVisible())
          AAC.Session.SetEnabled(false)
          assert(closes==1 and not AAC.CanRequest())
          AuctionHubFrame_OnEvent(AuctionHubFrame,"AUCTION_OPEN")
          assert(nativeEvents==1)
        ''')

    def test_server_close_does_not_close_again_and_hooks_are_idempotent(self):
        self.lua.execute('''
          AAC.Session.Init(); AAC.Session.Init()
          AuctionHubFrame_OnEvent(AuctionHubFrame,"PLAYER_MONEY")
          assert(nativeEvents==1)
          AAC.Session.Event(AAC_AuctionFrame,"AUCTION_OPEN")
          AAC.Session.Event(AAC_AuctionFrame,"AUCTION_CLOSE")
          assert(closes==0 and not AAC.CanRequest())
          AAC.CloseSession(); assert(closes==0)
        ''')

    def test_tick_and_success_only_while_own_session(self):
        self.lua.execute('''
          AAC.Session.Tick(.1); assert(ticks==0)
          AAC.Session.Event(AAC_AuctionFrame,"AUCTION_OPEN")
          AAC.Session.Tick(.1); assert(ticks==1)
          AAC.Session.Event(AAC_AuctionFrame,"CHAT_MSG_SYSTEM","ok")
          assert(messages==1)
          HideUIPanel(AAC_AuctionFrame); assert(closes==1)
          AAC.Session.Tick(.1); assert(ticks==1)
        ''')

    def test_native_feature_off_keeps_native_error_screen(self):
        self.lua.execute('''
          featureEnabled=false
          AuctionHubFrame_OnEvent(AuctionHubFrame,"AUCTION_OPEN")
          AAC.Session.Event(AAC_AuctionFrame,"AUCTION_OPEN")
          assert(nativeEvents==1 and not AAC.CanRequest())
        ''')

    def test_pending_transaction_blocks_mode_change(self):
        self.lua.execute('''
          AAC.Session.Event(AAC_AuctionFrame,"AUCTION_OPEN")
          AAC.Market.Blocked=function() return true end
          assert(AAC.Session.SetEnabled(false)==false)
          assert(AAC.CanRequest() and closes==0)
        ''')

    def test_query_drains_before_native_mode_and_queue_is_cleared(self):
        self.lua.execute('''
          clears=0; closing=0; blocked=true
          AAC.Browse={Queue_Clear=function() clears=clears+1 end}
          AAC.Market.TransactionPending=function() return false end
          AAC.Market.Blocked=function() return blocked end
          AAC.Market.PrepareClose=function() closing=closing+1 end
          AAC.Session.Event(AAC_AuctionFrame,"AUCTION_OPEN")
          assert(clears==1)
          assert(AAC.Session.SetEnabled(false)==false)
          assert(AAC.CanRequest() and closes==0 and closing==1)
          blocked=false; AAC.Session.Tick(.1)
          assert(not AAC.CanRequest() and closes==1 and clears>=2)
        ''')

    def test_native_passive_notifications_and_retired_replies_still_flow(self):
        self.lua.execute('''
          AAC.Session.Event(AAC_AuctionFrame,"AUCTION_OPEN")
          AuctionHubFrame_OnEvent(AuctionHubFrame,"AUCTION_ITEM_SOLD")
          assert(nativeEvents==1)
          AAC.Session.Event(AAC_AuctionFrame,"AUCTION_CLOSE")
          AAC.Session.Event(AAC_AuctionFrame,"CHAT_MSG_SYSTEM","late")
          assert(messages==1)
        ''')

    def test_closed_window_mode_request_finishes_when_retired_fence_drains(self):
        self.lua.execute('''
          blocked=true; restarts=0
          AAC.Market.Blocked=function() return blocked end
          AAC.Market.NeedsRestart=function() return true end
          AAC.Session.SetEnabled(false)
          AAC.Session.Tick(.1)
          assert(AAC.Session.restartNotified and AAC.IsEnabled())
          blocked=false
          AAC.Session.Tick(.1)
          assert(not AAC.IsEnabled())
        ''')

    def test_optional_bulk_addon_only_runs_in_native_mode(self):
        self.lua.execute("""
          bulkCalls=0
          function CoAAuctionPreviewBag90() bulkCalls=bulkCalls+1; return 'native' end
          function CoAAHBestaetigen() bulkCalls=bulkCalls+1; return 'native' end
          AAC.Session.InstallCompatibility()
          assert(CoAAuctionPreviewBag90()==false and CoAAHBestaetigen()==false)
          assert(bulkCalls==0)
          AAC.Session.SetEnabled(false)
          assert(CoAAuctionPreviewBag90()=='native' and CoAAHBestaetigen()=='native')
          assert(bulkCalls==2)
        """)

    def test_native_to_classic_works_on_next_visit_without_restart(self):
        self.lua.execute('''
          AAC.Session.SetEnabled(false)
          AuctionHubFrame_OnEvent(AuctionHubFrame,"AUCTION_OPEN")
          assert(AAC.Session.nativeVisited)
          AAC.Session.SetEnabled(true)
          assert(AAC_ClassicSettings.enabled and AAC.IsEnabled())
          AAC.Session.Event(AAC_AuctionFrame,"AUCTION_OPEN")
          assert(AAC.CanRequest())
          AuctionHubFrame_OnEvent(AuctionHubFrame,"AUCTION_OPEN")
          assert(nativeEvents==1)
        ''')

    def test_native_pending_request_finishes_before_hot_switch(self):
        self.lua.execute('''
          AAC.Session.SetEnabled(false)
          AuctionHub.Browse={Loading=true, Pending={}}
          AAC.Market.Blocked=function() return false end
          assert(AAC.Session.SetEnabled(true)==false)
          assert(not AAC.IsEnabled())
          AuctionHub.Browse.Loading=false
          AuctionHub.Browse.Pending={ {Offer={}} }
          AAC.Session.Tick(.1)
          assert(not AAC.IsEnabled())
          AuctionHub.Browse.Pending={}
          AAC.Session.Tick(.1)
          assert(AAC.IsEnabled())
        ''')

if __name__ == '__main__': unittest.main()
