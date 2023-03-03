# Este documento versará sobre los detalles de la topología en la 
# que vivirán los agentes y determinará sus interacciones.

using Graphs
using GraphPlot
using Random 
using Distributions

#export createAgentTopology, stepAgentTopology!

function createAgentTopology(properties)
    # :graphInitAlg : "simple", "barabasi", "dorogovtsev", "strogatz"
    n = properties[:n_agents]
    if properties[:graphInitAlg] == "simple"
        G = SimpleGraph(n,2*n)
    elseif properties[:graphInitAlg] == "barabasi"
        G = barabasi_albert(n,3)
    elseif properties[:graphInitAlg] == "dorogovtsev"
        G = dorogovtsev_mendes(n)
    elseif properties[:graphInitAlg] == "strogatz"
        G = watts_strogatz(n,4,0.3)
    else
        error("No se ha seleccionado un algoritmo de inicialización valido para la topología.")
    end

    # Hace falta asegurarnos de que la gráfica sea conexa antes de comenzar 
        # de no serlo la completamos y le ponemos 1 enlaces a cada nodo
        # no conectado:
    for v in vertices(G)
        if length(all_neighbors(G,v)) == 0 # está desconectado 
            new_id = v 
            while new_id == v # no self loops
                new_id = rand(1:nagents(model))
            end
            add_edge!(G, v, new_id)
        end
    end

    # quitamos self loops
    for v in vertices(G)
        rem_edge!(G,v,v)
    end
    
    return G
end

"""
    stepAgentTopology(G, properties)

función intermedia que llama la función para modificar la topología en caso
de que properties así lo pida
"""
function stepAgentTopology!(model)

    modMethod = model.properties.properties[:topologyStepMethod]

    if modMethod == "constant topology"
        ## La topología se mantiene constante a lo largo de la ejecución
    elseif modMethod == "dynamic topology"
        stepDynamicAgentTopology!(model)
    elseif modMethod == "watts strogatz"
        stepWattsStrogatzAlgorithm!(model)
    else 
        error("No se ha seleccionado un método de modificación de la topología válido.")
    end

    return 
end

"""
stepWattsStrogatzAlgorithm!(model)

model : model from Agents.jl

Enforces a small world structure to the agent topology 

Esta función nos ayuda a mantener una estructura de mundo pequeño en la topología 
de los agentes. Itera sobre todas las aristas del modelo y con una proba P 
cambia una de los extremos del arista por otro aleatorio del modelo dónde no se 
permiten aristas repetidos ni selfloops
"""
function stepWattsStrogatzAlgorithm!(model)

    p = model.properties.properties[:WattsStrogatzAlgProbability]
    G = model.properties.graph

    # iteramos sobre cada una de las aristas 
    for e in edges(G)
        # lanzamos el dado
        if rand(Bernoulli(p))
            # We do rewire the edge 

            # enforces net connectedness 
            old, keep, necessary =  validate_sort_edge(e, G)
            if necessary 
                continue
            else # decides randombly which side to disconnect
                if rand(Bernoulli(0.5))
                    # to decide which side of the edge to rewire 
                    old = src(e)
                    keep = dst(e)
                else
                    old = dst(e)
                    keep = src(e)
                end
            end
            # Search for a suitable new endge end 
            while true
                new = rand(1:nagents(model))
                new == old && break # the same old extreme
                new == keep && continue # no selfloops 
                if add_edge!(model.properties.graph,keep,new)
                    rem_edge!(model.properties.graph, keep, old) # rewire complete 
                    break
                end
            end
        end
    end # iterated over the whole edge set 
end

"""
    validate_sort_edge(e, G)

    Auxiliar function used to enforce the nets' connectedness. It find out whether
    there is a vertix in risk of been disconnected. If there is then ensures that 
    it is not disconnected. 


"""
function validate_sort_edge(e, G)
    a = src(e)
    b = dst(e)
    da = degree(G, a)
    db = degree(G, b)

    if da == 1 || db == 1
        necessary = true 
    else
        necessary = false 
    end

    if necessary
        if db == 1
            keep = b
            old = a 
        elseif da == 1
            keep = a 
            old = a
        else
            error("da == db == 1 ???")
        end
    else 
        keep = a 
        old = b 
    end 

    return old, keep, necessary
end


"""
    chopTopology(model)

distribution: es un método que en el que se rompen lazos con los agentes usando 
    la calificación del enlace para definir una probabilidad de romper el enlace. 
    Se calculan los extremos, las calificaciones más altas y más bajas y se define la más baja
    para que de una probabilidad de :baseLinkageBrakingProbability de romper el enlace. Mientras 
    que la calificación más alta corresponde con una probabilidad de 0 de romper el enlace. 

random: lanza dados Bernoulli con proba :baseLinkageBrakingProbability y si cae verdadero 
    elimina el lazo con la peor calificación que tenga el agente 
"""
function chopTopology!(model)
    properties = model.properties.properties
    baseProba = properties[:baseLinkageBrakingProbability]
    G = model.properties.graph

    if properties[:linkageBrakingMethod] == "distribution"
        # Para cada uno de los agentes hacemos lo siguiente:
        for agent in allagents(model)
            d = agent.neighborhood
            if length(keys(d)) > 2 # caso de tener suficientes l
                # calculamos al máximo y al mínimo de sus links
                maxLink = calcKeyMax(d)
                maxK = d[maxLink]
                minLink = calcKeyMin(d)
                minK = d[minLink]

                # luego para cada link lanzamos un dado bernoulli con la probabilidad adecuada
                for neighbor_id in keys(d)
                    if neighbor_id == 0
                        p = 0
                    else
                        p = calcBreakingProba(d[neighbor_id], minK, maxK, baseProba )
                    end
                    
                    # hacemos el ensayo Bernoulli 
                    if rand(Bernoulli(p))
                        # rompemos el link eliminamos de la red 
                        rem_edge!(model.properties.graph, agent.id, neighbor_id )
                        # y de la vecindad
                        delete!(agent.neighborhood, neighbor_id)
                        delete!(getindex(model, neighbor_id ).neighborhood,agent.id)
                    else
                        # no hacemos nada
                    end
                end
            else
                # en caso de no tener suficientes links (1) entonces no quita nada 
            end
        end
    elseif properties[:linkageBrakingMethod] == "random"
        # lanzamos una moneda con proba :baseLinkageBrakingProbability y si es afirmativa la 
        # la respuesta rompemos el peor de los enlaces del agente 
        for agent in allagents(model)
            d = agent.neighborhood
            if length(keys(d)) > 2 # de tener suficientes links
                # Calculamos el peor de sus links 
                minLink = calcKeyMin(d)
                # lanzamos la moneda 
                if rand(Bernoulli(baseProba))
                    # Rompemos el enlace 
                    rem_edge!(model.properties.graph, agent.id, minLink)
                    # y de la vecindad 
                    delete!(agent.neighborhood, minLink)
                    delete!(getindex(model, minLink ).neighborhood, agent.id)
                else
                    # No hacemos nada 
                end 
            else # no tengo suficientes links, no quito más 
                # 
            end
        end
    end
end

"""
    growTopology(model)

Crea nuevos enlaces entre los agentes siguiendo los métodos:

random: crea con proba :baseLinkageBrakingProbability un nuevo enlace
    con un agente tomado al azar dentro de la pila completa de agentes 

distribution: crea enlaces con recomendaciones obtenidad de los lazos 
    que ya tiene el agente. Con una probabilidad proporcional a la calificación del 
        # enlace pide recomendación de un agente al enlace, la probabilidad 
        # máxima sera igual a :baseLinkageSpawningProbability

Puede observarse que a la hora de acceder a la información de cuales son los 
vecinos de un vértice particular podríamos hacerlo tanto sobre la gráfica cómo 
sobre los diccionarios de vecindades de cada unos de los agentes. Al llegar a esta 
función ambos contienen exactamente la misma información. Pero lo hacemos 
sobre los diccionarios por una cuestión de sincronía. Al agregar nuevos links 
lo hacemos sobre la gráfica y no sobre los diccionarios ( esta información se agrega
al realizar las transacciones) de tal manera que para respetar un método síncrono 
en el cambio de la topología tenemos que hacerlo sobre los diccionarios. De no hacerlo
chocaría con múltiples decisiones de diseño dentro del modelo.
"""
function growTopology!(model)
    properties = model.properties.properties
    baseProba = properties[:baseLinkageBrakingProbability]
    G = model.properties.graph

    if properties[:linkageBrakingMethod] == "distribution"
        # Para cada uno de los agentes hacemos lo siguiente:
        for agent in allagents(model)
            d = agent.neighborhood
            if length(keys(d)) > 2 # Si se tienes 2 links o más
                # calculamos al máximo y al mínimo de sus links
                maxLink = calcKeyMax(d)
                maxK = d[maxLink]
                minLink = calcKeyMin(d)
                minK = d[minLink]

                # luego para cada link lanzamos un dado bernoulli con la probabilidad adecuada
                for neighbor_id in keys(d)
                    if neighbor_id == 0
                        p = 0
                    else
                        p = calcSpawningProbability(d[neighbor_id], minK, maxK, baseProba )
                    end
                    # hacemos el ensayo Bernoulli
                    if rand(Bernoulli(p))
                        # pedimos la recomendación de un agente a nuestro vecino
                        new_id = recommendNewLink(agent.id, neighbor_id, model)
                        # agregamos el nuevo enlace a la red
                        if agent.id != new_id
                            # No permitimos self loops
                            add_edge!(model.properties.graph, agent.id, new_id)
                        end
                    else
                        # no hacemos nada
                    end
                end
            elseif length(keys(d)) == 2 # Si tiene menos de 2 links (1) pide recomendación con proba 
                # :baseLinkageSpawningProbability

                # Problemas particulares ocurren cuando un par de agentes están conectados entre si 
                # y con nadie más 
                for neighbor_id in all_neighbors(G,agent.id) 
                    if rand(Bernoulli(baseProba))
                        new_id = recommendNewLink(agent.id, neighbor_id, model)
                        if agent.id != new_id
                            # No admitimos self loops
                            add_edge!(model.properties.graph, agent.id, new_id)
                        end
                    end
                end
            elseif length(keys(d)) == 1 # El vértice está desconectado 
                new_id = agent.id 
                while new_id == agent.id 
                    new_id = rand(1:nagents(model))
                end
                # Agregamos un nuevo enlace. No self loops.
                add_edge!(model.properties.graph, agent.id, new_id)
            else
                println("Cómo llegué aquí?")
            end
        end
    elseif properties[:linkageSpawningMethod] == "random"
        for agent in allagents(model)
            if length( keys(d) ) > 1 # Si tenemos algún link
                # agregamos uno nuevo siguiendo una proba :baseProba
                # lanzamos una model con proba baseProba, si acierta generamos un 
                # enlace nuevo 
                if rand(Bernoulli(baseProba))
                    # escogemos un índice al azar entre todos los posibles 
                    new_id = rand(1:nagents(model))
                    # Creamos el enlace con este nuevo agente
                    # solo hace falta hacerlo en la gráfica.
                    if agent.id != new_id
                        # No adminitmos self loops
                        add_edge!(model.properties.graph,agent.id, new_id )
                    end
                end
            else # Si no tenemos loops, conectamos al vértice
                # solo uno
                new_id = agent.id 
                while new_id == agent.id 
                    new_id = rand(1:nagents(model))
                end
                # No self loops
                add_edge!(model.properties.graph, agent.id, new_id)
            end
        end
    end
end

"""
stepDynamicAgentTopology!(model)

Permite que la topología de los agentes cambie en el tiempo. 

distribution: es un método que en el que se rompen lazos con los agentes usando 
    la calificación del enlace para definir una probabilidad de romper el enlace. 
    Se calculan los extremos, las calificaciones más altas y más bajas y se define la más baja
    para que de una probabilidad de :baseLinkageBrakingProbability de romper el enlace. Mientras 
    que la calificación más alta corresponde con una probabilidad de 0 de romper el enlace. 

random: lanza dados Bernoulli con proba :baseLinkageBrakingProbability y si cae verdadero 
    elimina el lazo con la peor calificación que tenga el agente 
"""
function stepDynamicAgentTopology!(model)
    # cortamos lazos 
    chopTopology!(model)
    # creamos nuevos lazos 
    growTopology!(model)

end

"""
calcBreakingProba(k, minLink, maxLink, Bp)

k: calificación
minLink: calificación más baja
maxLink: calificación más alta 
Bp: probabilidad base 

transforma la calificación de un enlace en una probabilidad para usarse en el
ensayo Bernoulli
"""
function calcBreakingProba(k, minLink, maxLink, Bp)
    up = maxLink - k
    down = maxLink - minLink

    res = up/down * Bp 
    if isnan(res)
        return Bp
    else
        return res 
    end
end

"""
calcSpawningProbability()

k: calificación
minLink: calificación más baja
maxLink: calificación más alta 
Bp: probabilidad base 

Función de calcula la probabilidad de generación de un link nuevo usando 
la calificación del link, 
"""
function calcSpawningProbability(k, minLink, maxLink, Bp)
    up = k - minLink
    down = maxLink - minLink 
    
    res = up/down * Bp 
    if isnan(res)
        return Bp
    else
        return res 
    end
end

"""
recommendNewLink(agent_id, neighbor_id, model)

agent_id
neighbor_id: id del agente recomendor 
model: modelo de agents.jl

recomienda un agente con quien establecer un enlace, si se escoge 
:linkageRecommendationMethod == "random" se toma un agente aleatorio
dentro de la vecindad de neighbor_id
:linkageRecommendationMethod == "best" recomienda al mejor dentro de 
su vecindad usando la calificación de links como base.
"""
function recommendNewLink(agent_id, neighbor_id, model)
    agent = getindex(model, neighbor_id)
    properties = model.properties.properties
    G = model.properties.graph

    recommended_id = agent_id # init
    
    if properties[:linkageRecommendationMethod] == "random"
        # Recomendar un link al azar dentro de la vecindad 
        recommended_id = rand(all_neighbors(G, neighbor_id))
        
    elseif properties[:linkageRecommendationMethod] == "best"
        d = agent.neighborhood
        recommended_id = calcKeyMax(d)
    end

    if recommended_id == agent_id # si está recomendado al peticionista 
        while recommended_id == agent_id || recommended_id == agent_id
            recommended_id = rand(1:nagents(model))
        end
    end

    return recommended_id
end

function calcKeyMax(d)
    # calcula el key de un diccionario que se corresponde con el máximo 
    maxKey = 0
    while maxKey == 0
        maxKey = rand(keys(d))
    end
    for key in keys(d)
        if d[key] ≥ d[maxKey] && key != 0
            maxKey = key
        end
    end
    return maxKey
end

function calcKeyMin(d)
    # calcula el key de un diccionario que se corresponde con el mínimo 
    minKey = 0
    while minKey == 0
        minKey = rand(keys(d))
    end
    for key in keys(d)
        if d[key] ≤ d[minKey] && key != 0
            minKey = key
        end
    end
    return minKey
end