FROM amazonlinux:2

RUN yum install -y httpd-2.4.52-1.amzn2

COPY extra.conf /etc/httpd/conf.d

COPY html /var/www/html

EXPOSE 80

CMD ["/usr/sbin/httpd", "-DFOREGROUND"]
