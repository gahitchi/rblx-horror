-- Dead Air / Blackline LD-03 -- non-destructive server-side Studio qualification.
-- Run this entire file in Roblox Studio's SERVER Command Bar DURING PLAY.
-- It never teleports players, moves doors, changes audio state or modifies the
-- authored map. It performs native Roblox pathfinding against actual geometry.
-- Results are diagnostic evidence; they do not replace human chase testing.
local ServerScriptService=game:GetService("ServerScriptService")
local Workspace=game:GetService("Workspace")
local PathfindingService=game:GetService("PathfindingService")
local RunService=game:GetService("RunService")
assert(RunService:IsRunning(),"Start Play (F5) and use the Server Command Bar")
local server=assert(ServerScriptService:FindFirstChild("Server"),"Rojo Server not found")
local spec=require(assert(server:FindFirstChild("Maps")):WaitForChild("BlacklineLayout")).make()
local map=assert(Workspace:FindFirstChild("Map"),"No active Workspace.Map")
assert(map:GetAttribute("MapId")=="studio",
    "Choose the studio / Blackline map for this qualification")
local areas=assert(map:FindFirstChild("Areas"))
local doors=assert(map:FindFirstChild("Doors"))
local booths=assert(map:FindFirstChild("Booths"))
local objectives=assert(map:FindFirstChild("Objectives"))
local sound=require(server:WaitForChild("NoiseService"))
local center={}
local bounds={}
for _,room in spec.rooms do
    local folder=assert(areas:FindFirstChild(room.name),"Missing Area: "..room.name)
    local region=assert(folder:FindFirstChild("Bounds"),"Missing Bounds: "..room.name)
    center[room.name]=Vector3.new((room.x1+room.x2)/2,3,(room.z1+room.z2)/2)
    bounds[room.name]=region
    assert(region.CanQuery==false,"Area helper should not obstruct audio")
end
local errors={}
local warnings={}
local function fault(category,message)
    local entry=category..": "..message
    table.insert(errors,entry)
    warn("[LD03] FAIL "..entry)
end
local function note(category,message)
    local entry=category..": "..message
    table.insert(warnings,entry)
    warn("[LD03] REVIEW "..entry)
end

local counts={edges=0,paths=0,failedPaths=0,areas=#spec.rooms,doors=0,windows=0}
for _,door in doors:GetChildren() do
    if door:IsA("BasePart") then
        counts.doors+=1
        local modifier=door:FindFirstChildOfClass("PathfindingModifier")
        if not modifier or modifier.PassThrough~=true then
            fault("Door",door.Name.." has no PassThrough PathfindingModifier")
        end
        if not door.CanQuery then
            fault("Door",door.Name.." must occlude sound when shut")
        end
        if door.Size.X<5.5 or door.Size.Y<8.5 then
            fault("Door",door.Name.." under configured monster clearance")
        end
    end
end
for _,part in map:GetDescendants() do
    if part:IsA("BasePart") and part.Name=="AcousticObservationGlass" then
        counts.windows+=1
        if part.CanQuery~=true or part.CanCollide~=true then
            fault("Glass","Observation pane missing acoustic/physical blocking")
        end
    end
end
if counts.windows~=#(spec.windows or {}) then
    fault("Glass","Expected "..#(spec.windows or {}).." windows, got "..counts.windows)
end
for _,name in spec.booths do
    local zone=assert(booths:FindFirstChild("Isolation_"..name),
        "Missing booth zone "..name)
    local doorName=zone:GetAttribute("Door")
    local door=if type(doorName)=="string" then doors:FindFirstChild(doorName) else nil
    if not door or not door:IsA("BasePart") or door:GetAttribute("Kind")~="booth" then
        fault("Booth",name.." missing its sound-seal door")
    elseif door:GetAttribute("Open")~=true then
        -- A simulated noise event has no side effects on the Engineer.
        -- It models a sound that was emitted when the booth door was sealed.
        local event={
            position=center[name], loudness=180, kind="LD03",
            time=os.clock(), zone=zone.Name,
        }
        local inside=sound.effectiveLoudness(event,center[name])
        local outside=sound.effectiveLoudness(event,center[spec.spawn])
        if inside<=0 or outside~=0 then
            fault("Booth",name.." failed sealed one-way acoustic containment")
        end
    else
        note("Booth",name.." open during test; closed-state acoustic gate not run")
    end
end

-- Async to keep the Studio command prompt responsive during ComputeAsync calls.
task.spawn(function()
    local options={AgentRadius=1.5,AgentHeight=8.5,
        AgentCanJump=false,AgentCanClimb=false,WaypointSpacing=4}
    local function testPath(a,b,context)
        counts.paths+=1
        local path=PathfindingService:CreatePath(options)
        local ok,err=pcall(function()
            path:ComputeAsync(center[a],center[b])
        end)
        if not ok or path.Status~=Enum.PathStatus.Success then
            counts.failedPaths+=1
            fault(context,a.." -> "..b..": "..
                (if ok then tostring(path.Status) else tostring(err)))
        end
        path:Destroy()
    end
    for _,link in spec.links do
        counts.edges+=1
        testPath(link[1] :: string,link[2] :: string,"Portal path")
    end
    for _,room in spec.rooms do
        if room.name~=spec.spawn then
            testPath(room.name,spec.spawn,"Return to Reception")
        end
    end
    for _,destination in {spec.generator,spec.fuseBox,spec.tape} do
        testPath(spec.spawn,destination,"Objective approach")
    end
    -- Functional objective parts must survive the map contract intact.
    for _,target in {"Generator","FuseBox","TapeDeck","ExitZone"} do
        if not objectives:FindFirstChild(target) then
            fault("Objective","Missing "..target)
        end
    end
    print(string.format("[LD03] Blackline: %d Areas, %d edges, %d doors, %d windows",
        counts.areas,counts.edges,counts.doors,counts.windows))
    print(string.format("[LD03] Path probes: %d attempted, %d failed",
        counts.paths,counts.failedPaths))
    print(string.format("[LD03] RESULTS: %d failures; %d review notes",
        #errors,#warnings))
    if #errors==0 then
        print("[LD03] STATIC + NATIVE PATH PROBES PASS; still test actual movement, hearing and pursuits")
    else
        warn("[LD03] Some routes failed; send the entire Output log for corrections")
    end
end)
