# Contributing

Bug reports, translations and focused pull requests are welcome.

## Source layout

- `addon/ArcadiaAuctionClassic/`: distributable Lua, XML, data, locales, license and credits.
- `tests/`: Lua 5.1 simulations using `lupa.lua51`, plus XML/package checks.
- `tools/build_exchange_ui.py`: generates the exchange XML. Run from the repository root after editing it.
- `tools/build_release.py`: creates the installable ZIP and checksum from the package only.

## Before opening a pull request

1. Describe the user-visible issue and expected behavior.
2. Preserve explicit confirmation for monetary actions and native quote/fee validation.
3. Keep code compatible with Lua 5.1; do not replace it with a newer Lua test runtime.
4. Update translations for all supported languages where practical, keeping a usable English fallback.
5. Run `python -m unittest discover -s tests -v` and `python tools/build_release.py`.
6. State what you checked in the real client separately from mocked tests.

Do not commit saved variables, character/account exports, private chat logs, credentials, extracted proprietary client implementation files or local backups. The optional personal bulk-addon interoperability test uses stubs, so the public tests require no other addons.

Preserve upstream notices and license terms. Contributions are distributed under this project's GPLv3 license. No official client integration or endorsement is implied.
