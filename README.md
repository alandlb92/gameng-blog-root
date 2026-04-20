# game-engineering-blog

Game engineering blog for [gameng.io](https://gameng.io). Monorepo with three independent projects.

## Projects

| Directory | Description | Stack |
|-----------|-------------|-------|
| `api/` | REST API — single backend for site and CMS | PHP 8.2+, MySQL |
| `site/` | Public frontend | HTML, CSS, vanilla JS |
| `CMS/` | Desktop admin panel | .NET 10 WinForms (Windows) |

## Production

| Service | URL |
|---------|-----|
| Site | `https://gameng.io` |
| API | `https://api.gameng.io` |
| Hosting | Hostinger |

## Quick start

### API

```bash
cd api
composer install
cp .env.example .env   # fill in DB credentials and JWT secret
mysql -u root -p < database/schema.sql
php -S 0.0.0.0:8000
```

### Site

```bash
cd site
npx serve .            # or any static file server
```

The site auto-detects local dev and points to the local API.

### CMS

```bash
cd CMS
dotnet run
```

Requires .NET 10 Desktop Runtime and a running API instance.

## Repository structure

```
game-engineering-blog/
├── api/        PHP REST API
├── site/       Static frontend
├── CMS/        Windows Forms CMS
└── README.md
```

Each project has its own `README.md` with full setup instructions.
