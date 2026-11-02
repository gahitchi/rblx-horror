--!strict
-- Every tuning number in one place. Distances are in studs, times in seconds.

local Config = {}

Config.GAME_NAME = "Dead Air"
Config.VERSION = "0.9.2-convincing-assets"
Config.DEBUG = true -- extra Output logging while in development
Config.DEBUG_AI = false -- shows the monster's state, awareness and path in the world

-- Movement
Config.CROUCH_SPEED = 6 -- silent
Config.WALK_SPEED = 11
Config.SPRINT_SPEED = 20 -- a little faster than the monster's chase, but loud and tiring
Config.STAMINA_SECONDS = 6 -- of continuous sprinting
Config.STAMINA_REFILL_SECONDS = 10 -- from empty to full
Config.CROUCH_CAMERA_DROP = 1.6

-- How far each kind of noise carries, in open air
Config.NOISE = table.freeze({
	WALK = 16,
	SPRINT = 38,
	LAND = 30,
	DOOR = 36,
	DOOR_SLAM = 50, -- the monster opening a door
	FLASHLIGHT = 8,
	VOICE_MAX = 60, -- shouting
	WALKIE_CRACKLE = 26, -- a teammate's transmission coming out of your walkie
	WALKIE_CLICK = 6, -- pressing talk, switching it on or off
	TAPE_PLACE = 8, -- setting the recorder down
	-- Chapter objectives (loud on purpose: getting out means making noise)
	LOCK_SLAM = 90, -- the quarantine locks slamming as the building wakes
	REEL_PLAYBACK = 160, -- loading a reel plays its track out loud for a few seconds
	RECORDING = 400, -- the complete recording through every speaker: everyone hears it
	CLUTTER = 34, -- moving an instrument off the road case
	TAPE_SLIP = 18, -- a rethreading mistake: the tape clatters off a guide
	SAFE_CLUNK = 16, -- a wrong combination
	BUZZ = 48, -- a wrong patch: the desk buzzes through the speakers
	FADER_SPIKE = 120, -- letting the levels drift during the last session
	MAIL_SLOT = 12, -- pushing a tape through the front doors' mail slot
	SHUTTER = 70, -- a quarantine shutter dropping
	BREATH = 12, -- breathing in a hiding spot with the monster close
	GASP = 40, -- running out of held breath
	THROW_LIGHT = 32, -- a can landing
	THROW_GLASS = 55, -- a bottle smashing
	THROW_HEAVY = 48, -- a pipe clanging down
	-- Echoes
	HUM = 20, -- an entranced body humming the sound, every few seconds
	WHISPER = 14, -- an echo's whisper, when the monster happens to catch it
})
Config.FOOTSTEP_INTERVAL = 0.4 -- how often movement noise is sampled per player
Config.WALL_DAMPING = 0.5 -- each wall between the noise and the listener halves its reach
Config.MAX_WALL_HITS = 3
Config.VOICE_THRESHOLD = 0.04 -- quieter than this counts as silence
Config.VOICE_SEND_INTERVAL = 0.25

-- The monster. It behaves in layers, like the creatures in big horror games:
--   perception: every noise it hears raises its awareness and gives it a rough idea of where the
--     sound came from (fainter = vaguer). Its own footsteps mask quiet sounds while it moves.
--   behaviour: low awareness makes it stop and listen; more makes it investigate, then search the
--     area; a player heard clearly and close turns it into a hunt.
--   director: an unseen pacing layer. It keeps the monster away for a grace period after it
--     arrives, sends it backstage after long or deadly encounters, and nudges it toward the players'
--     part of the building when it hasn't been near them for a while.
-- A hunt starts at walking pace and speeds up the longer it lasts, so a sprint buys distance but
-- not escape: break away and go quiet. Up close it lunges, after a warning.
Config.MONSTER = table.freeze({
	-- Speeds
	ROAM_SPEED = 7,
	SEARCH_SPEED = 8,
	INVESTIGATE_SPEED = 9,
	HURRY_SPEED = 13, -- investigating something loud or alarming
	RETREAT_SPEED = 11,
	CHASE_SPEED = Config.WALK_SPEED, -- at the start of a hunt
	CHASE_MAX_SPEED = 19, -- still just under a sprint
	CHASE_RAMP_SECONDS = 8, -- from start to max speed
	-- Lunge and catch
	LUNGE_RANGE = 14,
	LUNGE_WINDUP = 0.45, -- the warning before it leaps
	LUNGE_SPEED = 32,
	LUNGE_TIME = 0.6,
	LUNGE_COOLDOWN = 6,
	CATCH_DISTANCE = 4.5,
	-- Perception (awareness runs from 0 to 100)
	LISTEN_AT = 12,
	INVESTIGATE_AT = 35,
	HURRY_AT = 60,
	HUNT_AT = 70,
	AWARENESS_DECAY = 5, -- per second
	MAX_LOCATION_ERROR = 14, -- how far off its guess is for a barely audible sound
	CHASE_LOCK_DISTANCE = 55, -- it only hunts a player it hears this close or closer
	CHASE_MEMORY = 3.5, -- seconds without hearing its target before it loses the hunt
	TOUCH_DISTANCE = 3.5, -- this close it feels you, silent or not
	HEARING_STILL = 1, -- hearing range multipliers: best when it stands still and listens
	HEARING_WALKING = 0.85,
	HEARING_HURRYING = 0.75,
	HEARING_HUNTING = 0.7,
	-- Behaviour timing
	LISTEN_TIME = 2.2,
	SEARCH_TIME = 25,
	SEARCH_POINTS = 5,
	SEARCH_RADIUS = 22,
	ARRIVAL_DELAY = 15, -- seconds after the round starts before it appears
	-- Director
	GRACE_TIME = 45, -- after arriving, it keeps to the far side of the building
	NEAR_DISTANCE = 30, -- "near the players" for pacing purposes
	MENACE_SECONDS = 45, -- of being near players before it backs off for a while
	MENACE_COOL_SECONDS = 30, -- far from players, the menace drains in this long
	RETREAT_TIME = 35,
	HINT_AFTER = 75, -- seconds away from everyone before it drifts toward the players' area
	-- Frenzy (shocks): it hears much farther, never backs off, and goes straight for loud sounds
	FRENZY_HEARING = 2.5,
	-- Sight (Monster/Vision). He's a man with great hearing, not a blind thing: hearing leads, and
	-- light decides how far he sees. Ranges in studs.
	SIGHT = table.freeze({
		CONE_DEGREES = 110, -- his field of view
		DARK_RANGE = 9, -- someone standing in the dark
		LIT_RANGE = 28, -- someone in a lamp's pool of light
		TORCH_RANGE = 40, -- someone with their flashlight on
		BEAM_RANGE = 55, -- a flashlight shone across him is noticed from this far, wherever he faces
		BEAM_DOT = 0.93, -- how directly the beam has to point at him
		LIT_REACH = 0.7, -- a lamp lights this share of its range
		LIT_MIN_BRIGHTNESS = 0.27, -- small equipment pilots do not confer full lit-room sight range
		NOTICE_MIN = 0.35, -- seconds of watching before he's sure, up close...
		NOTICE_MAX = 1.3, -- ...and at the edge of his sight
		FRENZY_SCALE = 1.25, -- in a frenzy he sees this much farther
	}),
	-- Short-term cognition: attention is stable, but hearing never reveals
	-- unseen players' true coordinates. Tuning after a real multiplayer test.
	COGNITION = table.freeze({
		ATTENTION_SECONDS = 2.5, -- do not swivel instantly for every quiet tick
		SWITCH_RATIO = 1.2, -- stronger evidence can interrupt investigation
		STATIC_WINDOW = 12, -- classify repeated *anonymous* noises from the same spot
		STATIC_RADIUS = 6,
		STATIC_REPEATS = 3, -- first two decoy noises still matter
		STATIC_DISCOUNT = 0.36,
		STATIC_MIN_INTEREST = 26, -- after repetition, distant identical decoys can be ignored
		TRACK_SECONDS = 4.5, -- forget a player's sound bearing quickly
		TRACK_CLARITY = 0.42,
		PREDICTION_SECONDS = 1.0, -- avoid supernatural perfect intercepts
		SWITCH_HUNT_AFTER = 1.3, -- can turn to another loud player if first goes quiet
		SWITCH_HUNT_CLARITY = 0.65,
		HIDE_EVIDENCE_SECONDS = 7.0,
		HIDE_EVIDENCE_CLARITY = 0.55,
		HIDE_EVIDENCE_RADIUS = 12,
		SEARCH_REVISIT_SECONDS = 48,
		SEARCH_REVISIT_PENALTY = 22,
		SEARCH_DIRECTION_BONUS = 8, -- a recent moving source guides nearby search routes
		INSPECT_SECONDS = 1.6, -- deliberate pause at reachable studio workstation
		SEARCH_CELL = 6,
		MAX_VISITED = 48,
		GENERIC_HIDE_CHECK = 0.08, -- occasionally inspects plausible cover without certainty
		LUNGE_EVIDENCE_RADIUS = 8, -- no leap after a sound whose bearing is far off
	}),
})

-- Rounds
Config.MIN_PLAYERS = 1
Config.LOBBY_COUNTDOWN = if Config.DEBUG then 8 else 20 -- short while testing alone
Config.RESULTS_TIME = 12 -- long enough to read the results
-- There is no round timer: a round ends when the crew escapes or the monster catches everyone.

-- Pacing a chapter (20 to 25 minutes of play). Two shocks fire on progress; if the crew stalls,
-- each fires anyway after its fallback time. The longer the round runs, the closer the sound gets:
-- thicker fog, sharper hearing, and the director sends the monster toward the crew more often.
Config.PACING = table.freeze({
	SHOCK1_FALLBACK = 9 * 60, -- seconds into the round
	SHOCK2_FALLBACK = 16 * 60,
	SHOCK_MIN_GAP = 90, -- the second shock never follows the first sooner than this
	PRESSURE_START = 6 * 60, -- soft pressure starts building here...
	PRESSURE_FULL = 25 * 60, -- ...and is at its strongest here
	PRESSURE_HEARING = 0.5, -- at full pressure the monster hears this much farther (x1.5)
	PRESSURE_HINT = 0.6, -- at full pressure it drifts toward the crew this much sooner
	FOG_END_CALM = 210, -- long early sightlines let players read the room plan
	FOG_END_FULL = 110, -- pressure reduces visibility without obscuring navigation
})

-- The shocks.
Config.SHOCK = table.freeze({
	BLACKOUT = 7, -- main power trip; battery-backed route/EXIT pilots remain lit
	FRENZY = 20, -- seconds the monster frenzies after the second shock
	FOG_END = 75, -- brief shock haze; corridors remain readable at a distance
	FOG_SECONDS = 16, -- returns to the pressure-based grade promptly
	REPLAYED_SOUNDS = 6, -- the team's own sounds played back through the speakers
})

-- Last Call: the complete sound wakes every machine and the doors release for a while.
Config.LAST_CALL = table.freeze({
	DOORS_OPEN = 45, -- seconds before the locks re-engage
	FRENZY_HEARING = 3, -- during Last Call the monster hears this much farther
})

-- Holding a machine while the sound dubs onto the cassette (the last session, and later chapters).
-- Whoever holds it rides the faders: keep the level inside the safe band, or the sound spikes.
Config.DUB = table.freeze({
	SECONDS = 20,
	RANGE = 9, -- the holder must stay this close to the machine
	BAND = 0.18, -- half the width of the safe band (the level runs from 0 to 1)
	DRIFT = 0.45, -- how hard the level wanders, per second
	NUDGE = 0.9, -- how fast the holder can push it back, per second
	SPIKE_COOLDOWN = 2, -- seconds between noise spikes while the level is out of the band
	PULSE = 4, -- seconds between the recording's swells that pull the monster in (decoys work between them)
})

-- Chapter 1 of the studio: the last session.
Config.STUDIO1 = table.freeze({
	SAFE_COMBO = "031179", -- the date the engineer's wife drowned (3 November 1979), DDMMYY
	SAFE_LOCKOUT = 6, -- seconds the safe refuses input after three wrong tries
	ROAD_CASE_CLUTTER = 3, -- instruments to move off the road case
	DECOY_CARDS = 12, -- other cards in the archive's card index drawer
	PATCH_INPUTS = 8, -- desk inputs on the patch bay
	OPTIONAL_TAPES = 3,
})

-- Hiding under worktables (legacy lockers supported). Sound is partially muffled. When he is close your
-- breathing grows loud: hold it (Space) for a few seconds, or it hears you. Run out and you gasp.
Config.HIDE = table.freeze({
	MUFFLE = 0.35, -- legacy enclosed lockers
	DESK_MUFFLE = 0.72, -- open-front tables are only a little quieter, not soundproof
	BREATH_RANGE = 16, -- the monster this close makes your breathing loud
	BREATH_INTERVAL = 1.2, -- seconds between breaths it might hear
	HOLD_SECONDS = 6, -- how long you can hold your breath
	RECOVER_SECONDS = 8, -- from empty back to a full breath
	CHECK_CHANCE = 0.35, -- when searching nearby, the chance it checks a hiding spot it walks past
})

-- What you hold in your hands slows you: heavier things shorten and slow your sprint.
-- Weights run from 0 (nothing) to 1 (the heaviest thing you can carry).
Config.CARRY = table.freeze({
	SPRINT_LOSS = 6, -- sprint speed lost at weight 1
	STAMINA_DRAIN = 1.2, -- extra stamina drain at weight 1 (x2.2)
	THROW_SPEED = 48, -- how hard you throw, studs per second
	THROW_GRAVITY = 60,
})

-- Chapter medals, earned when a chapter is cleared: everyone escaped, nobody was ever caught
-- (revived players count as caught), and a fast run.
Config.MEDALS = table.freeze({
	FAST_SECONDS = 15 * 60,
	NAMES = table.freeze({
		survivors = "Everyone made it out",
		clean = "Nobody was caught",
		fast = "Fast run (under 15 minutes)",
	}),
})

-- Chapters in story order. `map` is the Config.MAPS id; a chapter unlocks when the one before it is
-- cleared (its evidence cassette carried out of the building).
Config.CHAPTERS = table.freeze({
	table.freeze({ id = "studio1", map = "studio", number = 1, name = "The Last Session" }),
})

-- Where the lobby floats, far above the map
Config.LOBBY_ORIGIN = Vector3.new(0, 400, 0)

-- Experience for what players do in a round (coins are a fifth of it). Rewards teamwork and
-- objectives, not only escaping, so a round where you got caught still moves you forward.
Config.REWARDS = table.freeze({
	ROUND = 20, -- for playing a round
	SPARES = 10,
	MACHINE_FIXED = 40,
	REEL_FOUND = 20,
	REEL_LOADED = 30,
	PATCHED = 40,
	LAST_SESSION = 60, -- holding the desk through the dub
	CASSETTE_OUT = 80, -- carrying the evidence out
	TAPE_DELIVERED = 30, -- an optional tape through the mail slot
	DECOY = 15, -- a tape recorder playing back
	ESCAPE = 100,
	REVIVE = 30, -- bringing a teammate back
	PING = 5, -- an echo marking the monster for the living
})
-- The free reward track (a battle pass nobody has to buy): reaching a level unlocks its reward.
-- A level lost to a revive relocks its rewards until it's reached again.
Config.TRACK = table.freeze({
	{ level = 2, kind = "boost", value = 0.05, id = "", name = "+5% XP" },
	{ level = 3, kind = "skin", value = 0, id = "cold", name = "Cold white flashlight" },
	{ level = 4, kind = "boost", value = 0.05, id = "", name = "+5% XP" },
	{ level = 5, kind = "skin", value = 0, id = "sodium", name = "Sodium amber flashlight" },
	{ level = 7, kind = "boost", value = 0.1, id = "", name = "+10% XP" },
	{ level = 8, kind = "skin", value = 0, id = "darkroom", name = "Darkroom red flashlight" },
	{ level = 10, kind = "boost", value = 0.1, id = "", name = "+10% XP" },
	{ level = 12, kind = "skin", value = 0, id = "ultraviolet", name = "Ultraviolet flashlight" },
	{ level = 15, kind = "skin", value = 0, id = "tape", name = "Old tape green flashlight" },
})

-- Flashlight looks (cosmetic only: the beam's colour, seen by everyone).
Config.FLASHLIGHT_SKINS = table.freeze({
	warm = { name = "Warm", color = Color3.fromRGB(255, 244, 222) },
	cold = { name = "Cold white", color = Color3.fromRGB(225, 236, 255) },
	sodium = { name = "Sodium amber", color = Color3.fromRGB(255, 196, 120) },
	darkroom = { name = "Darkroom red", color = Color3.fromRGB(255, 120, 110) },
	ultraviolet = { name = "Ultraviolet", color = Color3.fromRGB(190, 160, 255) },
	tape = { name = "Old tape green", color = Color3.fromRGB(190, 255, 190) },
})
Config.FLASHLIGHT_SKIN_ORDER =
	table.freeze({ "warm", "cold", "sodium", "darkroom", "ultraviolet", "tape" })

-- Coming back after being caught: once per round, while teammates are still inside. When the
-- monster catches you it rips your filter headset off: you become an echo and your body stays
-- where it fell, entranced and humming. You put up the price (a level, normally; Robux is possible
-- but priced as a rare exception), then a teammate has to reach your headset and hold E to put it
-- back on you while it re-syncs with loud static. If nobody comes before the round ends, the
-- price is refunded.
Config.REVIVE = table.freeze({
	HOLD_SECONDS = 4,
	NOISE = 40, -- the re-syncing static, every second of the hold
	PRODUCT_ID = 0, -- the Developer Product id from the Creator Dashboard; 0 hides the Robux option
})

-- Echoes: caught players float anywhere in the building. They sense the monster through walls and
-- can ping it for the living, and whisper short lines to living players nearby (the monster
-- sometimes hears a whisper). Whispers fade if used too often, so they can't be used to troll.
Config.ECHO = table.freeze({
	SPEED = 16, -- floating speed
	SEND_INTERVAL = 0.25, -- how often an echo's position reaches the server
	PING_COOLDOWN = 20,
	PING_SECONDS = 6, -- how long the living see the mark
	WHISPER_RANGE = 30, -- living players this close hear a whisper
	WHISPER_COOLDOWN = 4,
	WHISPER_WINDOW = 30, -- at most WHISPER_MAX whispers in this many seconds, then they fade out
	WHISPER_MAX = 4,
	WHISPER_HEARD_CHANCE = 0.25, -- chance the monster catches a whisper
	HUM_INTERVAL = 8, -- seconds between an entranced body's hums
	WHISPERS = table.freeze({ "It's close.", "Hide. Now.", "This way.", "It's gone." }),
})

Config.READY_COUNTDOWN = 3 -- when everyone in the lobby is ready, the round starts this soon

-- The experience's places (ids from the Creator Dashboard > your experience > Places). While they
-- are 0, or in Studio, nothing teleports: the match place plays on its own as before.
Config.PLACES = table.freeze({
	HUB = 0, -- the start place, where players gather and make lobbies
	MATCH = 0, -- the place rounds are played in (reserved servers)
})

-- The maps players can pick. `id` is what MapBuilder/ServerStorage.Maps use.
Config.MAPS = table.freeze({
	table.freeze({ id = "studio", name = "Recording studio", monster = "The Engineer" }),
})

-- Hub lobbies.
Config.LOBBY = table.freeze({
	MAX_PLAYERS = 4,
	LIST_INTERVAL = 2, -- how often each player's lobby list is refreshed
	PUBLISH_INTERVAL = 10, -- how often a hub tells other hubs about its lobbies (for friends)
	EXPIRY = 35, -- a published lobby disappears this long after its hub stops refreshing it
})

-- After a round in a match server.
Config.REPLAY = table.freeze({
	VOTE_TIME = 15, -- seconds to answer "play again?" and vote; no answer means back to the hub
})

-- Feature switches: turn one off if it misbehaves in a playtest, without losing the rest.
Config.FEATURES = table.freeze({
	WALKIE = true,
	TAPE = true,
	MIMICRY = true,
	SPECTATE = true,
	FEEDBACK = true,
	REPLAY = true, -- "play again?" and the map vote after each round in a match server
})

-- Walkie-talkie: hold V to talk through every other walkie; 1 to 4 send quick callouts.
-- Every other walkie that's switched on crackles at its owner while someone transmits.
Config.WALKIE = table.freeze({
	CRACKLE_INTERVAL = 0.6, -- seconds between crackle noises while someone talks
	MAX_TALK_SECONDS = 12, -- a held talk button lets go by itself after this
	CALLOUT_COOLDOWN = 2.5,
	CALLOUTS = table.freeze({ "It's here!", "Need help!", "Found a reel.", "Going quiet." }),
})

-- Tape recorder: record the noises around you, set it down, and it plays them back later as a lure.
Config.TAPE = table.freeze({
	RECORD_SECONDS = 5,
	RECORD_RADIUS = 14, -- noises this close to you end up on the tape
	MAX_EVENTS = 30,
	PLAY_DELAY = 6, -- seconds after setting it down before it plays
})

-- The Engineer's mimicry: now and then it replays a player sound it heard, near itself, to lure.
Config.MIMIC = table.freeze({
	MIN_INTERVAL = 40,
	MAX_INTERVAL = 75,
	MEMORY = 8, -- how many heard sounds it remembers
	MIN_DISTANCE = 10, -- how far from itself it throws the sound
	MAX_DISTANCE = 28,
	PLAYER_RANGE = 55, -- only when a player is close enough to hear it
	AMBUSH_TIME = 7, -- then it stands still and listens for whoever comes
})

return table.freeze(Config)
