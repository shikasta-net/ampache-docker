FROM php:apache

MAINTAINER Kym Eden

# Add repositories and install tools necessary for other steps
RUN echo 'deb http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list \
 && echo 'deb-src http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list \
 && echo 'deb http://archive.ubuntu.com/ubuntu trusty main multiverse' >> /etc/apt/sources.list \
 && apt-get update && apt-get -y upgrade \
 && apt-get -y install wget gnupg git \
 && wget -O - https://download.videolan.org/pub/debian/videolan-apt.asc | apt-key add - \
 && apt-get update

# Install codec libraries and other dependencies
RUN apt-get install -y --allow-unauthenticated -q ffmpeg \
# Install dependencies for gd
    libgd3 libpng-dev libjpeg-dev libfreetype6-dev \
# Install php-mysql extension, and php-gd and php-gettext for image conversion on the fly
 && docker-php-ext-install pdo_mysql gettext gd

# Install composer for dependency management
RUN php -r "readfile('https://getcomposer.org/installer');" | php \
 && mv composer.phar /usr/local/bin/composer

# Set the environment, may override the default php image settings
ENV APACHE_DOCUMENT_ROOT /var/www
WORKDIR /var/www

# Setup apache with default ampache vhost
ADD 001-ampache.conf /etc/apache2/sites-available/
RUN rm -rf /etc/apache2/sites-enabled/* \
 && ln -s /etc/apache2/sites-available/001-ampache.conf /etc/apache2/sites-enabled/ \
 && a2enmod rewrite

# extraction / installation
ADD https://github.com/ampache/ampache/archive/3.8.6.tar.gz /opt/ampache.tar.gz
RUN rm -rf /var/www/* \
 && tar -C /var/www -xf /opt/ampache.tar.gz --strip=1 \
 && rm /opt/ampache.tar.gz \
 && cp rest/.htaccess.dist rest/.htaccess \
 && cp play/.htaccess.dist play/.htaccess \
 && cp channel/.htaccess.dist channel/.htaccess \
 && composer install --prefer-source --no-interaction \
 && chown -R www-data:www-data /var/www \
 && apt-get autoremove --purge -y wget gnupg git && apt-get clean

VOLUME [ "/media", "/var/www/config", "/var/www/themes" ]
EXPOSE 80

CMD ["apache2-foreground"]
