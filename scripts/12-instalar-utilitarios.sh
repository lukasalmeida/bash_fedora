#!/bin/bash

run_stage() {
    section "12/12 — Scripts auxiliares"
    run_root tee /usr/local/bin/adddominio >/dev/null <<'EOF'
#!/bin/bash
read -p "Domínio local (ex: olezele.local): " DOMAIN
read -p "IP do serviço (ex: 127.0.0.1): " IP
read -p "Porta do serviço (ex: 8080): " PORT
read -p "Confirmar? (s/N): " CONFIRM
[[ "$CONFIRM" =~ ^[Ss]$ ]] || { echo "Operação cancelada."; exit 0; }
CONF_FILE="/etc/nginx/conf.d/${DOMAIN}.conf"
grep -q "$DOMAIN" /etc/hosts || echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts >/dev/null
sudo tee "$CONF_FILE" >/dev/null <<EONGINX
server {
    listen 80;
    server_name $DOMAIN;
    location / {
        proxy_pass http://$IP:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EONGINX
if sudo nginx -t; then
    sudo systemctl reload nginx
    echo "Domínio criado: http://$DOMAIN"
else
    sudo rm -f "$CONF_FILE"
    echo "Erro na configuração."
    exit 1
fi
EOF
    run_root chmod +x /usr/local/bin/adddominio
    run_root tee /usr/local/bin/atualizar >/dev/null <<'EOF'
#!/bin/bash
sudo dnf update --refresh -y
EOF
    run_root tee /usr/local/bin/temp >/dev/null <<'EOF'
#!/bin/bash
if [[ ! -d "$HOME/Temp" ]]; then echo "Pasta ~/Temp não existe."; exit 0; fi
read -p "Deseja limpar a pasta ~/Temp? (s/N): " resposta
if [[ "$resposta" =~ ^[Ss]$ ]]; then rm -rf "$HOME/Temp"/*; echo "Pasta Temp limpa."; fi
EOF
    run_root chmod +x /usr/local/bin/atualizar /usr/local/bin/temp
    ok "Scripts auxiliares instalados"
}
