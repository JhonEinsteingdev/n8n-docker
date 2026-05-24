#!/bin/bash
# backup.sh — exporta workflows y credenciales de n8n
# Uso: bash backup.sh [--with-credentials]
#
# Por defecto exporta solo workflows (seguros para commitear).
# Con --with-credentials también exporta credenciales DESENCRIPTADAS
# al directorio backups/ (que está en .gitignore).

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
err()  { echo -e "${RED}❌ $*${NC}"; exit 1; }

WITH_CREDS=false
for arg in "$@"; do
  [[ "$arg" == "--with-credentials" ]] && WITH_CREDS=true
done

DATE=$(date +%Y-%m-%d_%H%M%S)
WORKFLOWS_DIR="./workflows"
BACKUPS_DIR="./backups"

# Verificar que el contenedor esté corriendo
podman inspect n8n >/dev/null 2>&1 || err "El contenedor 'n8n' no está corriendo. Corré: podman-compose up -d"

echo ""
echo "📦  Backup n8n — $DATE"
echo "────────────────────────────────────"

# ── Workflows ────────────────────────────────────────────────────────────────
echo "▶  Exportando workflows..."
mkdir -p "$WORKFLOWS_DIR"

podman exec n8n n8n export:workflow --all --output=/home/node/.n8n/workflows_export.json

# Copiar el JSON consolidado al directorio workflows/
podman cp n8n:/home/node/.n8n/workflows_export.json "$WORKFLOWS_DIR/workflows.json"
ok "Workflows → $WORKFLOWS_DIR/workflows.json (listo para commitear)"

# ── Credenciales (solo con flag) ──────────────────────────────────────────────
if [ "$WITH_CREDS" = true ]; then
  warn "Exportando credenciales DESENCRIPTADAS — este archivo NO debe subirse al repo"
  mkdir -p "$BACKUPS_DIR"

  podman exec n8n n8n export:credentials --all --decrypted --output=/home/node/.n8n/creds_export.json
  podman cp n8n:/home/node/.n8n/creds_export.json "$BACKUPS_DIR/credentials_${DATE}.json"

  ok "Credenciales → $BACKUPS_DIR/credentials_${DATE}.json"
  warn "Recordá que backups/ está en .gitignore — no lo commitees"
fi

# ── Tarball completo (solo con flag) ─────────────────────────────────────────
if [ "$WITH_CREDS" = true ]; then
  TARBALL="$BACKUPS_DIR/n8n_backup_${DATE}.tar.gz"
  tar -czf "$TARBALL" \
    -C "$WORKFLOWS_DIR" workflows.json \
    -C "$(pwd)/$BACKUPS_DIR" "credentials_${DATE}.json" 2>/dev/null || true
  ok "Tarball → $TARBALL"
fi

echo ""
echo "   Para versionar en git:"
echo "   git add workflows/workflows.json && git commit -m 'chore: actualizar workflows'"
echo ""
