#!/usr/bin/env bash
# Gera o APK de debug do Gestor Financeiro.
#
# Dois problemas do ambiente que este script contorna:
#  1. O `gradle` vem do SDKMAN, que só entra no PATH em shell interativo.
#  2. O merge de recursos do plugin Android escreve arquivos grandes em /tmp,
#     que nesta máquina não tem espaço. Aqui o temporário é redirecionado para
#     dentro do próprio projeto.
set -euo pipefail
cd "$(dirname "$0")"
RAIZ="$PWD"

# --- Java e Gradle do SDKMAN -------------------------------------------------
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  set +u
  # shellcheck disable=SC1091
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  set -u
fi

# O plugin do Android 8.5.2 é homologado com o JDK 17 — o Java do sistema
# (25 no Fedora) não roda o Gradle 8.7. Procura no SDKMAN ou em ~/.local/opt.
JDK17="$(ls -d "$HOME"/.sdkman/candidates/java/17.* "$HOME"/.local/opt/jdk-17* 2>/dev/null | sort -V | tail -1 || true)"
if [ -n "$JDK17" ]; then
  export JAVA_HOME="$JDK17"
  export PATH="$JAVA_HOME/bin:$PATH"
fi

# --- SDK do Android ----------------------------------------------------------
export ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

if [ ! -d "$ANDROID_HOME/platforms/android-34" ]; then
  echo "Falta a platform-34 no SDK ($ANDROID_HOME)." >&2
  echo "Instale com: \$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager 'platforms;android-34'" >&2
  exit 1
fi

# --- temporários fora do /tmp ------------------------------------------------
TMPD="$RAIZ/.build-tmp"
mkdir -p "$TMPD"
export TMPDIR="$TMPD" TMP="$TMPD" TEMP="$TMPD"
# pego por qualquer JVM iniciada daqui, inclusive o daemon do Gradle
export _JAVA_OPTIONS="-Djava.io.tmpdir=$TMPD"

# grava o mesmo caminho no gradle.properties, para o daemon herdar de vez
JVMARGS="org.gradle.jvmargs=-Xmx2048m -Djava.io.tmpdir=$TMPD"
if grep -q '^org.gradle.jvmargs=' gradle.properties 2>/dev/null; then
  ATUAL="$(grep '^org.gradle.jvmargs=' gradle.properties)"
  if [ "$ATUAL" != "$JVMARGS" ]; then
    sed -i "s|^org.gradle.jvmargs=.*|$JVMARGS|" gradle.properties
    REINICIAR=1
  fi
else
  printf '%s\n' "$JVMARGS" >> gradle.properties
  REINICIAR=1
fi

# --- espaço em disco ---------------------------------------------------------
echo "Espaço livre:"
df -h "$HOME" /tmp 2>/dev/null | awk 'NR==1 || NR>1 {printf "  %-24s %6s livres de %-6s (%s usado)\n",$6,$4,$2,$5}' | tail -n +2
echo

LIVRE_KB="$(df -Pk "$HOME" | awk 'NR==2{print $4}')"
if [ "${LIVRE_KB:-0}" -lt 2097152 ]; then
  echo "AVISO: menos de 2 GB livres em $HOME. O build precisa de folga." >&2
  echo "Para liberar:  rm -rf ~/.gradle/caches/build-cache-*  e  rm -rf /tmp/*" >&2
  echo
fi

# --- Gradle ------------------------------------------------------------------
GRADLE_BIN="$(command -v gradle || true)"
if [ -z "$GRADLE_BIN" ] && [ -x "$HOME/.local/opt/gradle-8.7/bin/gradle" ]; then
  GRADLE_BIN="$HOME/.local/opt/gradle-8.7/bin/gradle"
fi
if [ -z "$GRADLE_BIN" ]; then
  GRADLE_BIN="$(ls -d "$HOME"/.gradle/wrapper/dists/gradle-*/*/gradle-*/bin/gradle 2>/dev/null \
                | sort -V | tail -1 || true)"
fi
if [ -z "$GRADLE_BIN" ]; then
  echo "Não encontrei o Gradle. Instale com: sdk install gradle 8.7" >&2
  exit 1
fi

echo "Gradle : $GRADLE_BIN"
echo "Java   : ${JAVA_HOME:-do sistema}"
echo "SDK    : $ANDROID_HOME"
echo "Temp   : $TMPD"
echo

# o daemon antigo ficou com o /tmp velho e com menos memória; derruba
if [ "${REINICIAR:-0}" = "1" ]; then
  "$GRADLE_BIN" --stop >/dev/null 2>&1 || true
fi

"$GRADLE_BIN" assembleDebug "$@"

APK="app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK" ]; then
  echo
  echo "──────────────────────────────────────────────"
  echo "APK pronto: $RAIZ/$APK"
  echo "Tamanho   : $(du -h "$APK" | cut -f1)"
  echo
  echo "Instalar por cabo:  adb install -r $APK"
  echo "Sem cabo: copie o arquivo para o celular e toque nele."
  echo "──────────────────────────────────────────────"
fi
