include("./zaf.jl")
using .zaf
using WAV
using Statistics
using Plots
using Tables
using CSV
using DSP
using SignalAnalysis
using DataFrames

# Папка сохранения полученных датасетов

data_dir = "datasets/"

# Папка исходных аудио-файлов

files_dir = "files/"

# Настройки CQT преобразования

octave_resolution = 24
minimum_frequency = 55
maximum_frequency = 9520
time_resolution = 25

# Размеры кадра в сек

window_duration = 0.04;

# Уровень энергии для порогового фильтра

energy_level = 50

# Количество кадров для сглаживания скользящей средней слепка аудио-данных

m_offset = 20

# Чтение WAV-файла

function read()
    if !isempty(ARGS) 
        try
            return wavread(files_dir*ARGS[1])     
        catch e
            println("Ошибка чтения wav-файла")
        end
    else
        println("Не указан входной файл")
        exit()
    end    
end

# Загрузка сохраненного файла данных очищенных окон с преобразованием в среднеквадратичное отклонение по частотным полосам

function load(filename)::Vector{Any}
    if !isempty(filename) 
        try        
            data = CSV.read(filename, DataFrame, skipto=2)
            return data[!, :Column1]   
        catch e
            println("Ошибка чтения csv-файла")
        end
    else
        println("Не указан входной файл")
        exit()
    end      
end

# Скользящее среднее

function m_average(arr::Vector{Float64}, n::Number)::Vector{Any}
    so_far = sum(arr[1:n])
    out = zero(arr[n:end])
    out[1] = so_far
    for (i, (start, stop)) in enumerate(zip(arr, arr[n+1:end]))
        so_far += stop - start
        out[i+1] = so_far
    end
    return out
end

# Нормализация уровня

function normalize(audio_input::Matrix{Float64},freq::Number)
    return mean(audio_input, dims=2), freq
end

# Разбитие на окна

function windows(freq::Number)
    local window_length = nextpow(2, ceil(Int, window_duration*freq))
    local window_function = zaf.hamming(window_length, "periodic") #  оконная аналитическая функция
    return window_length, convert(Int, window_length/2), window_function
end

# Фильтрация окон по уровню минимальной энергии звука в каждом окне

function filter(audio_input::Matrix{Float64},window_length::Number)::Matrix{Float64}
    output_signal = zeros(1,1)
    number_samples = length(audio_input)
    padding_length = floor(Int, window_length / 2)
    number_times =
        ceil(
            Int,
            ((number_samples + 2 * padding_length) - window_length) /
            step_length,
        ) + 1  
    local i = 0
    for j = 1:(number_times-10) # 10 последних кадров отбарсываем
        frame = audio_input[i+1:i+window_length]           
        if energy(frame) > energy_level
            output_signal = [output_signal;frame]
        end
        i = i + step_length

    end
    return output_signal
end

# Преобразование Фурье

function stft(audio::Matrix{Float64},freq::Number)
    local window_length,step_length,window_function = windows(freq)
    return zaf.stft(audio, window_function, step_length), window_length, step_length, window_function 
end

# Спектограмма разложения ряда Фурье

function spectrogram(audio::Matrix{Float64},freq::Number)::Matrix{Float64}
    local audio_stft, window_length = stft(audio,freq)   
    local audio_spectrogram = abs.(audio_stft[2:convert(Int, window_length/2)+1, :])  # Отбрасываем постоянную составляющую
    local number_samples = length(audio_input)
    local xtick_step = 1
    local ytick_step = 1000
    local plot_object = zaf.specshow(audio_spectrogram, number_samples, freq, xtick_step, ytick_step)
    heatmap!(title = "Spectrogram (dB)", size = (990, 600))
    savefig(plot_object, data_dir*ARGS[1]*"-"*"spectr.png")
    #CSV.write(data_dir*ARGS[1]*"-"*"spectr.csv", Tables.table(audio_spectrogram))
    return audio_spectrogram
end

# CQT-октавное вевлет-преобразование

function cqt(audio::Matrix{Float64},freq::Number)::Matrix{Float64}
    local cqt_kernel = zaf.cqtkernel(freq, octave_resolution, minimum_frequency, maximum_frequency)
    cqt_spectrogram = zaf.cqtspectrogram(audio, freq, time_resolution, cqt_kernel)
    CSV.write(data_dir*ARGS[1]*"-"*"cqt.csv", Tables.table(cqt_spectrogram))
    local xtick_step = 1
    local plot_object = zaf.cqtspecshow(cqt_spectrogram, time_resolution, octave_resolution, minimum_frequency, xtick_step)
    heatmap!(title = "CQT spectrogram (dB)", size = (990, 600))
    savefig(plot_object, data_dir*ARGS[1]*"-"*"cqt.png")   
    return cqt_spectrogram
end

# Преобразование вевлет-спектрограммы в спектр среднего значения по октавам со сглаживанием

function raft(spectr::Matrix{Float64})::Vector{Any} 
    freqs, frames = size(spectr)
    raft_data = zeros(freqs)
    for i in 1:freqs
        raft_data[i] = mean(spectr[i, :])
    end
    return m_average(raft_data,m_offset)
end

# Cохранение образа записи

function save(audio_data::Vector{Any},freq::Number)::Vector{Any}
    CSV.write(data_dir*ARGS[1]*"-"*"analise.csv", Tables.table(audio_data))
    numbers = length(audio_data)       
    xtick_locations = [0:octave_resolution:numbers;]
    xtick_labels = convert(
        Array{Int},
        minimum_frequency * 2 .^ (xtick_locations / octave_resolution),
    )    
    plot_object = plot(audio_data, xticks = (xtick_locations, xtick_labels))
    plot!(title = "Sound form", size = (990, 600))
    savefig(plot_object, data_dir*ARGS[1]*"-"*"analise.png")    
    return audio_data
end


# Считываем данные из WAV файла и нормализуем их, частота дискретизации получается из заголовка WAV-файла

audio_input, freq = read()

audio_input, freq = normalize(audio_input, freq)

# Исходя из частоты дискретизации получаем длину кадров и шаг между ними

window_length,step_length,window_function = windows(freq)

# Сохраняем спектограмму исходного сигнала

spectrogram(audio_input,freq)

# Фильтруем кадры, отбрасывая кадры с низкой энергией

audio = filter(audio_input,window_length)

frames, freqs = size(audio)

if frames<5 
    println("Файл не прошел фильтр суммарной энергии сигнала")
    exit()
end

# Осущетсвляем CQT-преобразование и сохранение спектограммы и массива данных

cqt_spectrogram = cqt(audio,freq)

# Преобразуем спектограмму в с спектр среднеквадратичных отклонений

raft_data = raft(cqt_spectrogram)

# Cохраняем результат

save(raft_data,freq)
