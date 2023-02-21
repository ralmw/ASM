## De aquí en adelante va mi código

using Agents, Random
using Distributions

export initialize_model, agent_step!, model_step!

mutable struct Wealth
    cash::Float64
    stock::Float64
end # mutable struct

"""
    mutable struct Trader <: AbstractAgent


    Estructura que constituye a un agente dentro del modelo.

    la propiedad des hace referencia al descriptor propio 
    del agente, cada agente tendrá su propio registro de los precios 
"""
mutable struct Trader <: AbstractAgent
    id::Int
    pos::Tuple{Int,Int}
    wealth::Wealth
    reglas
    properties::Dict
    GA_time::Int # when 0 it is time to execute the GA alg
    des
    neighborhood::Dict # Se almacena si el vínculo con el vecino es beneficioso 
end # mutable struct

function initialize_model(properties;
    n_agents = 1000,
    dims = (20,20),
)

    space = GridSpace(dims, periodic = false)
    # Model properties contain the grass as two arrays: Whether it is fully
    # grown and the time to regrow. Also have static parameter 'regrowth_time'.
    # Notice how he properties are a 'NamedTuple' to ensure type stability
    prop = (
        # aquí debo crear al descriptor-especialista como atributo del modelo
        des = initializeDescriptor(properties),
        properties = properties,
        graph = createAgentTopology(properties)
    )
    model = ABM(Trader, space; properties = prop, scheduler = Schedulers.randomly)
    id = 0
    for _ in 1:n_agents
        id += 1
        # aquí debo llenar los atributos de mis agentes
        reglas = createRules(properties)
        time = floor(Int,rand(Exponential(properties[:gaActivationFrec])))
        agent = Trader(id, (0,0), Wealth(10000.0, properties[:initStock]), reglas, properties, time,
            initializeDescriptor(properties), Dict(0 => 0.0) )
        add_agent!(agent, model)
    end

    return model
end # function

"""
    model_step!(model)

Esta función juego el papel de especialista.
Calcula el nuevo precio y actualiza el descriptor.
También actualiza la riqueza de los agentes tomando en cuenta el nuevo precio,
su posición optima siguiente el modelo microeconómico y su efectivo siguiendo
la tasa de interés dada.
"""
function model_step!(model)
    # especialista

    if model.properties.properties[:specialistType] == "local"

        # Veamos la topología
        G = model.properties.graph
        nodelabels = 1:nv(G)
        gplot(G, nodelabel = nodelabels)

        # Utiliza la topología para calcular las transacciones
        Transactions = calculateTransactions(model)
        TransDict, PriceDict = unzipTransactions(Transactions, model.properties.properties)
        # Se actualizan riquezas y se juzgan vínculos
        executeTransactions!(model, TransDict, PriceDict)
        updateDescriptors!(model,PriceDict)

        # Se modifica la topología de los agentes 
        stepAgentTopology!(model)
    elseif model.properties.properties[:specialistType] == "global"


        
        #El método detallado en los artículos de LeBaron et. al. 

        # recopila la información de los agentes
        agents = allagents(model)
        info = [ predict(agent.reglas, model.properties.des.des ) for agent in agents]
        dividendo = model.properties.des.dividendo[end]
        precio = model.properties.des.precios[end]
        properties = model.properties.properties
        #newPrice = -calculateNewPrice( info, dividendo, properties )
        #newPrice = subasta(info, dividendo, properties, precio)
        newPrice = newPriceByAvePred(info, dividendo, properties, precio)
        # una vez calculado el nuevo precio actualiza su información con esto
        updateDescriptor!(newPrice, model.properties.des)
        # a continuación actualiza la riqueza de los agentes de acuerdo al nuevo precio
        updateWealth!(agents, newPrice, info, dividendo, properties ) 
    else
        error("No se ha seleccionado un tipo de espacialista válido.")
    end

end # function

"""
    updateWealth!(agents, P, info, dividendo, properties)

Actualiza las poseciones del agente de acuerdo al nuevo precio alcanzado.
come:

wealth: objeto de la struct Wealth del agente
P: nuevo precio
predictor: el predictor usado por el agente
properties: nuestro conocido diccionario de variables globales

Actualiza la riqueza de los agentes tomando en cuenta el nuevo precio,
calcula la posición ideal de los agentes al nuevo precio y determinar las
ordenes de compra y venta de cada agente. Por lo general no habrá liquides,
siempre algunas de las dos será mayor, las órdenes de venta o las de compra,
para resolver esto problema raciona el lado que no pueda satisfacerse otorgando
a cada agente una parte de las acciones disponibles proporcional al tamaño de su
petición con respecto al número total de peticiones.
"""
function updateWealth!(agents, P, info, dividendo, properties)
    imbalances = zeros(length(agents))
    i = 0
    for agent in agents
        i += 1
        # calculate holding
        holding = calculateOptimalHolding(P, info[i], dividendo, properties)
        imbalances[i] = holding - agent.wealth.stock
    end
    # suma las ventas y las compras por separado
    compras = imbalances .> 0
    ventas = .!compras

    a = sum(imbalances[compras])
    b = sum(imbalances[ventas])

    # selecciona el que sume menos
    menor = a < -b ? compras : ventas
    C = a < -b ? a : b # a racionar
    divisor = a > -b ? a : -b # peticiones no satisfechas

    # eso quiere decir que quiero resolver todas las ventas bonito y las
    # compras las quiero racionar
    i = 0
    for agent in agents
        i += 1
        if menor[i] # no se racionará
            agent.wealth.stock = imbalances[i] + agent.wealth.stock # = holding
            agent.wealth.cash = agent.wealth.cash - P*imbalances[i]
        else # sí se racionará
            agent.wealth.stock = agent.wealth.stock + C*imbalances[i]/divisor
            agent.wealth.cash = agent.wealth.cash - P*C*imbalances[i]/divisor
        end
        # actualiza el efectivo de acuerdo a la tasa de interés
        agent.wealth.cash = agent.wealth.cash*(1+properties[:interestRate])
    end
    return
end # function

"""
    agent_step!(agent, model)

Esta función es la ejecución en el tiempo de los agentes, el equivalente a go
en Netlogo. La labor de esta función está en actualizar las reglas del agente
de acuerdo al último precio calculado almacenado en model.properties.price.
"""
function agent_step!(agent, model)
    # primero actualiza el fitness de las reglas usando la información del precio
    updateFitness!(model.properties.des, agent.reglas)
    agent.GA_time -= 1

    # si es el momento, ejecuta el algoritmo genético
    if agent.GA_time <= 0
        agent.reglas = GA(agent.reglas)
        agent.GA_time = 1 + floor(Int,rand(Exponential(agent.properties[:gaActivationFrec])))
    end
    return
end # function
