# Como rodar o Gestor Financeiro

O app é um PWA sem build: não tem `npm install`, não tem framework, não tem servidor.
São 8 arquivos estáticos em `app/`. Só precisa de um servidor HTTP local — qualquer um.

## Rodar no computador

Abra um terminal na pasta `gestor-financeiro/app` e escolha uma linha:

```bash
python3 -m http.server 8080
# ou
npx serve -l 8080
# ou
php -S localhost:8080
```

Depois abra **http://localhost:8080** no navegador.

> Não abra o `index.html` com dois cliques (`file://`). O Chrome bloqueia IndexedDB
> e service worker nesse modo e o app não salva nada.

## Instalar no celular

O celular precisa alcançar o servidor. Duas formas:

**1. Mesma rede Wi-Fi (mais simples)**

```bash
python3 -m http.server 8080 --bind 0.0.0.0
ip addr show | grep "inet " | grep -v 127.0.0.1   # descubra o IP da máquina
```

No celular, abra `http://SEU_IP:8080`. No Chrome: menu ⋮ → *Adicionar à tela inicial*.

Ressalva: sem HTTPS o service worker não registra fora de `localhost`, então o app
abre e salva os dados normalmente, mas não funciona offline.

**2. Com HTTPS (offline funcionando)**

Publique a pasta `app/` em qualquer host estático — GitHub Pages, Netlify, Cloudflare
Pages, Vercel. Todos servem HTTPS de graça e nenhum precisa de build. Aí o
*Adicionar à tela inicial* instala o app de verdade, com ícone e modo offline.

## Onde ficam os dados

No **IndexedDB do navegador**, no aparelho. Não sobem para lugar nenhum.
Consequências práticas:

- Cada navegador e cada aparelho tem seus próprios dados — não sincronizam.
- Limpar dados do site apaga tudo.
- Use **Ajustes → Exportar backup (JSON)** de vez em quando.

## Estrutura

```
app/
├── index.html                 o app inteiro: markup, CSS e JS
├── manifest.webmanifest       nome, ícones e modo standalone
├── sw.js                      service worker (cache do casco, offline)
├── icon.svg
└── icon-180 / 192 / 512 / 512-maskable .png
```

Não há dependências externas além das fontes do Google Fonts. Sem internet, o app
cai para a fonte do sistema e continua funcionando.
