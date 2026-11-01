#!/usr/bin/env python3
"""VF-01 contract check: a narrow, coherent Blackline electrical/signal story.

These checks cannot prove Studio rendering or user legibility; they keep the
visual stations synchronized to the *existing* objective source-of-truth.
"""
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parent.parent

def source(name):
    return (ROOT/name).read_text()

def main():
    devices=source("src/server/Maps/BlacklineFacilityDevices.luau")
    service=source("src/server/FacilityStateService.luau")
    objectives=source("src/server/ObjectiveService.luau")
    kit=source("src/server/Maps/Kit.luau")
    older=source("src/server/Maps/StoryProps.luau")
    ci=source(".github/workflows/rojo-build.yml")
    expected={"Reception","StaffGallery","ControlA","LiveHall"}
    assert len(re.findall(r'^    (Reception|StaffGallery|ControlA|LiveHall)="',devices,re.M))==4
    assert 'FacilitySystems' in kit
    assert 'BlacklineFacilityDevices.decorate(facilitySystems,room)' in kit
    assert 'spec.authored==true and spec.id=="studio"' in kit, (
        "inert radio/foundry maps must not receive Blackline devices")
    assert 'if not legend then return end' in devices, (
        "no procedural device scatter in the other 15 Blackline rooms")
    for name in expected:
        assert name+'="' in devices
        assert name+'={' in service
    assert 'node:SetAttribute("FacilityCircuit",room.name)' in devices
    assert 'part.CanCollide=false' in devices and 'part.CanQuery=false' in devices
    assert 'part.CastShadow=false' in devices
    assert 'part:SetAttribute("DisablePBR",true)' in devices
    assert 'part:SetAttribute("ArtPass","BlacklineVF01")' in devices
    assert 'gui.Parent=glass' in devices, "status text must be on visible front panel"
    assert 'Instance.new("SurfaceGui")' in devices
    assert 'Instance.new("SurfaceLight")' not in devices, (
        "zero additional shadowed lights for the four status nodes")
    for phase in ("Dead","Powered","Routed","Broadcast","Released"):
        assert service.count(phase+'={status=')==4,(
            phase,"each station must have deliberate copy for each real objective state")
        assert phase+'=Color3.fromRGB(' in service,(
            phase,"missing restrained semantic status indication")
    assert 'if not power then return "Dead" end' in service
    assert 'if exitReleased then return "Released" end' in service
    assert 'if broadcast then return "Broadcast" end' in service
    assert 'if fuses>=needed then return "Routed" end' in service
    assert 'if target:GetAttribute("FacilityPhase")==current then' in service,(
        "state changes must not churn gui assignments each frame")
    assert 'RoundState.get("PowerOn")==true' in objectives
    assert 'RoundState.get("FusesPlaced") or 0' in objectives
    assert 'RoundState.get("DoorsOpen")==true' in objectives
    assert 'Config.FUSES_NEEDED' in objectives
    assert 'FacilityStateService.init(layout.map)' in objectives
    assert objectives.count('refreshFacility()')>=6, (
        "missing lifecycle refresh for power, fuse, tape, release or reset")
    assert 'RoundState.set("PowerOn", on)' in objectives
    assert 'RoundState.set("FusesPlaced", placed)' in objectives
    assert 'RoundState.set("DoorsOpen", true)' in objectives
    assert 'SIGNAL  /  ON AIR' not in older, (
        "old power-only lights must not claim broadcasting before tape starts")
    assert 'local function startHum(myRound: number)' in objectives, (
        "existing real generator mechanical audio/AI noise must remain")
    assert 'NoiseService.emit(' not in service,(
        "no new artificial monster-attracting signals from cosmetic displays")
    assert 'task.spawn(' not in service and 'task.wait(' not in service,(
        "visual state cannot invent separate time-based machinery events")
    assert 'selene ' in ci and 'tools/validate_facility_vf01.py' in ci
    print("PASS VF01: four intentional Blackline panels, five meaningful states, "
          "source-of-truth objective wiring, zero new light/audio/physics workload")
    print("PENDING: readability and orientation at 5/15/30 studs, actual Roblox "
          "SurfaceGui replication, phase visuals and device collision acceptance")

if __name__=="__main__":
    main()
