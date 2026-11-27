local defs={}
for variant=1,2 do
    defs["civilianstone"..variant]={
        name="Hand-thrown stone",weaponType="Cannon",range=220,reloadtime=12,
        weaponVelocity=180,flightTime=6,model="civilian_stone"..variant..".dae",
        groundBounce=true,waterBounce=false,numBounce=3,bounceRebound=.32,bounceSlip=.48,
        collideFriendly=true,collideNeutral=true,avoidFriendly=false,avoidFeature=false,
        impactOnly=true,areaOfEffect=0,edgeEffectiveness=0,craterMult=0,craterBoost=0,
        fireStarter=0,impulseFactor=0,noSelfDamage=true,
        explosionGenerator="",smokeTrail=false,damage={default=4},
        customParams={civilian_stone=variant},
    }
end
return lowerkeys(defs)
