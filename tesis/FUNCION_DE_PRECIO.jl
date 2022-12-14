# Una función más 

using PlotlyJS  
using Roots 

# Defino a mis agentes de juguete:

# Paso número 1. Graficar la variedad de un agente.
# un agente debe tener los siguientes atributos:

# Agente:
#   Riqueza: w = (E, S)
#   Predicción: P 
#   Varianza de la predicción: σ
#   Precio anterior: P_t-1
#   Parámetro de elasticidad: λ

# Esto es todo lo que necesito de un agente para calcular su variedad.

esc_graf = 0.3 ## factor de escalamiento de las graficas

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
    r::Float64
end


# Ya que tengo a mis agentes es hora de definir mi función como función de 
# un agente y de las variables x,P 

function Δw(x,P,Agente::Agent)
    Pp = Agente.Pred.P
    E = Agente.Riqueza.E 
    S = Agente.Riqueza.S
    r = Agente.r
 
    #return (1/Pp)*((S + x)*(Pp - P) + (E-x*P)*(1+r)) + Pp*x
    return ((S + x)*(Pp - P) + (E-x*P)*(1+r))
end

# Ahora que ya está la función vamos a observarla 
function Plot_simple_DM(Agente::Agent)
    a = abs( Agente.Riqueza.E / Agente.Precio_pasado + Agente.Riqueza.S )
    b = abs( Agente.Pred.P / Agente.Pred.σ )

    #x_range = -a/sqrt(Agente.λ)*15:(a/sqrt(Agente.λ)*15*2/500):a/sqrt(Agente.λ)*15
    #y_range = -b/sqrt(Agente.λ)*15:(b/sqrt(Agente.λ)*15*2/500):b/sqrt(Agente.λ)*15

    x_range = -100:250:100
    y_range = (Agente.Pred.P - Agente.Pred.P/2):Agente.Pred.P/250:(Agente.Pred.P + Agente.Pred.P)

    x = collect(x_range)
    y = collect(y_range)
    z = zeros(length(x),length(y))
     i = 1
    j = 1
    for a in x_range
        j = 1
        for b in y_range
            z[i,j] = Δw(a,b,Agente)
            j += 1
        end 
        i += 1
    end

    layout = Layout(
        title="Variedad de decisión del agente sin cociente.",
        autosize=true,
        width=1000,
        height=800,
        margin=attr(l=65, r=50, b=65, t=90)
    )

    PlotlyJS.plot(surface(z=z, x=x, y=y), layout)
    
end


# Entonces mi función se ve bien. 

# Solo que los intervalos sobre los que mi función cambia son diferentes
# Aunque cualitativamente se parece mucho a la anterior lo que muy bueno



function exp_circle(x,P,Agente::Agent)
    a = Agente.Riqueza.E / Agente.Precio_pasado + Agente.Riqueza.S 
    b = Agente.Pred.P / Agente.Pred.σ 

    return exp(Agente.λ * ((x-δx(Agente) )^2/a^2 + (P-δP(Agente))^2/b^2))
    
end

function Plot_exp_circ(Agente)
    a = abs( Agente.Riqueza.E / Agente.Precio_pasado + Agente.Riqueza.S )
    b = abs( Agente.Pred.P / Agente.Pred.σ )

    x_range = δx(Agente)-a/(sqrt(Agente.λ))*esc_graf:(2*a/sqrt(Agente.λ)*esc_graf/250):δx(Agente)+a/(sqrt(Agente.λ))*esc_graf
    y_range = δP(Agente)-b/(sqrt(Agente.λ))*esc_graf:(2*b/sqrt(Agente.λ)*esc_graf/250):δP(Agente)+b/(sqrt(Agente.λ))*esc_graf

    x = collect(x_range) 
    y = collect(y_range)
    z = zeros(length(x),length(y))

    i = 1
    j = 1
    for a in x_range
        j = 1
        for b in y_range
            z[i,j] = exp_circle(a,b,Agente) 
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


function PlotDM(Agente::Agent)
    a = abs( Agente.Riqueza.E / Agente.Precio_pasado + Agente.Riqueza.S )
    b = abs( Agente.Pred.P / Agente.Pred.σ )

    x_range = δx(Agente)-a/(sqrt(Agente.λ))*esc_graf:(2*a/sqrt(Agente.λ)*esc_graf/250):δx(Agente)+a/(sqrt(Agente.λ))*esc_graf
    y_range = δP(Agente)-b/(sqrt(Agente.λ))*esc_graf:(2*b/sqrt(Agente.λ)*esc_graf/250):δP(Agente)+b/(sqrt(Agente.λ))*esc_graf

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

function δx(Agente::Agent)
    Pp = Agente.Pred.P 
    E = Agente.Riqueza.E 
    S = Agente.Riqueza.S 
    r = Agente.r

    up = -S
    down = 2 + r
    return up/down
end

function δP(Agente::Agent)
    Pp = Agente.Pred.P 
    E = Agente.Riqueza.E 
    S = Agente.Riqueza.S 
    r = Agente.r

    up = Pp
    down = 2 + r 

    return up/down 
end

# Veamos ahora la función completa con todo y su cociente.

function DM(x,P,Agente::Agent)
    up = Δw(x,P,Agente)

    a = Agente.Riqueza.E / Agente.Precio_pasado + Agente.Riqueza.S 
    b = Agente.Pred.P / Agente.Pred.σ 

    down = exp(Agente.λ * ((x-δx(Agente) )^2/a^2 + (P-δP(Agente))^2/b^2))

    #return up / down 
    return up/down 
end


Agente = Agent(Riqueza(100,10),Prediccion(10,1),12,0.1,0.1)


Plot_simple_DM(Agente)

# Ahí está, el bellísimo punto silla que tanto quería encontrar
# Lo que ahora tengo que hacer es centrar el cociente y la gráfica de la
# variedad al rededor del punto silla para capturar bonitamente
# el comportamiento

#PlotDM(Agente)

δx(Agente)
δP(Agente)

Δw(δx(Agente),δP(Agente),Agente)

Plot_exp_circ(Agente)

# Ahora que ya tengo la bonita variedad aislada y que puedo ver el comportamiento 
# de 2 pancitas. Ahora debo confirmar que efectivamente al tomar 2 variedades 
# la solución sea bonita. Entonces ahora tengo que graficar 2 variedades y observar el 
# conjunto solución.


function Plot_two_simple_DM(Agente1::Agent, Agente2::Agent)
    a1 = Agente1.Pred.P
    b1 = abs( Agente1.Pred.P / Agente1.Pred.σ )

    a2 = Agente2.Pred.P
    b2 = abs( Agente2.Pred.P / Agente2.Pred.σ )

    a = max(a1,a2)
    b = min(a1,a2)
    λ = min(Agente1.λ,Agente2.λ)

    #x_range = δx(Agente)-a/(sqrt(Agente.λ))*esc_graf:(2*a/sqrt(Agente.λ)*esc_graf/250):δx(Agente)+a/(sqrt(Agente.λ))*esc_graf
    #y_range = δP(Agente)-b/(sqrt(Agente.λ))*esc_graf:(2*b/sqrt(Agente.λ)*esc_graf/250):δP(Agente)+b/(sqrt(Agente.λ))*esc_graf

    max_x = 50
    x_range = -max_x:2*max_x/250:max_x
    y_range = b:(Agente1.Pred.P+Agente2.Pred.P)/250:a

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
            z1[i,j] = Δw(a,b,Agente1)
            z2[i,j] = Δw(-a,b,Agente2) 
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


Agente = Agent(Riqueza(100,30),Prediccion(100,1),12,0.01,0.5)

Agente2 = Agent(Riqueza(30,0),Prediccion(20,1),12,0.01,0.5)

Plot_two_simple_DM(Agente,Agente2)



δx(Agente)
δP(Agente)

Δw(δx(Agente),δP(Agente),Agente)