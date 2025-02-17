#!/usr/bin/env bash

# Этот скрипт обновляет переменные окружения в указанном файле окружения.
# Он поддерживает необязательные начальные и конечные маркеры для ограничения области обновления.
#
# Использование:
#   updateEnvVars.sh --env-file <file> [--start-marker <marker> [--end-marker <marker>]] <env_vars>
#
# Аргументы:
#   --env-file <file>       Путь к файлу окружения, который нужно обновить.
#   --start-marker <marker> Необязательно. Маркер, указывающий начало секции для обновления.
#   --end-marker <marker>   Необязательно. Маркер, указывающий конец секции для обновления.
#   <env_vars>              Переменные окружения, которые нужно добавить или обновить в формате key=value.
#
# Пример:
#   ./updateEnvVars.sh --env-file .env --start-marker "# START" --end-marker "# END" VAR1=value1 VAR2=value2
#
# Скрипт выполняет следующие шаги:
# 1. Разбирает аргументы командной строки.
# 2. Проверяет наличие и зависимости аргументов.
# 3. Извлекает переменные окружения из оставшихся аргументов.
# 4. Проверяет, существует ли указанный файл окружения.
# 5. Создает временный файл и копирует в него содержимое файла окружения.
# 6. Если указаны начальный и конечный маркеры, удаляет строки между маркерами (включительно).
# 7. Добавляет новые переменные окружения в файл.
# 8. Копирует временный файл обратно в исходный файл окружения и удаляет временный файл.

print_usage() {
    echo "Usage: $0 --env-file <file> [--start-marker <marker> [--end-marker <marker>]] <env_vars>"
    exit 1
}

print_help() {
    cat << EOF
Этот скрипт обновляет переменные окружения в указанном файле окружения.
Он поддерживает необязательные начальные и конечные маркеры для ограничения области обновления.

Использование:
  updateEnvVars.sh --env-file <file> [--start-marker <marker> [--end-marker <marker>]] <env_vars>

Аргументы:
  --env-file <file>       Путь к файлу окружения, который нужно обновить.
  --start-marker <marker> Необязательно. Маркер, указывающий начало секции для обновления.
  --end-marker <marker>   Необязательно. Маркер, указывающий конец секции для обновления.
  <env_vars>              Переменные окружения, которые нужно добавить или обновить в формате key=value.

Пример:
  ./updateEnvVars.sh --env-file .env --start-marker "# START" --end-marker "# END" VAR1=value1 VAR2=value2
EOF
}

# вывод справки, если первый аргумент --help
if [[ "$1" == "--help" ]]; then
    print_help
    exit 0
fi

# вычисление переданных аргументов
while [[ $# -gt 0 ]]; do
    case $1 in
        --env-file)
            env_file="$2"
            shift 2
            ;;
        --start-marker)
            start_marker="$2"
            shift 2
            ;;
        --end-marker)
            end_marker="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

# проверка существования аргументов и их зависимостей
# и синтаксиса, а так же нормализация значений
#####################################################

# проверка наличия аргумента $env_file
if [[ -z "$env_file" ]]; then
    print_usage
fi

# проверка наличия конечного маркера без начального
if [[ -n "$end_marker" && -z "$start_marker" ]]; then
    print_usage
fi

# если не передан конечный маркер, то он равен начальному
if [[ -z "$end_marker" ]]; then
    end_marker="$start_marker"
fi

# получение переменных окружения из оставшихся аргументов и запись их в ассоциативный массив
declare -A env_vars
while [[ $# -gt 0 ]]; do
    if [[ "$1" == *"="* ]]; then
        IFS='=' read -r key value <<< "$1"
        env_vars["$key"]="$value"
    else
        echo "Error: Invalid argument '$1'. Expected format 'key=value'."
        exit 1
    fi
    shift
done

# проверка существования файла
if [[ ! -f "$env_file" ]]; then
    echo "Error: File $env_file does not exist."
    exit 1
fi

# создание временного файла, копирование в него исходного файла, поиск начального и конечного маркера в файле
temp_file=$(mktemp)
cp $env_file $temp_file

# проверка что начальный маркер существует
if [[ -n "$start_marker" ]]; then

    # поиск начального и конечного маркера в файле
    start_line=$(grep -n "^${start_marker}" "$temp_file" | cut -d: -f1)
    end_line=$(grep -n "^${end_marker}" "$temp_file" | cut -d: -f1)

    # проверка существования начального и конечного маркера
    if [[ -z "$start_line" ]]; then
        echo "Error: Start marker ${start_marker} not found in $env_file."
        exit 1
    fi

    if [[ -z "$end_line" ]]; then
        echo "Error: End marker ${end_marker} not found in $env_file."
        exit 1
    fi

    # удаление строк между начальным и конечным маркером (включительно)
    sed -i "${start_line},${end_line}d" "$temp_file"

    # добавление пустой строки после начального маркера
    sed -i "${start_line}i \\" "$temp_file"
else
    start_line=$(wc -l < "$temp_file")
    start_line=$((start_line + 1))
fi

# добавление переменных окружения в файл
for key in "${!env_vars[@]}"; do
    sed -i "${start_line}i ${key}=${env_vars[$key]}" "$temp_file"
    start_line=$((start_line + 1))
done

# копирование временного файла в исходный и удаление временного файла
cp "$temp_file" "$env_file" && rm "$temp_file"
