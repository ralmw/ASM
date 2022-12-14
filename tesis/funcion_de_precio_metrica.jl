# En este documento trabajeré sobre la función para determinar el precio entre un par de agentes

using PlotlyJS
using Roots


# Paso número 1. Graficar la variedad de un agente.
# un agente debe tener los siguientes atributos:

# Agente:
#   Riqueza: w = (E, S)
#   Predicción: P 
#   Varianza de la predicción: σ
#   Precio anterior: P_t-1
#   Parámetro de elasticidad: λ

# Esto es todo lo que necesito de un agente para calcular su variedad.

mutable struct Riqueza
    E::Float64 
    S::Float64
end

mutable struct Prediccion 
    P::Float64
    σ::Float64
end

mutable struct Agent
    Riqueza::Riqueza
    Pred::Prediccion
    Precio_pasado::Float64
    λ::Float64
end


    
A = Agent(Riqueza(100,10),Prediccion(15,1),12,1)

# Lo primero que quiero hacer es observar cómo funciona la nueva "norma" que acabo de crear 
function N(w::Riqueza,P::Float64)
    return (1/P)*w.E + P*w.S
end


# Y ahora vamos a observarla, supongamos que tengo la siguiente riqueza:
w = Riqueza(1,1)

# y consideremos los siguientes precios:
Pp = 0.1:0.1:10
Pp = collect(Pp)
utts = [N(w,p) for p in Pp]

Plot(Pp,utts)

# La consecuencia <<natural>> de la definición de está norma y de maximizar 
# el aumento en mis ganancias tanto en las acciones actuales cómo con 

# Ahora lo que quiero hacer es observar mi función en acción, para un agente
# con este fin defino un agente de prueba
A = Agent(Riqueza(100,20),Prediccion(15,1),12,1)

# Ya que tengo a mi agente entonces puedo crear una función que coma a mi agente y me de su variedad de decisión

#Decision Manifold
function DM(x,P,Agente::Agent,ΔW,Φ,ϕ)
    Δw = ΔW(x,P,Agente::Agent,Φ,ϕ)
    #Δw = Agente.Riqueza.E - P*x + Agente.Precio_pasado + (Agente.Pred.P - Agente.Precio_pasado )*(Agente.Riqueza.S + x)
    a = Agente.Riqueza.E / Agente.Precio_pasado + Agente.Riqueza.S 
    b = Agente.Pred.P / Agente.Pred.σ 
    K = exp(Agente.λ * (x^2/a^2 + P^2/b^2))

    return Δw / K 
end

function first_Δw(x,P,Agente::Agent)
    return Agente.Riqueza.E - P*x + Agente.Pred.P*(Agente.Riqueza.S + x)
end

function metric_Δw(x,P,Agente::Agent,Φ,ϕ)
    #return (Agente.Pred.P - P)^2*(Agente.Pred.P-Agente.Precio_pasado)*x
    return exp(-(Agente.Pred.P - P)^2/30)*(Agente.Pred.P-Agente.Precio_pasado)*x

    #return 1/(Φ - ϕ)*(-x*P) + (Φ-ϕ)*(x)
end

DM(1,2,A,metric_Δw,10,1)

exp(0)

function PlotDM(Agente::Agent,Φ)
    a = abs( Agente.Riqueza.E / Agente.Precio_pasado + Agente.Riqueza.S )
    b = abs( Agente.Pred.P / Agente.Pred.σ )

    x_range = -a/sqrt(Agente.λ)*1.5:(a/sqrt(Agente.λ)*1.5*2/500):a/sqrt(Agente.λ)*1.5
    y_range = -b/sqrt(Agente.λ)*1.5:(b/sqrt(Agente.λ)*1.5*2/500):b/sqrt(Agente.λ)*1.5

    x = collect(x_range)
    y = collect(y_range)
    z = zeros(length(x),length(y))

    i = 1
    j = 1
    for a in x_range
        j = 1
        for b in y_range
            z[i,j] = DM(a,b,Agente,metric_Δw,Agente.Pred.P,b) 
            j += 1
        end 
        i += 1
    end

    layout = Layout(
        title="Variedad de decisión del agente",
        autosize=true,
        width=1000,
        height=800,
        margin=attr(l=65, r=50, b=65, t=90)
    )

    PlotlyJS.plot(surface(z=z, x=x, y=y), layout)
     
    
end

A = Agent(Riqueza(100,20),Prediccion(20,1),40,1)
PlotDM(A,10)


function Plot_simple_DM(Agente::Agent,Φ)
    a = abs( Agente.Riqueza.E / Agente.Precio_pasado + Agente.Riqueza.S )
    b = abs( Agente.Pred.P / Agente.Pred.σ )

    x_range = -a/sqrt(Agente.λ)*1.5:(a/sqrt(Agente.λ)*1.5*2/500):a/sqrt(Agente.λ)*1.5
    y_range = -b/sqrt(Agente.λ)*1.5:(b/sqrt(Agente.λ)*1.5*2/500):b/sqrt(Agente.λ)*1.5

    x = collect(x_range)
    y = collect(y_range)
    z = zeros(length(x),length(y))
     i = 1
    j = 1
    for a in x_range
        j = 1
        for b in y_range
            z[i,j] = metric_Δw(a,b,Agente,Agente.Pred.P,b)
            #z[i,j] = simple_DM(a,b,Agente,metric_Δw,Φ) 
            j += 1
        end 
        i += 1
    end

    layout = Layout(
        title="Variedad de decisión del agente",
        autosize=true,
        width=1000,
        height=800,
        margin=attr(l=65, r=50, b=65, t=90)
    )

    PlotlyJS.plot(surface(z=z, x=x, y=y), layout)
    
end

Plot_simple_DM(A,30)


function Plot_two_DM(Agente1::Agent, Agente2::Agent,Φ)
    a1 = abs( Agente1.Riqueza.E / Agente1.Precio_pasado + Agente1.Riqueza.S )
    b1 = abs( Agente1.Pred.P / Agente1.Pred.σ )

    a2 = abs( Agente2.Riqueza.E / Agente2.Precio_pasado + Agente2.Riqueza.S )
    b2 = abs( Agente2.Pred.P / Agente2.Pred.σ )

    a = max(a1,a2)
    b = max(b1,b2)
    λ = min(Agente1.λ,Agente2.λ)

    x_range = -a/sqrt(λ)*1.5:(a/sqrt(λ)*1.5*2/500):a/sqrt(λ)*1.5
    y_range = -b/sqrt(λ)*1.5:(b/sqrt(λ)*1.5*2/500):b/sqrt(λ)*1.5

    x = collect(x_range)
    y = collect(y_range)
    z1 = zeros(length(x),length(y))
    z2 = zeros(length(x),length(y))

    # La variedad de ambos agentes
    i = 1
    j = 1
    for a in x_range
        j = 1
        for b in y_range
            z1[i,j] = DM(a,b,Agente1,metric_Δw,Φ)
            z2[i,j] = DM(-a,b,Agente2,metric_Δw, Φ) 
            j += 1
        end 
        i += 1
    end 

    layout = Layout(
        title="Variedades de decisión de los agentes",
        autosize=true,
        width=1000,
        height=800,
        margin=attr(l=65, r=50, b=65, t=90)
    )

    trace1 = surface(z = z1, x=x, y=y, colorscale="Electric",showscale=false)
    trace2 = surface(z = z2, x=x, y=y, colorscale="Viridis")

    PlotlyJS.plot([trace1,trace2], layout)
    
end



A = Agent(Riqueza(100,100),Prediccion(50,1),25,0.1)
B = Agent(Riqueza(100,100),Prediccion(20,1),25,0.1)

Plot_two_DM(A,B,30)

# Ahora ya puedo visualizar la intersección de las variedades de 2 agentes :3
# Queda entonces encontrar el máximo. Quiero resolver simultaeamente el problema
# de la intersección y el del máximo. Pero comencemos por el de la intersección.

# DM(x,P,A) - DM(-x,P,B) == 0 sii x,P son puntos de intersección.

# Tengo que ver cómo se ve la resta de ambas variedades, finalmente lo que 
# buscaré serán los ceros de la resta para encontrar la intersección, entonces
# primero quiero verla

function Plot_subtraction_DM(Agente1::Agent, Agente2::Agent)
    a1 = abs( Agente1.Riqueza.E / Agente1.Precio_pasado + Agente1.Riqueza.S )
    b1 = abs( Agente1.Pred.P / Agente1.Pred.σ )

    a2 = abs( Agente2.Riqueza.E / Agente2.Precio_pasado + Agente2.Riqueza.S )
    b2 = abs( Agente2.Pred.P / Agente2.Pred.σ )

    a = max(a1,a2)
    b = max(b1,b2)
    λ = min(Agente1.λ,Agente2.λ)

    x_range = -a/sqrt(λ)*1.5:(a/sqrt(λ)*1.5*2/500):a/sqrt(λ)*1.5
    y_range = -b/sqrt(λ)*1.5:(b/sqrt(λ)*1.5*2/500):b/sqrt(λ)*1.5

    x = collect(x_range)
    y = collect(y_range)
    z = zeros(length(x),length(y))
    z0 = zeros(length(x),length(y))
    #z1 = zeros(length(x),length(y))
    #z2 = zeros(length(x),length(y))

    # La variedad de ambos agentes
    i = 1
    j = 1
    for a in x_range
        j = 1
        for b in y_range
            #z1[i,j] = DM(a,b,Agente1)
            #z2[i,j] = DM(-a,b,Agente2)
            z[i,j] = DM(a,b,Agente1) - DM(-a,b,Agente2)
            j += 1
        end 
        i += 1
    end 

    layout = Layout(
        title="Variedades de decisión de los agentes",
        autosize=true,
        width=1000,
        height=800,
        margin=attr(l=65, r=50, b=65, t=90)
    )

    trace1 = surface(z = z, x=x, y=y, colorscale="Electric",showscale=false)
    trace2 = surface(z = z0, x=x, y=y, colorscale="Viridis")

    PlotlyJS.plot([trace1,trace2], layout)
    
end

Plot_subtraction_DM(A,B)

# Veamos un ejemplo de cómo usar Roots:

f(x) = exp(x) - x^4;

α₀,α₁,α₂ = -0.8155534188089607, 1.4296118247255556, 8.6131694564414;

find_zero(f, (8,9), Bisection()) ≈ α₂ # a bisection method has the bracket specified


find_zero(f, (-10, 0)) ≈ α₀ # Bisection is default if x in `find_zero(f,x)` is not a number



find_zero(f, (-10, 0), Roots.A42()) ≈ α₀ # fewer fun

find_zero(f, (-10,9))


# funciona y funciona bonito, así que vamos a probarlo con mi función.
# Mi función a la que le quiero encontrar el cero es la siguiente:
DM(a,b,Agente1) - DM(-a,b,Agente2)
# Dónde a, Agente1 y Agente2 son constantes. Necesito una manera de escribir eso y que la máquina entienda qué debe de llenar
b = 10
f(x) = DM(x,b,A) - DM(-x,b,B)

find_zero(f,(-100,100))

DM(-77.87,b,A)

# Ya tengo un cero para un valor de b, ahora quiero obtener el cero para el cual el valor
# se maximizar. Para ello, cómo no tengo certeza alguna de dónde pueda estar el máximo 
# lo que haré será tomarme una partición del intervalo y en todos esos puntos
# encontrar el cero, y también evaluar la variedad de alguno de los agentes para tomarme
# esa información cómo semilla para buscar el máximo.

function Calculate_ranges(Agente1::Agent, Agente2::Agent)
    a1 = abs( Agente1.Riqueza.E / Agente1.Precio_pasado + Agente1.Riqueza.S )
    b1 = abs( Agente1.Pred.P / Agente1.Pred.σ )

    a2 = abs( Agente2.Riqueza.E / Agente2.Precio_pasado + Agente2.Riqueza.S )
    b2 = abs( Agente2.Pred.P / Agente2.Pred.σ )

    a = max(a1,a2)
    b = max(b1,b2)
    λ = min(Agente1.λ,Agente2.λ)

    intervalo = a/sqrt(λ)*1.5

    y_range = -b/sqrt(λ)*1.5:(b/sqrt(λ)*1.5*2/500):b/sqrt(λ)*1.5
    y = collect(y_range)
    
    return intervalo, y
end

intervalo, Y = Calculate_ranges(A,B)
intervalo
Y[1]
Y[end]

# Para cada elemento de Y calculamos el cero y evaluamos la función de tal manera que 
# obtendremos otro vector lleno de valores de X y de la evaluación.

function Find_zero_DM(y,A,B,intervalo)
    f(x) = DM(x,y,A) - DM(-x,y,B)
    return find_zero(f,(-intervalo,intervalo))
end

Find_zero_DM(33,A,B,500)

function Calculate_solution_set(A::Agent,B::Agent)
    intervalo, Y = Calculate_ranges(A,B)
    X = zeros(length(Y))
    Z = zeros(length(Y))
    for (i,y) ∈ enumerate(Y)
        x = intervalo
        try 
            x = Find_zero_DM(y,A,B,intervalo)
        catch e
            
        end
        X[i] = x 
        Z[i] = DM(x,y,A)
    end
    return X, Z 
end



X,Z = Calculate_solution_set(A,B)

maximum(Z)
argmax(Z)

# Ahora que ya tengo 

using Plots

Plot(X,Z)

Plot(X)
Plot(Y)
Plot(Z)

# Esto propone que siempre tendremos un par de soluciones gemelas, lo cuál sería interesante
# de demostrar y de entender. Pero tendría entonces que decidirme por alguno de los 
# dos máximos 
# Comencemos por observar algunos otros casos:
precio_pasado =1000
A = Agent(Riqueza(50,10),Prediccion(50,1),precio_pasado,0.1)
B = Agent(Riqueza(20,10),Prediccion(50,1),precio_pasado,0.1)


Plot_two_DM(A,B)

Plot_subtraction_DM(A,B)

X,Z = Calculate_solution_set(A,B)

maximum(Z)
argmax(Z)

Plot(X,Z)
Plot(X,Y)
Plot(Y,Z)
