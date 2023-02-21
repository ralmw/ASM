


# inicialización
model = initialize_model(properties, n_agents = 100)
# recolección de datos
getPrice(model) = model.properties.des.precios[end]
getDividend(model) = model.properties.des.dividendo[end]
mdata = [getPrice, getDividend, getInfo]

function getInfo(model)
    agents = allagents(model)
    return [ predict(agent.reglas, model.properties.des.des ) for agent in agents]
end # function



model = initialize_model(properties, n_agents = 100)
_ , mdf = run!(model, agent_step!, model_step!, 11; mdata)
plot(mdf.getPrice[1:10])

###############################################################
using Agents
using .Unam_ASM
using Random
using Distributions
using GraphPlot
using Graphs

properties = validateProperties()

model = initialize_model(properties, n_agents = 100)
_ , mdf = run!(model, agent_step!, model_step!, 100; )

agent = getindex(model, 39)
d = agent.neighborhood
all_neighbors(G,39)
length(all_neighbors(G,39))

G = model.properties.graph
nodelabels = 1:nv(G)
gplot(G, nodelabel = nodelabels)

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



# pruebas para observar ambas componentes del fitness
# quiero recolectar la información de aboslutamente todos los agentes

aggs = collect(allagents(model))

aggs[1]

10/10

0/0

model.properties.des.des

predict(aggs[1].reglas, model.properties.des.des )

predic

minimum

[aggs[1].reglas[i].predictor[1] for i in 1:100]

vars = [ag.reglas[i].fitness.V for ag in aggs for i in 1:100]
boxplot(vars, outliers = false, label="Varianzas", title="Boxplot de las varianzas sin outliers")


ff = [(ag.reglas[i].fitness.pred,ag.reglas[i].fitness.act) for ag in aggs for i in 1:100]
scatter(ff,title="Ambos componentes del fitness", label="Data",xlabel="pred",ylabel="act")

vars = [ag.reglas[i].fitness.V for ag in aggs for i in 1:100]
pred = [ag.reglas[i].fitness.pred for ag in aggs for i in 1:100]

mean(vars)
minimum(vars)

mean(pred)
minimum(pred)
maximum(pred)

boxplot(vars, outliers=false)

boxplot(pred)


f
