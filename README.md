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
- Gold/diamond exchange integrated into **Overview**, **Search → Money → Exchange offers**, and **My offers**.
- Quick-exchange rows show **what you receive after fees**, the cost and a button to review the exchange.
- New exchange offers accept an **amount, total price or price per diamond**. The fields update each other and group thousands with dots.
- Purchases, bids, listings, exchanges and cancellations require confirmation.
- Eleven client languages, with English fallback where needed.

The addon uses the game's auction APIs and native UI resources. It is standalone: no CoAManager or KittyCombo installation is required.

## Install

1. Download **`ArcadiaAuctionClassic-0.2.4-beta.zip`** from [Releases](https://github.com/libsman/ArcadiaAuctionClassic/releases). Use the named addon ZIP, not GitHub's automatically generated source archive.
2. Extract the `ArcadiaAuctionClassic` folder into your game's `Interface/AddOns` directory.
3. Restart the client after first installation so the new XML frames load.
4. Open an auctioneer as usual.

```text
Interface/
└── AddOns/
    └── ArcadiaAuctionClassic/
        ├── ArcadiaAuctionClassic.toc
        ├── Lua/
        └── Xml/
```

## Choose your interface

| Command | Result |
| --- | --- |
| `/aac classic` | Select Classic, then reopen the auctioneer. |
| `/aac native` | Select the game's original AuctionHub, then reopen the auctioneer. |

Switching interfaces does not normally require a restart. Outstanding requests finish first. A permanently missing reply may require a restart to recover safely. Features without a Classic counterpart, such as purchase orders, remain available in the original interface.

## Exchange example

Choose **My offers → Exchange → New offer → Offer diamonds**:

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
