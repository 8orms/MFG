# Используем официальный образ последней версии
FROM docker.osgeo.org/geoserver:2.26.1

# Устанавливаем переменные окружения
ENV GEOSERVER_DATA_DIR=/opt/geoserver/data_dir \
    GEOSERVER_ADMIN_USER=admin \
    GEOSERVER_ADMIN_PASSWORD=geoserver \
    INITIAL_MEMORY=1G \
    MAXIMUM_MEMORY=4G \
    ENCODING=UTF-8 \
    TIMEZONE=Europe/Moscow \
    CORS_ENABLED=true \
    OPTIMIZE_LINE_WIDTH=true \
    FOOTPRINTS_ENABLED=false

# Настраиваем права доступа
RUN chmod -R 755 ${GEOSERVER_DATA_DIR}

# Открываем порт
EXPOSE 8080

# Точка входа наследуется от базового образа
