--!strict
-- Developer-only Match-place server Command Bar preflight.
-- Run during a private Play session after Map generation. Does NOT simulate
-- an E press, humanoid posture, AI navigation or a successful catch.
local map = workspace:WaitForChild("Map")
local folder = map:FindFirstChild("HidingSpots")
assert(folder, "[Desk test] map has no hiding spots")
local props = map:FindFirstChild("Props")
assert(props, "[Desk test] map has no props")
local count = 0
for _, spot in folder:GetChildren() do
	if not spot:IsA("BasePart") then continue end
	count += 1
	assert(spot:GetAttribute("Kind") == "underdesk",
		"[Desk test] expected under-desk cover: " .. spot.Name)
	assert(spot.Transparency == 1 and not spot.CanCollide and not spot.CanQuery,
		"[Desk test] hiding marker must not be visible or block sight: " .. spot.Name)
	local prompt = spot:FindFirstChildOfClass("ProximityPrompt")
	assert(prompt and prompt.ActionText == "Get under" and prompt.ObjectText == "Desk",
		"[Desk test] under-desk prompt not installed: " .. spot.Name)
	local coverName = spot:GetAttribute("CoverName")
	assert(type(coverName) == "string" and #coverName > 0,
		"[Desk test] cover lacks an authored furniture reference")
	local expected = (coverName :: string) .. "Top"
	if coverName == "EditCounter" then
		local found = props:FindFirstChild("EditCounterTop", true)
		local screen = props:FindFirstChild("EditCounterBackPanel", true)
		assert(found and screen and screen:IsA("BasePart") and screen.CanQuery,
			"[Desk test] Control B desk must have real rear panel and tabletop")
	else
		local found = props:FindFirstChild(expected, true)
		assert(found and found:IsA("BasePart") and found.CanCollide and found.CanQuery,
			"[Desk test] desk is missing tangible tabletop " .. expected)
		local back = props:FindFirstChild((coverName :: string) .. "BackScreen", true)
		assert(back and back:IsA("BasePart") and back.CanQuery,
			"[Desk test] desk has no opaque back panel: " .. coverName)
	end
end
assert(count == 6, "[Desk test] expected six purposeful desk hiding spots, got " .. count)
print("[Desk test] PASS: six invisible markers, real cover and Get under prompts")
print("[Desk test] MANUAL: E to enter/leave, breath and gaze, witnessed-entry Engineer inspection, escape before inspection, and successful catch")
