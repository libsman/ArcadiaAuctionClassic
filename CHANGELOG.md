# Changelog

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
