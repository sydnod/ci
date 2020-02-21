ARG CI_COMMIT_SHA_SHORT='Undefined'

FROM php:7.2-apache
WORKDIR /var/www/html

ARG CI_COMMIT_SHA_SHORT
ENV CI_COMMIT_SHA_SHORT=$CI_COMMIT_SHA_SHORT

COPY index.php .
COPY static/ static/

# List all files
RUN find .