-- The transported factory keeps its existing unit identity and attachment
-- scripts. Its command menu and creation permissions follow the owning team.
return {
    common = {
        "air_copter_scoutlett", "air_copter_antiarmor",
        "ground_turret_mg", "ground_turret_antiarmor", "ground_turret_rocket",
        "ground_walker_mg", "ground_turret_cm_transport",
    },
    protagon = {
        "air_copter_mg", "ground_turret_sniper", "brehmerwall",
        "ground_truck_mg", "ground_truck_rocket",
    },
    antagon = {
        "air_copter_ssied", "ground_turret_ssied", "ground_walker_grenade",
        "ground_turret_dronegrenade", "ground_turret_mortar", "barricade",
        "civilian_truck_mg", "civilian_truck_mortar", "civilian_truck_ssied",
    },
}
