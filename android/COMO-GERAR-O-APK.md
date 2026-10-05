# Gerar o APK

O projeto está pronto. Eu não consigo compilá-lo aqui — a política de rede deste
ambiente bloqueia `dl.google.com`, `maven.google.com`, Maven Central e o Gradle,
então não há como baixar o SDK do Android. Na sua máquina isso já existe.

## O que o APK é

A mesma aplicação, dentro de uma WebView. Não é um port: é o `index.html` do PWA
empacotado nos assets do app. Duas diferenças importantes em relação a abrir no
navegador:

- Os arquivos são servidos em `https://appassets.androidplatform.net`, não em
  `file://`. Isso importa: em `file://` o Chromium bloqueia IndexedDB e o app não
  salvaria nada.
- Exportar backup e importar backup passam pelo app nativo — o `<a download>` do
  navegador não funciona em WebView. O backup vai para a pasta **Downloads**.

## Pré-requisitos

Instalados em 03/10/2026, todos na pasta pessoal, sem sudo:

| | |
|---|---|
| JDK | 17 (Temurin) em `~/.local/opt/jdk-17*` — o Java 25 do Fedora não roda o Gradle 8.7 |
| Gradle | 8.7 em `~/.local/opt/gradle-8.7` |
| SDK | `~/android-sdk` — platform-34, build-tools 34.0.0, platform-tools (`adb`) |
| Licenças | aceitas |

O `build-apk.sh` acha o JDK e o Gradle nesses lugares (ou no SDKMAN, se existir).
O caminho do SDK está em `local.properties`.

## Compilar

```bash
cd ~/Documentos/Pessoal/gestor-financeiro/android
bash build-apk.sh
```

Se der `gradle: comando não encontrado`, é isso que o script resolve: o Gradle
vem do SDKMAN, que só entra no PATH em shell interativo. O script carrega o
ambiente sozinho, fixa o JDK 17 (o homologado para o plugin 8.5.2), aponta o
`ANDROID_HOME` e, se o `gradle` mesmo assim não existir, usa uma distribuição já
baixada em `~/.gradle/wrapper/dists`.

Para rodar na mão, o equivalente é:

```bash
export JAVA_HOME=$(ls -d ~/.local/opt/jdk-17* | tail -1)
cd ~/Documentos/Pessoal/gestor-financeiro/android
~/.local/opt/gradle-8.7/bin/gradle assembleDebug
```

Antes de compilar uma versão nova, suba `versionCode` em `app/build.gradle` —
senão o Android pode recusar instalar por cima.

### Se falhar por falta de espaço

O plugin do Android escreve arquivos grandes em `/tmp` durante o merge de
recursos, e nesta máquina o `/tmp` enche. O script já redireciona o temporário
para `.build-tmp/` dentro do projeto e grava isso no `gradle.properties`, então
não deve acontecer. Se ainda faltar espaço, o gargalo é a partição de casa:

```bash
df -h ~
rm -rf ~/.gradle/caches/build-cache-*   # cache de build, recriável
rm -rf ~/.gradle/caches/transforms-*    # idem
```

O APK sai em:

```
app/build/outputs/apk/debug/app-debug.apk
```

Na primeira vez o Gradle baixa o plugin do Android e a `androidx.webkit`; leva
alguns minutos. Depois é questão de segundos.

## Instalar no celular

**Com cabo USB**, depuração USB ligada:

```bash
~/android-sdk/platform-tools/adb install -r app/build/outputs/apk/debug/app-debug.apk
```

**Sem cabo:** copie o `.apk` para o celular (Telegram para você mesmo, Google
Drive, `scp`) e toque nele. O Android vai avisar que o app vem de origem
desconhecida e pedir permissão para instalar dessa fonte — é esperado, porque o
APK está assinado com a chave de debug e não vem da Play Store.

## Sobre os dados

O app tem armazenamento próprio, **separado** do navegador. Se você já lançou
coisas na versão web, migre assim:

1. No navegador: Ajustes → Exportar backup (JSON)
2. No app: Ajustes → Importar backup

## Publicar de verdade (se um dia quiser)

Para a Play Store o APK precisa ser assinado com uma chave sua, e o formato é
`.aab`, não `.apk`:

```bash
keytool -genkey -v -keystore gestor.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias gestor
```

Depois adicione um bloco `signingConfigs` no `app/build.gradle` e rode
`gradle bundleRelease`. Guarde a chave: perdê-la significa não conseguir mais
atualizar o app publicado.

## Estrutura

```
android/
├── settings.gradle
├── build.gradle
├── gradle.properties
├── local.properties          caminho do SDK (não versionar)
└── app/
    ├── build.gradle
    └── src/main/
        ├── AndroidManifest.xml
        ├── java/com/constantin/gestor/MainActivity.java
        ├── res/                 ícones, cores, tema
        └── assets/www/          o app (index.html + ícones)
```

Quando o app web mudar, é só substituir `app/src/main/assets/www/index.html`
pela versão nova e recompilar.
