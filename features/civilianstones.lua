local defs={}
for variant=1,2 do
    defs["civilianstone"..variant]={
        name="Settled stone",description="A discarded protest stone",
        object="civilian_stone"..variant..".dae",blocking=false,flammable=false,
        reclaimable=false,autoreclaimable=false,resurrectable=0,
        upright=false,category="GROUND",damage=1,metal=0,energy=0,
        mass=.2,footprintX=1,footprintZ=1,
        customParams={civilian_stone=variant,nohealthbars=true},
    }
end
return lowerkeys(defs)
