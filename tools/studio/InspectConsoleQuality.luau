-- Blackline console Q01: read-only first-person Studio acceptance probe.
-- Run during F5 Play in SERVER Command Bar. Prints factual geometry state;
-- does not change the model, camera, graphics, light or gameplay.
local Workspace=game:GetService("Workspace")
local RunService=game:GetService("RunService")
local ServerStorage=game:GetService("ServerStorage")
assert(RunService:IsRunning(),"Run Play (F5) and use SERVER Command Bar")
local map=assert(Workspace:FindFirstChild("Map"),"No active Workspace.Map")
assert(map:GetAttribute("MapId")=="studio","Blackline must be active")
local art=assert(map:FindFirstChild("EnvironmentArt"),"Missing EnvironmentArt")
local shelf=ServerStorage:FindFirstChild("ArtLibrary")
local source=shelf and shelf:FindFirstChild("BlacklineHeroConsole")
local errors=0
local function fail(msg)
    errors+=1
    warn("[Q01] FAIL "..msg)
end
local function inspect(root)
    local meshes=0
    local textures=0
    local solid=0
    local badSurface=0
    for _,part in root:GetDescendants() do
        if part:IsA("BasePart") then
            if part.CanCollide or part.CanQuery or part.CanTouch then
                solid+=1
            end
            if part:IsA("MeshPart") then
                meshes+=1
                if part.MeshId=="" then
                    badSurface+=1
                end
                if part:FindFirstChildOfClass("SurfaceAppearance") then
                    textures+=1
                end
            end
        end
    end
    if root:IsA("MeshPart") then
        meshes+=1
        if root:FindFirstChildOfClass("SurfaceAppearance") then textures+=1 end
    end
    return meshes,textures,solid,badSurface
end
if not source then
    warn("[Q01] PENDING: no imported BlacklineHeroConsole in ArtLibrary; "..
        "existing fallback stays. Import Q01 GLB and replace the OLD approved "..
        "ArtLibrary prefab only after backing up the prior copy.")
else
    local count=0
    for _,d in art:GetChildren() do
        if d.Name=="BlacklineHeroConsole" then
            count+=1
            local meshes,textures,solid,bad=inspect(d)
            if meshes<4 then fail("expected multiple source material mesh groups") end
            if textures<2 then fail("UV and PBR surfaces not visible on imported mesh") end
            if solid~=0 then fail("visual-only imported art has solid parts") end
            if bad~=0 then fail("source contains unresolved MeshId") end
            local bounds,size=d:GetBoundingBox()
            local pivot=d:GetPivot().Position
            local intended=Vector3.new(-110,0,-122.8)
            if (pivot-intended).Magnitude>1.0 then
                fail("source GLB lost its floor pivot/origin: "..tostring(pivot))
            end
            if size.X<5.7 or size.X>7.0 or size.Y<3.8 or size.Y>4.8
                or size.Z<2.8 or size.Z>4.1 then
                fail("source console has wrong scale: "..tostring(size))
            end
            print(("[Q01] Installed console: %d mesh groups; %d PBR surfaces;"..
                " source center %s, extents %s"):format(meshes,textures,
                tostring(bounds.Position),tostring(size)))
        end
    end
    if count~=1 then fail("expected exactly one imported Control A console; got "..count) end
end
-- The authored invisible collider is unchanged and must remain solid.
local foundCollider=false
for _,part in art:GetChildren() do
    if part:IsA("BasePart") and part.Name=="DeskPlinth"
        and part:GetAttribute("VisualPresentation")=="BlacklineHeroConsole" then
        foundCollider=true
        if not part.CanCollide or not part.CanQuery then
            fail("Control A desk collision proxy has regressed")
        end
        if part.Transparency~=1 then fail("Control A proxy is visible") end
    end
end
if source and not foundCollider then
    fail("no matching invisible Control A gameplay collider")
end
print("[Q01] Studio screenshot gates: +Z operator side (not north wall), "..
    "12 channel label orientation, bevel silhouette, glass/meter legibility "..
    "at 3/12/25 studs, no Z-fighting, imported dimensions, p50/p95 frame time")
print(("[Q01] Completed read-only checks with %d errors"):format(errors))
