-- Modular placeholder art. Origins are pixel-grid offsets from the unit anchor.
-- Bodies share a neck at y=12; faces attach there; masks sit one pixel forward.
local M = {
    slots = {
        body = {'ghost_robe','ghost_coat','ghost_wisp'},
        face = {'ghost_round','ghost_long','ghost_skull'},
        mask = {'ghost_visor','ghost_veil','ghost_chevrons'},
    },
    parts = {},
}
local cyan = {C={0.25,0.85,1,0.85}, H={0.75,1,1,0.95}}
local violet = {C={0.65,0.4,1,0.85}, H={0.95,0.75,1,0.95}}
local gold = {C={1,0.65,0.25,0.85}, H={1,0.95,0.7,0.95}}
local function part(name,slot,palette,rows,alternate)
    local frames={rows}; if alternate then frames[2]=alternate end
    M.parts[name]={slot=slot,palette=palette,frames=frames,frameSeconds=0.5,
        origin=slot=='body' and {0,0,0} or {0,12,slot=='mask' and 1 or 0}}
end
part('ghost_robe','body',cyan,{
    '...HHH...','..HCCCH..','.HCCCCCH.','HCCCCCCCH','HCCCCCCCH',
    '.HCCCCCH.','.HCCCCCH.','.HCCCCCH.','.HCCCCCH.','HCCCCCCCH','HCCCHCCCH','.HH...HH.',
})
part('ghost_coat','body',violet,{
    '...HHH...','..HCHCH..','.HCCHCCH.','HCCHHHCCH',
    'HCCHCHCCH','.HCHCHCH.','.HCHCHCH.','.HCCHCCH.','.HCCHCCH.','.HHH.HHH.','..HC.CH..','..HH.HH..',
})
part('ghost_wisp','body',gold,{
    '...HHH...','..HCCCH..','.HCCCCCH.','HCCCCCCCH','.HCCCCCH.',
    '..HCCCH..','..HCCCH..','...HCCH..','...HCCH..','....HCH..','....HH...','....H....',
},{
    '...HHH...','..HCCCH..','.HCCCCCH.','HCCCCCCCH','.HCCCCCH.',
    '..HCCCH..','..HCCCH..','..HCCH...','..HCCH...','..HCH....','...HH....','....H....',
})
part('ghost_round','face',cyan,{
    '..HHH..','.HCCCH.','HCHCHCH','HCCCCCH','.HCHCH.','..HHH..',
},{'..HHH..','.HCCCH.','HCCCCCH','HCCCCCH','.HCHCH.','..HHH..'})
part('ghost_long','face',violet,{
    '..HHH..','..HCH..','..HCH..','..HCH..','..HCH..','..HHH..',
})
part('ghost_skull','face',gold,{
    '.HHHHH.','HCCCCCH','HC.H.CH','HCCCCCH','.H.H.H.','..HHH..',
})
part('ghost_visor','mask',gold,{
    '.......','.......','.HHHHH.','..CCC..','.......','.......',
})
part('ghost_veil','mask',cyan,{
    '.......','.......','.......','.HCHCH.','..HCH..','...H...',
})
part('ghost_chevrons','mask',violet,{
    '.......','.H...H.','..H.H..','...H...','.......','.......',
})
-- Mixed-radix enumeration reaches every combination; clients never roll RNG.
function M.Select(serial)
    local selected={}
    for _,slot in ipairs({'body','face','mask'}) do
        local choices=M.slots[slot]
        selected[slot]=choices[serial % #choices+1]
        serial=math.floor(serial/#choices)
    end
    return selected
end
return M
