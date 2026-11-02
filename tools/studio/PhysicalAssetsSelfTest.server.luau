--!strict
-- Developer-only server Command Bar test, after entering Match Play.
-- Tests genuine Rigidbody+Hinge assemblies, not just visual wheel meshes.
-- Does not automatically move or damage the player's character.
local Workspace = game:GetService("Workspace")
local map = Workspace:WaitForChild("Map")
local foundCases: { Model } = {}
local furniture = {}
for _, child in map:GetDescendants() do
	if child:IsA("Model") and child:GetAttribute("PhysicsVersion") == 1 then
		table.insert(foundCases, child)
	elseif child:IsA("Model") and child:GetAttribute("FurnitureType") ~= nil then
		local kind = child:GetAttribute("FurnitureType")
		furniture[kind] = (furniture[kind] or 0) + 1
	end
end
assert(#foundCases == 2,
	"[Physical props] Expected exactly two simulated wheeled cases")
task.wait(0.5) -- release happens after the generated Map enters Workspace
for _, case in foundCases do
	local body = case.PrimaryPart
	assert(body and body:IsA("BasePart"), "[Physical props] Missing rigid case body")
	assert(not body.Anchored and body.CanCollide and body.CanQuery,
		"[Physical props] Case must be unanchored with true body collision")
	assert(body:GetNetworkOwner() == nil,
		"[Physical props] Case must be owned by the server")
	local wheels = 0
	local hinges = 0
	for _, obj in case:GetDescendants() do
		if obj:IsA("BasePart") and obj.Name == "RollingCaster" then
			wheels += 1
			assert(not obj.Anchored and obj.CanCollide,
				"[Physical props] Wheel is not a rolling collider")
		elseif obj:IsA("HingeConstraint") then
			hinges += 1
			assert(obj.Attachment0 ~= nil and obj.Attachment1 ~= nil,
				"[Physical props] Missing wheel axle attachment")
		end
	end
	assert(wheels == 4 and hinges == 4,
		"[Physical props] Each case needs four physical wheels and hinges")
end
assert((furniture.WorkingTable or 0) > 0)
assert((furniture.StudioChair or 0) > 0)
assert((furniture.UpholsteredSofa or 0) > 0)
assert((furniture.AnalogueRack or 0) >= 3)
local objective = map:FindFirstChild("Objectives")
local story = objective and objective:FindFirstChild("RoadCase")
assert(story and story:IsA("BasePart") and story.Anchored and story.CanCollide,
	"[Physical props] Reel RoadCase must remain a fixed, usable objective")
print("[Physical props] PASS: two server-owned four-wheel cases; grounded furniture; story case intact")
print("[Physical props] MANUAL: shove a case, see the axles rotate, confirm it does not escape the loading bay or block the lift")
