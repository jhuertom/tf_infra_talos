global
    log stdout local0
    daemon

defaults
    mode tcp
    log global
    option tcplog
    option dontlognull
    retries 3
    timeout connect 10s
    timeout client 1m
    timeout server 1m
    timeout check 10s
    maxconn 3000

# Estadísticas web
listen stats
    bind *:${stats_port}
    mode http
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE

# Frontend HTTP - puerto 80
frontend http_frontend
    bind *:80
    mode http
    option httplog

    acl is_rancher hdr(host) -i ${rancher_hostname}
    acl is_k8s_wildcard hdr(host) -m end .${domain}

    use_backend rancher_http_backend if is_rancher
    use_backend talos_http_backend if is_k8s_wildcard

    default_backend talos_http_backend

# Frontend HTTPS - puerto 443 con SSL termination
frontend https_frontend
    bind *:443 ssl crt /etc/ssl/certs/${domain}.pem
    mode http
    option httplog

    # Redirigir HTTP a HTTPS
    redirect scheme https code 301 if !{ ssl_fc }

    acl is_rancher hdr(host) -i ${rancher_hostname}
    acl is_k8s_wildcard hdr(host) -m end .${domain}

    use_backend rancher_http_backend if is_rancher
    use_backend talos_http_backend if is_k8s_wildcard

# Backend para Rancher HTTP
backend rancher_http_backend
    mode http
    balance roundrobin
    # Solo verificar conectividad TCP, sin HTTP health check
    server rancher ${rancher_host}:${rancher_http_port} check port ${rancher_http_port}

# Backend para Talos Kubernetes Cluster
backend talos_http_backend
    mode http
    balance roundrobin
%{ for idx, server in talos_servers ~}
    server talos-cp-${format("%02d", idx + 1)} ${server.ip}:${server.port} check ssl verify none
%{ endfor ~}

# Backend para Rancher HTTPS directo (si es necesario)
backend rancher_https_backend
    mode http
    balance roundrobin
    # Solo verificar conectividad TCP
    server rancher ${rancher_host}:${rancher_https_port} check port ${rancher_https_port}

