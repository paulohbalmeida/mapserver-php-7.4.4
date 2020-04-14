FROM php:7.4.4-apache

ENV MAPSERVER_VERSION 7.4.4
ENV DEPENDENCIAS  \
    memcached \
    iputils-ping \
    wget \
    libfreetype6-dev \
    libproj-dev \
    libfribidi-dev \
    libharfbuzz-dev \
    libcairo-dev \
    libgdal-dev \
    cmake \ 
    libapache2-mod-xsendfile \
    protobuf-c-compiler \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    zlib1g-dev \
    libxml2-dev \
    libzip-dev \
    libonig-dev \
    unixodbc-dev \
    graphviz \
    swig \
    gdal-bin
ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/
RUN chmod uga+x /usr/local/bin/install-php-extensions && sync && \
    apt-get update && \
    export LANG=C.UTF-8 && \
    apt-get install --no-install-recommends -y build-essential && \
    apt-get install --no-install-recommends -y software-properties-common && \
    apt-get update && \
    apt-get install -y libpq-dev libxslt1-dev && \
    apt-get install --no-install-recommends -y ${DEPENDENCIAS} && \
    pecl install mcrypt-1.0.3 && \
    cd /opt && \
    wget http://download.osgeo.org/mapserver/mapserver-${MAPSERVER_VERSION}.tar.gz && \
    tar xvf mapserver-${MAPSERVER_VERSION}.tar.gz && \
    rm -f mapserver-${MAPSERVER_VERSION}.tar.gz && \
    cd mapserver-${MAPSERVER_VERSION}/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_CXX_FLAGS="-std=c++11 --coverage" \
        -DCMAKE_INSTALL_PREFIX=/opt \
        -DWITH_CLIENT_WFS=ON \
        -DWITH_CLIENT_WMS=ON \
        -DWITH_CURL=ON \
        -DWITH_SOS=OFF \
        -DWITH_PHP=ON \
        -DWITH_FCGI=OFF \
        -DWITH_PYTHON=OFF \
        -DWITH_SVGCAIRO=OFF \
        -DWITH_GIF=OFF \
	-DWITH_PROTOBUFC=0 \
        ../ >../configure.out.txt && \
    make && \
    make install && \
    cd / && \
    docker-php-source extract && \
    pwd && \
    cd /usr/src/php/ext/odbc && \
    phpize && \
    sed -ri 's@^ *test +"\$PHP_.*" *= *"no" *&& *PHP_.*=yes *$@#&@g' configure && \
    ./configure --with-unixODBC=shared,/usr && \
    docker-php-ext-install odbc && \
#    docker-php-ext-configure memcached  && \
#    docker-php-ext-install memcache && \
    docker-php-ext-install mbstring && \
    docker-php-ext-enable mcrypt && \
    docker-php-ext-install gd && \
    docker-php-ext-install odbc && \
    docker-php-ext-install pgsql && \
    docker-php-ext-install pdo_pgsql && \
#    docker-php-ext-install pspell && \
    docker-php-ext-install xmlrpc && \
    docker-php-ext-configure xsl && \
#    docker-php-ext-enable imagick && \
#    docker-php-ext-install dev && \
    docker-php-ext-install zip && \
#    docker-php-source delete && \
    a2enmod rewrite && \
    a2enmod cgi && \
    a2enmod xsendfile && \
    cd /var/www && \
    touch /var/www/index.php && \
    ln -s /tmp/ms_tmp ms_tmp && \
    apt-get remove --purge -y wget cmake && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker/000-default.conf /etc/apache2/sites-available/
COPY ./docker/ports.conf /etc/apache2/
COPY ./docker/index.php /var/www/
EXPOSE 8080
