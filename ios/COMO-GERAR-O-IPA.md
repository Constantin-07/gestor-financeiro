# Gerar o app de iPhone (.ipa) neste Linux

Mesma ideia do Android: o `index.html` do PWA dentro de uma WebView nativa
(`Sources/GestorFinanceiro/ContentView.swift`). Os arquivos são servidos por um
esquema próprio, `gestor://app/`, para o IndexedDB persistir no aparelho.
"Fazer backup" abre a folha de compartilhamento do iOS (Salvar em Arquivos, WhatsApp…).

## Ferramentas (já instaladas, 05/10/2026)

| | |
|---|---|
| Swift | 6.4 (pacote do Fedora 41) em `~/.local/opt/swift-6.4.0-RELEASE-fedora41` |
| xtool | 1.20.1 em `~/.local/opt/xtool/xtool.AppImage` |
| SDK do iOS | 27.1, extraído de `Xcode_27.1_Release_Candidate.xip` com `xtool sdk install` |

O Xcode.xip só pode ser baixado em developer.apple.com com Apple ID (grátis,
basta aceitar o Apple Developer Agreement — **não** precisa do programa pago).

## Gerar

```bash
bash ios/build-ipa.sh
```

Copia o `app/index.html` atual (sem o service worker) e gera
`ios/xtool/GestorFinanceiro.ipa`, **sem assinatura**.

Antes de cada versão nova, suba `CFBundleVersion` em `Resources/Info.plist`.

## Instalar no iPhone de outra pessoa

O .ipa sem assinatura é assinado por quem instala, com a própria Apple ID:

1. No computador (Windows ou Mac), instalar o **Sideloadly**.
2. Ligar o iPhone no cabo, arrastar o .ipa para o Sideloadly, informar a Apple ID e instalar.
3. No iPhone: **Ajustes → Privacidade e Segurança → Modo de Desenvolvedor** (ligar e reiniciar)
   e **Ajustes → Geral → VPN e Gerenciamento de Dispositivos → confiar** no perfil.

Com Apple ID gratuita o app **para de abrir após 7 dias**; reinstalar pelo Sideloadly
(ele tem renovação automática por Wi-Fi). Os dados ficam, desde que o app não seja apagado.

## Instalar direto deste PC

Com o iPhone no cabo deste computador: `xtool setup` (login com a Apple ID, só uma vez)
e depois `cd ios && xtool dev` — compila, assina e instala.
