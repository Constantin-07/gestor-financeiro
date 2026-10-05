# Gestor Financeiro

App de finanças pessoais — PWA instalável no celular.
Registrar entradas e saídas, orçamento por categoria, metas e controle de fatura de cartão.

## Estado atual

| | |
|---|---|
| Versão | **0.9** (04/10/2026) |
| Fase | MVP + contas fixas + gráficos + multi-banco + importação de extrato + orçamento no crédito |
| Formato | PWA sem build (HTML + CSS + JS puro) |
| Dados | IndexedDB local, com fallback para localStorage |
| Próximo passo | Usar com dinheiro real por um mês, depois o resto da Fase 2 |

## Estrutura

```
gestor-financeiro/
├── README.md              este arquivo
├── COMO-RODAR.md          como servir e instalar no celular
├── app/                   o PWA (8 arquivos estáticos)
└── docs/
    └── requisitos-v0.1.md levantamento completo
```

## Decisões

- **D1 — Formato do app.** ✅ PWA. Migração para React Native fica em aberto para a Fase 2.
- **D2 — Ciclo do mês.** ✅ Virou configuração no app (Ajustes → Ciclo do mês). Padrão: mês-calendário.
- **D3 — Banco local.** ✅ IndexedDB, um documento único, escrita com debounce.
- **D4 — Open Finance.** ⏳ Só na Fase 3.
- **D5 — Nome do app.** ⏳ Ainda "Gestor Financeiro".

## MVP — o que está pronto

| | | |
|---|---|---|
| F01 | Contas | corrente, poupança, carteira e cartão |
| F02 | Lançamento manual | despesa, receita e transferência |
| F03 | Categorias | 16 padrão em PT-BR; grade com Despesas/Receitas, gasto do mês em cada uma, emoji livre ou da grade, cor e arquivamento |
| F04 | Renda CLT | bruto, INSS, IRRF, benefícios → líquido; lançado todo mês como receita, com histórico de valores |
| F06 | Dashboard do mês | "ainda posso gastar", entradas, saídas, saldo |
| F07 | Metas | alvo, prazo, aporte mensal calculado, registro de aportes |
| F08 | Cartão de crédito | limite, fechamento, vencimento, fatura e pagamento |
| F09 | Compra parcelada | até 24x distribuídas nas faturas futuras |
| F10 | Busca e filtros | tipo, categoria, conta e texto |
| F11 | Backup | exportar JSON e CSV, importar JSON |
| F14 | Importar extrato | OFX e CSV, com conciliação automática (RN12) e categorização por histórico e dicionário |
| F13 | Contas fixas | aluguel, assinaturas, mensalidades — lançadas automaticamente |
| F25 | Gráficos | donut de gastos por categoria, entradas x saídas, saldo acumulado, categorias no tempo |
| F26 | Multi-banco | contas agrupadas por instituição, com filtro em todos os gráficos |
| F27 | Crédito x débito | forma de pagamento no lançamento e orçamento unificado com teto por forma |

**Falta do MVP:** F12 (PIN/biometria) — fica para a próxima rodada.

### F27 — crédito x débito

- Na despesa, **Forma de pagamento: Débito · Pix · dinheiro | Crédito**. O seletor filtra
  o "Pago com": no débito aparecem conta corrente, poupança e carteira; no crédito, só
  cartões. Parcelas só aparecem no crédito.
- A forma **não é gravada** no lançamento: ela sai da conta (`formaDe(t)` — cartão é
  crédito, o resto é débito). Trocar a conta de um lançamento troca a forma.
- **Orçamento unificado** (Plano): cada teto é de uma categoria e vale para uma forma —
  **qualquer forma**, **só no crédito** ou **só no débito · Pix** — escolhida em "+ Novo teto".
  No Plano, quatro abas (Crédito, Débito·Pix, Qualquer, Metas) resumem cada grupo; tocar mostra só aquela
  lista, com anel de progresso por teto. Tocar num teto edita ou exclui. Tetos de formas diferentes na mesma categoria
  convivem ("Lazer R$ 500" e "Lazer no crédito R$ 200"); o app avisa no que estourar primeiro.
- O crédito conta pela **data da compra** — numa compra parcelada, conta a parcela do mês.
- No dado, `forma` é `"credito"` ou `"debito"`; sem `forma`, o teto é geral. Estouro gera o
  alerta "Lazer no crédito estourou o orçamento" no Resumo.
- Extrato: lançamentos no cartão mostram "crédito" e há filtros **Crédito** e **Débito**.

### F13 — como as contas fixas funcionam

- Frequências: mensal, a cada 2/3/6/12 meses, semanal e quinzenal.
- Data de término opcional — serve para financiamento e curso com número fixo de meses.
- Os lançamentos são **materializados sob demanda**: o app cria as ocorrências até o fim do
  mês que você está olhando. Navegar para frente gera as seguintes.
- Cada ocorrência é um lançamento normal: entra no orçamento, na projeção e no extrato,
  marcada com ↻. Dá para editar ou excluir uma ocorrência isolada sem afetar as outras
  — uma ocorrência editada à mão nunca é sobrescrita.
- Alterar o valor da recorrência afeta só o futuro; o histórico fica intacto.
- Pausar remove as ocorrências futuras ainda intocadas. Excluir mantém o histórico
  como lançamentos avulsos.
- Recorrência num cartão de crédito cai na fatura correta, respeitando o fechamento.

## Regras de negócio implementadas

- **RN01** saldo = inicial + efetivadas até hoje; futuras aparecem como previstas
- **RN02** transferência e pagamento de fatura não entram em receita nem despesa
- **RN03** compra no cartão vai para a fatura, não debita a conta; após o fechamento, cai na fatura seguinte
- **RN04** parcelamento gera N lançamentos, um por fatura, herdando a categoria
- **RN05** ciclo do mês configurável
- **RN07** aporte = (alvo − acumulado) ÷ meses restantes
- **RN08** líquido = bruto − descontos
- **RN15** o salário vira uma receita "Salário" todo mês, no dia do pagamento, na conta escolhida (chave `salarioRef` = `AAAA-MM`). Antes do dia é previsto; no dia entra no saldo sozinho. O valor vem de `renda.historico`: cada alteração vale a partir de um mês (`desde`, padrão = próximo mês), então meses passados nunca mudam. Salário editado à mão no extrato (`editado`) é preservado
- **RN09** posso gastar = renda − **saída da conta** − aportes de metas (regime de caixa). Débito/Pix/dinheiro saem na data; compra no cartão sai no mês em que a fatura vence; fatura paga antes pesa no mês do pagamento e o vencimento conta só o resto. O Resumo avisa "+ R$ X no cartão · sai na fatura de dd/mm"
- **RN16** cartão não é banco: pertence à conta que paga a fatura (`contaPagamentoId`) e herda o banco dela
- **RN10** exclusão lógica via `deletedAt`
- **RN11** recorrência é idempotente: a chave `recorrenciaId@data` impede duplicar ou ressuscitar excluídos
- **RN14** teto por forma: "crédito" conta só despesas em cartão, "débito" só fora do cartão, ambos pela data da compra; tetos de formas diferentes são independentes
- **RN13** **previsto x realizado**: todo lançamento é uma das duas coisas. Data no futuro ou ocorrência de conta fixa nasce como *previsto* — é expectativa sua, não confirmação do banco. Previsto não entra no saldo das contas, aparece esmaecido no extrato e some da faixa âmbar quando você toca no ✓. Na Fase 3, é o Open Finance que passa a confirmar no seu lugar (RN12)
- **RN12** *(a implementar na F14/F20)* **conciliação**: transação importada do banco procura uma previsão em aberto da mesma recorrência, em janela de dias e com valor próximo, e funde em vez de duplicar

Detalhamento completo em `docs/requisitos-v0.1.md`.


## Navegação

```
Resumo    header verde · alerta de estouro · "Para onde foi" · metas · bancos
  │
  └──(toque em qualquer categoria)──> Extrato do mês
                                        donut · faturas · filtros · lançamentos
Plano     quatro abas — Crédito · Débito·Pix · Qualquer · Metas — cada uma com resumo e só a sua lista
Gráficos  filtro por banco: todos / cada instituição
Ajustes   hub em blocos: renda · contas e cartões › · contas fixas › · categorias › · backup e dados ›
          ciclo do mês e tema numa lista curta embaixo; › abre subpágina com voltar
```

**Resumo** abre com o bloco verde: quanto você ainda pode gastar, quanto isso dá
por dia no que resta do mês, e os totais de entrada e saída. Abaixo, um alerta
laranja por categoria que estourou o orçamento (dispensável), o grid "Para onde
foi" com as cinco maiores categorias mais "Outros", as metas em anéis de
progresso e o saldo de cada banco.

**Extrato do mês** é a tela empurrada a partir de qualquer categoria. No topo, o
donut de gastos do mês por categoria, com um **anel interno** que mostra quanto foi na
conta (verde) e quanto no cartão (violeta) — ele não muda com o modo escolhido.
Embaixo, os blocos **Conta | Cartão** escolhem o extrato: em Conta, só o que mexeu no
dinheiro (débito, Pix, receitas, pagamento de fatura) com o saldo ao fim de cada dia;
em Cartão, o bloco da fatura (status, fechamento, vencimento, uso do limite e **Pagar**)
e as compras no cartão.

**Plano** é onde orçamento e metas são definidos — a aba não mostra mais o
extrato, por isso mudou de nome.

## Paleta dos gráficos

**Verde é entrada, vermelho é saída — e por isso nenhuma categoria de despesa
pode usar essas duas cores.** A paleta das categorias tem 6 hues, sem verde e
sem vermelho, validada nos dois temas com o validador de acessibilidade (banda
de luminosidade, piso de croma, separação para daltonismo, piso de visão normal
e contraste). A categoria guarda o **slot** (0–5), não o hex — o tom certo para
claro ou escuro é resolvido em tempo de render.

| Slot | 1 azul | 2 laranja | 3 ciano | 4 amarelo | 5 magenta | 6 violeta |
|---|---|---|---|---|---|---|
| Claro | `#2a78d6` | `#eb6834` | `#0f9bc4` | `#eda100` | `#e87ba4` | `#4a3aa7` |
| Escuro | `#3987e5` | `#d95926` | `#2299c0` | `#c98500` | `#d55181` | `#9085e9` |

Reservados, fora da paleta de categorias:

| Papel | Claro | Escuro |
|---|---|---|
| Entrada | `#1baf7a` | `#199e70` |
| Saída / negativo | `#e34948` | `#e66767` |

Categorias de **receita** não escolhem cor: usam sempre o verde de entrada.
O donut dobra em "Outros" (cinza neutro) a partir da sexta categoria, então
nunca há mais de 5 hues na tela ao mesmo tempo. Com mais de 6 categorias de
despesa dois nomes podem repetir o mesmo tom — a legenda com nome, valor e
percentual é o que carrega a identidade, e qualquer categoria pode ter a cor
trocada em Ajustes.

## Importar extrato (F14) — pronto

Ajustes → **Importar extrato do banco**. Aceita OFX e CSV; o CSV detecta o
separador, o formato do número e as colunas de data, valor e descrição sozinho.

Ao importar você escolhe a conta, e é isso que amarra os lançamentos ao banco:
o extrato, o donut, os indicadores, as faturas e os gráficos passam a poder ser
filtrados por instituição.

### Formatos já testados contra arquivos reais

| Banco | Formato | Particularidade tratada |
|---|---|---|
| **Inter** | CSV `;` | Cinco linhas de apresentação antes da tabela; colunas `Valor` e `Saldo` juntas |
| **Nubank** | CSV `,` | Coluna `Identificador` vira chave anti-duplicata; descrição de Pix vem com CPF mascarado e dados bancários |
| **Itaú** | OFX e TXT | Arquivo em **windows-1252**, não UTF-8; linhas de `SALDO ANTERIOR` / `S A L D O` intercaladas no extrato |

Três defesas gerais que saíram desses casos:

- **Encoding**: o arquivo é lido como bytes. Tenta UTF-8 estrito e, falhando, decodifica
  como windows-1252 — senão os acentos do Itaú viram lixo.
- **Linhas de saldo**: qualquer descrição que comece com "saldo" (inclusive
  espaçada, `S A L D O`) é descartada. Sem isso, o saldo do dia entraria como receita.
- **Descrições**: CPF mascarado, agência, conta e código do banco são removidos.
  "Transferência recebida pelo Pix - FULANO - •••.899.183-•• - BANCO INTER (0077)
  Agência: 1 Conta: 37746072-9" vira "Pix recebido · FULANO".

### Onde baixar

- **Nubank** — app, tela da conta, arrasta a fileira de botões → Exportar extrato.
  Chega por e-mail em PDF e OFX.
- **Inter** — app ou internet banking, Conta Digital → Extrato → exportar.
- **Itaú** — **só pelo internet banking**, o app não exporta. Conta corrente →
  Extrato → *Salvar em outros formatos* → OFX (Money 100/102 ou 2000).
  O OFX do Itaú não inclui lançamentos do próprio dia.

O que a conciliação (RN12) faz com cada linha do arquivo, nesta ordem:

1. Se o `FITID` já existe, ignora — reimportar o mesmo arquivo não duplica nada.
2. Se já há um lançamento realizado igual (mesma conta, data e valor), ignora —
   cobre o que você tinha digitado à mão.
3. Se há uma **previsão** compatível (mesma conta e tipo, até 5 dias de
   diferença, valor dentro de 2% ou R$ 1), confirma essa previsão com o valor
   real do banco.
4. Caso contrário, cria um lançamento novo, categorizado primeiro pelo seu
   próprio histórico e depois por um dicionário de estabelecimentos brasileiros.

A prévia mostra o que vai acontecer antes de aplicar. Nada é gravado sem
confirmação.

**É esta a função que o Open Finance vai chamar.** A única coisa que muda na
Fase 3 é a origem da lista: em vez de ler um arquivo, o backend consulta o
agregador e entrega o mesmo formato para `conciliar()`.

## Sobre Open Finance (F20, Fase 3)

Não dá para o app conectar sozinho. O Open Finance Brasil é regulado: exige
instituição autorizada pelo Banco Central ou um agregador (Pluggy, Belvo, Klavi,
Quanto), com CNPJ, contrato pago e **um backend** — o `client_secret` e os tokens
não podem viver dentro de um PWA. Decisão de 13/09/2026: seguir com OFX/CSV e
reavaliar depois de rodar com dinheiro real.


A API de cartão de crédito do Open Finance Brasil expõe faturas, lançamentos e a
identificação de compras parceladas — então boa parte do que hoje é digitado à
mão vai deixar de ser.

**O que ele nunca vai trazer é o futuro.** O aluguel do mês que vem, o salário
que ainda não caiu, a parcela de dezembro: o banco só publica depois do fato.
Por isso a separação entre previsto e realizado (RN13) não é um remendo por
falta de integração — ela continua necessária com tudo conectado. O que muda é
quem confirma: hoje é você tocando no ✓, depois é a conciliação (RN12).

Hoje o app já modela múltiplas instituições e filtra tudo por banco, então quando
a integração chegar ela alimenta uma estrutura que já existe.
