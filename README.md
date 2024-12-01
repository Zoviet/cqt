# Создание снимков аудио файлов через октавное CQT - преобразование

Создание частотного-массива (слепка) исходного файла для создания эталонных шаблонов шумов.

## Библиотеки

```
import Pkg; Pkg.add("DSP")
import Pkg; Pkg.add("SignalAnalysis")
import Pkg; Pkg.add("FFTW")
import Pkg; Pkg.add("Plots")
import Pkg; Pkg.add("CSV")
import Pkg; Pkg.add("Tables")
import Pkg; Pkg.add("DataFrames")
import Pkg; Pkg.add("WAV")

```

## Использование

```
julia zaudio.jl test.wav

```

## Шаги

1. Читаем WAV файл

2. Нормализуем уровень средним

3. Разбиваем на кадры

4. Кадры с низкой энергией отбрасываем

5. Осуществляем CQT - преобразование

6. Сохраняем в datasets
