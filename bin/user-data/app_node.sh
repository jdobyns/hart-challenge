#!/bin/bash
apt-get update
apt-get upgrade
apt-get install -y python-software-properties debconf-utils
add-apt-repository -y ppa:webupd8team/java
apt-get update
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
apt-get install -y oracle-java8-installer


curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -
echo 'deb http://packages.elastic.co/logstash/2.2/debian stable main' | sudo tee /etc/apt/sources.list.d/logstash-2.2.x.list

apt-get update
apt-get -y install oracle-java8-installer
apt-get -y install logstash nodejs git -y python-pip nginx monit

cat <<EOF > 
input {
  file {
    path => [ "/var/log/*.log", "/var/log/messages", "/var/log/syslog" ]
    type => "syslog"
  }
}
 
output {
  elasticsearch { host => https://search-hart-6-b5jvgvfpr7d23yz22l2klqnkli.us-east-1.es.amazonaws.com }
  stdout { codec => rubydebug }
}
EOF

cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;

    server_name example.com;

    location / {
        proxy_pass http://localhost:3080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

dir=/opt/data/app
rm -rf $dir
mkdir -p $dir
cd $dir
echo "Get Latest Rev"
git clone https://github.com/roosri/sloth.git .
npm install -g initd-forever
initd-forever -a /opt/data/app/sloth.js -n /etc/init.d/sloth -l /var/log/app.log -m /etc/nonit/conf.d/sloth
service monit reload