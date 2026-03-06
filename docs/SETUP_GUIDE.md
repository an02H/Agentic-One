# GUIDE DE SETUP — Agentic-One

## Prérequis

- VM Ubuntu 24.04 LTS (12 vCPU / 32 Go RAM) avec Docker installé
- Accès SSH : `ssh an02@192.168.10.216`
- VS Code avec Remote SSH configuré

---

## Étape 1 — Cloner le dépôt sur la VM

```bash
cd /home/an02
git clone https://github.com/an02H/Agentic-One.git
cd Agentic-One
```

## Étape 2 — Optimiser l'OS

```bash
sudo bash scripts/install_ai_core.sh
sudo reboot
```

Après redémarrage, vérifier :

```bash
bash scripts/audit_ai_core.sh
```

Résultat attendu : tous les checks `✅ PASS`, 0 `❌ FAIL`.

## Étape 3 — Configurer Ollama

Via Portainer (http://192.168.10.216:9000) → Conteneur Ollama → Environnement :

```
OLLAMA_HOST=0.0.0.0:11434
OLLAMA_NUM_PARALLEL=4
OLLAMA_MAX_LOADED_MODELS=2
OLLAMA_KEEP_ALIVE=15m
```

Télécharger les modèles (dans la console du conteneur) :

```bash
ollama pull mistral-nemo
ollama pull mxbai-embed-large
```

## Étape 4 — Configurer n8n

1. Ouvrir http://192.168.10.216:5678
2. Créer le compte administrateur initial
3. Activer l'authentification dans Settings
4. Importer le workflow : Menu ⋮ → Import → coller `config/n8n-gateway.json`
5. Activer le workflow (toggle en haut à droite)

**Credentials Vault** (Settings → Credentials → Add) :

| Nom                | Type             | Valeur                              |
|--------------------|------------------|-------------------------------------|
| Ollama Local Core  | HTTP Request     | http://192.168.10.216:11434         |
| ChromaDB Local     | HTTP Request     | http://192.168.10.216:8000          |

## Étape 5 — Déployer le monitoring Rust

```bash
cd /home/an02/Agentic-One/services/monitoring

# Installer Rust si absent
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# Compiler en mode release
cargo build --release

# Installer le service systemd
sudo cp /home/an02/Agentic-One/config/lab-monitor.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable lab-monitor
sudo systemctl start lab-monitor

# Vérifier
sudo systemctl status lab-monitor
```

Dashboard disponible sur : http://192.168.10.216:7070

## Étape 6 — Tester le pipeline RAG

```bash
cd /home/an02/Agentic-One/services/brain

# Installer les dépendances Python
pip3 install -r requirements.txt --break-system-packages

# Déposer des PDFs dans le dossier data/
mkdir -p data
cp /chemin/vers/vos/docs/*.pdf data/

# Lancer l'ingestion
python3 ingest.py
```

## Étape 7 — Tester l'API Gateway n8n

```bash
curl -X POST http://192.168.10.216:5678/webhook/chat-gateway \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Décris l architecture du Lab Agentic-One"}'
```

---

## Vérification finale

| Service   | URL                                  | Statut attendu |
|-----------|--------------------------------------|----------------|
| n8n       | http://192.168.10.216:5678           | Login UI       |
| Portainer | http://192.168.10.216:9000           | Dashboard       |
| Monitoring| http://192.168.10.216:7070           | Dashboard Rust  |
| Ollama    | http://192.168.10.216:11434/api/tags | JSON modèles   |

---

## ⚠️ Précautions

- Ne jamais exposer le port 11434 (Ollama) hors du réseau interne Docker
- Toujours utiliser `--break-system-packages` avec pip3 sur Ubuntu 24.04
- Créer un snapshot ESXi avant chaque mise à jour majeure des modèles
- Le dashboard :7070 est temporaire — désactiver avec `sudo systemctl disable lab-monitor` une fois l'UI principale déployée
