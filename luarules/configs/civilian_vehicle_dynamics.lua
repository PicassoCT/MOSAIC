-- Speeds are map units/second; acceleration/braking targets are seconds.
-- Cargo masses are gameplay estimates in kg, independent of collision mass.
local M = {}
M.profiles = {
    car = {speed=126, seconds=3.5, brakeSeconds=1.5, mass=1800},
    sport = {speed=156, seconds=3, brakeSeconds=1.5, mass=1700},
    van = {speed=96, seconds=4.5, brakeSeconds=2, mass=3000},
    rigid = {speed=75, seconds=5.5, brakeSeconds=2.5, mass=7000},
    heavy = {speed=67.5, seconds=6, brakeSeconds=2.8, mass=9000},
    articulated = {speed=75, seconds=7, brakeSeconds=3, mass=15000},
    bus = {speed=81, seconds=6, brakeSeconds=2.5, mass=12000},
    limousine = {speed=105, seconds=4.5, brakeSeconds=2, mass=3000},
}
M.models = {
    truck_arab0='car', truck_arab1='car', truck_arab2='car',
    truck_arab3='van', truck_arab4='van', truck_arab5='van',
    truck_arab6='rigid', truck_arab7='heavy', truck_arab8='heavy',
    truck_western0='car', truck_western1='sport', truck_western2='van',
    truck_western3='articulated',
}
M.longBodies = {[1]='articulated',[2]='articulated',[3]='bus',[4]='bus',[5]='limousine'}
M.hijackExtraNames = {truck_arab9=true,truck_western4=true}
M.cargoMass = {empty=0, light=1000, passengers=1800, medium=3500,
    heavy=7500, bulk=12000, armoured=9000}
M.payloadDefaults = {truckpayload='medium', truckpayloadservice='medium',
    truckpayloadparade='heavy', truckpayloadrefugee='passengers',
    truckpayloadfortnox='armoured', civilianloot='light'}
M.legacyCargo = {
    [1]='medium',[2]='bulk',[3]='medium',[4]='heavy',[5]='light',[6]='medium',
    [7]='medium',[8]='medium',[9]='bulk',[10]='light',[11]='bulk',[12]='bulk',
    [13]='bulk',[14]='light',[15]='medium',[16]='bulk',[17]='heavy',[18]='light',
    [19]='light',[20]='light',[21]='heavy',[22]='medium',[23]='heavy',[24]='heavy',
    [25]='empty',[26]='empty',[27]='empty',[28]='empty',[29]='empty',[30]='empty',
    [31]='heavy',[32]='medium',[33]='passengers',[34]='passengers',[35]='passengers',
    [36]='heavy',[37]='heavy',[38]='heavy',[39]='heavy',[40]='passengers',
    [41]='passengers',[42]='passengers',[43]='light',[44]='light',[45]='light',[46]='heavy',
    FortNox='armoured', refugee='passengers',
}
M.serviceCargo = {air_scrubber='heavy',night_kitchen='medium',battery_exchange='heavy',
    salvage_press='bulk',cold_chain='heavy',sleeper_shuttle='passengers',crematorium='heavy',
    noodle_shop='medium',casino='medium',strip_club='medium',bar='medium',band='medium',
    unato_rations='medium'}
M.paradeCargo = {
    [1]='medium',[2]='heavy',[3]='medium',[4]='light',[5]='medium',[6]='heavy',
    [7]='heavy',[8]='heavy',[9]='medium',[10]='medium',[11]='light',[12]='medium',
    [13]='medium',[14]='medium',[15]='medium',[16]='medium',[17]='heavy',[18]='heavy',
    [19]='medium',[20]='medium',[21]='heavy',[22]='medium',[23]='medium',[24]='heavy',
}
M.payloadVariants = {legacy=M.legacyCargo,service=M.serviceCargo,parade=M.paradeCargo}
function M.Calculate(profile, cargoMass, factor)
    local load = cargoMass/profile.mass
    local speed = profile.speed*math.max(0.8,1-0.08*load)
    return {maxSpeed=speed*factor,
        accRate=profile.speed/(900*profile.seconds*(1+0.65*load)),
        decRate=profile.speed/(900*profile.brakeSeconds*(1+0.35*load))}, speed
end
return M
