# En este documento estará todo lo relacionado al especialista y su
# funcionamiento.


# info = [reglas[i].predictor for i in 1:100]
#
# dividendo = 1
# calculateNewPrice(info, dividendo, properties)
# subasta(info)

# module Specialists

using Statistics

export calculateNewPrice, calculateOptimalHolding, subasta, newPriceByAvePred

"""
    newPriceByAvePred(info, dividendo, properties, precio)

Esta función determina el nuevo precio cómo lo dicho por el promedio de
los predictores de los agentes.

Esta es una alternativa al método propuesto originalmente por los autores.
En la propuesta original de los autores no hay dependendia directa entre el
precio anterior y el nuevo. Esto no permite que los predictores (a,b) cumplan con
el propósito de modelación ideado. Con esta nueva regla se respeta este propósito
de modelación
"""
function newPriceByAvePred(info, dividendo, properties, precio)
    a = [info[i][1] for i in 1:length(info) ]
    b = [info[i][2] for i in 1:length(info) ]

    A = mean(a)
    B = mean(b)

    #  transform from [ln 0.5, ln 2] to [0.5,2]
    A = exp(A)

    return A*(precio + dividendo) + B - dividendo
end # function

"""
    calculateNewPrice(info, dividendo, properties)

Esta función calcula el nuevo precio usando la información de predicción
obtenida de todos los agentes.

entrada

info : vector que contiene los predictor de todos los agentes
dividendo : el último dividendo
properties : el properties de siempre
"""
function calculateNewPrice(info, dividendo, properties)
    a = [info[i][1] for i in 1:length(info) ]
    b = [info[i][2] for i in 1:length(info) ]

    A = sum(a) - length(info)*(1+properties[:interestRate])
    B = sum(a*dividendo + b)

    return -B/A
end # function

"""
    subasta(info, dividendo, properties, precio)

come:
info : el vector con los predictores de los agentes
dividendo : el dividendo anterior
properties : el diccionario de parámetros
precio : el precio anterior

Está función es igual a la función que ellos usan originalmente.
Realiza una subasta para calcular el nuevo precio, propone un precio
y pregunta a los agentes por su demanda. El proceso se repite maxIt veces
con la intención de minimizar la diferencia entre la oferta y la demanda.

Mi interés sobre esté método para determinar el precio resugió por lo horribles
que se ven mis series de tiempo con el otro método. Y es de alguna forma natural
lo horribles que son pues el precio anterior al precio no le importa. En algún
grado estaba haciendo que el nuevo precio fuera independiente del anterior.

Este método agrega inercia el nuevo precio. La subaste comienza con el precio
anterior y limitando el número de interaciones creo correlación entre el precio
anterior y el nuevo.
"""
function subasta(info, dividendo, properties, precio)
    maxIt = 1

    for i in 1:maxIt # el número de subastas
        imbalance = 0
        slope = 0

        for j in 1:100 # por cada uno de los
            # manda el precio a todos los agentes
            predictor = info[j]
            imbalance += calculateOptimalHolding(precio, predictor, dividendo, properties)
            slope += (predictor[1] - (1 + properties[:interestRate]) )/(properties[:riskAversion])
        end
        precio -= imbalance/slope
    end
    return precio
end # function

"""
    calculateOptimalHolding(price, predictor, dividendo, properties)

Está función calcula la cantidad ideal de acciones que quiere poseer un agente
determinado
"""
function calculateOptimalHolding(price, predictor, dividendo, properties)
    P = price
    a = predictor[1]
    b = predictor[2]
    d = dividendo
    λ = properties[:riskAversion]
    σ = 1
    r = properties[:interestRate]

    return ( a*(P+d) + b - P*(1+r) ) / (λ*σ)

end # function

# end  # module Specialists
