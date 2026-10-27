# ShutUpWesley - Knowledgebase

MechWarrior 5: Mercenaries mod that silences NPC banter and whining during missions. Free, Nexus Mods upload. Requested by users of the save editor.

## Project
- Folder: `<code>\shutupwesley\` (mod source lives in the MW5 Mod Editor project; this folder holds notes, Nexus page text, release zips).
- Deliverable: mod folder `ShutUpWesley\` (mod.json + cooked pak) zipped for Nexus. Users drop it into `MW5Mercs\Mods`. No installer, no runtime.
- Toolchain: MW5 Mod Editor (PGI, UE 4.27 base, Epic Games Store free add-on "Mechwarrior 5 Modding Toolkit", 55 GB). Installing to `D:\Epic Games` 2026-10-26.
- Game on dev box: GOG 1.15.398 (DLC9). YAML still 0.97.3.2 (needs 0.99.3.1 before any campaign launch).

## Facts (from PGI Mod Editor Guide v2)
- Audio is Wwise. Dialogue/VO are Wwise events on buses; UE SoundClass/SoundMix do not apply.
- Overrides: "Save To Mod" duplicates a game asset into `<Mod>\ModOverride\<original path>`; the override replaces the original at runtime. New assets go in `<Mod> Content`.
- Package: Manage Mod -> Package Mod; output defaults to the editor's `MW5Mercs\Mods`. mod.json carries name, version, loadOrder (0 unless required), author, description.
- Editor requires the Epic account to own MW5 (verify whether GOG ownership is accepted; the store let the add-on be claimed).
- Mod logic entry point: a Blueprint named `ModActor` in the mod content is spawned by the game at startup (community convention used by Mod Options, YAML). Not in the PGI guide.

## Game asset map (from pak index, `tools\pak-index.sh` -> `pak-index.txt`, 286,068 entries, V11, unencrypted)
- Wwise banks: `Content/Audio/Banks` incl. `Dialogue.bnk` (single dialogue bank). Media in `Content/WwiseAudio/Windows` (19k wem).
- Wwise events `Content/Audio/Events/Dialogue/`: `BB_*` (cockpit computer "Betty": ammo/heat/detect callouts, keep by default), `Dialogue_Radio_Chatter`, `Commander_Chatter`, `Enemy_Radio_Chatter`, `Enemy_Radio_ChatterV2` (the banter buses), `Hangar_Chatter` (out of mission), `Audio_Cache_Chatter`, `Play_BA_01..09`, `DialogueContextTagPriorityData`.
- Playback component: `Content/Dialogue/_common/DefaultDialogueComponent` (+ `DialogueGroup_Struct`). Prime override target for per-category muting.
- Speaker data: `Content/Dialogue/Voices` (534), `Content/Dialogue/persona` (146), `Content/Dialogue/Missions/*` (scripted mission lines A1M1.., Cluster*, DLC*), `Campaign/Dialogue` (story, HoloTable), DLC7-9 `Dialogue/Personas`, DLC7 `Dialogue/Barks/*Barks` (LanceBarks, EnemyClanPilotNBarks, ClanBaseCommanderNBarks, named characters: Ash, Barrett, Jacob, Lyana, Morgan, Nick, Rachel, Sam, Sasha, RivalClannerN).
- Game already has a global `VoiceVolume` slider (GameUserSettings.ini). Setting it to 0 kills Betty, briefings and story too. The mod's value = selective: kill barks/banter, keep Betty + objective lines.

## Bark book structure (confirmed from extracted `EnemyClanPilot1Barks`, tools\extract-barks.sh -> extracted\)
- Class `MWDialogueBookAsset` (Script/MechWarrior). Properties: `Lines` (array of struct `MWDialogueLine`), `DialogueVoice`/`DialogueVoiceAssetId`, `Persona`/`PersonaAssetId`.
- `MWDialogueLine` fields: `Name`, `Caption` (Text), `Context` (GameplayTag `DialogueContext.*`), `AudioSource`, `Duration`, `MaxPlaysPerMission`, `MaxPlaysPerCampaign`, `CooldownTimeSeconds`, `CooldownNumMissions`, `bCanInterruptSelfContext`, `bCanInterruptLowerPriorityContext`, `bServerOnly`.
- EnemyClanPilot1 has only 15 lines: 2x AttackDestroyComponent, 2x KillBlowCheer, 2x TakeDamageDestroyComponent, 1 each EngagementStarted / DiedUnitCritical / Ejected* / Assassination*. Tiny pools + loose play limits = the repetition users hear.
- Captions confirm it is the "Stravag / freebirth / surat" set.
- 29 books in DLC7/Dialogue/Barks: EnemyClanPilot1-10, ClanBaseCommander1-4, RivalClanner1-5, LanceBarks, Ash, Barrett, Jacob, Lyana, Morgan, Nick, Rachel, Sam, Sasha. Vanilla (non-DLC7) enemy/lance chatter lives in `Content/Dialogue/Voices` + `persona` (534 + 146 assets), same class; map those next.

## How the override is actually built (what worked, 2026-10-27)
- All MWDialogueLine fields are READ-ONLY in the editor (VisibleAnywhere; books are generated from CSV). Details panel and Python set_editor_property cannot change them.
- Python duplicate_asset into `/ShutUpWesley/ModOverride/...` is WRONG: it writes to `<Mod>\Content\ModOverride` with package `/ShutUpWesley/...`, and MWLogAssetManager warns "duplicate PrimaryAssetID ... cannot replace path /Game/...". Those copies were parked in `_to_delete\`.
- RIGHT: copy the uncooked original (`<Editor>\MW5Mercs\Content\DLC7\Dialogue\Barks\*.uasset`, single-file packages, read-only attr) into the mod's TOP-LEVEL `<Mod>\ModOverride\DLC7\Dialogue\Barks\` (mirrored path, package name stays `/Game/...`) and patch bytes on disk: `tools\suw_patch.py --mode silent|quiet|verify` (uses the editor's bundled Python 3.7, stdlib only).
- `MaxPlaysPerMission` is 0 on every shipped line = UNLIMITED. So Silent cannot use it; Silent blanks each line's `Context` GameplayTag (`DialogueContext.*` -> `None`) so no event ever matches. Quiet sets MaxPlaysPerMission = 1.
- Uncooked tag layouts: IntProperty payload at tag+24(+1 hasguid). GameplayTag StructProperty payload is 41 bytes = nested tagged list `[TagName][NameProperty][8][0][0][FName value][None]`; value at payload+25.
- The running editor LOCKS every file it discovers under the plugin folder (watcher loads them). Patch with the editor CLOSED, then reopen and Package Mod.
- Counts: ClanBaseCommander 22 lines each, EnemyClanPilot 15, RivalClanner 28, LanceBarks 181. 20 books / 559 lines in v1 (9 story-character books skipped).
- Python API stub (property names, docs): `%LOCALAPPDATA%\MW5Mercs\Intermediate\PythonStub\unreal.py`. Editor log: `%LOCALAPPDATA%\MW5Mercs\Saved\Logs\MW5Mercs.log` (buffered). In the Output Log Cmd box use `py "<file>"`.

## Design (FINAL for v1: data override, no Blueprint logic)
- Override each bark book via Save To Mod; set every line's `MaxPlaysPerMission` = 0 (Silent) or 1 (Quiet, each taunt once per mission). `MaxPlaysPerCampaign` left alone in Quiet.
- Two Nexus files: ShutUpWesley-Silent, ShutUpWesley-Quiet. v1 scope = clan DLC7 books; v1.1 = vanilla enemy/lance voices; story characters (named books) excluded from Silent by default, optional file later.
- Untouched: `BB_*` cockpit computer, `Dialogue/Missions/*` scripted lines, briefings, HoloTable, hangar chatter.
- Risk: PGI changes books in a patch -> override reverts to our copy of the old book (stale captions, no crash). Note on Nexus page.

## Design (superseded: ModActor + Mod Options)
- ModActor on startup registers Mod Options settings: Mute lancemate banter, Mute enemy/employer radio, Mute story commentary in missions. Defaults: all on.
- On mission start (world is a mission level, not the dropship/leopard hub), set the Wwise RTPC / state that drives the voice bus to 0 for the enabled categories; restore on mission end so dropship/Cantina VO is untouched.
- Audio only: comms text panel and objectives untouched. Users who also want the text gone can stack No HUD Dialogue Text (Nexus 810).
- If the voice bus is a single bus with no category split, v1 = one toggle "Mute all mission VO" and category split comes later via dialogue-event overrides.

## Existing mods checked (none mute audio banter)
- No HUD Dialogue Text Or Portraits (810), No Dialog HUD (395), Immersive Comms (1329): text/panel only.
- No Nasty Radio (550): changes voice filters, large dialogue-file replacement.

## Packaging (headless, confirmed 2026-10-27)
- `tools\package.ps1 -Variant Silent|Quiet` runs `RunUAT.bat PackageMW5Mod -Project -PluginPath=<plugin folder> -basedonreleaseversion="1.0" -ModName=ShutUpWesley -ModSubstitionFolder=ModOverride -DeployDirectory=<Editor>\MW5Mercs\Mods` hidden; log `package-<Variant>.log.out`. ~4 min on the HDD. Works with the editor open or closed.
- `-ModSubstitionFolder` (PGI's typo, keep it) MUST be the bare folder name. UAT source `Engine\Source\Programs\AutomationTool\MW5\MW5.cs` builds `<plugin>/<name>/` for the cook (`-DLCSubstitutionsContentPath=<name>`) and the pak response file maps `Saved/Cooked/WindowsNoEditor/MW5Mercs/Plugins/ShutUpWesley/<name>/*` -> `../../../MW5Mercs/Content/`. Passing a full path produced a mangled response line and the overrides were paked under the plugin path (never loaded by the game).
- Correct pak layout (matches DropFees, a shipped override mod): overrides at `MW5Mercs/Content/DLC7/Dialogue/Barks/*.uasset|.uexp`, plus `MW5Mercs/Plugins/ShutUpWesley/AssetRegistry.bin` and `MW5Mercs/Config/*.ini`. mod.json `manifest` lists the DESTINATION paths `/Game/DLC7/Dialogue/Barks/<Book>.uasset`.
- UAT deploys one level too high: `<Editor>\MW5Mercs\Mods\{mod.json,Paks\,Resources\}`. Assemble into `dist\<Variant>\ShutUpWesley\` and copy that folder to `C:\Program Files (x86)\GOG Galaxy\Games\MW5Mercs\MW5Mercs\Mods\ShutUpWesley`.
- Delete `<plugin>\Saved\Cooked` before each build or stale cooked files get paked twice. `<plugin>\Content\ModOverride` (duplicate_asset leftovers) is harmless dead weight in the pak; remove it once the editor is closed (editor locks it).
- Verification: `tools\verify-pak.sh` (repak list), `tools\check-override.sh` (unpack, compare each override book to the shipped original; expect 0 identical).
- Variants: patch originals with `suw_patch.py --mode quiet --src <originals> --dst stage\quiet\...`, copy into `<plugin>\ModOverride\...` (editor must be CLOSED), set mod.json displayName/description, delete Saved\Cooked, package. Same ModName so Silent and Quiet cannot be enabled together. Staged book sets: `stage\silent`, `stage\quiet`.

## Status
- 2026-10-27: Silent v1.0.0 build 5 packaged and installed to GOG Mods folder for in-game test. Quiet books staged (stage\quiet); plugin swap blocked until editor closes.
- 2026-10-26: project started. Editor installed from the Epic launcher to D:. Original plan (ModActor muting the Wwise voice bus) superseded by the data override above.
