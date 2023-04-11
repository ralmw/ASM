pruebas.jl 


# Aquí están las diferentes pruebas que le aplicaré  mi modelo. 

# el primer paso es transformar el enorme dataframe que recibo en un vector de dataframes de precios 
# que me permita procesar cada una de las series de tiempo de manera individual.
# come el dataframe come el dataframe y para cada valor diferente de ensamble crea un dataframe 
# con precisamente esos datos y los ordena por el tiempo de ejecución. 

# usando datos de ejemplo resultado del ensemble run de ejemplo en run.jl
last(adf,10)
last(mdf,10)

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
executions


unique(mdf.ensemble)

ensemble = 6
first(filter(:ensemble => x -> x == ensemble,mdf),10)