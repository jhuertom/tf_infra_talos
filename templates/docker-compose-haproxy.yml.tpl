services:
  haproxy:
    image: haproxy:2.8-alpine
    container_name: haproxy
    ports:
      - "80:80"
      - "443:443"
      - "8404:8404"  # Stats page
    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
      - ./certs:/etc/ssl/certs/
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg", "-c"]
      interval: 30s
      timeout: 10s
      retries: 3
  dns-cloudflare:
    volumes:
      - /etc/letsencrypt/cloudflare.ini:/etc/letsencrypt/cloudflare.ini:ro
      - /etc/letsencrypt:/etc/letsencrypt
    image: certbot/dns-cloudflare:latest
    command: certonly --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini --dns-cloudflare-propagation-seconds 60 -d '*.${domain}' -d '${domain}' --agree-tos --email ${cloudflare_email} --non-interactive --force-renewal