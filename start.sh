redis-server /etc/redis/redis.conf
service nginx start
service php7.1-fpm start 
service mysql start
#ln -s  /var/www/html/lumen/storage/app/public/ /var/www/html/lumen/public/storage
