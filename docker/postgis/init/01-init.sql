-- Создаем расширения
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS postgis_raster;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;

-- Создаем схемы для организации данных
CREATE SCHEMA IF NOT EXISTS vector;
COMMENT ON SCHEMA vector IS 'Схема для хранения векторных данных (скважины, реперы, границы и т.д.)';

CREATE SCHEMA IF NOT EXISTS raster;
COMMENT ON SCHEMA raster IS 'Схема для хранения метаданных растровых данных';

-- Создаем таблицу для хранения информации о растрах
CREATE TABLE IF NOT EXISTS raster.raster_catalog (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    filepath VARCHAR(512) NOT NULL,
    file_size BIGINT,
    creation_date TIMESTAMP WITH TIME ZONE,
    modification_date TIMESTAMP WITH TIME ZONE,
    raster_date DATE, -- дата создания растра (например, дата аэрофотосъемки)
    resolution NUMERIC, -- пространственное разрешение в метрах
    bounds geometry(POLYGON, 4326), -- границы растра
    type VARCHAR(50), -- тип растра (ортофото, спутник, и т.д.)
    format VARCHAR(50), -- формат файла (ECW, GeoTIFF и т.д.)
    status VARCHAR(50) DEFAULT 'active',
    metadata JSONB -- дополнительные метаданные в JSON формате
);

-- Создаем индекс для поиска растров по расположению
CREATE INDEX IF NOT EXISTS idx_raster_catalog_bounds ON raster.raster_catalog USING GIST(bounds);

-- Создаем таблицу для хранения информации о проектах
CREATE TABLE IF NOT EXISTS public.projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'active',
    boundary geometry(POLYGON, 4326)
);

-- Создаем индекс для геометрии проектов
CREATE INDEX IF NOT EXISTS idx_projects_boundary ON public.projects USING GIST(boundary);

-- Устанавливаем права доступа
GRANT ALL ON ALL TABLES IN SCHEMA public TO current_user;
GRANT ALL ON ALL TABLES IN SCHEMA vector TO current_user;
GRANT ALL ON ALL TABLES IN SCHEMA raster TO current_user;

-- Создаем базовые таблицы для хранения метаданных
CREATE TABLE IF NOT EXISTS public.spatial_ref_sys (
    srid integer PRIMARY KEY,
    auth_name varchar(256),
    auth_srid integer,
    srtext varchar(2048),
    proj4text varchar(2048)
); 