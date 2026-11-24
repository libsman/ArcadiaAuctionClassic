# Arcadia Auction Classic

**The familiar auction-house interface, adapted for today's Chronicles of Arcadia.**

[![Checks](https://github.com/libsman/ArcadiaAuctionClassic/actions/workflows/checks.yml/badge.svg)](https://github.com/libsman/ArcadiaAuctionClassic/actions/workflows/checks.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

[Download the beta](https://github.com/libsman/ArcadiaAuctionClassic/releases) · [Report a bug](https://github.com/libsman/ArcadiaAuctionClassic/issues) · [Changelog](CHANGELOG.md)

Maintained by **Blackkid**. Based on **AdvancedAuctionHouse** by Mavoc, TellTod, Noguai, Graves and Byte.

## What it does

- Familiar Classic search, categories, tooltips, filters and saved searches.
- Sortable **price per item** for gold and diamond auctions. Gold lots show **Gold/Diamond**.
- **Shift-click an item link** while the search view is open to fill its name into the keyword field.
- Own auctions, selling and sale-history views, with sale commission and expected proceeds.
- Gold/diamond exchange under **Search → Money → Exchange (new)** and the **Exchange (new)** checkbox in **My offers**.
- Quick-exchange rows show **what you receive after fees**, the cost and a button to review the exchange.
- New exchange offers accept an **amount, total price or price per diamond**. The fields update each other and group thousands with dots.
- Purchases, bids, listings, exchanges and cancellations require confirmation.
- Eleven client languages, with English fallback where needed.

The addon uses the game's auction APIs and native UI resources.

## Install

1. Download the named **`ArcadiaAuctionClassic-<version>.zip`** from [Releases](https://github.com/libsman/ArcadiaAuctionClassic/releases). Use the named addon ZIP, not GitHub's automatically generated source archive.
2. Extract the `ArcadiaAuctionClassic` folder into your game's `Interface/AddOns` directory.
3. Restart the client after first installation so the new XML frames load.
4. Open an auctioneer as usual.

```text
Interface/
  AddOns/
    ArcadiaAuctionClassic/
      ArcadiaAuctionClassic.toc
      Lua/
      Xml/
```

## Choose your interface

| Command | Result |
| --- | --- |
| `/aac classic` | Select Classic, then reopen the auctioneer. |
| `/aac native` | Select the game's original AuctionHub, then reopen the auctioneer. |

Switching interfaces does not normally require a restart. Outstanding requests finish first. A permanently missing reply may require a restart to recover safely. The original interface remains available through `/aac native`.

## Buying and selling

- **My purchases → Buy orders:** the familiar Classic list, with filters for all requests, buyers for your bag and your own orders. Selecting a row shows the relevant action and net proceeds.
- **Create buy order:** search for an item by part of its name (at least three characters), or drag / Shift-click an item into the compact form. The item does not have to be in your bag. Icons and tooltips help identify it, and your existing orders appear below. Enter quantity and either maximum unit price or total item price. Whole unit prices round down if the total cannot be divided evenly; fees are separate. Gross and net unit prices and totals are visible together and can be edited in either direction. Net uses a consistent commission rate from the current server order list and estimates one complete fill; partial fills can differ. Without a known rate, net inputs are unavailable. Review the reserved balance and fee before confirming.
- **My offers:** enter either gross or net totals and unit prices; the other fields update using the game's commission rates. Listing and promotion fees remain separate.
- **My offers → Check prices:** compares stackable items per currency. Equipment and stat-bearing mana stones are not compared by base item ID.
- **My offers → List again:** prepares a recent confirmed listing in the ordinary selling form. Review the quantity and confirm there; promotion is selected separately.
- **My purchases → Bids:** keeps your auction bids alongside buy orders. Buy-order actions remain in the same section, with confirmation before posting, selling or cancellation.

## Exchange example

Choose **My offers → Exchange (new) → Offer diamonds**:

| Field | Value |
| --- | ---: |
| Diamonds offered | `1.000` |
| Total requested gold | `100.000.000` |
| Gold per diamond, calculated automatically | `100.000` |

You can edit the total or unit price. The requested offer total is **before the execution fee**. Quick-exchange receipts are **after the quoted fee**. The game supplies exchange quotes; available quantities and prices can change before confirmation.

## Beta status

Targeted at the Chronicles of Arcadia **12.1.7.2501-era auction APIs**. This is an independent community project, not an official CoA release or launcher integration.

The standalone test suite exercises Lua 5.1 logic, XML script loading, quote changes, confirmations, fees and request ownership. These simulations do not replace in-game checks of every language, layout or server transaction. Please report the addon version, client version and steps to reproduce an issue. Remove private chat and account details from screenshots and logs.

## Development

Python 3.11 is used in CI. The addon itself runs on the game's Lua 5.1 environment.

```sh
python -m pip install -r requirements-dev.txt
python -m unittest discover -s tests -v
python tools/build_release.py
```

The release builder produces an installable ZIP and SHA-256 checksum in `dist/`. It packages only `addon/ArcadiaAuctionClassic`; tests, local settings and development files are excluded.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the source layout and checks.

## Credits and license

Distributed under **GNU GPL version 3**. Original AdvancedAuctionHouse credits and modification notices are preserved in [NOTICE.md](addon/ArcadiaAuctionClassic/NOTICE.md). The [provenance manifest](addon/ArcadiaAuctionClassic/PROVENANCE.json) records the upstream source paths and hashes used for this fork.

Standard game textures, templates and translations are referenced from the installed client; they are not bundled or relicensed here. The new native AuctionHub implementation is not included. No Guild Wars 2 artwork is included.
