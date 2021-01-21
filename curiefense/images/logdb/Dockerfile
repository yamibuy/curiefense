FROM postgres:alpine
COPY postgres/init/0_create_user.sh /docker-entrypoint-initdb.d/
COPY postgres/init/1_init.sql /docker-entrypoint-initdb.d/
EXPOSE 5432
