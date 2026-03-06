# N8N WORKFLOWS — Agentic-One

## Principe de sécurité

n8n est le **seul composant autorisé** à router les requêtes entre l'UI et les services backend. Les agents externes n'ont aucune visibilité sur les endpoints internes ni sur les clés API.

```
UI → POST /webhook/chat-gateway → n8n → Ollama (Bearer injecté) → Réponse
```

---

## Workflow 1 : Chat Gateway (RUN)

**Fichier** : `config/n8n-gateway.json`

**Import** : n8n UI → Nouveau Workflow → ⋮ → Import from JSON

### Flux

```
[Webhook POST /chat-gateway]
        │ { "prompt": "..." }
        ▼
[HTTP Request → Ollama :11434]
        │ { "model": "mistral-nemo", "prompt": ..., "stream": false }
        ▼
[Format Response]
        │ { "response": "...", "model": "..." }
        ▼
[Retour HTTP au client]
```

### Test

```bash
curl -X POST http://192.168.10.216:5678/webhook/chat-gateway \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Réponds en une phrase : qu est-ce que Mistral ?"}'
```

---

## Workflow 2 : RAG Trigger (LEARN) — À créer manuellement

Ce workflow surveille un dossier et déclenche l'ingestion automatiquement.

### Nœuds à configurer

1. **Trigger** : Webhook POST `/rag-ingest`
2. **SSH Execute** : Commande `python3 /home/an02/Agentic-One/services/brain/ingest.py`
3. **Respond to Webhook** : `{ "status": "ingestion_started" }`

---

## Credentials Vault — Référence

| Credential Name   | Type         | Valeur (saisir dans n8n, jamais en code) |
|-------------------|--------------|------------------------------------------|
| Ollama Local Core | HTTP Request | http://192.168.10.216:11434              |
| ChromaDB Local    | HTTP Request | http://192.168.10.216:8000               |
| Cloud LLM Token   | Header Auth  | Bearer XXXXX (saisir dans n8n Vault)     |

---

## Variables d'environnement n8n (Docker)

À configurer via Portainer sur le conteneur n8n :

```
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=REMPLACER_VAULT_N8N
WEBHOOK_URL=http://192.168.10.216:5678
```

> ⚠️ Ne jamais stocker ces valeurs dans le repo Git. Utiliser le Vault n8n ou des variables Docker Compose.
