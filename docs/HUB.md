# The hub and match servers

The game is two places in one Roblox experience:

- **Hub** (the start place, `hub.project.json`, code in `src/hub/`): where players arrive, see
  lobbies and make their own. Lobbies in the same hub server are listed for everyone (friends-only
  ones only for the host's friends); lobbies your friends made in other hub servers are listed too,
  and joining one moves you to that hub server first.
- **Match** (`default.project.json`, code in `src/server`, `src/client`): rounds are played here, in
  a reserved server per group. After each round: "Play again?" No (or no answer) goes back to the
  hub; Yes votes on the next map. Same map: the next round starts in the same server. Another map:
  the group moves to a fresh match server on it.

Shared code (`src/shared`: Config, Remotes, Sounds, Chapters) is synced into both places.

**Chapters.** Every crew (lobby) plays one chapter, and lobbies are strict: everyone in it must have
that chapter unlocked (the one before it cleared). The hub reads each player's cleared chapters
from the match place's progress save (`Progress_v1`). Quick join puts a player in a public crew on
their next unplayed chapter, or makes one. The teleport carries `{ map, chapter }`; "play again"
keeps the chapter.

## One-time setup

1. Publish the current game (the match place) as usual, if it isn't already.
2. Creator Dashboard > your experience > **Places** > **Add a place**, for the hub. Then in the
   experience's settings make the hub the **start place** (the one players join first).
3. Copy both place ids into `src/shared/Config.luau`: `Config.PLACES.HUB` and `Config.PLACES.MATCH`.
4. Publish each place with its own code:
   - Hub: open the hub place in Studio, run `rojo serve hub.project.json`, connect, then
     File > Publish to Roblox.
   - Match: open the match place, run `rojo serve` (default project), connect, publish.
   (Alternatively `rojo build hub.project.json -o hub.rbxl` and publish that file.)
5. Both places need **Game Settings > Security > Enable Studio Access to API Services** for testing
   saving and lobbies in Studio.

Every time code changes, republish the place(s) it touches: `src/hub` = hub only, `src/server` and
`src/client` = match only, `src/shared` = both.

## Testing

- In Studio: the hub's lobby list, creating, joining and leaving lobbies all work; **Start** says
  teleports need the published game. The match place plays on its own as before, and "Play again?"
  keeps everyone in the same server.
- Teleports (Start, back to the hub, changing map, joining a friend in another hub) only work in
  the published game: join it from the Roblox app, with a friend or a second account.
- Each map can be a hand-made model stored in the match place at `ServerStorage.Maps.<map id>`
  (see `Config.MAPS` and `docs/MAP_CONTRACT.md`); without one, the studio greybox is built.

## New generated environment (hub-v1 branch)

The **chatgpt/hub-v1** branch replaces the placeholder waiting room in the
hub place with Wrenmouth Coast Checkpoint. This is a native-part environment
with named hub markers; the existing lobby/teleport system remains authoritative.
It is intentionally independent of the match-place studio redesign, which
lives on **chatgpt/studio-v2** until changes are merged together.

Read [HUB_V1_PLAYTEST.md](HUB_V1_PLAYTEST.md) for the map, marker contract,
crew-board/van/loadout/telescope interactions, and the later Studio test gate.
