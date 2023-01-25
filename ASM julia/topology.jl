# Este documento versará sobre los detalles de la topología en la 
# que vivirán los agentes y determinará sus interacciones.

using Graphs
using GraphPlot

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

function stepDynamicAgentTopology!(model)

    if linkageBrakingMethod == "distribution"

    
end