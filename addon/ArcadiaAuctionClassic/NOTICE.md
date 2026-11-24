# Attribution and modifications

Arcadia Auction Classic is a modified version of Advanced AuctionHouse.

Original authors named by its manifest: **Mavoc, TellTod, Noguai, Graves, Byte**.

Original project: https://www.curseforge.com/chronicles-of-arcadia/addons/advancedauctionhouse

Original manifest version: v7.4.0, build 20190526000000. Baseline: the `_BuiltIn/AdvancedAuctionHouse` sources present in the local CoA client archive inspected on 2026-11-23. Per-file source hashes are recorded in PROVENANCE.json. This is not an unmodified upstream release.

Modifications for Blackkid's community project, 2026-11-23: independent AAC namespace and saved settings; current auction session ownership; current browse listing IDs and confirmations; search/history coordination; current sale and bid handling; localization fallback; obsolete hooks removed; XML and legacy UI fixes; original-interface fallback.

The AAH manifest explicitly licenses its addon code under the **GNU General Public License version 3**. This fork is distributed under that license, with readable Lua/XML sources. Keep this notice and LICENSE.txt with redistributions, and make modified source available under the applicable GPL terms.

The addon refers to standard game UI templates, translations and textures already installed in the CoA client. Those client resources and the new native AuctionHub implementation are not included in this archive; their rights are not asserted by this license notice.

Community maintainer: Blackkid. No affiliation or endorsement by the CoA team is implied. Hosting, official launcher inclusion and rewards-program approval have not been requested or granted as part of this build.

2026-11-23, 0.1.4: actual per-unit sorting with separated currencies, small progress display, multilingual confirmation/fee labels and independent Classic Exchange controller/UI. Community maintainer: Blackkid. Original author credits above are retained.

2026-11-23, 0.1.5: Gold/Dia comparison, fixed decimal formatting, clearer labels and Classic Exchange layout with separate views and aligned table columns.

2026-11-23, 0.1.6: visible Blackkid community-maintainer branding in the window title, manifest and in-game description. Original authors, GPLv3 license and source provenance retained.

2026-11-23 Blackkid: 0.1.7 adds a simple two-card currency exchange home, live net quotes and presets, with separate offer management. Original authors and GPLv3 remain credited.

2026-11-23 Blackkid: 0.1.8 replaces technical Exchange offer forms with simple gold/diamond offer cards and smaller native currency icons.

2026-11-24 Blackkid: 0.1.9 updates active-Prestige auction durations, estimated sale-fee presentation and AAC command help for patch2501.

2026-11-24 Blackkid: 0.1.10 simplifies exchange navigation, adds public rate books and combines owned orders without expanding cancellation permissions.

2026-11-24 Blackkid: 0.2.0 integrates exchange into Money categories, Overview and My offers; classic rate list and compact quote replace the standalone tab.

2026-11-24 Blackkid: 0.2.1 isolates the synthetic Money/Exchange category from native category lookups and makes it the first subentry.

2026-11-24 Blackkid: 0.2.2 reuses native currency sprites and Classic list/button assets for the colored exchange landing, fixes sell field anchoring and adds scoped Shift-link search input.

2026-11-24 Blackkid: 0.2.3 adds synchronized total/unit exchange prices with grouped inputs and compact net/cost quick-exchange rows using existing Classic controls and native currency icons. No GW2 assets are included.

2026-11-24 Blackkid: 0.2.4 prepares the standalone public source/test/release package and corrects the exchange-card texture path.
