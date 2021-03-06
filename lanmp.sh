#!/bin/bash
#
# Web Server Install Script
# Created by wdlinux QQ:12571192
# Maintained by itxx00@gmail.com
# Url:http://www.wdlinux.cn
# Since 2010.04.08
#

. lib/common.conf
. lib/common.sh
. lib/basic_packages.sh
. lib/mysql.sh
. lib/apache.sh
. lib/nginx.sh
. lib/tengine.sh
. lib/php.sh
. lib/na.sh
. lib/libiconv.sh
. lib/eaccelerator.sh
. lib/zend.sh
. lib/pureftp.sh
. lib/pcre.sh
. lib/webconf.sh
. lib/service.sh
# make sure source files dir exists.
[ -d $IN_SRC ] || mkdir $IN_SRC
[ -d $LOGPATH ] || mkdir $LOGPATH

###
echo "Select Install
    1 apache + php + mysql + zend + eAccelerator + pureftpd + phpmyadmin
    2 nginx/tengine + php + mysql + zend + eAccelerator + pureftpd + phpmyadmin
    3 nginx/tengine + apache + php + mysql + zend + eAccelerator + pureftpd + phpmyadmin
    4 install all service
    5 don't install now
"
sleep 0.1
read -p "Please Input 1,2,3,4,5: " SERVER_ID
if [[ $SERVER_ID == 2 ]]; then
    SERVER="nginx"
elif [[ $SERVER_ID == 1 ]]; then
    SERVER="apache"
elif [[ $SERVER_ID == 3 ]]; then
    SERVER="na"
elif [[ $SERVER_ID == 4 ]]; then
    SERVER="all"
else
    exit
fi

if [ $SERVER != "apache" ]; then
    echo "Select nginx or tengine:
        1 nginx (default)
        2 tengine
    "
    sleep 0.1
    read -p "Please Input 1,2: " WEBSERV_ID
    if [[ $WEBSERV_ID == 2 ]]; then
        WEBSERV="tengine"
    else
        WEBSERV="nginx"
    fi
fi

echo "Select php version:
    1 php-5.2 (default)
    2 php-5.3
"
sleep 0.1
read -p "Please Input 1,2: " PHP_VER_ID
if [[ $PHP_VER_ID == 2 ]]; then
    PHP_VER=$PHP53_VER
else
    PHP_VER=$PHP52_VER
fi

# make sure network connection usable.
ping -c 1 -t 1 www.wdlinux.cn >/dev/null 2>&1
if [[ $? == 2 ]]; then
    echo "nameserver 8.8.8.8
nameserver 202.96.128.68" > /etc/resolv.conf
    echo "dns err"
fi
ping -c 1 -t 1 www.wdlinux.cn >/dev/null 2>&1
if [[ $? == 2 ]]; then
    echo "dns err"
    exit
fi

# Get os version info
GetOSVersion

###
if is_debian_based; then
    service apache2 stop 2>/dev/null
    service mysql stop 2>/dev/null
    service pure-ftpd stop 2>/dev/null
    apt-get update
    apt-get remove -y apache2 apache2-utils apache2.2-common apache2.2-bin \
        apache2-mpm-prefork apache2-doc apache2-mpm-worker mysql-common \
        mysql-client mysql-server php5 php5-fpm pure-ftpd pure-ftpd-common \
        pure-ftpd-mysql 2>/dev/null
    apt-get -y autoremove
    [ -f /etc/mysql/my.cnf ] && mv /etc/mysql/my.cnf /etc/mysql/my.cnf.lanmpsave
else
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
fi
install_basic_packages

ntpdate tiger.sina.com.cn
hwclock -w

if [ ! -d $IN_DIR ]; then
    mkdir -p $IN_DIR/{etc,init.d,wdcp_bk/conf}
    mkdir -p /www/web
    if is_debian_based; then
        /etc/init.d/apparmor stop >/dev/null 2>&1
        update-rc.d -f apparmor remove >/dev/null 2>&1
        apt-get remove -y apparmor apparmor-utils >/dev/null 2>&1
        ogroup=$(awk -F':' '/x:1000:/ {print $1}' /etc/group)
        [ -n "$ogroup" ] && groupmod -g 1010 $ogroup >/dev/null 2>&1
        ouser=$(awk -F':' '/x:1000:/ {print $1}' /etc/passwd)
        [ -n "$ouser" ] && usermod -u 1010 -g 1010 $ouser >/dev/null 2>&1
        adduser --system --group --home /nonexistent --no-create-home mysql >/dev/null 2>&1
    else
        setenforce 0
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        service httpd stop >/dev/null 2>&1
        service mysqld stop >/dev/null 2>&1
        chkconfig --level 35 httpd off >/dev/null 2>&1
        chkconfig --level 35 mysqld off >/dev/null 2>&1
        chkconfig --level 35 sendmail off >/dev/null 2>&1
        groupadd -g 27 mysql >/dev/null 2>&1
        useradd -g 27 -u 27 -d /dev/null -s /sbin/nologin mysql >/dev/null 2>&1
    fi
    groupadd -g 1000 www >/dev/null 2>&1
    useradd -g 1000 -u 1000 -d /dev/null -s /sbin/nologin www >/dev/null 2>&1
fi

cd $IN_SRC

[ $IN_DIR = "/www/wdlinux" ] || IN_DIR_ME=1

if [ $SERVER == "apache" ]; then
    wget_down $HTTPD_DU
elif [ $SERVER == "nginx" ]; then
    wget_down $PHP_FPM $PCRE_DU
    if [ $WEBSERV == "tengine" ]; then
        wget_down $TENGINE_DU
    else
        wget_down $NGINX_DU
    fi
fi
if [[ $os_ARCH = x86_64 ]]; then
    wget_down $ZENDX86_DU
else
    wget_down $ZEND_DU
fi
wget_down $MYSQL_DU $PHP_DU $EACCELERATOR_DU $PUREFTP_DU $PHPMYADMIN_DU

function in_all {
    na_ins
    SERVER="nginx"; php_ins
    SERVER="nginx"; eaccelerator_ins
    SERVER="nginx"; zend_ins
    SERVER="apache"; php_ins
    SERVER="apache"; eaccelerator_ins
    SERVER="apache"; zend_ins
}

if [ $SOFT_DOWN == 1 ]; then
    cd $IN_PWD
    if [ -f lanmp.tar.gz ]; then
        tar zxvf lanmp.tar.gz 
    else
        wget -c http://dl.wdlinux.cn:5180/lanmp.tar.gz
        tar zxvf lanmp.tar.gz
    fi
fi

mysql_ins
if [ $SERVER == "all" ]; then
    in_all
else
    if [ $SERVER = "nginx" ]; then
        ${WEBSERV}_ins
    else
        ${SERVER}_ins
    fi
    php_ins 
    eaccelerator_ins
    zend_ins
fi
pureftpd_ins
start_srv
lanmp_in_finsh
