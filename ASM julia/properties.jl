# en este documento se crea el diccionario properties
# que se utiliza a lo largo de todo el código

#mi idea es crear dos diccionarios. uno primero donde la
#persona ejecutando el código pondrá los parámetros que quiera
#variar y otro en donde se agregen todos los parámetros que
#hagan falta para que los parámetros puestos por el usuario funcionen

# Para seleccionar el descriptor deseado se debe modificar el valor
# de la entrada :descriptor del diccionario properties
# la correspondencia es la siguiente:
# de LeBaron: 1
# de Joshi: 2
# de Ehrentreich: 3

export validateProperties


properties = Dict( :nBitsReales => 1, :nBits => 7, :kClusters => 10,
    :maxPerCluster => 10, :nReglas => 100, :minPropReglas => 0.2,
    :minNumHijos => 20, :tamañoTorneo => 5,
    :interestRate => 0.001, :dividendMean => 1000, :activeDividend => true,
    :descriptor => 3,
    :riskAversion => 0.1, :gaActivationFrec => 350,
    :initStock => 1.0, :iniPrecio => 100,
    :priceCompromise => "middle", :graphInitAlg => "strogatz",
    :n_agents => 100, :topologyStepMethod => "watts strogatz",
    :priceType => "local", :transJudgement => "continuous",
    :linkageBrakingMethod => "distribution", :baseLinkageBrakingProbability => 0.1,
    :linkageSpawningMethod => "distribution", :baseLinkageSpawningProbability => 0.5,
    :linkageRecommendationMethod => "random", :specialistType => "local",
    :modelTraining => false, :WattsStrogatzAlgProbability => 0.01,
    :perturbate => false, :perturbationFactor => 1.1 )

# :minPropReglas : float entre 0 y 1 
    # indíca el número mínimo de reglas que puede tener una población por
    # proporción, si son 100 reglas entonces reglas puede tener longitud mínima 
    # de 20 

# :activeDividend : true , false 
    # true, el dividendo es un proceso de Ornstein_Uhlenbeck
    # false, el dividendo es constante 1

# Valores para priceCompromise: "middle", "proportional"
# cuando se selecciona "middle" se selecciona el precio que este 
# justo a la mitad de las predicciones de ambos agentes 
# si se selecciona "proportional" se selecciona un precio 
# de manera proporcional a la riqueza de los agentes. 
# mando con la norma euclidiana a la riqueza de los agentes, a1,a2 
# para luego dividir el intervalo entre precios en a1+a2 se seleccionar el 
# precio que beneficie al más rico  

# :graphInitAlg : "simple", "barabasi", "dorogovtsev", "strogatz"

# :topologyStepMethod : "constant topology", "dynamic topology", "watts strogatz"

# :priceType : "local", "global"

# transJudgement : "continuous", "discrete"

# :linkageBrakingMethod : "distribution", "random"

    # "distribution" rompe enlaces usando la calificación de los 
    # enlaces como probabilidades, se agranda el intervalo para 
    # que la mayor probabilidad sea de 0.5

    # "random" con una probabilidad p rompe el peor de los enlaces

# :baseLinkageBrakingProbability probabilidad base para romper un enlace con 
# "distribution" en :linkageBrakingMethod

# :linkageSpawningMethod : "distribution", "random" 

    # "random" crea con :baseLinkageSpawningProbability de probabilidad 
        # un enlace con un agente al azar dentro de la pila completa de 
        # agentes 
    # "distribution" : con una probabilidad proporcional a la calificación del 
        # enlace pide recomendación de un agente al enlace, la probabilidad 
        # máxima sera igual a :baseLinkageSpawningProbability

# :linkageRecommendationMethod : "random", "best" 
    
    # "random" escoge a un agente al azar dentro de su vecindad 
    # "best" escoge al mejor de sus enlaces para recomendar 

# :specialistType : "local", "global"

    # "local": todo sucede a nivel local, este es mi modelo 
    # "global": un espacialista centralizado, este es el SFI-ASM original

# :modelTraining : true, false 

    # true : se entrenada el modelo usando datos externos 
    # false : no se entrenará al modelo usando datos externos 

# :WattsStrogatzAlgProbability : a probability 

    # probability to rewire a given edge in the Watts Strogatz algorithm 
    # this is used to step de agent topology



function validateProperties(; properties = properties)

    #properties[:descriptor]

    if properties[:descriptor] == 1 # Descriptor de LeBaron
        properties[:nBits] = 7
        properties[:nBitsReales] = 1
    elseif properties[:descriptor] == 2 # Descriptor de Joshi
        properties[:nBits] = 43
        properties[:nBitsReales] = 2
    elseif properties[:descriptor] == 3 # Descriptor de Ehrentreich
        properties[:nBits] = 46
        properties[:nBitsReales] = 3
    end
    return properties
end















#fin
