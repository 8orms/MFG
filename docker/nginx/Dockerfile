# Используем официальный образ Nginx
FROM nginx:stable

# Устанавливаем дополнительные пакеты
RUN apt-get update && apt-get install -y \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Создаем директорию для кэша
RUN mkdir -p /tmp/nginx_cache && \
    chmod 755 /tmp/nginx_cache

# Копируем конфигурацию
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

# Открываем порты
EXPOSE 80 443

# Запускаем Nginx
CMD ["nginx", "-g", "daemon off;"]
