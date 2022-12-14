using Agents

# schellings segregation model

space = GridSpace((10,10))

mutable struct Schelling <: AbstractAgent
    id::Int
    pos::Tuple{Int,Int}
    group::Int
    happy::Bool
end # struct

properties = Dict(:min_to_be_happy => 3 )

model = AgentBasedModel(Schelling, space; properties)

model

scheduler = Schedulers.randomly
t(model, s) = s == 3
model = initialize()
step!(model, agent_step!, dummystep, t )

model = AgentBasedModel(Schelling, space; properties, scheduler)

function initialize(; N = 320, M=20, min_to_be_happy = 3)
    space = GridSpace((M,M))
    scheduler = Schedulers.randomly
    properties = Dict(:min_to_be_happy => min_to_be_happy )
    model = AgentBasedModel(Schelling, space; properties, scheduler)

    # we add Agents
    for n in 1:N
        agent = Schelling(n,(1,1), n<N/2 ? 1 : 2, false)
        add_agent_single!(agent, model)
    end
    return model
end


model = initialize()

function agent_step!(agent, model)
    agent.happy && return
    nearby_same = 0

    for neighbor in nearby_agents(agent, model)
        if agent.group == neighbor.group
            nearby_same += 1
        end
    end

    if nearby_same >= model.min_to_be_happy
        agent.happy = true
    else
        move_agent_single!(agent, model)
    end
    return
end

step!(model, agent_step!)

using InteractiveDynamics, GLMakie

fig, _ = abm_plot(model)
display(fig)

groupcolor(agent) = agent.group == 1 ? :blue : :orange
groupmarker(agent) = agent.group == 1 ? :circle : :rect

fig, _ = abm_plot(model; ac = groupcolor, am = groupmarker)
display(fig)

model = initialize()
abm_play(
    model, agent_step!;
    ac = groupcolor, am = groupmarker, as = 12
)

model.properties

# lo primero del día de hoy es replicar el modelo de presa depredador
# para entender de qué manera se usan varios tipos de agentes y cómo se
# coordinan sus movimientos.






Lo que yo puedo hacer en mi modelo es hacer una struct que pueda aplicar a
ambos tipos de agentes y distinguirlo usando símbolos tal cómo lo hacen
aqui, y también hacerme un par de funciones de ayuda para que
hacer uso de ellas sea mucho más sencillo. Además de llenar los campos que
un tipo de agente no necesite con nothing por simplicidad.
Yo creo que puede funcionar bastante bien

#%%
#Aquí comienza el modelo de presa depredador

using Agents, Random

mutable struct SheepWolf <: AbstractAgent
    id::Int
    pos::Dims{2}
    type::Symbol # :sheep or :wolf
    energy::Float64
    reproduction_prob::Float64
    Δenergy::Float64
end

Sheep(id, pos, energy,repr, Δe) = SheepWolf(id, pos, :sheep, energy, repr, Δe)
Wolf(id, pos, energy, repr, Δe) = SheepWolf(id, pos, :wolf, energy, repr, Δe)

function initialize_model(;
    n_sheep = 100,
    n_wolves = 50,
    dims = (20,20),
    regrowth_time = 30,
    Δenergy_sheep = 4,
    Δenergy_wolf = 20,
    sheep_reproduce = 0.04,
    wolf_reproduce = 0.05,
    seed = 23182,
)

    rng = MersenneTwister(seed)
    space = GridSpace(dims, periodic = false)
    # Model properties contain the grass as two arrays: Whether it is fully
    # grown and the time to regrow. Also have static parameter 'regrowth_time'.
    # Notice how he properties are a 'NamedTuple' to ensure type stability
    properties = (
        fully_grown = falses(dims),
        countdown = zeros(Int, dims),
        regrowth_time = regrowth_time,
    )
    model = ABM(SheepWolf, space; properties, rng, scheduler = Schedulers.randomly)
    id = 0
    for _ in 1:n_sheep
        id += 1
        energy = rand(1:(Δenergy_sheep*2))-1
        sheep = Sheep(id, (0,0), energy, sheep_reproduce, Δenergy_sheep)
        add_agent!(sheep, model)
    end
    for _ in 1:n_wolves
        id += 1
        energy = rand(1:(Δenergy_wolf*2)) - 1
        wolf = Wolf(id, (0,0), energy, wolf_reproduce, Δenergy_wolf)
        add_agent!(wolf, model)
    end
    for p in positions(model) # random grass initial growth
        fully_grown = rand(model.rng, Bool)
        countdown = fully_grown ? regrowth_time : rand(model.rng, 1:regrowth_time) - 1
        model.countdown[p...] = countdown
        model.fully_grown[p...] = fully_grown
    end
    return model
end # function

function sheepwolf_step!(agent::SheepWolf, model)
    if agent.type == :sheep
        sheep_step!(agent, model)
    else # then 'agent.type == :wolf'
        wolf_step!(agent, model)
    end
end

function sheep_step!(sheep, model)
    walk!(sheep, rand, model)
    sheep.energy -= 1
    sheep_eat!(sheep, model)
    if sheep.energy < 0
        kill_agent!(sheep, model)
        return
    end
    if rand(model.rng) <= sheep.reproduction_prob
        reproduce!(sheep, model)
    end
end

function wolf_step!(wolf, model)
    walk!(wolf, rand, model)
    wolf.energy -= 1
    agents = collect(agents_in_position(wolf.pos, model))
    dinner = filter!(x -> x.type == :sheep, agents)
    wolf_eat!(wolf, dinner, model)
    if wolf.energy < 0
        kill_agent!(wolf, model)
        return
    end
    if rand( model.rng) <= wolf.reproduction_prob
        reproduce!(wolf, model)
    end
end

function sheep_eat!(sheep, model)
    if model.fully_grown[sheep.pos...]
        sheep.energy += sheep.Δenergy
        model.fully_grown[sheep.pos...] = false
    end
end

function wolf_eat!(wolf, sheep, model)
    if !isempty(sheep)
        dinner = rand( model.rng, sheep)
        kill_agent!(dinner, model)
        wolf.energy += wolf.Δenergy
    end
end

function reproduce!(agent, model)
    agent.energy /= 2
    id = nextid(model)
    offspring = SheepWolf(
    id,
    agent.pos,
    agent.type,
    agent.energy,
    agent.reproduction_prob,
    agent.Δenergy,
    )
    add_agent_pos!(offspring, model)
    return
end

function grass_step!(model)
    @inbounds for p in positions(model)
        if !(model.fully_grown[p...])
            if model.countdown[p...] ≤ 0
                model.fully_grown[p...] = true
                model.countdown[p...] = model.regrowth_time
            else
                model.countdown[p...] -= 1
            end
        end
    end
end


model = initialize_model()

using InteractiveDynamics, CairoMakie ,GLMakie

offset(a) = a.type == :sheep ? (-0.7, -0.5) : (-0.3, -0.5)
ashape(a) = a.type == :sheep ? :circle : :utriangle
acolor(a) = a.type == :sheep ? RGBAf0(1.0, 1.0, 1.0, 0.8) : RGBAf0(0.2, 0.2, 0.2, 0.8)

grasscolor(model) = model.countdown ./ model.regrowth_time

heatkwargs = ( colormap = [:brown, :green], colorrange = ( 0,1))

plotkwargs = (
    ac = acolor,
    as = 15,
    am = ashape,
    offset = offset,
    heatarray = grasscolor,
    heatkwargs = heatkwargs,
)

fig, _ = abm_plot(model; plotkwargs...)
display(fig)

model = initialize_model()
abm_play(
    model, sheepwolf_step!, grass_step!;
    plotkwargs...
)

sheep(a) = a.type == :sheep
wolves(a) = a.type == :wolf
count_grass(model) = count(model.fully_grown)

model = initialize_model()
n = 500
adata = [(sheep,count), (wolves, count)]
mdata = [count_grass]
adf, mdf = run!(model, sheepwolf_step!, grass_step!, n; adata, mdata)

adf
mdf
