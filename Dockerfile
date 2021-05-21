FROM quay.io/centos7/s2i-base-centos7

# This image provides an Apache+PHP environment for running PHP
# applications.

LABEL maintainer="Florian Froehlich (florian.froehlich@sws.de)"

EXPOSE 8080

ENV PHP_VERSION=5.5 \
    PATH=$PATH:/opt/remi/php55/root/usr/bin

LABEL io.k8s.description="Platform for running PHP 5.5 applications" \
      io.k8s.display-name="Apache 2.4 with PHP 5.5" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="php,php55"

# Install Apache httpd and PHP
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
RUN yum install -y yum-utils
RUN yum-config-manager --enable remi-php55
RUN yum install -y centos-release-scl && \
    INSTALL_PKGS="httpd24 nano php55 php56-php-common php55-php php55-php-mysqlnd php55-php-pgsql php55-php-bcmath php55-php-devel \
                  php55-php-fpm php55-php-gd php55-php-intl php55-php-ldap php55-php-mbstring php55-php-pdo \
                  php55-php-pecl-memcache php55-php-process php55-php-soap php55-php-opcache php55-php-xml \
                  php55-php-gmp" && \
    yum install -y --setopt=tsflags=nodocs --enablerepo=centosplus $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum -y clean all --enablerepo='*'

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Copy extra files to the image.
COPY ./root/ /

# In order to drop the root user, we have to make some directories world
# writeable as OpenShift default security model is to run the container under
# random UID.
RUN sed -i -f /opt/app-root/etc/httpdconf.sed /opt/rh/httpd24/root/etc/httpd/conf/httpd.conf 
RUN    sed -i '/php_value session.save_path/d' /opt/remi/php55/root/etc/php-fpm.d/www.conf 
RUN    echo "IncludeOptional /opt/app-root/etc/conf.d/*.conf" >> /opt/rh/httpd24/root/etc/httpd/conf/httpd.conf 
RUN    head -n151 /opt/rh/httpd24/root/etc/httpd/conf/httpd.conf | tail -n1 | grep "AllowOverride All" || exit 
RUN    mkdir /tmp/sessions 
RUN    chown -R 1001:0 /opt/app-root /tmp/sessions 
RUN    chmod -R a+rwx /tmp/sessions 
RUN    chmod -R ug+rwx /opt/app-root 
RUN    chmod -R a+rwx /opt/remi/php55/root/etc 
RUN    chmod -R a+rwx /opt/rh/httpd24/root/var/run/httpd

USER 1001

# Set the default CMD
CMD $STI_SCRIPTS_PATH/run
