# este es un documento de apoyo para programar la activación de las reglas
# con respecto al descriptor en turno

Analizándo lo que me falta me di cuanta de que me faltan un par de cosas grandes
e importantes. La parte microeconómica y también la actualización de las
reglas que en realidad consiste en actualizar el fitness de las reglas.

Para medir la activaciones de las reglas me gustaría tener una métrica ya usada



es aquí donde me gustaría tener ya un método coevolutivo para mejorar el
predictor de las reglas en otra escala temporal pero todavía no lo tengo :(



predict(reglas, des)



"""
    predict(reglas, des)

Esta función verifica si alguna de las reglas del agente se activan con
el descriptor des dado.

De las reglas que se activan escoge aquellas con el mejor fitness y regresa
su predictor.

Esta función también actualiza el último tiempo de activación de las reglas
y es la encargada de llamar a la función que actualiza el fitness de todas
las reglas
"""
function predict(reglas, des)
    activas = []
    properties = reglas[1].properties
    for i in 1:length(reglas)
        active = compareRule(reglas[i], des, properties)
        if active
            push!(activas, i)
        end
    end

    if length(activas) == 0 # no hace nada si no hay reglas activas
        updateFitness()
        return zeros(2)
    else
        # selecciona a la mejor entre ellas, usando el fitness real
        ind = argmax( x -> reglas[x].fitness.real, activas )
    end

    return reglas[ind].predictor
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
