-- Simulation frames at 30 fps; metal is money, energy is supply.
return {
    updateFrames = 15,
    range = 120,
    investigationFrames = 30 * 30,
    investigationMoney = 300,
    investigationSupply = 0,
    factoryFrames = 90 * 30,
    factoryMoney = 2000,
    factorySupply = 1000,
    falseAccusationReward = 500,
    markerHeight = 64,
    factories = {"nimrod", "protagonassembly", "antagonassembly", "transportedassembly",
        "ground_truck_assembly", "warheadfactory", "armybase", "aicore", "blacksite", "hivemind",
        "propagandaserver", "launcher"},
}
