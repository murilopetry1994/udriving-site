#!/bin/bash
set -e

echo "==> Parando containers existentes..."
docker compose -f docker-compose.prod.yml down 2>/dev/null || true
docker rm -f nginx-init 2>/dev/null || true

echo "==> Subindo nginx HTTP (para validação do certbot)..."
docker run -d --name nginx-init \
  -p 80:80 \
  -v "$(pwd)/html:/usr/share/nginx/html:ro" \
  -v "$(pwd)/nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro" \
  -v "$(pwd)/certbot/www:/var/www/certbot:ro" \
  nginx:alpine

sleep 2

echo "==> Gerando certificado SSL via Let's Encrypt..."
docker run --rm \
  -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
  -v "$(pwd)/certbot/www:/var/www/certbot" \
  certbot/certbot certonly --webroot --webroot-path=/var/www/certbot \
  --email mupetry1@gmail.com --agree-tos --no-eff-email \
  -d udriving.com.br -d www.udriving.com.br

echo "==> Parando nginx temporário..."
docker rm -f nginx-init

echo "==> Subindo stack completa com HTTPS..."
docker compose -f docker-compose.prod.yml up -d

echo "==> Pronto! Acesse https://udriving.com.br"
