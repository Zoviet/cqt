using Statistics
using Plots
using Tables
using CSV
using DataFrames


# Папка с датасетами

data_dir = "datasets/"

# Чтение файла данных

function read()
    if !isempty(ARGS) 
        try        
            data = CSV.read(data_dir*ARGS[1], DataFrame, skipto=2)  
            ret = []
            map(eachrow(data)) do col
                push!(ret,std(col))
            end  
            return ret
        catch e
            println("Ошибка чтения wav-файла: "*e)
        end
    else
        println("Не указан входной файл")
        exit()
    end      
end

# Скользящее среднее

function m_average(arr::Vector{Any}, n::Number)::Vector{Any}
    so_far = sum(arr[1:n])
    out = zero(arr[n:end])
    out[1] = so_far
    for (i, (start, stop)) in enumerate(zip(arr, arr[n+1:end]))
        so_far += stop - start
        out[i+1] = so_far
    end
    return out
end



audio_data = read()

println(typeof(audio_data))

println(size(audio_data))

println(ndims(audio_data))

println(audio_data[1:41])

audio_data = m_average(audio_data,20)

numbers = size(mel_spectrogram)

minimum_mel = 2595 * log10(1 + (freq / window_length) / 700)
maximum_mel = 2595 * log10(1 + (freq / 2) / 700)
mel_scale = range(minimum_mel, stop = maximum_mel, length = numbers)
hertz_scale = 700 .* (10 .^ (mel_scale / 2595) .- 1)

plot_object = plot(audio_data, xticks = convert(Array{Int}, round.(hertz_scale[1:8:numbers])))
plot!(title = "Sound form", size = (990, 600))
savefig(plot_object, data_dir*ARGS[1]*"-"*"analize.png")
