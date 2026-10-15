#!/bin/zsh
# Double-click this file on a Mac. It starts SQL Server in Docker for the Data Warehouse project.
# Inside SQL Server, this package sits at C:\sql\dwh_project\ (SQL Server on Linux reads C:\ as /), so the scripts run as in the videos.
CONTAINER="sql-dwh-project"
PKG="dwh_project"
PASSWORD="SqlServer!2026"
cd "$(dirname "$0")"
PKG_DIR="$(cd ../.. && pwd)"
PATH="/Applications/Docker.app/Contents/Resources/bin:/usr/local/bin:$PATH"
pause() { echo; read -k 1 -s "?Press any key to close."; echo; }

if ! docker info >/dev/null 2>&1; then
  echo "Docker Desktop is not running. Start Docker Desktop, wait for the whale icon, then double-click this file again."
  pause; exit 1
fi

# One SQL Server is enough: if another package already started one on port 1433, use it.
TARGET="$(docker ps --filter publish=1433 --format '{{.Names}}' | head -1)"
if [ -z "$TARGET" ]; then
  echo "Starting SQL Server (the first start downloads it, about 1.5 GB) ..."
  docker compose up -d || { pause; exit 1; }
  TARGET="$CONTAINER"
else
  echo "SQL Server is already running in Docker ($TARGET). Using it."
fi

sql() { docker exec "$TARGET" /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$PASSWORD" -C -h -1 -Q "$1" 2>/dev/null; }
printf "Waiting for SQL Server "
for i in {1..120}; do sql "SELECT 1" >/dev/null && break; printf "."; sleep 2; done; echo
if ! sql "SELECT 1" >/dev/null; then
  echo "SQL Server did not answer. Open Docker Desktop, click the container $TARGET and read its log. The usual reason: Rosetta is off (section Mac: Docker in the guide)."
  pause; exit 1
fi

# Put the package files where the scripts look.
docker exec -u root "$TARGET" mkdir -p "/sql/$PKG"
docker cp "$PKG_DIR/01_datasets" "$TARGET:/sql/$PKG/" 2>/dev/null || for d in "$PKG_DIR/01_datasets"; do docker cp "$d" "$TARGET:/sql/$PKG/"; done
docker exec -u root "$TARGET" chown -R mssql:root /sql

print -r -- 'Ready. The datasets are where the scripts look: C:\sql\dwh_project\01_datasets\'
echo "Run 03_scripts/init_database.sql first, then build the warehouse like in the project."
echo "Connect in Visual Studio Code: server localhost, port 1433, user sa, password $PASSWORD"
pause
