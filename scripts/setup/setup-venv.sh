#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "🔧 Настройка виртуального окружения..."

# Проверка наличия необходимых пакетов
check_requirements() {
    local packages=("python3-venv" "python3-full")
    local missing=()

    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package"; then
            missing+=("$package")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}Отсутствуют необходимые пакеты: ${missing[*]}${NC}"
        echo "Установка..."
        sudo apt update
        sudo apt install -y "${missing[@]}"
    fi
}
# Создание и активация виртуального окружения
setup_venv() {
    if [ ! -d "venv" ]; then
        echo "Создание виртуального окружения..."
        python3 -m venv venv
    fi

    echo "Активация виртуального окружения..."
    source venv/bin/activate

    echo "Обновление pip..."
    pip install --upgrade pip

    echo "Установка зависимостей..."
    pip install -r requirements.txt
}

# Проверка успешной установки
verify_installation() {
    echo "Проверка установки..."
    if python -c "import uvicorn; import fastapi; print('✅ Установка успешна!')" 2>/dev/null; then
        echo -e "${GREEN}Виртуальное окружение настроено успешно!${NC}"
    else
        echo -e "${RED}Ошибка при установке пакетов${NC}"
        return 1
    fi
}

main() {
    check_requirements
    setup_venv
    verify_installation
}

main "$@"
