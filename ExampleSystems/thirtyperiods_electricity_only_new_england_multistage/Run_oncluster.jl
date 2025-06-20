case = dirname(@__FILE__);

import Pkg
println("Activating Package")

Pkg.activate("/home/ed0400/Macro")

include("/home/ed0400/Macro/ExampleSystems/thirtyperiods_electricity_only_new_england_multistage/run.jl");