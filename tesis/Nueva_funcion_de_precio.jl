# En este documento trabajeré sobre la función para determinar el precio entre un par de agentes

using PlotlyJS

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

# Ya que tengo a mi agente entonces puedo crear una función que coma a mi agente y me de su variedad de decisión

#Decision Manifold
function DM(x,P,Agente::Agent)
    Δw = Agente.Riqueza.E - P*x + Agente.Pred.P*(Agente.Riqueza.S + x)
    a = Agente.Riqueza.E / Agente.Precio_pasado + Agente.Riqueza.S 
    b = Agente.Pred.P / Agente.Pred.σ 
    K = exp(Agente.λ * (x^2/a^2 + P^2/b^2))

    return Δw / K 
end

function simple_DM(x,P,Agente::Agent)
    return Agente.Riqueza.E - P*x + Agente.Pred.P*(Agente.Riqueza.S + x)
end

DM(1,2,A)

Agente = Agent(Riqueza(100,100),Prediccion(15,1),25,1)
a = Agente.Riqueza.E / Agente.Precio_pasado + Agente.Riqueza.S 
b = Agente.Pred.P / Agente.Pred.σ 


function PlotDM(Agente::Agent)
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
            z[i,j] = DM(a,b,Agente) 
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

function Plot_simple_DM(Agente::Agent)
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
            z[i,j] = simple_DM(a,b,Agente) 
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

function Plot_two_DM(Agente1::Agent, Agente2::Agent)
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
            z1[i,j] = DM(a,b,Agente1)
            z2[i,j] = DM(-a,b,Agente2) 
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

Plot_two_DM(A,B)

# Ahora ya puedo visualizar la intersección de las variedades de 2 agentes :3
# Queda entonces encontrar el máximo. Quiero resolver simultaeamente el problema
# de la intersección y el del máximo. Pero comencemos por el de la intersección.

DM(x,P,A) - DM(-x,P,B) == 0 sii x,P son puntos de intersección.