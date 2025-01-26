translate the question into English and then answer it.
Роль - учитель, специалист (по сетевым технологиям, БД, ГИС системам, Docker и все испольлзуемые и планируемые копмоненты корпоративной серверной ГИС. 
Будет разворачиваться на сервере организации (150-200 человек), которая занимается инженерными изысканиями (геология\геодезия\экология и т.д.)в РФ, с большой базой выполненных объектов при необходимости можно будет усилить сервер, в ходе беседы указывай места оторые сильнее всего зависятт от железа) c  что ты сейчас работаешь в среде Cursor AI (Claudy Sonnet), и запускаешь команды из windows, нужен powershell 

# Корпоративная ГИС

> Система на основе GeoServer с разделением на векторные и растровые данные

## 📌 Ключевые параметры системы

### Имена сервисов и контейнеров:
* PostGIS: `corporate-gis-postgis-1`
* GeoServer Vector: `corporate-gis-geoserver_vector-1`
* GeoServer ECW: `corporate-gis-geoserver_ecw-1`
* GeoNetwork: `corporate-gis-geonetwork-1`
* Nginx: `corporate-gis-nginx-1`
* Elasticsearch: `corporate-gis-elasticsearch-1`

### Версии ПО:
* PostGIS: 15-3.3
* GeoServer Vector: 2.25.2
* GeoNetwork: 4.2.2
* Nginx: stable
* Elasticsearch: 7.17.9

### Порты и URL:
* Nginx: `80` → `http://localhost`
* GeoServer ECW: `8081` → `http://localhost/geoserver-ecw`
* GeoServer Vector: `8082` → `http://localhost/geoserver-vector`
* GeoNetwork: `8083` → `http://localhost/geonetwork`
* PostGIS: `5432`
* Elasticsearch: `9200`
* Kibana: `5601` → `http://localhost:5601`

### Мониторинг системы:
* Kibana Dashboard: `http://localhost:5601`
* Nginx Status: `http://localhost/nginx_status`
* Метрики:
  * Docker: `metricbeat-docker-*`
  * PostgreSQL: `metricbeat-postgresql-*`
  * Nginx: `metricbeat-nginx-*`
  * Система: `metricbeat-system-*`

### Учетные данные:
* GeoServer: `admin`/`geoserver`
* PostGIS: `postgres`/`postgres`
* База данных: `gis`

### Сетевые настройки:
* Сеть: `gis_network`
* Подсеть: `192.168.100.0/24`
* Внутренние имена сервисов: 
  * `postgis`
  * `geoserver_vector`
  * `geoserver_ecw`
  * `geonetwork`
  * `nginx`
  * `elasticsearch`

## 📂 Структура проекта
```
./data/
  ├── postgis/
  ├── geoserver-data/
  │   ├── ecw/          # Конфигурация растрового GeoServer
  │   └── vector/       # Конфигурация векторного GeoServer
  ├── raster-storage/   # Хранилище растровых данных
  └── geonetwork/       # Конфигурация GeoNetwork
      └── config/       # Пользовательские настройки
./docker/
  ├── nginx/
  │   └── conf/        # Конфигурация Nginx
  ├── metricbeat/      # Конфигурация Metricbeat
  └── filebeat/        # Конфигурация Filebeat
```

## ✅ Статус проекта

### Выполнено:
1. Настройка PostGIS
2. Настройка GeoServer Vector
3. Настройка GeoServer ECW
4. Настройка Nginx как прокси
5. Добавление GeoNetwork
6. Базовая маршрутизация через Nginx

### В процессе:
* Интеграция GeoNetwork с GeoServer (проблема с харвестером)

### Требует выполнения:
* Настройка SSL
* Тонкая настройка кэширования
* Мониторинг сервисов

## 🚨 Известные проблемы и решения

### DNS в Docker:
> Симптом: `Unknown host: geoserver-vector`
* Решение: Использовать URL `http://nginx/geoserver-vector/wms`

### Символы в именах хостов:
> Симптом: `URISyntaxException: Illegal character in hostname`
* Решение: Использовать дефисы вместо подчеркиваний или Nginx как прокси

## 🔧 Управление системой

### Основные команды:
```bash
# Запуск системы
docker-compose up -d

# Проверка статуса
docker-compose ps

# Просмотр логов
docker-compose logs [сервис]

# Перезапуск сервиса
docker-compose restart [сервис]

# Просмотр метрик
curl http://localhost/nginx_status    # Статус Nginx
curl http://localhost:9200/_cat/indices?v    # Индексы Elasticsearch
```

### Важно при работе в Windows:
* Использовать PowerShell для команд
* Синтаксис команд:
  ```powershell
  # Правильно:
  docker-compose down; docker-compose up -d
  
  # Неправильно:
  docker-compose down && docker-compose up -d
  ```

## 💻 Требования к системе
* Docker Desktop
* RAM: минимум 8GB
* Диск: 20GB свободного места
* ОС: Windows 10+ или Linux
* Свободные порты: 80, 8081-8083, 5432, 9200

## 📝 Рекомендации
1. Проверяйте свободные порты перед запуском
2. Перезапускайте Nginx после изменения конфигурации
3. Проверяйте наличие ECW лицензии
4. Следите за логами сервисов
5. Регулярно проверяйте статус контейнеров
6. Мониторьте метрики в Kibana
7. Настройте оповещения для критических событий

## 🚨 Основные проблемы и решения:

### 1. Проблема с DNS в Docker:
- Симптом: `Unknown host: geoserver-vector`
- Решение: Использование правильных имен сервисов в docker-compose
- Рабочий URL: `http://nginx/geoserver-vector/wms`

### 2. Проблема с символами в именах хостов:
- Симптом: `URISyntaxException: Illegal character in hostname`
- Решение: Замена подчеркиваний на дефисы или использование Nginx как прокси

### 3. Проблемы с сетью Docker:
- Сеть: gis_network
- Подсеть: 192.168.100.0/24
- Решение: Правильная настройка DNS и использование имен сервисов

## 📝 Следующие шаги:
1. Завершить настройку харвестера GeoNetwork
2. Проверить работу ECW лицензии
3. Настроить SSL
4. Оптимизировать кэширование
5. Добавить мониторинг сервисов

## 🔧 Полезные команды:

```bash
# Проверка статуса контейнеров
docker-compose ps

# Просмотр логов
docker-compose logs [сервис]

# Перезапуск сервиса
docker-compose restart [сервис]
```

## 🌐 Сетевые настройки:
- Все сервисы в одной сети: `gis_network`
- Nginx работает как обратный прокси
- Внутренняя маршрутизация через имена сервисов
- Внешний доступ через порт 80 (Nginx)

## Важные замечания:
1. При работе в Windows используйте PowerShell для выполнения команд
2. Убедитесь, что все необходимые порты свободны перед запуском
3. При изменении конфигурации Nginx требуется перезапуск контейнера
4. Для работы с ECW необходима действующая лицензия

## Требования к системе:
- Docker Desktop
- Минимум 8GB RAM
- 20GB свободного места на диске
- Windows 10 или новее / Linux

## Архитектура

Система состоит из следующих компонентов:

1. **PostGIS** - пространственная база данных
   - Порт: 5432
   - База данных: gis
   - Пользователь: postgres
   - Пароль: postgres

2. **GeoServer Vector** (kartoza/geoserver:2.25.2)
   - Для работы с векторными данными
   - Порт: 8082
   - Веб-интерфейс: http://localhost/geoserver-vector
   - WMS: http://localhost/geoserver-vector/wms
   - Прямой доступ: http://localhost:8082/geoserver/web/
   - Логин: admin
   - Пароль: geoserver
   - Установленные расширения:
     - vectortiles-plugin
     - wps-plugin
     - printing-plugin

3. **GeoServer ECW** (urbanits/geoserver:master)
   - Для работы с растровыми данными (особенно ECW)
   - Порт: 8081
   - Веб-интерфейс: http://localhost/geoserver-ecw/
   - WMS: http://localhost/geoserver-ecw/wms
   - Прямой доступ: http://localhost:8081/geoserver/web/

4. **Nginx**
   - Прокси-сервер для маршрутизации запросов
   - Порт: 80
   - Базовый URL: http://localhost/
   - Кэширование WMS-запросов
   - CORS поддержка

5. **GeoNetwork** (geonetwork:4.2.2)
   - Каталог метаданных
   - Порт: 8083
   - Веб-интерфейс: http://localhost/geonetwork/
   - Прямой доступ: http://localhost:8083/geonetwork/
   - Интеграция с обоими GeoServer'ами
   - Использует PostGIS для хранения данных
   - Возможности:
     - Управление метаданными
     - Поиск и каталогизация данных
     - Предпросмотр слоев
     - Интеграция через CSW
     - Поддержка стандартов ISO 19115/19139

6. **Мониторинг**
   - Elasticsearch + Kibana
   - Порт Kibana: 5601
   - Веб-интерфейс: http://localhost:5601
   - Компоненты мониторинга:
     - Metricbeat: сбор метрик
     - Filebeat: сбор логов
   - Основные дашборды:
     - Docker контейнеры
     - PostgreSQL метрики
     - Nginx статистика
     - Системные ресурсы

## Структура директорий

```
corporate-gis/
├── data/
│   ├── geoserver-data/
│   │   ├── ecw/          # Конфигурация растрового GeoServer
│   │   └── vector/       # Конфигурация векторного GeoServer
│   ├── geonetwork/       # Конфигурация GeoNetwork
│   │   └── config/       # Пользовательские настройки GeoNetwork
│   ├── raster-storage/   # Хранилище растровых данных
│   └── user_projections/ # Пользовательские проекции
├── docker/
│   ├── nginx/
│   │   ├── conf/        # Конфигурация Nginx
│   │   └── Dockerfile
│   └── postgis/
│       ├── init/        # Скрипты инициализации PostGIS
│       └── Dockerfile
├── postgis/
│   └── init/           # SQL скрипты для инициализации БД
├── docker-compose.yml
└── README.md
```

## Запуск системы

1. Убедитесь, что Docker Desktop и PowerShell установлены
2. Клонируйте репозиторий
3. Создайте необходимые директории через PowerShell:
   ```powershell
   mkdir -Force -Path data/geoserver-data/ecw, data/geoserver-data/vector, data/raster-storage, data/user_projections
   ```
4. Запустите контейнеры:
   ```powershell
   docker-compose up -d
   ```

## Доступ к сервисам

### Через Nginx (рекомендуется)

- Векторный GeoServer: http://localhost/geoserver-vector/
- Растровый GeoServer: http://localhost/geoserver-ecw/
- GeoNetwork: http://localhost/geonetwork/

### Прямой доступ

- Векторный GeoServer: http://localhost:8082/geoserver/web/
- Растровый GeoServer: http://localhost:8081/geoserver/web/
- GeoNetwork: http://localhost:8083/geonetwork/
- PostGIS: localhost:5432

## Особенности конфигурации

1. **Nginx**:
   - Настроено кэширование WMS-тайлов
   - Поддержка CORS
   - Отдельные локации для векторного и растрового GeoServer
   - Автоматическое перенаправление на векторный GeoServer

2. **PostGIS**:
   - Оптимизированные настройки для работы с ГИС-данными
   - Автоматическое создание расширений при первом запуске

3. **GeoServer Vector**:
   - Оптимизирован для работы с векторными данными
   - Установлены дополнительные плагины

4. **GeoServer ECW**:
   - Специальная сборка с поддержкой ECW
   - Оптимизирован для работы с растровыми данными

5. **GeoNetwork**:
   - Каталог метаданных
   - Интеграция с обоими GeoServer'ами
   - Использует PostGIS для хранения данных
   - Возможности:
     - Управление метаданными
     - Поиск и каталогизация данных
     - Предпросмотр слоев
     - Интеграция через CSW
     - Поддержка стандартов ISO 19115/19139

6. **Мониторинг**
   - Elasticsearch + Kibana
   - Порт Kibana: 5601
   - Веб-интерфейс: http://localhost:5601
   - Компоненты мониторинга:
     - Metricbeat: сбор метрик
     - Filebeat: сбор логов
   - Основные дашборды:
     - Docker контейнеры
     - PostgreSQL метрики
     - Nginx статистика
     - Системные ресурсы

## Известные проблемы и их решения

### 1. Проблема с символом подчеркивания в URL

При настройке проксирования GeoServer через Nginx следует избегать использования символа подчеркивания (_) в URL-путях и именах серверов. Tomcat, на котором работает GeoServer, не принимает символ подчеркивания в имени хоста, что приводит к ошибке:

```
The character [_] is never valid in a domain name
```

**Решение:**
- Использовать дефис (-) вместо подчеркивания (_) в URL-путях
- Пример правильных URL:
  - `/geoserver-vector/` вместо `/geoserver_vector/`
  - `/geoserver-ecw/` вместо `/geoserver_ecw/`

### 2. Настройка проксирования в Nginx

Для корректной работы GeoServer через Nginx необходимо настроить:

1. Правильные upstream блоки:
```nginx
upstream geoserver-ecw {
    server geoserver_ecw:8080;
}

upstream geoserver-vector {
    server geoserver_vector:8080;
}
```

2. Корректные location блоки с обработкой аутентификации:
```nginx
location /geoserver-vector/ {
    proxy_pass http://geoserver-vector/geoserver/;
    proxy_redirect http://geoserver-vector/geoserver/ /geoserver-vector/;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Host $host;
}

location /geoserver-vector/j_spring_security_check {
    proxy_pass http://geoserver-vector/geoserver/j_spring_security_check;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Host $host;
}
```

3. Общие настройки прокси:
```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

### 3. Таймауты и ограничения

Рекомендуемые настройки для стабильной работы:
```nginx
client_max_body_size 50M;
proxy_connect_timeout 60;
proxy_send_timeout 60;
proxy_read_timeout 60;
send_timeout 60;
```

## Диагностика проблем

1. Проверить логи Nginx:
```powershell
docker-compose logs nginx
```

2. Проверить логи GeoServer:
```powershell
docker-compose logs geoserver_vector geoserver_ecw
```

3. Проверить занятость портов:
```powershell
netstat -ano | findstr ":80 :8081 :8082"
```

# Настройка GeoServer через Nginx

## Известные проблемы и их решения

### 1. Проблема с символом подчеркивания в URL

При настройке проксирования GeoServer через Nginx следует избегать использования символа подчеркивания (_) в URL-путях и именах серверов. Tomcat, на котором работает GeoServer, не принимает символ подчеркивания в имени хоста, что приводит к ошибке:

```
The character [_] is never valid in a domain name
```

**Решение:**
- Использовать дефис (-) вместо подчеркивания (_) в URL-путях
- Пример правильных URL:
  - `/geoserver-vector/` вместо `/geoserver_vector/`
  - `/geoserver-ecw/` вместо `/geoserver_ecw/`

### 2. Настройка проксирования в Nginx

Для корректной работы GeoServer через Nginx необходимо настроить:

1. Правильные upstream блоки:
```nginx
upstream geoserver-ecw {
    server geoserver_ecw:8080;
}

upstream geoserver-vector {
    server geoserver_vector:8080;
}
```

2. Корректные location блоки с обработкой аутентификации:
```nginx
location /geoserver-vector/ {
    proxy_pass http://geoserver-vector/geoserver/;
    proxy_redirect http://geoserver-vector/geoserver/ /geoserver-vector/;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Host $host;
}

location /geoserver-vector/j_spring_security_check {
    proxy_pass http://geoserver-vector/geoserver/j_spring_security_check;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Host $host;
}
```

3. Общие настройки прокси:
```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

### 3. Таймауты и ограничения

Рекомендуемые настройки для стабильной работы:
```nginx
client_max_body_size 50M;
proxy_connect_timeout 60;
proxy_send_timeout 60;
proxy_read_timeout 60;
send_timeout 60;
```

## Проверка работоспособности

1. Проверить доступность GeoServer напрямую:
   - Vector: http://localhost:8082/geoserver/web/
   - ECW: http://localhost:8081/geoserver/web/

2. Проверить доступность через Nginx:
   - Vector: http://localhost/geoserver-vector/web/
   - ECW: http://localhost/geoserver-ecw/web/

## Диагностика проблем

1. Проверить логи Nginx:
```bash
docker-compose logs nginx
```

2. Проверить логи GeoServer:
```bash
docker-compose logs geoserver_vector geoserver_ecw
```

3. Проверить занятость портов:
```bash
netstat -ano | findstr ":80 :8081 :8082"
```

## Рабочие URL сервисов

### GeoServer Vector
- Административный интерфейс: http://localhost/geoserver-vector/
- WMS: http://localhost/geoserver-vector/wms
- OWS: http://localhost/geoserver-vector/ows

### GeoServer ECW
- Административный интерфейс: http://localhost/geoserver-ecw/
- WMS: http://localhost/geoserver-ecw/wms
- OWS: http://localhost/geoserver-ecw/ows

### GeoNetwork
- Интерфейс: http://localhost/geonetwork/

## Принципы развертывания

Основной принцип развертывания системы - минимальное количество ручных действий для запуска и настройки. Система должна быть готова к работе "из коробки" после выполнения `docker-compose up -d`.

### Рекомендации по конфигурации

1. **Конфигурационные файлы**: Все конфигурационные файлы должны быть подготовлены заранее и храниться в соответствующих директориях проекта. Избегайте ручных изменений файлов внутри контейнеров.

2. **Монтирование директорий**: 
   - Используйте монтирование томов для хранения данных и логов вне контейнеров
   - Конфигурационные файлы должны быть правильно размещены в структуре проекта
   - Пути к файлам конфигурации должны быть корректно прописаны в `docker-compose.yml`

3. **Логирование**:
   - Все логи должны быть доступны из хост-системы
   - Настройте пути к логам в конфигурации сервисов так, чтобы они указывали на смонтированные тома
   - Используйте единый подход к хранению и ротации логов

4. **Автоматизация**:
   - Все необходимые настройки должны выполняться автоматически при старте контейнеров
   - Используйте environment-переменные для конфигурации
   - Подготовьте init-скрипты для первоначальной настройки сервисов

