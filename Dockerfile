FROM debian:jessie
MAINTAINER Bruce Chu
RUN rm /etc/apt/sources.list
RUN echo 'deb http://mirrors.aliyun.com/debian/ jessie main non-free contrib\n\
deb http://mirrors.aliyun.com/debian/ jessie-proposed-updates main non-free contrib\n\
deb-src http://mirrors.aliyun.com/debian/ jessie main non-free contrib\n\
deb-src http://mirrors.aliyun.com/debian/ jessie-proposed-updates main non-free contrib\n'\
>> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y wget curl git zip unzip
RUN wget https://www.dotdeb.org/dotdeb.gpg
RUN apt-key add dotdeb.gpg
RUN rm /etc/apt/sources.list
RUN echo 'deb http://mirrors.aliyun.com/debian/ jessie main non-free contrib\n\
deb http://mirrors.aliyun.com/debian/ jessie-proposed-updates main non-free contrib\n\
deb-src http://mirrors.aliyun.com/debian/ jessie main non-free contrib\n\
deb-src http://mirrors.aliyun.com/debian/ jessie-proposed-updates main non-free contrib\n\
deb http://mirror.xtom.com.hk/dotdeb/ jessie all\n\
deb-src http://mirror.xtom.com.hk/dotdeb/ jessie all\n'\
>> /etc/apt/sources.list
RUN apt-get update
RUN cat /etc/apt/sources.list
RUN apt-get install -y apt-transport-https lsb-release ca-certificates
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
RUN apt-get update

#安装nginx、php及php扩展
RUN apt-get install -y vim nginx php7.1-fpm php7.1-curl php7.1-bcmath php7.1-mbstring php7.1-redis php7.1-mysql php7.1-cli php7.1-dom php7.1-xml php7.1-gd php7.1-mongodb imagemagick php7.1-imagick
RUN rm /etc/nginx/sites-enabled/default
RUN echo 'server {\n\
        listen 80 default_server;\n\
        listen [::]:80 default_server;\n\
        root /var/www/html/lumen/public;\n\
        index index.php index.html index.htm index.nginx-debian.html;\n\
        server_name _;\n\
        location / {\n\
            try_files $uri $uri/ /index.php?$query_string;\n\
        }\n\
        location ~ \.php$ {\n\
                include snippets/fastcgi-php.conf;\n\
                fastcgi_pass unix:/run/php/php7.1-fpm.sock;\n\
        }\n\
}\n'\
>> /etc/nginx/sites-enabled/default
#安装mysql
#RUN apt-get install -y mysql-server
#RUN service mysql start
RUN apt-get update
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5
#ENV MYSQL_MAJOR 5.6
ENV MYSQL_VERSION 5.7

RUN echo "deb http://repo.mysql.com/apt/debian/ jessie mysql-${MYSQL_VERSION}" > /etc/apt/sources.list.d/mysql.list
RUN { \
        echo mysql-community-server mysql-community-server/data-dir select ''; \
        echo mysql-community-server mysql-community-server/root-pass password ''; \
        echo mysql-community-server mysql-community-server/re-root-pass password ''; \
        echo mysql-community-server mysql-community-server/remove-test-db select false; \
    } | debconf-set-selections \
    && apt-get update && apt-get install -y mysql-community-server && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
    && chmod 777 /var/run/mysqld
RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf \
    && echo 'skip-host-cache\nskip-name-resolve' | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/my.cnf > /tmp/my.cnf \
    && mv /tmp/my.cnf /etc/mysql/my.cnf


#安装并启动redis
RUN apt-get update && apt-get install -y redis-server
RUN redis-server /etc/redis/redis.conf

#安装composer
#RUN curl -sS https://getcomposer.org/installer | php
#RUN mv composer.phar /usr/local/bin/composer
ADD composer.phar /usr/local/bin/composer
RUN chmod 755 /usr/local/bin/composer

#启动nmp
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh
CMD /start.sh && tail -f
#ENTRYPOINT ["~/debian/start.sh"]
#ENTRYPOINT ["/var/www/html/start.sh"]

#暴露端口
EXPOSE 3306
EXPOSE 80

