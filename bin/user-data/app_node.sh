#!/bin/bash
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb http://packages.elastic.co/logstash/2.2/debian stable main" | sudo tee -a /etc/apt/sources.list
curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -

apt-get update
apt-get -y upgrade

apt-get -y install python-software-properties debconf-utils default-jre
apt-get -y install logstash nodejs git python-pip nginx monit

cat <<EOF > /etc/logstash/conf.d/app.conf
input {
  file {
    path => [ "/var/log/*.log", "/var/log/messages", "/var/log/syslog" ]
    type => "syslog"
  }
}
 
output {
  elasticsearch { host => https://$es_url}
  stdout { codec => rubydebug }
}
EOF

cat <<EOF > /etc/nginx/sites-available/default
upstream app_yourdomain {
    server 127.0.0.1:3000;
    keepalive 8;
}

server {
    listen 0.0.0.0:80;
    server_name app.opsflo.com;
    access_log /var/log/nginx/app.log;

    # pass the request to the node.js server with the correct headers
    # and much more can be added, see nginx config options
    location / {
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_set_header X-NginX-Proxy true;

      proxy_pass http://app_yourdomain/;
      proxy_redirect off;
    }
 }
EOF

service nginx restart

dir=/opt/data/app
rm -rf $dir
mkdir -p $dir
cd $dir
echo "Get Latest Rev"
git clone https://github.com/jdobyns/sloth.git .
npm install -g forever initd-forever
cd /tmp
initd-forever -a /opt/data/app/sloth.js -n sloth -l /var/log/app.log -p /var/run/sloth.pid
mv -v /tmp/sloth /etc/init.d/sloth
chmod a+x /etc/init.d/sloth
cat <<EOF > /etc/monit/conf.d/sloth.monit 
check process nodejs with pidfile "/var/run/sloth.pid"
        start program = "/etc/init.d/sloth start"
   stop program = "/etc/init.d/sloth stop"
    if failed port 3000 protocol HTTP
        request /
        with timeout 10 seconds
        then restart
EOF

service monit reload