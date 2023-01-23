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
    Pcomp::Float64
    vendedor::Int 
    Pvend::Float64
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

    P1 = a1*(Pt + Dt) + b1 # predicción del agente 1
    P2 = a2*(Pt + Dt) + b2 # precio predicho por el agente 2

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
        Pc = P1
        vendedor = agente2
        Pv = P2
    else
        comprador = agente2 
        Pc = P2
        vendedor = agente1
        Pv = P1
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
    return Transaction(comprador.id, Pc, vendedor.id, Pv, PT, x)

end

"""
    calculateTransactions(model)

    calcula todas las transacciones entre pares de agentes 
    y las regresa todas en un vector de julia. 

    Esto con una ejecución síncrona en mente.
"""
function calculateTransactions(model)
    # obtiene la topología de los agentes e 
    # itera sobre las aristas para obtener transacciones 
    G = model.properties.graph
    Transactions = []
    for e in edges(G)
        u,v = src(e), dst(e)
        agent1 = getindex(model, u)
        agent2 = getindex(model, v)
        trans = calcTransaction(agent1,agent2)
        append!(Transactions,trans)
    end
    return Transactions
end

"""
    unzipTransactions(transactions, properties)

    transactions : lista de todas las transacciones calculadas en 
        calculateTransactions
    properties : diccionario global de properties
    
    transforma el vector de transacciones calculado den calculateTransactions
    y lo transforma en un par de diccionarios que nos permitan llevar a cabo 
    las transacciones, calcular los nuevos precios y juzgar las transacciones

    Toma en cuanta ambos casos, tanto la existencia de un precio único global 
    cómo la posibilidad de precios locales por agente.

    Regresa un par de diccionarios, TransDict y PriceDict,
    las llaves de ambos son la Id del agente y se toma su persepectiva
    PriceDict contiene el precio observado por el agente
    TransDict contiene la información de las transacciones en las que participó el
    agente desde la persepectiva del agente, información necesaría para actualizar
    la riqueza del agente y para juzgar las transacciones. 
    lista de 
    [[Pv, comprador, Pc, Pt, -x]]
    [[Pc, vendedor, Pv, Pt, x]]
"""
function unzipTransactions(transactions,properties)
    TransDict = Dict(0 => [[0,0.0,0.0],[0,0.0,0.0]])
    for trans in transactions
        # estoy usando solamente Id, no agentes
        comprador = trans.comprador
        vendedor = trans.vendedor
        Pt = trans.Pt
        x = trans.x
        Pc = trans.Pcomp 
        Pv = trans.Pvend

        # agregamos transacción al comprador
        if haskey(TransDict,comprador) # Si ya se inicializó la lista de comprador 
            append!(TransDict[comprador], [Pc, vendedor, Pv, Pt, x])
        else 
            TransDict[comprador] = [[Pc, vendedor, Pv, Pt, x]]
        end

        # Agregamos transacción al vendedor
        if haskey(TransDict, vendedor) # el código es análogo al anterior 
            append!(TransDict[vendedor], [Pv, comprador, Pc, Pt, -x]) # cambia el signo de x 
        else
            TransDict[vendedor] = [[Pv, comprador, Pc, Pt, -x]]
        end
    end

    
    # ahora calculamos el diccionario de nuevos precios 
    PriceDict = Dict(0 => 0.0)
    if properties[:priceType] == "local"
        for i ∈ 1:properties[:n_agents]
            PriceDict[i] = mean([TransDict[i][j][4] for j in 1:length(TransDict[i]) ] )
        end
        # Calculamos el promedio grobal 
        PriceDict[0] = mean([PriceDict[j] for j in 1:properties[:n_agents]])

    elseif properties[:priceType] == "global" # Si solo hay un precio global
        PriceDict[0] = mean([trans.Pt for trans in transactions])
        for i ∈ 1:properties[:n_agents]
            PriceDict[i] = PriceDict[0]
        end
    end

    # Ya que tenemos nuestros dos diccionarios para 
    # precios y transacciones los regresamos
    return TransDict, PriceDict
end


"""
    executeTransactions(model, TransDict, PriceDict)

    model : objeto model de Agents.jl 
    TransDict : Diccionario entregado por unzipTransactions
    PriceDict : Diccionario entregado por unzipTransactions

    Esta función propaga todos los cambios que son necesarios 
    para que las transacciones esten correctamente ejecutadas y 
    ordena a los agentes a que juzguen las transacciones para poder 
    tomar en cuenta esta información a la hora de actualizar la 
    topología de los agentes.
"""
function executeTransactions!(model, TransDict, PriceDict)
    for agent in allagents(model)
        updateAgentWealth!(agent, TransDict, PriceDict, model.properties.properties)
    end
end

"""
    updateAgentWealth!(agent, TransDict, PriceDict, properties)


function updateAgentWealth!(agent, TransDict, PriceDict, properties)

Actualiza la riqueza del agente y el valor del vínculo que dió lugar a la 
transacción. 

Actualizamos la calificación del vínculo con la contraparte 
Aquí debo crear la key en el dict si hace falta
actualizo el valor de vínculo como un promedio ponderado 
de lo anterior con el nuevo valor
"""
function updateAgentWealth!(agent, TransDict, PriceDict, properties)
    id = agent.id
    cash = agent.wealth.cash 
    stock = agent.wealth.stock 
    Transactions = TransDict[id]
    Price = PriceDict[id]

    # estructura de trans [P pred, id_contraparte, P pred contraparte, Pt, x]
    #                       [Pv, comprador, Pc, Pt, -x]
    for trans in Transactions
        # actualizo riqueza 
        P_pred = trans[1]
        id_contraparte = trans[2]
        Pt = trans[4]
        x = trans[5]
        cash = cash + Pt * x
        stock = stock + x
        judgement = judgeTransaction(Pt, Price, P_pred, properties)

        # Actualizamos la calificación del vínculo con la contraparte 
        # Aquí debo crear la key en el dict si hace falta
        # actualizo el valor de vínculo como un promedio ponderado 
        # de lo anterior con el nuevo valor
        α =  0.950
        if haskey(agent.neighborhud, id_contraparte)
            # Si ya está no hago nada
        else
            agent.neighborhud[:id_contraparte] = 0
        end
        A = agent.neighborhud[:id_contraparte]
        A = A*α + judgement*(1-α)
        agent.neighborhud[:id_contraparte] = A
    end  

end

"""
judgeTransaction(Pt, Price, P_pred, properties)

Pt : precio conseguido en la transacción 
Price : Precio final observado por el agente 
P_pred : precio predicho por el agente usado en la transacción

Juzga la transacción, si fue beneficiosa para el agente regresa un valor
positivo, de lo contrario uno negativo. 
"""
function judgeTransaction(Pt, Price, P_pred, properties)
    if properties[:transJudgement] == "continuous"
        if Price < P_pred 
            return (Pt - P_pred)/(P_pred - Price)
        else
            return (P_pred - Pt)/(Price - P_pred)
        end
    elseif properties[:transJudgement] == "discrete"
        if Price < P_pred 
            if Pt > P_pred 
                return 1 
            else 
                return 0 
            end
        else 
            if Pt < P_pred 
                return 1 
            else
                return 0 
            end
        end
    end
end

