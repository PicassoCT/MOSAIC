-- Event-driven cigarette effect. Call alongside the model's Show/Hide changes.
return function(unitID, enabled)
    local currentPiece, iconMode, dead
    local slot = 'cigarette'
    local self = {}
    local function remove()
        if enabled and GG.SmokeRibbon then GG.SmokeRibbon.Remove(unitID,slot) end
    end
    function self.Show(piece)
        currentPiece = piece
        if not enabled or dead or iconMode or not piece or not GG.SmokeRibbon then return end
        local ok,err=GG.SmokeRibbon.Set(unitID,slot,piece,{
            direction={0,1,0}, directionSpace='world',
            length=18, width=2.5, curl=0.6, speed=0.65, strands=2,
            colorStart={0.68,0.70,0.74,0.35}, colorEnd={0.55,0.58,0.62,0},
            emission={0.1,0}, seed=unitID%100,
            motionAffected=true, windAffected=true,
            motionInfluence=0.65, windInfluence=0.3, trailTime=0.55,
        })
        if not ok then Spring.Echo('Cigarette smoke: '..tostring(err)) end
    end
    function self.Hide(piece)
        if currentPiece==piece then currentPiece=nil;remove() end
    end
    function self.SetIconMode(showIcon)
        iconMode=showIcon
        if showIcon then currentPiece=nil;remove() end
        -- hideAll hides every cigarette; wait for the next real Show event.
    end
    function self.Shutdown() dead=true;currentPiece=nil;remove() end
    return self
end
