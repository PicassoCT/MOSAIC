"""Synthetic Lua 5.1 contract tests. These are not live Recoil observations."""
from __future__ import annotations

from contextlib import contextmanager
import json
import os
from pathlib import Path
import tempfile
import unittest

from runner import lua_literal, validate_scenario

try:
    from lupa.lua51 import LuaRuntime
except ImportError:
    LuaRuntime = None


ROOT = Path(__file__).resolve().parent
OVERLAY = ROOT / "overlay"
GADGET = OVERLAY / "luarules/gadgets/dbg_animation_lab.lua"
WIDGET = OVERLAY / "luaui/widgets_mosaic/dbg_animation_lab_capture.lua"
JSON_LUA = OVERLAY / "luarules/configs/animation_lab_json.lua"

STUB = r'''
gadget = {}; widget = {}
Game = {mapSizeX=2048,mapSizeZ=2048,gameSpeed=30,mapName='SYNTHETIC FIXTURE',gameName='SYNTHETIC FIXTURE'}
Engine = {version='SYNTHETIC Lua contract test'}
CMD = {MOVE=10,STOP=0,ATTACK=20,FIRE_STATE=45,MOVE_STATE=50}
UnitDefNames = {mock_human={id=1},mock_truck={id=2}}
Test = {frame=0, rules={}, units={}, serial=0, orders={}, threads={}, globals={}, messages={}, saved={}, synced=true}
gadgetHandler = {
 IsSyncedCode=function()return Test.synced end,
 AddSyncAction=function(_,name,fn)Test.sync=fn end,
 RemoveSyncAction=function()end
}
widgetHandler = {
 RegisterGlobal=function(_,name,fn)Test.globals[name]=fn end,
 DeregisterGlobal=function(_,name)Test.globals[name]=nil end
}
Spring = {
 GetGameFrame=function()return Test.frame end,
 GetDrawFrame=function()return Test.frame*2 end,
 GetFrameTimeOffset=function()return 0.25 end,
 SetGameRulesParam=function(key,value)Test.rules[key]=value end,
 GetGameRulesParam=function(key)return Test.rules[key] end,
 Echo=function(message)Test.messages[#Test.messages+1]=message end,
 GetGroundHeight=function()return 0 end,
 ValidUnitID=function(id)return Test.units[id] ~= nil end,
 GetUnitIsDead=function(id)return not Test.units[id] or Test.units[id].dead end,
 SetUnitAlwaysVisible=function()end, SetUnitNoSelect=function()end,
 GetUnitPosition=function(id)local u=Test.units[id];if u then return u.x,u.y,u.z end end,
 GetUnitVelocity=function()return 0,0,0,0 end,
 GetUnitHeading=function()return 0 end,
 GetUnitDirection=function()return 0,0,1 end,
 GetUnitTransporter=function(id)return Test.units[id].carrier end,
 UnitAttach=function(carrier,id,piece)Test.units[id].carrier=carrier end,
 UnitDetach=function(id)Test.units[id].carrier=nil end,
 SetUnitPosition=function(id,x,z)Test.units[id].x=x;Test.units[id].z=z end,
 DestroyUnit=function(id)Test.units[id].dead=true end,
 GetUnitPieceMap=function()return {root=1,Feet1=2,attachPoint=3} end,
 GetUnitPiecePosDir=function(id,piece)local u=Test.units[id];return u.x+(piece==2 and (Test.frame%3) or 0),u.y+piece,u.z end,
 GetUnitRulesParam=function()return nil end,
 IsUnitInView=function()return true end,
 GetViewGeometry=function()return 320,240 end,
 WorldToScreenCoords=function(x,y,z)return 160,120+y/3,0.5 end,
 GetCameraState=function()return Test.camera or {name='free',mode=4} end,
 SetCameraState=function(value)Test.camera=value end,
 IsGUIHidden=function()return false end,
 SendCommands=function(command)Test.lastCommand=command end,
 GetTimer=function()return Test.frame/30 end,
 DiffTimers=function(a,b)return a-b end,
 SendLuaRulesMsg=function(message)if gadget.RecvLuaMsg then gadget:RecvLuaMsg(message,0)end end,
 UnitScript={}
}
function Spring.CreateUnit(def,x,y,z,facing,team)
 Test.serial=Test.serial+1
 local id=Test.serial
 Test.units[id]={x=x,y=y,z=z,def=def,dead=false,env={UpperAnimationState='standing',LowerAnimationState='standing'}}
 Test.units[id].env.accept=function()return true end
 Test.units[id].env.reject=function()return false end
 Test.units[id].env.yielding=function()
  coroutine.yield(2)
  Test.yieldReturned=true
  return true
 end
 return id
end
function Spring.GiveOrderToUnit(id,command,args)
 Test.orders[#Test.orders+1]={id=id,command=command,args=args}
 if command==CMD.MOVE then Test.units[id].goal={args[1],args[2],args[3]}
 elseif command==CMD.STOP then Test.units[id].goal=nil end
end
function Spring.UnitScript.GetScriptEnv(id)return Test.units[id].env end
function Spring.UnitScript.CallAsUnit(id,fn,...)return fn(...)end
function Spring.UnitScript.SetSignalMask(mask)end
function Spring.UnitScript.StartThread(fn,...)
 local args={...}
 local co=coroutine.create(function()fn(unpack(args))end)
 local ok,delay=coroutine.resume(co);assert(ok,delay)
 if coroutine.status(co)~='dead' then Test.threads[#Test.threads+1]={co=co,wake=Test.frame+(delay or 1)} end
end
function Test.step(frame)
 Test.frame=frame
 for _,u in pairs(Test.units)do
  if u.goal and not u.dead then
   local dx,dz=u.goal[1]-u.x,u.goal[3]-u.z;local distance=math.sqrt(dx*dx+dz*dz)
   if distance>0 then local amount=math.min(distance,2);u.x=u.x+dx/distance*amount;u.z=u.z+dz/distance*amount end
  end
 end
 for _,t in ipairs(Test.threads)do
  if coroutine.status(t.co)~='dead' and frame>=t.wake then
   local ok,delay=coroutine.resume(t.co);assert(ok,delay);t.wake=frame+(delay or 1)
  end
 end
end
function SendToUnsynced(name,payload)
 python_event(payload)
 if Test.globals.AnimationLabEvent then Test.globals.AnimationLabEvent(payload) end
end
'''


def scenario(phases=None, units=None):
    return validate_scenario({
        "schema_version": 1, "name": "SYNTHETIC contract fixture", "warmup_frames": 2,
        "capture": {"interval_frames": 3, "width": 320, "height": 240},
        "units": units or [{"name": "subject", "def": "mock_human", "x": 0, "z": 0}],
        "phases": phases or [
            {"name": "walking", "frames": 9, "expected_motion": True,
             "actions": [{"type": "move", "unit": "subject", "x": 100, "z": 0}],
             "checks": [{"type": "displaced", "unit": "subject", "min": 10}]},
            {"name": "stopped", "frames": 6, "actions": [{"type": "stop", "unit": "subject"}]},
        ],
    })


@contextmanager
def current_directory(directory):
    previous = Path.cwd()
    os.chdir(directory)
    try:
        yield
    finally:
        os.chdir(previous)


@unittest.skipIf(LuaRuntime is None, "Install optional lupa to execute Lua 5.1 contract tests")
class OverlayTests(unittest.TestCase):
    def setup_lua(self, spec=None, with_widget=False, save_ok=True):
        self.spec = spec or scenario()
        self.events = []
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().python_event = lambda text: self.events.append(json.loads(text))
        lua.execute(STUB)
        config = {"scenario": self.spec, "run_id": "synthetic-run", "seed": 1337,
                  "view": "side", "output_dir": "animlab", "capture_dir": "animlab/captures"}
        lua.globals().lab_config = lua.execute("return " + lua_literal(config))
        lua.globals().python_include = lambda path: lua.execute(JSON_LUA.read_text())
        lua.execute("VFS={FileExists=function()return true end,Include=function(path) if path:find('animation_lab_run.lua',1,true)then return lab_config else return python_include(path)end end}")
        lua.execute(GADGET.read_text())
        lua.execute("gadget:Initialize()")
        if with_widget:
            from PIL import Image
            lua.globals().python_mkdir = lambda path: Path(path).mkdir(parents=True, exist_ok=True)

            def save_image(x, y, width, height, path, options):
                if not save_ok:
                    return False
                Image.new("RGB", (width, height), (int(lua.globals().Test.frame) % 255, 30, 80)).save(path)
                return True

            lua.globals().python_save = save_image
            lua.execute("Spring.CreateDir=python_mkdir;gl={SaveImage=python_save}")
            lua.execute(WIDGET.read_text())
            lua.execute("widget:Initialize()")
        self.lua = lua
        return lua

    def drive(self, last, widget=False):
        for frame in range(int(self.lua.globals().Test.frame) + 1, last + 1):
            self.lua.execute(f"Test.step({frame});gadget:GameFrame({frame})")
            if widget:
                self.lua.execute("widget:Update();widget:DrawScreenPost()")

    def test_json_escaping_and_nonfinite_rejection(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        encode = lua.execute(JSON_LUA.read_text())["encode"]
        original = 'quoted " \\ newline\n\t\x01 ü'
        self.assertEqual(json.loads(encode(original)), original)
        with self.assertRaises(Exception):
            encode(float("nan"))

    def test_no_ready_no_spawn_and_wrong_player_ignored(self):
        lua = self.setup_lua()
        lua.execute("gadget:RecvLuaMsg('animlab_ready:synthetic-run',1)")
        self.drive(10)
        self.assertEqual(lua.globals().Test.serial, 0)
        lua.execute("gadget:RecvLuaMsg('animlab_ready:synthetic-run',0)")
        self.drive(35)
        self.assertEqual(lua.globals().Test.serial, 1)
        self.assertEqual(lua.globals().Test.rules.animlab_status, 2)

    def test_native_order_and_displacement_check(self):
        lua = self.setup_lua()
        lua.execute("gadget:RecvLuaMsg('animlab_ready:synthetic-run',0)")
        self.drive(20)
        self.assertTrue(any(item["kind"] == "check" and item["ok"] for item in self.events))
        self.assertEqual(lua.globals().Test.orders[3].command, 10)
        self.assertEqual([e["phase"] for e in self.events if e["kind"] == "phase"], ["walking", "stopped"])

    def test_missing_definition_fails_without_spawning_fallback(self):
        spec = scenario(units=[{"name": "subject", "def": "missing_model"}])
        lua = self.setup_lua(spec)
        lua.execute("gadget:RecvLuaMsg('animlab_ready:synthetic-run',0)")
        self.drive(5)
        self.assertEqual(lua.globals().Test.serial, 0)
        self.assertEqual(lua.globals().Test.rules.animlab_status, 3)
        self.assertIn("unknown unit definition", self.events[-1]["message"])

    def test_script_rejection_is_failed_not_success(self):
        spec = scenario(phases=[{"name": "reject", "frames": 9, "actions": [
            {"type": "call", "unit": "subject", "function": "reject", "args": []}]}])
        lua = self.setup_lua(spec)
        lua.execute("gadget:RecvLuaMsg('animlab_ready:synthetic-run',0)")
        self.drive(15)
        self.assertEqual(lua.globals().Test.rules.animlab_status, 3)
        returned = [e for e in self.events if e["kind"] == "call_return"][0]
        self.assertIs(returned["result"], False)

    def test_yielding_script_runs_on_coroutine(self):
        spec = scenario(phases=[{"name": "yielding", "frames": 9, "actions": [
            {"type": "call", "unit": "subject", "function": "yielding", "args": []}]}])
        lua = self.setup_lua(spec)
        lua.execute("gadget:RecvLuaMsg('animlab_ready:synthetic-run',0)")
        self.drive(15)
        self.assertTrue(lua.globals().Test.yieldReturned)
        self.assertEqual(lua.globals().Test.rules.animlab_status, 2)

    def test_attach_detach_and_expected_destroy(self):
        spec = scenario(units=[{"name": "subject", "def": "mock_human"}, {"name": "truck", "def": "mock_truck", "x": 30}], phases=[
            {"name": "attach", "frames": 3, "actions": [{"type": "attach", "unit": "subject", "transporter": "truck", "piece": "attachPoint"}], "checks": [{"type": "transported", "unit": "subject", "transporter": "truck"}]},
            {"name": "detach", "frames": 3, "actions": [{"type": "detach", "unit": "subject", "x": 50, "z": 0}], "checks": [{"type": "detached", "unit": "subject"}]},
            {"name": "death", "frames": 3, "actions": [{"type": "destroy", "unit": "subject"}]},
        ])
        lua = self.setup_lua(spec)
        lua.execute("gadget:RecvLuaMsg('animlab_ready:synthetic-run',0)")
        self.drive(15)
        self.assertEqual(lua.globals().Test.rules.animlab_destroyed_1, 1)
        self.assertEqual(lua.globals().Test.rules.animlab_status, 2)

    def test_real_png_widget_contract_and_analyzer(self):
        from analyze import analyze_run
        with tempfile.TemporaryDirectory() as directory:
            run = Path(directory)
            data = run / "engine-data"
            data.mkdir()
            with current_directory(data):
                self.setup_lua(with_widget=True)
                self.drive(22, widget=True)
                marker = json.loads(Path("animlab/complete.json").read_text())
                self.assertEqual(marker["status"], "complete")
                events = [json.loads(line) for line in Path("animlab/events.jsonl").read_text().splitlines()]
                samples = [e for e in events if e["kind"] == "sample"]
                self.assertEqual([s["frame"] for s in samples], [5, 8, 11, 14, 17])
                self.assertTrue(all(s["units"][0]["pieces"][0]["position_kind"] == "emission_point" for s in samples))
            (run / "manifest.json").write_text(json.dumps({"schema_version": 1, "run_id": "synthetic-run", "status": "captured", "synthetic_fixture": True, "scenario": self.spec}))
            report = analyze_run(run, make_video=False)
            self.assertEqual(report["status"], "needs_visual_review", report["capture_problems"])
            self.assertTrue(report["synthetic_fixture"])

    def test_png_failure_produces_failed_completion(self):
        with tempfile.TemporaryDirectory() as directory, current_directory(directory):
            self.setup_lua(with_widget=True, save_ok=False)
            self.drive(8, widget=True)
            marker = json.loads(Path("animlab/complete.json").read_text())
            self.assertEqual(marker["status"], "failed")
            self.assertIn("gl.SaveImage failed", marker["message"])

    def test_opening_cinematic_does_not_consume_animation_phases(self):
        with tempfile.TemporaryDirectory() as directory, current_directory(directory):
            lua = self.setup_lua(with_widget=True)
            lua.execute("WG={MosaicArrival={active=true}}")
            self.drive(8, widget=True)
            self.assertEqual(lua.globals().Test.serial, 0)
            self.assertIsNone(lua.globals().Test.camera)
            lua.execute("WG.MosaicArrival.active=false")
            self.drive(30, widget=True)
            events = [json.loads(line) for line in Path("animlab/events.jsonl").read_text().splitlines()]
            first_phase = next(e for e in events if e["kind"] == "phase")
            first_sample = next(e for e in events if e["kind"] == "sample")
            self.assertEqual(first_phase["frame"], first_sample["frame"])
            self.assertGreater(first_sample["frame"], 8)
            self.assertEqual(json.loads(Path("animlab/complete.json").read_text())["status"], "complete")


class BuiltInScenarioTests(unittest.TestCase):
    def test_all_scenarios_validate(self):
        for path in (ROOT / "scenarios").glob("*.json"):
            with self.subTest(path=path.name):
                validate_scenario(json.loads(path.read_text()))


if __name__ == "__main__":
    unittest.main()
