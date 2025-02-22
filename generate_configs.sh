#!/bin/bash

# Создаем директории
mkdir -p cloud-init docker/compose docker/config scripts/setup scripts/monitoring

# Создаем cloud-init/user-data.yaml
cat > cloud-init/user-data.yaml << 'EOF'
---
#cloud-config
package_update: true
package_upgrade: true

packages:
  - docker.io
  - docker-compose
  - git
  - python3-pip
  - nvidia-docker2
  - build-essential

write_files:
  - path: /opt/ai-assistant/docker-compose.yml
    permissions: '0644'
    content: |
      version: '3.8'
      services:
        core:
          image: ollama/ollama
          ports:
            - "11434:11434"
          volumes:
            - ollama_data:/root/.ollama
        rhasspy:
          image: rhasspy/rhasspy
          ports:
            - "12101:12101"
          volumes:
            - ./config:/profiles
        db:
          image: postgres:15
          environment:
            - POSTGRES_DB=assistant_db
            - POSTGRES_USER=admin
            - POSTGRES_PASSWORD=your_secure_password_here
          volumes:
            - postgres_data:/var/lib/postgresql/data

volumes:
  ollama_data:
  postgres_data:
EOF
# Создаем docker/compose/production.yml
cat > docker/compose/production.yml << 'EOF'
---
version: '3.8'
services:
  assistant:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      - DB_HOST=db
      - REDIS_HOST=cache
      - MODEL_PATH=/models/deepseek-coder
    volumes:
      - ./models:/models
    ports:
      - "8000:8000"
    depends_on:
      - db
      - cache

  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data
    env_file:
      - ../config/.env

  cache:
    image: redis:alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
EOF

# Создаем .yamllint
cat > .yamllint << 'EOF'
---
extends: default

rules:
  document-start:
    present: true
  trailing-spaces:
    level: error
  line-length:
    max: 120
  indentation:
    spaces: 2
    indent-sequences: true
EOF
echo "Конфигурационные файлы созданы!"
