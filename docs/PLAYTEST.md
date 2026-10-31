# Playtest checklist: 0.5.0

One session tests everything built since the last playtest. Nothing here has run in Roblox yet,
so expect some of it to break; that's what this session is for.

## Before you start

- Play ChatGPT's art branch merged with `main` if both are ready, so the art and the gameplay get
  tested together. Otherwise play `main`.
- In `src/shared/Config.luau`: set `DEBUG_AI = true` for the first round (it shows the monster's
  state and path), then `false` for a round played for feel.
- If one feature breaks badly, switch it off in `Config.FEATURES` (`WALKIE`, `TAPE`, `MIMICRY`,
  `SPECTATE`) and keep testing the rest.
- Use **Test > Clients and Servers with 2 players** for at least one round: walkies and spectating
  need two people.
- Keep the Output window open. Copy every red or yellow line, and every `[Map]` line.

## 1. The map and the monster's movement (solo, DEBUG_AI on)

- [ ] No `[Map] ERROR` lines at start.
- [ ] The monster walks into every room, including the booths, the archive and the basement.
- [ ] It never stands against a wall with "nav Failed" for more than a couple of seconds.
- [ ] It opens doors it walks through.
- [ ] Its footsteps are audible before you see it.

## 2. Hearing and behaviour (solo)

- [ ] Walking near it makes it stop and turn toward you (Listen) before anything else.
- [ ] More noise sends it to where you were (Investigate), then it checks around (Search).
- [ ] Sprinting near it starts a hunt (a cry, the vignette closes in).
- [ ] Breaking line of sight and crouching quietly loses it after a few seconds; it searches ahead of
      where you were heading.
- [ ] Brushing past it while crouched gets you found.
- [ ] Up close in a hunt, it lunges after a visible and audible warning.
- [ ] After it catches someone, or spends a long time near you, it backs off for a while.
- [ ] In the first 45 seconds after it arrives, it keeps away from where you are.

## 3. Mimicry (solo)

- [ ] After you've made some noise near it, now and then you hear a footstep, door or crackle that
      isn't real, from a room near it. It then stands still for a few seconds.

## 4. Tape recorder (solo)

- [ ] R starts recording; the item line says RECORDING.
- [ ] Walk or open a door while recording: it says "Recorded". Recording in silence says the tape is blank.
- [ ] R again sets it down in front of you, on the floor, not inside a wall.
- [ ] About 6 seconds later it plays the sounds back, with a small red light, and the monster goes to check.
- [ ] E picks it back up. Picked up before it plays, it's still recorded; after it plays, it's blank.

## 5. Walkie-talkies (2 players)

- [ ] Each player has a walkie on the belt, visible to the other.
- [ ] 1 to 4 send callouts: the other player sees "[radio] Name, Room: text" and their walkie crackles.
- [ ] Holding V makes the other's walkie crackle repeatedly; the item line shows who's on the radio.
- [ ] With voice chat (published place only): your voice comes out of the other's walkie, sounding like a radio.
- [ ] The crackle draws the monster to the player whose walkie made it.
- [ ] N switches your walkie off: no messages, no crackle on you.

## 6. Spectating (2 players)

- [ ] When one player is caught, they watch the other over the shoulder; Q and E switch players.
- [ ] Their own flashlight doesn't light the spectated view.
- [ ] When the round ends, the camera goes back to normal first person.

## 7. The round as a whole

- [ ] Every objective works: generator, fuses, tape deck, front doors, escape.
- [ ] Lobby, results and a second round all work.
- [ ] Frame rate stays at 60 on the laptop.
- [ ] How it feels: too hard, too easy, too dark? Which moments were tense, and which were boring?

## 8. Added in 0.4.0: progress, results, ready-up, feedback

- [ ] Top right in the lobby: your level and coins. With API access off it says "(not saved)".
- [ ] Ready up (button or G): the count updates; when everyone's ready the countdown drops to 3.
- [ ] At the end of a round, the results panel lists each player's outcome and what they earned,
      with your own breakdown (round, generator pulls, fuses, emergency tape, decoys, escape).
- [ ] With API access on: level and coins are still there after leaving and rejoining.
- [ ] Feedback (lobby or results): pick a rating, tags and a comment, Send; "Thank you!" appears and
      a `[Feedback]` line shows in the Output. Sending twice in a row is politely refused.
- [ ] The mouse is free to click in the lobby and in the menus, and locked again in the round.

## 9. Added in 0.5.0: teammate revives and the reward track (2 players)

- [ ] When one player is caught, a "Lost walkie" stays where it happened (dark).
- [ ] The caught player (spectating) sees "Ask your team to bring you back?". At level 1, "Lose a
      level" is refused; get to level 2 first (play a round or two, or lower the XP numbers).
- [ ] After paying, the walkie lights up and the other player gets a radio message with the room.
- [ ] Holding E on it for 4 s crackles loudly (the monster should come), then the caught player
      reappears there; the reviver earns XP. Only once per player per round.
- [ ] If nobody reaches it before the round ends, the level comes back ("refunded").
- [ ] Lobby: "Next reward at level N" and the flashlight button cycling through unlocked looks; the
      beam colour shows for you and for the other player. Losing a level relocks its look.
- [ ] Robux revive: needs a Developer Product id in `Config.REVIVE.PRODUCT_ID` (0 hides the button);
      Studio test purchases are free.
