#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

ENV_FILE="docker/config/.env"

echo "🔍 Проверка переменных окружения..."

# Проверка существования файла
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}❌ Файл $ENV_FILE не найден!${NC}"
    exit 1
fi

# Массив обязательных переменных
required_vars=(
    "DB_NAME"
    "DB_USER"
    "DB_PASSWORD"
    "POSTGRES_DB"
    "POSTGRES_USER"
    "POSTGRES_PASSWORD"
    "REDIS_PASSWORD"
)

# Проверка переменных
missing_vars=0
for var in "${required_vars[@]}"; do
    if ! grep -q "^${var}=" "$ENV_FILE"; then
        echo -e "${RED}❌ Отсутствует переменная: ${var}${NC}"
        missing_vars=$((missing_vars + 1))
    else
        value=$(grep "^${var}=" "$ENV_FILE" | cut -d'=' -f2)
        if [ -z "$value" ]; then
            echo -e "${RED}❌ Пустое значение для: ${var}${NC}"
            missing_vars=$((missing_vars + 1))
        else
            echo -e "${GREEN}✓ ${var} установлен${NC}"
        fi
    fi
done

if [ $missing_vars -eq 0 ]; then
    echo -e "${GREEN}✅ Все необходимые переменные установлены!${NC}"
else
    echo -e "${RED}❌ Отсутствуют $missing_vars переменных!${NC}"
    exit 1
fi
