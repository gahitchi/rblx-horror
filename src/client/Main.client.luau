--!strict
-- Client entry point. Each controller starts in its own thread and its own error guard,
-- so one that fails or waits (voice, for example) never stops the others.

local DangerEffect = require(script.Parent.DangerEffect)
local FlashlightController = require(script.Parent.FlashlightController)
local Hud = require(script.Parent.Hud)
local MovementController = require(script.Parent.MovementController)
local VoiceController = require(script.Parent.VoiceController)

local controllers: { [string]: { start: () -> () } } = {
	MovementController = MovementController,
	FlashlightController = FlashlightController,
	VoiceController = VoiceController,
	Hud = Hud,
	DangerEffect = DangerEffect,
}

for name, controller in controllers do
	task.spawn(function()
		xpcall(controller.start, function(message: any)
			warn(
				string.format("[Dead Air] %s failed:\n%s", name, debug.traceback(tostring(message)))
			)
		end)
	end)
end
