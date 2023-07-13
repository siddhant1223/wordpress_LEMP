#!/bin/bash

# Check if Docker is installed
if ! which docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker $USER
    newgrp docker
    echo "Docker installed successfully."
else
    echo "Docker is already installed."
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully."
else
    echo "Docker Compose is already installed."
fi

# Command-line argument for the site name
site_name=$1

if [[ -z $site_name ]]; then
    echo "Please provide a site name as a command-line argument."
    exit 1
fi

# Create /etc/hosts entry
sudo sh -c "echo '127.0.0.1\t$site_name' >> /etc/hosts"

mkdir -p {nginx,db-data}
# Create nginx.conf

cat <<EOF > nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;

events {
  worker_connections 1024;
}

http {
  server {
    listen 80;
    server_name example.com;

    root /var/www/html;
    index index.php;

    location / {
      try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
      fastcgi_pass php:9000;
      fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
      include fastcgi_params;
      fastcgi_param SERVER_NAME \$host;
    }
  }
}

EOF


cat <<EOF > nginx/site.conf 
server {
  listen 80;
  server_name $site_name;

  location / {
    proxy_pass http://wordpress:80;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location /phpmyadmin {
    proxy_pass http://phpmyadmin:80;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}

EOF



# Create docker-compose.yml
cat <<EOF > docker-compose.yml
version: '3'

services:
  php:
    image: php:8.0-fpm
    volumes:
      - ./wordpress:/var/www/html
    networks:
      - lemp-network
  
  nginx:
    image: nginx:latest
    ports:
      - 80:80
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/site.conf:/etc/nginx/conf.d/site.conf
      - ./wordpress:/var/www/html
    depends_on:
      - php
    networks:
      - lemp-network 
  
  mysql:
    image: mysql:latest
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress_password
    volumes:
      - ./mysql:/var/lib/mysql
    networks:
      - lemp-network

  wordpress:
    image: wordpress:latest
    volumes:
      - ./wordpress:/var/www/html
    environment:
      WORDPRESS_DB_HOST: mysql
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress_password
    depends_on:
      - mysql
    networks:
      - lemp-network

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    ports:
      - 8080:80
    environment:
      PMA_HOST: mysql
      MYSQL_ROOT_PASSWORD: root_password
    depends_on:
      - mysql
    networks:
      - lemp-network

networks:
  lemp-network:
    driver: bridge
EOF

# Enable/disable the site (stopping/starting the containers)
function en_dis_site() {
    if [[ "$1" == "start" ]]; then
        docker-compose -f docker-compose.yml up -d
        echo "Site '$site_name' started."
    elif [[ "$1" == "stop" ]]; then
        docker-compose down
        echo "Site '$site_name' stopped."
    else
        echo "Invalid command. Please specify either 'start' or 'stop'."
    fi
}

# Delete the site (deleting containers and local files)
function delete_site() {
    docker-compose down -v
    sudo sed -i "/$site_name/d" /etc/hosts
    echo "Site '$site_name' deleted."
}

# Prompt the user to open the site in a browser
function open_site() {
    if [[ "$(docker-compose ps -q wordpress)" ]]; then
        echo "Site is up and healthy. Opening '$site_name' in a browser..."
        xdg-open "http://$site_name"
    else
        echo "Site is not running."
    fi
}

# Subcommands
case $2 in
    "start")
        en_dis_site "start"
        ;;
    "stop")
        en_dis_site "stop"
        ;;
    "delete")
        delete_site
        ;;
    "open")
        open_site
        ;;
    *)
        echo "Invalid subcommand. Please specify either 'start', 'stop', 'delete', or 'open'."
        ;;
esac

