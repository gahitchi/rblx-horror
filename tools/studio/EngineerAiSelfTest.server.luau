--!strict
-- Developer-only deterministic decision tests; paste into the Roblox Studio
-- Server Command Bar while the Match place is running with Rojo synced.
-- This script is not deployed or imported into the live game.
local ServerScriptService = game:GetService("ServerScriptService")
local server = ServerScriptService:WaitForChild("Server")
local cognition = require(server:WaitForChild("Monster"):WaitForChild("EvidenceMemory"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local function stimulus(kind: string, position: Vector3, clarity: number, loud: boolean)
	return {
		kind = kind,
		source = nil,
		exact = position,
		estimate = position,
		clarity = clarity,
		distance = 24,
		loud = loud,
		time = 100,
	}
end

local checks = 0
local function expect(condition: boolean, message: string)
	checks += 1
	assert(condition, "[Engineer AI test " .. tostring(checks) .. "] " .. message)
end

local brain = cognition.new()
local center = Vector3.new(0, 3, 0)

-- A fresh noise is interesting; an equally weak new tick does not override
-- the current investigation during its attention hold.
local first = stimulus("throw", center, 0.65, false)
brain.observe(first, 100)
expect(brain.attend(first, 100, false), "fresh noise should gain attention")
local second = stimulus("throw", Vector3.new(1, 3, 0), 0.65, false)
brain.observe(second, 101)
expect(not brain.attend(second, 101, true), "equal weak noise should not interrupt")

-- Repeating an anonymous decoy in one spot reduces its novelty.
local third = stimulus("throw", Vector3.new(1, 3, 0), 0.65, false)
brain.observe(third, 102)
expect(not brain.attend(third, 102, true),
	"three similar anonymous sounds should lose interest")

-- Objectives do not become immune to distraction fatigue.
local alarm = stimulus("recording", center, 1, true)
brain.observe(alarm, 103)
expect(brain.attend(alarm, 103, true), "loud objective must interrupt")

-- Anonymous breath from a hiding spot is evidence, not an occupant ID.
brain.reset()
local breath = stimulus("breath", Vector3.new(6, 3, 0), 0.8, false)
brain.observe(breath, 120)
expect(brain.confidentNear(Vector3.new(7, 3, 0), 120.5),
	"nearby breath should prompt plausible locker inspection")
expect(not brain.confidentNear(Vector3.new(70, 3, 0), 120.5),
	"breathing must not reveal unrelated lockers")
expect(not brain.confidentNear(Vector3.new(7, 3, 0), 129),
	"breathing evidence must expire")

-- Search points should avoid recent duplicates, then eventually reset.
brain.reset()
local near = Vector3.new(5, 3, 0)
local far = Vector3.new(13, 3, 0)
local ordered = brain.sortSearch(center, { far, near }, 200)
expect(ordered[1] == near, "unvisited closer point should come first")
brain.visited(near, 201)
ordered = brain.sortSearch(center, { far, near }, 202)
expect(ordered[1] == far, "visited point should lose priority")
ordered = brain.sortSearch(center, { far, near }, 300)
expect(ordered[1] == near, "old visited penalty must decay")
brain.reset()
ordered = brain.sortSearch(center, { far, near }, 202)
expect(ordered[1] == near, "new round must have no visited memory")

expect(Config.MONSTER.COGNITION.TRACK_SECONDS < 8, "memory must remain short")
print(string.format("PASS: %d deterministic Engineer AI decision checks", checks))
