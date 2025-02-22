#!/bin/bash
set -e

# Проверка зависимостей
check_dependencies() {
    command -v docker >/dev/null 2>&1 || { echo "Docker не установлен"; exit 1; }
    command -v docker-compose >/dev/null 2>&1 || { echo "Docker-compose не установлен"; exit 1; }
}

# Настройка окружения
setup_environment() {
    cp docker/config/.env.example docker/config/.env
    echo "Пожалуйста, настройте переменные окружения в docker/config/.env"
}

# Запуск системы
start_system() {
    docker-compose -f docker/compose/production.yml up -d
    echo "Система запущена"
}

main() {
    check_dependencies
    setup_environment
    start_system
}

main "$@"
