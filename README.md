# Magento install script for Ubuntu

This is developer tool intended for users wanting to quickly get up and running with separate instances of Magento Open Source running concurrently, potentially with varying PHP versions, on a single Linux machine via a LEMP (nginx) stack. It is designed to run on a fresh install of Ubuntu 20.04LTS but should work fine on Ubuntu derivatives. It is not designed for production usage.

### Prequisites

You will need to have access to your Magento authentication keys as this script installs Magento via Composer. These keys are easy to get hold of, are free for Magento Open Source, and instructions for acquiring them can be found on [this page](https://devdocs.magento.com/guides/v2.4/install-gde/prereq/connect-auth.html).

### Quick install: Don't run this unless you know what you're doing and have read and understood the [source code](https://raw.githubusercontent.com/tommypyatt/magento-install-ubuntu/main/install.sh):

```
wget https://raw.githubusercontent.com/tommypyatt/magento-install-ubuntu/main/install.sh && chmod +x ./install.sh && ./install.sh
```

Reboot machine after completion.

After reboot, visit magento.test in your preferred browser for a working frontend, and magento.test/admin for a backend. Username: `admin`, password `admin123`.

## Further detail of script actions

 - Install updates to Ubuntu
 - Add requisite third-party repositories for [PHP versions](https://launchpad.net/~ondrej/+archive/ubuntu/php) and [Elasticsearch 7](https://www.elastic.co/guide/en/elasticsearch/reference/7.16/deb.html).
 - Update local packages list and install Magento dependencies (nginx, curl, mariadb-server, elasticsearch, PHP, PHP extensions - bcmath, common, curl, fpm, gd, intl, mbstring, soap, xml, xsl, zip, cli, xml, dev, xdebug)
 - Add an nginx config for test site (magento.test)
 - Enable the nginx config by symlinking it into `sites-available`
 - Add upstream FastCGI backend to `conf.d` for PHP7.4
 - Add a hosts file entry to access magento.test in a local browser
 - Increase memory heap size allocated to Elasticsearch to 256MB
 - Start elasticsearch and enable start on boot via `systemctl`
 - Create a mysql database user for Magento and create database for test site
 - Add current user to `www-data` group and vice-versa
 - Add utilities for Magento CLI usage (Composer and Magerun2)
 - Download Magento via Composer
 - Update fastcgi_backend references in `nginx.conf.sample` to use backend for PHP7.4 created earlier
 - Install Magento
 - Set deploy mode to developer
 - Disable two factor auth for local admin panel access
 
 ## Interactivity
 
 The script runs mostly uninteractive but you will be prompted, probably once, for your user password for sudo access and another time for your [Magento authentication keys](https://devdocs.magento.com/guides/v2.4/install-gde/prereq/connect-auth.html).
 
 ## Further notes
 
 PHP7.4 is installed initially. Other versions of PHP can be installed from the PPA that is added to the system. To install PHP7.3, for example, along with the plugins upon which Magento depends, go for it:
 
 `sudo apt install php7.4-{bcmath,common,curl,fpm,gd,intl,mbstring,mysql,soap,xml,xsl,zip,cli,xml,dev,xdebug}`
 
 You'll just need to now add a respective fastcgi backend configuration and modify your project's `nginx.conf.sample` to suit. I would like to automate this but I need to first think of a good way to do that.
 
 At the time of writing, PHP7.4 is what I needed. I may (almost certainly will) update this to PHP8.1 in the future.
 
 `magento` and `magerun` scripts are included which can be run in a terminal. These are bash scripts that check for the appropriate PHP version in a `.php-version` file in the project root, from where the scripts are designed to be run.
 
 Further work is almost definitely required. For example I haven't yet added Elasticsearch phonetic and icu plugins, or enable `display_errors` in php-fpm config, so some manual effor will still be required depending on your project and usage requirements.
