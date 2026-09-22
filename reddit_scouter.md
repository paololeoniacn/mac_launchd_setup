Assunzione: il progetto va in `~/llm-trends/`, Python via `uv`, web search tramite Reddit JSON API (no auth needed) + HN Algolia API + arxiv API. L'LLM locale (Qwen2.5-14B su porta 8080) sintetizza i trend e genera il thread HTML. launchd lancia lo script due volte al giorno.Tutto il progetto è sopra. Ecco il flusso completo e come metterlo in moto:

---

**Architettura in 3 passi**

`fetch.py` chiama tre API senza auth: Reddit JSON (`/hot.json`), HN Algolia (filtra le ultime 24h), arxiv REST (Atom XML, ultimi paper per 3 query). Filtra già in ingresso i post con meno di 50 upvote. → `rank.py` costruisce un prompt con al massimo 60 item e chiama Qwen2.5-14B su porta 8080 con `temperature=0`, chiedendo JSON puro con schema fisso — nessun guardrail testuale, il controllo è tutto nel parsing + retry. → `render.py` genera `output/latest.html` (thread stile dark-Reddit con colori per categoria) e `output/latest.json`, più una copia archiviata con timestamp.

**Installazione**

```bash
cp -r llm-trends ~/llm-trends
cd ~/llm-trends
bash install.sh          # sostituisce YOUR_USERNAME nel plist, uv sync, launchctl load
```

**Test immediato** (con mlx_lm.server già attivo su 8080):
```bash
uv run ~/llm-trends/run.py
open ~/llm-trends/output/latest.html
```

**Log**
```bash
tail -f ~/llm-trends/logs/trends.log
```

**Nota su launchd vs cron**: il plist usa `StartCalendarInterval` che, a differenza di cron, non recupera i run persi mentre il Mac era spento. Se vuoi il run-at-wake aggiungi `<key>RunAtLoad</key><true/>` nel plist.