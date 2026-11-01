# Dead Air — notes for Claude

Co-op (1 to 4 players) first-person horror escape for Roblox. Owner: Gabriel (gahitchi). Proprietary, all rights reserved.
Gabriel's first real game project, to learn game development before returning to Deep Down (Godot, on hold).

Design doc: https://claude.ai/artifact/Y3L4y9snNMY5AaPbwh1GLQ. Read it before designing features.

## Direction
- Read `docs/DIRECTION.md` first (1 Nov 2026): an emotional game, not an AAA one. Stylized, readable on phones, mood from light, fog and sound. Every round must end in an adrenaline rush.
- A monster that hunts by sound. Loud to escape, quiet to survive: objectives make noise on purpose.
- Voice loudness feeds the monster when a player has voice (Audio API), but voice is always optional (Roblox requires an age check for chat).
- Each map has its own peculiarities and its own monster (like Rainbow Six Siege maps): recording studio (the Engineer) first, then a radio station, then a bell foundry.
- Launch with one map and the full core, then add maps as updates.
- Fair monetization: cosmetics, plus one deliberate exception chosen by Gabriel: a revive can be bought with Robux, priced very high so it stays rare (the normal price is a level). Nothing else that affects survival is sold. The reward track (XP boosts, skins) is free.
- Ask Gabriel when a direction is unclear; he prefers being asked.

## Team
- Gabriel: direction, playtesting.
- ChatGPT: the map and the graphical side (models, textures, lighting look), on its own branch (`chatgpt/...`). It may also touch scripts now and then. Art follows the stylized scope in `docs/DIRECTION.md`; the realism pass on `chatgpt/studio-art-pass` is parked there, not deleted.
- Claude: scripts and game systems. Keep map-specific data out of the systems where possible, so ChatGPT's map can replace the greybox in `MapBuilder`. Fetch before editing: someone else may have pushed.
- Claude and ChatGPT are teammates, not rivals (Gabriel's rule). The focus areas are about who leads on what, not ownership: either can change any file. Make the other's work easier: keep things compatible with their branch, explain changes that affect them, offer help, credit their work, and describe untested work the same way for both. Never frame their work as competing or lesser.

## Workflow
- Claude writes code here and pushes to `main`. Gabriel runs `rojo serve` on his Arch laptop (Studio through Vinegar) and plays.
- There's no Roblox runtime in Claude's environment, so nothing can be play-tested here: review logic carefully and say plainly what is untested.
- Two places (docs/HUB.md): the hub (`hub.project.json`, `src/hub/`) and the match place (`default.project.json`, `src/server`, `src/client`); `src/shared` goes to both. Teleports can't be tested in Studio.
- Before pushing: `stylua src`, `luau-lsp analyze` with each place's sourcemap on its own folders (no type errors), `rojo build` for both project files. Selene needs the Roblox API dump from the network and may not run.
- Bump `Config.VERSION` when a build is meant to be tested.

## Code conventions
- Luau `--!strict` everywhere, typed. One responsibility per module.
- The server is the authority: noise, objectives, catches and rounds happen there. Clients only draw and send input.
- All tuning numbers live in `src/shared/Config.luau`.
- Maps follow `docs/MAP_CONTRACT.md`: a `Workspace.Map` with named folders and marker parts, read by `MapContract`. Systems get positions only from the resulting Layout, never hard-coded. The greybox (`MapBuilder`) follows the same contract and is used when no `Workspace.Map` exists. Change the contract doc and `MapContract` together.
- The monster AI is layered: `Monster/Perception` (awareness, fuzzy hearing), `Monster/Director` (pacing), `Monster/Navigator` (pathing, doors, stuck recovery), `MonsterService` (the state machine). `Config.DEBUG_AI` shows its state and path in the world.
- Doorways must be at least 6 studs wide or the monster's pathfinding can't fit through.
- Comments explain why, in plain words.
- Sounds in `src/shared/Sounds.luau` are placeholders until real ones are uploaded.
