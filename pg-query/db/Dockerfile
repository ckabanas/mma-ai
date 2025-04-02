# Use the official PostgreSQL image as base
FROM postgres:latest
# Set environment variables
ENV POSTGRES_USER=postgres
ENV POSTGRES_DB=rentalco
COPY ./all.sql /docker-entrypoint-initdb.d/
RUN chmod a+r /docker-entrypoint-initdb.d/*
