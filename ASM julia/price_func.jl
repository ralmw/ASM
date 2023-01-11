# La conclusión de todos mis esfuerzos es que lo haré de 2 maneras, dependiendo de un parametró decidiré si 
# el precio es el que se encuentra justamente a la mitad de ambos agentes o se decide de manera proporcional 
# a la riquza de ambos agentes de tal manera que priorize la opinión del más rico. 
# La mágnifica ecuación resultante del trabajo del año pasado enterito es la siguiente:

# (s + x)*(P - Pt) + (E - xPt)(1+r)

# La labor ahora está en calcular sencillamente un precio a partir de 2 agentes y usar la ecuación para
# determinar la cantidad de acciones a comerciar. 


# Recuperando mis códigos anteriores:

# Primero recordemos la estructura de agente usada en el evolutivo


agente 


# Del agente ncesito su riqueza, su predición y ya.

agente.wealth
a,b = predict(agente.reglas,model.properties.des.des)

# Para obtener la predicción final tengo que aplicar la regla usada para 
# determinar P del predictor. 

P = model.properties.des.precios[end]*a + b


mutable struct Transaction 
    comprador::Int
    vendedor::Int 
    Pt::Float64
    x::Float64
end

# Y esta es toda la información que necesito para la función.

function calcTransaction(agente1::Trader,agente2::Trader)
    a1,b1 = predict(agente1.reglas,model.properties.des.des)
    a2,b2 = predict(agente2.reglas,model.properties.des.des)

    Pt = model.properties.des.precios[end] # último precio 
    # minúscula precio anterior 
    # mayúscula precio actual en la transacción
    Dt = model.properties.des.des[end] # último dividendo

    P1 = a1*(Pt + Dt) + b1 
    P2 = a2*(Pt + Dt) + b2 

    # Y ahora toca tomar el precio de acuerdo con el criterio seleccionado, ya sea 
    # justo a la mitad a proporcional a la riqueza de los agentes.

    if agente1.properties[:priceCompromise] == "middle"
        PT = (P1 + P2)/2
    elseif agente1.properties[:priceCompromise] == "proportional"
        m1 = (agente1.wealth[1]^2 + agente1.wealth[2]^2)^(1/2)
        m2 = (agente2.wealth[1]^2 + agente2.wealth[2]^2)^(1/2)

        if P1 >= P2
            m = m2 
        else 
            m = m1 # m es la norma correspondiente al agente de Pt mas bajo
        end  
        Pt2 = max(P1,P2)
        Pt1 = min(P1,P2) # Para tener los precios ordenados 

        PT = (Pt2 - Pt1)*(m/(m1+m2)) + Pt1
        # PT es el precio acordado en la transacción actual
    end

    # Ahora encontremos x óptimo para ese precio

    if P1 >= P2 # el agente 1 compra y el agente 2 vende 
        comprador = agente1 
        vendedor = agente2
    else
        comprador = agente2 
        vendedor = agente1
    end

    S1 = comprador.wealth.stock 
    E1 = comprador.wealth.cash

    S2 = vendedor.wealth.stock 
    E2 = vendedor.wealth.cash 

    r = agente1.properties[:interestRate]

    up = PT*(S2 - S1) + S2*P2 - S1+P1 + (1+r)*(E2-E1)
    down =  2PT + P1 + P2 - 2*PT*(1+r)

    x = up/down

    #la transación es entre pares, un comparador, un vendedor, a un precio y una cantidad x entre ellos. 
    # Para ello uso la struct Transaction
    return Transaction(comprador.id, vendedor.id, PT, x)

end