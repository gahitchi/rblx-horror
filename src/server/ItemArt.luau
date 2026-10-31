--!strict
-- How the items look. Placeholder shapes for now; replace the insides of these functions freely.
-- What each one must return is written above it: the item scripts rely only on that.

local ItemArt = {}

local function piece(
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	parent: Instance?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Parent = parent
	return p
end

-- The walkie-talkie clipped to a player's belt, seen by the others.
-- Must return one Part (the scripts weld it to the character): non-solid, Massless, roughly palm
-- sized. Extra detail parts can be welded to it with WeldConstraints (also non-solid, Massless).
function ItemArt.makeWalkie(): Part
	local body = piece(
		"Walkie",
		Vector3.new(0.35, 0.7, 0.18),
		Color3.fromRGB(35, 35, 32),
		Enum.Material.SmoothPlastic
	)
	local antenna = piece(
		"Antenna",
		Vector3.new(0.06, 0.45, 0.06),
		Color3.fromRGB(20, 20, 20),
		Enum.Material.SmoothPlastic,
		body
	)
	antenna.CFrame = body.CFrame * CFrame.new(0.1, 0.55, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = antenna
	weld.Parent = antenna
	return body
end

-- A tape recorder set down on the floor as a decoy.
-- Must return one anchored Part whose bottom face rests at its position (the scripts place it on
-- the floor and add the pick-up prompt and a small light to it). Detail parts can be welded to it.
function ItemArt.makeTapeRecorder(): Part
	local body = piece(
		"TapeRecorder",
		Vector3.new(1.2, 0.5, 0.8),
		Color3.fromRGB(60, 56, 50),
		Enum.Material.SmoothPlastic
	)
	body.Anchored = true
	body.CanQuery = false
	return body
end

return ItemArt
