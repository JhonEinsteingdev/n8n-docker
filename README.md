# n8n local con Podman

> Configuración mínima para correr [n8n](https://n8n.io/) en local usando Podman + podman-compose.

## Tabla de contenidos

- [Requisitos](#requisitos)
- [Instalación y primer arranque](#instalación-y-primer-arranque)
- [Uso diario](#uso-diario)
- [Workflows activos](#workflows-activos)
- [Integraciones configuradas](#integraciones-configuradas)
- [Datos y backups](#datos-y-backups)
- [Workflows versionados](#workflows-versionados)
- [Solución de problemas](#solución-de-problemas)

---

## Requisitos

| Herramienta | Instalación |
|---|---|
| [Podman](https://podman.io/) | `sudo dnf install podman` |
| [podman-compose](https://github.com/containers/podman-compose) | `pip install podman-compose` |

---

## Instalación y primer arranque

### 1. Crear el volumen externo

Los datos de n8n viven en un volumen Podman gestionado por el sistema
(no dentro de esta carpeta). Solo hay que crearlo una vez:

```bash
podman volume create n8n_data
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env
# Edita .env con tus valores reales
```

> El `.env` está en `.gitignore` — nunca se sube al repo.

### 3. Levantar el servicio

```bash
# Opción A — script automático (recomendado para la primera vez)
bash setup.sh

# Opción B — manual
podman-compose up -d
```

Abre el navegador en **<http://localhost:5678>** y completa el registro inicial.

---

## Uso diario

| Acción | Comando |
|---|---|
| Iniciar | `podman-compose up -d` |
| Detener | `podman-compose down` |
| Ver logs | `podman logs -f n8n` |
| Reiniciar | `podman-compose restart` |

---

## Workflows activos

### Notion → Excel → Gmail

| Campo | Valor |
|---|---|
| **Trigger** | Cron — día 15 de cada mes, 8:00 am |
| **Qué hace** | Exporta tareas de Notion, genera un `.xlsx` y lo envía por Gmail |
| **Estado** | ✅ Activo |

---

## Integraciones configuradas

| Servicio | Tipo de credencial | Nombre en n8n |
|---|---|---|
| Notion | Integration token | `Notion account` |
| Gmail | OAuth2 | Cuenta de Google configurada en n8n |

### ⚠️ Nota sobre OAuth Google

La app de Google está en modo **Testing**. Si el token expira o deja de funcionar:

1. Ir a [console.cloud.google.com](https://console.cloud.google.com)
2. APIs & Services → OAuth consent screen
3. En **Test users**, verificar que el correo sigue en la lista
4. Si fue removido, volver a agregarlo

---

## Datos y backups

El volumen `n8n_data` **no está en esta carpeta** — Podman lo gestiona
internamente en `~/.local/share/containers/storage/volumes/n8n_data/`.

Esta carpeta solo tiene la configuración de infraestructura.

### Exportar workflows manualmente

```bash
# Exportar todos los workflows a un JSON local
podman exec n8n n8n export:workflow --all --output=/home/node/.n8n/workflows.json

# Copiar el JSON a tu máquina
podman cp n8n:/home/node/.n8n/workflows.json ./workflows-backup.json
```

### Ver dónde vive el volumen

```bash
podman volume inspect n8n_data
```

---

## Workflows versionados

Los workflows exportados viven en `workflows/workflows.json` y se versionar
junto con el repo. Para mantenerlos actualizados:

```bash
# Exportar el estado actual de n8n → workflows/workflows.json
bash backup.sh

# Commitear los cambios
git add workflows/workflows.json
git commit -m "chore: actualizar workflows"
```

### Restaurar workflows en una instalación nueva

```bash
podman exec -i n8n n8n import:workflow --input=/home/node/.n8n/workflows_export.json
# O copiando primero el archivo:
podman cp workflows/workflows.json n8n:/home/node/.n8n/workflows_export.json
podman exec n8n n8n import:workflow --input=/home/node/.n8n/workflows_export.json
```

### Backup completo con credenciales

```bash
# Genera backups/n8n_backup_FECHA.tar.gz (en .gitignore, nunca al repo)
bash backup.sh --with-credentials
```

---

## Workflows versionados

Los exports viven en `workflows/` — la carpeta está en el repo pero los `.json`
están en `.gitignore`, así que nunca se suben al repositorio.

### Exportar el estado actual de n8n

```bash
bash backup.sh
# → genera workflows/workflows.json (solo local)
```

### Restaurar workflows en una instalación nueva

```bash
# Copiar el JSON al contenedor e importar
podman cp workflows/workflows.json n8n:/home/node/.n8n/workflows_export.json
podman exec n8n n8n import:workflow --input=/home/node/.n8n/workflows_export.json
```

### Backup completo con credenciales

```bash
# Genera backups/n8n_backup_FECHA.tar.gz (también en .gitignore)
bash backup.sh --with-credentials
```

---

## Solución de problemas

**El contenedor no arranca**
```bash
podman logs n8n
```

**El puerto 5678 ya está en uso**
```bash
# Cambiar el puerto en .env
N8N_PORT=5679
podman-compose up -d
```

**Resetear datos (⚠️ destructivo)**
```bash
podman-compose down
podman volume rm n8n_data
podman volume create n8n_data
podman-compose up -d
```
