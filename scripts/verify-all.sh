#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Начинаем полную проверку конфигурации...${NC}\n"

# Функция проверки наличия необходимых утилит
check_prerequisites() {
    echo -e "${BLUE}📋 Проверка необходимых утилит...${NC}"
    local prerequisites=("docker" "docker-compose" "yamllint" "git")
    local missing=0

    for cmd in "${prerequisites[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}❌ $cmd не установлен${NC}"
            missing=$((missing + 1))
            case $cmd in
                "yamllint")
                    echo "   Установите: sudo apt install yamllint"
                    ;;
                "docker")
                    echo "   Установите: sudo apt install docker.io"
                    ;;
                "docker-compose")
                    echo "   Установите: sudo apt install docker-compose"
                    ;;
            esac
        else
            echo -e "${GREEN}✓ $cmd установлен${NC}"
        fi
    done

    if [ $missing -gt 0 ]; then
        echo -e "${RED}❌ Установите необходимые утилиты перед продолжением${NC}"
        exit 1
    fi
}

# Функция проверки структуры проекта
check_project_structure() {
    echo -e "\n${BLUE}📁 Проверка структуры проекта...${NC}"
    local required_dirs=("cloud-init" "docker/compose" "docker/config" "scripts" "models")
    local required_files=(
        "cloud-init/user-data.yaml"
        "docker/compose/production.yml"
        "docker/config/.env"
        "docker/Dockerfile"
        ".yamllint"
    )
    local missing=0

    for dir in "${required_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo -e "${GREEN}✓ Директория $dir существует${NC}"
        else
            echo -e "${RED}❌ Директория $dir отсутствует${NC}"
            missing=$((missing + 1))
        fi
    done

    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "${GREEN}✓ Файл $file существует${NC}"
        else
            echo -e "${RED}❌ Файл $file отсутствует${NC}"
            missing=$((missing + 1))
        fi
    done

    return $missing
}
# Функция проверки YAML файлов
check_yaml_files() {
    echo -e "\n${BLUE}📝 Проверка YAML файлов...${NC}"
    local yaml_files=("cloud-init/user-data.yaml" "docker/compose/production.yml")
    local has_errors=0

    for file in "${yaml_files[@]}"; do
        echo -e "${YELLOW}Проверка $file:${NC}"
        if yamllint "$file"; then
            echo -e "${GREEN}✓ $file прошел проверку${NC}"
        else
            echo -e "${RED}❌ $file содержит ошибки${NC}"
            has_errors=1
        fi
    done

    return $has_errors
}

# Функция проверки переменных окружения
check_env_variables() {
    echo -e "\n${BLUE}🔐 Проверка переменных окружения...${NC}"
    local env_file="docker/config/.env"
    local required_vars=(
        "DB_NAME"
        "DB_USER"
        "DB_PASSWORD"
        "POSTGRES_DB"
        "POSTGRES_USER"
        "POSTGRES_PASSWORD"
        "REDIS_PASSWORD"
        "OPENAI_API_KEY"
        "RHASSPY_API_KEY"
    )
    local missing=0

    if [ ! -f "$env_file" ]; then
        echo -e "${RED}❌ Файл $env_file не найден!${NC}"
        return 1
    fi

    for var in "${required_vars[@]}"; do
        if grep -q "^${var}=" "$env_file"; then
            value=$(grep "^${var}=" "$env_file" | cut -d'=' -f2)
            if [ -z "$value" ]; then
                echo -e "${RED}❌ Переменная $var имеет пустое значение${NC}"
                missing=$((missing + 1))
            else
                echo -e "${GREEN}✓ Переменная $var установлена${NC}"
            fi
        else
            echo -e "${RED}❌ Переменная $var отсутствует${NC}"
            missing=$((missing + 1))
        fi
    done

    return $missing
}

# Функция проверки Docker конфигурации
check_docker_config() {
    echo -e "\n${BLUE}🐋 Проверка Docker конфигурации...${NC}"
    
    echo -e "${YELLOW}Проверка Dockerfile:${NC}"
    if [ -f "docker/Dockerfile" ]; then
        if docker build -f docker/Dockerfile . -t test_build --quiet; then
            echo -e "${GREEN}✓ Dockerfile валиден${NC}"
        else
            echo -e "${RED}❌ Ошибка в Dockerfile${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Dockerfile не найден${NC}"
        return 1
    fi

    echo -e "${YELLOW}Проверка docker-compose:${NC}"
    if docker-compose -f docker/compose/production.yml config; then
        echo -e "${GREEN}✓ docker-compose конфигурация валидна${NC}"
    else
        echo -e "${RED}❌ Ошибка в docker-compose конфигурации${NC}"
        return 1
    fi
}

# Функция проверки git конфигурации
check_git_config() {
    echo -e "\n${BLUE}📦 Проверка Git конфигурации...${NC}"
    
    if [ -f ".gitignore" ]; then
        echo -e "${GREEN}✓ .gitignore существует${NC}"
        if grep -q "docker/config/.env" ".gitignore"; then
            echo -e "${GREEN}✓ .env файл игнорируется${NC}"
        else
            echo -e "${RED}❌ .env файл не добавлен в .gitignore${NC}"
        fi
    else
        echo -e "${RED}❌ .gitignore отсутствует${NC}"
    fi

    if [ -d ".git" ]; then
        echo -e "${GREEN}✓ Git репозиторий инициализирован${NC}"
        echo -e "${YELLOW}Статус репозитория:${NC}"
        git status
    else
        echo -e "${RED}❌ Git репозиторий не инициализирован${NC}"
    fi
}
# Основная функция
main() {
    local error_count=0

    check_prerequisites
    check_project_structure || error_count=$((error_count + $?))
    check_yaml_files || error_count=$((error_count + $?))
    check_env_variables || error_count=$((error_count + $?))
    check_docker_config || error_count=$((error_count + $?))
    check_git_config || error_count=$((error_count + $?))

    echo -e "\n${BLUE}📊 Итоги проверки:${NC}"
    if [ $error_count -eq 0 ]; then
        echo -e "${GREEN}✅ Все проверки пройдены успешно!${NC}"
    else
        echo -e "${RED}❌ Найдено $error_count ошибок/предупреждений${NC}"
        exit 1
    fi
}

main "$@"
