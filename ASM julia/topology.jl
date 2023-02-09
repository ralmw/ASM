# Este documento versará sobre los detalles de la topología en la 
# que vivirán los agentes y determinará sus interacciones.

using Graphs
using GraphPlot
using Random 
using Distributions

G = Graph(3)

add_edge!(G,1,2)
add_edge!(G,1,3)

gplot(G,nodelabel=1:3)



G = smallgraph("house")

nvert = nv(G)
nedges = ne(G)

gplot(G,nodelabel=1:nvert, edgelabel=1:nedges)


for e in edges(G)
    #println(e)
    u,v = src(e), dst(e)
    println(u,"\t",v, "\t",e)
end

 adjacency_matrix(G)


# Gráfica simple
G = SimpleGraph(20,30)
gplot(G)

 # Siguiendo barabasi-albert, conexa
G = barabasi_albert(40,3)
gplot(G)


# Dorogovtsev-Mendes de triángulos, conexa
G = dorogovtsev_mendes(40)
gplot(G)

# Strogatz de mundo pequeño, conexa
G = watts_strogatz(20, 4, 0.3)
gplot(G)

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
            # calculamos al máximo y al mínimo de sus links
            maxLink = reduce((x, y) -> d[x] ≥ d[y] ? x : y, keys(d))
            maxK = d[maxLink]
            minLink = reduce((x, y) -> d[x] ≤ d[y] ? x : y, keys(d))
            minK = d[minLink]

            # luego para cada link lanzamos un dado bernoulli con la probabilidad adecuada
            for neighbor_id in keys(d)
                p = calcBreakingProba(d[neighbor_id], minK, maxK, baseProba )
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
        end
    elseif properties[:linkageBrakingMethod] == "random"
        # lanzamos una moneda con proba :baseLinkageBrakingProbability y si es afirmativa la 
        # la respuesta rompemos el peor de los enlaces del agente 
        for agent in allagents(model)
            d = agent.neighborhud
            # Calculamos el peor de sus links 
            minLink = reduce((x,y) -> d[x] ≤ d[y] ? x : y, keys[d])
            # lanzamos la moneda 
            if rand(Bernoulli(baseProba))
                # Rompemos el enlace 
                rem_edge!(model.properties.graph, agent.id, minLink)
            else
                # No hacemos nada 
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
function growTopology(model)
    properties = model.properties.properties
    baseProba = properties[:baseLinkageBrakingProbability]

    if properties[:link]
    
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