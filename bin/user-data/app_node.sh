#!/bin/bash
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb http://packages.elastic.co/logstash/2.2/debian stable main" | sudo tee -a /etc/apt/sources.list
curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -

apt-get update
apt-get -y upgrade

apt-get -y install python-software-properties debconf-utils default-jre
apt-get -y install logstash nodejs git python-pip nginx monit

es_endpoint=`aws es describe-elasticsearch-domain --domain-name $1 | jq .DomainStatus.Endpoint`

cat <<EOF > /etc/logstash/conf.d/app.conf
input {
  file {
    path => [ "/var/log/*.log", "/var/log/messages", "/var/log/syslog" ]
    type => "syslog"
  }
}
 
output {
  elasticsearch { host => https://$es_endpoint}
  stdout { codec => rubydebug }
}
EOF

cat <<'EOF' > /etc/nginx/sites-available/default
server {
  listen       80;
  server_name  app.opsflo.com;

  location / {
    proxy_pass http://localhost:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
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