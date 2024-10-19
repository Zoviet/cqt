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

plot_object = plot(audio_data)
plot!(title = "Sound form", size = (990, 600))
savefig(plot_object, data_dir*ARGS[1]*"-"*"analize.png")
