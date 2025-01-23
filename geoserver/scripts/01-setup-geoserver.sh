#!/bin/bash

# Ожидание запуска Tomcat
sleep 10

# Настройка CORS
sed -i 's/<filter-mapping>/<filter-mapping>\n    <filter-name>CorsFilter<\/filter-name>\n    <url-pattern>\/*<\/url-pattern>\n  <\/filter-mapping>\n  <filter>\n    <filter-name>CorsFilter<\/filter-name>\n    <filter-class>org.apache.catalina.filters.CorsFilter<\/filter-class>\n    <init-param>\n      <param-name>cors.allowed.origins<\/param-name>\n      <param-value>*<\/param-value>\n    <\/init-param>\n  <\/filter>/g' /usr/local/tomcat/webapps/geoserver/WEB-INF/web.xml

# Настройка GDAL_DATA
export GDAL_DATA=/usr/share/gdal

# Создание необходимых директорий
mkdir -p ${GEOSERVER_DATA_DIR}/workspaces
mkdir -p ${GEOSERVER_DATA_DIR}/data
mkdir -p ${GEOSERVER_DATA_DIR}/logs

# Установка прав доступа
chown -R root:root ${GEOSERVER_DATA_DIR}
chmod -R 755 ${GEOSERVER_DATA_DIR} 