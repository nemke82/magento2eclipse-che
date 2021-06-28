# magento2che
Magento 2 optimized setup for Eclipse Che platform -- Nginx, MySQL, PHP 7.4, PHP-FPM, and a lot more...

Watch full video how you can easily setup Magento 2 Dev environment right in your browser:
<VIDEO>

*How-to instructions:*
1) Follow https://github.com/nemke82/eclipse-che-vagrant-minikube instructions and install Eclipse Che on your local desktop or laptop computer 
2) Fork https://github.com/nemke82/magento2eclipse-che to your repo
3) The simplest way to load Magento 2 Che environment is to call this repository with following URL:
```
https://<your-che-host>/f?url=https://github.com/mygroup/myrepo
```

If you have installed Eclipse Che using my repository then address example should be:
https://che-eclipse-che.192.168.34.100.nip.io/f?url=https://github.com/nemke82/magento2eclipse-che

Eclipse Che will now launch a workspace container for you on your local computer, containing a full Linux system. It will also clone the GitHub repository branch based on the GitHub page you were coming from.

When instance loads navigate to the right sidebar area and click on "Start Supervisor" button:
![](eclipse-che-start-services.png)

Services/Tools installed:
- **Nginx**
- **PHP 7.4** based on ppa:ondrej/php repo (https://launchpad.net/~ondrej/+archive/ubuntu/php). To add additional PHP extensions, please update Dockerfile and create Docker image.
- **Python** (base version)
- **rsync**
- **mc** (Midnight commander)
- **MySQL** (Percona) 5.7 version (latest)
- **xDebug** (latest Magento 2 supported version 2.9.8). From menu area select "Start X-Debug" and wait for confirmation. Enables CLI and PHP together, then you can follow https://www.gitpod.io/docs/languages/php/#debugging-php-in-gitpod guidelines.
- **Blackfire**. Note: Please run **./blackfire-run.sh** to enter your Server/Client ID and Token's. Sometimes it requires extra PHP-FPM restart, so please run service php7.4-fpm restart if required.
- **Tideways**. Note: Please run **/usr/bin/tideways-daemon --address 0.0.0.0:9135 &** to initiate daemon. Please update .env-file located in repo with TIDEWAYS_APIKEY
- **Newrelic**. Note: Please run **newrelic-daemon -c /etc/newrelic/newrelic.cfg** to initiate daemon. Please update .gitpod.Dockerfile (https://github.com/nemke82/magento2gitpod/blob/master/.gitpod.Dockerfile) with license key. Requires Fresh M2 installation (run m2install.sh) or your store to finish process of validation. <BR>
- **Redis**. Service started by supervisord
- **NodeJS/NPM NVM Manager**. Note: run nvm ls-remote to list available versions, then nvm install to install specific version or latest. 
- **ElasticSearch 7.9.3**. Note: Separate Docker container running for this. type curl 127.0.0.1:9200 to check <BR>
  
  Some extensions like ElasticSuite (https://github.com/Smile-SA/elasticsuite/wiki/ServerConfig-5.x) requires two ElasticSearch plugins to be installed. You can install them with the following commands:<BR>
  
  $ES_HOME/bin/elasticsearch-plugin install analysis-phonetic <BR>
  $ES_HOME/bin/elasticsearch-plugin install analysis-icu <BR>
  
- **MFTF (Magento 2 Multi Functional Testing Framework)** 
Follow https://github.com/magento/magento2-functional-testing-framework/blob/develop/docs/getting-started.md guidelines.
Installer is here: **chmod a+rwx m2-install-solo.sh && bash m2-install-solo.sh**

Note: Please run following command to start Selenium and Chromedriver (as required):

java -Dwebdriver.chrome.driver=chromedriver -jar $HOME/selenium-server-standalone-3.141.59.jar & <BR>
$HOME/chromedriver & <BR>

Every listed service installation code is added within .gitpod.Dockerfile
You can split them into separate workspaces and share it among themself if you know what you are doing.

- **RabbitMQ support**
default username/password: guest/guest <BR>
For browser open 15762 browser (already exposed) <BR>
Rest commands can be used as per RabbitMQ guidelines https://www.rabbitmq.com/cli.html

TO INSTALL Magento 2.4.2 (latest): <BR>
**Navigate to the right sidebar and click on Install Magento 2 latest (composer)**

For Magento 2.4-dev branch replicated from https://github.com/magento/magento2 please run: <BR>
**Navigate to the right sidebar and click on Install Magento 2 latest (github way)**

MySQL (default settings):
username: root <BR>
password: nem4540 <BR>

In case you need to create additional database: <BR>
mysql -e 'create database nemanja;' <BR>
(where "nemanja" is database name used) <BR>

If you are moving your own installation don't foget to adjust following cookie paths: <BR>
**web/cookie/path to "/"**
**web/cookie/domain to ".192.168.34.100.nip.io"**
  
**Changelog 2021-06-28:**
- Initial release. Good luck!
