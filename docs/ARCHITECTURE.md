# ARCHITECTURE — Agentic-One

## Vue d'ensemble

L'Agentic-One Lab est un écosystème d'agents IA spécialisés déployés localement sur une infrastructure Docker/ESXi. L'architecture repose sur **trois principes non-négociables** :

1. **Sécurité by design** — Aucune clé API ne circule en clair. n8n est le seul point de routage vers l'extérieur.
2. **Performance locale first** — Rust pour les micro-services, LLM local (Mistral-Nemo) pour la majorité des opérations.
3. **Scalabilité contrôlée** — Templates ESXi (Golden Images) permettant de cloner des capacités en 30 secondes.

---

## Topologie Réseau

```
[Poste Dev Windows 11]
        │  SSH / VS Code Remote
        ▼
[VM1 : 192.168.10.216 — an02@docker]
        │
        ├── Docker Container : n8n        :5678  ◄── SEUL point d'entrée public
        ├── Docker Container : Ollama     :11434 (interne uniquement)
        ├── Docker Container : Portainer  :9000
        └── Systemd Service : Lab Monitor :7070  (temporaire)
```

## Flux de données sécurisé

```
UI / Agent externe
      │ POST /chat-gateway
      ▼
[n8n :5678]  ←── Credentials Vault (clés API)
      │
      ├── Mode RUN  → Ollama :11434 (mistral-nemo)
      ├── Mode LEARN → Script Python RAG (ingest.py)
      └── Mode ECO  → Cron / Monitoring Rust
```

---

## Composants

### n8n (Control Plane & API Gateway)
- **Rôle** : Point d'entrée unique, routage sécurisé, injection des credentials
- **Port** : 5678
- **Règle** : Tout appel vers un service externe passe obligatoirement par n8n

### Ollama (Moteur d'inférence)
- **Modèle principal** : `mistral-nemo` (inférence chat / agents)
- **Modèle embedding** : `mxbai-embed-large` (RAG vectoriel)
- **Port** : 11434 (interne Docker uniquement)
- **Config clé** : `OLLAMA_NUM_PARALLEL=4`, `OLLAMA_KEEP_ALIVE=15m`

### ChromaDB (Vector Store)
- **Rôle** : Stockage des embeddings pour le pipeline RAG
- **Emplacement** : `services/brain/chroma_db/` (persistant)
- **Usage** : Mode LEARN (ingestion) + Mode RUN (retrieval)

### Lab Monitor Rust (Métriques)
- **Rôle** : Exposition CPU/RAM via HTTP JSON pour le dashboard
- **Port** : 7070 (temporaire — désactivable)
- **Endpoints** : `GET /metrics`, `GET /health`, `GET /`

---

## Modes Opérationnels

| Mode  | Déclencheur              | Stack actif                        | Consommation |
|-------|--------------------------|------------------------------------|--------------|
| ECO   | Cron n8n / Idle          | Rust Monitor seul                  | Basse        |
| RUN   | Requête UI synchrone     | Ollama + Mistral-Nemo              | Haute        |
| LEARN | Upload PDF → n8n trigger | Python RAG + ChromaDB + Embeddings | Maximale     |

---

## Sizing VM

| Ressource | Valeur    | Justification                             |
|-----------|-----------|-------------------------------------------|
| vCPU      | 12        | Parallélisme inférence + système          |
| RAM       | 32 Go     | Mistral 7B (~12 Go) + ChromaDB + overhead |
| Stockage  | 100 Go    | Vector Store NVMe (latence I/O critique)  |
| Swap      | DÉSACTIVÉ | Latence disque incompatible LLM           |
