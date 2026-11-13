return lowerkeys({text_fx_test = {
    name='Text FX test',
    description='Dancing Tiglil and Lorem Ipsum text effects, with five-second holds',
    objectName='house_western_hologram.dae',
    script='text_fx_test_script.lua',
    buildCostEnergy=0, buildCostMetal=0, buildTime=1,
    maxDamage=9000, footprintX=1, footprintZ=1,
    canMove=false, canAttack=false, blocking=false,
    maxSlope=90, maxWaterDepth=1000, sightDistance=100,
    category='NOTARGET', explodeAs='NOWEAPON', selfDestructAs='NOWEAPON',
    customParams={normaltex='unittextures/house_europe_normal.dds', text_fx_test=1, text_fx_speed=1},
}})
