# macOS Automation Workspace

## Scopo
Questo workspace aiuta a creare, gestire e monitorare **launchd agents** per task automatici su macOS (Apple Silicon). Il flusso tipico: definire un task → generare il `.plist` → installarlo in `~/Library/LaunchAgents/` → verificarne lo stato.

---

## Struttura del workspace

```
mac_launchd_setup/
├── CLAUDE.md                            # questo file
├── handle_project.sh                    # entry point centralizzato (install/dashboard/...)
├── .gitignore                           # ignora .DS_Store e dashboard-data.js (generato)
├── plists/
│   └── local.brew.update.plist.template # template plist con placeholder (__SCRIPT__/__LOG__/__ERR__)
└── scripts/
    ├── install.sh                       # genera il plist coi path reali e carica l'agent
    ├── brew-update.sh                   # task: brew update + upgrade cask claude-code + toast
    └── dashboard/
        ├── dashboard.html               # dashboard di stato
        └── refresh-dashboard.sh         # rigenera dashboard-data.js dallo stato launchd + apre
```

**Portabilità (repo pubblico):** nessun path utente è hardcoded nei file versionati.
Gli script usano `$HOME` e ricavano la propria posizione; il plist — che launchd vuole
con path **assoluti** e non espande `~` — è un *template*, e `install.sh` risolve i path
reali al momento dell'installazione. I log e il target `~/Library/LaunchAgents/` sono
sempre relativi all'utente corrente.

---

## Gestione centralizzata: `handle_project.sh`

Tutte le operazioni passano dal dispatcher alla root del repo:

```bash
./handle_project.sh install     # genera il plist coi path locali e carica l'agent
./handle_project.sh dashboard   # rigenera lo stato live e apre la dashboard nel browser
./handle_project.sh status      # stato degli agent local.* (launchctl)
./handle_project.sh logs        # tail -f del log di local.brew.update
./handle_project.sh run         # esegue subito brew-update (update + upgrade + toast)
./handle_project.sh uninstall   # scarica e rimuove l'agent
./handle_project.sh help        # elenco comandi
```

---

## Come creare un nuovo task

### 1. Script del task in `scripts/`

Logica in bash con **path assoluti** (`/opt/homebrew/bin/brew`, `/usr/bin/osascript`, …)
e `$HOME` per i percorsi utente (mai il nome utente hardcoded). Log persistenti in
`$HOME/Library/Logs/<label>.log`.

### 2. Template plist in `plists/`

Crea `plists/<label>.plist.template` con i placeholder che `install.sh` sostituisce:
`__SCRIPT__` (path assoluto dello script), `__LOG__`, `__ERR__`. `Label` = `<label>`,
`ProgramArguments` = `/bin/bash` + `__SCRIPT__`.

### 3. Installa

```bash
./handle_project.sh install
```

`install.sh` risolve i path reali dal template, scrive il plist in
`~/Library/LaunchAgents/` e (ri)carica l'agent.

### 4. Verifica

```bash
./handle_project.sh status
# Colonne: PID | ExitCode | Label
# PID != '-' → in esecuzione; ExitCode 0 → ultima run OK
```

### 5. Dashboard

```bash
./handle_project.sh dashboard
```

`refresh-dashboard.sh` scansiona `~/Library/LaunchAgents/local.*.plist`, ricava
schedule/exit code/ultima run e scrive `scripts/dashboard/dashboard-data.js`
(`window.TASKS = [...]`), poi apre `dashboard.html`. La pagina carica quel file via
`<script src>` (funziona su `file://`, dove `fetch` sarebbe bloccato dal CORS).
`dashboard-data.js` è generato e in `.gitignore`; in un clone fresco `open dashboard.html`
mostra l'array di fallback statico finché non lanci `dashboard`.

---

## Comandi utili (riferimento rapido)

| Operazione | Comando |
|---|---|
| Installare / ricaricare | `./handle_project.sh install` |
| Rimuovere l'agent | `./handle_project.sh uninstall` |
| Stato di tutti i local.* | `./handle_project.sh status` |
| Aprire la dashboard | `./handle_project.sh dashboard` |
| Log in tempo reale | `./handle_project.sh logs` |
| Eseguire subito il task | `./handle_project.sh run` |
| Avviare/fermare (launchctl) | `launchctl start\|stop <label>` |

---

## Regole di naming

- Label: `local.<categoria>.<azione>` → es. `local.brew.update`, `local.git.fetch`
- File plist: `<label>.plist` → es. `local.brew.update.plist`
- Log: `~/Library/Logs/<label>.log` / `.err` (persistenti tra reboot, preferiti a `/tmp/`)

---

## PATH in launchd

launchd ha un `$PATH` minimale. Usa **sempre percorsi assoluti**:

- Homebrew (Apple Silicon): `/opt/homebrew/bin/`
- Python (uv): `~/.local/bin/uv` o il path del virtualenv
- Shell: `/bin/bash -c "..."` oppure `/bin/zsh -c "..."`

---

## Cosa chiedere a Claude in questo workspace

- *"Crea un task che esegue X ogni giorno alle Y"* → script in `scripts/` + template in `plists/`
- *"Installa il task local.foo.bar"* → `./handle_project.sh install`
- *"Aggiorna la dashboard"* → `./handle_project.sh dashboard`
- *"Il task local.brew.update ha exit code 1, cosa è andato storto?"* → debug (`./handle_project.sh logs`)
- *"Elenca tutti i task attivi"* → `./handle_project.sh status`

---

## Note macOS-specifiche

- Se il Mac è **spento** all'orario schedulato, launchd **non recupera** il task. Aggiungere `StartInterval` come fallback se serve resilienza.
- I task in `~/Library/LaunchAgents/` girano come **utente corrente** — non hanno privilegi root. Per task di sistema usa `/Library/LaunchDaemons/` (richiede sudo).
- Su macOS Ventura+ alcuni path (Desktop, Documenti, ecc.) richiedono **Full Disk Access** in Impostazioni di Sistema → Privacy.
