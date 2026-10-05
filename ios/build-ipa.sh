#!/usr/bin/env bash
# Gera o .ipa do Gestor Financeiro para iPhone, a partir deste Linux, com o xtool.
#
# O .ipa sai SEM assinatura: quem instala assina com a própria Apple ID
# (Sideloadly, AltStore, SideStore…). Com Apple ID gratuita, o app vale 7 dias.
set -euo pipefail
cd "$(dirname "$0")"
RAIZ="$PWD"
export PATH="$HOME/.local/opt/swift-6.4.0-RELEASE-fedora41/usr/bin:$PATH"
XTOOL="$HOME/.local/opt/xtool/xtool.AppImage"

python3 sync-www.py

"$XTOOL" dev build --configuration release --ipa "$@"

IPA="$(ls -t xtool/*.ipa 2>/dev/null | head -1 || true)"
[ -z "$IPA" ] && IPA="$(find . -name '*.ipa' -newer Resources/www/index.html | head -1)"
echo
echo "──────────────────────────────────────────────"
echo "IPA pronto: $RAIZ/${IPA#./}"
echo "Tamanho   : $(du -h "$IPA" | cut -f1)"
echo "──────────────────────────────────────────────"
