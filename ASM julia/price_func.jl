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

# Y esta es toda la información que necesito para la función.

function calcTransaction(agente1::Trader,agente2::Trader)
    a1,b1 = predict(agente1.reglas,model.properties.des.des)
    a2,b2 = predict(agente2.reglas,model.properties.des.des)

    Pt = model.properties.des.precios[end] # último precio 
    Df = model.properties.des.des[end] # último dividendo

    P1 = a1*(Pt + Dt) + b1 
    P2 = a2*(Pt + Dt) + b2 

    # Y ahora toca tomar el precio de acuerdo con el criterio seleccionado, ya sea 
    # justo a la mitad a proporcional a la riqueza de los agentes.
    
end