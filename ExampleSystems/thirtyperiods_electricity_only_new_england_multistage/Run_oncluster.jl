case = dirname(@__FILE__);

import Pkg
Pkg.instantiate()
println("Activating Package")

Pkg.activate("/home/ed0400/Macro/MacroEnergy")

include("/home/ed0400/Macro/MacroEnergy/ExampleSystems/thirtyperiods_electricity_only_new_england_multistage/run.jl");
