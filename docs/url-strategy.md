# Стратегия URL и маршрутизации

## Базовые принципы

1. Все сервисы должны быть доступны через единый домен
2. Использовать явные префиксы для разных типов сервисов
3. Сохранять согласованность между внешними и внутренними путями
4. Избегать конфликтов между путями разных сервисов

## Структура URL

### Внешние URL (доступные пользователям)

- GeoServer Vector: `/geoserver-vector/*`
  - Веб-интерфейс: `/geoserver-vector/web/`
  - WMS: `/geoserver-vector/wms`
  - WFS: `/geoserver-vector/wfs`
  - OWS: `/geoserver-vector/ows`

- GeoServer ECW: `/geoserver-ecw/*`
  - Веб-интерфейс: `/geoserver-ecw/web/`
  - WMS: `/geoserver-ecw/wms`
  - WFS: `/geoserver-ecw/wfs`
  - OWS: `/geoserver-ecw/ows`

- GeoNetwork: `/geonetwork/*`
  - Веб-интерфейс: `/geonetwork/`
  - API: `/geonetwork/api/`
  - CSW: `/geonetwork/srv/eng/csw`

### Внутренние URL (для Docker-сервисов)

- GeoServer Vector: `http://corporate-gis-geoserver-vector-1:8080/geoserver/`
- GeoServer ECW: `http://corporate-gis-geoserver-ecw-1:8080/geoserver/`
- GeoNetwork: `http://corporate-gis-geonetwork-1:8080/geonetwork/`

## Правила редиректов

1. Всегда добавлять завершающий слэш для директорий
2. Использовать явные правила редиректа вместо автоматических
3. Сохранять оригинальные пути при проксировании

## Настройка Nginx

### Основные принципы

1. Использовать named locations для проксирования
2. Явно указывать правила редиректа
3. Настраивать корректные заголовки для прокси
4. Использовать try_files для проверки существования файлов

### Пример конфигурации

```nginx
# GeoServer Vector
location /geoserver-vector/ {
    try_files $uri @geoserver_vector;
}

location @geoserver_vector {
    proxy_pass http://corporate-gis-geoserver-vector-1:8080/geoserver/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## Проверка конфигурации

1. Проверить доступность всех сервисов через внешние URL
2. Убедиться в корректной работе редиректов
3. Проверить сохранение сессий и cookies
4. Протестировать все типы запросов (GET, POST, etc.)

## Обработка ошибок

1. Настроить информативные страницы ошибок
2. Логировать все ошибки редиректов
3. Мониторить количество 404 и 500 ошибок 