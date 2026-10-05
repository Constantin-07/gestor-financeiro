#!/usr/bin/env bash
# Gestor Financeiro — sobe um servidor local e mostra o endereço para o celular.
set -euo pipefail
cd "$(dirname "$0")/app"
PORTA="${1:-8080}"
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
echo
echo "  Gestor Financeiro"
echo "  ─────────────────────────────────────────"
echo "  Neste computador:  http://localhost:$PORTA"
[ -n "${IP:-}" ] && echo "  No celular (Wi-Fi): http://$IP:$PORTA"
echo
echo "  Ctrl+C para parar."
echo
exec python3 -m http.server "$PORTA" --bind 0.0.0.0
