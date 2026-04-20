# game-engineering-blog (monorepo root)

Blog de engenharia de games em duas partes: uma API PHP pura e um frontend estático HTML/CSS/JS. Não há framework, não há build step. O CMS é um projeto separado (Windows Forms C#) que consome a mesma API.

## Repositórios do ecossistema

| Projeto | Repo | Descrição |
|---------|------|-----------|
| `api/` | game-engineering-blog-api | REST API PHP — backend único |
| `site/` | game-engineering-blog-web | Frontend estático |
| `CMS/` | game-engineering-blog-cms | Windows Forms C# — painel admin |

## Hosts de produção

| Serviço | URL |
|---------|-----|
| Frontend | `https://gameng.io` |
| API | `https://api.gameng.io` |
| Hospedagem | Hostinger (API + site) |

---

## api/ — REST API PHP

**Stack:** PHP 8.2+, MySQL, sem framework. Router customizado OO. JWT manual (HS256).

### Estrutura

```
api/
├── index.php              Router central
├── .htaccess              Redireciona tudo para index.php
├── src/
│   ├── Controllers/       PostController, CommentController, TagController,
│   │                      AuthController, NewsletterController, StatsController,
│   │                      ResourceController
│   ├── Models/            Post, Comment, Tag, User, Newsletter, Stats
│   └── Core/
│       ├── Database.php   PDO Singleton
│       ├── Router.php     HTTP method + rota → controller@method
│       ├── Auth.php       JWT geração e validação
│       ├── Request.php    Wrapper para $_SERVER, body, query, IP, Bearer
│       └── Response.php   success(), error(), json helpers
├── database/schema.sql    Schema completo — rodar uma vez
├── postman/               Collection + environments local/prod
└── resources/             Imagens enviadas via CMS — servidas estaticamente em /resources/
```

### Rotas públicas

| Method | Route | Descrição |
|--------|-------|-----------|
| GET | /posts | Posts publicados. Query: `?lang=en&tag=slug1,slug2&page=&limit=` |
| GET | /posts/{slug} | Post completo com tags e comentários aprovados. `?lang=en` |
| GET | /posts/{slug}/related | Até 6 posts relacionados — ordenados por sobreposição de tags (desc) depois recência (desc). `?lang=en` |
| GET | /search | Busca por título/excerpt/content. `?q=&lang=&tag=`. Máx 50 |
| POST | /comments | Cria comentário (status: pending) |
| GET | /tags | Lista todas as tags com contagem de posts |
| POST | /auth/login | Retorna JWT (`email` + `password`) |
| POST | /newsletter/subscribe | Inscreve e-mail |
| DELETE | /newsletter/unsubscribe | Cancela via token |
| POST | /views/{slug} | Incrementa view |
| GET | /views/{slug} | Retorna views e likes |
| POST | /likes/{slug} | Incrementa like (1 por IP por post — 409 se já curtiu) |
| GET | /config | Retorna todas as configurações do site como mapa `key → value` |

### Rotas admin (JWT obrigatório)

| Method | Route | Descrição |
|--------|-------|-----------|
| GET | /admin/posts | Todos os posts incluindo drafts. `?status=draft\|published&lang=` |
| GET | /admin/posts/{slug} | Qualquer post + todas as `translations[]` |
| POST | /posts | Cria post. Requer `translations[]` com ao menos `en` |
| PUT | /posts/{slug} | Atualiza metadata e traduções |
| PUT | /posts/{slug}/translations | Upsert de uma tradução específica |
| DELETE | /posts/{slug} | Remove post |
| GET | /admin/comments/pending | Comentários pendentes com contexto do post |
| GET | /comments?post={slug} | Todos os comentários do post (todos os status) |
| PUT | /comments/{id} | Define status: `approved` ou `rejected` |
| DELETE | /comments/{id} | Remove comentário |
| PUT | /config | Atualiza uma ou mais configurações. Body: `{ "theme_primary": "#ff0000" }` |
| GET | /admin/resources | Lista imagens em `resources/[path]`. Query: `?path=` |
| POST | /admin/resources | Upload de imagem (multipart). Query: `?path=` |
| DELETE | /admin/resources | Remove imagem. Query: `?file=caminho/relativo` |

### Formato de resposta

```json
// Sucesso
{ "data": { ... }, "meta": { "page": 1, "total": 42 } }

// Erro
{ "error": "mensagem legível", "code": 404 }
```

### Autenticação JWT

- Header: `Authorization: Bearer <token>` — expiração 24h
- Implementado manualmente em `Core/Auth.php`
- Usuário admin único — inserido direto na tabela `users` com senha bcrypt
- Router rejeita com 401 antes de chegar no controller

### CORS

- `production` → apenas `https://gameng.io`
- outros envs → `*` (desenvolvimento local)
- CMS Windows Forms não envia `Origin` — não é restringido

### Banco de dados

- PDO Singleton, prepared statements em todas as queries
- Collation: `utf8mb4_unicode_ci`
- Tabelas: `posts`, `post_translations`, `comments`, `tags`, `post_tags`, `newsletter`, `views`, `likes`, `users`

### Convenções da API

- Slugs: lowercase, hífens, sem acentos — gerado via `Post::slugify()`
- Unicidade do slug verificada na aplicação (409) antes da constraint do DB
- Datas: UTC, ISO 8601
- Status do post: `draft`, `published`
- Status do comentário: `pending`, `approved`, `rejected`
- Nunca expor stack traces em produção — usar `Response::error()`
- Models possuem as queries; Controllers orquestram

### Variáveis de ambiente (`api/.env`)

```
APP_ENV=local
DB_HOST=localhost
DB_NAME=blog
DB_USER=user
DB_PASS=secret
JWT_SECRET=your_long_secret_key
```

---

## site/ — Frontend estático

**Stack:** HTML5, CSS3, vanilla JS (ES modules). Sem framework, sem build. CDNs: Pico CSS, marked.js, Prism.js.

### Estrutura

```
site/
├── index.html             Home — lista de posts paginada
├── search.html            Resultados de busca
├── 404.html
├── .htaccess              Rewrite /slug → /post/index.html
├── post/index.html        Detalhe do post (lê slug da URL)
├── tag/index.html         Filtro multi-tag (lê tags da URL)
└── assets/
    ├── css/
    │   ├── main.css       Overrides do Pico, variáveis CSS, tema dark
    │   ├── post.css       Layout do post — code blocks, headings
    │   └── components.css Cards, tag pills, paginação, form de comentário
    └── js/
        ├── api.js         Cliente central — todos os fetch passam aqui
        ├── i18n.js        Detecção de idioma, switcher, strings da UI
        ├── render.js      Helpers DOM — renderPostCard(), renderComments(), renderTags()
        └── pages/
            ├── home.js
            ├── post.js
            ├── tag.js
            └── search.js
```

### Roteamento de URLs

| URL | Arquivo | Lê |
|-----|---------|----|
| `gameng.io` | `index.html` | `?page=` |
| `gameng.io/my-post-slug` | `post/index.html` | slug do `location.pathname` |
| `gameng.io/tag/rendering` | `tag/index.html` | tag do `location.pathname` |
| `gameng.io/tag/?tag=a,b` | `tag/index.html` | tags do `?tag=` |
| `gameng.io/search` | `search.html` | `?q=` |

### API client (`api.js`)

Nunca chamar `fetch()` direto nos scripts de página — tudo passa por `api.js`.

```js
export const getPosts({ page, limit, tag, lang })
export const getPost(slug, lang)
export const getTags()
export const searchPosts(query, lang)
export const submitComment({ post_slug, author_name, author_email, content })
export const subscribeNewsletter(email)
export const incrementView(slug)
export const incrementLike(slug)
export const getStats(slug)
```

Base URL: `https://api.gameng.io`. Em dev local (hostname ≠ `gameng.io`): `http://192.168.100.19:8000`.

### Markdown

Conteúdo do post chega como Markdown da API. Renderizado no cliente em `post/index.html` apenas:

```js
document.getElementById('post-content').innerHTML = marked.parse(post.content);
Prism.highlightAll(); // após setar innerHTML
```

Prism autoloader detecta a linguagem por fenced code blocks (` ```cpp `, ` ```glsl ` etc). Linguagens relevantes: `cpp`, `c`, `glsl`, `hlsl`, `wgsl`, `lua`, `python`, `bash`, `json`.

Carregar Prism e marked **apenas** nas páginas que renderizam conteúdo de post.

### Internacionalização

- Idioma padrão: **English (`en`)**
- Secundário: Português (`pt`)
- Preferência em `localStorage` key `lang`, fallback para `en`
- Todas as chamadas de API passam `?lang=` com o idioma atual
- Strings da UI definidas em `i18n.js` — nunca hardcoded no HTML
- Switcher: pill agrupado `[EN|PT]` — idioma ativo com fundo roxo preenchido

### Páginas

**Home** — `GET /posts?lang=&page=&limit=10`. Cards com título, excerpt, tags, data, views. Paginação. 1 AdSense abaixo do header.

**Post detail** — Lê slug do pathname. `GET /posts/{slug}?lang=`. Chama `POST /views/{slug}` ao carregar. Like (409 tolerado), views, comentários aprovados, form de comentário. 1 AdSense entre o conteúdo e os comentários.

**Tag browser** — Lê tags do path ou `?tag=`. Todos os tags via `GET /tags` como pills toggleáveis. URL atualiza via `history.pushState`. `popstate` mantém back/forward. 1 AdSense abaixo do heading.

**Search** — Lê `?q=` ao carregar, submete via `history.pushState`. `GET /search?q=&lang=`. 1 AdSense abaixo do heading.

### AdSense

Máximo 2 unidades por página. Placement manual — desabilitar Auto ads no dashboard.

```html
<!-- No <head> de todas as páginas -->
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=YOUR_CLIENT_ID" crossorigin="anonymous"></script>

<!-- Unidade individual -->
<ins class="adsbygoogle" style="display:block"
  data-ad-client="YOUR_CLIENT_ID" data-ad-slot="YOUR_SLOT_ID"
  data-ad-format="auto" data-full-width-responsive="true"></ins>
<script>(adsbygoogle = window.adsbygoogle || []).push({});</script>
```

Nunca colocar ads dentro do conteúdo do post (entre parágrafos).

### Design visual

Tema dark com personalidade gamedev. Base: Pico CSS dark palette. Overrides em `main.css`:

```css
:root {
  --pico-background-color: #0d0d0f;
  --pico-color: #e2e2e2;
  --pico-primary: #7f6cf5;        /* roxo — acento principal */
  --pico-code-background-color: #1a1a1f;
}
```

Estética técnica e densa — blog para engenheiros de games, não site de marketing.

### Convenções do site

- ES modules em todo lugar — `import/export`, sem variáveis globais exceto CDN libs
- Sem inline styles — apenas classes CSS
- Datas formatadas no cliente via `Intl.DateTimeFormat` a partir de ISO 8601
- Todo fetch deve tratar estado de loading e de erro — nunca deixar a página em branco
- `author_email` coletado no form mas nunca exibido (a API remove das respostas)
- SEO: `<title>`, `<meta description>` e OG tags definidos via JS após fetch dos dados

---

## O que este projeto NÃO faz

- Sem SSR — conteúdo renderizado no cliente (limitação de SEO conhecida e aceita)
- Sem painel web de admin — gerenciado pelo CMS Windows Forms (`CMS/`)
- Deploy do site: upload de arquivos via FTP para o Hostinger (sem CI/CD)
