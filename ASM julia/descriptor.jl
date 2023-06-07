# en este documento se detallarán los pormenores de la implemtentación
# del descriptor de mercado usado en mi modelo.

# Idealmente habrá un agente que será el que lleve acabo los cálculos
# relacionados al precio y su descripción

# module Descriptors

#export updateDescriptor!, initializeDescriptor, updateDescriptors!

using Random, Distributions, Statistics
using Agents

##########################################
#########################################
########
######## Agregar varianza empírica del precio
########
##########################################
########################################


# funcionan correctamente mis funciones :D entonces ya tengo las
# funciones básicas del descriptor y también ya tengo
# la estrucura que tendrá el descriptor
# tengo ya todo lo necesario para programar la manera en que se activarán
# las reglas

# des.precios
#
# sqrt(var(des.precios))
#
# plot(des.precios)
#
# des = initializeDescriptor(properties)
# des = updateDescriptor(10000,des)

"""
    updateDescriptors!(model, PriceDict)

entradas:
model : objeto model de Agents.jl 
PriceDict : Dict de precios observados por los agentes tal cómo
    es entregado por unzipTransactions()


    Esta funcion actualiza los descriptores individuales de cada
    agente con el precio observado por el agente

    Símula el proceso de Ornstein_Uhlenbeck para que la informacion 
    sobre el dividendo sea la misma para todos los agentes
"""
function updateDescriptors!(model, PriceDict)
    properties = model.properties.properties
    an_agent = getindex(model,1)
    an_des = an_agent.des

    if properties[:activeDividend] == true
        d = Ornstein_Uhlenbeck(an_des.dividendo[end], 5, properties)
    else
        d = 1
    end

    for agent in allagents(model)
        updateDescriptor!(PriceDict[agent.id], agent.des, simDiv = false, D = d)
    end

    # update global descriptor 
    p = mean([PriceDict[i] for i in 1:nagents(model)]) # reference global price
    updateDescriptor!(p, model.properties.des, simDiv = false, D = d)
end

"""
    updateDescriptor!(P, des)

entradas:
p : nuevo precio
des : descriptor 

simDiv : indica si se debe simular el proceso de Ornstein_Uhlenbeck 
    o si el nuevo valor sera dado como parametro a la función 
D : el nuevo dividendo dado cómo parametro, esto se usa cuando el 
    el nuevo valor del dividendo ya se calculo en otra parte.

Esta función actualiza el descriptor con el nuevo precio
Los parámetros adicionales se usan ahora que el modelo 
fue actualizado para que cada agente tenga su propio descriptor 
y así permitir por completo la existencia de precios locales.

"""
function updateDescriptor!(P, des; simDiv=True, D = 1)
    # Primero tengo que actualiza las series del precio y dividendo
    deleteat!(des.precios, 1)
    push!(des.precios, P)

    deleteat!(des.dividendo, 1)

    if des.properties[:activeDividend] == true
        if simDiv == true
            d = Ornstein_Uhlenbeck(des.dividendo[end], 5, des.properties)
        else 
            d = D
        end
    else 
        d = 1
    end
    push!(des.dividendo, d )

    # y se recalcula el descriptor
    T = des.properties[:descriptor]
    if T == 1
        descriptor = LeBaronDesUpdate(des.precios, des.dividendo, des.properties)
    elseif T == 2
        descriptor = JoshiDesUpdate(des.precios, des.dividendo, des.properties)
    elseif T == 3
        descriptor = EhrentreichDesUpdate(des.precios, des.dividendo, des.properties)
    end
    des.des = descriptor
    #return des

    # Actualiza la varianza observada 
    des.var = var(des.precios + des.dividendo)

    return

end # function

mutable struct Descriptor
    precios
    dividendo
    des # corto de descriptor
    properties # el tipo de descriptor, LeBaron, Joshi, etc.
    var # varianza observada del descriptor, del precio más dividendo
end # mutable struct

"""
    initializeDescriptor(properties)

Aquí se inicializa al descriptor, se simulan procesos de Ornstein_Uhlenbeck
para el precio y el dividendo y se actualiza el descriptor de mercado
con respecto a estas simulaciones
"""
function initializeDescriptor(properties)
    precios = zeros(501)# el tamaño es por los MA de 500
    dividendo = zeros(501)
    precios[1] = properties[:iniPrecio]
    dividendo[1] = properties[:dividendMean]
    for i in 2:501
        precios[i] = Ornstein_Uhlenbeck(precios[i-1], 10, properties)
    end
    # si quiero que no se genere el dividendo es aquí
    for i in 2:501
        dividendo[i] = Ornstein_Uhlenbeck(dividendo[i-1], 5, properties)
    end

    # lo siguiente depende del descriptor que se esté usando
    desType = properties[:descriptor]
    if desType == 1 # LeBaron
        descriptor = LeBaronDesUpdate(precios,dividendo,properties)
    elseif desType == 2 # Joshi
        descriptor = JoshiDesUpdate(precios,dividendo, properties)
    elseif desType == 3 # Ehrentreich
        descriptor = EhrentreichDesUpdate(precios, dividendo, properties)
    end

    # Calculamos la varianza empírica del precio más el dividendo
    empVar = var(precios + dividendo)

    return Descriptor(precios, dividendo, descriptor, properties,empVar)
end # function

"""
    Ornstein_Uhlenbeck(p)

Esta función calcula el siguiente tiempo del dividendo o del precio
siguiente un proceso de Ornstein Uhlenbeck con los siguientes parámetros
ρ = 1
d = 100
ϵ ~ Normal(0, 10)
"""
function Ornstein_Uhlenbeck(p, σ, properties)
    d = properties[:dividendMean]
    ρ = 1
    ϵ = rand(Normal(0,σ))
    return d + ρ*(p - d) + ϵ
end # function

"""
    LeBaronDesUpdate(precios)

Esta función actualiza los valores del descriptor usando la serie de tiempo
dada y regresa el vector del descriptor correspondiente
"""
function LeBaronDesUpdate(precios, dividendo, properties)
    des = zeros(7)
    interest = properties[:interestRate]

    des[1] = LeBaron_1(precios,dividendo,interest)
    des[2] = LeBaron_2(precios,dividendo,interest)
    des[3] = LeBaron_3(precios,dividendo,interest)
    des[4] = LeBaron_4(precios,dividendo,interest)
    des[5] = LeBaron_5(precios,dividendo,interest)
    des[6] = LeBaron_6(precios,dividendo,interest)
    des[7] = LeBaron_7(precios,dividendo,interest)

    return des
end # function

function LeBaron_1(precios, dividend, I)
    return precios[end] * I/dividend[end]
end # function
function LeBaron_2(precios, dividend, I)
    return precios[end] > mean(precios[end-5:end])
end # function
function LeBaron_3(precios, dividend, I)
    return precios[end] > mean(precios[end-10:end])
end # function
function LeBaron_4(precios, dividend, I)
    return precios[end] > mean(precios[end-100:end])
end # function
function LeBaron_5(precios, dividend, I)
    return precios[end] > mean(precios[end-500:end])
end # function
function LeBaron_6(precios, dividend, I)
    return true
end # function
function LeBaron_7(precios, dividend, I)
    return false
end # function



"""
    JoshiDesUpdate(precios, dividendo, properties)

Esta función actualiza el descriptor de Joshi et. al. usando las series de
tiempo dadas, el orden de los bits cambian, se agrupan a todos los bits
reales en los primeros bits, es decir, los bits 23-32 y 33-42 serán los
primeros bits de descriptor aquí
"""
function JoshiDesUpdate(precios, dividendo, properties)
    des = zeros(43)

    des[1] = Joshi_1(precios,dividendo,properties)
    des[2] = Joshi_2(precios,dividendo,properties)
    des[3] = Joshi_3(precios,dividendo,properties)
    des[4] = Joshi_4(precios,dividendo,properties)
    des[5] = Joshi_5(precios,dividendo,properties)
    des[6] = Joshi_6(precios,dividendo,properties)
    des[7] = Joshi_7(precios,dividendo,properties)
    des[8] = Joshi_8(precios,dividendo,properties)
    des[9] = Joshi_9(precios,dividendo,properties)
    des[10] = Joshi_10(precios,dividendo,properties)
    des[11] = Joshi_11(precios,dividendo,properties)
    des[12] = Joshi_12(precios,dividendo,properties)
    des[13] = Joshi_13(precios,dividendo,properties)
    des[14] = Joshi_14(precios,dividendo,properties)
    des[15] = Joshi_15(precios,dividendo,properties)
    des[16] = Joshi_16(precios,dividendo,properties)
    des[17] = Joshi_17(precios,dividendo,properties)
    des[18] = Joshi_18(precios,dividendo,properties)
    des[19] = Joshi_19(precios,dividendo,properties)
    des[20] = Joshi_20(precios,dividendo,properties)
    des[21] = Joshi_21(precios,dividendo,properties)
    des[22] = Joshi_22(precios,dividendo,properties)
    des[23] = Joshi_23(precios,dividendo,properties)
    des[24] = Joshi_24(precios,dividendo,properties)
    des[25] = Joshi_25(precios,dividendo,properties)
    des[26] = Joshi_26(precios,dividendo,properties)
    des[27] = Joshi_27(precios,dividendo,properties)
    des[28] = Joshi_28(precios,dividendo,properties)
    des[29] = Joshi_29(precios,dividendo,properties)
    des[30] = Joshi_30(precios,dividendo,properties)
    des[31] = Joshi_31(precios,dividendo,properties)
    des[32] = Joshi_32(precios,dividendo,properties)
    des[33] = Joshi_33(precios,dividendo,properties)
    des[34] = Joshi_34(precios,dividendo,properties)
    des[35] = Joshi_35(precios,dividendo,properties)
    des[36] = Joshi_36(precios,dividendo,properties)
    des[37] = Joshi_37(precios,dividendo,properties)
    des[38] = Joshi_38(precios,dividendo,properties)
    des[39] = Joshi_39(precios,dividendo,properties)
    des[40] = Joshi_40(precios,dividendo,properties)
    des[41] = Joshi_41(precios,dividendo,properties)
    des[42] = Joshi_42(precios,dividendo,properties)
    des[43] = Joshi_43(precios,dividendo,properties)

    return des
end # function

function Joshi_1(precios, dividendo, properties)
    return dividendo[end] / properties[:dividendMean]
end # function
function Joshi_2(precios, dividendo, properties)
    return precios[end] * properties[:interestRate] / dividendo[end]
end # function
function Joshi_3(precios, dividendo, properties)
    return true
end # function
function Joshi_4(precios, dividendo, properties)
    return false
end # function
function Joshi_5(precios, dividendo, properties)
    return rand([0,1])
end # function

function Joshi_6(precios, dividendo, properties)
    return dividendo[end] > dividendo[end-1]
end # function
function Joshi_7(precios, dividendo, properties)
    return dividendo[end-1] > dividendo[end-2]
end # function
function Joshi_8(precios, dividendo, properties)
    return dividendo[end-2] > dividendo[end-3]
end # function
function Joshi_9(precios, dividendo, properties)
    return dividendo[end-3] > dividendo[end-4]
end # function
function Joshi_10(precios, dividendo, properties)
    return dividendo[end-4] > dividendo[end-5]
end # function

function Joshi_11(precios, dividendo, properties)
    return mean(dividendo[end-5+1:end]) > mean(dividendo[end-6+1:end-1])
end # function
function Joshi_12(precios, dividendo, properties)
    return mean(dividendo[end-20+1:end]) > mean(dividendo[end-1-20+1:end-1])
end # function
function Joshi_13(precios, dividendo, properties)
    return mean(dividendo[end-100+1:end]) > mean(dividendo[end-1-100+1:end-1])
end # function
function Joshi_14(precios, dividendo, properties)
    return mean(dividendo[end-500+1:end]) > mean(dividendo[end-1-500+1:end-1])
end # function

function Joshi_15(precios, dividendo, properties)
    return dividendo[end] > mean(dividendo[end-5+1:end])
end # function
function Joshi_16(precios, dividendo, properties)
    return dividendo[end] > mean(dividendo[end-20+1:end])
end # function
function Joshi_17(precios, dividendo, properties)
    return dividendo[end] > mean(dividendo[end-100+1:end])
end # function
function Joshi_18(precios, dividendo, properties)
    return dividendo[end] > mean(dividendo[end-500+1:end])
end # function

function Joshi_19(precios, dividendo, properties)
    # bit 17 del Ehrentreich
    return mean(dividendo[end-5+1:end]) > mean(dividendo[end-20+1:end])
end # function
function Joshi_20(precios, dividendo, properties)
    return mean(dividendo[end-5+1:end]) > mean(dividendo[end-100+1:end])
end # function
function Joshi_21(precios, dividendo, properties)
    return mean(dividendo[end-5+1:end]) > mean(dividendo[end-500+1:end])
end # function
function Joshi_22(precios, dividendo, properties)
    return mean(dividendo[end-20+1:end]) > mean(dividendo[end-100+1:end])
end # function
function Joshi_23(precios, dividendo, properties)
    return mean(dividendo[end-20+1:end]) > mean(dividendo[end-500+1:end])
end # function
function Joshi_24(precios, dividendo, properties)
    return mean(dividendo[end-100+1:end]) > mean(dividendo[end-500+1:end])
end # function

function Joshi_25(precios, dividendo, properties)
    # bit 42 del Ehrentreich
    return precios[end] > precios[end-1]
end # function
function Joshi_26(precios, dividendo, properties)
    return precios[end-1] > precios[end-2]
end # function
function Joshi_27(precios, dividendo, properties)
    return precios[end-2] > precios[end-3]
end # function
function Joshi_28(precios, dividendo, properties)
    return precios[end-3] > precios[end-4]
end # function
function Joshi_29(precios, dividendo, properties)
    return precios[end-4] > precios[end-5]
end # function

function Joshi_30(precios, dividendo, properties)
    # bit 48 del Ehrentreich
    return mean(precios[end-5+1:end]) > mean(precios[end-6+1:end-1])
end # function
function Joshi_31(precios, dividendo, properties)
    return mean(precios[end-20+1:end]) > mean(precios[end-1-20+1:end-1])
end # function
function Joshi_32(precios, dividendo, properties)
    return mean(precios[end-100+1:end]) > mean(precios[end-1-100+1:end-1])
end # function
function Joshi_33(precios, dividendo, properties)
    return mean(precios[end-500+1:end]) > mean(precios[end-1-500+1:end-1])
end # function

function Joshi_34(precios, dividendo, properties)
    # bit 52 del Ehrentreich
    return precios[end] > mean(precios[end-5+1:end])
end # function
function Joshi_35(precios, dividendo, properties)
    return precios[end] > mean(precios[end-20+1:end])
end # function
function Joshi_36(precios, dividendo, properties)
    return precios[end] > mean(precios[end-100+1:end])
end # function
function Joshi_37(precios, dividendo, properties)
    return precios[end] > mean(precios[end-500+1:end])
end # function

function Joshi_38(precios, dividendo, properties)
    # bit 56 del Ehrentreich
    return mean(precios[end-5+1:end]) > mean(precios[end-20+1:end])
end # function
function Joshi_39(precios, dividendo, properties)
    return mean(precios[end-5+1:end]) > mean(precios[end-100+1:end])
end # function
function Joshi_40(precios, dividendo, properties)
    return mean(precios[end-5+1:end]) > mean(precios[end-500+1:end])
end # function
function Joshi_41(precios, dividendo, properties)
    return mean(precios[end-20+1:end]) > mean(precios[end-100+1:end])
end # function
function Joshi_42(precios, dividendo, properties)
    return mean(precios[end-20+1:end]) > mean(precios[end-500+1:end])
end # function
function Joshi_43(precios, dividendo, properties)
    return mean(precios[end-100+1:end]) > mean(precios[end-500+1:end])
end # function


"""
    EhrentreichDesUpdate(precios, dividendo, properties)

Función que actualiza el descriptor de Ehrentreich
"""
function EhrentreichDesUpdate(precios, dividendo, properties)
    des = zeros(46)
    d = properties[:dividendMean]
    I = properties[:interestRate]

    des[1] = Ehrentreich_1(precios, dividendo, d, I)
    des[2] = Ehrentreich_2(precios, dividendo, d, I)
    des[3] = Ehrentreich_3(precios, dividendo)
    des[4] = Ehrentreich_4(precios, dividendo)
    des[5] = Ehrentreich_5(precios, dividendo)
    des[6] = Ehrentreich_6(precios, dividendo)
    des[7] = Ehrentreich_7(precios, dividendo)
    des[8] = Ehrentreich_8(precios, dividendo)
    des[9] = Ehrentreich_9(precios, dividendo)
    des[10] = Ehrentreich_10(precios, dividendo)
    des[11] = Ehrentreich_11(precios, dividendo)
    des[12] = Ehrentreich_12(precios, dividendo)
    des[13] = Ehrentreich_13(precios, dividendo)
    des[14] = Ehrentreich_14(precios, dividendo)
    des[15] = Ehrentreich_15(precios, dividendo)
    des[16] = Ehrentreich_16(precios, dividendo)
    des[17] = Ehrentreich_17(precios, dividendo)
    des[18] = Ehrentreich_18(precios, dividendo)
    des[19] = Ehrentreich_19(precios, dividendo)
    des[20] = Ehrentreich_20(precios, dividendo)
    des[21] = Ehrentreich_21(precios, dividendo)
    des[22] = Ehrentreich_22(precios, dividendo)
    des[23] = Ehrentreich_23(precios, dividendo)
    des[24] = Ehrentreich_24(precios, dividendo)
    des[25] = Ehrentreich_25(precios, dividendo)
    des[26] = Ehrentreich_26(precios, dividendo)
    des[27] = Ehrentreich_27(precios, dividendo)
    des[28] = Ehrentreich_28(precios, dividendo)
    des[29] = Ehrentreich_29(precios, dividendo)
    des[30] = Ehrentreich_30(precios, dividendo)
    des[31] = Ehrentreich_31(precios, dividendo)
    des[32] = Ehrentreich_32(precios, dividendo)
    des[33] = Ehrentreich_33(precios, dividendo)
    des[34] = Ehrentreich_34(precios, dividendo)
    des[35] = Ehrentreich_35(precios, dividendo)
    des[36] = Ehrentreich_36(precios, dividendo)
    des[37] = Ehrentreich_37(precios, dividendo)
    des[38] = Ehrentreich_38(precios, dividendo)
    des[39] = Ehrentreich_39(precios, dividendo)
    des[40] = Ehrentreich_40(precios, dividendo)
    des[41] = Ehrentreich_41(precios, dividendo)
    des[42] = Ehrentreich_42(precios, dividendo)
    des[43] = Ehrentreich_43(precios, dividendo)
    des[44] = Ehrentreich_44(precios, dividendo)
    des[45] = Ehrentreich_45(precios, dividendo)
    des[46] = Ehrentreich_46(precios, dividendo)

    return des

end # function

function Ehrentreich_1(precios, dividendo, d, I)
    return dividendo[end] / d
end # function
function Ehrentreich_2(precios, dividendo, d, I)
    return precios[end] * I / dividendo[end]
end # function
function Ehrentreich_3(precios, dividendo)
    # Modificada para considerar solo el promedio de los últimos 500 tiempos 
    return precios[end]/mean(precios[end-500+1:end])
end # function

function Ehrentreich_4(precios, dividendo)
    # bit 14
    return dividendo[end] > dividendo[end-1]
end # function
function Ehrentreich_5(precios, dividendo)
    return dividendo[end-1] > dividendo[end-2]
end # function
function Ehrentreich_6(precios, dividendo)
    return dividendo[end-2] > dividendo[end-3]
end # function
function Ehrentreich_7(precios, dividendo)
    return dividendo[end-3] > dividendo[end-4]
end # function

function Ehrentreich_8(precios, dividendo)
    # bit 18
    return mean(dividendo[end-5+1:end]) > mean(dividendo[end-6+1:end-1])
end # function
function Ehrentreich_9(precios, dividendo)
    return mean(dividendo[end-20+1:end]) > mean(dividendo[end-1-20+1:end-1])
end # function
function Ehrentreich_10(precios, dividendo)
    return mean(dividendo[end-100+1:end]) > mean(dividendo[end-1-100+1:end-1])
end # function
function Ehrentreich_11(precios, dividendo)
    return mean(dividendo[end-500+1:end]) > mean(dividendo[end-1-500+1:end-1])
end # function

function Ehrentreich_12(precios, dividendo)
    # bit 22
    return dividendo[end] > mean(dividendo[end-5+1:end])
end # function
function Ehrentreich_13(precios, dividendo)
    return dividendo[end] > mean(dividendo[end-20+1:end])
end # function
function Ehrentreich_14(precios, dividendo)
    return dividendo[end] > mean(dividendo[end-100+1:end])
end # function
function Ehrentreich_15(precios, dividendo)
    return dividendo[end] > mean(dividendo[end-500+1:end])
end # function

function Ehrentreich_16(precios, dividendo)
    # bit 26
    return mean(dividendo[end-5+1:end]) > mean(dividendo[end-10+1:end])
end # function
function Ehrentreich_17(precios, dividendo)
    return mean(dividendo[end-5+1:end]) > mean(dividendo[end-100+1:end])
end # function
function Ehrentreich_18(precios, dividendo)
    return mean(dividendo[end-5+1:end]) > mean(dividendo[end-500+1:end])
end # function
function Ehrentreich_19(precios, dividendo)
    return mean(dividendo[end-10+1:end]) > mean(dividendo[end-100+1:end])
end # function
function Ehrentreich_20(precios, dividendo)
    return mean(dividendo[end-10+1:end]) > mean(dividendo[end-500+1:end])
end # function
function Ehrentreich_21(precios, dividendo)
    return mean(dividendo[end-100+1:end]) > mean(dividendo[end-500+1:end])
end # function

function Ehrentreich_22(precios, dividendo)
    # bit 7 Technical
    return precios[end] > precios[end-1]
end # function
function Ehrentreich_23(precios, dividendo)
    return precios[end-1] > precios[end-2]
end # function
function Ehrentreich_24(precios, dividendo)
    return precios[end-2] > precios[end-3]
end # function
function Ehrentreich_25(precios, dividendo)
    return precios[end-3] > precios[end-4]
end # function
function Ehrentreich_26(precios, dividendo)
    return precios[end-4] > precios[end-5]
end # function

function Ehrentreich_27(precios, dividendo)
    # bit 12 Technical
    return mean(precios[end-5+1:end]) > mean(precios[end-6+1:end-1])
end # function
function Ehrentreich_28(precios, dividendo)
    return mean(precios[end-10+1:end]) > mean(precios[end-1-10+1:end-1])
end # function
function Ehrentreich_29(precios, dividendo)
    return mean(precios[end-20+1:end]) > mean(precios[end-1-20+1:end-1])
end # function
function Ehrentreich_30(precios, dividendo)
    return mean(precios[end-100+1:end]) > mean(precios[end-1-100+1:end-1])
end # function
function Ehrentreich_31(precios, dividendo)
    return mean(precios[end-500+1:end]) > mean(precios[end-1-500+1:end-1])
end # function

function Ehrentreich_32(precios, dividendo)
    # bit 17 Technical
    return precios[end] > mean(precios[end-5+1:end])
end # function
function Ehrentreich_33(precios, dividendo)
    return precios[end] > mean(precios[end-10+1:end])
end # function
function Ehrentreich_34(precios, dividendo)
    return precios[end] > mean(precios[end-20+1:end])
end # function
function Ehrentreich_35(precios, dividendo)
    return precios[end] > mean(precios[end-100+1:end])
end # function
function Ehrentreich_36(precios, dividendo)
    return precios[end] > mean(precios[end-500+1:end])
end # function

function Ehrentreich_37(precios, dividendo)
    # bit 22 Technical
    return mean(precios[end-5+1:end]) > mean(precios[end-10+1:end])
end # function
function Ehrentreich_38(precios, dividendo)
    return mean(precios[end-5+1:end]) > mean(precios[end-20+1:end])
end # function
function Ehrentreich_39(precios, dividendo)
    return mean(precios[end-5+1:end]) > mean(precios[end-100+1:end])
end # function
function Ehrentreich_40(precios, dividendo)
    return mean(precios[end-5+1:end]) > mean(precios[end-500+1:end])
end # function
function Ehrentreich_41(precios, dividendo)
    return mean(precios[end-10+1:end]) > mean(precios[end-20+1:end])
end # function
function Ehrentreich_42(precios, dividendo)
    return mean(precios[end-10+1:end]) > mean(precios[end-100+1:end])
end # function
function Ehrentreich_43(precios, dividendo)
    return mean(precios[end-10+1:end]) > mean(precios[end-500+1:end])
end # function
function Ehrentreich_44(precios, dividendo)
    return mean(precios[end-20+1:end]) > mean(precios[end-100+1:end])
end # function
function Ehrentreich_45(precios, dividendo)
    return mean(precios[end-20+1:end]) > mean(precios[end-500+1:end])
end # function
function Ehrentreich_46(precios, dividendo)
    return mean(precios[end-100+1:end]) > mean(precios[end-500+1:end])
end # function

# end  # module Descriptor
