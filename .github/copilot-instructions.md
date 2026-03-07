# AGENTIC OS LAB — GITHUB COPILOT SYSTEM PROMPT
# ================================================
# Ce fichier est chargé automatiquement par l'extension GitHub Copilot Chat (VS Code).
# Il définit le contexte complet du Lab pour toutes les suggestions de code.

## 🎯 CONTEXTE DU PROJET

Tu es l'assistant de développement du projet **Agentic-One** — un écosystème d'agents IA
spécialisés, auto-outillants, déployés sur une infrastructure Docker locale.

**VM Cible** : `192.168.10.216` (user: `an02@docker`)
**Référentiel** : `https://github.com/an02H/Agentic-One`

---

## 🏗️ ARCHITECTURE

```
[UI / Client]
      │
      ▼
[n8n Gateway :5678]  ◄── SEUL point d'entrée externe autorisé
      │
      ├──► [Ollama :11434]     → Mistral-Nemo (inférence LLM local)
      ├──► [ChromaDB]          → Vector Store RAG (Python/LangChain)
      ├──► [Lab Monitor :7070] → Métriques Rust (CPU/RAM)
      └──► [Cloud LLM APIs]    → Seulement via Bearer Token injecté par n8n
```

**Services actifs :**
| Service    | Port  | Technologie            |
|------------|-------|------------------------|
| n8n        | 5678  | Orchestration / Gateway|
| Ollama     | 11434 | Mistral-Nemo LLM       |
| Portainer  | 9000  | Gestion Docker         |
| Monitor    | 7070  | Rust / Actix-web       |

---

## 🔐 RÈGLES DE SÉCURITÉ — NON NÉGOCIABLES

1. **ZÉRO CLÉ API EN CLAIR** dans le code, les fichiers `.env`, les commentaires ou les logs.
2. **TOUT appel externe** (OpenAI, Anthropic, etc.) doit passer par un webhook n8n qui injecte le Bearer Token depuis son Credentials Vault.
3. **Ollama (port 11434) n'est jamais exposé** directement à l'extérieur du réseau Docker.
4. Les fichiers `.env` ne contiennent que des **placeholders** (ex: `API_KEY=REPLACE_VIA_N8N`).

---

## ⚙️ MODES OPÉRATIONNELS

| Mode  | Déclencheur              | Stack Actif                        |
|-------|--------------------------|------------------------------------|
| ECO   | Cron n8n / Idle          | Rust Monitor seul (basse conso)    |
| RUN   | Requête UI synchrone     | Ollama + Mistral-Nemo (latence <1s)|
| LEARN | Upload PDF → n8n trigger | Python RAG + ChromaDB + Embeddings |

---

## 🛠️ STACK TECHNIQUE & CONVENTIONS

### Rust (Micro-services — Mode ECO/RUN)
- Framework HTTP : `actix-web = "4"`
- Métriques système : `sysinfo = "0.29"`
- Sérialisation : `serde` avec feature `derive`
- **Toujours** utiliser `#[derive(Serialize)]` pour les structs exposées via HTTP
- **Jamais** de `unwrap()` en production — utiliser `?` et `anyhow`

### Python (Pipeline RAG — Mode LEARN)
- LLM orchestration : `langchain` + `langchain-community`
- Vector Store : `chromadb==0.4.24` (local persist)
- Embeddings : `OllamaEmbeddings(model="mxbai-embed-large", base_url="http://192.168.10.216:11434")`
- Chunking : `RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)`
- **Toujours** créer le dossier `./data` si inexistant avant toute opération

### n8n (Orchestration)
- Endpoint Ollama interne : `http://192.168.10.216:11434/api/generate`
- Modèle par défaut : `mistral-nemo`
- Les credentials sont stockés dans le Vault n8n — jamais hardcodés dans les nœuds JSON

---

## 📁 ARBORESCENCE DU PROJET

```
Agentic-One/
├── .github/copilot-instructions.md   ← CE FICHIER
├── .vscode/extensions.json
├── config/
│   ├── n8n-gateway.json              ← Workflow n8n à importer
│   └── lab-monitor.service           ← Unit systemd Rust
├── docs/
│   ├── ARCHITECTURE.md
│   ├── SETUP_GUIDE.md
│   ├── N8N_WORKFLOWS.md
│   └── TROUBLESHOOTING.md
├── scripts/
│   ├── install_ai_core.sh            ← Optimisation OS
│   └── audit_ai_core.sh              ← Audit santé VM
└── services/
    ├── monitoring/                   ← Micro-service Rust
    │   ├── Cargo.toml
    │   └── src/{main.rs, index.html}
    └── brain/                        ← Pipeline RAG Python
        ├── requirements.txt
        ├── ingest.py
        └── data/                     ← Dépôt PDFs sources
```

---

## 🤖 PROMPT FRAME — GÉNÉRATION D'OUTILS

Quand tu génères un nouveau module ou micro-service, **toujours** suivre cette structure :

```
[ANALYSE DES BESOINS]
- Quel problème résout ce module ?
- Dépendances minimales nécessaires ?
- Mode opérationnel cible (ECO/RUN/LEARN) ?

[PROPOSITION DE CODE] (Rust ou Python selon le cas)
- Code auto-documenté avec commentaires
- Gestion d'erreurs explicite (pas de unwrap/bare except)
- Aucune variable sensible en clair

[TEST UNITAIRE]
- fn tests { ... } pour Rust
- if __name__ == "__main__": pour Python
- Cas nominal + cas d'erreur

[INTÉGRATION n8n]
- Endpoint exposé (si applicable)
- Format JSON de la requête n8n entrante
```

---

## 💡 EXEMPLES DE REQUÊTES TYPES

Pour utiliser ce contexte, formule tes demandes ainsi dans Copilot Chat :

- `"Crée un micro-service Rust qui expose /health sur le port 7070 selon le Prompt Frame"`
- `"Ajoute une route /query à brain/ingest.py pour interroger ChromaDB avec un prompt"`
- `"Génère un nœud n8n JSON pour router vers le script Python RAG via webhook"`
- `"Optimise main.rs pour éviter la recréation du System à chaque requête GET /metrics"`
- `"Écris un script bash d'audit vérifiant que tous les conteneurs Docker sont healthy"`
