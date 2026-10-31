--!strict
-- Every tuning number in one place. Distances are in studs, times in seconds.

local Config = {}

Config.GAME_NAME = "Dead Air"
Config.VERSION = "0.1.1"
Config.DEBUG = true -- extra Output logging while in development

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
})
Config.FOOTSTEP_INTERVAL = 0.4 -- how often movement noise is sampled per player
Config.WALL_DAMPING = 0.5 -- each wall between the noise and the listener halves its reach
Config.MAX_WALL_HITS = 3
Config.VOICE_THRESHOLD = 0.04 -- quieter than this counts as silence
Config.VOICE_SEND_INTERVAL = 0.25

-- The monster
-- It starts every chase at a player's walking pace and speeds up the longer the chase lasts, so a
-- sprint buys distance but not escape: running out of breath in its hearing range is fatal. The way
-- out is to break away and go quiet. Up close it lunges, with a warning (sound, glow, vignette).
Config.MONSTER = table.freeze({
	WANDER_SPEED = 8,
	INVESTIGATE_SPEED = Config.WALK_SPEED,
	CHASE_SPEED = Config.WALK_SPEED, -- at the start of a chase
	CHASE_MAX_SPEED = 19, -- still just under a sprint
	CHASE_RAMP_SECONDS = 8, -- from start to max speed
	LUNGE_RANGE = 14,
	LUNGE_WINDUP = 0.45, -- the warning before it leaps
	LUNGE_SPEED = 32,
	LUNGE_TIME = 0.6,
	LUNGE_COOLDOWN = 6,
	CATCH_DISTANCE = 4.5,
	CHASE_LOCK_DISTANCE = 55, -- hearing a player this close starts a chase
	CHASE_MEMORY = 3.5, -- seconds of silence before it loses a chase
	SEARCH_TIME = 10,
	SEARCH_RADIUS = 20,
	DOOR_OPEN_DISTANCE = 6,
	ARRIVAL_DELAY = 12, -- seconds after the round starts before it appears
	REPATH_INTERVAL = 0.5,
})

-- Rounds
Config.MIN_PLAYERS = 1
Config.LOBBY_COUNTDOWN = if Config.DEBUG then 8 else 20 -- short while testing alone
Config.ROUND_TIME = 1200
Config.RESULTS_TIME = 8
Config.RESPAWN_DELAY = 3

-- Objectives
Config.GENERATOR_PULLS = 3
Config.GENERATOR_HUM_INTERVAL = 6
Config.FUSES_NEEDED = 3
Config.TAPE_DURATION = 20
Config.ALARM_INTERVAL = 1.5

-- Where the lobby floats, far above the map
Config.LOBBY_ORIGIN = Vector3.new(0, 400, 0)

return table.freeze(Config)
