-- Blackline VF03: read-only Studio acceptance for the mastering and gallery art.
-- Run in SERVER Command Bar during F5 Play; never moves players, doors, or props.
local Workspace=game:GetService("Workspace")
local RunService=game:GetService("RunService")
assert(RunService:IsRunning(),"Run F5 Play and use the SERVER Command Bar")
local map=assert(Workspace:FindFirstChild("Map"),"Workspace.Map missing")
assert(map:GetAttribute("MapId")=="studio","Blackline/studio map required")
local art=assert(map:FindFirstChild("EnvironmentArt"),"EnvironmentArt missing")
local structure=assert(map:FindFirstChild("Structure"),"Structure missing")
local errors=0
local function fail(msg)
    errors+=1
    warn("[VF03] FAIL "..msg)
end
local function allParts(model)
    local parts={}
    for _,d in model:GetDescendants() do
        if d:IsA("BasePart") then
            table.insert(parts,d)
            if d.CanCollide or d.CanQuery or d.CanTouch then
                fail(model.Name.." visual blocks physics/sound: "..d:GetFullName())
            end
        end
    end
    return parts
end
local master=art:FindFirstChild("MasteringReferenceWall")
local transfer=art:FindFirstChild("MasteringTransferStation")
local gallery=art:FindFirstChild("ViewingGalleryObservation")
if not master or not master:IsA("Model") then fail("missing MasteringReferenceWall") end
if not gallery or not gallery:IsA("Model") then fail("missing ViewingGalleryObservation") end
if not transfer or not transfer:IsA("Model") then
    fail("missing MasteringTransferStation")
else
    local parts=allParts(transfer)
    local tier=transfer:GetAttribute("VisualTier")
    if tier~="NativeFallback" and tier~="ImportedPBR" then
        fail("invalid mastering transfer VisualTier")
    end
    if #parts==0 then fail("mastering transfer scene is empty") end
    local cf,size=transfer:GetBoundingBox()
    -- Valid meshes may retain a model pivot at the original source origin,
    -- but the actual drawn parts must stay by the deliberate stand.
    if math.abs(cf.Position.X-(-59))>2 or
        math.abs(cf.Position.Z-(-180))>2.5 or
        size.X>7.5 or size.Y>5.5 or size.Z>6.0 then
        fail("transfer geometry has shifted or expanded: "..tostring(cf.Position)..
            " / "..tostring(size))
    end
    if tier=="NativeFallback" then
        local reels=0
        for _,part in parts do
            if part.Name=="TransportFlange" then reels+=1 end
        end
        if reels~=2 then fail("mastering native deck must have two reel flanges") end
    else
        local imported=transfer:FindFirstChild("BlacklineTransferDeck",true)
        if not imported or not imported:IsA("PVInstance") then
            fail("missing imported BlacklineTransferDeck root")
        else
            if imported:GetPivot().LookVector:Dot(Vector3.zAxis)<.94 then
                fail("mastering transfer is not facing toward the occupied room")
            end
        end
    end
    print(("[VF04] Master transfer: %s, %d parts, center=%s, size=%s"):format(
        tostring(tier),#parts,tostring(cf.Position),tostring(size)))
end

if master and master:IsA("Model") then
    local parts=allParts(master)
    local tier=master:GetAttribute("VisualTier")
    if tier~="NativeFallback" and tier~="ImportedPBR" then
        fail("missing reference-wall VisualTier")
    end
    if #parts==0 then fail("empty mastering reference wall") end
    if tier=="NativeFallback" then
        local n=0
        for _,p in parts do
            if p.Name=="ReferenceDriver" then n+=1 end
        end
        if n~=2 then fail("native reference wall needs exactly two drivers") end
    else
        local imported=master:FindFirstChild("BlacklineMasterReference",true)
        if not imported then fail("imported mastering prefab missing") end
        if imported and imported:IsA("PVInstance") then
            local pivot=imported:GetPivot().Position
            if math.abs(pivot.X-(-36.5))>1.0 or math.abs(pivot.Z-(-190.84))>1.0 then
                fail("mastering GLB pivot moved; inspect importer recentering")
            end
        end
    end
    local boundsCF,boundsSize=master:GetBoundingBox()
    print(("[VF03] Mastering reference: %s, %d parts, center=%s, size=%s"):format(
        tostring(tier),#parts,tostring(boundsCF.Position),tostring(boundsSize)))
end
if gallery and gallery:IsA("Model") then
    local parts=allParts(gallery)
    local x=gallery:GetAttribute("WindowCenterX")
    if type(x)~="number" or math.abs(x-23.5)>.05 then
        fail("observation ornament is not registered on Kit's actual window")
    end
    if gallery:GetAttribute("AcousticPaneOwnedBy")~="Kit" then
        fail("visual art must not replace the physical acoustic pane")
    end
    local plenum=gallery:FindFirstChild("AcousticReturnPlenum",true)
    local talkback=gallery:FindFirstChild("TalkbackNotice",true)
    if not plenum or not talkback then fail("missing gallery signature architecture") end
    print(("[VF03] Gallery: %d visual-only parts, acoustic window x=%s"):format(
        #parts,tostring(x)))
end
local windowCount=0
for _,p in structure:GetDescendants() do
    if p:IsA("BasePart") and p.Name=="AcousticObservationGlass"
        and math.abs(p.Position.Z-(-128))<.25 and
        math.abs(p.Position.X-23.5)<.25 then
        windowCount+=1
        if not p.CanQuery or not p.CanCollide then
            fail("true observation pane no longer occludes sound/players")
        end
        print(("[VF03] Real gallery pane: center=%s, size=%s"):format(
            tostring(p.Position),tostring(p.Size)))
    end
end
if windowCount~=1 then
    fail("expected exactly one true 9-stud gallery/live-floor window")
end
print(("[VF03] %d errors. Remaining gates: flashlight-first sightlines, native "..
    "door clearance, mesh PBR, 1080p frame time and memory"):format(errors))
