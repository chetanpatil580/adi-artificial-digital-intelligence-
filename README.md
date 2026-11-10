# ADI — Artificial Digital Intelligence

ADI is a local-first, all-in-one AI workspace. It combines a streaming chat client, a research and
knowledge base, a VS Code-style code panel, a permission-gated terminal, local files and PC automation
in one dark, professional desktop-style interface.

Everything runs on your machine. There is no hosted account, no telemetry and no hidden automation.
Cloud model calls happen only through provider keys that you add and that are encrypted at rest.

---

## Highlights

- **Chat** — streamed answers, Markdown, syntax highlighting, sources, attachments, edit & regenerate,
  stop, timestamps, tool activity and honest error states. No hidden chain-of-thought is displayed.
- **12 provider adapters** — OpenAI, Anthropic, Google Gemini, OpenRouter, Groq, Together, Mistral,
  DeepSeek, xAI, any OpenAI-compatible endpoint, Ollama and LM Studio.
- **Local-first routing** — Cloud / Local / Auto modes, default-provider preference and automatic
  failover across the providers you configured.
- **Approval-gated computer control** — every command is classified `SAFE`, `CONFIRM` or `BLOCKED`.
  Only allowlisted executables run, risky commands wait for an explicit approval dialog, and each
  decision is written to the audit log.
- **Approved folders only** — ADI reads files only inside folders you explicitly approve (plus its own
  workspace). Path traversal outside those roots is rejected server-side.
- **Local knowledge (RAG)** — deterministic local embeddings over uploads and indexed folders, with
  cited excerpts. No vector database service is involved.
- **Workspace panels** — Projects, Files, Knowledge, Agents, Tasks, Memory, Terminal, Web, Code,
  Tools, System, Providers, Activity and Settings.
- **Permission Center** — switch off terminal, files, web, microphone and other capabilities instantly.
- **API keys** — encrypted with Fernet on the backend; only a masked hint ever reaches the browser.

## Requirements

| Component | Version |
| --- | --- |
| Windows | 10 / 11 (PowerShell 5.1+) |
| Python | 3.10+ (3.12 recommended) |
| Node.js | 18+ (20 LTS recommended) |
| Models | an API key for a cloud provider **or** Ollama / LM Studio for local models |

The app is Windows-first but the backend and frontend are cross-platform; only the helper scripts are
PowerShell.

## Quick start

```powershell
cd "C:\path\to\adi"
.\setup.ps1      # creates backend/.env with a fresh encryption key
.\install.ps1    # Python venv, backend requirements, npm install, backend tests
.\start.ps1      # starts FastAPI on :8000 and Next.js on :3000, opens the browser
```

Stop everything:

```powershell
.\stop.ps1
```

`start.ps1` reuses an already-running backend and refuses to double-start. Logs are written to
`logs/backend.*.log` and `logs/frontend.*.log`.

### Manual start

```powershell
# Terminal 1 - backend
cd backend
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000

# Terminal 2 - frontend
cd frontend
npm run dev
```

Open <http://localhost:3000>. API docs: <http://127.0.0.1:8000/api/docs>.

### First-run checklist

1. Open **API Providers** and add a cloud key, or start Ollama / LM Studio and use **Scan local**.
2. Optionally click **Default** on a provider so Auto mode prefers it.
3. Open **Settings → Permission Center** and review the enabled capabilities.
4. In **Files**, approve any folders ADI may read. Nothing is scanned until you do this.
5. Try a chat, then a safe terminal command such as `python --version`.

## Architecture

```
adi/
  backend/
    app/
      api/routes/        FastAPI routers (chat, providers, terminal, tools, files, rag,
                         memory, agents, projects, tasks, web, settings, permissions,
                         system, audit)
      providers/         Adapter interface + OpenAI-compatible, Anthropic, Gemini + catalog
      services/          Chat orchestration, provider routing, audit, permissions
      terminal/          Command classification and orchestration
      tools/             Allowlist, executor, approvals
      files/             Approved-folder browser, extractors, indexer
      rag/               Deterministic embeddings, chunking, cosine search
      security/          Path guards, Fernet key storage, sanitizers
      database/          SQLAlchemy models, session, first-run seeding
      schemas/           Pydantic request models
    tests/               pytest suite (API + security)
    data/                SQLite DB, uploads, encryption key, workspace (gitignored)
  frontend/
    app/                 Next.js App Router entry + global styles
    components/chat/     Composer, messages, markdown, model selector
    components/shell/    Sidebar, top bar, control panel, palette, approval modal
    components/workspace/ Feature panels
    stores/              Zustand app + chat stores
    lib/                 API client, SSE parser, formatting helpers
```

The chat stream uses server-sent events with a small event contract: `meta`, `status`, `tool`,
`delta`, `done`, `error`. The terminal uses `started`, `chunk`, `approval_required`, `done`, `error`.

## Security model

ADI is designed around visibility and explicit consent.

- **No unrestricted shell access.** Commands are classified before execution. Blocked patterns never
  run; risky commands open an approval dialog with the exact command, working directory and reason.
- **Allowlisted executables and approved roots.** Working directories must be inside the ADI workspace
  or a folder you approved. Paths are normalized and traversal is rejected.
- **No hidden file scanning.** The browser only lists roots you approve. Removal of a root deletes the
  permission row, never your files.
- **No silent microphone or camera.** Voice input is browser speech recognition, triggered by a click,
  and can be disabled in Settings and the Permission Center.
- **No hidden reasoning.** The UI shows status and tool activity, never private chain-of-thought.
- **Keys stay server-side.** Provider keys are encrypted with Fernet, stored in SQLite, never returned
  in plain text, never placed in `NEXT_PUBLIC_*` variables or browser storage.
- **Local rate limit and optional bearer auth.** If you expose the backend beyond localhost, set
  `APP_ACCESS_TOKEN` in `backend/.env` and send `Authorization: Bearer <token>`; otherwise keep the
  default `127.0.0.1` bind.

The audit log records terminal requests, approvals, rejections, provider changes, file access and
settings changes. See the **Activity** panel.

## Configuration

`backend/.env` is generated by `setup.ps1`. All values are optional except the encryption key.

| Variable | Default | Purpose |
| --- | --- | --- |
| `APP_ENV` | `development` | Set `production` to disable reload and tighten behavior |
| `APP_SECRET_KEY` | dev value | Application secret |
| `APP_ENCRYPTION_KEY` | generated | Fernet key for provider API keys |
| `APP_ACCESS_TOKEN` | empty | Optional bearer token for the whole API |
| `DATABASE_URL` | `data/adi.db` | SQLAlchemy database URL |
| `DATA_DIR` | `backend/data` | Database, uploads and workspace location |
| `WORKSPACE_DIR` | `DATA_DIR/workspace` | Default approved root for tools |
| `CORS_ORIGINS` | localhost:3000 | Comma-separated allowed origins |
| `PROVIDER_TIMEOUT` | `90` | Per-request provider timeout (seconds) |
| `COMMAND_TIMEOUT` | `30` | Terminal command timeout (seconds) |
| `MAX_OUTPUT_BYTES` | `65536` | Captured output cap |
| `MAX_UPLOAD_MB` | `25` | Upload size limit |
| `RAG_CHUNK_CHARS` / `RAG_CHUNK_OVERLAP` / `RAG_TOP_K` | `900` / `120` / `6` | Retrieval tuning |

The frontend reads `NEXT_PUBLIC_ADI_API_URL` from `frontend/.env.local` (default
`http://127.0.0.1:8000`). This is a public origin only — never a secret.

## API overview

| Area | Endpoints |
| --- | --- |
| Health | `GET /api/health`, `GET /api/system`, `GET /api/audit` |
| Chat | `POST /api/chat/stream`, `POST /api/chat`, `GET/POST /api/chats`, `PATCH/DELETE /api/chats/{id}` |
| Providers | `GET /api/providers/catalog`, `GET/POST /api/providers`, `PUT/DELETE /api/providers/{id}`, `POST /api/providers/{id}/test`, `GET /api/providers/{id}/models`, `GET /api/models`, `GET /api/local/models` |
| Terminal | `POST /api/terminal/run` (SSE), `GET /api/terminal/history`, `GET /api/terminal/cwd` |
| Tools | `GET /api/tools`, `GET /api/tools/runs`, `GET /api/tools/approvals`, `POST /api/tools/runs/{id}/approve|reject` |
| Files | `GET/POST /api/files/folders`, `DELETE /api/files/folders/{id}`, `GET /api/files`, `/search`, `/preview`, `/content`, `POST /api/files/upload`, `/index` |
| Knowledge | `GET /api/rag/documents`, `POST /api/rag/search`, `DELETE /api/rag/documents/{id}` |
| Workspace | Projects, agents, tasks, memory under `/api/projects`, `/api/agents`, `/api/tasks`, `/api/memory` |
| Web | `POST /api/web/search` (permission-gated) |
| Settings | `GET/PUT /api/settings`, `GET /api/permissions`, `PUT /api/permissions/{key}` |

## Testing

```powershell
cd backend
.\.venv\Scripts\python.exe -m pytest -q

cd ..\frontend
npm run typecheck
npm run build
```

The backend suite covers provider key encryption, provider routing errors, memory CRUD, safe folder
browsing, traversal rejection, indexing/search, uploads, terminal SAFE/CONFIRM/BLOCKED behavior, the
permission gate, settings validation, audit logging and chat/agent endpoints.

## Keyboard shortcuts

| Keys | Action |
| --- | --- |
| `Ctrl + K` | Command palette |
| `Ctrl + N` | New chat |
| `Ctrl + Shift + P` | Command palette |
| `Ctrl + /` or `/` | Focus chat composer |
| `Ctrl + Enter` | Send (always) |
| `Enter` | Send when "Send with Enter" is on |
| `Esc` | Stop streaming / close dialogs |

## Troubleshooting

**"ADI can't reach its local backend."** Start it with `.\start.ps1` or check
`logs/backend.err.log`. Confirm nothing else owns port 8000.

**A provider test fails.** Verify the key and base URL, then retry. For local servers, confirm Ollama
(`http://127.0.0.1:11434`) or LM Studio (`http://127.0.0.1:1234`) is running and exposes an
OpenAI-compatible endpoint.

**A command was blocked.** Blocked commands are refused by design. Risky commands open an approval
dialog; read the reason, then approve or reject. The decision is recorded in Activity.

**Files panel says permission denied.** Enable **Local files** in Settings → Permission Center, then
approve at least one folder.

**Uploads fail.** Check the extension and the `MAX_UPLOAD_MB` limit.

**Ports are busy.** `.\stop.ps1` stops ADI listeners; if another app owns the port, change the port in
`start.ps1` and `NEXT_PUBLIC_ADI_API_URL`.

## Data and reset

- Database: `backend/data/adi.db`
- Encryption key: `backend/data/.encryption_key` (or `APP_ENCRYPTION_KEY`)
- Uploads: `backend/data/uploads`
- Workspace: `backend/data/workspace`

To fully reset ADI, stop it, then remove `backend/data/adi.db`. If you also remove the encryption key,
every stored provider key becomes unrecoverable and must be re-entered. Keep `.encryption_key` if you
want to retain keys.
