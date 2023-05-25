using FFTW 
using Plots 


## Con mis datos
serie = series[2]
serie = serie.getPrice
plot(serie)
FFT_log_adj_plot(serie)

FFT_log_adj_plot(brownian)
FFT_log_adj_coef(brownian)

FFT_log_adj_plot(randomWalk)
FFT_log_adj_coef(randomWalk)


#### Pink Noise
using CSV, DataFrames, FFTW, Plots, GLM

df = CSV.read("Pink_Noise.csv",DataFrame, header=false)
vect = df.Column1

FFT_log_adj_coef(vect)
FFT_log_adj_plot(vect)

FFT_log_adj_coef(serie)
FFT_log_adj_plot(serie)


"""
FFT_log_adj_coef(serie)

serie: serie de tiempo a la que se calculará el exponente

No calcula todavía cómo tal el exponente, calcula la pendiente de la recta ajustada 
al logaritmo del espectrograma del a transformada de Fourier de la serie.
"""
function FFT_log_adj_coef(serie)
    # Cómo se ve la serie
    #plot(serie)

    # Calcula la FFT
    Y = fft(serie)

    # Visualizar los coeficientes en el espacio de frecuencias
    n = length(serie)
    frequencies = fftfreq(n,100)
    magnitudes = abs.(Y)
    #plot(frequencies, magnitudes, xlabel="Frecuencia", ylabel="Magnitud", legend=false)

    # Nos quedamos con las correspondientes a frecuencias positivas
    freqs = frequencies[2:floor(Int,length(frequencies)/2)]
    mags = magnitudes[2:floor(Int,length(frequencies)/2)]

    #plot(freqs, mags)
    #plot(log.(freqs), log.(mags))

    # Y ajustamos la recta
        
    # Que ahora sí se ve cómo una línea, solo resta ajustarle una recta 
    data = DataFrame(log_scales = log.(freqs), log_mags = log.(mags))

    modelo = lm(@formula(log_mags ~ log_scales), data )

    # Obtener la pendiente
    return coef(modelo)[2]
end

"""
FFT_log_adj_plot(serie)

serie : serie de tiempo (vector)

Grafica el logaritmo del espectrograma de la serie y la recta ajustada.
"""
function FFT_log_adj_plot(serie)
    # Calcula la FFT
    Y = fft(serie)

    # Visualizar los coeficientes en el espacio de frecuencias
    n = length(serie)
    frequencies = fftfreq(n,100)
    magnitudes = abs.(Y)
    #plot(frequencies, magnitudes, xlabel="Frecuencia", ylabel="Magnitud", legend=false)

    # Nos quedamos con las correspondientes a frecuencias positivas
    freqs = frequencies[2:floor(Int,length(frequencies)/2)]
    mags = magnitudes[2:floor(Int,length(frequencies)/2)]

    # Y ajustamos la recta
        
    # Que ahora sí se ve cómo una línea, solo resta ajustarle una recta 
    data = DataFrame(log_scales = log.(freqs), log_mags = log.(mags))

    modelo = lm(@formula(log_mags ~ log_scales), data )

    # para graficar
    data.model = predict(modelo, data)

    p = plot(xlabel="x", ylabel="y", legend=:bottomright)
    plot!(p, data.log_scales, data.log_mags, label="data")
    plot!(p, data.log_scales, data.model, label="model", linewidth=3)
    return p
end

plot(series[1].retornos[250:end])

histogram((series[1].retornos[250:end]))

histogram(diff(brownian))