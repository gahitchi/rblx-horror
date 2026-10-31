# Dead Air — notes for Claude

Co-op (1 to 4 players) first-person horror escape for Roblox. Owner: Gabriel (gahitchi). Proprietary, all rights reserved.
Gabriel's first real game project, to learn game development before returning to Deep Down (Godot, on hold).

Design doc: https://claude.ai/artifact/Y3L4y9snNMY5AaPbwh1GLQ. Read it before designing features.

## Direction
- A monster that hunts by sound. Loud to escape, quiet to survive: objectives make noise on purpose.
- Voice loudness feeds the monster when a player has voice (Audio API), but voice is always optional (Roblox requires an age check for chat).
- Each map has its own peculiarities and its own monster (like Rainbow Six Siege maps): recording studio (the Engineer) first, then a radio station, then a bell foundry.
- Launch with one map and the full core, then add maps as updates.
- Fair monetization: cosmetics only, nothing that helps survive.
- Ask Gabriel when a direction is unclear; he prefers being asked.

## Team
- Gabriel: direction, playtesting.
- ChatGPT: the map and the graphical side (models, textures, lighting look), on its own branch (`chatgpt/...`). It may also touch scripts now and then.
- Claude: scripts and game systems. Keep map-specific data out of the systems where possible, so ChatGPT's map can replace the greybox in `MapBuilder`. Fetch before editing: someone else may have pushed.

## Workflow
- Claude writes code here and pushes to `main`. Gabriel runs `rojo serve` on his Arch laptop (Studio through Vinegar) and plays.
- There's no Roblox runtime in Claude's environment, so nothing can be play-tested here: review logic carefully and say plainly what is untested.
- Before pushing: `stylua src`, `luau-lsp analyze` with a sourcemap (no type errors), `rojo build`. Selene needs the Roblox API dump from the network and may not run.
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
