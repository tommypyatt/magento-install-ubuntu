#!/bin/bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl vim

# Add third party package repos
sudo add-apt-repository -y ppa:ondrej/php
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update
sudo apt install -y elasticsearch

# Install applications
sudo apt install -y nginx curl mariadb-server php8.1-{bcmath,common,curl,fpm,gd,intl,mbstring,mysql,soap,xml,xsl,zip,cli,xml,dev,xdebug}

# Clean up
sudo apt autoremove -y

# Add an nginx config for magento.test
echo -e "server {\n\
    listen 80;\n\
    server_name magento.test;\n\
    set \$MAGE_ROOT /home/$USER/repos/magento;\n\
    include /home/$USER/repos/magento/nginx.conf;\n\
}" | sudo tee /etc/nginx/sites-available/magento.conf
sudo ln -s /etc/nginx/sites-available/magento.conf /etc/nginx/sites-enabled/magento.conf

# Add upstream fastcgi backend for PHP 8.1
echo -e "upstream fastcgi_backend81 {\n\
    server   unix:/var/run/php/php8.1-fpm.sock;\n\
}" | sudo tee /etc/nginx/conf.d/fastcgi_php81.conf

# Add a hosts file entry
echo -e "127.0.1.1       magento.test" | sudo tee -a /etc/hosts

# Assign a big enough heap size to elasticsearch for Magento
echo -e "-Xms256m\n-Xmx256m" | sudo tee /etc/elasticsearch/jvm.options.d/heap.options

# Start elasticsearch and enable start on boot
sudo service elasticsearch start
sudo systemctl enable elasticsearch.service

# Create a DB user and database
sudo mysql -e "create user 'magento'@'localhost' identified by 'magento'"
sudo mysql -e "grant all privileges on *.* to 'magento'@'localhost'"
mysql -umagento -pmagento -e "create database magento"

# Set up groups for permissions
sudo usermod -a -G www-data $USER
sudo usermod -a -G $USER www-data

# Add Magento utilities for CLI usage
cd
mkdir bin
cd bin
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php -r "unlink('composer-setup.php');"
wget https://files.magerun.net/n98-magerun2.phar
wget https://raw.githubusercontent.com/tommypyatt/magento-install-ubuntu/main/bin/magento
wget https://raw.githubusercontent.com/tommypyatt/magento-install-ubuntu/main/bin/magerun
chmod +x ./magento ./magerun

# Download Magento
cd
mkdir repos
cd repos
/bin/php8.1 ~/bin/composer.phar create-project --repository-url=https://repo.magento.com/ magento/project-community-edition magento
cd magento
chmod -R g+w var/ pub/ generated/
cp nginx.conf.sample nginx.conf
sed -i "s/fastcgi_backend/fastcgi_backend81/g" ./nginx.conf
echo '/bin/php8.1' > .php-version

# Install Magento
/bin/php8.1 bin/magento setup:install --base-url=http://magento.test --db-host=localhost --db-name=magento --db-user=magento --db-password=magento --admin-firstname=admin --admin-lastname=admin --admin-email=admin@admin.com --admin-user=admin --admin-password=admin123 --language=en_GB --currency=GBP --timezone=Europe/London --use-rewrites=1 --search-engine=elasticsearch7 --elasticsearch-host=localhost --elasticsearch-port=9200 --elasticsearch-index-prefix=magento2 --elasticsearch-timeout=15 --backend-frontname=admin
/bin/php8.1 bin/magento deploy:mode:set developer
/bin/php8.1 bin/magento module:disable Magento_TwoFactorAuth
