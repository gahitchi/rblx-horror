--!strict
-- Hub client entry point.

local HubUi = require(script.Parent.HubUi)

xpcall(HubUi.start, function(message: any)
	warn("[Dead Air] HubUi failed:\n" .. debug.traceback(tostring(message)))
end)
