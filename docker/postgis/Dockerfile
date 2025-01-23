# Используем официальный образ PostGIS
FROM postgis/postgis:15-3.3

# Устанавливаем временную зону
ENV TZ=Europe/Moscow

# Устанавливаем локаль
ENV LANG ru_RU.utf8

# Копируем скрипты инициализации (если будут нужны)
COPY ./init/*.sql /docker-entrypoint-initdb.d/

# Настраиваем права доступа
RUN chmod 755 /docker-entrypoint-initdb.d/*

# Открываем порт
EXPOSE 5432

# Настраиваем параметры PostgreSQL для оптимальной работы с ГИС данными
RUN echo "\
shared_buffers = 2GB\n\
work_mem = 256MB\n\
maintenance_work_mem = 256MB\n\
random_page_cost = 1.1\n\
effective_cache_size = 3GB\n\
synchronous_commit = off\n\
max_wal_size = 1GB\n\
checkpoint_completion_target = 0.9\n\
" >> /usr/share/postgresql/postgresql.conf.sample
