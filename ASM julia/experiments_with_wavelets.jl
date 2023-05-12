using Wavelets






brownian = [0.0]
for i in 2:2^12
    ϵ = rand(Normal(0,1))
    append!(brownian, brownian[i-1] + ϵ)
end
brownian 
plot(1:length(brownian),brownian)

wt = wavelet(WT.db2)

xt = dwt(brownian, wt, 5 )
plot(xt)

xti = idwt(xt, wt, 5)
plot(xti)

d, l = wplotdots(xt)

plot(xt[2:end],d)
plot(xt[2:end], l)

plot(l,d)

scatter(l,d)

scatter(xt[2:end],d)

l
d

M = wplotim(xt)


heatmap(M)




# Usando Wavelets.jl 
using Wavelets


f = brownian
n = length(f)


# Un ejemplo con función conocida
n = 2048;
t = range(0, n / 1000, length=n) # 1kHz sampling rate
f = testfunction(n, "Doppler")

plot(f)
# aplicamos wavelets
xt = dwt(f, wt)
M = wplotim(xt)
heatmap(M)
mean_vector = mean(M,dims = 2)[:,1]
scales = cumsum( ones( floor(Int,log2(n))))
plot(scales, mean_vector)





# Usando ContinuousWavelets
using ContinuousWavelets

f = brownian
f = y
t = range(0, length(f) / 1000, length=length(f))
n = length(t)
p1 = plot(t, f, legend=false, title="Market series", xticks=true)

c = wavelet(Morlet(π), β=2)

res = ContinuousWavelets.cwt(f, c)
size(res)
length(t)
length(freqs)

freqs = getMeanFreq(ContinuousWavelets.computeWavelets(length(f), c)[1])

p2 = heatmap(t, freqs, log.(abs.(res).^2)', xlabel= "time (s)", ylabel="frequency (Hz)", colorbar=true, c=cgrad(:viridis, scale=:log10))
l = @layout [a{.3h};b{.7h}]
plot(p1,p2,layout=l)


# Ahora vamos a calcula la media 

mean_vector = mean(abs.(res), dims = 1)[1,:]
mean_vector = abs.(mean_vector)


plot(freqs,mean_vector)
plot(freqs,mean_vector, scale=:log10)

# Y ahora sí que puedo calcular la mejor recta 

# Obtener los logaritmos de los coeficientes de wavelet
log_coefs = log10.(mean_vector)

# Calcular las escalas correspondientes a cada fila
escalas = log10.(freqs)

plot(escalas, log_coefs)

using GLM
# Que ahora sí se ve cómo una línea, solo resta ajustarle una recta 
data = DataFrame(scales = escalas, log_coefs = log_coefs)

modelo = lm(@formula(log_coefs ~ scales), data )

# Obtener la pendiente, que corresponde al exponente de Hurst
hurst_exponente = coef(modelo)[2] - 0.5










##### Serie con un exponente predefinido 

using FFTW

# Definir el exponente de Hurst deseado
H = 0.9

# Número de puntos en la serie de tiempo
N = 2^14

# Generar una serie de números aleatorios con distribución normal estándar
r = randn(N)

# Aplicar la transformada de Fourier a la serie de números aleatorios
R = fft(r)

# Aplicar la función de transferencia adecuada
T = [((k+1)^(H-0.5)) for k = 0:N÷2-1]   # sólo necesitamos la mitad del espectro
T = [T; reverse(T[1:end])]            # completamos el espectro con su simétrica

# Multiplicar los coeficientes de la transformada de Fourier por la función de transferencia
F = R .* T

# Aplicar la transformada de Fourier inversa para obtener la serie de tiempo ficticia
y = real(ifft(F))


plot(y)












# Con midpoint displacement method

using Plots

function midpoint_displacement(x, H; scale=1, iter=10)
    n = length(x)
    new_n = Int(2^ceil(log2(n)))
    new_x = zeros(new_n)
    new_x[1:n] = x
    
    for i = 1:iter
        scale *= 0.5^H
        seg_len = new_n ÷ 2^i
        half_seg_len = seg_len ÷ 2
        
        for j = 1:(2^i)
            start_idx = (j-1) * seg_len + 1
            mid_idx = start_idx + half_seg_len
            end_idx = start_idx + seg_len - 1


            start_idx = floor(Int, start_idx)
            mid_idx = floor(Int, mid_idx)
            end_idx = floor(Int, end_idx)
            
            new_x[mid_idx] = (new_x[start_idx] + new_x[end_idx]) / 2 + scale * randn()
        end
    end
    
    return new_x[1:n]
end

function fractal_time_series(n, H)
    x = randn(n)
    y = midpoint_displacement(x, H; iter=ceil(log2(n)), scale=1)
    return y
end

# Genera una serie de tiempo con un exponente de Hurst de 0.7
y = fractal_time_series(2^13, 0.7)

# Grafica la serie de tiempo
plot(y, xlabel="Tiempo", ylabel="Valor", legend=false)
