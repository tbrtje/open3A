FROM alpine:3.12
LABEL Maintainer="Pawel Kostelnik <pkostelnik@snat.tech>" \
      Description="Lightweight container with Nginx 1.18, PHP-FPM 7.3 and open3a 3.3 based on Alpine Linux."

# Install packages and remove default server definition
RUN apk --no-cache add php7 php7-fpm php7-opcache php7-mysqli php7-json php7-openssl php7-curl \
    php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-ctype php7-session \
    php7-mbstring php7-gd nginx supervisor curl aria2 unzip && \
    rm /etc/nginx/conf.d/default.conf

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/html

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/html
#COPY --chown=nobody src/ /var/www/html/

# Download the comporessed app
RUN aria2c "https://www.open3a.de/download/open3A 3.4.zip" -d /tmp -o open3A.zip \
# unzip the app into workfolder
    && unzip /tmp/open3A.zip -d /var/www/html \
# set proper accessrights and create nedded folder
    && chmod 777 /var/www/html/specifics \
    && chmod 777 /var/www/html/system/Backup \
    && mkdir /var/www/html/system/session \
    && chmod 777 /var/www/html/system/session \
    && chmod 777 /var/www/html/system/DBData/Installation.pfdb.php

# Expose the port nginx is reachable on
EXPOSE 80

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:80/fpm-ping
