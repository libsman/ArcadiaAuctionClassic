-- Arcadia Auction Classic. Session ownership only; no engine API replacements.
AAC.Session = AAC.Session or {}
local S = AAC.Session
local function say(key, fallback)
    DEFAULT_CHAT_FRAME:AddMessage("AAC: " .. (_G[key] or fallback))
end

function AAC.FeatureEnabled(name)
    local hub = AuctionHub
    if not hub or type(hub.Enabled) ~= "function" then return false end
    local id = type(name) == "number" and name or (hub.FE and hub.FE[name or "Hub"])
    if not id then return false end
    local ok, enabled = pcall(hub.Enabled, id)
    return ok and enabled == true
end

function AAC.IsEnabled()
    return S.ready == true and AAC_ClassicSettings and AAC_ClassicSettings.enabled ~= false
        and AAC.FeatureEnabled("Hub")
end

function AAC.CanRequest()
    -- Optional coexistence: personal bulk-sale preview owns the same engine cache.
    if CoAAuctionMarket and type(CoAAuctionMarket.isHubHeld) == "function"
        and CoAAuctionMarket.isHubHeld() then return false end
    return AAC.IsEnabled() and AAC.SessionOpen == true
end

function AAC.CloseSession()
    if AAC.Exchange then AAC.Exchange.Close() end
    local wasOpen = AAC.SessionOpen
    AAC.SessionOpen = false
    if AAC.Market and AAC.Market.Reset then AAC.Market.Reset() end
    if AAC.Browse and AAC.Browse.Queue_Clear then AAC.Browse.Queue_Clear() end
    if wasOpen then AuctionClose() end
end

function S.NativeBusy()
    local b = AuctionHub and AuctionHub.Browse
    return b and (b.Loading == true or (type(b.Pending) == "table" and #b.Pending > 0))
end

function S.SetEnabled(enabled)
    S.restartForClassic = nil -- compatibility with the previous loaded beta
    if enabled and not AAC.IsEnabled() and S.NativeBusy() then
        S.pendingMode = true
        return false
    end
    if AAC.Market and AAC.Market.PrepareClose then AAC.Market.PrepareClose() end
    local pending = AAC.Market and (AAC.Market.Blocked or AAC.Market.TransactionPending)
    if pending and pending() then
        S.pendingMode = enabled == true
        S.restartNotified = nil
        return false
    end
    S.pendingMode = nil
    if AAC_AuctionFrame and AAC_AuctionFrame:IsVisible() then HideUIPanel(AAC_AuctionFrame) end
    AAC.CloseSession()
    if AuctionHubFrame and AuctionHubFrame:IsVisible() then HideUIPanel(AuctionHubFrame) end
    AAC_ClassicSettings = AAC_ClassicSettings or {}
    AAC_ClassicSettings.enabled = enabled == true
    say(enabled and "AAC_CLASSIC_NEXT" or "AAC_NATIVE_NEXT",
        enabled and "Classic interface selected. Reopen the auctioneer." or "Original interface selected. Reopen the auctioneer.")
    return true
end

-- Optional personal addon interoperability. Do not let a bulk preview claim
-- the same client cache; its unchanged workflow stays available in native mode.
function S.InstallCompatibility()
    S.compat = S.compat or {}
    for _, name in ipairs({"CoAAuctionPreview", "CoAAuctionPreviewBag90", "CoACardSalePreview",
        "CoAAHVorschau", "CoAKartenAHVorschau", "CoAAHPickerPreview", "CoAAuctionConfirm",
        "CoAAuctionConfirmSlot", "CoACardSaleConfirm", "CoAAHBestaetigen", "CoAAHPlatzBestaetigen",
        "CoAKartenAHBestaetigen"}) do
        local current = _G[name]
        if type(current) == "function" and current ~= S.compat[name] then
            local original = current
            local wrapper = function(...)
                if AAC.IsEnabled() then
                    say("AAC_NATIVE_FOR_BULK", "Use /aac native and reopen the auctioneer for Offers / Sales 1-90.")
                    return false
                end
                return original(...)
            end
            _G[name], S.compat[name] = wrapper, wrapper
        end
    end
    local current = CoAAuctionEvent
    if type(current) == "function" and current ~= S.compat.event then
        local original = current
        local wrapper = function(event, ...)
            if AAC.IsEnabled() and event ~= "LOADING_START" and event ~= "LOADING_END" then return end
            return original(event, ...)
        end
        CoAAuctionEvent, S.compat.event = wrapper, wrapper
    end
end

function S.InstallHooks()
    if S.hooked then return end
    if type(AuctionHubFrame_OnEvent) ~= "function" then return end
    local original = AuctionHubFrame_OnEvent
    AuctionHubFrame_OnEvent = function(frame, event, ...)
        -- Keep native initialization and out-of-window notifications intact.
        if AAC.IsEnabled() and event == "AUCTION_OPEN" then return end
        if event == "AUCTION_OPEN" then S.nativeVisited = true end
        return original(frame, event, ...)
    end
    S.hooked = true
    if type(ToggleGameMenu) == "function" then
        local toggle = ToggleGameMenu
        ToggleGameMenu = function(...)
            if AAC.SessionOpen and AAC_AuctionFrame:IsVisible() then
                if type(StaticPopup_EscapePressed) == "function" and StaticPopup_EscapePressed() then return end
                if type(CloseMenus) == "function" and CloseMenus() then return end
                HideUIPanel(AAC_AuctionFrame)
                return
            end
            return toggle(...)
        end
    end
end

function S.Init()
    if S.ready then S.InstallHooks(); S.InstallCompatibility(); return end
    AAC_ClassicSettings = AAC_ClassicSettings or {enabled=true}
    SaveVariablesPerCharacter("AAC_ClassicSettings")
    AAC.Main.InitSaveVariables()
    AAC.History.Init()
    AAC.Main.InitGUI(AAC_AuctionFrame)
    AAC_HookFunctions()
    S.ready = true
    S.InstallHooks()
    S.InstallCompatibility()
end

function S.Event(frame, event, ...)
    if event == "VARIABLES_LOADED" then
        local ok, err = pcall(S.Init)
        if not ok then
            S.ready = false
            say("AAC_INIT_FAILED", "Classic initialization failed; the original AH remains available.")
            DEFAULT_CHAT_FRAME:AddMessage(tostring(err))
        end
        return
    elseif event == "AUCTION_OPEN" then
        S.InstallCompatibility()
        if not AAC.IsEnabled() then return end
        AAC.SessionOpen = true
        AAC.SessionGeneration = (AAC.SessionGeneration or 0) + 1
        if AAC.Market and AAC.Market.Reset then AAC.Market.Reset() end
        if AAC.Browse and AAC.Browse.Queue_Clear then AAC.Browse.Queue_Clear() end
        ShowUIPanel(frame)
        if AAC_PrestigeFuncUpdate then AAC_PrestigeFuncUpdate() end
        return
    elseif event == "AUCTION_CLOSE" then
        -- Server already closed: hiding must not send another AuctionClose.
        AAC.SessionOpen = false
        if AAC.Market and AAC.Market.Reset then AAC.Market.Reset() end
        if frame:IsVisible() then HideUIPanel(frame) end
        return
    end
    if event == "AUCTION_HISTORY_SHOW" or event == "AUCTION_HISTORY_HIDE" then
        local handler = AAC.Events[event]
        if handler then handler(frame, ...) end
        return
    end
    if event == "CHAT_MSG_SYSTEM" and AAC.Market and AAC.Market.SystemMessage then
        AAC.Market.SystemMessage(select(1, ...) or arg1)
    elseif event == "WARNING_MESSAGE" and AAC.Market and AAC.Market.WarningMessage then
        AAC.Market.WarningMessage(select(1, ...) or arg1)
    end
    if not AAC.CanRequest() then return end
    local handler = AAC.Events[event]
    if handler then handler(frame, ...) end
end

function S.Tick(elapsed)
    S.elapsed = (S.elapsed or 0) + (tonumber(elapsed) or 0.05)
    if S.elapsed < 0.05 then return end
    S.elapsed = 0
    if AAC.Exchange then AAC.Exchange.Tick() end
    if AAC.CanRequest() and AAC.Market and AAC.Market.Tick then AAC.Market.Tick(elapsed) end
    if S.pendingMode ~= nil and AAC.Market and not AAC.Market.Blocked()
        and not (S.pendingMode and S.NativeBusy()) then
        S.SetEnabled(S.pendingMode)
    elseif S.pendingMode ~= nil and AAC.Market and AAC.Market.NeedsRestart
        and AAC.Market.NeedsRestart() and not S.restartNotified then
        S.restartNotified = true
        say("AAC_RESTART_REQUIRED", "An earlier reply is missing. If it does not arrive, restart the game client before switching interfaces.")
    end
end

function S.Command(_, message)
    local command = string.lower(tostring(message or "")):match("^%s*(.-)%s*$")
    if command == "native" or command == "off" then S.SetEnabled(false)
    elseif command == "classic" or command == "on" then S.SetEnabled(true)
    elseif AAC.CanRequest() then ShowUIPanel(AAC_AuctionFrame)
    else say("AAC_HELP", "/aac classic: classic AH; /aac native: original AH. Then reopen the auctioneer.") end
end
SLASH_AAC1 = "/aac"
SlashCmdList["AAC"] = S.Command
