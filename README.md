# MeakAuras

![WoW Version](https://img.shields.io/badge/WoW-12.0%2B%20Midnight-blue)
![Interface](https://img.shields.io/badge/Interface-120001-green)
[![GitHub](https://img.shields.io/badge/GitHub-Falkicon%2FMeakAuras-181717?logo=github)](https://github.com/Falkicon/MeakAuras)
[![Sponsor](https://img.shields.io/badge/Sponsor-pink?logo=githubsponsors)](https://github.com/sponsors/Falkicon)

A Midnight-compatible fork of [WeakAuras](https://github.com/WeakAuras/WeakAuras2) for World of Warcraft 12.0+.

> **Why "Meak"?** It's meek in combat - it knows when to stay quiet around secret values!
>
> *Name lineage: Power Auras → Weak Auras → Meak Auras*

> **Midnight Compatibility**: MeakAuras handles WoW 12.0's "secret values" - opaque userdata returned by combat APIs in instanced content. Where original WeakAuras errors, MeakAuras gracefully degrades.

## About

MeakAuras is a powerful and flexible framework for displaying highly customizable graphics on World of Warcraft's user interface. Show buffs, debuffs, cooldowns, and other relevant information with precision timing and beautiful visuals.

WeakAuras will not support Retail after Midnight (they continue supporting Classic). MeakAuras is the Midnight-compatible fork for Retail players.

## Features

- **Intuitive Configuration** – Powerful visual editor for creating and customizing displays
- **Rich Trigger System** – Auras, health, power, cooldowns, combat events, items, and more
- **Custom Textures** – Includes Power Auras textures and Blizzard spell alerts
- **Progress Tracking** – Bars and textures showing exact durations
- **Animations** – Preset and custom animation paths
- **Side Effects** – Chat announcements, sounds, and custom actions
- **Grouping** – Position and configure multiple displays together
- **Performance** – Conditional loading, modularity, efficient aura scanning
- **Lua Scripting** – Custom triggers and on-show/on-hide code for power users

## Midnight Secret Value Handling

MeakAuras includes defensive wrappers for APIs affected by 12.0 combat restrictions:

| Component | Protection |
|-----------|------------|
| `UnitAura` | Safe wrapper with type checking before `AuraUtil.UnpackAuraData` |
| `C_UnitAuras` | pcall wrappers for `GetAuraDataByIndex`, `GetAuraDataByAuraInstanceID` |
| `AuraUtil.ForEachAura` | Replaced with `SafeForEachAura` that skips secret values |
| Aura comparisons | Graceful handling when values cannot be compared |

See [STATUS.md](STATUS.md) for detailed migration progress.

## Quick Start

Open the options window using any of these commands:

| Command | Description |
|---------|-------------|
| `/ma` | Open MeakAuras options |
| `/meakauras` | Open MeakAuras options |
| `/wa` | Open MeakAuras options (muscle memory) |
| `/weakauras` | Open MeakAuras options (muscle memory) |

Or click the minimap icon.

## Installation

1. Download or clone this repository
2. Place the addon folders in your WoW addons directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```
3. Restart WoW or type `/reload` if already running

**Required folders:**
- `WeakAuras/` (core addon)
- `WeakAurasOptions/` (configuration UI)
- `WeakAurasTemplates/` (trigger templates)
- `WeakAurasModelPaths/` (3D model support)
- `WeakAurasArchive/` (import/export)

## Extensions

- **[WeakAuras Companion](https://weakauras.wtf)** – Desktop app for syncing auras from Wago.io
- **[SharedMedia](https://www.curseforge.com/wow/addons/sharedmedia)** – Additional bar textures
- **[SharedMediaAdditionalFonts](https://www.curseforge.com/wow/addons/shared-media-additional-fonts)** – More fonts

## Finding Auras

Browse community-created auras at [wago.io](https://wago.io/) - from simple buff trackers to complete UI packages.

## Documentation

See the original [WeakAuras Wiki](https://github.com/WeakAuras/WeakAuras2/wiki) for general usage documentation. MeakAuras-specific changes are documented in [STATUS.md](STATUS.md).

## Known Issues

- **Thunder Clap spellCount error** – GenericTrigger.lua comparisons error on secret values (logged but functional)
- **GenericTrigger.lua** – Left original to avoid icon regression; needs careful rework

## Contributing

Found a bug or have a fix? [Open an issue](https://github.com/Falkicon/MeakAuras/issues) or submit a pull request.

## Support

If you find MeakAuras useful, consider [sponsoring on GitHub](https://github.com/sponsors/Falkicon) to support continued Midnight compatibility work.

## License

MeakAuras is a fork of WeakAuras, licensed under the GNU General Public License v2.0.

## Credits

- **[WeakAuras Team](https://github.com/WeakAuras)** – Original addon and years of development
- **Falkicon** – Midnight compatibility fork and maintenance
