--!strict
-- Canonical production map dispatcher. No legacy geometry is constructed here.
-- Each map is generated from scratch by Maps/Kit + the authored Maps/Layouts definition,
-- then read by MapContract exactly like a Studio-made Workspace.Map.
local Kit=require(script.Parent.Maps.Kit)
local Layouts=require(script.Parent.Maps.Layouts)
local Lobby=require(script.Parent.Maps.Lobby)

local MapBuilder={}
local MapContract=require(script.Parent.MapContract)
export type Layout=MapContract.Layout
export type Area=MapContract.Area
export type Zone=MapContract.Zone
-- Used by art and service modules; keep the public type identical to existing callers.
export type LoadedLayout=MapContract.Layout
MapBuilder.FUSE_COLOR=Color3.fromRGB(230,190,60)

function MapBuilder.buildLobby(): CFrame
    return Lobby.build()
end

function MapBuilder.build(mapId: string?): Model
    local id=mapId or "studio"
    if id=="studio" then return Kit.build(Layouts.studio()) end
    if id=="radio" then return Kit.build(Layouts.radio()) end
    if id=="foundry" then return Kit.build(Layouts.foundry()) end
    warn("[Map] Unknown map id "..id.."; using studio")
    return Kit.build(Layouts.studio())
end

return MapBuilder
