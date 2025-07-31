#!/bin/bash

# Verificar si el usuario es root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse como root. Usa 'sudo'."
    exit 1
fi

# Configuración
MONGO_VERSION="4.4.29"
UBUNTU_CODENAME="jammy"  # Forzar Ubuntu 22.04 (Jammy)

# Función para manejar errores
handle_error() {
    echo "Error: $1"
    exit 1
}

# Paso 1: Instalar dependencias críticas (libssl1.1 para Jammy)
echo "🔹 Instalando dependencias (libssl1.1)..."
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.19_amd64.deb -O /tmp/libssl1.1.deb || handle_error "Falló al descargar libssl1.1"
dpkg -i /tmp/libssl1.1.deb || handle_error "Falló al instalar libssl1.1"
rm /tmp/libssl1.1.deb

# Paso 2: Agregar repositorio y clave GPG
echo "🔹 Agregando repositorio de MongoDB 4.4 para Jammy..."
apt-get install -y gnupg curl || handle_error "Falló la instalación de gnupg/curl"
curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-org-4.4.gpg || handle_error "Falló al agregar clave GPG"
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-org-4.4.gpg ] https://repo.mongodb.org/apt/ubuntu ${UBUNTU_CODENAME}/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list || handle_error "Falló al crear archivo de repositorio"

# Paso 3: Instalar MongoDB 4.4
echo "🔹 Actualizando e instalando MongoDB ${MONGO_VERSION}..."
apt-get update || handle_error "Falló apt-get update"
apt-get install -y mongodb-org=${MONGO_VERSION} mongodb-org-server=${MONGO_VERSION} mongodb-org-shell=${MONGO_VERSION} mongodb-org-mongos=${MONGO_VERSION} mongodb-org-tools=${MONGO_VERSION} || handle_error "Falló la instalación de MongoDB"

# Paso 4: Bloquear actualizaciones no deseadas
echo "mongodb-org hold" | dpkg --set-selections
echo "mongodb-org-server hold" | dpkg --set-selections
echo "mongodb-org-shell hold" | dpkg --set-selections
echo "mongodb-org-mongos hold" | dpkg --set-selections
echo "mongodb-org-tools hold" | dpkg --set-selections

# Paso 5: Iniciar y habilitar el servicio
echo "🔹 Iniciando MongoDB..."
systemctl start mongod || handle_error "No se pudo iniciar mongod"
systemctl enable mongod || handle_error "No se pudo habilitar mongod"

# Paso 6: Verificar instalación
echo "🔹 Verificando la versión instalada..."
mongod --version || handle_error "MongoDB no se instaló correctamente"

echo "✅ MongoDB ${MONGO_VERSION} instalado y configurado exitosamente en Ubuntu ${UBUNTU_CODENAME}."
echo "📌 Puerto predeterminado: 27017"
echo "📌 Configuración: /etc/mongod.conf"