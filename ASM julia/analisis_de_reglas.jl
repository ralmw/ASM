analisis_de_reglas.jl 

### Aquí agrupo todo el código relacionado con el análisis de las reglas de los agentes
# mi objetivo es determinar si los agentes llegan a "pensar lo mismo" si consiguen 
# "ponerse de acuerdo". Para ello deseo encontrar similitudes entre las reglas. 



# Distancia 
# Mi método es primero definir una distancia entre reglas que incluya la distancia de hamming 
# Pero también la probabilidad de actividad simultánea. 
# Me enfocaré solamente en el descriptor de Ehrentreich. 

# Muestra
# Posteriormente crearé una muestra de las reglas 

# t-SNE a R3
# Esta muestra y función de distancia las alimentaré a t-SNE para obtener un encaje en R3 
# de mis reglas 

# Red neuronal 
# Cómo esto no me da una función para encajar mis reglas entrenaré una red neuronal con 
# mis datos generados y el resultado de t-SNE. 



# El motivo para no usar un autoencoder es que de está manera puedo incorporar la 
# información sobre la activación simultánea al encaje

using Distributions

"""
ruleRuleDistance(rule, rule)

come la parte condicional de un par de reglas y calcula la distancia entre ellas. 
"""
function ruleRuleDistance(a, b) # partes condicionales
    hamming = sum(a .!= b)

    # bits en los que ambas reglas son no cero 
    noCero = collect(1:length(a))[(a .!= 2) .*  (b .!= 2)]

    contradiction = false
    for i in noCero
        if a[i] != b[i]
            contradiction = true
        end
    end

    if contradiction
        proba = 0
    else 
        proba = 0.5^hamming
    end

    return 1-proba + hamming/10
end


# De esta manera creo una regla así creo mi muestra. 
muestra = []
for i in 1:100000
    append!(muestra,  [Unam_ASM.createRule(properties, 0)] )
end 

# Y ahora los específicos para mi espacio de interes 

# Primero los de especificidad 1 
# 10 
for i in 1:10
    for bitVal in 1:2
        regla = Unam_ASM.createRule(properties, 1)
        # Aquí la modifico, respeto el resto de bits 
        synt = 2 .* ones(10)
        synt[i] = bitVal-1
        regla.conditional[37:end] = UInt8.(synt)
        append!(muestra, [regla] )
    end
end

# especificidad 2 
# 10*9
for i in 1:10
    for j in i:10
        for bitVal in 1:2
            regla = Unam_ASM.createRule(properties, 1)
            # Aquí la modifico, respeto el resto de bits 
            synt = 2 .* ones(10)
            synt[i] = rand(Bernoulli())
            synt[j] = rand(Bernoulli())
            regla.conditional[37:end] = UInt8.(synt)
            append!(muestra, [regla] )
        end
    end
end

# especificidad 3 
# 10*9*8
for i in 1:10
    for j in i:10
        for k in j:10
            for bitVal in 1:2
                regla = Unam_ASM.createRule(properties, 1)
                # Aquí la modifico, respeto el resto de bits 
                synt = 2 .* ones(10)
                synt[i] = rand(Bernoulli())
                synt[j] = rand(Bernoulli())
                synt[k] = rand(Bernoulli())
                regla.conditional[37:end] = UInt8.(synt)
                append!(muestra, [regla] )
            end
        end
    end
end

# especificidad 4 
# 10*9*8*7 
for i in 1:10
    for j in i:10
        for k in j:10
            for l in k:10
                for bitVal in 1:2
                    regla = Unam_ASM.createRule(properties, 1)
                    # Aquí la modifico, respeto el resto de bits 
                    synt = 2 .* ones(10)
                    synt[i] = rand(Bernoulli())
                    synt[j] = rand(Bernoulli())
                    synt[k] = rand(Bernoulli())
                    synt[l] = rand(Bernoulli())
                    regla.conditional[37:end] = UInt8.(synt)
                    append!(muestra, [regla] )
                end
            end
        end
    end
end

# En esta ocasión tomo cómo muestra a las reglas del modelo, todas las reglas 
muestra = [regla  for agent in allagents(model) for regla in agent.reglas]

# Aplico t-SNE 
using TSne
# tsne(X, ndim, reduce_dims, max_iter, perplexit; [keyword arguments])
condicionales = [regla.conditional for regla in muestra]
Y = tsne(condicionales, 3, 0, 30, 30; distance = ruleRuleDistance, progress = true)

using PlotlyJS, CSV, DataFrames
df = DataFrame(x1= Y[:,1], x2 = Y[:,2], x3 = Y[:,3],conjunto = [regla.id for regla in muestra] )
PlotlyJS.plot(
    df,
    x=:x1, y=:x2, z=:x3, marker_size=0.8,
    type="scatter3d", mode="markers"
)

# El espacio está bien? Es útil el encaje que estoy haciendo? 
# Cómo lo sé? 

# Ahora, entrenar una red neuronal con estos datos
