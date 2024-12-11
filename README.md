# UniFi Hotspot Portal

Este é um portal de acesso para redes sem fio UniFi com autenticação WPA2 Enterprise.

## Requisitos

- Ubuntu 20.04 LTS
- UniFi Controller configurado e acessível
- Acesso root ao servidor

## Instalação Rápida

1. Faça login no seu servidor Ubuntu como root

2. Baixe o script de instalação:
   ```bash
   wget https://raw.githubusercontent.com/yourusername/unifi-hotspot-portal/main/install.sh
   ```

3. Torne o script executável:
   ```bash
   chmod +x install.sh
   ```

4. Execute o script:
   ```bash
   ./install.sh
   ```

5. Configure o arquivo .env:
   ```bash
   nano /root/unifi-hotspot-portal/.env
   ```
   
   Atualize as seguintes informações:
   - DB_PASSWORD: Senha do banco de dados
   - JWT_SECRET: Uma string aleatória para segurança
   - UNIFI_HOST: IP do seu UniFi Controller
   - UNIFI_USERNAME: Usuário do UniFi Controller
   - UNIFI_PASSWORD: Senha do UniFi Controller

6. Reinicie o serviço:
   ```bash
   systemctl restart hotspot
   ```

## Acesso ao Portal

- URL: http://seu_ip_do_servidor
- Painel de Administração: http://seu_ip_do_servidor/admin

## Usuário Administrador Padrão

Para criar o primeiro usuário administrador, use o seguinte comando:

```bash
cd /root/unifi-hotspot-portal
node scripts/create-admin.js
```

## Funcionalidades

- Autenticação WPA2 Enterprise
- Gerenciamento de usuários
- Importação em massa via Excel
- Gerenciamento de pontos de acesso
- Múltiplos sites UniFi
- Perfil de usuário editável

## Suporte

Em caso de problemas, verifique os logs:
```bash
journalctl -u hotspot -f
```