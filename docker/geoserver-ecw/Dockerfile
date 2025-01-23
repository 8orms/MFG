# Используем готовый образ с поддержкой ECW
FROM urbanits/geoserver:master

# Устанавливаем переменные окружения
ENV GEOSERVER_DATA_DIR=/opt/geoserver/data_dir \
    GEOSERVER_ADMIN_USER=admin \
    GEOSERVER_ADMIN_PASSWORD=geoserver \
    INITIAL_MEMORY=2G \
    MAXIMUM_MEMORY=8G \
    ENCODING=UTF-8 \
    TIMEZONE=Europe/Moscow

# Настраиваем права доступа
RUN chmod -R 755 ${GEOSERVER_DATA_DIR}

# Открываем порт
EXPOSE 8080

# Точка входа наследуется от базового образа
