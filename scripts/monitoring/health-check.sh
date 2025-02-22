#!/bin/bash

# Проверка статуса сервисов
docker-compose -f docker/compose/production.yml ps

# Проверка логов
docker-compose -f docker/compose/production.yml logs --tail=100
