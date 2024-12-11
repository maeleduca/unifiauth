#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Função para log
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Função para verificar o último comando
check_error() {
    if [ $? -ne 0 ]; then
        error "$1"
        exit 1
    fi
}

# Função para gerar senha aleatória
generate_password() {
    openssl rand -base64 16
}

# Função para gerar JWT secret
generate_jwt_secret() {
    openssl rand -base64 32
}

# Função para validar IP
validate_ip() {
    if [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    error "Este script precisa ser executado como root"
    exit 1
fi

log "Iniciando instalação do UniFi Hotspot Portal..."

# Atualizar sistema
log "Atualizando sistema..."
apt update && apt upgrade -y
check_error "Falha ao atualizar o sistema"

# Instalar dependências
log "Instalando dependências..."
apt install -y curl postgresql postgresql-contrib nginx certbot python3-certbot-nginx
check_error "Falha ao instalar dependências"

# Instalar Node.js
log "Instalando Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
check_error "Falha ao instalar Node.js"

# Coletar informações do banco de dados
log "Configurando banco de dados..."
read -p "Digite o nome do banco de dados [hotspot_portal]: " DB_NAME
DB_NAME=${DB_NAME:-hotspot_portal}

read -p "Digite o usuário do banco de dados [hotspot]: " DB_USER
DB_USER=${DB_USER:-hotspot}

DB_PASSWORD=$(generate_password)
log "Senha gerada para o banco de dados: $DB_PASSWORD"

# Configurar PostgreSQL
log "Criando banco de dados e usuário..."
sudo -u postgres psql << EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF
check_error "Falha ao configurar o banco de dados"

# Coletar informações do UniFi Controller
log "Configurando UniFi Controller..."
while true; do
    read -p "Digite o IP do UniFi Controller: " UNIFI_HOST
    if validate_ip "$UNIFI_HOST"; then
        break
    else
        warning "IP inválido, tente novamente"
    fi
done

read -p "Digite a porta do UniFi Controller [8443]: " UNIFI_PORT
UNIFI_PORT=${UNIFI_PORT:-8443}

read -p "Digite o usuário do UniFi Controller: " UNIFI_USERNAME
while [ -z "$UNIFI_USERNAME" ]; do
    warning "Usuário não pode ser vazio"
    read -p "Digite o usuário do UniFi Controller: " UNIFI_USERNAME
done

read -s -p "Digite a senha do UniFi Controller: " UNIFI_PASSWORD
echo
while [ -z "$UNIFI_PASSWORD" ]; do
    warning "Senha não pode ser vazia"
    read -s -p "Digite a senha do UniFi Controller: " UNIFI_PASSWORD
    echo
done

read -p "Digite o Site ID do UniFi [default]: " UNIFI_SITE_ID
UNIFI_SITE_ID=${UNIFI_SITE_ID:-default}

# Gerar JWT Secret
JWT_SECRET=$(generate_jwt_secret)

# Clonar repositório
log "Clonando repositório..."
git clone https://github.com/yourusername/unifi-hotspot-portal.git /opt/hotspot
check_error "Falha ao clonar repositório"
cd /opt/hotspot

# Configurar ambiente
log "Configurando variáveis de ambiente..."
cat > .env << EOL
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
JWT_SECRET=$JWT_SECRET
UNIFI_HOST=$UNIFI_HOST
UNIFI_PORT=$UNIFI_PORT
UNIFI_USERNAME=$UNIFI_USERNAME
UNIFI_PASSWORD=$UNIFI_PASSWORD
UNIFI_SITE_ID=$UNIFI_SITE_ID
UNIFI_SSL=false
EOL
check_error "Falha ao criar arquivo .env"

# Instalar dependências do Node.js
log "Instalando dependências do Node.js..."
npm install
check_error "Falha ao instalar dependências do Node.js"

# Construir frontend
log "Construindo frontend..."
npm run build
check_error "Falha ao construir frontend"

# Configurar Nginx
log "Configurando Nginx..."
cat > /etc/nginx/sites-available/hotspot << EOL
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

ln -s /etc/nginx/sites-available/hotspot /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
check_error "Configuração do Nginx inválida"
systemctl restart nginx
check_error "Falha ao reiniciar Nginx"

# Configurar serviço systemd
log "Configurando serviço systemd..."
cat > /etc/systemd/system/hotspot.service << EOL
[Unit]
Description=UniFi Hotspot Portal
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/hotspot
ExecStart=/usr/bin/npm start
Restart=always
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOL

# Recarregar systemd e iniciar serviço
systemctl daemon-reload
systemctl enable hotspot
systemctl start hotspot
check_error "Falha ao iniciar serviço"

# Criar usuário admin inicial
log "Criando usuário administrador inicial..."
node scripts/create-admin.js
check_error "Falha ao criar usuário administrador"

# Verificar status dos serviços
log "Verificando status dos serviços..."
systemctl status postgresql | grep "active"
systemctl status nginx | grep "active"
systemctl status hotspot | grep "active"

# Exibir informações finais
log "Instalação concluída com sucesso!"
echo
echo "Informações importantes:"
echo "------------------------"
echo "URL do portal: http://$(hostname -I | awk '{print $1}')"
echo "Usuário admin: admin@example.com"
echo "Senha admin: admin123"
echo
warning "IMPORTANTE: Altere a senha do administrador após o primeiro acesso!"
echo
log "Para verificar os logs do sistema:"
echo "journalctl -u hotspot -f"
echo
log "Para reiniciar o serviço:"
echo "systemctl restart hotspot"