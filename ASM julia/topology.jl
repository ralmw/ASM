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
        # de no serlo la completamos y le ponemos 2 enlaces a cada nodo
        # no conectado:
    for v in vertices(G)
        if all_neighbors(G,v) == 0 # está desconectado 
            ### código
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
    else 
        error("No se ha seleccionado un método de modificación de la topología válido.")
    end

    return 
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

    if properties[:linkageBrakingMethod] == "distribution"
        # Para cada uno de los agentes hacemos lo siguiente:
        for agent in allagents(model)
            d = agent.neighborhud
            if length(keys(d)) > 2 # caso de tener suficientes l
                # calculamos al máximo y al mínimo de sus links
                maxLink = reduce((x, y) -> (d[x] ≥ d[y]) && (x != 0 && y != 0) ? x : y, keys(d))
                maxK = d[maxLink]
                minLink = reduce((x, y) -> (d[x] ≤ d[y]) && (x != 0 && y != 0) ? x : y, keys(d))
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
                        delete!(agent.neighborhud, neighbor_id)
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
            d = agent.neighborhud
            if length(keys(d)) > 2 # de tener suficientes links
                # Calculamos el peor de sus links 
                minLink = reduce((x,y) -> (d[x] ≤ d[y]) && (x != 0 && y != 0) ? x : y, keys[d])
                # lanzamos la moneda 
                if rand(Bernoulli(baseProba))
                    # Rompemos el enlace 
                    rem_edge!(model.properties.graph, agent.id, minLink)
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
"""
function growTopology!(model)
    properties = model.properties.properties
    baseProba = properties[:baseLinkageBrakingProbability]

    if properties[:linkageBrakingMethod] == "distribution"
        # Para cada uno de los agentes hacemos lo siguiente:
        for agent in allagents(model)
            d = agent.neighborhud
            if length(keys(d)) > 2 # Si se tienes 2 links o más
                # calculamos al máximo y al mínimo de sus links
                maxLink = reduce((x, y) -> (d[x] ≥ d[y]) && (x != 0 && y != 0) ? x : y, keys(d))
                maxK = d[maxLink]
                minLink = reduce((x, y) -> (d[x] ≤ d[y]) && (x != 0 && y != 0) ? x : y, keys(d))
                minK = d[minLink]

                # luego para cada link lanzamos un dado bernoulli con la probabilidad adecuada
                for neighbor_id in keys(d)
                    if neighbor_id == 0
                        p = 0
                    else
                        p = calcSpawningProbability(d[neighbor_id], minK, maxK, baseProba )
                    end
                    println("Problema: ", agent.id, " ", neighbor_id, " growtopo")
                    # hacemos el ensayo Bernoulli 
                    if rand(Bernoulli(p))
                        # pedimos la recomendación de un agente a nuestro vecino
                        new_id = recommendNewLink(neighbor_id, model)
                        # agregamos el nuevo enlace a la red 
                        if agent.id != new_id
                            # No permitimos self loops 
                            add_edge!(model.properties.graph, agent.id, new_id)
                        end
                    else
                        # no hacemos nada
                    end
                end
            else # Si tiene menos de 2 links (1) pide recomendación de manera determinista
                # falla si no se satisface esta condición 
                for neighbor_id in keys(d)
                    if neighbor_id != 0
                        new_id = recommendNewLink(neighbor_id, model)
                        if agent.id != new_id
                            # No admitimos self loops
                            add_edge!(model.properties.graph, agent.id, new_id)
                        end
                    end
                end
            end
        end
    elseif properties[:linkageSpawningMethod] == "random"
        for agent in allagents(model)
            if lenght(keys(agent.neighborhud)) > 2 # Si tenemos suficientes links
                # agregamos uno nuevo siguiendo una probabilidad
                # lanzamos una model con proba baseProba, si acierta generamos un 
                # enlace nuevo 
                if rand(Bernoulli(baseProba))
                    # escogemos un índice al azar entre todos los posibles 
                    n_agents = nagents(model)
                    new_id = rand(1:n_agents)
                    # Creamos el enlace con este nuevo agente
                    # solo hace falta hacerlo en la gráfica.
                    if agent.id != new_id
                        # No adminitmos self loops
                        add_edge!(model.properties.graph,agent.id, new_id )
                    end
                end
            else # agregamos de manera determinista un nuevo link en caso de tener 
                # solo uno
                new_id = rand(1:n_agents)
                if agent.id != new_id 
                    # no adminitmos self loops
                    add_edge!(model.properties.graph, agent.id, new_id)
                end
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

    return up/down * Bp
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
    return up/down * Bp
end

"""
recommendNewLink(neighbor_id, model)

neighbor_id: id del agente recomendor 
model: modelo de agents.jl

recomienda un agente con quien establecer un enlace, si se escoge 
:linkageRecommendationMethod == "random" se toma un agente aleatorio
dentro de la vecindad de neighbor_id
:linkageRecommendationMethod == "best" recomienda al mejor dentro de 
su vecindad usando la calificación de links como base.
"""
function recommendNewLink(neighbor_id, model)
    agent = getindex(model, neighbor_id)
    properties = model.properties.properties
    
    if properties[:linkageRecommendationMethod] == "random"
        cont = true
        new_id = 0
        while cont 
            new_id = rand(keys(agent.neighborhud))
            if new_id != 0
                cont = false
            end
        end
        print("Problema reco: ", neighbor_id, " ")
        println(new_id)
        return new_id
        
    elseif properties[:linkageRecommendationMethod] == "best"
        d = agent.neighborhud
        maxLink = reduce((x, y) -> (d[x] ≥ d[y]) && (x != 0 && y != 0) ? x : y, keys(d))
        return maxLink
    end

end
