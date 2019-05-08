#!/bin/bash
yum install java-1.8.0-openjdk 

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cp logstash.repo /etc/yum.repos.d/
sudo yum install logstash

#rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cp elasticsearch.repo /etc/yum.repos.d/
sudo yum install elasticsearch -y

sudo fallocate -l 1G /swapfile
sudo dd if=/dev/zero of=/swapfile bs=1024 count=1048576
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

sudo systemctl start elasticsearch.service
sudo systemctl enable elasticsearch.service

#rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cp kibana.repo /etc/yum.repos.d/
sudo yum install kibana -y

sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable kibana.service

nano /etc/kibana/kibana.yml

server.port: 5601
#server.host: "localhost" server.host: "0.0.0.0"

sudo systemctl start kibana.service