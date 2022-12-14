# en este documento se crea el diccionario properties
# que se utiliza a lo largo de todo el código

mi idea es crear dos diccionarios. uno primero donde la
persona ejecutando el código pondrá los parámetros que quiera
variar y otro en donde se agregen todos los parámetros que
hagan falta para que los parámetros puestos por el usuario funcionen

# Para seleccionar el descriptor deseado se debe modificar el valor
# de la entrada :descriptor del diccionario properties
# la correspondencia es la siguiente:
# de LeBaron: 1
# de Joshi: 2
# de Ehrentreich: 3

properties = Dict( :nBitsReales => 1, :nBits => 7, :kClusters => 10,
    :maxPerCluster => 10, :nReglas => 100,
    :minNumHijos => 20, :tamañoTorneo => 5,
    :interestRate => 0.001, :dividendMean => 1000,
    :descriptor => 3,
    :riskAversion => 0.001, :gaActivationFrec => 350,
    :initStock => 1.0, :iniPrecio => 100 )

properties[:descriptor]

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

properties[:nBits]
properties[:nBitsReales]















fin
