-- Simulation frames at 30 fps. Counts are caps, never a reason to spawn people.
return {
    tickFrames=30, weekday=7, clearFrames=30*30, badWeatherFrames=20*30,
    recruitFrames=5*30, arrivalFrames=100*30, cooldownFrames=120*30,
    releaseFrames=3*30, previewFrames=4*60*30, recruitRadius=2800,
    venueSeparation=700, secondaryPopulation=48, dangerThreshold=100,
    daylightStart=7, daylightEnd=18, maxSlope=.12,
    mainKinds={"protest","wedding","convoy"},
    -- Entrance directions are local to the live building orientation. The
    -- anchor lies beyond its collision footprint, with an outward escape lane.
    objectives={
        objective_presidentialpalace={side=1, setback=100},
        objective_westhemhq={side=1, setback=110},
        objective_refugeecamp={side=1, setback=100},
    },
    profiles={
        protest={startHour=9, peakHour=13, endHour=17, minimum=16, maximum=32,
            radius=120, roles={"organizer","sign","chanter","speaker","onlooker","filming"}},
        wedding={startHour=10, peakHour=12, endHour=15, minimum=12, maximum=24,
            radius=105, roles={"couple","couple","guest","guest","filming","onlooker"}},
        yoga={startHour=8, peakHour=9, endHour=11, minimum=7, maximum=13,
            radius=105, roles={"instructor","yoga","yoga","yoga"}},
        convoy={startHour=11, peakHour=12, endHour=15, minimum=6, maximum=12,
            radius=100, roles={"guest","onlooker","filming"}},
    },
    escalation={chancePercent=15, fraction=.125, intervalFrames=12*30, range=220, minRange=40},
    convoy={minimum=3, maximum=6, departureFrames=6*30, hornFrames=12*30,
        timeoutFrames=150*30, spacing=120, goalRadius=40},
    -- Same native route validator/house clearance used by the city parade.
    routeHouseClearance=35, routeMinNodes=3, routeMaxNodes=4,
    routeMinLength=650, routeMinLegDistance=140, routeStagingGap=80,
    routeRejectRetrace=false, vehicleSpacing=120, combatHeatThreshold=100,
}
