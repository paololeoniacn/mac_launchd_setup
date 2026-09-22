# llm-trends

Scheduler che 2×/giorno (09:30 e 15:30) raccoglie i 10 trend topic più seri
da r/LocalLLaMA, r/LocalLLM, r/MachineLearning, r/artificial, Hacker News e
arxiv, li sintetizza con il LLM locale (Qwen2.5-14B su porta 8080) e genera
un thread HTML + JSON aggiornati.

## Struttura

```
llm-trends/
├── run.py                          # entrypoint
├── pyproject.toml
├── install.sh                      # installa launchd + deps
├── com.llmtrends.scheduler.plist   # template plist (non modificare)
├── src/
│   ├── fetch.py    # Reddit JSON API + HN Algolia + arxiv REST
│   ├── rank.py     # LLM ranker (temperatura=0, JSON strutturato)
│   └── render.py   # HTML + JSON renderer
├── output/
│   ├── latest.html  ← apri questo nel browser
│   ├── latest.json
│   └── trends_YYYYMMDD_HHMM.{html,json}  ← archivio
└── logs/
    ├── trends.log
    ├── launchd_stdout.log
    └── launchd_stderr.log
```

## Prerequisiti

- macOS (Apple Silicon)
- `uv` installato (`curl -LsSf https://astral.sh/uv/install.sh | sh`)
- `mlx_lm.server` in esecuzione su `localhost:8080` con Qwen2.5-14B-Instruct-4bit

## Installazione

```bash
# 1. Clona / copia il progetto in ~/llm-trends
cp -r . ~/llm-trends
cd ~/llm-trends

# 2. Installa (crea venv, registra launchd)
bash install.sh

# 3. Test immediato
uv run run.py

# 4. Apri il risultato
open output/latest.html
```

## Troubleshooting

**Il LLM non risponde**
```bash
curl http://localhost:8080/v1/models
# se fallisce: mlx_lm.server --model mlx-community/Qwen2.5-14B-Instruct-4bit --port 8080
```

**launchd non parte**
```bash
launchctl list | grep llmtrends
# controlla launchd_stderr.log per errori di path
```

**Reddit ritorna 429**
Reddit limita le richieste senza auth. Lo User-Agent personalizzato aiuta;
se continua, aggiungi un sleep tra le richieste in fetch.py.

**Cambiare orari**
Modifica `StartCalendarInterval` nel plist installato in
`~/Library/LaunchAgents/com.llmtrends.scheduler.plist`, poi:
```bash
launchctl unload ~/Library/LaunchAgents/com.llmtrends.scheduler.plist
launchctl load -w ~/Library/LaunchAgents/com.llmtrends.scheduler.plist
```

## Architettura decisionale

Nessun guardrail nel prompt. Il controllo avviene tramite:
- `temperature=0` per output deterministico e JSON valido
- parsing + retry in `_extract_json()`
- filtri score-based in `fetch.py` (skippa post con <50 upvote)
- il JSON schema nel prompt forza la struttura senza istruire il modello
  a censurare o filtrare contenuti
