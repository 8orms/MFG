# Настройка Nginx в проекте Corporate GIS

## Структура конфигурации

### Расположение файлов
- **Основной конфиг**: `docker/nginx/nginx.conf` → `/etc/nginx/nginx.conf`
- **Конфиги виртуальных хостов**: `docker/nginx/conf.d/*.conf` → `/etc/nginx/conf.d/`
- **Логи**: `logs/nginx/` → `/var/log/nginx/`

### Docker монтирование
```yaml
volumes:
  - ./docker/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
  - ./docker/nginx/conf.d:/etc/nginx/conf.d:ro
  - ./logs/nginx:/var/log/nginx
```

## Основные параметры

### Ресурсы и производительность
- Процессы: `worker_processes auto;`
- Соединения: `worker_connections 1024;`
- Таймауты:
  ```nginx
  proxy_connect_timeout 600;
  proxy_send_timeout 600;
  proxy_read_timeout 600;
  send_timeout 600;
  ```
- Буферы:
  ```nginx
  client_body_buffer_size 128k;
  proxy_buffer_size 4k;
  proxy_buffers 4 32k;
  proxy_busy_buffers_size 64k;
  proxy_temp_file_write_size 64k;
  ```

### Ограничения и безопасность
- Максимальный размер запроса: `client_max_body_size 500M;`
- Защита от DDoS:
  ```nginx
  limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;
  limit_conn_zone $binary_remote_addr zone=addr:10m;
  ```
- Заголовки безопасности:
  ```nginx
  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header X-XSS-Protection "1; mode=block" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header Referrer-Policy "no-referrer-when-downgrade" always;
  add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
  ```

## Проксируемые сервисы

### GeoServer Vector
- **URL**: `/geoserver-vector/`
- **Backend**: `http://geoserver-vector:8080/geoserver/`
- **Порт**: 8082
- **Особенности**: 
  - Требует настройки cookie path
  - Поддерживает WebSocket соединения

### GeoServer ECW
- **URL**: `/geoserver-ecw/`
- **Backend**: `http://geoserver-ecw:8080/geoserver/`
- **Порт**: 8081
- **Особенности**: 
  - Требует настройки cookie path
  - Работает с растровыми данными

### GeoNetwork
- **URL**: `/geonetwork/`
- **Backend**: `http://geonetwork:8080/geonetwork/`
- **Порт**: 8083
- **Особенности**:
  - Интегрируется с GeoServer
  - Требует настройки cookie path

## Логирование

### Форматы логов
- **Основной формат**: JSON
- **Расположение**: `/var/log/nginx/`
- **Файлы**:
  - `access.log` - логи доступа
  - `error.log` - логи ошибок

### Формат JSON логов
```nginx
log_format detailed_json escape=json '{
    "time_local":"$time_local",
    "remote_addr":"$remote_addr",
    "remote_user":"$remote_user",
    "request":"$request",
    "status": "$status",
    "body_bytes_sent":"$body_bytes_sent",
    "request_time":"$request_time",
    "http_referrer":"$http_referer",
    "http_user_agent":"$http_user_agent",
    "http_x_forwarded_for":"$http_x_forwarded_for",
    "upstream_response_time":"$upstream_response_time"
}';
```

## Мониторинг

### Nginx Status
- **URL**: `/nginx_status`
- **Доступ**: только с localhost
- **Метрики**: базовая статистика Nginx

## Система мониторинга и контроля доступности

### Компоненты системы мониторинга

#### 1. Nginx Status
```nginx
location /nginx_status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    deny all;
}
```

#### 2. Filebeat для сбора логов
```yaml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/access.log
  json.keys_under_root: true
  json.add_error_key: true
  
- type: log
  enabled: true
  paths:
    - /var/log/nginx/error.log
  
output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  indices:
    - index: "nginx-access-%{+yyyy.MM.dd}"
      when.contains:
        message: "access.log"
    - index: "nginx-error-%{+yyyy.MM.dd}"
      when.contains:
        message: "error.log"
```

#### 3. Автоматические проверки (Healthcheck)
Создаем скрипт `tools/healthcheck.sh`:
```bash
#!/bin/bash

# Функция для проверки HTTP статуса
check_http() {
    local url=$1
    local expected=$2
    local description=$3
    local status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$status" = "$expected" ]; then
        echo "✓ $description: OK (Status: $status)"
        return 0
    else
        echo "✗ $description: FAIL (Expected: $expected, Got: $status)"
        return 1
    }
}

# Функция для проверки TCP порта
check_tcp() {
    local host=$1
    local port=$2
    local description=$3
    
    nc -z -w5 "$host" "$port"
    if [ $? -eq 0 ]; then
        echo "✓ $description: Port $port is open"
        return 0
    else
        echo "✗ $description: Port $port is closed"
        return 1
    fi
}

# Массив проверок
declare -A checks=(
    ["GeoServer Vector"]="http://localhost/geoserver-vector/ 302"
    ["GeoServer ECW"]="http://localhost/geoserver-ecw/ 302"
    ["GeoNetwork"]="http://localhost/geonetwork/ 302"
    ["Elasticsearch"]="http://localhost:9200/ 200"
    ["Kibana"]="http://localhost:5601/ 302"
)

# Массив TCP проверок
declare -A tcp_checks=(
    ["PostGIS"]="localhost 5432"
    ["Elasticsearch"]="localhost 9200"
    ["Kibana"]="localhost 5601"
    ["Nginx"]="localhost 80"
)

# Выполнение проверок
failures=0

echo "=== Starting HTTP checks ==="
for service in "${!checks[@]}"; do
    IFS=' ' read -r url expected <<< "${checks[$service]}"
    check_http "$url" "$expected" "$service" || ((failures++))
done

echo -e "\n=== Starting TCP checks ==="
for service in "${!tcp_checks[@]}"; do
    IFS=' ' read -r host port <<< "${tcp_checks[$service]}"
    check_tcp "$host" "$port" "$service" || ((failures++))
done

# Отправка метрик в Elasticsearch
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
curl -X POST "http://localhost:9200/healthchecks/_doc" -H "Content-Type: application/json" -d "{
    \"@timestamp\": \"$timestamp\",
    \"failures\": $failures,
    \"total_checks\": $((${#checks[@]} + ${#tcp_checks[@]})),
    \"success_rate\": $(( (${#checks[@]} + ${#tcp_checks[@]} - failures) * 100 / (${#checks[@]} + ${#tcp_checks[@]}) ))
}"

exit $failures
```

#### 4. Kibana Dashboard
- Создаем визуализации для:
  - Статуса сервисов
  - Времени ответа
  - Количества ошибок
  - Success Rate

### Автоматизация проверок

#### 1. Docker Healthcheck
Добавляем в `docker-compose.yml`:
```yaml
services:
  nginx:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/nginx_status"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

#### 2. Cron задачи
Добавляем в crontab:
```bash
*/5 * * * * /path/to/tools/healthcheck.sh >> /var/log/healthcheck.log 2>&1
```

#### 3. Prometheus метрики (опционально)
Добавляем nginx-prometheus-exporter:
```yaml
services:
  nginx-exporter:
    image: nginx/nginx-prometheus-exporter
    command: -nginx.scrape-uri=http://nginx:80/nginx_status
    ports:
      - "9113:9113"
    depends_on:
      - nginx
```

### Оповещения

#### 1. Email уведомления
Создаем скрипт `tools/notify.sh`:
```bash
#!/bin/bash

# Параметры почты
SMTP_SERVER="smtp.example.com"
SMTP_PORT="587"
SMTP_USER="monitor@example.com"
ADMIN_EMAIL="admin@example.com"

# Отправка уведомления
send_notification() {
    local subject="$1"
    local body="$2"
    echo "$body" | mail -s "$subject" \
        -S smtp="$SMTP_SERVER:$SMTP_PORT" \
        -S smtp-use-starttls \
        -S smtp-auth=login \
        -S smtp-auth-user="$SMTP_USER" \
        -S smtp-auth-password="$SMTP_PASSWORD" \
        "$ADMIN_EMAIL"
}

# Проверяем результаты healthcheck
if [ $1 -ne 0 ]; then
    send_notification "Service Check Failed" "$(cat /var/log/healthcheck.log)"
fi
```

#### 2. Elasticsearch Watcher
Создаем алерт в Elasticsearch:
```json
{
  "trigger": {
    "schedule": {
      "interval": "5m"
    }
  },
  "input": {
    "search": {
      "request": {
        "indices": ["healthchecks"],
        "body": {
          "query": {
            "bool": {
              "must": [
                {
                  "range": {
                    "@timestamp": {
                      "gte": "now-5m"
                    }
                  }
                },
                {
                  "range": {
                    "success_rate": {
                      "lt": 100
                    }
                  }
                }
              ]
            }
          }
        }
      }
    }
  },
  "condition": {
    "compare": {
      "ctx.payload.hits.total": {
        "gt": 0
      }
    }
  },
  "actions": {
    "email_admin": {
      "email": {
        "to": "admin@example.com",
        "subject": "Service Health Check Alert",
        "body": "Service health checks failed. Please check the dashboard."
      }
    }
  }
}
```

### Визуализация и отчетность

#### 1. Kibana Dashboard
- Создаем дашборд с основными метриками:
  - Статус сервисов (зеленый/красный)
  - График доступности за последние 24 часа
  - Топ ошибок
  - Среднее время ответа

#### 2. Prometheus + Grafana (опционально)
- Устанавливаем Grafana
- Импортируем готовый дашборд для Nginx
- Добавляем алерты в Grafana

### Действия при сбоях

1. **Автоматические действия**:
   - Перезапуск сервиса при падении
   - Очистка логов при переполнении
   - Ротация логов

2. **Ручные действия**:
   - Проверка логов
   - Проверка конфигурации
   - Проверка ресурсов
   - Рестарт сервисов

## Важные особенности

### Редиректы
- Все URL без завершающего слеша автоматически редиректятся на URL со слешем
- Настроены через:
  ```nginx
  location = /geoserver-vector {
      return 301 $scheme://$host$request_uri/;
  }
  ```

### Прокси-заголовки
Для всех проксируемых сервисов установлены:
```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header Connection "";
proxy_http_version 1.1;
```

### Ограничения запросов
Для каждого location блока:
```nginx
limit_req zone=one burst=10 nodelay;
limit_conn addr 10;
```

## Проверка конфигурации

### Внутри контейнера
```bash
nginx -t
```

### Проверка доступности сервисов
```bash
curl -I http://localhost/geoserver-vector/
curl -I http://localhost/geoserver-ecw/
curl -I http://localhost/geonetwork/
```

## Типичные проблемы и решения

1. **502 Bad Gateway**
   - Проверить доступность backend сервиса
   - Проверить настройки upstream
   - Увеличить таймауты если необходимо

2. **404 Not Found**
   - Проверить правильность путей в proxy_pass
   - Проверить настройки location блоков
   - Проверить редиректы

3. **413 Request Entity Too Large**
   - Увеличить client_max_body_size
   - Проверить настройки буферов

4. **504 Gateway Timeout**
   - Увеличить proxy_read_timeout
   - Проверить время ответа backend сервиса 