include("./zaf.jl")
using .zaf
using WAV
using Statistics
using Plots
using Tables
using CSV
using DSP
using SignalAnalysis

# Папка сохранения полученных датасетов

data_dir = "datasets/"

# Настройки CQT преобразования

octave_resolution = 24
minimum_frequency = 55
maximum_frequency = 9520
time_resolution = 25

# Размеры кадра в сек

window_duration = 0.04;

# Уровень энергии для порогового фильтра

energy_level = 50

# Чтение WAV-файла

function read()
    if !isempty(ARGS) 
        try
            return wavread(ARGS[1])     
        catch e
            println("Ошибка чтения wav-файла: "*e)
        end
    else
        println("Не указан входной файл")
        exit()
    end    
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
    return audio_spectrogram
end

# CQT-октавное преобразование

function cqt(audio::Matrix{Float64},freq::Number)::Matrix{Float64}
    local cqt_kernel = zaf.cqtkernel(freq, octave_resolution, minimum_frequency, maximum_frequency)
    cqt_spectrogram = zaf.cqtspectrogram(audio, freq, time_resolution, cqt_kernel)
    local xtick_step = 1
    local plot_object = zaf.cqtspecshow(cqt_spectrogram, time_resolution, octave_resolution, minimum_frequency, xtick_step)
    heatmap!(title = "CQT spectrogram (dB)", size = (990, 600))
    savefig(plot_object, data_dir*ARGS[1]*"-"*"cqt.png")
    CSV.write(data_dir*ARGS[1]*"-"*"cqt.csv", Tables.table(cqt_spectrogram))
    return cqt_spectrogram
end

# Считываем данные из WAV файла и нормализуем их, частота дискретизации получается из заголовка WAV-файла

audio_input, freq = read()

audio_input, freq = normalize(audio_input, freq)

# Исходя из частоты дискретизации получаем длину кадров и шаг между ними

window_length,step_length,window_function = windows(freq)

# Фильтруем кадры, отбрасывая кадры с низкой энергией

audio = filter(audio_input,window_length)

# Осущетсвляем CQT-преобразование и сохранение спектограммы и массива данных

cqt(audio,freq)
