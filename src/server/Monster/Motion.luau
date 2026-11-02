--!strict
-- Small procedural pose layer; visual-only. No gameplay decisions are made here.
-- The five Motor6D joints are native and will accept authored animations later.
-- Headphones are welded to the Head part and follow it during listening.
local Motion = {}

export type Controller = {
	update: (state: string, focus: Vector3?, inspecting: boolean, now: number, dt: number) -> (),
	destroy: () -> (),
}

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function Motion.new(model: Model, root: BasePart): Controller
	local joints: { [string]: Motor6D } = {}
	local rests: { [string]: CFrame } = {}
	for _, id in { "Head", "LeftArm", "RightArm", "LeftLeg", "RightLeg" } do
		local joint = root:FindFirstChild(id .. "Joint")
		if joint and joint:IsA("Motor6D") then
			joints[id] = joint
			rests[id] = joint.C0
		end
	end
	local time = 0
	local lastIntent = ""
	local destroyed = false

	local visual = {} :: Controller

	function visual.update(
		state: string,
		focus: Vector3?,
		inspecting: boolean,
		now: number,
		dt: number
	)
		if destroyed or not model.Parent or not root.Parent then
			return
		end
		time += math.max(0, math.min(dt, 0.2))
		local speed = flat(root.AssemblyLinearVelocity).Magnitude
		local stride = math.clamp(speed / 12, 0, 1)
		local swing = math.sin(time * (2.2 + speed * 0.72)) * stride
		local urgent = state == "Hunt" or state == "Investigate"
		local listen = state == "Listen"
		local inspect = state == "Search" and inspecting
		local intent = if state == "Hunt"
			then "Pursuit"
			elseif state == "Retreat" then "Withdraw"
			elseif inspect then "Inspect"
			elseif listen then "Listening"
			elseif state == "Search" then "Searching"
			elseif state == "Investigate" then "Approach"
			elseif state == "Roam" then "Patrol"
			else "Still"
		if intent ~= lastIntent then
			model:SetAttribute("Intent", intent)
			lastIntent = intent
		end
		local headYaw = 0
		if focus then
			local localDir = root.CFrame:VectorToObjectSpace(flat(focus - root.Position))
			if localDir.Magnitude > 0.1 then
				headYaw = math.clamp(math.atan2(-localDir.X, -localDir.Z), -0.8, 0.8)
			end
		end
		local roll = if listen then math.rad(12) elseif inspect then math.rad(-9) else 0
		local pitch = if listen
			then math.rad(-9)
			elseif inspect then math.rad(17)
			elseif urgent then math.rad(-6)
			else math.rad(1.6) * math.sin(time * 0.9)
		local head = CFrame.Angles(pitch, headYaw * (if listen or inspect then 1 else 0.25), roll)
		local reach = if inspect then math.rad(-28) elseif listen then math.rad(-9) else 0
		local left = CFrame.Angles(reach + swing * 0.18, 0, math.rad(-4))
		local right = CFrame.Angles(reach - swing * 0.18, 0, math.rad(4))
		if state == "Hunt" then
			left = CFrame.Angles(math.rad(-23) + swing * 0.29, 0, 0)
			right = CFrame.Angles(math.rad(-23) - swing * 0.29, 0, 0)
		end
		local poses: { [string]: CFrame } = {
			Head = head,
			LeftArm = left,
			RightArm = right,
			LeftLeg = CFrame.Angles(swing * 0.16, 0, 0),
			RightLeg = CFrame.Angles(-swing * 0.16, 0, 0),
		}
		local blend = math.clamp(dt * 8, 0, 1)
		for id, joint in joints do
			local rest = rests[id]
			local delta = poses[id]
			if rest and delta then
				joint.C0 = joint.C0:Lerp(rest * delta, blend)
			end
		end
	end

	function visual.destroy()
		destroyed = true
		for id, joint in joints do
			if joint.Parent then
				joint.C0 = rests[id]
			end
		end
		table.clear(joints)
	end
	return visual
end

return Motion
