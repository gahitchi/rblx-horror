#!/usr/bin/env python3
"""Dead Air two-place source preflight; no Roblox runtime or pip dependencies.

Run from any directory:
    python3 tools/integration/check_integration.py

Checks deterministic repository contracts only. It cannot verify Luau syntax,
Roblox pathfinding, assets, device FPS, DataStore, or published teleports.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
failures: list[str] = []
notes: list[str] = []


def fail(message: str) -> None:
    failures.append(message)


def canonical_luau(text: str) -> str:
    """One layout for Luau source, so these checks don't depend on line breaks.

    StyLua (the project's formatter) wraps long calls and tables over several lines and adds
    trailing commas. Collapse that back to the single-line shape the checks were written for:
    single spaces, no trailing comma before a closer, no space just inside parentheses.
    """
    text = re.sub(r"\s+", " ", text)
    text = re.sub(r",\s*([)}\]])", r" \1", text)
    text = re.sub(r"\(\s+", "(", text)
    text = re.sub(r"\s+\)", ")", text)
    text = re.sub(r"\s+\]", "]", text)
    return text


def require_text(path: str) -> str:
    file = ROOT / path
    if not file.is_file():
        fail(f"Missing file: {path}")
        return ""
    text = file.read_text(encoding="utf-8")
    return canonical_luau(text) if path.endswith(".luau") else text


def must_have(code: str, fragment: str, path: str) -> None:
    if fragment not in code:
        fail(f"{path}: missing expected integration token {fragment!r}")


def project(path: str, server_source: str, client_source: str) -> None:
    try:
        obj = json.loads(require_text(path))
        tree = obj["tree"]
        server = tree["ServerScriptService"]
        scripts = tree["StarterPlayer"]["StarterPlayerScripts"]
        paths = [
            next(iter(server.values()))["$path"],
            next(iter(scripts.values()))["$path"],
        ]
        if paths != [server_source, client_source]:
            fail(f"{path}: wrong place sources {paths!r}")
        for source in paths + ["src/shared"]:
            if not (ROOT / source).is_dir():
                fail(f"{path}: source directory is missing: {source}")
        shared = tree["ReplicatedStorage"]["Shared"]["$path"]
        if shared != "src/shared":
            fail(f"{path}: ReplicatedStorage.Shared does not point to src/shared")
    except (ValueError, KeyError, StopIteration, TypeError) as exc:
        fail(f"Invalid Rojo project {path}: {exc}")


def studio_layout(text: str) -> None:
    room_pattern = (
        r'\{\s*name = "(\w+)", role = "(\w+)", x1 = (-?\d+), '
        r'x2 = (-?\d+), z1 = (-?\d+), z2 = (-?\d+), height = (\d+)\s*\}'
    )
    rooms = {}
    for match in re.finditer(room_pattern, text):
        name, role, x1, x2, z1, z2, height = match.groups()
        if name in rooms:
            fail(f"Duplicate studio room: {name}")
        rooms[name] = (int(x1), int(x2), int(z1), int(z2), int(height))
    links = re.findall(r'\{\s*"(\w+)", "(\w+)", "(normal|open|booth|short)"\s*\}', text)
    if len(rooms) != 23 or len(links) != 30:
        fail(f"Studio floor graph changed: {len(rooms)} rooms and {len(links)} links")
    for important in ("ControlA", "LiveHall", "Reception", "EntryHall",
                      "PublicWC", "StaffWC", "JanitorCloset", "TapeArchive"):
        if important not in rooms:
            fail(f"Missing key studio room: {important}")

    for a, b, kind in links:
        if a not in rooms or b not in rooms:
            fail(f"Door connects unknown rooms: {a} / {b}")
            continue
        ax1, ax2, az1, az2, _ = rooms[a]
        bx1, bx2, bz1, bz2, _ = rooms[b]
        overlap = 0
        if ax2 == bx1 or bx2 == ax1:
            overlap = min(az2, bz2) - max(az1, bz1)
        elif az2 == bz1 or bz2 == az1:
            overlap = min(ax2, bx2) - max(ax1, bx1)
        if overlap < 12:
            fail(f"Too narrow or nonadjacent door: {a} <-> {b} ({overlap} studs)")
    if sum(kind == "booth" for _, _, kind in links) != 3:
        fail("Studio must have three isolation-booth connections")
    if sum(kind == "short" for _, _, kind in links) != 1:
        fail("Last Call should have one short-route shutter")

    # Ensure all rooms are navigable in the planned layout after the short
    # shutter closes (geometry and collision still need an in-game test).
    visited = {"ControlA"}
    while True:
        before = len(visited)
        for a, b, kind in links:
            if kind != "short" and (a in visited or b in visited):
                visited.add(a)
                visited.add(b)
        if len(visited) == before:
            break
    if set(rooms) != visited:
        fail(f"Last Call graph disconnected: {sorted(set(rooms) - visited)}")
    if "Reception" not in visited:
        fail("Control A cannot reach the front doors after Last Call")


def main() -> int:
    project("hub.project.json", "src/hub/server", "src/hub/client")
    project("default.project.json", "src/server", "src/client")

    hub = require_text("src/hub/server/Main.server.luau")
    lobby = require_text("src/hub/server/LobbyService.luau")
    builder = require_text("src/hub/server/HubBuilder.luau")
    vista = require_text("src/hub/server/HubVista.luau")
    dynamics = require_text("src/hub/server/HubDynamics.luau")
    cosmetics = require_text("src/hub/server/HubLoadout.luau")
    hub_ui = require_text("src/hub/client/HubUi.luau")
    hub_progress = require_text("src/hub/client/HubProgress.client.luau")
    match = require_text("src/server/Main.server.luau")
    replay = require_text("src/server/ReplayService.luau")
    studio = require_text("src/server/Maps/StudioGroundFloor.luau")
    desk_cover_test = require_text("tools/studio/DeskCoverSelfTest.server.luau")
    studio_production = require_text("src/server/Maps/StudioProductionDetail.luau")
    hero_console = require_text("src/server/Maps/StudioHeroConsole.luau")
    studio_lighting = require_text("src/server/Maps/StudioLightingRig.luau")
    studio_lighting_service = require_text("src/server/LightingService.luau")
    studio_rooms = require_text("src/server/Maps/StudioLayout.luau")
    world_evidence = require_text("src/server/Maps/StudioEvidenceDetail.luau")
    chapter_text = require_text("src/server/Chapters/Studio1Text.luau")
    chapter_ui = require_text("src/client/ChapterUi.luau")
    chapter = require_text("src/server/Chapters/Studio1.luau")
    tension = require_text("src/server/Chapters/StudioTension.luau")
    engineer = require_text("src/server/MonsterService.luau")
    engineer_model = require_text("src/server/Monster/EngineerModel.luau")
    engineer_motion = require_text("src/server/Monster/Motion.luau")
    engineer_environment = require_text("src/server/Monster/Environment.luau")
    engineer_navigator = require_text("src/server/Monster/Navigator.luau")
    engineer_mimicry = require_text("src/server/Monster/Mimicry.luau")
    engineer_scenarios = require_text("tools/studio/EngineerAiSelfTest.server.luau")
    engineer_memory = require_text("src/server/Monster/EvidenceMemory.luau")
    engineer_director = require_text("src/server/Monster/Director.luau")
    engineer_senses = require_text("src/server/Monster/Perception.luau")
    hiding = require_text("src/server/HideService.luau")
    notebook = require_text("src/client/NotebookUi.luau")
    client_main = require_text("src/client/Main.client.luau")
    config = require_text("src/shared/Config.luau")
    studio_layout(require_text("src/server/Maps/StudioLayout.luau"))

    for token in ("HubBuilder.build", "HubDynamics.init", "HubLoadout.init",
                  "LobbyService.init", "LobbyService.onDeparture", "HubSpawn"):
        must_have(hub, token, "hub/Main")
    for marker in ("VanDoors", "CrewBoard", "KitCrate", "Telescope",
                   "GatePath", "Foghorn"):
        must_have(builder, f'"{marker}"', "hub/HubBuilder")
        if marker in ("VanDoors", "CrewBoard", "KitCrate", "Telescope"):
            must_have(hub_ui, f'"{marker}"', "hub/HubUi")
    for component in ("GateBlocker", "BarrierArm", "Hinge"):
        must_have(builder, f'"{component}"', "hub/HubBuilder")
    for landmark in ("studio1", "studio2", "studio3", "RadioMast"):
        must_have(vista, f'"{landmark}"', "hub/HubVista")
    must_have(hub_progress, "ChaptersCleared", "hub/HubProgress")
    must_have(hub_progress, "light.Enabled = unlocked", "hub/HubProgress")
    must_have(dynamics, "function HubDynamics.departure", "hub/HubDynamics")
    must_have(lobby, "function LobbyService.onDeparture", "hub/LobbyService")
    must_have(lobby, "Config.PLACES.HUB == 0", "hub/LobbyService")
    must_have(lobby, "Config.PLACES.MATCH == 0", "hub/LobbyService")
    must_have(lobby, "Config.PLACES.HUB == Config.PLACES.MATCH", "hub/LobbyService")
    must_have(lobby, "Progress_v1", "hub/LobbyService")
    must_have(cosmetics, "Progress_v1", "hub/HubLoadout")
    must_have(cosmetics, "UpdateAsync", "hub/HubLoadout")

    for token in ("pcall(StudioGroundFloor.build)", "MapBuilder.build()",
                  "MapContract.read", "RoundService.init", "ReplayService.init"):
        must_have(match, token, "match/Main")
    for token in ("Config.PLACES.HUB", "Config.PLACES.MATCH",
                  "Config.PLACES.HUB ~= Config.PLACES.MATCH",
                  "fromMatch = true"):
        must_have(replay, token, "match/ReplayService")
    for token in ("StudioProductionDetail.apply", "StudioServiceDetail.apply",
                  "StudioArchitectureDetail.apply", "StudioStoryDetail.apply",
                  "StudioStoreAssets.apply"):
        must_have(studio, token, "match/StudioGroundFloor")
    # Lighting "ray/path tracing" look: authored indirect fill, not a claimed
    # realtime hardware tracer. All new sources are physically placed inside
    # rooms; total lights and shadow caster count are hard-capped.
    match_project = json.loads(require_text("default.project.json"))
    lighting_preset = match_project["tree"]["Lighting"]["$properties"]
    if lighting_preset.get("LightingStyle") != "Realistic":
        fail("Match place does not request Realistic lighting")
    if lighting_preset.get("PrioritizeLightingQuality") is not True:
        fail("Match place does not prioritize lighting detail")
    if "Technology" in lighting_preset:
        fail("Match still uses deprecated Technology setting")
    for setting in ("LightingStyle", "PrioritizeLightingQuality"):
        if re.search(r"Lighting\." + setting + r"\s*=", studio_lighting_service):
            fail(f"LightingService tries to write a Studio-authored property: {setting}")

    for token in ("StudioLightingRig.apply(map)", "StudioEvidenceDetail.apply(map)"):
        must_have(studio, token, "match/StudioGroundFloor")
    for token in ("LightingService.set", "LightingService.blackout",
                  "LightingService.fogIn", "LightingService.reset",
                  "role == \"Guide\"", "role == \"Emergency\"",
                  "role == \"Task\"", "role == \"Fault\"",
                  "FrostedDiffuser", "DeadAirStudioGrade", "DeadAirStudioBloom"):
        must_have(studio_lighting_service, token, "match/LightingService")
    for token in ("Instance.new(\"SurfaceLight\")", "Instance.new(\"SpotLight\")",
                  "Instance.new(\"PointLight\")", "role = \"Bounce\"",
                  "LightShadow", "LightBase", "assert(shadows <= 1"):
        must_have(studio_lighting, token, "match/StudioLightingRig")

    positions = {}
    for room in re.finditer(
        r'\{ name = "(\w+)", role = "(\w+)", x1 = (-?\d+), x2 = (-?\d+), '
        r'z1 = (-?\d+), z2 = (-?\d+), height = (\d+) \}', studio_rooms
    ):
        name, _role, x1, x2, z1, z2, h = room.groups()
        positions[name] = tuple(map(int, (x1, x2, z1, z2, h)))
    fixture_pattern = re.compile(
        r'\{ name = "([^"]+)", room = "([^"]+)", at = Vector3\.new\('
        r'(-?\d+(?:\.\d+)?), (-?\d+(?:\.\d+)?), '
        r'(-?\d+(?:\.\d+)?)\),\s*role = "([^"]+)", '
        r'range = (\d+(?:\.\d+)?), intensity = (\d+(?:\.\d+)?)'
    )
    fixtures = fixture_pattern.findall(studio_lighting)
    names = {f[0] for f in fixtures}
    if len(fixtures) != 55 or len(names) != len(fixtures):
        fail(f"Lighting rig expected 55 unique authored fixtures, found {len(fixtures)}")
    bounce_count = 0
    for name, room, x, y, z, role, range_, intensity in fixtures:
        bounds = positions.get(room)
        if not bounds:
            fail(f"Unknown lighting room: {name}: {room}")
            continue
        x, y, z = float(x), float(y), float(z)
        x1, x2, z1, z2, height = bounds
        if not (x1 + .5 < x < x2 - .5 and z1 + .5 < z < z2 - .5
                and 2 < y < height - .5):
            fail(f"Fixture is outside its room: {name}")
        if float(range_) > 25 or float(intensity) > 0.9:
            fail(f"Over-budget light range or brightness: {name}")
        if role == "Bounce":
            bounce_count += 1
    if bounce_count != 8:
        fail(f"Expected eight localized indirect-light proxies, found {bounce_count}")
    route_count = sum(1 for f in fixtures if f[5] == "Route")
    if route_count != 15:
        fail(f"Studio requires fifteen mounted emergency/route lights, found {route_count}")
    for token in ("StudioRouteFixtures", "room.height - 0.36", 'role = "Route"'):
        must_have(studio_lighting, token, "match/StudioLightingRig")
    for token in ('role == "Route"', "nominal * 0.35",
                  "Lighting.Brightness = 1.20",
                  "Lighting.EnvironmentDiffuseScale = 0.25",
                  "Lighting.ExposureCompensation"):
        must_have(studio_lighting_service, token, "match/LightingService")
    must_have(config, "FOG_END_CALM = 210", "shared/Config")
    must_have(config, "FOG_END_FULL = 110", "shared/Config")
    must_have(config, "FOG_END = 75", "shared/Config")

    if "StudioLightingRig" not in studio:
        fail("Studio geometry isn't wired to the lighting pass")

    # High-detail console is authored visual geometry, not a second puzzle.
    for token in ("StudioHeroConsole.build(ctrl, map)", "ProductionDressing",
                  "local ctrl = Kit.group(production, \"ControlA\")"):
        must_have(studio_production, token, "match/StudioProductionDetail")
    if '"DeskMeterBridge"' in studio_production or '"ChannelVU"' in studio_production:
        fail("Old duplicate Control A meter bridge must not coexist with hero console")
    for token in ("local CHANNELS = 16", "for i = 1, CHANNELS do",
                  "for i = 1, 8 do", "function HeroConsole.build(parent: Instance, map: Model)",
                  "interaction.Transparency = 1", "SessionLogReadingShelf",
                  "ConsoleIndicator", "VULens_", "FaderCap_",
                  "ChannelNumber_", "MasterPanel", "WoodSideCheek"):
        must_have(hero_console, token, "match/StudioHeroConsole")
    for token in ("StudioHeroConsole = require", "HeroMixConsole",
                  'descendant:GetAttribute("ConsoleIndicator")',
                  "for _, led in consoleIndicators do", "state ~= \"dead\""):
        if token == "StudioHeroConsole = require":
            must_have(studio_production, token, "match/StudioProductionDetail")
        else:
            must_have(studio_lighting_service, token, "match/LightingService")
    if '"MixFader"' in studio:
        fail("Old decorative MixFaders must not overlap the new controls")
    must_have(studio, 'objective(objectives, "MixingDesk", Vector3.new(-56, 1.6, -78)',
              "match/StudioGroundFloor")
    must_have(studio, 'objective(objectives, "SessionLog", Vector3.new(-57, 3.68, -75.65)',
              "match/StudioGroundFloor")
    must_have(config, 'Config.VERSION = "0.8.9-desk-cover"', "shared/Config")

    for objective in ("BookingDiary", "SessionLog", "TapeMachine", "Spares",
                      "CardIndex", "RoadCase", "Safe", "MemorialProgramme",
                      "PatchBay", "MixingDesk", "MailSlot", "ExitZone"):
        must_have(studio, f'"{objective}"', "match/StudioGroundFloor")
    for token in ("NotebookUi = require(script.Parent.NotebookUi)", "NotebookUi = NotebookUi"):
        must_have(client_main, token, "match/client/Main")
    for token in ("Remotes.Document.OnClientEvent", "Remotes.Radio.OnClientEvent",
                  'state:GetAttributeChangedSignal("Phase")', "table.clear(papers)",
                  "table.clear(radio)", "ChapterUi.isOpen()", "Enum.KeyCode.J",
                  "MAX_RADIO = 16", "MAX_PAPERS = 12"):
        must_have(notebook, token, "match/client/NotebookUi")
    # The optional sheets are actually in the authored map and are
    # server-delivered through the normal, round-owned read prompts.
    evidence_ids = set(re.findall(r'id = "([A-Za-z]+)", label =', chapter_text))
    world_ids = set(re.findall(r'id = "([A-Za-z]+)", caption =', world_evidence))
    if len(evidence_ids) != 5 or evidence_ids != world_ids:
        fail(f"Story evidence mismatch: text={sorted(evidence_ids)} map={sorted(world_ids)}")
    for token in ("StudioEvidenceDetail.apply(map)",
                  "StudioProductionDetail.apply", "StudioServiceDetail.apply"):
        must_have(studio, token, "match/StudioGroundFloor")
    for token in ("Text.EVIDENCE", 'props:FindFirstChild("RecordedEvidence")',
                  'Kit.prompt(paper, "Read"', "Kit.document(player, entry.title, entry.body)"):
        must_have(chapter, token, "match/Studio1")
    for token in ("state.shelfLabels", "Text.cardOrdinary",
                  "randomNumbers(extra, used)", "giveReel(player, \"A\"",
                  'if not giveReel(player, "B"', 'if not giveReel(player, "C"'):
        must_have(chapter, token, "match/Studio1")
    must_have(chapter_text, "3 NOVEMBER 1979", "match/Studio1Text")
    must_have(chapter_text, "Text.cardOrdinary", "match/Studio1Text")
    must_have(config, 'SAFE_COMBO = "031179"', "shared/Config")
    for token in ("guideButtons", "guide.BackgroundColor3 = BUTTON"):
        must_have(chapter_ui, token, "match/client/ChapterUi")
    notebook_capacity = re.search(r"MAX_PAPERS = (\d+)", notebook)
    if not notebook_capacity or int(notebook_capacity.group(1)) < len(evidence_ids) + 4:
        fail("Notebook cannot retain all five optional pages plus four core documents")
    for token in ("if not state.diaryRead then", "if not state.logRead then",
                  'table.insert(lines, "Read the session log (control A)")'):
        must_have(chapter, token, "match/Studio1")

    # The blind Engineer may consult actual player position only on physical
    # contact or LOS-verified catch, not to steer ordinary audio-only chases.
    for token in ("EvidenceMemory.new()", "memory.observe(stimulus, now)",
                  "memory.attend(stimulus, now, busy)",
                  "memory.predicted(target, now)", "memory.sortSearch",
                  "memory.confidentNear", "memory.visited",
                  "memory.reset()", "lungeDestination = heardAt"):
        must_have(engineer, token, "match/MonsterService")
    for forbidden in ("n.moveTo(targetRoot.Position",
                      "h:MoveTo(targetRoot.Position",
                      "then targetRoot.Position"):
        if forbidden in engineer:
            fail("Blind Engineer cannot navigate directly to an unheard target: " + forbidden)
    for token in ("anonymousBreath", "STATIC_MIN_INTEREST",
                  "staticRepeats >= C.STATIC_REPEATS",
                  "SEARCH_REVISIT_SECONDS", "SEARCH_DIRECTION_BONUS",
                  "player.Parent ~= nil", "C.TRACK_SECONDS"):
        must_have(engineer_memory, token, "match/Monster/EvidenceMemory")
    for token in ("Config.MONSTER = table.freeze(", "COGNITION = table.freeze(",
                  "STATIC_MIN_INTEREST = 26", "SEARCH_DIRECTION_BONUS = 8",
                  "GENERIC_HIDE_CHECK = 0.08", "SWITCH_HUNT_AFTER = 1.3"):
        must_have(config, token, "shared/Config")
    for token in ("Director.startRetreat", "Director.pickArea", "Director.wantsRetreat"):
        must_have(engineer, token, "match/MonsterService")
    # Finishing pass: real physical poses, native rig pivot hierarchy,
    # sensible inspection opportunities, protected hide/round boundaries,
    # bounded path costs and a deterministic Studio unit harness.
    for token in ("local Motion = require(", "Motion.new(m, r)", "pose.update(state,",
                  "motion.destroy()", "Environment.select(areas, center, investigateKind)",
                  'model:SetAttribute("Inspecting", inspection)',
                  'player:GetAttribute("Hiding") ~= true',
                  'startSearch(r.Position)', "inspectionPoints = {}"):
        must_have(engineer, token, "match/MonsterService")
    if engineer.count('player:GetAttribute("Hiding") ~= true') < 2:
        fail("Both contact detection and catch validation must exclude hidden players")
    for token in ("Motor6D", "joint.C0 = CFrame.new(offset +",
                  "joint.C1 = CFrame.new(0, pivotY, 0)", "head",
                  "left", "head:SetAttribute"):
        # Case insensitive on the joint names; don't demand a specific skin.
        if token not in ("left",) and token not in engineer_model:
            fail("Engineer articulated rig missing: " + token)
    for token in ("HeadJoint", "LeftArm", "RightLeg", 'model:SetAttribute("Intent", intent)',
                  "local headYaw", "joint.C0 = joint.C0:Lerp",
                  "function visual.destroy"):
        # The joints are generated as name .. Joint, not literal HeadJoint.
        if token == "HeadJoint":
            must_have(engineer_model, 'joint.Name = name .. "Joint"', "match/EngineerModel")
        else:
            must_have(engineer_motion, token, "match/Motion")
    for token in ("function Environment.select", "BY_SOUND", "TapeMachine",
                  "MixingDesk", "CardIndex", "PatchBay", "RoadCase",
                  "bestWalk = 9"):
        must_have(engineer_environment, token, "match/Environment")
    for token in ("MAX_FALLBACK_PATHS = 6", "attempts >= MAX_FALLBACK_PATHS",
                  "os.clock() - lastComputeTime >= REPLAN_INTERVAL"):
        must_have(engineer_navigator, token, "match/Navigator")
    for token in ("generation += 1", "generation ~= myGeneration"):
        must_have(engineer_mimicry, token, "match/Mimicry")
    for token in ("brain.attend(", "brain.observe(", "brain.confidentNear(",
                  "brain.sortSearch(", "brain.reset()"):
        must_have(engineer_scenarios, token, "tools/studio/EngineerAiSelfTest")
    must_have(config, "INSPECT_SECONDS = 1.6", "shared/Config")

    must_have(engineer_director, "function Director.update", "match/Director")
    must_have(engineer_senses, "NoiseService.effectiveLoudness", "match/Perception")
    for token in ("NoiseService.emit(spot.Position, Config.NOISE.GASP",
                  "NoiseService.emit(spot.Position, Config.NOISE.BREATH"):
        must_have(hiding, token, "match/HideService")

    # Verified cover must be intentional and visible, not random wardrobes
    # or an omniscient hidden-player query. The Engineer only guarantees
    # inspection after actually SEEING someone enter that exact cover.
    for token in ("local function underDesk(", '"Kind", "underdesk"',
                  '"ReceptionCounter"', '"BreakTable"', '"ArchiveSortingDesk"',
                  '"ServiceMaintenanceDesk"', '"LiveRoomMusicDesk"',
                  '"ControlBEditCover"', '"ExitClearance"', '"BackScreen"'):
        must_have(studio, token, "match/StudioGroundFloor")
    for obsolete in ('"ArchiveLocker"', '"ControlAWardrobe"', '"LiveWardrobe"',
                     '"ReceptionLocker"', '"ServiceLocker"'):
        if obsolete in studio:
            fail("Removed locker asset still generated: " + obsolete)
    for token in ('prompt.ActionText = if kind == "underdesk" then "Get under"',
                  'MonsterService.reportHide(player, spot)', 'originalAutoRotate',
                  'humanoid.Sit = true', '"underdesk" then HIDE.DESK_MUFFLE',
                  'Remotes.LeaveHiding.OnServerEvent', 'HideService.leave(found)'):
        must_have(hiding, token, "match/HideService")
    for token in ("function MonsterService.reportHide(", "lastVisual[seen.player]",
                  "now - record.time > 2.5", "spotFronts = { [point] = spot }",
                  "onCatch(found)", 'log("caught", found.Name, "under cover")'):
        must_have(engineer, token, "match/MonsterService")
    must_have(studio_production, '"EditCounterBackPanel"', "match/StudioProductionDetail")
    must_have(config, "DESK_MUFFLE = 0.72", "shared/Config")
    must_have(desk_cover_test, "assert(count == 6", "tools/studio/DeskCoverSelfTest")
    must_have(config, 'Config.VERSION = "0.8.9-desk-cover"', "shared/Config")

    must_have(chapter, "StudioTension.start(myRound)", "match/Studio1")
    for guard in ("MAX_CUES_PER_ROUND", "MIN_CUE_GAP", "OPENING_END",
                  'RoundState.get("LastCall")', "Kit.shocksFired() > 0"):
        must_have(tension, guard, "match/StudioTension")

    match_ids = re.search(
        r"Config.PLACES = table.freeze\(\{\s*HUB = (\d+),.*?MATCH = (\d+)",
        config,
    )
    if not match_ids:
        fail("Could not read Config.PLACES HUB and MATCH IDs")
    else:
        hub_id, match_id = map(int, match_ids.groups())
        if hub_id == 0 or match_id == 0:
            notes.append("Deployment blocked: configure both real published place IDs in Config.PLACES")
        elif hub_id == match_id:
            fail("HUB and MATCH place IDs must be distinct")
    version = re.search(r'Config.VERSION = "([^"]+)"', config)
    if not version:
        fail("Shared build version not set")
    else:
        notes.append(f"Shared build: {version.group(1)}")

    if failures:
        print(f"FAIL — {len(failures)} source checks failed:")
        for item in failures:
            print(f"  - {item}")
    else:
        print("PASS — hub and studio source contracts / route graph / launch wiring")
    for item in notes:
        print(f"NOTE — {item}")
    print("NOT TESTED — Luau compile, Rojo build, Studio navigation, sound, saving, device FPS or live teleport")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
