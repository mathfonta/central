
# 📊 Status do Projeto — AutoPost

> **Retomando após pausa?** Diga `#autopost-status` — o Claude lê este arquivo e dá o briefing completo em 30 segundos.

---

## 🟢 Situação Atual

**Data:** 2026-05-15 (fechamento de sessão)
**Fase:** Lançamento — Meta App Review aguardando + **pipeline 100% funcional** + 3 fixes de UX/copy
**Uso API semanal:** normal — Gemini 2.5 Flash operacional como provider de copy

### Commits pendentes de push
Nenhum — todos os repos sincronizados ✅

| Repo | Último commit | Status |
|------|--------------|--------|
| `backend/` | `c56de31` — fix contexto obrigatório no copywriter | ✅ Pushed |
| `frontend/` | `875f47d` — fix AttackSequenceCard estado concluído | ✅ Pushed |

### Sessão 2026-05-15 — Fix migrations + 3 bugs de UX/copy

**O que foi entregue:**

| Item | Detalhe | Status |
|------|---------|--------|
| **Migration `exa_trends_context` nunca aplicada** | Railway deployou ANTES do commit de fix (1 min de diferença). Banco travado em `d2e3f4a5b6c7`. Fix: `alembic upgrade head` local aplicou 3 migrations pendentes (`e6f7a8b9c0d1`, `b2c3d4e5f6a7`, `c3d4e5f6a7b8`). Banco agora em HEAD. | ✅ Resolvido |
| **Contexto do cliente ignorado na copy** | Instrução era "use para enriquecer" — Gemini ignorava detalhes específicos. Fix: "OBRIGATÓRIO USAR — mencione explicitamente na legenda". | ✅ `c56de31` |
| **AttackSequenceCard sumindo** | `attack_sequence_position = 10` para cliente Espectra (tinha >= 10 posts de teste). Card retornava `null` silenciosamente. Fix: estado "Sequência concluída 🎉" + reset do position para 0 no banco. | ✅ `875f47d` + DB |
| **2 posts publicados com sucesso** | Foto (obra_realizada, prova_social, Gemini 26s) + Vídeo Reel (obra_realizada, hook_choque, transcrição 290 chars). Pipeline fluindo. | ✅ Em produção |

**WeeklyInsightCard:** vazio porque Celery Beat ainda não rodou (roda segunda 07:00). Não é bug.

---

### Sessão 2026-05-14 — Bugs corrigidos + Story 14.2 em produção

**O que foi entregue:**

| Item | Detalhe | Status |
|------|---------|--------|
| **Bug 1 — "Publicações recentes só mostra falhas"** | Filter incluía só `published`; `approved` e `publishing` eram invisíveis. Fix: array `["published","approved","publishing"]` + badge amarelo "..." para pendentes. | ✅ Corrigido — `ed62283` |
| **Bug 2 — "Hashtags duplicadas após editar legenda"** | `draft` era inicializado de `activeCaption` (com hashtags). No save, backend armazenava `copy_result["caption"]` com hashtags; `build_full_caption` adicionava novamente. Fix: `rawCaption` state separado. | ✅ Corrigido — `ed62283` |
| **Rendering gap ApprovalScreen** | `CaptionVariantSelector` retorna null quando só há 1 variante; fallback `!caption_long` era false → legenda em branco. Fix: `(!caption_long \|\| (!caption_short && !caption_stories))`. | ✅ Corrigido — `ed62283` |
| **COPY_PROVIDER Railway** | Variável não chegava ao container. Solução: deletar + re-adicionar no Railway (força novo deploy completo). Log diagnóstico removido do `copywriter.py`. | ✅ Resolvido — `e7b2d74` |
| **Migration Story 14.2** | `c3d4e5f6a7b8_add_attack_sequence_position_to_clients.py` aplicada via `releaseCommand = "alembic upgrade head"` no deploy. | ✅ Automático |

---

### Sessão 2026-05-13 — Epic 13 CONCLUÍDO: Exa Search Intelligence

**O que foi entregue:**

| Story | Entrega | Status |
|-------|---------|--------|
| **13.1** | `app/tools/exa_search.py` — `search_exa_trends()`, cache Redis 24h, fallback gracioso. 9 testes. | ✅ Done |
| **13.2** | `exa_context` no copywriter, `#TENDENCIAS_DO_NICHO` no prompt, migration `exa_trends_context`. 5 testes. | ✅ Done |
| **13.3** | Hashtag extraction: explicit `#tags` + bullet-derived, `#HASHTAGS_EM_ALTA` injetado no prompt. 5 testes. | ✅ Done |
| **13.4** | `WeeklyContext` model+migration+schema, Celery Beat segunda 07:00, `_summarize_snippets` (Gemini), `GET /insights/weekly`, `WeeklyInsightCard.tsx` no dashboard. 13 testes. | ✅ Done |

**Total testes Epic 13:** 32 passando (9 + 5 + 5 + 13)

**Nota backend:** `HEAD.lock` impediu último commit da 13.4. Rodar `Remove-Item "C:\Projetos\autopost\backend\.git\HEAD.lock" -Force` no PowerShell antes do push.

---

### Sessão 2026-05-14 (noite) — Fix crítico migrations Alembic

**Bug crítico resolvido — pipeline estava quebrado:**

| Item | Detalhe |
|------|---------|
| **Erro** | `UndefinedColumnError: column exa_trends_context does not exist` — todo POST de vídeo falhava após 2s |
| **Causa raiz** | Migration `a1b2c3d4e5f6_add_exa_trends_context` usava mesmo revision ID da migration antiga `caption_edited` (também `a1b2c3d4e5f6`). Alembic detectava `CycleDetected` e não aplicava nenhuma migration do Epic 13/14. |
| **Fix** | Novo ID `e6f7a8b9c0d1`, `down_revision` apontando para `d2e3f4a5b6c7`, ponteiro `weekly_context` corrigido. Commit `8bf217a`. Push feito. |
| **Migrations pendentes agora aplicadas** | `e6f7a8b9c0d1` (exa_trends_context) + `b2c3d4e5f6a7` (weekly_context) + `c3d4e5f6a7b8` (attack_sequence_position) |

**Analytics Intelligence** discutido — candidato a Epic 15. Briefing completo em `💡 Ideas/ideia-analytics-intelligence.md`.

---

### Sessão 2026-05-12 (tarde) — Fix Gemini + Bugs Frontend Identificados

**O que foi feito:**

| Item | Detalhe | Status |
|------|---------|--------|
| **Fix `list object has no attribute setdefault`** | Gemini retorna `[{...}]` (array) em vez de `{...}` (dict). Fix: `if isinstance(result, list): result = result[0]` após `json.loads()`. Commitado. | ✅ Em produção |
| **COPY_PROVIDER=gemini funcionando** | Confirmado nos logs: `COPY_PROVIDER='gemini'`. Foto: copy gerada em 37s. Vídeo: transcrito 1686 chars + copy em 30s. Gemini 2.5 Flash operacional. | ✅ Em produção |
| **Git auth via .github-token** | PAT criado e salvo em `.github-token` (gitignored). Regra `git-auth.md` criada. CLAUDE.md atualizado com Step 4. | ✅ Configurado |
| **Obsidian conectado ao Cowork** | Drive `G:\Meu Drive\OBSidian\AutoPost` montado — Regra 0 agora funciona completamente. | ✅ Ativo |

**Bugs identificados e corrigidos em 2026-05-14:**

| Bug | Detalhe | Status |
|-----|---------|--------|
| **"Publicações recentes" só mostra falhas** | Cards de posts aprovados/publicados não apareciam — só os falhados ficavam visíveis. | ✅ Corrigido |
| **Hashtags não aparecem no final da copy** | Copy chegava sem hashtags no app, duplicava após edição. | ✅ Corrigido |

**Qualidade Gemini (avaliação pendente):**
- Usuário testou mas não deu feedback de qualidade ainda — avaliar na próxima sessão comparando copy gerada com copy esperada para construção civil.

---

### Sessão 2026-05-12 (manhã) — Copy Viral GPT-10X + Debug COPY_PROVIDER

**O que foi feito:**

| Item | Detalhe | Status |
|------|---------|--------|
| **Fix Gemini transcription 404** | Modelo `gemini-2.5-flash-preview-05-20` → `gemini-2.5-flash` (estável). Removido `http_options` com `api_version: v1` que bloqueava modelos preview. | ✅ Funcionando |
| **Copy viral — REGRAS 6-9** | Hook ≤10 palavras, ritmo visual frases curtas/médias, emojis posicionados (4-7/legenda), CTA conversacional. Integração do framework GPT-10X. | ✅ Em produção |
| **Triggers virais por nicho** | `_VIRAL_TRIGGERS` dict com ganchos específicos por segmento (construção, arquitetura, saúde, dentista, comércio). Injetados no prompt. | ✅ Em produção |
| **Obsidian — `🔬 Skill - Copy Viral (GPT-10X).md`** | Skill file criado com biblioteca de 5 categorias de hooks + 5 CTAs adaptados para serviços. | ✅ Criado |
| **`COPY_PROVIDER` no Pydantic Settings** | Declarado `COPY_PROVIDER: str = "claude"` no modelo. Commit `4fbecfe`. | ✅ Em produção |
| **`_call_gemini_for_copy()`** | Função async que chama Gemini como provider alternativo de copy. | ✅ Em produção |
| **Log diagnóstico COPY_PROVIDER** | `logger.info(f"[copywriter] COPY_PROVIDER={settings.COPY_PROVIDER!r}...")` adicionado. Commit `3982098`. | ✅ Em produção |
| **Debug COPY_PROVIDER** | Solução: deletar + re-adicionar variável no Railway forçou deploy completo com injeção correta. Log diagnóstico removido (`e7b2d74`). | ✅ Resolvido (2026-05-14) |

**Estado da copy (com Claude):**
Primeiro resultado pós-GPT-10X: *"Entrar no banheiro virou um esporte. Isso mudou. 🚪"* — hook com ritmo, storytelling, emojis intercalados. Qualidade visivelmente melhorada.

---

### Sessão 2026-05-11 — Epic 12: Qualidade de Copy + Transcrição de Áudio

**Ponto de partida:** Story 12.2 (upload de vídeo robusto) já implementada. Usuário confirmou funcionamento com vídeo real (porta de correr, 45s, Android).

**Problema identificado:** Copy gerada era pobre (2-3 frases genéricas). Comparação com Gemini + contexto rico mostrou diferença enorme.

**O que entregamos:**

| Item | Detalhe | Arquivos |
|------|---------|---------|
| **Qualidade de copy** | `MAX_CAPTION_LONG_CHARS` 400 → 1500. System prompt reescrito com storytelling, parágrafos `\n\n`, emojis intercalados, 3 abordagens distintas. `MAX_TOKENS` 1500 → 2500. | `copywriter.py` |
| **Caixa de contexto expandida** | `MAX_CHARS` 200 → 500, `rows` 3 → 5, placeholder com exemplo rico | `ContextModal.tsx` |
| **Story 12.2 concluída** | Upload de vídeo robusto, compressão automática CRF 28, badge "Comprimindo", dicas de gravação. QA CONCERNS (aprovado). | `video.py`, `content.py`, `GeneratingScreen.tsx`, `UploadScreen.tsx` |
| **Story 12.3 — Transcrição de Áudio** | Filtro 20 palavras, `audio_transcript` no result do analyst, injeção no copywriter como "TRANSCRIÇÃO DO ÁUDIO". 17 testes. QA CONCERNS (aprovado). | `analyst.py`, `copywriter.py`, `config.py`, `test_audio_transcription.py` |
| **GEMINI_API_KEY** | Configurada no Railway `worker` (usuário adicionou nesta sessão) | Railway |

**Descoberta importante:** `app/tools/transcription.py` já existia (commitado na Story 10.2 como Gemini plugável). A arquitetura de extração paralela frames+áudio também já estava em `analyze_video_with_ai()`. Story 12.3 só precisou adicionar o filtro de 20 palavras + salvar no result + injetar no copywriter.

**Status produção (2026-05-11):** backend pushed (`41c8453` migration fix + `22d2f46` Story 12.3). Railway aplicou `alembic upgrade head` — colunas `caption_short`/`caption_stories` agora são `Text`. GEMINI_API_KEY válida (nível pago). Aguardando teste manual com vídeo narrado.

---

### Sessão 2026-05-06 — Hotfix produção + Epic 11 Governança ✅ DONE

**Bugs resolvidos (todos em produção):**

| Bug | Causa | Fix | Commit |
|-----|-------|-----|--------|
| Pipeline travado 3+ min | `NameError` em `copywriter.py` — `_VOICE_TONE_MAP` definido depois de `_STATIC_LIBRARY` | Reordenou definições | `39e3305` |
| Fotos 8–21MB explorando na API Claude | Sem compressão antes de enviar | `_compress_image_for_claude()` com progressive quality/dimension | `00764a7` |
| "????" no Instagram | `ImageFont.load_default()` sem suporte Unicode | TTF DejaVu via apt + `_load_font()` | `96fed65` |
| Card gerado com texto técnico | Designer criava card para fotos de croqui | Always use clean photo — card builder é Epic futuro | `268e447` |
| Música não aparecia na legenda | `user_context` não estava sendo parseado no copywriter | Extrai "Música de fundo:" → `🎵` no caption | `2ae27d1` |
| Campo música criava expectativa falsa | Meta API não suporta adicionar música via API | Campo removido do ContextModal | `a8d5384` |

**Epic 11 — Governança e Qualidade ✅ DONE:**

| Story | Entrega | Status |
|-------|---------|--------|
| 11.1 CI Backend | `backend-ci.yml` — import check + pytest | ✅ Ativo |
| 11.2 CI Frontend | `frontend-ci.yml` — typecheck + build | ✅ Ativo |
| 11.3 Branch Protection | `main` protegido nos dois repos via `gh api` | ✅ Ativo |
| 11.4 Hotfix Workflow AIOS | `hotfix.yaml` + `hotfix-spec.md` no AIOS | ✅ Criado |
| 11.5 Smoke Tests | `test_smoke_pipeline.py` — 4 bugs como testes | ✅ Ativo |

**A partir de agora:** push direto em `main` é bloqueado. Todo código passa por CI verde.

---

## 🗓️ Planejamento — Próxima Sessão

### ⚡ FOCO DA PRÓXIMA SESSÃO — Âncoras de lançamento

**Item 1 (produto):** Âncoras de lançamento — primeiros clientes reais.
- 3 profissionais: 1 empreiteiro + 1 arquiteto + 1 paisagista
- Onboarding: resultado visível em 48h
- Oferta: 3 meses grátis + R$30/cliente indicado

**Item 2 (técnico opcional):** Avaliar qualidade Gemini vs Claude na copy gerada — comparar para construção civil.

### ⚡ FOCO DA SESSÃO ANTERIOR — App Review enviado, aguardar Meta (até 10 dias)

**Situação:** App Review definitivo enviado em 2026-05-11. Análise em andamento.
**Impacto:** Sem aprovação, clientes novos não conseguem conectar o Instagram (só contas Tester).
**Submission ID:** `14468890472358828`

**Checklist concluído (2026-05-11):**
- [x] DNS `autopost.app.br` → "Valid Configuration" no Vercel ✅
- [x] Verificação de empresa ESPECTRA CONSTRUCAO, TECNOLOGIA & SERVICOS LTDA → **Verificada** ✅ (2026-05-08)
- [x] App Review definitivo enviado → **Análise em andamento** ✅ (2026-05-11)

**Permissões em análise:**
- `instagram_business_basic`, `instagram_basic`, `instagram_content_publish`
- `pages_manage_posts`, `pages_show_list`, `pages_read_engagement`, `business_management`

**Próxima ação:** Aguardar resposta Meta (prazo: maioria em até 10 dias). Enquanto isso → Âncoras de lançamento.

**Domínio registrado (2026-05-05):**
- `autopost.app.br` registrado no Registro.br — expira 05/05/2027
- `www.autopost.app.br` → Production (Vercel) ✅

**Remoções feitas hoje:**
- `instagram_business_content_publish` removida da submissão (pertence à Instagram Platform API, não ao Facebook Login — `instagram_content_publish` é a equivalente correta e já está aprovada)

**Chamadas de teste feitas nesta sessão (2026-05-03):**
- `instagram_manage_comments` → GET `/17937184227227231/comments` → HTTP 200 ✅ (mas permissão removida da submission — não necessária para v1)
- `instagram_business_content_publish` → POST `17841459795427610/media` (creation_id `17985423545993181`) + POST `17841459795427610/media_publish` → publicou com id `18194991265362033` ✅

**Limpezas feitas:**
- `instagram_manage_comments` removido do OAuth scope (não está na App Review; funcionalidade de comentários adiada para v2)
- Backend `meta_oauth.py` atualizado + deployed via Railway

**Só depois da Meta:**
| # | Item | Prioridade |
|---|------|-----------|
| 1 | **Âncoras de lançamento** — 3 profissionais, 3 meses grátis | Alta |
| 2 | **TWA Google Play** — empacotar PWA como app Android | Média |
| 3 | **`upgrade_clicked`** + **`churn`** — eventos analytics restantes | Baixa |

### Variáveis de ambiente — TODAS CONFIGURADAS ✅
| Variável | Onde | Status |
|----------|------|--------|
| `NEXT_PUBLIC_POSTHOG_KEY` | Vercel | ✅ Configurada (2026-05-03) |
| `POSTHOG_API_KEY` | Railway | ✅ Configurada (2026-05-03) |
| `GEMINI_API_KEY` | Railway `api` | ✅ Configurada (2026-05-03) |
| `GEMINI_API_KEY` | Railway `worker` | ✅ Configurada (2026-05-11) — **nivel pago ativado, chave válida** |

### Bugs já resolvidos (nesta sessão, aguardando push)
| Bug | Solução | Commit |
|-----|---------|--------|
| #2 Cards Reels/Story quebrados | Placeholder escuro + ícone ▶ | `2be2bfd` |
| #3 Card pendente comprimido | Modo compacto com "Toque para revisar" | `2be2bfd` |
| #4 Dashboard acumula todos os posts | slice(0,3) para publicados + falhados | `2be2bfd` |

### Sessão 2026-05-03 — Hardening pré-lançamento

| Item | Status | Detalhe |
|------|--------|---------|
| **Bug #1 — dark mode** | ✅ Done (sessão anterior) | CSS vars em input, label, login, register |
| **Rate limiting** | ✅ Done (sessão anterior) | `/register` 5/h, `/forgot-password` 5/h, `POST /content-requests` 10/h |
| **Analytics Posthog** | ✅ Done (sessão anterior) | `post_created`, `post_approved`, `post_published` + PosthogProvider |
| **RLS Supabase** | ✅ Done | `clients` já tinha RLS; criada migration `c5d6e7f8a9b1` para `content_requests` — merge dos 2 heads divergentes |
| **JWT refresh automático** | ✅ Done | `lib/auth.ts` salva refresh_token; `lib/api.ts` interceptor retry com fila de requests pendentes |
| **Prompt caching Anthropic** | ✅ Done | copywriter: `_STATIC_LIBRARY` ~1600 tokens cacheado; analyst/onboarding/cerebro: cache_control no system |

### Sessão 2026-05-03 — Epic 10: Enriquecimento de Conteúdo de Vídeo ✅ DONE

| Item | Status | Detalhe |
|------|--------|---------|
| **Story 10.1 — Campo de Música** | ✅ Done | ContextModal: campo "Música de fundo" (opcional), merge em user_context. Frontend `2f38cc0` |
| **Story 10.2 — Transcrição de Vídeo** | ✅ Done | app/tools/transcription.py (Gemini plugável); extração paralela frames+áudio; fallback sem chave. Backend `171aa20` |
| **Variáveis de ambiente** | ✅ Done | Posthog (Railway+Vercel) + GEMINI_API_KEY (Railway) — todas configuradas |

### Ideias em backlog (não priorizadas)
- Texto/emojis sobrepostos em imagens (editor pós-design)
- Agente que aprende com aprovações/rejeições (ML loop)
- Toggle dark/light mode
- Validade de âncoras AE

### Sessão 2026-04-30 — Epic 9 concluído + UX de aprovação
| Item | Status |
|------|--------|
| **Bug: dashboard "Erro ao carregar posts"** | ✅ Resolvido — migration branch Alembic corrigida (down_revision errado em a3b4c5d6e7f8) |
| **GeneratingScreen** | ✅ Done state com botão "Revisar e aprovar →" em vez de auto-redirecionar |
| **ApprovalScreen** | ✅ Nova tela cheia: vídeo reproduzível, badge tipo, seletor variante, edição inline, footer com Aprovar/Rejeitar |
| **PhotoPreview** | ✅ Seletor de formato removido (era não-funcional, nunca enviado ao backend) |
| **Pipeline vídeo (analyze_photo)** | ✅ Fix — pula visão Claude para reels/story, injeta análise mínima |
| **Pipeline vídeo (prepare_design)** | ✅ Fix — pula Pillow para reels/story, vai direto para awaiting_approval |
| **Overlay "Enviando..."** | ✅ Elimina 3s de delay silencioso durante upload |
| **PostCard onOpen** | ✅ Cards pendentes no dashboard abrem ApprovalScreen ao clicar |
| **Story 9.4 — Publicação de Vídeo** | ✅ Done — Reels (REELS, polling 30×10s) + Story (IMAGE/VIDEO auto-detect) |
| **Footer ApprovalScreen** | ✅ Fix — botões em fluxo normal, sem fixed full-width no desktop |

### Sessão 2026-04-29 — Epic 9: Formatos & Estratégias Instagram
| Item | Status |
|------|--------|
| **Pesquisa estratégias Instagram 2025-2026** | ✅ Concluída — 4 formatos, 23 sub-estratégias validadas |
| **Story 9.1 — Formatos Instagram Fase 1** | ✅ Done + Em produção — 4 formatos, SubStrategySelector, campo `strategy` no backend |
| **Story 9.2 — Skill Library Copywriter** | ✅ Done — QA PASS 7/7, 23 prompts STRATEGY_PROMPTS, 84 testes afetados passando, em produção |
| **Story 9.3 — Upload por Formato** | ✅ Done — UploadScreen 4 modos, backend video/mp4+mov, extensão R2 dinâmica, 48 testes |

**Epic 8 ✅ CONCLUÍDO** | Meta App Review: enviado | Decisões estratégicas de lançamento tomadas

### Sessão 2026-04-28 (tarde) — Integração Claude Design Export
| Item | Status |
|------|--------|
| **Protocolo Claude Design → @ux-design-expert → @dev** | ✅ Executado corretamente |
| **globals.css** | ✅ Tokens semânticos CSS vars + dark mode + animações `.tap`/`.anim-slide-up` |
| **lib/post-types.tsx** | ✅ POST_TYPES centralizado com SVG icons + IDs corretos do backend |
| **BottomSheet.tsx** | ✅ Primitiva base para modais mobile — slide-up nativo, scroll lock |
| **PostTypeCard.tsx** | ✅ Cards/Rows com pressed state e feedback visual por tipo |
| **UploadScreen.tsx** | ✅ Tela full-screen de seleção câmera/galeria por tipo de post |
| **PhotoPreview.tsx** | ✅ Preview com seletor de crop ratio (1:1 / 4:5 / 1.91:1) |
| **ContextModal.tsx** | ✅ Reescrito com BottomSheet — mantém contexto + tom de voz |
| **ContentTypeBar.tsx** | ✅ Refatorado para usar PostTypeCard/PostTypeRow |
| **dashboard/page.tsx** | ✅ State machine: dashboard → upload → preview + modal |
| **Build + TypeScript** | ✅ Zero erros — 13 páginas compiladas |
| **Commit frontend** | ✅ ccd9fb2 — aguardando @devops push |
| **Diferido** | 🟡 StreakBar (precisa endpoint `/api/streak`) + Redesign Histórico |

### Sessão 2026-04-28 — Redesign UX Dashboard
| Item | Status |
|------|--------|
| **ContentTypeBar** | ✅ Em produção — substitui FAB, 5 tipos inline, "O que vamos postar hoje?" |
| **Tom de voz** | ✅ Movido para o fluxo de upload (ContextModal), fora do topo do dashboard |
| **PostCard** | ✅ Posts publicados mostram apenas imagem — grid estilo galeria |
| **Push + deploy Vercel** | ✅ main sincronizado, deploy automático acionado |

### Sessão 2026-04-28 — Estratégia de Lançamento (advanced elicitation)
| Item | Status |
|------|--------|
| **UX — Rearranjo Tela Inicial** | ✅ Decisão tomada — candidata ao Epic 9 (ver Ideas/Em Andamento) |
| **Modelo de Upgrade / Precificação** | ✅ Decisão tomada — plano único R$67–97/mês, 1 post grátis, Stripe, A/B por canal |
| **Go-to-Market** | ✅ Decisão tomada — TWA Play Store + âncoras WhatsApp + TikTok Fase 2 |
| **App nativo vs PWA** | ✅ Decisão: TWA Google Play (1–2 semanas dev) — App Store adiada |
| **Próxima sessão preparada** | ✅ Task em `🚀 Próxima Sessão.md` |

### Sessão 2026-04-28 (verificação @aios-master)
| Item | Status |
|------|--------|
| **Story 8.2 — Tom de Voz por Perfil** | ✅ Em produção — voice_tone confirmado em `/auth/me` (valor: "casual") |
| **Story 8.3 — Copy em Múltiplos Formatos** | ✅ Em produção — caption_long/short/stories/selected confirmados em `/content-requests` |
| **Push backend + frontend** | ✅ Feito — ambos sincronizados com origin/main |
| **Migrations Railway** | ✅ Aplicadas — voice_tone (clients) + caption variants (content_requests) rodaram via lifespan |
| **Meta App Review — screencast gravado** | ✅ Screencast OAuth gravado e enviado em todas as permissões |
| **Meta App Review — instagram_business_content_publish** | 🟡 Aguardando 24h para API call registrar → **envio final hoje 2026-04-28** |

### Sessão 2026-04-27
| Item | Status |
|------|--------|
| **Story 8.2 — Tom de Voz por Perfil** | ✅ Done (commitado) — voice_tone no Client model, PATCH /auth/profile, VoiceToneSelector Dashboard, #TOM_DE_VOZ no Copywriter |
| **Story 8.3 — Copy em Múltiplos Formatos** | ✅ Done (commitado) — 3 variações (long/short/stories) no Copywriter, colunas separadas, CaptionVariantSelector no PostCard |
| **Meta App Review — screencast gravado** | ✅ Screencast OAuth gravado e enviado em todas as permissões |

### Sessão 2026-04-26
| Item | Status |
|------|--------|
| **Story 8.1 — Janela de Contexto** | ✅ Done — ContextModal + user_context no pipeline completo (backend + frontend) |
| **Story 7.2 — @security dep-audit (Python + CI/CD)** | ✅ Done — pip-audit PASS (0 vulns em 99 pacotes), GitHub Actions criados, *dep-audit command ativo |
| **Pasta 💡 Ideas/ criada** | ✅ Organizada em Novas / Em Andamento / Incorporadas |
| **Obsidian reorganizado** | ✅ Home + Status + Protocolo + Global atualizados |
| **GitHub repo renomeado** | ✅ autopost-aiox → equipe-aiox |
| **Pendência — monorepo AutoPost** | 🟡 Avaliar após Meta App Review (backend/ + frontend/ no mesmo repo) |

### Sessão 2026-04-25
| Item | Status |
|------|--------|
| **Story 7.1 — Agente @security (Sage)** | ✅ Done — 13 artefatos criados, QA PASS 12/12 ACs |
| **Story 6.4 — Pipeline multi-foto** | ✅ Done — pushed (backend) |
| **Story 6.5 — CaptionEditor botão editar visível** | ✅ Done — pushed (frontend) |
| **@security *secrets-check** | ✅ Executado — resultado CLEAN, 1 finding MEDIUM (SEC-001 tok.json) resolvido |
| **equipe-aiox repo criado** | ✅ github.com/mathfonta/equipe-aiox (privado) — AIOX agora versionado |
| **Rotina git startup** | ✅ .claude/rules/git-startup-check.md criado + CLAUDE.md atualizado |
| **Diagnóstico git** | ✅ Confirmado: backend + frontend têm repos separados, raiz era sem git (corrigido) |

### Sessão 2026-04-24
| Item | Status |
|------|--------|
| Epic 5 — Fluxo de Aprovação Avançado | ✅ Em produção (Railway + Vercel) |
| Story 5.1 — Edição Inline da Legenda | ✅ Done — live |
| Story 5.2 — Retry: Nova Versão | ✅ Done — live |
| Story 5.3 — Menu de Intenção | ✅ Done — live |
| Renovação de Token Meta (v1.1 antecipado) | ✅ Deployado — POST /meta/refresh + Celery task diária (07:00) |
| MetaTokenWarning no Dashboard | ✅ Deployado — banner amarelo/vermelho + botão renovar |
| **Bug crítico: dashboard "Erro ao carregar posts"** | ✅ **Resolvido** — fix: migrations no `lifespan` do FastAPI |
| Vault Obsidian ativo | G:\Meu Drive\OBSidian\AutoPost\ (Google Drive) |

### Entregas anteriores (2026-04-18–19)
| Item | Status |
|------|--------|
| Bug loop onboarding→dashboard | ✅ Resolvido (causa raiz corrigida) |
| Botão câmera — upload real de foto | ✅ Testado e funcional em produção |
| Pipeline dispara via dashboard | ✅ Funcional |
| Meta App Review — Configurações Básicas | ✅ Concluído (ícone 1024×1024 + privacy + terms + categoria) |

### Botão câmera — como funciona agora
- **Mobile:** FAB → bottom sheet com "Tirar foto" (câmera) e "Escolher da galeria"
- **Desktop:** FAB → abre file picker do SO direto
- Upload via `POST /content-requests` → pipeline Celery dispara automaticamente
- Spinner durante upload, erro se falhar, refresh da lista ao concluir

## ⏭️ PRÓXIMOS PASSOS — retomar aqui

> **Última atualização:** 2026-04-30 — Epic 9 100% Done, pipeline de vídeo funcional, UX de aprovação completa

### ⚡ DECISÃO PARA PRÓXIMA SESSÃO

**Epic 9 CONCLUÍDO.** Produto está feature-complete para o MVP. Próximo foco: **lançamento**.

**Opção A — TWA Google Play (aquisição passiva)**
- Empacotar PWA atual como TWA (Trusted Web Activity) — 1–2 semanas dev
- Canal de aquisição passivo ativo desde o lançamento
- Pré-requisito: Google Play Console + chave de assinatura

**Opção B — Analytics de uso (obrigatório antes de qualquer escala)**
- 5 eventos: `post_created | post_approved | post_published | upgrade_clicked | churn`
- Dashboard mínimo para taxa de ativação + NPS
- Sem isso: não há como saber se âncoras estão ativando

**Opção C — Âncoras de lançamento (maior ROI imediato)**
- 3 profissionais: 1 empreiteiro + 1 arquiteto + 1 paisagista
- Onboarding com resultado visível em 48h
- Oferta: 3 meses grátis + R$30/cliente indicado

**Recomendação @aios-master:** Sequência ideal: B → C → A (medir antes de escalar).

---

### 1. Epic 9 — Formatos & Estratégias Instagram
- [x] **Story 9.1** — Seletor de Formato + Sub-estratégia (4 formatos, SubStrategySelector) ✅ Done (2026-04-29)
- [x] **Story 9.2** — Skill Library Copywriter (23 prompts STRATEGY_PROMPTS, 84 testes) ✅ Done (2026-04-29)
- [x] **Story 9.3** — Upload por Formato (UploadScreen 4 modos, backend video, R2 dinâmico, 48 testes) ✅ Done (2026-04-29)
- [x] **Story 9.4** — Publicação de Vídeo (Reels + Story via Meta API assíncrona) ✅ Done (2026-04-30)

**Backlog Story 9.3:** Validação MIME explícita para carousel no backend (concern LOW do @qa)

### 2. TWA Google Play ← SE OPÇÃO B
- [ ] Criar projeto na Google Play Console
- [ ] Configurar TWA (Trusted Web Activity) empacotando a PWA atual
- [ ] Submeter para review (3–7 dias úteis)
- [ ] Publicar — canal de aquisição passivo ativo desde o lançamento

### 3. Analytics de uso — obrigatório antes do lançamento
- [ ] Instrumentar 5 eventos: `post_created` | `post_approved` | `post_published` | `upgrade_clicked` | `churn`
- [ ] Dashboard mínimo para acompanhar taxa de ativação + NPS

### 4. Landing page de lançamento
- [ ] Demo estática do produto (sem OAuth)
- [ ] Galeria de 3 cases reais (1 por nicho — construção / arquitetura / paisagismo)
- [ ] Ancoragem de preço: "vs R$800+/mês de social media"
- [ ] Stripe link direto — sem Hotmart
- [ ] Decisão final de preço: R$67 ou R$97 (A/B por canal)

### 5. Âncoras de lançamento
- [ ] Identificar 3 profissionais: 1 empreiteiro + 1 arquiteto + 1 paisagista
- [ ] Onboarding do âncora: resultado visível em 48h, sem script de venda
- [ ] Oferta: 3 meses grátis + R$30/cliente indicado

### 6. Meta App Review ✅ SUBMETIDO (aguardando análise Meta)
- [x] Formulário completo preenchido (ícone, privacy, terms, categoria, permissões, dados)
- [x] Screencast OAuth gravado e enviado em todas as permissões
- [x] Conta de teste criada: `matheusfontanellaaugusto+metareview@gmail.com` / `MetaReview2026!`
- Submission ID: `14468890472358828`
- Prazo estimado Meta: 1–4 semanas após envio

### Backlog Técnico (post-lançamento)
- WebSocket (substituir polling de 5s)
- StreakBar (endpoint `/api/streak` não construído — mock hardcoded no frontend)
- OpenClaw/WhatsApp — exploração pós-Meta Review
- Carousel MIME validation no backend (`content_type == "carousel"` rejeitar `video/*`)
- Monorepo AutoPost: avaliar mover backend/ + frontend/ para mesmo repo

## ⚠️ Pendências técnicas

| Item | Descrição | Prioridade |
|------|-----------|------------|
| **Meta App Review** | Formulário 90% preenchido — falta screencast e envio final | 🔴 Alta |
| **Mover frontend para `autopost/frontend/`** | Estrutura atual: pasta irmã fora do projeto | 🟡 Média |
| **Token Meta (60 dias)** | Renovação manual via `/meta/status` | 🟢 Baixa (v1.1) |

---

## ✅ O que está implementado (código)

| Epic | Story | O que entregou | Testes | Deploy |
|------|-------|---------------|--------|--------|
| **Epic 1** | 1.1 | Railway + Supabase + Redis + R2 — infra base | — | ✅ Railway |
| **Epic 1** | 1.2 | FastAPI + Auth JWT via Supabase (`/auth/*`) | ✅ | ✅ Railway |
| **Epic 1** | 1.3 | Multi-tenancy + RLS no banco | ✅ | ✅ Supabase |
| **Epic 1** | 1.4 | Pipeline Celery (4 tasks encadeadas) | ✅ | ✅ Railway |
| **Epic 2** | 2.1 | Agente Analista — Claude Haiku com visão | ✅ 9 testes | ✅ Railway |
| **Epic 2** | 2.2 | Agente Copywriter — Claude Sonnet | ✅ 10 testes | ✅ Railway |
| **Epic 2** | 2.3 | Agente Designer — Pillow + R2 upload | ✅ 9 testes | ✅ Railway |
| **Epic 2** | 2.4 | Agente Publicador — Meta Graph API | ✅ 10 testes | ✅ Railway |
| **Epic 2** | 2.5 | Agente Onboarding — Claude Sonnet + Redis | ✅ 13 testes | ✅ Railway |
| **Epic 2** | 2.6 | API Conteúdo — `POST /content-requests`, aprovação, rejeição | ✅ 11 testes | ✅ Railway |
| **Epic 5** | 5.1 | Edição Inline da Legenda (PATCH /content-requests/{id}) | ✅ 30 testes | ✅ Railway |
| **Epic 5** | 5.2 | Retry: Nova Versão (POST /retry, task retry_generate_copy) | ✅ 30 testes | ✅ Railway |
| **Epic 5** | 5.3 | Menu de Intenção (content_type, IntentMenu, badge) | ✅ 30 testes | ✅ Railway |
| **Epic 6** | 6.4 | Pipeline multi-foto: análise enriquecida, retry approaches, before_after, carousel | ✅ +353 testes | ✅ Pushed |
| **Epic 6** | 6.5 | CaptionEditor botão editar sempre visível (UX fix) | ✅ WAIVED | ✅ Pushed |
| **Epic 7** | 7.1 | Agente @security (Sage) — OWASP, STRIDE, secrets-check, RLS review | ✅ WAIVED (AIOX) | ✅ AIOX repo |
| **Epic 7** | 7.2 | @security dep-audit — pip-audit Python + GitHub Actions CI/CD (backend + frontend) | ✅ PASS | ✅ AIOX repo |
| **Epic 2** | 2.7 | OAuth Meta — `/meta/connect`, `/meta/callback`, `/meta/status` | ✅ 10 testes | ✅ Railway |
| **Epic 2** | 2.8 | Segundo Cérebro Local — writer/reader, PADROES, INSIGHTS | ✅ | ✅ Railway |
| **Epic 3** | 3.1 | Estrutura Global + Bootstrap (Obsidian vault) | ✅ | ✅ |
| **Epic 3** | 3.2 | Motor de Promoção de Padrões (Celery Beat mensal) | ✅ | ✅ Railway |
| **Epic 3** | 3.3 | Integração AIOS Agents com Cérebro Global | ✅ | ✅ |
| **Epic 4** | 4.1 | Setup Next.js 14 + Vercel + Autenticação | **Done** | ✅ Vercel |
| **Epic 4** | 4.2 | Dashboard Principal + Fila de Aprovação | **Done** | ✅ Vercel |
| **Epic 4** | 4.3 | Preview do Post (estilo Instagram) | **Done** | ✅ Vercel |
| **Epic 4** | 4.4 | Onboarding Wizard (conectar Instagram) | **Done** | ✅ Vercel + Railway |
| **Epic 4** | 4.5 | Histórico de Posts + Métricas | **Done** | ✅ Vercel |
| **Epic 4** | 4.6 | PWA + Notificações Push | **Done** | ✅ Vercel |
| **Epic 9** | 9.1 | Seletor de Formato + Sub-estratégia (content_type carousel/reels/story, SubStrategySelector) | ✅ | ✅ Railway+Vercel |
| **Epic 9** | 9.2 | Skill Library Copywriter — 23 prompts STRATEGY_PROMPTS calibrados por formato+estratégia | ✅ 84 testes | ✅ Railway |
| **Epic 9** | 9.3 | Upload por Formato — UploadScreen 4 modos, backend video/mp4+mov, extensão R2 dinâmica | ✅ 48 testes | ✅ Railway+Vercel |
| **Epic 9** | 9.4 | Publicação de Vídeo — Reels (media_type=REELS, polling 30×10s) + Story (IMAGE/VIDEO auto-detect) | ✅ | ✅ Railway |

| **Epic 10** | 10.1 | Campo "Música de fundo" no ContextModal — merge em user_context antes do envio | ✅ | ✅ Vercel |
| **Epic 10** | 10.2 | Transcrição de vídeo via Gemini (app/tools/transcription.py plugável) — frames+áudio em paralelo | ✅ fallback | ✅ Railway |
| **Epic 12** | 12.1 | Onboarding momento wow — primeiro post em 2 minutos | ✅ | ✅ Railway+Vercel |
| **Epic 12** | 12.2 | Upload de vídeo robusto — compressão CRF 28, badge, dicas de gravação | ✅ 7 testes | ✅ Railway+Vercel |
| **Epic 12** | 12.3 | Transcrição automática de áudio em Reels — filtro 20 palavras, injeção no copywriter | ✅ 17 testes | ✅ Railway |
| — | — | **Qualidade de copy**: MAX_CAPTION 400→1500 chars, storytelling, parágrafos | — | ✅ Railway |
| — | — | **Caixa de contexto**: 200→500 chars, rows 3→5 | — | ✅ Vercel |

| **Epic 13** | 13.1 | `exa_search.py` — search_exa_trends(), Redis cache 24h, fallback gracioso | ✅ 9 testes | ✅ Railway |
| **Epic 13** | 13.2 | Exa context no copywriter — `#TENDENCIAS_DO_NICHO`, migration `exa_trends_context` | ✅ 5 testes | ✅ Railway |
| **Epic 13** | 13.3 | Hashtag extraction do Exa — `#HASHTAGS_EM_ALTA`, explicit + bullet-derived tags | ✅ 5 testes | ✅ Railway |
| **Epic 13** | 13.4 | Celery Beat weekly intel, WeeklyContext model, `GET /insights/weekly`, `WeeklyInsightCard.tsx` | ✅ 13 testes | ✅ Railway |

| **Epic 14** | 14.1 | Regra Zero + Sinais Algorítmicos no Copywriter | ✅ | ✅ Railway |
| **Epic 14** | 14.2 | Sequência de Ataque Editorial para Clientes Novos — `attack_sequence_position` nos clients, lógica de seleção sequencial no copywriter | ✅ testes | ✅ Railway |
| **Epic 14** | 14.3 | Streak Semanal Funcional — `GET /insights/streak`, mock removido, 11 testes | ✅ 11 testes | ✅ Railway+Vercel |

**Total de testes:** ~230 passando (backend)  
**URL da API:** `https://espectra-api-production.up.railway.app`

---

## 🏆 Validação em Produção (2026-04-17)

Pipeline completo executado com sucesso — foto → análise → copy → design → aprovação → publicação:
- Post publicado: https://www.instagram.com/p/DXQPdciGRrj/
- Instagram: @espectra.tes
- Copy gerado automaticamente pelo Claude Sonnet
- Imagem 1080x1080 processada pelo Designer (Pillow)

**Fixes aplicados em produção:**
- NullPool para Celery workers (asyncpg event loop conflict)
- Download R2 via boto3 + presigned URL para Instagram
- Polling status_code=FINISHED antes de publicar
- instagram_basic scope obrigatório no OAuth
- MAX_TOKENS 1024 + sanitização markdown no JSON

---

## ✅ Bloqueios — Todos resolvidos

| Item | Resolvido em |
|------|-------------|
| Credenciais Meta no `.env` local | 2026-04-17 |
| Variáveis Meta no Railway | 2026-04-17 |
| Migration `d5e2f9a3c1b7` aplicada | 2026-04-17 |
| `python-multipart` adicionado | 2026-04-17 |
| API Active em produção | 2026-04-17 |

---

## ⚠️ Pendências / Standby

| Item | Descrição | Quando tratar |
|------|-----------|--------------|
| **Meta App Review** | `instagram_content_publish` requer aprovação Meta para produção ampla. MVP: clientes como Testers (sem review). Iniciar revisão em paralelo com deploy — prazo: 1–4 semanas. | Iniciar agora |
| **Token Meta (60 dias)** | Renovação manual via `/meta/status`. Automação: v1.1 | v1.1 |

---

## ⏭️ Próximos passos

**Decisão tomada:** Epic 4 — Frontend Dashboard

### Em execução — Epic 4: Frontend (Next.js + Tailwind → Vercel)
- **Story 4.1** ✅ Done: Setup Next.js + Vercel + Login/Register
- **Story 4.2** ✅ Done: Dashboard + Fila de Aprovação com polling
- **Story 4.3** ✅ Done: Preview do Post estilo Instagram + PostMetrics + SkeletonCard
- **Story 4.4** ✅ Done: Onboarding Wizard 3 etapas + OAuth Meta redirect
- **Story 4.5** ✅ Done: Histórico de Posts + Métricas
- **Story 4.6** ✅ Done: PWA + Notificações Push

**Epic 4 CONCLUÍDO** — MVP frontend completo e em produção na Vercel.

Stories em: `docs/stories/epic-4-frontend/`

### Backlog v1.1
- Renovação automática do token Meta
- Agente Carrossel (+R$29/mês)
- WebSocket (substituir polling)

---

## 🏗️ Arquitetura em produção

```
Railway (api + worker + beat)
  ↕
Supabase (PostgreSQL multi-tenant + Auth JWT)
  ↕
Redis (filas Celery + cache onboarding)
  ↕
Cloudflare R2 (storage de imagens)
  ↕
Claude Haiku (análise foto + design)
Claude Sonnet (copy + onboarding)
  ↕
Meta Graph API (Instagram + Facebook)
```

**Pipeline completo:**
```
foto → analyze_photo → generate_copy → prepare_design → [aprovação] → publish_post → collect_metrics (24h)
```

**Endpoints disponíveis:**
```
GET  /health
POST /auth/register  |  POST /auth/login  |  POST /auth/refresh  |  GET /auth/me
POST /onboarding/start  |  POST /onboarding/message  |  GET /onboarding/status
POST /content-requests  |  GET /content-requests  |  GET /content-requests/{id}
POST /content-requests/{id}/approve  |  POST /content-requests/{id}/reject
GET  /meta/connect  |  GET /meta/callback  |  GET /meta/status
```

---

## ⏸️ Histórico de Pausas

| Data | Motivo | Resolvido |
|------|--------|-----------|
| 2026-04-14 | Story 2.7 pendente de configuração Meta | ✅ Resolvido em 2026-04-17 |
| 2026-04-17 | Queda de energia — perda de contexto | ✅ Recuperado via `#autopost-status` |
