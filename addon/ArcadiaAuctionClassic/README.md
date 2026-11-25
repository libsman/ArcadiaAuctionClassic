# Arcadia Auction Classic — 1.0.0

Maintained by Blackkid. Based on AdvancedAuctionHouse by Mavoc, TellTod, Noguai, Graves and Byte. GPLv3; see LICENSE.txt and NOTICE.md.

Project, source, releases and issue tracker: https://github.com/libsman/ArcadiaAuctionClassic

## Install
Extract this folder into Interface/AddOns and restart the game client after first installation. Open an auctioneer normally.

- /aac classic selects Classic for the next auctioneer visit.
- /aac native selects the original interface for the next visit.

Switching normally needs no restart; unfinished requests are allowed to complete first. New XML requires the client UI to load again. Permanently missing server replies can require a restart.

## Exchange
Search has Money / Exchange (new). In My offers, check Exchange (new) beside Money Transaction to offer gold or diamonds.

Quick exchange displays actual net receipts after fees and the cost. Click the buy button to review and confirm. Other amount opens free entry. New offers accept amount, total price and gold per diamond with automatic recalculation and dot thousands grouping. New-offer totals are before execution fees; see the notice in the form.

All monetary actions require confirmation. Server quotes, features, quantities and fees remain authoritative. This is a community beta, not an official CoA release. See the project README for supported features and testing limits.

## Buying and selling
Search → Buy orders shows existing requests in a Classic list. Filter by buyers for your bag or your own orders. Select a row to see proceeds and sell, or choose Create buy order and drag an item into the form. All trades require confirmation.

My offers has direct Check prices, List again and Buy orders buttons. The normal auction form and list remain available via Back or the bottom tabs. Price comparison skips equipment and stat-bearing mana stones. Repeat listing prepares an available bag stack in the normal selling form; check and confirm there. Promotion is selected separately.

## My purchases
Bids and all buy-order actions are together under My purchases. Choose Buy orders to view your requests, find buyers or create a new request. The create form includes item-name search (at least three characters), item icons and tooltips, and your existing orders below. Back returns to the order list.
