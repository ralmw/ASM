pruebas.jl 


# Aquí están las diferentes pruebas que le aplicaré  mi modelo. 

# el primer paso es transformar el enorme dataframe que recibo en un vector de dataframes de precios 
# que me permita procesar cada una de las series de tiempo de manera individual.
# come el dataframe come el dataframe y para cada valor diferente de ensamble crea un dataframe 
# con precisamente esos datos y los ordena por el tiempo de ejecución. 

# usando datos de ejemplo resultado del ensemble run de ejemplo en run.jl
last(adf,10)
last(mdf,10)

using Distributions
using StatsBase
using GLM

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

    for i in eachindex(df.getPrice)
        if i == 1
            append!(retornos,1/0)
        else
            retorno = (df.getPrice[i] - df.getPrice[i-1])/df.getPrice[i-1]
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


# Así se usan las funciones con el resultado del ensemble run 

series = desEnsableDf(mdf)
calcReturns!(series)

series

# ahora debo programar las 6 funciones de estadísticos.

# Primeros los 4 momentos muestrales, que probablemente ya estén programados
using StatsBase

serie = series[1]

mean(serie.retornos[2:end])
var(serie.retornos[2:end])
skewness(serie.retornos[2:end])
kurtosis(serie.retornos[2:end])


# como lo de kolmogorov se ve muy incómodo no lo quiero hacer, pasemos a la entropía de Shannon
# Que es algo que perfectamente puedo hacer yo solito. 

# La idea es que tengo que discretizar el espacio en dónde están mis estimaciones del precio y 
# luego ya directamente calcular la entropía con la fórmula, pienso hacerlo sobre las decenas. 
# redondear las predicciones hasta las decenas y luego calcular la entropía de Shannon

using ComplexityMeasures

adf.getAgentPrediction

entropy_wavelet(adf.getAgentPrediction)

filter(:step => x -> x == 100, adf)


# Aquí la función para calcular la entropía sobre las predicciones

using Distributions
using StatsBase

"""
calculatePredictionsShannonEntropy(predictions)

    predictions : el vector de predicciones hechas por los agentes 
    sobre las cuales se desea calcular la entropía 

    Redonda las predicciones a las decenas, ajusta una distribución de proba categórica
    y luego calcula la entropía de Shannon para la distribución 

"""
function calculatePredictionsShannonEntropy(vect)
    println("entrada: ",vect)

    vect = floor.(vect ./ 10)
    println("redondeo: ",vect)

    p = fit_mle(Categorical, vect)
    println(p) # ajusta un distribución de proba

    return Distributions.entropy(p) # calcula la entropía de Shannon
end



# Lo siguiente es sobre Hurst y Wavelet 


##### Aquí es dónde pruebo continuous wavelets 

using ContinuousWavelets, Plots, Wavelets

n = 2047;

t = range(0, n / 1000, length=n) # 1kHz sampling rate

f = testfunction(n, "Doppler")

length(t)


# mis datos 
f = series[1].getPrice
t = range(0, length(f) / 1000, length=length(f))
length(t)

p1 = plot(t, f, legend=false, title="Doppler", xticks=false)

c = wavelet(Morlet(π), β=2)

res = ContinuousWavelets.cwt(f, c)
size(res)
length(t)
length(freqs)


freqs = getMeanFreq(ContinuousWavelets.computeWavelets(length(f), c)[1])
freqs[1] = 0
p2 = heatmap(t, freqs, log.(abs.(res).^2)', xlabel= "time (s)", ylabel="frequency (Hz)", colorbar=false, c=cgrad(:viridis, scale=:log10))
l = @layout [a{.3h};b{.7h}]
plot(p1,p2,layout=l)

# Bueno, ya que está esto tengo mucho que comprender todavía. Pero si entiendo correctamente
# el resultado de ContinuousWavelets.cwt es una matriz con num columnas igual a la del vector 
# alimentado y con tantas filas como frecuencias fue posible calcular. Entonces acada tiempo 
# tengo un coeficiente que se corresponde con la frecuencia de la que se esté calculando
# aunque no sé qué determina cuántas frecuencias son calculadas

# Y si entendí correctamente el método para estimar el exponente de Hurst lo que necesito 
# es ajustar una recta a los coeficientes de wavelet para que su pendiente sea el exponente.

res

using StatsBase, GLM

# Obtener los logaritmos de los coeficientes de wavelet
log_coefs = log.(abs.(res))

# Calcular las escalas correspondientes a cada fila
escalas = exp10.(collect(1:size(log_coefs, 2)))
escalas = freqs

# Realizar un análisis de regresión lineal para obtener la pendiente y el intercepto
modelo = lm(log_coefs[:, end] .~ escalas .+ 1)

# Obtener la pendiente, que corresponde al exponente de Hurst
hurst_exponente = coef(modelo)[2]


# Según chatGPT está bien pendejo.

"""
hurst_exponent()
"""
function hurst_exponendt(serie)
    n = length(serie)
    media = mean(serie)
    serie_m = serie .- media

    serie_cum = cumsum(serie_m)
end

serie

ave_rescaled_ranges, scales = calcAveRescaledRanges(serie)

using Plots

plot(scales, ave_rescaled_ranges)

# ahora me hace falta calcula el logaritmo de ave_rescaled_ranges
log_coefs = log2.(ave_rescaled_ranges)

plot(scales, log_ave_rescaled_ranges)
# Que ahora sí se ve cómo una línea, solo resta ajustarle una recta 


modelo = lm(log_coefs[:, end] .~ scales .+ 1)

# Obtener la pendiente, que corresponde al exponente de Hurst
hurst_exponente = coef(modelo)[2]



"""
calcAveRescaledRanges(serie)

serie: serie de tiempo

calcula los rangos reescalados (Rescaled Ranges) de las diferentes subseries 
de longitudes iguales a potencias de 2 que caben en el vector y calcula el 
promedio por potencia de 2  
"""
function calcAveRescaledRanges(serie; init_k = 2)

    # Ahora, para cada k potencia de 2 que quepan en n 
    # para todas las las subseries de longitud k 

    # calculamos las diferentes potencias posibles 
    scales = Float64[]
    ave_rescaled_ranges = Float64[]
    for k in init_k:floor(Int,log2(n))
        # y todos los diferentes intervalos de esa longitud 
        #k = 7
        #2^k

        max_cont = floor(Int,n / (2^k))
        cont = 0
        rescaled_ranges = Float64[]
        while (cont) * 2^k < n 
            if cont == 0
                rango = 1:(2^k)
            elseif cont == max_cont
                rango = (n-2^k):n
            else
                rango = (2^k*cont):(2^k*(cont+1))
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
function calcRescaledRange(serie)
    media = mean(serie)
    serie_m = serie .- media

    serie_cum = cumsum(serie_m)

    # Ahora calculo el rango 
    range = maximum(serie_cum) - minimum(serie_cum)

    # y su desviación estandar
    stdd = std(serie)

    rescaled_range = range / stdd
    return rescaled_range
end
    

serie = serie.getPrice

calcRescaledRange(serie)

