# Arcadia Auction Classic — 0.2.4 beta

Maintained by Blackkid. Based on AdvancedAuctionHouse by Mavoc, TellTod, Noguai, Graves and Byte. GPLv3; see LICENSE.txt and NOTICE.md.

Project, source, releases and issue tracker: https://github.com/libsman/ArcadiaAuctionClassic

## Install
Extract this folder into Interface/AddOns and restart the game client after first installation. Open an auctioneer normally. No CoAManager or KittyCombo dependency.

- /aac classic selects Classic for the next auctioneer visit.
- /aac native selects the original interface for the next visit.

Switching normally needs no restart; unfinished requests are allowed to complete first. New XML requires the client UI to load again. Permanently missing server replies can require a restart.

## Exchange
Overview offers Auctions / Exchange offers. Search has Money / Exchange offers. My offers has Auctions / Exchange, with New offer for gold or diamonds.

Quick exchange displays actual net receipts after fees and the cost. Click the buy button to review and confirm. Other amount opens free entry. New offers accept amount, total price and gold per diamond with automatic recalculation and dot thousands grouping. New-offer totals are before execution fees; see the notice in the form.

All monetary actions require confirmation. Server quotes, features, quantities and fees remain authoritative. This is a community beta, not an official CoA release. See the project README for supported features and testing limits.
