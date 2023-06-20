autoencoder

# El proposito de este código es crear un autoenconder para mis reglas, de tal 
# manera que obtenga un encaje en R3 de ellas. 


# Primera red de ejemplo 

# With Julia 1.7+, this will prompt if neccessary to install everything, including CUDA:
using Flux, Statistics, ProgressMeter

# Generate some data for the XOR problem: vectors of length 2, as columns of a matrix:
noisy = rand(Float32, 2, 1000)                                    # 2×1000 Matrix{Float32}
truth = [xor(col[1]>0.5, col[2]>0.5) for col in eachcol(noisy)]   # 1000-element Vector{Bool}

# Define our model, a multi-layer perceptron with one hidden layer of size 3:
model = Chain(
    Dense(2 => 3, tanh),   # activation function inside layer
    BatchNorm(3),
    Dense(3 => 2),
    softmax) |> gpu        # move model to GPU, if available

# The model encapsulates parameters, randomly initialised. Its initial output is:
out1 = model(noisy |> gpu) |> cpu                                 # 2×1000 Matrix{Float32}

# To train the model, we use batches of 64 samples, and one-hot encoding:
target = Flux.onehotbatch(truth, [true, false])                   # 2×1000 OneHotMatrix
loader = Flux.DataLoader((noisy, target) |> gpu, batchsize=64, shuffle=true);
# 16-element DataLoader with first element: (2×64 Matrix{Float32}, 2×64 OneHotMatrix)

optim = Flux.setup(Flux.Adam(0.01), model)  # will store optimiser momentum, etc.

# Training loop, using the whole data set 1000 times:
losses = []
@showprogress for epoch in 1:1_000
    for (x, y) in loader
        loss, grads = Flux.withgradient(model) do m
            # Evaluate model and loss inside gradient context:
            y_hat = m(x)
            Flux.crossentropy(y_hat, y)
        end
        Flux.update!(optim, model, grads[1])
        push!(losses, loss)  # logging, outside gradient context
    end
end

optim # parameters, momenta and output have all changed
out2 = model(noisy |> gpu) |> cpu  # first row is prob. of true, second row p(false)

mean((out2[1,:] .> 0.5) .== truth)  # accuracy 94% so far!




######## Mi Autoencoder  





# Preparación de mis datos 

# Reescalar mis datos para tener vectores cuyos valores estén entre 0 y 1, esto 
# equivale a dividirlos entre 2. 

# Luego meterlos a la red neuronal 

muestra # generado en analisis_de_reglas.jl

data = [Float32.(regla.conditional)./2 for regla in muestra]
# Ponerlos en forma de Matrix
data = reduce(hcat, data)



# Defino mi modelo 
model = Chain(
    Dense(46 => 30, tanh), 
    Dense(30 => 16, tanh),
    Dense(16 => 30, tanh),
    Dense(30 => 46),
    sigmoid) |> gpu   



# Veamos qué hace ahora el modelo 
out1 = model(data)

# Efectivamente la estructura es correcta :3

# To train the model, we use batches of 64 samples, my target is my original data:
target = data             # 2×1000 OneHotMatrix
loader = Flux.DataLoader((data, target) |> gpu, batchsize=64, shuffle=true);
# 16-element DataLoader with first element: (2×64 Matrix{Float32}, 2×64 OneHotMatrix)


optim = Flux.setup(Flux.Adam(0.01), model)  # will store optimiser momentum, etc.

# Training loop, using the whole data set 1000 times:
losses = []
@showprogress for epoch in 1:1_000
    for (x, y) in loader
        loss, grads = Flux.withgradient(model) do m
            # Evaluate model and loss inside gradient context:
            y_hat = m(x)
            Flux.mse(y_hat, y)
        end
        Flux.update!(optim, model, grads[1])
        push!(losses, loss)  # logging, outside gradient context
    end
end

optim # parameters, momenta and output have all changed
out2 = model(data |> gpu) |> cpu  # first row is prob. of true, second row p(false)


plot(losses; xaxis=(:log10, "iteration"),
    yaxis="loss", label="per batch")
n = length(loader)
plot!(n:n:length(losses), mean.(Iterators.partition(losses, n)),
    label="epoch mean", dpi=200)



heatmap(out2[:,1:50])
heatmap(data[:,1:50])