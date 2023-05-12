

# A continuación el ejemplo de uso que encontré 

using FFTW

N = 10
fftfreq(N,N)

N = 11 

fftfreq(N,N)

using FFTW 
using Plots

N = 21 
xj = (0:N-1)*2*π/N 
f = 2*exp.(17*im*xj) + 3*exp.(6*im*xj) + rand(N)

original_k = 1:N 
shifted_k = fftshift(fftfreq(N)*N)

original_fft = fft(f)
shifted_fft= fftshift(fft(f))

p1 = plot(original_k,abs.(original_fft),title="Original FFT Coefficients", xticks=original_k[1:2:end], legend=false, ylims=(0,70));
p1 = plot!([1,7,18],abs.(original_fft[[1,7,18]]),markershape=:circle,markersize=6,linecolor="white");
p2 = plot(shifted_k,abs.(shifted_fft),title="Shifted FFT Coefficients",xticks=shifted_k[1:2:end], legend=false, ylims=(0,70));
p2 = plot!([-4,0,6],abs.(shifted_fft[[7,11,17]]),markershape=:circle,markersize=6,linecolor="white");
plot(p1,p2,layout=(2,1))



# Aplicado ahora a un seno 


using FFTW 
using Plots 

t0 = 0 
fs = 44100 
tmax = 0.1 

t = t0:1/fs:tmax; 
signal = sin.(2π * 60 .* t)

F = fftshift(fft(signal))
freqs = fftshift(fftfreq(length(t), fs))

# plots 
time_domain = plot(t, signal, title = "Signal", label='f',legend=:top)
freq_domain = plot(freqs, abs.(F), title = "Spectrum", xlim=(-100, +100), xticks=-100:20:100, label="abs.(F)",legend=:top) 
plot(time_domain, freq_domain, layout = (2,1))



# Para mis fines puedo fijar una frecuencia cualquiera y el 
# resultado deberá ser el mismo. Podré pues una frecuencia
# de 44100 igual que en el ejemplo 

serie = series[1].getPrice

t0 = 0 
fs = 1200
tmax = 1/fs * length(serie)

t = t0:1/fs:tmax 
t = t[1:end-1]
signal = serie .- mean(serie)

F = fftshift( fft( signal))
freqs = fftshift( fftfreq(length(t), fs))


# plots 
time_domain = plot(t, signal, title = "Signal", label='f',legend=:top)
freq_domain = plot(freqs, abs.(F), title = "Spectrum", xlim=(-100, +100), xticks=-100:20:100, label="abs.(F)",legend=:top) 
plot(time_domain, freq_domain, layout = (2,1))


# Ahora, si quiero graficar coeficiente contra escala 
# me quedo con las escalas positivas 

pos_freqs = freqs[freqs .> 0.0]
pos_F = abs.(F[freqs .> 0.0])

plot(pos_freqs,pos_F)









function hurst_fft(x)
    # Calculate the FFT of the time series
    fft_x = fft(x)
  
    # Calculate the magnitudes of the FFT coefficients
    magnitudes = abs.(fft_x)
  
    # Calculate the Hurst exponent
    H = mean(log.(magnitudes[2:end]) ./ log.(magnitudes[1:end-1]))
  
    return H
  end
  

  hurst_fft(signal)

brownian = [0.0]
for i in 2:2^12
    ϵ = rand(Normal(0,1))
    append!(brownian, brownian[i-1] + ϵ)
end
hurst_fft(brownian)