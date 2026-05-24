#!/bin/bash
# setup.sh — primer arranque de n8n con Podman
# Uso: bash setup.sh

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
err()  { echo -e "${RED}❌ $*${NC}"; exit 1; }

echo ""
echo "🚀  Configurando n8n local con Podman"
echo "────────────────────────────────────"

# 1. Verificar dependencias
command -v podman        >/dev/null 2>&1 || err "Podman no encontrado. Instalalo con: sudo dnf install podman"
command -v podman-compose >/dev/null 2>&1 || err "podman-compose no encontrado. Instalalo con: pip install podman-compose"
ok "Dependencias OK"

# 2. Crear volumen si no existe
if podman volume inspect n8n_data >/dev/null 2>&1; then
  warn "El volumen 'n8n_data' ya existe — se reutiliza"
else
  podman volume create n8n_data
  ok "Volumen 'n8n_data' creado"
fi

# 3. Configurar .env
if [ -f .env ]; then
  warn ".env ya existe — no se sobreescribe"
else
  cp .env.example .env
  ok ".env creado desde .env.example"
  echo ""
  warn "Editá .env con tus credenciales antes de continuar:"
  echo "      nano .env"
  echo ""
  read -rp "¿Ya editaste el .env? [s/N] " respuesta
  [[ "$respuesta" =~ ^[sS]$ ]] || { warn "Editá el .env y volvé a correr el script."; exit 0; }
fi

# 4. Levantar servicio
echo ""
echo "▶  Levantando n8n..."
podman-compose up -d
echo ""
ok "n8n corriendo en http://localhost:${N8N_PORT:-5678}"
echo ""
echo "   Logs en vivo:  podman logs -f n8n"
echo "   Detener:       podman-compose down"
echo ""
