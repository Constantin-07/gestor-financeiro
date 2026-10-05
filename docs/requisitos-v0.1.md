# Gestor Financeiro — Levantamento de Requisitos
**Versão 0.1 — 12/09/2026 · Constantin**

---

## 1. Visão

Um aplicativo instalável no celular (PWA) para controlar dinheiro pessoal: registrar o que entra e o que sai, saber quanto sobra, respeitar um orçamento por categoria e acompanhar objetivos de poupança.

**Uso hoje:** uma pessoa, finanças pessoais, renda de salário fixo (CLT).
**Uso futuro:** o modelo de dados nasce preparado para vários usuários e vários *perfis financeiros* (pessoal, negócio, família) sem reescrever o app.

**Frase de sucesso:** em menos de 10 segundos eu lanço um gasto, e a qualquer momento eu sei quanto ainda posso gastar neste mês.

---

## 2. Princípios de projeto

1. **Lançar gasto é a ação mais frequente** — tem que ser a mais rápida da interface.
2. **Nada de tela em branco** — categorias, contas e orçamento vêm pré-preenchidos e ajustáveis.
3. **Funciona sem internet** — os dados vivem no celular; sincronização é opcional e vem depois.
4. **Preparado, não superconstruído** — o banco de dados já prevê multiusuário/multiperfil desde a v1, mas a interface só expõe isso quando for usado.
5. **O dado é seu** — exportar tudo (CSV/JSON) a qualquer momento, sem prisão de plataforma.

---

## 3. Escopo por fase

### Fase 1 — MVP (o app já é útil aqui)

| # | Funcionalidade | Descrição |
|---|---|---|
| F01 | Cadastro de contas | Conta corrente, poupança, carteira (dinheiro vivo). Cada uma com saldo inicial. |
| F02 | Lançamento manual | Despesa, receita e transferência entre contas. Valor, data, categoria, conta, descrição, observação. |
| F03 | Categorias e subcategorias | Lista padrão em PT-BR (Moradia, Mercado, Transporte, Lazer, Saúde, Educação, Assinaturas...) editável, com ícone e cor. |
| F04 | Renda CLT | Salário bruto, descontos (INSS, IRRF, VT/VR, plano, outros) e líquido. Data de pagamento. |
| F06 | Dashboard do mês | Entradas, saídas, saldo, quanto ainda pode gastar, maiores categorias. |
| F07 | Metas / objetivos | Nome, valor-alvo, prazo, valor já acumulado, aporte mensal sugerido, barra de progresso. |
| F08 | Cartão de crédito | Limite, dia de fechamento, dia de vencimento. Compras vão para a fatura, não para o saldo da conta. |
| F09 | Compra parcelada | Compra em N vezes gera N parcelas nas faturas futuras. |
| F10 | Busca e filtros | Por período, categoria, conta, valor, texto. |
| F11 | Backup e exportação | Exportar/importar CSV e JSON; backup local do banco. |
| F12 | Bloqueio por biometria | PIN ou digital para abrir o app. |

### Fase 2 — Automação e análise

| # | Funcionalidade | Descrição |
|---|---|---|
| F13 | Lançamentos recorrentes | Aluguel, assinaturas, salário. Cadastra uma vez, repete por regra (mensal, semanal, anual), com data-fim opcional. |
| F14 | Importação de extrato | CSV e OFX do banco/cartão, com detecção de duplicatas e categorização assistida. |
| F15 | Categorização automática | Regras por texto do lançamento ("IFOOD" → Alimentação) que o app aprende do histórico. |
| F16 | Relatórios e gráficos | Evolução mensal, para onde vai o dinheiro (pizza), comparativo entre períodos, média dos últimos 3/6/12 meses. |
| F17 | Controle de dívidas | Saldo devedor, taxa de juros, cronograma de quitação, simulação de amortização. |
| F18 | Projeção de saldo | Considerando recorrentes e faturas já lançadas, quanto sobra no fim do mês. |
| F19 | Notificações | Conta a vencer, fatura fechando, orçamento estourado, meta atrasada. |
| F25 | Gráficos | Donut de gastos por categoria no Resumo; aba com entradas x saídas por mês, saldo acumulado, categorias ao longo do tempo e comparativo entre bancos. |
| F26 | Multi-banco | Contas agrupadas por instituição. Saldo por banco no Resumo e filtro por banco em todos os gráficos. |

### Fase 3 — Integração e expansão

| # | Funcionalidade | Descrição |
|---|---|---|
| F20 | Open Finance | Sincronização automática com bancos via agregador (Pluggy, Belvo ou similar). Requer CNPJ e é serviço pago. |
| F21 | Nuvem e multi-dispositivo | Conta de usuário, sincronização, restauração em outro aparelho. |
| F22 | Múltiplos perfis | Separar "Pessoal", "Negócio", "Família" com relatórios independentes e consolidados. |
| F23 | Compartilhamento | Segundo usuário lançando na mesma carteira, com permissões. |
| F24 | Investimentos | Carteira, aportes, rendimento, patrimônio líquido total. |

### Fora de escopo (por enquanto)
Declaração de imposto de renda · múltiplas moedas e câmbio · emissão de nota fiscal · conciliação contábil · divisão de contas entre amigos.

---

## 4. Regras de negócio

**RN01 — Saldo.** O saldo de uma conta é o saldo inicial mais todas as transações efetivadas até hoje. Lançamentos futuros aparecem como *previstos* e não alteram o saldo atual.

**RN02 — Transferência não é receita nem despesa.** Mover dinheiro entre contas próprias muda os saldos, mas não entra em nenhum relatório de gastos ou de renda.

**RN03 — Cartão de crédito.** Uma compra no cartão entra na fatura do período em aberto e **não** debita a conta corrente. O débito na conta acontece quando a fatura é paga. Compra feita após o fechamento cai na fatura do mês seguinte.

**RN04 — Parcelamento.** Compra de R$ 1.200 em 12x gera 12 parcelas de R$ 100, uma em cada fatura futura. Cada parcela pertence à categoria da compra original e é rastreável até ela.

**RN05 — Mês de referência.** Configurável: mês-calendário (dia 1 ao último dia) ou ciclo personalizado começando no dia do pagamento do salário. Todos os cálculos de orçamento e dashboard respeitam essa escolha.

**RN07 — Aporte sugerido da meta.** `(valor-alvo − acumulado) ÷ meses restantes até o prazo`. Se o prazo passou e a meta não foi atingida, ela fica marcada como *atrasada* com o novo valor mensal recalculado.

**RN08 — Renda líquida.** Líquido = bruto − (INSS + IRRF + benefícios descontados + outros). O que entra no fluxo de caixa é o líquido; o bruto fica registrado para referência.

**RN09 — Capacidade de gasto.** "Quanto ainda posso gastar" = renda líquida prevista do mês − despesas efetivadas − despesas previstas − aportes de metas do mês.

**RN12 — Conciliação (F14 e F20).** Toda transação vinda de importação ou de Open Finance procura, antes de entrar, uma previsão em aberto compatível: mesma recorrência ou mesma conta, data dentro de uma janela de tolerância e valor próximo. Se achar, funde — a previsão vira o lançamento real com o valor que o banco informou. Se não achar, entra como lançamento novo. Sem essa regra, previsão e importação duplicam todo lançamento fixo.

**RN11 — Recorrência idempotente.** Cada ocorrência gerada é identificada por `recorrenciaId@data`. A chave considera também as ocorrências excluídas, para que uma ocorrência pulada nunca seja recriada.

**RN10 — Exclusão.** Nada é apagado de verdade: exclusão é lógica (`deleted_at`), para permitir desfazer e não corromper históricos e faturas.

---

## 5. Modelo de dados (entidades principais)

- **usuario** — id, nome, email, pin_hash, criado_em
- **perfil** — id, usuario_id, nome ("Pessoal"), moeda, dia_inicio_mes *(a chave da expansão futura: tudo abaixo pendura aqui)*
- **conta** — id, perfil_id, nome, tipo (corrente | poupança | carteira | cartão), saldo_inicial, instituição, ativa
- **cartao** — id, conta_id, limite, dia_fechamento, dia_vencimento
- **fatura** — id, cartao_id, mês_referência, data_fechamento, data_vencimento, status (aberta | fechada | paga), valor_total
- **categoria** — id, perfil_id, nome, tipo (despesa | receita), categoria_pai_id, ícone, cor, arquivada
- **transacao** — id, perfil_id, conta_id, categoria_id, tipo (despesa | receita | transferência), valor, data, data_efetivacao, descrição, observação, fatura_id, recorrencia_id, parcela_atual, parcela_total, transacao_pai_id, status (prevista | efetivada), deleted_at
- **recorrencia** — id, perfil_id, modelo da transação, regra (frequência, intervalo, dia), data_inicio, data_fim, ativa
- **orcamento** — id, perfil_id, categoria_id, mês_referência, valor_teto
- **meta** — id, perfil_id, nome, valor_alvo, valor_acumulado, prazo, conta_vinculada_id, status
- **renda** — id, perfil_id, tipo (salário | outro), bruto, descontos (json), líquido, dia_pagamento, ativa
- **regra_categorizacao** — id, perfil_id, padrão_texto, categoria_id, prioridade

---

## 6. Requisitos não funcionais

| # | Requisito |
|---|---|
| NF01 | Funciona 100% offline; toda leitura e escrita é local. |
| NF02 | Abertura do app em menos de 2 segundos; lançar um gasto em no máximo 3 toques. |
| NF03 | Dados sensíveis criptografados em repouso no aparelho. |
| NF04 | Interface em português do Brasil, moeda em Real, datas no formato dd/mm/aaaa. |
| NF05 | Tema claro e escuro. |
| NF06 | Nenhum dado enviado a terceiros na Fase 1 e 2 — sem analytics invasivo, sem anúncios. |
| NF07 | Backup exportável pelo próprio usuário, em formato aberto e legível. |
| NF08 | Suporta pelo menos 10 anos de histórico (~50 mil transações) sem degradar a busca. |
| NF09 | Acessibilidade: contraste adequado, fontes escaláveis, alvos de toque generosos. |

---

## 7. Decisões técnicas pendentes

**D1 — Formato do app. DECIDIDO em 12/09/2026: PWA (app web instalável).**
Abre no navegador, é instalado na tela inicial e funciona offline. Permite validar as regras de negócio com dinheiro real rapidamente. A migração para React Native fica em aberto para a Fase 2, reaproveitando a lógica de negócio.
Consequências: NF01 (offline) passa a depender de service worker e cache local; F12 (biometria) usa WebAuthn; F19 (notificações) é limitado no iPhone e será reavaliado na Fase 2.

**D2 — Ciclo do mês.** Mês-calendário ou ciclo começando no dia do pagamento do salário? *(pendente)*

**D3 — Banco de dados.** Com o PWA definido: IndexedDB (nativo do navegador, mais simples) ou SQLite-wasm com persistência em OPFS (SQL de verdade, melhor para os relatórios da Fase 2). Sem servidor em nenhum dos casos. *(pendente)*

**D4 — Agregador de Open Finance.** Só na Fase 3. Pluggy e Belvo cobram mensalidade e exigem CNPJ — avaliar se compensa frente à importação de OFX, que é gratuita. *(pendente)*

**Removido — F05/RN06, orçamento por categoria.** Descartado em 12/09/2026. Definir um teto manual por categoria era um passo de planejamento que o usuário não pediu; o app reporta o que aconteceu. A divisão por categoria vive no donut do Resumo, alimentada pelos lançamentos (e, na Fase 3, pelo Open Finance).

**D5 — Nome do app.** "Gestor Financeiro" é o nome do projeto; o app pode ter outro. *(pendente)*

---

## 8. Próximos passos

1. Fechar D2 (ciclo do mês) e D3 (IndexedDB ou SQLite-wasm).
2. Desenhar as telas principais do MVP: dashboard, lançamento rápido, lista de transações, orçamento, metas.
3. Construir o MVP funcionalidade por funcionalidade, na ordem F01 → F12.
4. Usar por um mês com dinheiro real antes de partir para a Fase 2 — o uso real corrige mais requisitos do que qualquer documento.
