# ShutUpWesley

A MechWarrior 5: Mercenaries mod that silences the repetitive NPC radio banter
during missions: enemy Clan pilots, Clan base commanders, rival Clanners and the
lance chatter added with the Clans DLC. The cockpit computer, mission briefings,
objectives and scripted story dialogue are untouched.

Download the packaged mod from Nexus Mods. This repository holds the mod source
and the tooling used to build it.

## Variants

| File | What it does |
|------|--------------|
| ShutUpWesley-Silent | Those lines never play. |
| ShutUpWesley-Quiet  | Each line plays at most once per mission instead of endlessly. |

Install only one variant at a time (they share the mod name).

## Install

1. Extract the zip into `<game>\MW5Mercs\Mods\` so you get `Mods\ShutUpWesley\mod.json`.
2. Start the game, open Mods, enable ShutUpWesley, restart when prompted.

Works with the GOG, Steam and Epic versions. No dependencies. Load order does not
matter unless another mod also overrides the DLC7 bark books.

## How it works

The mod is a data-only override of 20 `MWDialogueBookAsset` files under
`DLC7/Dialogue/Barks` (10 EnemyClanPilot books, 4 ClanBaseCommander, 5
RivalClanner, LanceBarks; 559 lines). No Blueprint logic, no audio files.

Shipped books have `MaxPlaysPerMission = 0` on every line, which the game treats
as unlimited. The Silent variant blanks each line's `Context` GameplayTag so no
dialogue event ever matches it; the Quiet variant sets `MaxPlaysPerMission = 1`.
The named story characters (Ash, Barrett, Jacob, Lyana, Morgan, Nick, Rachel,
Sam, Sasha) are left alone.

The `MWDialogueLine` fields are read-only in the Mod Editor (the books are
generated from CSV), so the patch is applied to the uncooked `.uasset` bytes by
`tools/suw_patch.py`, then the mod is cooked and packaged with PGI's own
`PackageMW5Mod` UAT command (`tools/package.ps1`).

## Building

Requirements: the MechWarrior 5 Mod Editor (Epic Games Store), Python 3 (the
editor bundles one), and for the verification scripts a Linux shell with
[repak](https://github.com/trumank/repak).

```
set MW5_EDITOR=D:\path\to\MechWarrior5Editor
copy the ShutUpWesley folder from this repo to %MW5_EDITOR%\MW5Mercs\Plugins\
python tools\suw_patch.py --mode silent      (or quiet)
powershell -File tools\package.ps1 -Variant Silent
```

The packaged mod lands in `%MW5_EDITOR%\MW5Mercs\Mods\` (mod.json, Paks\,
Resources\); assemble those into a `ShutUpWesley\` folder. Notes on the UAT
quirks (substitution folder must be the bare name `ModOverride`, cook output must
be cleared between builds) are in `knowledgebase.md`.

The game's own `.uasset` files are not part of this repository.

## Known limitations

- Only the Clans (DLC7) bark books are covered in 1.0. Vanilla Inner Sphere enemy
  and lancemate voice lines are planned for a later version.
- If PGI changes a bark book in a patch, the override keeps this mod's copy of the
  older book (stale captions at worst, no crash).

## License

MIT, see LICENSE. MechWarrior 5: Mercenaries is the property of Piranha Games Inc.
This mod is not affiliated with or endorsed by Piranha Games or Microsoft.
