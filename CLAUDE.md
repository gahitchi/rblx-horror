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

## Workflow
- Claude writes code here and pushes to `main`. Gabriel runs `rojo serve` on his Arch laptop (Studio through Vinegar) and plays.
- There's no Roblox runtime in Claude's environment, so nothing can be play-tested here: review logic carefully and say plainly what is untested.
- Before pushing: `stylua src`, `luau-lsp analyze` with a sourcemap (no type errors), `rojo build`. Selene needs the Roblox API dump from the network and may not run.
- Bump `Config.VERSION` when a build is meant to be tested.

## Code conventions
- Luau `--!strict` everywhere, typed. One responsibility per module.
- The server is the authority: noise, objectives, catches and rounds happen there. Clients only draw and send input.
- All tuning numbers live in `src/shared/Config.luau`.
- The map is built in code (`MapBuilder`) as a greybox; real models come later.
- Comments explain why, in plain words.
- Sounds in `src/shared/Sounds.luau` are placeholders until real ones are uploaded.
