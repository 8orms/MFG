FROM postgis/postgis:15-3.3

# Set environment variables
ENV POSTGRES_DB=gis
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV LANG=en_US.utf8
ENV LC_ALL=en_US.utf8

# Copy initialization scripts
COPY ./postgis/init /docker-entrypoint-initdb.d/

# Expose the PostgreSQL port
EXPOSE 5432

# Add labels
LABEL maintainer="Your Name <your.email@example.com>"
LABEL version="1.0"
LABEL description="PostGIS container for GIS applications" 