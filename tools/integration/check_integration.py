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


def require_text(path: str) -> str:
    file = ROOT / path
    if not file.is_file():
        fail(f"Missing file: {path}")
        return ""
    return file.read_text(encoding="utf-8")


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
    chapter = require_text("src/server/Chapters/Studio1.luau")
    tension = require_text("src/server/Chapters/StudioTension.luau")
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
    for objective in ("BookingDiary", "SessionLog", "TapeMachine", "Spares",
                      "CardIndex", "RoadCase", "Safe", "MemorialProgramme",
                      "PatchBay", "MixingDesk", "MailSlot", "ExitZone"):
        must_have(studio, f'"{objective}"', "match/StudioGroundFloor")
    must_have(chapter, "StudioTension.start(myRound)", "match/Studio1")
    for guard in ("MAX_CUES_PER_ROUND", "MIN_CUE_GAP", "OPENING_END",
                  'RoundState.get("LastCall")', "Kit.shocksFired() > 0"):
        must_have(tension, guard, "match/StudioTension")

    match_ids = re.search(
        r"Config.PLACES = table.freeze\(\{\s*HUB = (\d+),[^\n]*\n\s*MATCH = (\d+),",
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
