--!strict
-- Every tuning number in one place. Distances are in studs, times in seconds.

local Config = {}

Config.GAME_NAME = "Dead Air"
Config.VERSION = "0.6.0"
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
	FUSE = 50,
	GENERATOR_PULL = 140,
	GENERATOR_HUM = 55,
	ALARM = 400, -- the emergency tape on the speakers: everyone hears it
	VOICE_MAX = 60, -- shouting
	WALKIE_CRACKLE = 26, -- a teammate's transmission coming out of your walkie
	WALKIE_CLICK = 6, -- pressing talk, switching it on or off
	TAPE_PLACE = 8, -- setting the recorder down
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
})

-- Rounds
Config.MIN_PLAYERS = 1
Config.LOBBY_COUNTDOWN = if Config.DEBUG then 8 else 20 -- short while testing alone
Config.ROUND_TIME = 1200
Config.RESULTS_TIME = 12 -- long enough to read the results
Config.RESPAWN_DELAY = 3

-- Objectives
Config.GENERATOR_PULLS = 3
Config.GENERATOR_HUM_INTERVAL = 6
Config.FUSES_NEEDED = 3
Config.TAPE_DURATION = 20
Config.ALARM_INTERVAL = 1.5

-- Where the lobby floats, far above the map
Config.LOBBY_ORIGIN = Vector3.new(0, 400, 0)

-- Experience for what players do in a round (coins are a fifth of it). Rewards teamwork and
-- objectives, not only escaping, so a round where you got caught still moves you forward.
Config.REWARDS = table.freeze({
	ROUND = 20, -- for playing a round
	GENERATOR_PULL = 10,
	FUSE = 25,
	TAPE_DECK = 40, -- starting the emergency tape
	DECOY = 15, -- a tape recorder playing back
	ESCAPE = 100,
	REVIVE = 30, -- bringing a teammate back
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

-- Coming back after being caught: once per round, while teammates are still inside. You put up the
-- price (a level, normally; Robux is possible but priced as a rare exception), then a teammate has
-- to reach the walkie you dropped and hold E on it while it screeches back to life. If nobody
-- comes before the round ends, the price is refunded.
Config.REVIVE = table.freeze({
	HOLD_SECONDS = 4,
	NOISE = 40, -- the reconnecting static, every second of the hold

	PRODUCT_ID = 0, -- the Developer Product id from the Creator Dashboard; 0 hides the Robux option
	MIN_TIME_LEFT = 45, -- no revives in the last seconds of a round
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
	table.freeze({ id = "studio", name = "Blackline Recording Complex", monster = "The Engineer" }),
	table.freeze({ id = "radio", name = "Wavelength Broadcast Station", monster = "The Engineer" }),
	table.freeze({ id = "foundry", name = "Ashbell Industrial Foundry", monster = "The Engineer" }),
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
	CALLOUTS = table.freeze({ "It's here!", "Need help!", "Found a fuse.", "Going quiet." }),
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
