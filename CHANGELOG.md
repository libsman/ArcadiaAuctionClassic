# Changelog

## 1.2.0 - 2026-11-26

- Manage the guild treasury directly from **My offers > Guild treasury**.
- View the balance, recent income, weekly payout limits and reset time.
- Search and select guild members, then choose an amount per member or split a total evenly.
- Review recipients and amounts before confirming a payout. Guild permissions, membership requirements and payout limits are respected.
- Browse the treasury income and payout history.
- Includes translations for all eleven supported client languages.


## 1.1.2 - 2026-11-26

- Recover stalled auction searches and buy-order searches with one automatic retry instead of leaving the search blocked.
- Request sale history for the selected item, including its equipment attributes. Fall back to general item history if the selected item has changed.
- Confirm listings from the updated own-offers list, including items whose link metadata changes on the server.
- Keep exchange results visible after refreshing offers, and show remaining listed amounts and mail refunds.
- Money transactions still require confirmation and are never retried automatically.
- Validation: 185 automated tests (Lua 5.1 regressions and release tooling).

## 1.1.1 - 2026-11-26

- Fix sale history getting permanently stuck after a missing server reply. Requests time out after five seconds and foreground requests retry once.
- Validate history item links before displaying or using prices; late replies for another item do not consume the current request.
- Replace the history restart warning with a simple retry message.
- Add the native Sell for guild option in My offers, respecting guild permissions and eligible currency. The confirmation shows proceeds going to the guild treasury.
- Validation: 171 Lua 5.1 tests pass. No new in-client verification for this release.

## 1.1.0 - 2026-11-26

- Select several own auctions and preview extension, promotion or cancellation with a combined cost. Requests advance only after an observed matching result; unexpected changes stop the batch.
- Existing offers show their actual saved sale commission and net proceeds. Cancellation warns when relisting would use a higher commission.
- Updated linked-account fee explanation and linked-seller tooltip. Listing estimates still use the regular fee because the buyer is not yet known.
- Ambiguous identical cancellations are excluded from batches; individual cancellation remains available. No automatic batch on all auctions when no boxes are checked.


## 1.0.0 � First stable release

- Fix Money transaction switching itself off as soon as the currency selector appears.
- Use native localized Gold/Diamond names in currency-sale confirmation dialogs.
- Retain Classic search, tooltip filters, unit prices, buy orders, gross/net prices and currency exchange from the beta series.
- Validation: 152 Lua 5.1 tests; in-client currency selection, both price directions, gold-sale confirmation (cancelled), search, exchange navigation and own offers after reopening. No transaction submitted during this check.
- Known client behavior: own auctions may initially appear empty after a UI reload; close and reopen the auction house.

## 0.3.11-beta — Reliable equipment purchases

- Fix purchased equipment remaining in search results and blocking the next purchase when the game regenerates technical item-link metadata in its success reply.
- Keep auction, price, currency, equipment attributes and stack-size checks; purchases are never retried automatically.
- Verified two consecutive equipment purchases in the game client: both rows disappeared after confirmation. All 150 automated tests pass.

## 0.3.10-beta — Restore selling price history

- Fix the disabled Price history button in My offers.
- Read the actual staged item for history requests and automatic pricing, including upgraded items.
- Verified the history window with real sales in the game client; all 149 automated tests pass.

## 0.3.9-beta — Use the expanded window

- Buy-order forms and lists now grow with Expand view instead of keeping a fixed number of rows.
- Item-search results, price checks and recent listings also use the extra height.
- Move paging and action buttons down with the list; hide paging when all entries fit.
- Keep the visible list position when collapsing or expanding and clamp pages to valid bounds.

## 0.3.8-beta — Clearer Classic forms

- Compact My offers into native item, price and duration columns. Gross/net totals and unit prices remain editable; automatic pricing and promotion move into collapsible extra options.
- Align buy-order price fields with the selling form and keep existing orders underneath.
- Shorten settings, history and help labels in all eleven supported languages. Show clear empty/loading states and hide unnecessary exchange pagination.
- Fix purchases being rejected solely because the client regenerated an item link. Auction identity, quantity, currency and confirmed price are still checked.
- Checked the forms, navigation and sale confirmation in the German game client without submitting a sale. All 149 automated tests pass.
- Known issue under investigation: the game can return an empty own-auction list until the auction house is reopened. This release does not claim to fix that intermittent loading issue.

## 0.3.7-beta — Gross and net auction prices

- Add editable gross and net totals and unit prices to My offers, using the game's auction commission API and integer fee rounding.
- Keep listing and promotion fees separate from sale proceeds and retain confirmation before posting.
- Arrange the four prices together in the Classic selling form, reusing translated labels in all eleven languages.
- Preserve fractional unit prices when changing a stack total.
- Verified net entry, item-stack prices and the confirmation preview in the German client without submitting a sale. All 149 automated tests pass.

## 0.3.6-beta — Gross and net buy-order prices

- Show editable gross and net unit prices and totals together in the Classic order form.
- Convert using server-listed commission rates and native rounding, including the diamond minimum fee. Keep placement fees separate.
- Net is an estimate for one complete fill; partial fills can differ. Net inputs stay unavailable when no consistent current server rate is known.
- Translate labels and explanations in all eleven supported client languages.
- Verified both conversion directions, currency changes and the confirmation preview in the German client; no order was submitted. 147 automated tests pass.

## 0.3.5-beta — Clearer buy-order form and total price

- Highlight item search and show a clear drag-here hint in the item slot.
- Add a total-price field linked to quantity and unit price. Integer unit prices round down, never above the entered item budget; fees remain separate.
- Translate the new labels in all eleven supported client languages.

## 0.3.4-beta — Clearer selection and native currency icons

- Refresh the current buy-order list after a confirmed cancellation; keep the result and refund notice after loading.
- Move item search to the upper left above the order form, keeping existing orders underneath.
- Use native gold/diamond textures in item unit-price columns and buy-order / price-check lists.
- Keep the Gold/Diamond rate explicit for currency lots in mixed results.
- Remove a duplicated settings tooltip line.
- Tested the German client layouts directly; cancellation regression covered with Lua5.1 simulation, no user order cancelled for this review.

## 0.3.3-beta — My purchases and clearer Classic views

- Grouped auction bids and all buy-order tools under My purchases, with familiar Classic navigation.
- Added partial-name item selection with icons and tooltips, including Arcadia items beyond the original catalogue range. Items need not be owned.
- Compact buy-order form with existing orders below; Back returns to the order list.
- Prevented item-link and bag shortcuts from opening buy orders inside selling tools.
- Shortened and translated the filter guide, settings, overview and selling labels in eleven languages.
- Checked the German client directly: search results, sorting, buy-order selection, navigation, exchange views, settings and help. Other client languages and every live server transaction are not claimed as verified.

## 0.3.2-beta — Client-verified trading views

- Fixed item-link reading in price checks and buy-order selection using the actual client API.
- Reused the existing coloured unit-price display; removed unsupported inline image markup.
- Verified Classic navigation, own listings, price-check pagination, item selection, input focus, fees and confirmation cancellation in the running client. No trade was submitted.

## 0.3.1-beta — Classic layout

- Removed the separate selling-tools dashboard; actions are directly accessible in My offers and Search.
- Reused Classic list rows, currency controls and horizontal selling-form layout.
- Proceeds and row actions appear after selection. Native contents are restored on Back.
- Trading confirmations, fees and request safety remain unchanged.

## 0.3.0-beta — Buy orders and selling tools

- Find existing buyers for items in your bag, with fee and net proceeds before confirmation.
- Create and cancel buy orders from Search / My Offers using the current server APIs and fees.
- Check competing unit prices for comparable stackable items; rolled equipment and stat-bearing mana stones remain manual comparisons.
- Prepare a recent confirmed listing again, retaining currency, price and duration. No automatic posting; promotion is reset for explicit selection.
- Native Classic child panel, no additional main tab, and complete text coverage in eleven client languages.
- Guard delayed replies, changed orders/inventory, fractional prices and automatic price-history overwrites.

## 0.2.9-beta — Upgraded item search

- Shift-click search removes a trailing upgrade suffix such as +20, using the base item name indexed by the auction house.
- Chat links outside the visible search view and other parts of item names are unchanged.

## 0.2.8-beta — Currency selection layout fix

- Native 16px currency radio buttons and icons with clear caption spacing.
- Currency controls are children of the active offer form, so focusing a field cannot raise a separate form backdrop over them.
- No trading, pricing or confirmation changes.

## 0.2.7-beta — Exchange in the classic selling page

- Exchange (new) is a checkbox beside Money Transaction in My Offers; redundant subtabs removed.
- Amount, total and unit price in a compact native-style form; exchange orders and a separate count below. Gold/diamond icons identify the offered currency.
- Custom quick-exchange amounts use aligned receipt/cost columns and Back/Review buttons along the bottom.
- Regular auctions, their search field and inventory-click behavior restore correctly when leaving exchange mode. Native confirmations and refreshed price checks remain in place.

## 0.2.6-beta — Stable numeric entry

- Numeric fields keep the native cursor undisturbed while typing; grouping happens on focus loss or Enter. Related totals still update immediately.
- Removed the exchange subtab from Overview; find Exchange (new) under Money in Search. Own-offer management remains available.
- Client-byte Lua compilation is now part of package validation, detecting unsupported file prefixes.

## 0.2.5-beta — Native quick-exchange layout

- Approved native layout with small gold-stack/diamond icons and net amount, cost and buy button on one line.
- Flat rows with consistent spacing, descending presets and a separate custom-amount view.
- Compact browsing layout and translated short buy labels in all eleven languages.
- Native quotes, fees and explicit confirmation remain unchanged.

## 0.2.4-beta — Initial GitHub beta

- Classic auction search, tooltip filters, unit-price sorting, selling and own auctions adapted to the current API.
- Gold/diamond exchange integrated into Classic navigation.
- New-offer amount, total price and unit price update one another, with grouped numeric input.
- Compact quick-exchange rows show net receipts, costs and native currency icons.
- Fixed the native texture path used for the colored exchange-card headers.
- Scoped Shift-click item-link search.
- Confirmed actions, refreshed quotes, fee checks and request/session ownership.
- Standalone Lua 5.1 tests and a reproducible installable ZIP builder.

This is the first public GitHub release, based on the existing 0.2.3 beta with the exchange texture-path correction. Earlier development changes and original author credits remain documented in the bundled NOTICE.md. Publishing the source does not imply official integration or validation of every client/server interaction.
