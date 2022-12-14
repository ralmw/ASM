# Este el algoritmo genético del modulo reglas.

# la declaración deberá ser de la siguiente manera aunque no funcione de manera
# global.

# quiero que desde los agentes pueda llamar.
predice(des, reglas) y me regrese la predicción correspondiente a la mejor regla
GA(reglas) y que ejecute el algoritmo genético sobre las reglas.

Estructura de mi algoritmo genético.::::::::::::::::::::

inicio
    clusterización
    poda para mantener el tamaño de los clusters
    poda de los peores usando escalamiento sigma sobre clusters
    reproducción con torneo y escalamiento sigma
fin

reglas = createRules(properties)
reglas = GA(reglas)


using Random
using Distributions

using Clustering
#using Plots Fue usado para confirmar el correcto funcionamiento
#using StatsPlots Usado para ver el dendrograma
using Statistics

using StatsBase





#%% Aquí empiezan las funciones relacionadas al algoritmo evolutivo.

# mi dado para la inicialización de los bits
v = [0.05,0.05,0.9]
q = DiscreteNonParametric( [0,1,2], v )
rand(q, 100)

mutable struct Rule
    conditional
    realConditional
    predictor
    fitness
    variance
    properties
    cluster
    lastActive
end # struct

mutable struct Fitness
    real
    scaled
end # struct

struct LittleRule
    id::Int8
    fitness::Float64
end # struct

#Entonces ahora necesito una función que construya mis reglas de la manera que quiero.

"""
    createRule(properties)

Esta función será el constructor de mis reglas. Aqui se inicializarán las
reglas usando los parametros properties otorgados al constructor
"""
function createRule(properties)
    conditional = rand(q, properties[:nBits])# vector con los bits iniciales generados estocásticamente
    # es aquí también donde debo ajustar para que sean UInt8

    for i in 1:properties[:nBitsReales] # aquí rectifico los bits reales
        if conditional[i] == 0
            conditional[i] = 1 # estos bits serán solamente 1 o 2, uso o no
        end
    end
    conditional = UInt8.(conditional)
    realConditional = rand( properties[:nBitsReales] ) .+ 0.25
    # ya tengo la parte conficional correctamente inicializada.
    # ahora inicializo la parte predictora. en qué intervalos era?
    a = rand( Uniform( 0.5,2 ) ) # desde la mitad del valor actual al doble
    b = rand( Uniform( -10.0, 19.0 ) )
    predictor = [a,b]
    fitness = Fitness( rand() ,1) #fitness aleatorio
    variance =  1
    cluster = 1
    return Rule(conditional, realConditional, predictor,
        fitness, variance, properties, cluster, 0 )
end # function

"""
    createRules(properties)

Esta es la función usada durante la creación del agente para crear su
lista inicial de reglas.
"""
function createRules(properties)
    return [ createRule(properties) for _ in 1:properties[:nReglas] ]
end # function

"""
    GA(reglas)

Función que llama el agente para ejecutar el algoritmo genético
"""
function GA(reglas)

    reglas, clusters, ct = clusterize(reglas)
    reglas, clusters, ct = podaPorCluster(reglas, clusters, ct)
    reglas, clusters, ct = podaSigma(reglas, clusters, ct)
    hijos = calculateProgeny(reglas, clusters)

    append!(reglas, hijos)

    return reglas
end # function

"""
    clusterize(reglas)

come el vector de reglas.

regresa
return reglas, clusters, ct

Esta es la primera parte de mi algoritmo genético.
Aplico clusterización jerárquica sobre mis reglas y asigna cada regla a
un cluster, regresa el vector clusters que funciona cómo un índice para
los clusters y también el vector ct que contiene esencialmente la misma
información pero que se utilizará posteriormente

"""
function clusterize(reglas)
    # crea matriz de distancias
    M = zeros(Int8, length(reglas), length(reglas) )

    for i in CartesianIndices(M)
        a = reglas[i[1]].conditional # primera y segunda reglas
        b = reglas[i[2]].conditional
        M[i] = sum(a .!= b) # distancia de hamming
    end
    # M, la matriz de distancias obtenida

    # realiza clusterización y corta
    hc = hclust(M, linkage=:complete)
    #plot(hc) para observar el dendrograma
    ct = cutree(hc, k = properties[:kClusters] )

    # Ahora asignar las reglas a sus correspondientes cluster
    for i in 1:length(reglas)
        reglas[i].cluster = ct[i]
    end

    # índice de los clusters
    clusters = [[] for _ in 1:properties[:kClusters]]
    for i in eachindex(ct)
        push!(clusters[ ct[i] ], i )
    end
    # clusters el índice obtenido

    return reglas, clusters, ct
end # function

"""
    podaPorCluster(reglas, clusters, ct)

usando la información obtenida anteriormente sobre los clusters
limíta el tamaño de los clusters a la cantidad indicada en
properties[:maxPerCluster]
"""
function podaPorCluster(reglas, clusters, ct)
    # crea lista de reglas a eliminar
    toEliminate = []
    for cluster in clusters
        #toEliminate = []
        if length(cluster) > properties[:maxPerCluster]
            # crea una lista de indices y fitness de las reglas
            temp = []
            for ind in cluster
                x = LittleRule(ind, reglas[ind].fitness.real)
                push!(temp , x)
            end
            #temp contiene todas los índices y fitness de las reglas del cluster
            sort!(temp, rev = true, by = x -> x.fitness )
            # ahora que está ordenado puedo eliminar tantos coómo hagan falta
            temp = temp[properties[:maxPerCluster]+1:end]
            # y ahora almaceno estos en algún lado
            append!(toEliminate, temp)
        end
    end
    # toEliminate las reglas a ser eliminadas para mantener la diversidad

    # y ahora depuramos nuestra pequeña lista de reglas.
    sort!(toEliminate, rev = false, by = x -> x.id )
    #toEliminate
    temp = [ i.id for i in toEliminate ]
    deleteat!( reglas, temp )
    #reglas nuestra lista actualizada de reglas

    # actualizo la información sobre clusters en ct
    deleteat!( ct, temp )
    #ct

    # recalculo el índice de clusters
    clusters = [[] for _ in 1:properties[:kClusters]]
    for i in eachindex(ct)
        push!(clusters[ ct[i] ], i )
    end
    #clusters

    return reglas, clusters, ct
end # function

"""
    podaSigma(reglas, clusters, ct)

Esta función elimina a los peores individuos del conjunto de reglas,
elimina a las peores usando escalamiento sigma sobre clusters y respetando
a las mejores reglas de todos los clusters.

respetará a las mejores puediendo eliminar aquellas reglas cuyo fitness.scaled
sea mayor a uno
"""

function podaSigma(reglas, clusters, ct)
    properties = reglas[1].properties
    # escalamiento sigma sobre clusters
    for cluster in clusters
        # primero hay que calcular los valores necesarios que creo que son
        # desviación estandar y varianza
        x = mean([ reglas[id].fitness.real for id in cluster ] )
        σ = std( [ reglas[id].fitness.real for id in cluster ], corrected = false )
        for id in cluster
            if σ != 0
                reglas[id].fitness.scaled = 1 + (reglas[id].fitness.real - x)/(2*σ)
            else
                reglas[id].fitness.scaled = 1
            end
        end
    end
    # las reglas ya tienen fitness.scaled actualizado

    # ahora ordenamos las reglas según este escalamiento
    v = sortperm(reglas, rev = true, by = x -> x.fitness.scaled )
    ct = ct[v]
    reglas = reglas[v]

    # mi intención con esta pieza de código es tener suficiente espacio
    # en mi vector de reglas para calcular el número de hijos
    # estipulado. Cuando después de la clusterización no hay todavía
    # suficiente espacio es que esta parte del código se vuelve
    # importante

    # quiero ver en primer lugar cuanto tengo que borra todavía
    #properties[:minNumHijos] # es cuanto espacio quiero tener
    #properties[:nReglas] - length(reglas) # es cuanto espacio tengo

    if properties[:minNumHijos] > properties[:nReglas] - length(reglas)
        #entonces todavía tengo que eliminar reglas y para ello primero
        # calculo cuantas reglas tengo todavía que eliminar que será igual a
        n = properties[:minNumHijos] - ( properties[:nReglas] - length(reglas))

        #y simplemente los corto
        ind = length(reglas) - n # el índice para hacer el corte
        # pero todavía no, hay que tomar en cuenta el elitismo

        i = length(reglas)
        while reglas[i].fitness.scaled < 1
            i -= 1
        end
        i += 1 # el punto relevante para el elitismo

        reglas = reglas[ 1:max(ind, i) ] # y ya
        ct = ct[1:max(ind, i)]

    else
        # no hago nada pues ya tengo suficiente espacio
    end

    # reglas; lista actualizada de reglas
    # y ya tengo espacio para mis nuevos hijitos :D

    # y recalculamos los clusters
    clusters = [[] for _ in 1:properties[:kClusters]]
    for i in eachindex(ct)
        push!(clusters[ ct[i] ], i )
    end
    # clusters; índice actualizado

    return reglas, clusters, ct
end # function



# reproducción por torneo y escalamiento sigma

"""
    findFather(reglas)

Esta función selecciona a un padre usando selección por torneo.
Selecciona 10 candidatos al azar y escoje a aquel que tenga
fitness.scaled mayor

mientras menor sea el tamaño de la muestra más aleatoria será la
selección

recibe el vector de reglas y a n que es el tamaño del torneo
que está contenido en properties[:tamañoTorneo]

regresa el índice del padre seleccionado ganador
"""
function findFather(reglas, n)
    itr = sample( 1:length(reglas), n, replace = false )
    ind = argmax( x -> reglas[x].fitness.scaled, itr )
    return ind
end



# a continuación debo determinar la forma que tomará mi alg evo
# haré una lista de hijos y ahí almacenaré a todos los hijos antes
# de agregarlos a la lista final de reglas
# clustersInfo contiene la espeificidad de que cada uno de los clusters



"""
    calcClustInfo(reglas, clusters)

Calcula la especificidad de las reglas y lo regresa en un vector
"""
function calcClustInfo(reglas, clusters)
    clustersInfo = zeros( length(clusters) )

    for i in 1:length(clusters)
        # calculate specificity of every cluster
        temp = zeros(Float64, length(clusters[i]) )
        cont = 1
        for j in clusters[i]
            # calcula la especificidad de cada regla y guardala
            temp[cont] = sum( 2 .== reglas[j].conditional )/length(reglas[1].conditional)
            cont += 1
        end
        clustersInfo[i] = mean(temp)
    end
    clustersInfo = 1 .- clustersInfo
    return clustersInfo
end # function

# en clustersInfo ya tengo la información de los clusters
# y con información me refiero a la especificidad de cada uno de los clusters
# ahora debo darle esta información a la siguiente parte del código
# es decir, que tengo que programar las diferentes matrices de markov que usaré
# busqué un poco sobre cadenas de markov en julia y están pensadas para
# cosas un tanto más de cadenas de Markov así que yo lo haré simplemente
# a través de dados

"""
    calculateProgeny(reglas, clusters)

Esta función calcula los hijos y los regresa en una lista
"""
function calculateProgeny(reglas, clusters)
    properties = reglas[1].properties
    hijos = []
    clustersInfo = calcClustInfo(reglas, clusters)
    fitnessAve = mean([reglas[i].fitness.real for i in 1:length(reglas)])

    while length(reglas) + length(hijos) < properties[:nReglas]
        # selecciona método de reproducción, mutación o cruza
        if rand(Bernoulli(0.2))
            # mutación
            hijo = mutate(reglas, clustersInfo, fitnessAve) # ya deben estar calculados
        else
            # cruza
            hijo = crossover(reglas, fitnessAve)
        end
        push!(hijos, hijo )
    end
    return hijos
end # function

"""
    mutate(reglas, clustersInfo, fitnessAve)

Come la lista de reglas, clustersInfo que es la especificidad
de cada cluster y fitnessAve que es el fitness.real promedio de
la población total de reglas

Esta función llevará a cabo todos los pasos necesarios para
obtener un hijo a través de mutación, usará la especificidad del cluster
del padre, y usará mutación polinomial para la parte real de la parte
condicional pero también usará una distribución Cauchy cortada para la parte
predictora de las reglas. Esto para que la exploración al rededor del
padre en la parte condicional sea mas controlada pero para que la
mutación en la parte predictora permita cambios grandes en la función de
la regla, cómo que si una regla predice a la baja entonces un hijo suyo pueda
predecir a la alta.

documentation
"""
function mutate(reglas, clustersInfo, fitnessAve)
    padre = reglas[findFather(reglas, properties[:tamañoTorneo])]
    conditional = padre.conditional
    realConditional = padre.realConditional
    predictor = padre.predictor
    # muta la parte condicional
    conditional = mutateConditional(conditional, clustersInfo[padre.cluster] )
    # muta la parte realConditional, la parte condicional real de la regla
    realConditional = mutateReals(realConditional)
    # muta la parte predictora de la regla
    predictor = mutatePredictor(predictor)
    fit = Fitness(fitnessAve, 0)
    hijo = Rule(conditional, realConditional, predictor, fit, 1,
        padre.properties, padre.cluster,0 )

    return hijo
end

"""
    mutateConditional(conditional, E)

recibe:

conditional = vector de 3-Bits
E = especificidad del cluster

Esta función lleva a cabo la muta binaria con respecto a la especificidad del
cluster de la regla padre.
La probalidad de 2 se ajusta con respecto a lo que marque el cluster
al que el padre pertenece. La idea es la de Ehrentreich con su operador
de mutación adaptativo pero esta vez a nivel cluster.
"""
function mutateConditional(cond, E)
    conditional = deepcopy(cond)
    for i in 1:length(conditional)
        if rand( Bernoulli(2/length(conditional) ) )
            # muta el bit
            if conditional[i] == 0
                # probas
                if rand(Bernoulli(E)) # == true
                    conditional[i] = 1
                else
                    conditional[i] = 2
                end
            elseif conditional[i] == 1
                # más probas
                if rand(Bernoulli(E))  # == true
                    conditional[i] = 0
                else
                    conditional[i] = 2
                end
            else # conditional[i] == 2
                # probas finales
                if rand(Bernoulli(E)) # == true
                    if rand(Bernoulli()) # == true
                        conditional[i] = 1
                    else
                        conditional[i] = 0
                    end
                else
                    conditional[i] = 2
                end

            end
        end
    end
    return conditional # no hay problemas de alocación de memoria?
end # function

"""
    mutateReals(rule)

Esta función lleva a cabo la muta polinomial para la parte condicional
real de las reglas.

Los parámetros bajo los cuales se realiza la mutación polinomial está
hardcodeados aquí.


"""
function mutateReals(realCond)
    # operaciones
    realConditional = deepcopy(realCond)
    η = 120
    lb = 0.25
    ub = 1.25

    # dado que serán pocos bits preguntaré uno por uno
    for i in 1:length(realConditional)
        if rand(Bernoulli(1/length(realConditional)))
            # muta
            v = realConditional[i]
            u = rand()
            δ = min(v-lb,ub-v)/(ub-lb)
            if u < 0.5
                Δ = (2*u + (1-2*u)*((1-δ)^(η+1)) )^(1/(η + 1)) - 1
            else
                Δ = 1-(2*(1-u) + 2*(u-0.5)*((1-δ)^(η + 1)) )^(1/(η + 1))
            end
            realConditional[i] = v + Δ*(ub-lb)
        end
    end
    return realConditional
end # function

"""
    mutatePredictor(predic)

Aquí se mutará la parte predictora de la regla. Se una una distribución
Cauchy para aprovechar sus colas largas y permitir que la regla mutada cambie
completamente su comportamiento en cuanto a la predicción.

se usará la siguiente ecuación

#p = p .+ ϵ

donde ϵ sigue una distribución Cauchy y donde limitaremos los valores
posibles al intervalo [0.5, 2] para el parámetro a y
[-20,20] para el parámetro b.

Note la diferencia a los valores originales del modelo para a
que son [0.7, 1.2] y [-10,20].
"""
function mutatePredictor(predic)
    predictor = deepcopy(predic)
    ϵ = [exp(rand(Cauchy(0,0.28711))),rand(Cauchy(0,8.2842))]
    predictor = predictor .+ ϵ
    predictor[1] = max(0.5, predictor[1])
    predictor[1] = min( 2,  predictor[1])
    predictor[2] = max(20,  predictor[2])
    predictor[2] = min(20,  predictor[2])
    # una vez normalizado me regresa el resultado.
    return predictor
end



"""
    crossover(reglas, aveFitness)

Esta función es la responsable de calcular hijos usando cruza
"""
function crossover(reglas, aveFitness)
    padre1 = reglas[findFather(reglas, properties[:tamañoTorneo])]
    padre2 = reglas[findFather(reglas, properties[:tamañoTorneo])]

    # cruza uniforme para la parte condicional
    cond = uniformCrossover( padre1.conditional, padre2.conditional )

    # Cruza de reales por SBX
    realCond = crossoverSBX(padre1.realConditional, padre2.realConditional)
    pred = crossoverSBX(padre1.predictor, padre2.predictor)

    fit = Fitness(aveFitness, 0)
    hijo = Rule(cond, realCond, pred, fit, 1, padre1.properties,
        padre1.cluster,0)

    return hijo
end # function

"""
    crossoverSBX(v1,v2)

Simulated Binary Crossover para la parte condicional real y predictora
de las reglas
"""
function crossoverSBX(v1,v2)
    β = rand()
    if β < 0.5
        β = (2*β)^(1/21)
    else
        β = (1/(2*(1-β)))^(1/ 21)
    end

    if rand(Bernoulli())
        h = +
    else
        h = -
    end
    return 1/2 .* h( v1 .+ v2, β*abs.(v1 .- v2) ) #hijo
end # function

"""
    uniformCrossover(cond1, cond2)

Realiza la cruza uniforme de la parte condicional
"""
function uniformCrossover(cond1, cond2)
    condHijo = zeros(Int8, length( cond1 ))

    for i in 1:length(cond1)
        if rand(Bernoulli())
            condHijo[i] = cond1[i]
        else
            condHijo[i] = cond2[i]
        end
    end
    return condHijo
end # function
