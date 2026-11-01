--!strict
-- Client entry point. Each controller starts in its own thread and its own error guard,
-- so one that fails or waits (voice, for example) never stops the others.

local StarterGui = game:GetService("StarterGui")

local DangerEffect = require(script.Parent.DangerEffect)
local EngineerMotion = require(script.Parent.EngineerMotion)
local FlashlightController = require(script.Parent.FlashlightController)
local Hud = require(script.Parent.Hud)
local ItemController = require(script.Parent.ItemController)
local LobbyUi = require(script.Parent.LobbyUi)
local MovementController = require(script.Parent.MovementController)
local ReplayUi = require(script.Parent.ReplayUi)
local SpectateController = require(script.Parent.SpectateController)
local VoiceController = require(script.Parent.VoiceController)

-- No Roblox backpack bar: items are on fixed keys, and 1-4 are walkie callouts.
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local controllers: { [string]: { start: () -> () } } = {
	MovementController = MovementController,
	FlashlightController = FlashlightController,
	VoiceController = VoiceController,
	Hud = Hud,
	DangerEffect = DangerEffect,
	EngineerMotion = EngineerMotion,
	ItemController = ItemController,
	SpectateController = SpectateController,
	LobbyUi = LobbyUi,
	ReplayUi = ReplayUi,
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
