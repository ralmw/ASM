




model = initialize_model(properties)
# corremos el modelo 1000 tiempos como fase transitoria
_,_ = run!(model, agent_step!, model_step!, 100; )
# recolectamos la información de los siguientes 10000 tiempos
adf , mdf = run!(model, agent_step!, model_step!, 100; mdata,adata)
plot(mdf.getPrice[1:100])
plot(mdf.getDividend[1:100])

step = 90
ejem = subset(adf, :step => a -> a .== step)
histogram(ejem[!,:getAgentPrice], bins = 14)
subset(mdf, :step => a -> a .== step)

###############################################################
include("join.jl")
using Agents
using .Unam_ASM
using Random
using Distributions
using GraphPlot
using Graphs
using Plots
using DataFrames



# El siguiente es un ejemplo de cómo debe ejecutarse el código para correr el modelo

properties = validateProperties()
properties[:n_agents] = 100

properties[:modelTraining] = false
run!(model, agent_step!, model_step!, 100; )




# El siguiente es un ejemplo de cómo se recopila información del modelo 

properties = validateProperties()
properties[:n_agents] = 100

# Se definen las función de recolección de datos
getPrice(model) = model.properties.des.precios[end]
getDividend(model) = model.properties.des.dividendo[end]
mdata = [getPrice, getDividend]

getAgentPrice(agent) = agent.des.precios[end]
adata = [getAgentPrice]


# inicialización
model = initialize_model(properties)

# recolectamos la información de los siguientes 10000 tiempos
adf , mdf = run!(model, agent_step!, model_step!, 100; mdata,adata)





# El siguiente es un ejemplo dónde se entrena al modelo con datos externos 

properties = validateProperties()
properties[:n_agents] = 100
properties[:modelTraining] = true
global globalTrainingCont = 1
x = 1:100000
y = 100 .* sin.(2π .* x ./ 500) .+ 500
global globalTrainingPriceVector = y # Un seno de periodo 500 y amplitud 100 con base en 500
training_n = length(globalTrainingPriceVector)

properties[:globalTrainingCont] = 1 
properties[:globalTrainingPriceVector] = globalTrainingPriceVector

# for training :


model = initialize_model(properties)
adf , mdf = run!(model, agent_step!, model_step!, training_n;  )

# Efectivamente tiene toda la información que deseo. Ahora vamos a dejarlo correr





# el siguiente es un ejemplo de cómo se perturba el modelo 

properties = validateProperties()
properties[:n_agents] = 100

model = initialize_model(properties)
percentageAgentsPerturbate = 0.2 # porcentaje de agentes a perturbar 
perturbacionFactor = 2

for agent in allagents(model)
    if rand() < percentageAgentsPerturbate
        agent.properties[:perturbate] = true 
        agent.properties[:perturbacionFactor] = perturbacionFactor
    end
end

# ahora se corre el modelo 
_ , mdf = run!(model, agent_step!, model_step!, 100; )





# el siguente es un ejemplo de ensemble run

properties = validateProperties()
properties[:n_agents] = 100

# Se definen las función de recolección de datos
price(model) = model.properties.des.precios[end]
dividend(model) = model.properties.des.dividendo[end]
mdata = [price, dividend]

getAgentPrice(agent) = agent.des.precios[end]
getAgentPrediction(agent) = agent.prediction
nextGAExecution(agent) = agent.GA_time
aveRuleFitness(agent) = mean([agent.reglas[i].fitness.real for i in eachindex(agent.reglas)])
agentClustersInfo(agent) = agent.GA_recent ? agent.ct : []
agentRules(agent) = agent.GA_recent ? agent.reglas : [] # 
agentRulesFitness(agent) = [agent.reglas[i].fitness.real for i in eachindex(agent.reglas)]
agentRulesIds(agent) = [agent.reglas[i].id for i in eachindex(agent.reglas)]
# fib(n::Integer) = n ≤ 2 ? one(n) : fib(n-1) + fib(n-2)
adata = [getAgentPrice, getAgentPrediction, nextGAExecution, aveRuleFitness, agentClustersInfo,
    agentRules, agentRulesFitness]


# inicialización
models = []
for i in 1:2
    model = initialize_model(properties)
    append!(models,[model])
end
models

adf, mdf = ensemblerun!(models,agent_step!, model_step!, 500; mdata, adata)


last(adf,10)
last(mdf, 10)

###############################################################

# diccionarios y gráfica no tienen la misma información

G = model.properties.graph
for agent in allagents(model)
    print(agent.id, ": ")
    print(length(all_neighbors(G, agent.id)) )
    print(" ", length(keys(agent.neighborhood))-1)
    println(" ", length(all_neighbors(G, agent.id)) == length(keys(agent.neighborhood))-1 )
end


#############################################


agentts = allagents(model)

agente = getindex(model,1)
agente.GA_time
predict(agente.reglas,model.properties.des.des)

model.des

model.properties.des.des




keys(model.properties)

properties[:vars]

model.properties.vars







#Ahora quiero ver cómo se comportan las series de tiempo.

mdf.getPrice

plot(mdf.getPrice)


#Ya que tengo todo el historial de predictores quiero encontrar qué valores
#promedio le corresponde a cada uno de los info.

#Quiero entonces algo que come predictores y que regresa el predictor promedio

function avePred(info)
    a = mean([info[i][1] for i in 1:length(info)])
    b = mean([info[i][2] for i in 1:length(info)])
    return [a,b]
end # function

function predPrice(predictor, dividendo = 1)
    r = 0.001
    a, b = predictor
    A = a - 1 + r
    B = a * dividendo + b

    return -B/A
end # function

[avePred(mdf.getInfo[i] )[1]  for i in 1:1000 ]
predPrice(avePred(mdf.getInfo[1]))

mdf.getPrice[1]
mdf.getDividend[1]

predPrice(avePred(mdf.getInfo[1]),mdf.getDividend[1])

mdf.avePred = avePred.(mdf.getInfo)
mdf.predPrice = predPrice.(mdf.avePred,mdf.getDividend)


mdf[!,[:getPrice, :predPrice]]

mdf.getInfo[10]

n = 5000
calculateNewPrice(mdf.getInfo[n], mdf.getDividend[n],properties)
predPrice(avePred(mdf.getInfo[n]),mdf.getDividend[n])
mdf.avePred[n]
mdf.getPrice[n]
mdf.getPrice[n+1]

n = 5555
avePred(mdf.getInfo[n])


# los predictores usados a lo largo del tiempo son los siguientes:
mdf.avePred[5000]


mdf.getInfo[5000]

######### Porque las reglas de mis agentes tienen fitness promedio Inf ??????   RESUELTO

# pruebas para observar ambas componentes del fitness
# quiero recolectar la información de aboslutamente todos los agentes
model = models[1]

aggs = collect(allagents(model))

aggs[1]

10/10

0/0

model.properties.des.des

predict(aggs[1].reglas, model.properties.des.des )



vars = [ag.reglas[i].fitness.V for ag in aggs for i in 1:100]
boxplot(vars, outliers = false, label="Varianzas", title="Boxplot de las varianzas sin outliers")


ff = [(ag.reglas[i].fitness.pred,ag.reglas[i].fitness.act) for ag in aggs for i in 1:100]
scatter(ff,title="Ambos componentes del fitness", label="Data",xlabel="pred",ylabel="act")

## Recolección manual del promedio 
fits = [(ag.reglas[i].fitness.real) for ag in aggs for i in 1:100]
sum(fits .== Inf)


fitActs = [ag.reglas[i].fitness.act for ag in aggs for i in 1:100]
fitPreds = [ag.reglas[i].fitness.pred for ag in aggs for i in 1:100]
fitVars = [ag.reglas[i].fitness.V for ag in aggs for i in 1:100]

sum(fitActs .== Inf)
sum(fitPreds .== Inf )
sum(fitVars .== Inf)

sum(fitVars .== 1 )

# El problema está al tranformar la varianza 


mean(vars)
minimum(vars)

mean(pred)
minimum(pred)
maximum(pred)

boxplot(vars, outliers=false)

boxplot(pred)


f



################### Cómo se ven las reglas de los agentes después de ser entrenadas por 
# la serie sintética senoidal?

# Un heatmap para comparar las partes condicionales de un par de agentes ordenadas por 
# clusterización jerárquica
agent = getindex(model, 10)
agent2 = getindex(model, 20)


heatmapConditionalComparison(agent, agent2, 10)



using Clustering

function heatmapConditionalComparison(agent, agent2, k)
    # función que crea un heatmap de la similitud entre las reglas de 2 agentes
    # Me quedo con las reglas
    reglas = agent.reglas 
    reglas2 = agent2.reglas

    # ordeno mis reglas usando clusterización jerárquica
    #k = 4 # numero de clusters
    reglas = hclustOrdenReglas(reglas, k)
    reglas2 = hclustOrdenReglas(reglas2, k)

    # calculo la matriz de distancias 
    # sum(a .!= b) # distancia de hamming

    M = zeros(length(reglas), length(reglas2))

    for i in eachindex(reglas)
        a = reglas[i].conditional
        for j in eachindex(reglas2)
            b = reglas2[j].conditional
            M[i,j] = sum(a .!= b)
        end
    end

    return heatmap(M)
end

function hclustOrdenReglas(reglas, k)
    # función que ordena las reglas usando clusterización jerárquica para el heatmap
    
    # Con jerárquica

    # calcula la matriz de distancias de las reglas
    M = zeros(Int8, length(reglas), length(reglas) )

    for i in CartesianIndices(M)
        a = reglas[i[1]].conditional # primera y segunda reglas
        b = reglas[i[2]].conditional
        M[i] = sum(a .!= b) # distancia de hamming
    end
    # M, la matriz de distancias obtenida

    # realiza clusterización y corta
    hc = hclust(M, linkage=:complete)
    plot(hc) #para observar el dendrograma
    ct = cutree(hc, k = k )

    # Entonces recorro ct k veces y voy extrayendo el índice 
    nuevoOrden = []
    for cluster in 1:k
        for i in eachindex(reglas)
            if ct[i] == cluster
                append!(nuevoOrden, i)
            end
        end
    end

    return reglas[nuevoOrden]
end



## la conclusión de está comparación es que efectivamente hay reglas 
# en ambos agentes que se parecen bastante entre si pero también
# hay otras que no se parecen tanto 