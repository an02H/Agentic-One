# Agentic-One 🤖

Écosystème d'agents IA spécialisés, auto-outillants, déployés sur infrastructure locale (Docker/ESXi).

**VM** : `192.168.10.216` (an02@docker) · **Stack** : Rust · Python · n8n · Ollama · ChromaDB

---

## Démarrage rapide

```bash
# 1. Cloner sur la VM
git clone https://github.com/an02H/Agentic-One.git && cd Agentic-One

# 2. Optimiser l'OS
sudo bash scripts/install_ai_core.sh && sudo reboot

# 3. Auditer
bash scripts/audit_ai_core.sh

# 4. Tester le chat via n8n
curl -X POST http://192.168.10.216:5678/webhook/chat-gateway \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello Mistral"}'
```

## Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Vue d'ensemble technique et flux de données |
| [SETUP_GUIDE.md](docs/SETUP_GUIDE.md) | Guide d'installation pas-à-pas |
| [N8N_WORKFLOWS.md](docs/N8N_WORKFLOWS.md) | Configuration des workflows n8n |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Résolution des problèmes courants |

## Services

| Service       | Port  | Technologie            |
|---------------|-------|------------------------|
| n8n Gateway   | 5678  | Orchestration / Vault  |
| Portainer     | 9000  | Gestion Docker         |
| Lab Monitor   | 7070  | Rust / Actix-web       |
| Ollama (LLM)  | 11434 | Interne Docker         |

## Règle de sécurité fondamentale

> **Aucune clé API en clair dans le code.** Tout appel externe passe par n8n (:5678).
