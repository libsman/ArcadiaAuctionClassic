-- Coordinates shared client browse data and owns AAC transaction confirmations.
local Market = { Epoch = 0 }
local function buyOrdersBusy()
    return AAC.BuyOrders and (AAC.BuyOrders.Busy() or AAC.BuyOrders.HasConfirmation())
end
AAC.Market = Market

local Pay = { AuctionType = { Browse = 0, Bid = 1 } }
AAC.Pay = Pay

local SEARCH_INTERVAL = 3.2
local RESPONSE_TIMEOUT = 15
local PAGE_ATTEMPTS = 3
local PAGE_SIZE = 250
local search, queued, waiting, readyAt = nil, nil, nil, 0
local current, pending, confirmation, continuation
local closing = false
local retiredBuys, spent = {}, {}

local function bareLink(link)
    return link and link:match("(|H.-|h.-|h)")
end

local function purchaseKey(link, count)
    local canonical = bareLink(link) or link
    -- The client regenerates two fields between a gear listing and its success
    -- receipt (verified with a live buy): field 3's high byte and field 12.
    -- Keep the remaining payload, including stats, upgrades and corruption;
    -- neither the displayed name nor a complete raw link identifies a receipt.
    local payload = canonical and canonical:match("^|Hitem:([^|]+)|h")
    if payload then
        local fields = {}
        for value in payload:gmatch("%S+") do fields[#fields + 1] = value end
        local packed = tonumber(fields[3] or "", 16)
        if #fields >= 13 and packed then
            fields[3] = string.format("%x", packed % 16777216)
            fields[12] = "0"
            canonical = "item:" .. table.concat(fields, " ")
        end
    end
    if canonical then return canonical .. "|" .. tostring(count) end
end

local function retirePurchases()
    for _, item in ipairs(pending and pending.purchases or {}) do
        local key = purchaseKey(item.link, item.cacheCount)
        if key then retiredBuys[key] = true end
    end
end
local dialogs = { "AAC_MARKET_BUY", "AAC_MARKET_BID", "AAC_MARKET_MULTI", "AAC_MARKET_SELL", "AAC_MARKET_CANCEL" }

function Market.Notice(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("AAC: " .. message) end
end

function Market.Feature(name)
    return AAC.FeatureEnabled == nil or AAC.FeatureEnabled(name)
end

local function complete(wait)
    return wait.result and (wait.page > 1 or wait.update or wait.empty)
end

local function drainRetiredSearch()
    if waiting and not waiting.job and complete(waiting) then waiting = nil end
end

local function finishSearch(message)
    local finished = search
    search = nil
    if finished then
        if waiting and waiting.job == finished then
            waiting.job = nil
            drainRetiredSearch()
        end
        if message then current = nil end
        finished.finish(message)
    end
end

local function finishQueued(message)
    local finished = queued
    queued = nil
    if finished then finished.finish(message) end
end

function Market.StopSearch(owner)
    if queued and queued.owner == owner then finishQueued() end
    if search and search.owner == owner then finishSearch() end
end

function Market.StartSearch(owner, send, finish, publish)
    if buyOrdersBusy() or (AAC.Exchange and AAC.Exchange.Blocked()) then return false end
    if closing or not AAC.CanRequest() or pending or confirmation or continuation then return false end
    finishSearch()
    finishQueued()
    queued = {
        owner = owner, send = send, finish = finish, publish = publish,
        page = 1, refusals = 0, seen = {}, deadline = GetTime() + RESPONSE_TIMEOUT,
    }
    Market.Epoch = Market.Epoch + 1
    current = nil
    spent = {}
    return true
end

function Market.SearchEvent(owner, event)
    if not waiting or owner ~= waiting.owner then return end
    if event == "AUCTION_BROWSE_UPDATE" and waiting.page == 1 then
        waiting.update = true
    elseif event == "AUCTION_SEARCH_RESULT" then
        waiting.result = true
    elseif event == "AUCTION_BROWSE_PAGE_REFUSED" and waiting.page > 1 then
        waiting.refused = true
        waiting.result = true
    end
    drainRetiredSearch()
end

local function pageReady(job)
    local total, pages = GetAuctionBrowseMaxItems(), GetAuctionBrowseMaxPages()
    if type(total) ~= "number" or type(pages) ~= "number" or total < 0 or total > 5000 then return end
    if total == 0 then
        if job.page == 1 and pages <= 1 then return 0, 0 end
        return
    end
    if pages ~= math.ceil(total / PAGE_SIZE) or (job.total and job.total ~= total) then return end
    local last = math.min(PAGE_SIZE, total - (job.page - 1) * PAGE_SIZE)
    local found = {}
    for i = 1, last do
        local index, _, count, _, _, _, _, _, _, mode, _, _, _, dbid = GetAuctionBrowseItemInfo(job.page, i)
        if not index or not dbid or not count or not mode or job.seen[dbid] or found[dbid]
            or not GetAuctionBrowseItemLink(index) then return end
        found[dbid] = true
    end
    for dbid in pairs(found) do job.seen[dbid] = true end
    return total, pages
end

local function tickSearch(now)
    if waiting then
        local active = search and waiting.job == search
        if complete(waiting) then
            if not active then
                waiting = nil
            elseif waiting.refused then
                waiting = nil
                search.refusals = search.refusals + 1
                readyAt = now + SEARCH_INTERVAL
                if search.refusals >= PAGE_ATTEMPTS then
                    finishSearch(AAC_MARKET_FAILED or "Search request failed.")
                end
            else
                local total, pages
                if waiting.empty and not waiting.update then
                    total, pages = 0, 0
                else
                    total, pages = pageReady(search)
                end
                if total ~= nil then
                    local job = search
                    waiting = nil
                    job.total, job.pages = total, pages
                    current = job.owner
                    job.publish(job.page, total, pages)
                    job.page = job.page + 1
                    job.refusals = 0
                    if job.page > pages then finishSearch() end
                    return
                elseif now >= waiting.deadline then
                    local job = search
                    waiting = nil
                    if job.page == 1 and not job.retried then
                        job.retried = true
                    else
                        finishSearch(AAC_MARKET_TIMEOUT or "Search timed out.")
                    end
                end
            end
        elseif active and now >= waiting.deadline then
            finishSearch(AAC_MARKET_SEARCH_STALLED or "A search reply is missing. Restart the client if it does not arrive.")
        end
        if waiting then
            if queued and now >= queued.deadline then
                finishQueued(AAC_MARKET_SEARCH_STALLED or "A search reply is missing. Restart the client if it does not arrive.")
            end
            return
        end
    end
    if closing then return end
    if not search and queued then search, queued = queued, nil end
    if not search or now < readyAt or pending or confirmation then return end

    local job = search
    readyAt = now + SEARCH_INTERVAL
    waiting = { job = job, owner = job.owner, page = job.page, deadline = now + RESPONSE_TIMEOUT }
    if job.page == 1 then
        job.send()
    elseif not AuctionBrowseNextPage(job.page) then
        waiting = nil
        job.refusals = job.refusals + 1
        if job.refusals >= PAGE_ATTEMPTS then
            finishSearch(AAC_MARKET_FAILED or "Search request failed.")
        end
    end
end

function Market.Active() return search ~= nil or queued ~= nil or waiting ~= nil end

function Market.TransactionPending() return buyOrdersBusy() or pending ~= nil or continuation ~= nil or (AAC.Exchange and AAC.Exchange.pending ~= nil) end
function Market.HasConfirmation() return confirmation ~= nil end

function Market.Blocked()
    return Market.Active() or Market.TransactionPending() or next(retiredBuys) ~= nil
        or (AAC.Exchange and AAC.Exchange.Blocked())
        or (AAC.History and AAC.History.RequestPending ~= nil)
end

function Market.NeedsRestart()
    local history = AAC.History and AAC.History.RequestPending
    local now = GetTime()
    return (waiting and now >= waiting.deadline) or (history and now >= history.deadline)
        or next(retiredBuys) ~= nil
end

function Market.IsClosing() return closing end

function Market.PrepareClose()
    if AAC.TradingUI then AAC.TradingUI.Close() end
    if AAC.Exchange then AAC.Exchange.Close() end
    closing = true
    finishSearch()
    finishQueued()
    if confirmation then
        local key = confirmation.key
        confirmation = nil
        StaticPopup_Hide(key)
    end
    if AAC.History then AAC.History.PrepareClose() end
end

local function accept(key)
    local request = confirmation
    if not request or request.key ~= key then return end
    confirmation = nil
    if AAC.CanRequest() and not pending and GetTime() < request.deadline then request.run() end
end

local function dismiss(key)
    if confirmation and confirmation.key == key then confirmation = nil end
end

function Market.Confirm(key, text, callback)
    if buyOrdersBusy() or (AAC.Exchange and AAC.Exchange.Blocked()) then return false end
    if closing or not AAC.CanRequest() or pending or confirmation or continuation then return false end
    confirmation = { key = key, run = callback, deadline = GetTime() + 30 }
    StaticPopup_Show(key, text)
    return true
end

function Market.Submit(kind, observe, send, purchases, onBought)
    if buyOrdersBusy() or (AAC.Exchange and AAC.Exchange.Blocked()) then return false end
    if closing or not AAC.CanRequest() or pending then return false end
    pending = { kind = kind, observe = observe, purchases = purchases, onBought = onBought, deadline = GetTime() + RESPONSE_TIMEOUT }
    send()
    return true
end

function Market.Confirmed()
    pending = nil
end

function Market.Changed()
    Market.Notice(AAC_MARKET_CHANGED or "The selection changed. Review it and confirm again.")
end

function Market.Tick()
    if not AAC.CanRequest() then return end
    local now = GetTime()
    if confirmation and now >= confirmation.deadline then
        local key = confirmation.key
        confirmation = nil
        StaticPopup_Hide(key)
    end
    if pending then
        if pending.observe and pending.observe() then
            Market.Confirmed()
        elseif now >= pending.deadline then
            retirePurchases()
            pending = nil
            Market.Notice(AAC_MARKET_TIMEOUT or "The server did not confirm the request.")
        end
    end
    if continuation then
        local nextPurchase = continuation
        continuation = nil
        if not closing then nextPurchase() end
    end
    if AAC.History and AAC.History.Tick then AAC.History.Tick(now) end
    tickSearch(now)
end

function Market.Reset()
    closing = false
    finishSearch()
    finishQueued()
    -- Browse and buyout results do not identify the originating session.
    -- Keep only their response fences across a window close.
    retirePurchases()
    drainRetiredSearch()
    confirmation, pending, current, continuation = nil, nil, nil, nil
    Market.Epoch = Market.Epoch + 1
    spent = {}
    for _, key in ipairs(dialogs) do
        if StaticPopup_Hide then StaticPopup_Hide(key) end
    end
    if AAC.History and AAC.History.ResetRequests then AAC.History.ResetRequests() end
end

local function snapshot(item)
    local copy = {}
    for key, value in pairs(item) do copy[key] = value end
    return copy
end

local function stillListed(item, kind)
    if kind == Pay.AuctionType.Browse then
        if current ~= item.owner or item.epoch ~= Market.Epoch or not item.dbid or spent[item.dbid] then return false end
        local index, _, count, _, _, _, _, seller, _, mode, bid, buyout, _, dbid =
            GetAuctionBrowseItemInfo(item.page, item.slot)
        return index == item.auctionid and dbid == item.dbid and count == item.cacheCount
            and seller == item.seller and mode == item.moneyMode and (bid or 0) == item.bidPrice
            and (buyout or 0) == item.buyoutPrice
    end
    if AAC.Bid.Revision ~= item.revision then return false end
    local name, count, _, _, _, _, seller, status, mode, bid, buyout = GetAuctionBidItemInfo(item.auctionid)
    return name == item.name and count == item.cacheCount and seller == item.seller and status == item.status
        and mode == item.moneyMode and (bid or 0) == item.bidPrice and (buyout or 0) == item.buyoutPrice
end

local function matchesBought(message)
    local pattern = TEXT("SYS_AC_BUYOUT_SUCCESS")
    if type(pattern) ~= "string" then return end
    local first, last = pattern:find("%s", 1, true)
    if not first then return end
    local prefix, suffix = pattern:sub(1, first - 1), pattern:sub(last + 1)
    if message:sub(1, #prefix) ~= prefix or (#suffix > 0 and message:sub(-#suffix) ~= suffix) then return end
    local payload = message:sub(#prefix + 1, #message - #suffix)
    local link = bareLink(payload)
    local digits = payload:match("^([%d,%.]+)x ")
    local count = digits and tonumber((digits:gsub("[,%.]", ""))) or 1
    return link, count
end

local saleRefusals = {
    "SYS_AC_CREATE_ITEM_MAXCOUNT", "SYS_AC_NOT_ENOUGH_MONEY", "SYS_AC_NOT_ENOUGH_MONEY_PROMOTE",
    "SYS_AUCTION_CREATE_MONEY_DISABLE", "SYS_AUCTION_CREATE_MONEY_ERROR", "SYS_AUCTION_SELL_MONEY_ERROR",
    "SYS_AC_CREATE_MONEY_ERR", "SYS_AUCTION_MONEY_TYPE_ERR", "SYS_GAMEMSGEVENT_014",
}

function Market.WarningMessage(message)
    if type(message) ~= "string" then return end
    if waiting and waiting.page == 1 and message == TEXT("SYS_AC_SEARCH_EMPTY") then
        waiting.empty = true
        drainRetiredSearch()
    end
    if not pending or pending.kind ~= "sell" then return end
    local template = TEXT("SYS_AC_CREATE_ITEM_FAILED")
    local first, last
    if type(template) == "string" then first, last = template:find("%s", 1, true) end
    if first then
        local prefix, suffix = template:sub(1, first - 1), template:sub(last + 1)
        if #prefix + #suffix > 0 and #message > #prefix + #suffix and message:sub(1, #prefix) == prefix
            and (#suffix == 0 or message:sub(-#suffix) == suffix) then
            pending = nil
            return
        end
    end
    for _, key in ipairs(saleRefusals) do
        if message == TEXT(key) then pending = nil; return end
    end
end

function Market.SystemMessage(message)
    Market.WarningMessage(message)
    if type(message) ~= "string" then return end
    local link, count = matchesBought(message)
    if not link then return end
    local key = purchaseKey(link, count)
    if retiredBuys[key] then
        retiredBuys[key] = nil
        return
    end
    if not AAC.CanRequest() or not pending or not pending.purchases then return end
    for i, item in ipairs(pending.purchases) do
        if key == purchaseKey(item.link, item.cacheCount) then
            if item.dbid then spent[item.dbid] = true end
            table.remove(pending.purchases, i)
            if #pending.purchases == 0 then
                continuation = pending.onBought
                Market.Confirmed()
            end
            if item.owner and item.owner.RemovePurchased and item.epoch == Market.Epoch then
                item.owner.RemovePurchased(item.auctionid)
            end
            return
        end
    end
end

local function pay(items, kind, amount, buyout)
    local immutable = {}
    local totals = {}
    local lines = {}
    local seen = {}
    if closing or not AAC.CanRequest() or Market.Active() then return end
    if not buyout and not Market.Feature("ItemBids") then return end
    for _, item in ipairs(items) do
        local price = buyout and item.buyoutPrice or amount
        local mode = item.moneyMode
        local key = item.dbid or item.auctionid
        if not key or seen[key] or not item.link or (mode ~= "copper" and mode ~= "account") or type(price) ~= "number"
            or price <= 0 or price ~= math.floor(price) then return end
        local currentBid = item.bidPrice or 0
        local minimumBid = math.max(currentBid + 1, math.floor(currentBid * 1.05))
        if not buyout and (price < minimumBid or (item.buyoutPrice or 0) > 0 and price >= item.buyoutPrice) then return end
        if buyout and retiredBuys[purchaseKey(item.link, item.cacheCount)] then
            Market.Notice(AAC_MARKET_BUY_STALLED or "An earlier purchase reply is missing for this stack. Restart the client if it does not arrive.")
            return
        end
        seen[key] = true
        immutable[#immutable + 1] = snapshot(item)
        totals[mode] = (totals[mode] or 0) + price
        lines[#lines + 1] = AAC.UX and string.format(AAC.UX.text.buy, item.count, item.name or item.link,
            AAC.UX.Number(price,false), TEXT(mode == "account" and "SYS_MONEY_TYPE_1" or "SYS_MONEY_TYPE_0"))
            or (tostring(item.count).."x "..(item.name or item.link).." — "..tostring(price).." "..TEXT(mode == "account" and "SYS_MONEY_TYPE_1" or "SYS_MONEY_TYPE_0"))
    end
    for mode, total in pairs(totals) do
        if total > GetPlayerMoney(mode) then StaticPopup_Show("BUYOUT_ALERT"); return end
    end
    local key = buyout and (#items == 1 and "AAC_MARKET_BUY" or "AAC_MARKET_MULTI") or "AAC_MARKET_BID"
    if #immutable > 6 then
        lines = { tostring(#immutable) .. " " .. (AAC_MARKET_AUCTIONS or "auctions") }
        for mode, total in pairs(totals) do
            lines[#lines + 1] = tostring(total) .. " " .. TEXT(mode == "account" and "SYS_MONEY_TYPE_1" or "SYS_MONEY_TYPE_0")
        end
    end
    Market.Confirm(key, table.concat(lines, "\n"), function()
        if Market.Active() or (not buyout and not Market.Feature("ItemBids")) then return end
        for _, item in ipairs(immutable) do
            if not stillListed(item, kind) then Market.Changed(); return end
        end
        for mode, total in pairs(totals) do
            if total > GetPlayerMoney(mode) then StaticPopup_Show("BUYOUT_ALERT"); return end
        end
        local function send(item, price)
            if kind == Pay.AuctionType.Browse then
                AuctionBrowseBuyItemByID(item.dbid, price)
            else
                AuctionBidBuyItem(item.auctionid, price)
            end
        end
        if buyout then
            local function submitNext(i)
                local item = immutable[i]
                if not stillListed(item, kind) or retiredBuys[purchaseKey(item.link, item.cacheCount)] then
                    Market.Changed()
                    return
                end
                if item.buyoutPrice > GetPlayerMoney(item.moneyMode) then
                    StaticPopup_Show("BUYOUT_ALERT")
                    return
                end
                local nextPurchase = immutable[i + 1] and function() submitNext(i + 1) end or nil
                Market.Submit("buyout", nil, function() send(item, item.buyoutPrice) end, { item }, nextPurchase)
            end
            submitNext(1)
            return
        end
        local bidRevision = AAC.Bid and AAC.Bid.Revision
        local expected = immutable[1]
        local function matchingOwnedBid()
            local match
            local count = 0
            for _, item in ipairs(AAC.Bid and AAC.Bid.List.Items or {}) do
                if item.link == expected.link and item.seller == expected.seller and item.cacheCount == expected.cacheCount
                    and item.moneyMode == expected.moneyMode and item.buyoutPrice == expected.buyoutPrice then
                    count = count + 1
                    match = item
                end
            end
            return match, count
        end
        local original, originalCount = matchingOwnedBid()
        local function bidConfirmed()
            if not AAC.Bid or bidRevision == AAC.Bid.Revision then return false end
            local latest, latestCount = matchingOwnedBid()
            if latestCount ~= 1 or latest.bidPrice ~= amount or latest.status ~= true then return false end
            if kind == Pay.AuctionType.Browse then
                return originalCount == 0
            end
            return originalCount == 1 and original.auctionid == expected.auctionid
                and latest.auctionid == expected.auctionid
                and (expected.bidPrice ~= amount or expected.status ~= true)
        end
        Market.Submit("bid", bidConfirmed, function() send(expected, amount) end)
    end)
end

function Pay.PayAuction(item, moneyBid, moneyIsBuyout, typeAuction)
    if item and moneyBid and moneyIsBuyout ~= nil and typeAuction ~= nil then
        pay({item}, typeAuction, moneyBid, moneyIsBuyout)
    end
end

function Pay.PayMultiAuction(items, typeAuction)
    if items and #items > 0 and Market.Feature("BuyQueue") then pay(items, typeAuction, 0, true) end
end

function Pay.InitPopups()
    for _, key in ipairs(dialogs) do
        local popupKey = key
        local headings = {
            AAC_MARKET_BUY = TEXT("AUCTION_BUYOUT"),
            AAC_MARKET_MULTI = TEXT("AUCTION_BUYOUT"),
            AAC_MARKET_BID = TEXT("AUCTION_BID"),
            AAC_MARKET_SELL = AAC_MARKET_SELL_CONFIRM or "List this auction?",
            AAC_MARKET_CANCEL = AAC_MARKET_CANCEL_CONFIRM or "Cancel this auction?",
        }
        StaticPopupDialogs[key] = {
            text = headings[key] .. "\n%s",
            button1 = TEXT("ACCEPT"),
            button2 = TEXT("CANCEL"),
            OnAccept = function() accept(popupKey) end,
            OnCancel = function() dismiss(popupKey) end,
            OnHide = function() dismiss(popupKey) end,
            hideOnEscape = 1,
        }
    end
end

Pay.InitPopups()
