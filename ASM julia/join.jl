# este documento me ayudará a justar todos los elementos para la ejecucion del
# modelo

include("reglas.jl")
include("descriptor.jl")
include("specialist.jl")
include("agentes.jl")

using .Reglas, .Descriptors, .Specialists
using Plots, StatsPlots

reglas = createRules(properties)
GA(reglas)

des.des

predict( reglas,des.des)

des = initializeDescriptor(properties)
des = updateDescriptor!(10000,des)
