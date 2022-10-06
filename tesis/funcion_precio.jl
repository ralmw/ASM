# tengo que hacer una función que fabrique vectores info llenos de predictores iguales al promedio que yo determino 
# luego tengo que calcular el nuevo precio para ese descriptor. Tengo que hacer una malla o grid de diferentes valores 
# para luego graficarlo cómo una sábada 3-dimensional 


using PlotlyJS

# con este método solamente tengo que hacer una bonita función p que dados 
# los valores promedio de a y b me fabrique un descriptor y luego calcule 
# el nuevo precio usando el método que uso en el modelo. 

dividendo = 1
r = 0.1

function p(a,b)
    # crea el descriptor 
    info = [[a,b] for _ in 1:100]    
    # calcula el precio 
   
    a = [info[i][1] for i in 1:length(info)]
    b = [info[i][2] for i in 1:length(info)]

    A = sum(a) - length(info)*(1+r)
    B = sum(a*dividendo + b)

    return -B/A
end

p(1.11,20)
p(1.1,20)
p(1.09,20)


x_range = 1:0.01:1.2
y_range = -10:0.1:19

x_range = 1:0.001:1.2
y_range = -10:0.5:19

x = collect(x_range)
y = collect(y_range)
z = zeros(length(x),length(y))

i = 1
j = 1
for a in x_range
    j = 1
    for b in y_range
        z[i,j] = p(a,b) 
        j += 1
    end 
    i += 1
end


layout = Layout(
    title="El precio como función del descriptor",
    autosize=true,
    width=600,
    height=600,
    margin=attr(l=65, r=50, b=65, t=90)
)

PlotlyJS.plot(surface(z=z, x=x, y=y), layout)

p(1.01,1)


#

using CSV, DataFrames

df = CSV.File("mat.csv") |> DataFrame

df

z_data = Matrix{Float64}(df)

maximum(z_data)

PlotlyJS.plot(surface(z=z_data, x = x, y = y), layout)


# low res 

x_range = 1:0.01:1.2
y_range = -10:0.1:19

x = collect(x_range)
y = collect(y_range)

df = CSV.File("mat_low.csv") |> DataFrame

df

z_data = Matrix{Float64}(df)

maximum(z_data)

PlotlyJS.plot(surface(z=z_data, x = x, y = y), layout)

