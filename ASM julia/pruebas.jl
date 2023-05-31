pruebas.jl 


# Aquí están las diferentes pruebas que le aplicaré  mi modelo. 


using Distributions
using StatsBase
using GLM


# Ejemplo de ejecución



# Así se usan las funciones con el resultado del ensemble run 
mdfs = desEnsableDf(mdf)
calcReturns!(mdfs)

adfs = desEnsableDf(adf)



mdfs


# Así se realizan las pruebas al resultado de una ejecución
columnas = ["price", "retornos"]
funciones = [mean, var, skewness, kurtosis, hurstExponentRSMethod, FFTLogAdjCoef, 
    calcSeriesShannonEntropy]

calcStats!(mdfs[1], columnas, funciones, 200)

# Falta agregar la columna calculada al DataFrame 
calculatePredictionsShannonEntropy!(mdfs[1], adfs[1])


mdfs[1]

plot(mdfs[1].retornosCalcSeriesShannonEntropy[300:end])
plot(mdfs[1].priceSkewness)
plot(mdfs[1].price)
plot!(mdfs[2].price)
plot!(mdfs[3].price)
plot!(mdfs[4].price)
plot!(mdfs[5].price)
plot!(mdfs[6].price)

plot(mdfs[6].retornos[50:end])







# Y lo único que hace falta es calcular la entropía de Shannon sobre las predicciones 
# de los agentes y agregarlo al DataFrame


# Primero hay que cargar todas las funciones


# Simulación de un movimiento browniano y de una caminata aleatoria
brownian = [0.0]
for i in 2:10000
    ϵ = rand(Normal(0,1))
    append!(brownian, brownian[i-1] + ϵ)
end
brownian 
plot(1:10000,brownian)
hurstExponentRSMethod(brownian)

randomWalk = [0]
for i in 2:10000
    step = rand(Bernoulli(0.5))
    if step == 0
        step = -1
    end
    append!(randomWalk,randomWalk[i-1]+step)
end
plot(1:10000,randomWalk)
hurstExponentRSMethod(randomWalk)



# Me hará falta una función que una los diferentes dataframes de las diferentes ejecuciones, el 
# tiempo se pierde en cada una de las ejecuciones. Crearé primero una corrida de ejemplo para
# programar lo que quiero. 

# Me regresa el dataframe grande en un dataframe por ejecución
function desEnsableDf(df)
    executions = []
    for ensemble in unique(df.ensemble)
        # para cada uno de los ensemble 
        # filtrar 
        tempdf = filter(:ensemble => x -> x == ensemble,df)

        # ordenar por step
        sort!(tempdf, :step)

        # a la lista 
        append!(executions,[tempdf])
    end
    return executions
end

"""
    appendDfs(dfsList)

Une en uno solo los dataframe dados a la función dentro de un vector. 
Asume que cada uno de los dataframes dados está ordenado

El orden en que se dan los dataframes importa ya que compensa por la pérdida de memoria 
de ejecuciones anteriores y otorga un tiempo único. corrige los steps para repeticiones 
"""
function appendDfs(dfsList)
    # Creamos un Df vacío 
    tempDf = popfirst!(dfsList)
    while !isempty(dfsList)
        df = popfirst!(dfsList)
        # calcula el primer el último step en tempDf 
        step = tempDf[nrow(tempDf) , :step]

        # suma el step en df 
        df.step = df.step .+ (step + 1)


        # pega el df en tempDf
        vcat(tempDf, df)
    end
    return tempDf
end

"""
    calcReturns!(df)

df: dataframe que contiene la serie de precios ordenada en la columna :getPrice 

Calcula los retornos en los precios de la serie de tiempo y agrega la columna al DataFrame

"""
function calcReturns!(df::DataFrame)
    retornos = Float64[]

    for i in eachindex(df.price)
        if i == 1
            append!(retornos,1/0)
        else
            retorno = (df.price[i] - df.price[i-1])/df.price[i-1]
            append!(retornos,retorno)
        end
    end

    df[!, :retornos] = retornos
    
end

"""
    calcReturns!(series)

series: vector de dataframes de series de tiempo independientes 

ejecuta la función homónima pero para dataframes individuales.
agrega a cada uno de los dataframes una columna con los retornos de la serie.
"""
function calcReturns!(series::Array{Any})
    for serie in series 
        calcReturns!(serie)
    end    
end



# ahora debo programar las 6 funciones de estadísticos.

# Primeros los 4 momentos muestrales, que probablemente ya estén programados
using StatsBase

serie = series[1]

mean(serie.retornos[2:end])
var(serie.retornos[2:end])
skewness(serie.retornos[2:end])
kurtosis(serie.retornos[2:end])


# Aquí la función para calcular la entropía sobre las predicciones

using Distributions
using StatsBase

# Función que filtra las predicciones de los agentes para un tiempo particular
# y las deja en forma de vector listas para ser comidas por 
# calculatePredictionsShannonEntropy

### Función que come el mdf, el adf y agrega la nueva columna al mdf 


function calculatePredictionsShannonEntropy!(mdf::DataFrame, adf::DataFrame)
    temp = zeros(size(mdf)[1])

    for i in eachindex(temp)
        preds = filterPredictionsForShannon(adf, i-1) # tenemos step == 0
        entropy = calculatePredictionsShannonEntropy(preds)
        temp[i] = entropy
    end

    mdf[!, "predictionsShannonEntropy"] = temp

end

"""
filterPredictionsForShannon(adf, i)

adf : DataFrame con la información de los agentes
i : tiempo deseado 

Una vez que todas las ejecuciones han sido juntadas en un solo vector 
se puede usar esta función para agregar la entropía de Shannon sobre 
las predicciones al DataFrame mdf
"""
function filterPredictionsForShannon(adf, i)

    return filter(:step => ==(i), adf).getAgentPrice
    
end

"""
calculatePredictionsShannonEntropy(predictions)

    predictions : el vector de predicciones hechas por los agentes 
    sobre las cuales se desea calcular la entropía 

    Redonda las predicciones a las decenas, ajusta una distribución de proba categórica
    y luego calcula la entropía de Shannon para la distribución 

"""
function calculatePredictionsShannonEntropy(vect::Array{Float64})
    #println("entrada: ",vect)

    vect = floor.(vect ./ 10)
    #println("redondeo: ",vect)

    p = fit_mle(Categorical, vect)
    #println(p) # ajusta un distribución de proba

    return Distributions.entropy(p) # calcula la entropía de Shannon
end





######     Ayuda para mis cálculos a mano 

"""
hurstExponentRSMethod(serie)

serie : serie de tiempo como vector de reale 

calcula el exponente de Hurst usando el método de R/S. 

Quita la tendencia a los datos y usa segmentos con longitudes iguales a todas las posibles potencias 
de dos. Finalmente ajusta una recta al logaritmo del promedio de los Rescaled Ranges calculados.

"""
function hurstExponentRSMethod(serie)

    ave_rescaled_ranges, scales = calcAveRescaledRanges(serie)
    log_coefs = log.(ave_rescaled_ranges)
    data = DataFrame(scales = scales, log_coefs = log_coefs)
    modelo = lm(@formula(log_coefs ~ scales), data )

    return coef(modelo)[2]
    
end


"""
calcAveRescaledRanges(serie)

serie: serie de tiempo

calcula los rangos reescalados (Rescaled Ranges) de las diferentes subseries 
de longitudes iguales a potencias de 2 que caben en el vector y calcula el 
promedio por potencia de 2  
"""
function calcAveRescaledRanges(serie; init_k = 2, base = 2)

    # Primero seguimos la observación del prof Hansen y le quitamos la tendencia a los datos 
    serie = detrendData(serie)

    # Ahora, para cada k potencia de 2 que quepan en n 
    # para todas las las subseries de longitud k 

    # calculamos las diferentes potencias posibles 
    n = length(serie)
    scales = Float64[]
    ave_rescaled_ranges = Float64[]
    for k in init_k:floor(Int,log(base,n))
        # y todos los diferentes intervalos de esa longitud 
        #k = 7
        #2^k

        max_cont = floor(Int,n / (base^k))
        cont = 0
        rescaled_ranges = Float64[]
        while (cont) * base^k < n 
            if cont == 0
                rango = 1:(base^k)
            elseif cont == max_cont
                rango = (n-base^k+1):n
            else
                rango = (base^k*cont):(base^k*(cont+1)-1)
            end

            subserie = serie[rango]
            rescaled_range = calcRescaledRange(subserie)
            append!(rescaled_ranges, rescaled_range)

            cont += 1
        end
        rescaled_ranges

        #std(rescaled_ranges)
        ave_rescaled_range = mean(rescaled_ranges)

        append!(scales,k)
        append!(ave_rescaled_ranges,ave_rescaled_range)
    end
    return ave_rescaled_ranges, scales
end
"""
calcRescaledRange(serie)

calcula el rango reescalado de una subserie, se usa para calcular el 
exponente de Hurst 
"""
function calcRescaledRange(serie; complete = false)
    media = mean(serie)
    serie_m = serie .- media

    serie_cum = cumsum(serie_m)

    # Ahora calculo el rango 
    range = maximum(serie_cum) - minimum(serie_cum)

    # y la desviación estandar de la serie original
    stdd = std(serie,corrected = false)

    rescaled_range = range / stdd

    if complete 
        return rescaled_range, range, stdd
    else
        return rescaled_range
    end
end
    
"""
detrendData(serie)

serie : serie de tiempo cómo vector de reales 

Quita la tendencia a los datos para evitar que el exponente de Hurst sea siempre igual a 1

Fórmula de Hansen
"""
function detrendData(serie)
    T = length(serie)
    new = zeros(T)

    first = serie[1]
    last = serie[end]

    for i in eachindex(serie)
        new[i] = serie[i] - (last - first)*i/T 
    end
    return new    
end


######################### Aplicar las pruebas al precio  y retornos



function calcStats!(df, columnas, funciones, windowSize)

    for columna in columnas
        for funcion in funciones
            newCol = calcStat(df, columna, funcion, windowSize)
            # agregamos la nueva columna al dataframe 
            colName = columna * uppercasefirst(String(Symbol(funcion)))

            df[!, colName] = newCol
        end
    end  
end

function calcStat(df, columna, funcion, windowSize)
    # Prealoco un vector
    temp = zeros(size(df)[1])

    #lo lleno con los MA de una sola función
    if windowSize > size(df)[1] 
        error("Toma un tamaño de ventana menor a la longitud de la serie")
    end

    for i in 1:(size(df)[1] - windowSize)
        window = i:(i+windowSize)
        muestra = df[!,columna][window]
        temp[i+windowSize] = funcion(muestra)
    end
     
    # regreso el vector calculado 
    return temp
end


"""
calcSeriesShannonEntropy(vect)

vect : serie de tiempo como vector de flotantes


Come una serie de tiempo y calcula la entropía de Shannon usando el 
método SAX, de discretizar en un alfabeto

"""
function calcSeriesShannonEntropy(vect)

    max = maximum(vect)
    min = minimum(vect)

    midPoint = (max - min)/2
    lowPoint = midPoint - (max - min) / 4
    highPoint = midPoint + (max - min) / 4

    new = zeros(length(vect))

    for i in eachindex(vect)
        new[i] = toAlphabet(vect[i], lowPoint, midPoint, highPoint)
    end 

    new = Int.(round.(new))

    # Y ahora calculamos la entropia sobre la serie traducida al alfabeto 
    p = fit_mle(Categorical, vect)
    #println(p) # ajusta un distribución de proba
    return Distributions.entropy(p)
    
end

function toAlphabet(x, lowPoint, midPoint, highPoint)

    if x < lowPoint
        return 0
    elseif x < midPoint
        return 1 
    elseif x < highPoint
        return 2 
    else
        return 3
    end

end