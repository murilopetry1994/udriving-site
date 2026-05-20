# udriving-site — Instruções para Claude

## Infraestrutura

- **Servidor:** Hostinger VPS (gerenciador Docker da Hostinger)
- **Compose de produção:** `docker-compose.prod.yml`
- **Branch de produção:** `master`
- **Deploy:** push no `master` → Hostinger detecta e redeploy automático (ou manual via painel)

## Arquitetura Docker

O servidor já tem **Traefik** rodando na rede `host`, gerenciado pela Hostinger.
O Traefik ocupa as portas 80 e 443 e gerencia certificados SSL via Let's Encrypt.

**Regra absoluta:** o nginx NUNCA deve tentar bindar as portas 80 ou 443 diretamente.

### Como o roteamento funciona

```
Internet → Traefik (porta 80/443) → nginx interno (porta 80) → html/
```

- Nginx serve apenas HTTP internamente (sem SSL, sem certbot)
- Traefik cuida de HTTPS, redirect HTTP→HTTPS e renovação de certificado
- A config do nginx usada em produção é `nginx/nginx.conf` (simples, sem SSL)

### docker-compose.prod.yml — padrão correto

```yaml
services:
  nginx:
    image: nginx:alpine
    volumes:
      - ./html:/usr/share/nginx/html:ro
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.udriving.rule=Host(`udriving.com.br`) || Host(`www.udriving.com.br`)"
      - "traefik.http.routers.udriving.entrypoints=websecure"
      - "traefik.http.routers.udriving.tls=true"
      - "traefik.http.routers.udriving.tls.certresolver=letsencrypt"
      - "traefik.http.services.udriving.loadbalancer.server.port=80"
    restart: unless-stopped
```

## Fluxo de deploy

1. Fazer alterações localmente
2. `git add` + `git commit` + `git push origin master`
3. No servidor: `git pull origin master && docker compose -f docker-compose.prod.yml up -d`
   - Ou acionar redeploy pelo painel da Hostinger

## Erros comuns e causas

| Erro | Causa | Solução |
|---|---|---|
| `address already in use :80` | nginx tentando bindar porta 80, que pertence ao Traefik | Remover `ports:` do compose, usar labels |
| `cannot load certificate fullchain.pem` | `nginx.prod.conf` com SSL — o nginx não deve gerenciar SSL | Usar `nginx.conf` (HTTP only) |
| Container com config antiga após push | Servidor não fez `git pull` | Rodar `git pull` antes do `docker compose up` |

## Outros serviços no servidor (não mexer)

- `traefik-vtma-traefik-1` — Traefik (rede host)
- `evolution-api-kwbf-api-1` — Evolution API
- `n8n-f8go-n8n-1` — n8n
- `evolution-api-kwbf-postgres-1` — PostgreSQL
- `evolution-api-kwbf-redis-1` — Redis
