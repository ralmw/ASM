# Este el algoritmo genético del modulo reglas.

# module Reglas

#export GA, predict, createRules, updateFitness!
# export createRules

## quiero que desde los agentes pueda llamar.
#predict(des, reglas) y me regrese la predicción correspondiente a la mejor regla
#GA(reglas) y que ejecute el algoritmo genético sobre las reglas.

#regla = reglas[1]

# solamente depende de este .jl y de properties.jl
#reglas = createRules(properties)
#reglas = GA(reglas)

# depende de descriptor.jl y de properties.jl
#predict(reglas, des.des)

#Estructura de mi algoritmo genético.::::::::::::::::::::

# inicio
#     clusterización
#     poda para mantener el tamaño de los clusters
#     poda de los peores usando escalamiento sigma sobre clusters
#     reproducción con torneo y escalamiento sigma
# fin

using Random
using Distributions
using Clustering
using Statistics
using StatsBase
#using Plots Fue usado para confirmar el correcto funcionamiento
#using StatsPlots Usado para ver el dendrograma

#%% Aquí comienzan las funciones para la determinación del fitness de las reglas

"""
    updateFitness!(des, reglas)

Esta función actualiza el fitness de las reglas tomando en cuenta el núevo precio

entrada

des : el descriptor, completo con precio y dividendo
reglas : las reglas a ser actualizadas

hace falta verificar que las modifiaciones in-place funcionan correctamente

También actualiza el predictor de la regla usando la información sobre el nuevo
precio, viendo al predictor de la regla cómo una memoria sobre lo ocurrido
en el pasado.
"""
function updateFitness!(des, reglas)
    for regla in reglas
        # actualiza la presición
        updateVariance!(des, regla) # para aquellas reglas que acaban de activarse
        # transforma la varianza y actualiza fitness.pred
        regla.fitness.pred = transformVariance(regla.fitness.V)
        # calcula fit.act
        updateFitAct!(regla)
        # actualiza fit.real
        updateFitnessReal!(regla)

        # Actualiza el predictor de la regla usando al información sobre el
        # precio anterior
        updatePredictor!(des, regla)
    end
end # function

"""
    updateFitnessReal!(regla)

actualiza el fitness.real de la regla igual a fitness.act + fitness.pred
"""
function updateFitnessReal!(regla)
    regla.fitness.real = regla.fitness.act + regla.fitness.pred
end # function


"""
    updateVariance(des, regla)

actualiza la varianza de la regla usando el núevo precio

entrada

des : el descriptor completo, con precio y dividendo
regla : la regla a actualizar
"""
function updateVariance!(des, regla)
    # solo se actualiza para aquellas reglas que fueron activadas el
    # el periodo anterior
    if regla.lastActive == 0
        θ = 50 # será el promedio ponderado de 50 predicciones

        p, P = des.precios[end-1:end]
        d, D = des.dividendo[end-1:end]
        a, b = regla.predictor
        V = regla.fitness.V

        V = (1- 1/θ)*V + (1/θ)*( (P + D) - (a*(p + d) + b) )^2

        regla.fitness.V = V
    end
end # function

"""
    updatePredictor!(des, regla)

Esta función actualiza el predictor de la regla dada in-place, utilizando la
visión del predictor cómo una memoria sobre el pasado de la regla.
"""
function updatePredictor!(des, regla)
    # solo se actualiza para aquellas reglas que fueron activadas el
    # el periodo anterior
    if regla.lastActive == 0
        #α = 0.975 # \alpha será el parámetro para el promedio ponderado
        α = 0.995

        p, P = des.precios[end-1:end]
        d, D = des.dividendo[end-1:end]
        A = regla.predictor[1]

        x = p + d
        X = P + D
        new = X / x

        new = minimum([new, 2])
        new = maximum([new,0.5])

        # transforma a [ln 0.5, ln 2]
        new = log(new)

        A = A*α + new*(1-α)

        regla.predictor[1] = A
    end
end # function

"""
    transformVariance(V)

Esta función transformará la varianza de las reglas en un número entre 0 y 1
"""
function transformVariance(V)
    return 1/log10(V)
end # function

"""
    calculateFitnessAct(n)

Calcula el fit.act para las reglas a partir de la última activación de las
mismas.
"""
function calculateFitnessAct(n, properties)
    λ = properties[:gaActivationFrec]
    c = 0.3183098861 #constante para que los límites sean 1/2
    n = -n + 3*λ

    return c*atan(n)*exp( -(λ/n)^2 )
end # function

"""
    updateFitAct!(regla)

    Calcula el fit.act para la regla a partir de la última activación de la
    misma.
"""
function updateFitAct!(regla)
    regla.fitness.act = calculateFitnessAct(regla.lastActive, regla.properties)
end # function

#%% Aquí comienzan las funciones para las activaciones de las reglas

"""
    predict(reglas, des)

entrada: 
    reglas : lista de reglas cómo las entrega createRules()
    des : la parte des de des. Sólo el véctor des, no el descriptor completo 

Esta función verifica si alguna de las reglas del agente se activan con
el descriptor des dado.

De las reglas que se activan escoge aquellas con el mejor fitness y regresa
su predictor.

Esta función también actualiza el último tiempo de activación de las reglas.
"""
function predict(reglas, des)
    activas = []
    properties = reglas[1].properties
    for i in eachindex(reglas)
        # compareRule actualiza la información de la última activación
        active = compareRule(reglas[i], des, properties)
        if active
            push!(activas, i)
        end
    end

    if length(activas) == 0 # no hace nada si no hay reglas activas
        #updateFitness()
        return [0,0]
    else
        # selecciona a la mejor entre ellas, usando el fitness real
        ind = argmax( x -> reglas[x].fitness.real, activas )
    end

    return reglas[ind].predictor
end # function

"""
    predict(reglas, des, properties)

entrada: 
    reglas : lista de reglas cómo las entrega createRules()
    des : la parte des de des. Sólo el véctor des, no el descriptor completo 
    properties : recibe el properties del agente 

La predict sin properties del agente solo que perturbable. 
si properties[:perturbate] == true 
se perturba el predictor por un factor igual a properties[:perturbationFactor]
la perturbación tiene la forma de una multiplicación 


Esta función verifica si alguna de las reglas del agente se activan con
el descriptor des dado.

De las reglas que se activan escoge aquellas con el mejor fitness y regresa
su predictor.

Esta función también actualiza el último tiempo de activación de las reglas.
"""
function predict(reglas, des, properties)
    activas = []
    for i in eachindex(reglas)
        # compareRule actualiza la información de la última activación
        active = compareRule(reglas[i], des, properties)
        if active
            push!(activas, i)
        end
    end

    if length(activas) == 0 # no hace nada si no hay reglas activas
        #updateFitness()
        return [0,0]
    else
        # selecciona a la mejor entre ellas, usando el fitness real
        ind = argmax( x -> reglas[x].fitness.real, activas )
    end


    if properties[:perturbate]
        return reglas[ind].predictor .* properties[:perturbationFactor]
    else
        return reglas[ind].predictor
    end
end # function


"""
    compareRule(regla, des, properties)

Esta función compara el descriptor con la regla dada, en caso de que la regla
se active regresa true, de lo contrario regresa false.
Esta función también actualiza Rule.lastActive
"""
function compareRule(regla, des, properties)
    # comparamos primero la parte real
    a1 = compareReals(regla, des, properties)
    # luego la parte binaria
    a2 = compareConditional(regla, des, properties)

    # si ambas son ciertas entonces la regla se activa y hay que actualizar
    #ifelse( a1 && a2, regla.lastActive = 0, regla.lastActive += 1)
    if a1 && a2
        regla.lastActive = 0
    else
        regla.lastActive += 1
    end
    # las activaciones de la regla
    return a1 && a2
end # function

"""
    compareConditional(regla, des, properties)

Esta función verifica que se satisfaga la parte binaria de la regla
"""
function compareConditional(regla, des, properties)
    # parte binaria del descriptor
    a = des[ properties[:nBitsReales]+1:end ]
    # parte exclusivamente binaria de la regla
    b = regla.conditional[ properties[:nBitsReales]+1:end ]

    pos = h.(b)
    # se queda con la información relevante
    a = a[pos]
    b = b[pos]

    # compara
    return ifelse(sum(a .== b) == length(a), true, false)
end # function

# esta función también es importante
h(x) = ifelse(x == 2, false, true)
# esta función es importante, no borrar por accidente
f(x) = ifelse(x==1,true, false )

"""
    compareReals(regla,des,properties)

Esta función verifica si la regla se satisface en su parte real
"""
function compareReals(regla,des,properties)
    # compara con el descritor
    a = des[1:properties[:nBitsReales]] .> regla.realConditional

    # información sobre bits relevantes
    temp = regla.conditional[1:properties[:nBitsReales]]
    temp = f.(temp)

    # combina ambas piezas de información
    a = a[temp]

    # si el vector es todo de 1's entonces la regla se satisface
    return ifelse( sum(a.==1) == sum(temp.==1), true, false)

end # function


#%% Aquí empiezan las funciones relacionadas al algoritmo evolutivo.

# mi dado para la inicialización de los bits
v = [0.05,0.05,0.9]
q = DiscreteNonParametric( [0,1,2], v )
rand(q, 100)

mutable struct Rule
    id
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
    real # the sum of fit.pred and fit.act
    scaled
    V # Stands for variance
    pred # fitness due to precision
    act # fitness due to activations
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
function createRule(properties, id)
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
    a = rand( Uniform( log(0.5), log(2) ) ) # en [ln 0.5, ln 2]
    b = rand( Uniform( -10.0, 10.0 ) )
    predictor = [a,b]
    fitness = Fitness( rand(), 2, 2, 2 ,2) #fitness aleatorio
    variance =  1
    cluster = 1
    return Rule(id, conditional, realConditional, predictor,
        fitness, variance, properties, cluster, 2*properties[:gaActivationFrec] )
end # function

"""
    createRules(properties)

Esta es la función usada durante la creación del agente para crear su
lista inicial de reglas.
"""
function createRules(properties)
    return [ createRule(properties, id ) for id in 1:properties[:nReglas] ]
end # function

"""
GA(reglas, ct)

La misma función que abajo solo que regresa el vector ct que describe los clusters 
de reglas
"""
function GA(reglas, ct_return, agent_last_rule_id)

    reglas, clusters, ct = clusterize(reglas)
    reglas, clusters, ct = podaPorCluster(reglas, clusters, ct)
    reglas, clusters, ct = podaSigma(reglas, clusters, ct)
    hijos = calculateProgeny(reglas, clusters, agent_last_rule_id)

    append!(reglas, hijos)

    if ct_return == false
        return reglas
    else 
        return reglas, ct 
    end
end # function

"""
    GA(reglas)

Función que llama el agente para ejecutar el algoritmo genético
"""
function GA(reglas, agent_last_rule_id)

    reglas, clusters, ct = clusterize(reglas)
    reglas, clusters, ct = podaPorCluster(reglas, clusters, ct)
    reglas, clusters, ct = podaSigma(reglas, clusters, ct)
    hijos = calculateProgeny(reglas, clusters, agent_last_rule_id)

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
    properties = reglas[1].properties
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
    for i in eachindex(reglas)
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
    properties = reglas[1].properties
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

Elimina a los peores individuos de la población tomando en cuenta mil cosas. 
Hace un escalamiento sigma para eliminar de todos los clusters haciendo un 
escalamiento sigma, elimina las reglas que tiene mucho no se activan y 
también toma en cuenta algo de elitismo, dónde procura no eliminar por 
completo un cluster en particular a las mejores reglas de cada cluster.
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

    # Antes de hacer la poda quiero comenzar eliminando reglas demasiado viejas
    # sin importar en dónde se encuentren
    ind = []
    λ = properties[:gaActivationFrec]
    reglas_restantes = length(reglas)
    min_reglas = Int(floor(properties[:minPropReglas] * properties[:nReglas]))

    # cuantas reglas podemos eliminar todavía 
    num_reglas_puedo_eliminar = reglas_restantes - min_reglas

    for i in eachindex(reglas)
        if num_reglas_puedo_eliminar > 0 # solo elimino si puedo 
            if λ*5 > reglas[i].lastActive >= λ*4 # podría ser 4
                #proba
                if rand(Bernoulli(0.5))
                    push!(ind, i)
                end
            elseif λ*6 > reglas[i].lastActive >= λ*5
                #proba
                if rand(Bernoulli(0.75))
                    push!(ind, i)
                end
            elseif reglas[i].lastActive >= λ*6
                # determinista
                push!(ind, i)
            end
            num_reglas_puedo_eliminar -= 1
        end
    end
    deleteat!(reglas, ind)
    deleteat!(ct, ind)

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
        #i += 1 # el punto relevante para el elitismo ¿por qué?

        reglas = reglas[ 1:max(ind, i,min_reglas) ] # y ya
        ct = ct[1:max(ind, i, min_reglas)]

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
    if length(reglas) >= n
        itr = sample( 1:length(reglas), n, replace = false )
    else
        itr = sample(1:length(reglas), n, replace = true)
    end
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

    for i in eachindex(clusters)
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
function calculateProgeny(reglas, clusters, agent_last_rule_id)
    properties = reglas[1].properties
    hijos = []
    clustersInfo = calcClustInfo(reglas, clusters)
    fitnessAve = mean([reglas[i].fitness.V for i in eachindex(reglas)])
    next_id = agent_last_rule_id + 1

    while length(reglas) + length(hijos) < properties[:nReglas]
        # selecciona método de reproducción, mutación o cruza
        if rand(Bernoulli(0.2))
            # mutación
            hijo = mutate(reglas, clustersInfo, fitnessAve, next_id) # ya deben estar calculados
        else
            # cruza
            hijo = crossover(reglas, fitnessAve, next_id)
        end
        push!(hijos, hijo )
        next_id += 1
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
function mutate(reglas, clustersInfo, fitnessAve, id)
    padre = reglas[findFather(reglas, reglas[1].properties[:tamañoTorneo])]
    conditional = padre.conditional
    realConditional = padre.realConditional
    predictor = padre.predictor
    # muta la parte condicional
    conditional = mutateConditional(conditional, clustersInfo[padre.cluster] )
    # muta la parte realConditional, la parte condicional real de la regla
    realConditional = mutateReals(realConditional)
    # muta la parte predictora de la regla
    predictor = mutatePredictor(predictor)
    fit = Fitness(0, 0, fitnessAve, 0, 0 )
    hijo = Rule(id, conditional, realConditional, predictor, fit, 1,
        padre.properties, padre.cluster, 2*reglas[1].properties[:gaActivationFrec] )

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
    for i in eachindex(conditional)
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
    for i in eachindex(realConditional)
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
posibles al intervalo [ln 0.5, ln 2] para el parámetro a y
[-20,20] para el parámetro b.

Note la diferencia a los valores originales del modelo para a
que son [0.7, 1.2] y [-10,20].
"""
function mutatePredictor(predic)
    predictor = deepcopy(predic)
    ϵ = [rand(Cauchy(0,0.28711)),rand(Cauchy(0,8.2842))]
    predictor = predictor .+ ϵ
    predictor[1] = max(log(0.5), predictor[1])
    predictor[1] = min( log(2),  predictor[1])
    predictor[2] = max(20,  predictor[2])
    predictor[2] = min(20,  predictor[2])
    # una vez normalizado me regresa el resultado.
    return predictor
end



"""
    crossover(reglas, aveFitness)

Esta función es la responsable de calcular hijos usando cruza
"""
function crossover(reglas, aveFitness, id)
    properties = reglas[1].properties
    padre1 = reglas[findFather(reglas, properties[:tamañoTorneo])]
    padre2 = reglas[findFather(reglas, properties[:tamañoTorneo])]

    # cruza uniforme para la parte condicional
    cond = uniformCrossover( padre1.conditional, padre2.conditional )

    # Cruza de reales por SBX
    realCond = crossoverSBX(padre1.realConditional, padre2.realConditional)
    pred = crossoverSBX(padre1.predictor, padre2.predictor)

    fit = Fitness(0, 0, aveFitness, 0, 0)
    hijo = Rule(id, cond, realCond, pred, fit, 1, padre1.properties,
        padre1.cluster,2*padre1.properties[:gaActivationFrec])

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

    for i in eachindex(cond1)
        if rand(Bernoulli())
            condHijo[i] = cond1[i]
        else
            condHijo[i] = cond2[i]
        end
    end
    return condHijo
end # function


# end  # module
