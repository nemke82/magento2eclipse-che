FROM ubuntu:20.04

USER root

ENV TZ=Europe/Belgrade
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt update
RUN apt install -y tzdata
RUN apt-get -y install lsb-release
RUN apt-get -y install apt-utils
RUN apt-get -y install python
RUN apt-get -y install rsync
RUN apt-get -y install curl
RUN apt-get -y install libnss3-dev
RUN apt-get -y install openssh-client
RUN apt-get -y install mc
RUN apt install -y software-properties-common
RUN apt-get -y install gcc make autoconf libc-dev pkg-config
RUN apt-get -y install libmcrypt-dev
RUN mkdir -p /tmp/pear/cache
RUN mkdir -p /etc/bash_completion.d/cargo
RUN mkdir -p /home/magento2che
RUN mkdir -p /var/run/nginx/
RUN mkdir -p /var/log/php-fpm
RUN apt install -y php-dev
RUN apt install -y php-pear
RUN apt-get -y install dialog
RUN apt-get -y install nginx
RUN apt-get -y install wget
RUN apt-get install -y sudo
RUN apt-get install -y nano

#Install php-fpm7.4
RUN apt-get update \
    && apt-get install -y curl zip unzip git software-properties-common supervisor sqlite3 \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y php7.4-fpm php7.4-common php7.4-cli php7.4-imagick php7.4-gd php7.4-mysql \
       php7.4-pgsql php7.4-imap php-memcached php7.4-mbstring php7.4-xml php7.4-xmlrpc php7.4-soap php7.4-zip php7.4-curl \
       php7.4-bcmath php7.4-sqlite3 php7.4-apcu php7.4-apcu-bc php7.4-intl php-dev php7.4-dev php7.4-xdebug php-redis \
    && php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --version=1.10.16 --filename=composer \
    && mkdir /run/php \
    && chown root:root /run/php \
    && chown -R root:root /etc/php \
    && apt-get remove -y --purge software-properties-common \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && update-alternatives --remove php /usr/bin/php8.0 \
    && update-alternatives --remove php /usr/bin/php7.3 \
    && update-alternatives --set php /usr/bin/php7.4 \
    && echo "daemon off;" >> /etc/nginx/nginx.conf

#Adjust few options for xDebug and disable it by default
RUN echo "xdebug.remote_enable=on" >> /etc/php/7.4/mods-available/xdebug.ini
    #&& echo "xdebug.remote_autostart=on" >> /etc/php/7.4/mods-available/xdebug.ini
    #&& echo "xdebug.profiler_enable=On" >> /etc/php/7.4/mods-available/xdebug.ini \
    #&& echo "xdebug.profiler_output_dir = /workspace/magento2pitpod" >> /etc/php/7.4/mods-available/xdebug.ini \
    #&& echo "xdebug.profiler_output_name = nemanja.log >> /etc/php/7.4/mods-available/xdebug.ini \
    #&& echo "xdebug.show_error_trace=On" >> /etc/php/7.4/mods-available/xdebug.ini \
    #&& echo "xdebug.show_exception_trace=On" >> /etc/php/7.4/mods-available/xdebug.ini
RUN mv /etc/php/7.4/cli/conf.d/20-xdebug.ini /etc/php/7.4/cli/conf.d/20-xdebug.ini-bak
RUN mv /etc/php/7.4/fpm/conf.d/20-xdebug.ini /etc/php/7.4/fpm/conf.d/20-xdebug.ini-bak

# Install MySQL
ENV PERCONA_MAJOR 5.7
RUN apt-get update \
 && apt-get -y install gnupg2 \
 && apt-get clean && rm -rf /var/cache/apt/* /var/lib/apt/lists/* /tmp/* \
 && mkdir /var/run/mysqld \
 && wget -c https://repo.percona.com/apt/percona-release_latest.stretch_all.deb \
 && dpkg -i percona-release_latest.stretch_all.deb \
 && apt-get update

RUN set -ex; \
	{ \
		for key in \
			percona-server-server/root_password \
			percona-server-server/root_password_again \
			"percona-server-server-$PERCONA_MAJOR/root-pass" \
			"percona-server-server-$PERCONA_MAJOR/re-root-pass" \
		; do \
			echo "percona-server-server-$PERCONA_MAJOR" "$key" password 'nem4540'; \
		done; \
	} | debconf-set-selections; \
	apt-get update; \
	apt-get install -y \
		percona-server-server-5.7 percona-server-client-5.7 percona-server-common-5.7 \
	;
	
RUN chown -R root:root /etc/mysql /var/run/mysqld /var/log/mysql /var/lib/mysql /var/lib/mysql-files /var/lib/mysql-keyring

# Install our own MySQL config
COPY mysql.cnf /etc/mysql/conf.d/mysqld.cnf
COPY .my.cnf /home/magento2che
COPY mysql.conf /etc/supervisor/conf.d/mysql.conf
RUN chown root:root /home/magento2che/.my.cnf

# Install default-login for MySQL clients
COPY client.cnf /etc/mysql/conf.d/client.cnf

USER root

#Copy nginx default and php-fpm.conf file
#COPY default /etc/nginx/sites-available/default
COPY php-fpm.conf /etc/php/7.4/fpm/php-fpm.conf
RUN chown -R root:root /etc/php

COPY nginx.conf /etc/nginx

#Selenium required for MFTF
RUN wget -c https://selenium-release.storage.googleapis.com/3.141/selenium-server-standalone-3.141.59.jar
RUN wget -c https://chromedriver.storage.googleapis.com/80.0.3987.16/chromedriver_linux64.zip
RUN unzip chromedriver_linux64.zip

USER root

# Install Chrome and Chromium
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && dpkg -i google-chrome-stable_current_amd64.deb; apt-get -fy install \
    && apt-get install -yq \
       gconf-service libasound2 libatk1.0-0 libatk-bridge2.0-0 libc6 libcairo2 libcups2 libdbus-1-3 \
       libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 \
       libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 \
       libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates \
       fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget

ENV BLACKFIRE_LOG_LEVEL 1
ENV BLACKFIRE_LOG_FILE /var/log/blackfire/blackfire.log
ENV BLACKFIRE_SOCKET unix:///tmp/agent.sock
ENV BLACKFIRE_SOURCEDIR /etc/blackfire
ENV BLACKFIRE_USER root

RUN curl -sS https://packagecloud.io/gpg.key | apt-key add \
    && curl -sS https://packages.blackfire.io/gpg.key | apt-key add \
    && echo "deb http://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list \
    && apt-get update \
    && apt-get install -y blackfire-agent \
    && apt-get install -y blackfire-php

RUN \
    version=$(php -r "echo PHP_MAJOR_VERSION, PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/${version} \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so

COPY blackfire-agent.ini /etc/blackfire/agent
COPY blackfire-php.ini /etc/php/7.3/fpm/conf.d/92-blackfire-config.ini
COPY blackfire-php.ini /etc/php/7.3/cli/conf.d/92-blackfire-config.ini

COPY blackfire-run.sh /blackfire-run.sh

ENTRYPOINT ["/bin/bash", "/blackfire-run.sh"]

#Install Tideways
RUN apt-get update
RUN echo 'deb http://s3-eu-west-1.amazonaws.com/tideways/packages debian main' > /etc/apt/sources.list.d/tideways.list && \
    curl -sS 'https://s3-eu-west-1.amazonaws.com/tideways/packages/EEB5E8F4.gpg' | apt-key add -
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -yq tideways-daemon && \
    apt-get autoremove --assume-yes && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
    
ENTRYPOINT ["tideways-daemon","--hostname=tideways-daemon","--address=0.0.0.0:9135"]

RUN echo 'deb http://s3-eu-west-1.amazonaws.com/tideways/packages debian main' > /etc/apt/sources.list.d/tideways.list && \
    curl -sS 'https://s3-eu-west-1.amazonaws.com/tideways/packages/EEB5E8F4.gpg' | apt-key add - && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq install tideways-php && \
    apt-get autoremove --assume-yes && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo 'extension=tideways.so\ntideways.connection=tcp://0.0.0.0:9135\ntideways.api_key=${TIDEWAYS_APIKEY}\n' > /etc/php/7.3/cli/conf.d/40-tideways.ini
RUN echo 'extension=tideways.so\ntideways.connection=tcp://0.0.0.0:9135\ntideways.api_key=${TIDEWAYS_APIKEY}\n' > /etc/php/7.3/fpm/conf.d/40-tideways.ini
RUN rm -f /etc/php/7.3/cli/20-tideways.ini

# Install Redis.
RUN apt-get update \
 && apt-get install -y \
  redis-server \
 && rm -rf /var/lib/apt/lists/*
 
 #n98-magerun2 tool.
 RUN wget https://files.magerun.net/n98-magerun2.phar \
     && chmod +x ./n98-magerun2.phar \
     && mv ./n98-magerun2.phar /usr/local/bin/n98-magerun2
     
#Install APCU
RUN echo "apc.enable_cli=1" > /etc/php/7.3/cli/conf.d/20-apcu.ini
RUN echo "priority=25" > /etc/php/7.3/cli/conf.d/25-apcu_bc.ini
RUN echo "extension=apcu.so" >> /etc/php/7.3/cli/conf.d/25-apcu_bc.ini
RUN echo "extension=apc.so" >> /etc/php/7.3/cli/conf.d/25-apcu_bc.ini

RUN chown -R root:root /var/log/blackfire
RUN chown -R root:root /etc/init.d/blackfire-agent
RUN mkdir -p /var/run/blackfire
RUN chown -R root:root /var/run/blackfire
RUN chown -R root:root /etc/blackfire
RUN chown -R root:root /etc/php
RUN chown -R root:root /etc/nginx
RUN chown -R root:root /etc/init.d/
RUN echo "net.core.somaxconn=65536" >> /etc/sysctl.conf

#New Relic
RUN \
  curl -L https://download.newrelic.com/php_agent/release/newrelic-php5-9.17.1.301-linux.tar.gz | tar -C /tmp -zx && \
  export NR_INSTALL_USE_CP_NOT_LN=1 && \
  export NR_INSTALL_SILENT=1 && \
  /tmp/newrelic-php5-*/newrelic-install install && \
  rm -rf /tmp/newrelic-php5-* /tmp/nrinstall* && \
  touch /etc/php/7.3/fpm/conf.d/newrelic.ini && \
  touch /etc/php/7.3/cli/conf.d/newrelic.ini && \
  sed -i \
      -e 's/"REPLACE_WITH_REAL_KEY"/"ba052d5cdafbbce81ed22048d8a004dd285aNRAL"/' \
      -e 's/newrelic.appname = "PHP Application"/newrelic.appname = "magento2che"/' \
      -e 's/;newrelic.daemon.app_connect_timeout =.*/newrelic.daemon.app_connect_timeout=15s/' \
      -e 's/;newrelic.daemon.start_timeout =.*/newrelic.daemon.start_timeout=5s/' \
      /etc/php/7.3/cli/conf.d/newrelic.ini && \
  sed -i \
      -e 's/"REPLACE_WITH_REAL_KEY"/"ba052d5cdafbbce81ed22048d8a004dd285aNRAL"/' \
      -e 's/newrelic.appname = "PHP Application"/newrelic.appname = "magento2che"/' \
      -e 's/;newrelic.daemon.app_connect_timeout =.*/newrelic.daemon.app_connect_timeout=15s/' \
      -e 's/;newrelic.daemon.start_timeout =.*/newrelic.daemon.start_timeout=5s/' \
      /etc/php/7.3/fpm/conf.d/newrelic.ini && \
  sed -i 's|/var/log/newrelic/|/tmp/|g' /etc/php/7.3/fpm/conf.d/newrelic.ini && \
  sed -i 's|/var/log/newrelic/|/tmp/|g' /etc/php/7.3/cli/conf.d/newrelic.ini
     
RUN chown -R root:root /etc/php
RUN chown -R root:root /etc/newrelic
COPY newrelic.cfg /etc/newrelic
RUN rm -f /usr/bin/php
RUN ln -s /usr/bin/php7.4 /usr/bin/php

#NVM support
RUN mkdir -p /usr/local/nvm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 0.10.33

# Install nvm with node and npm
RUN curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/v$NODE_VERSION/bin:$PATH
RUN chown -R root:root /usr/local/nvm

USER root

COPY lighthouse.conf /etc
RUN cat /etc/lighthouse.conf >> /home/magento2che/.bashrc

