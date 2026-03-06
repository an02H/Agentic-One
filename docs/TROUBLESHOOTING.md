# TROUBLESHOOTING — Agentic-One

## Diagnostic rapide

```bash
bash scripts/audit_ai_core.sh
```

---

## Problèmes fréquents

### ❌ Ollama ne répond pas sur :11434

**Symptôme** : `curl http://192.168.10.216:11434/api/tags` timeout

**Causes / Solutions** :
1. Conteneur arrêté → Portainer (:9000) → Redémarrer le conteneur Ollama
2. Variable `OLLAMA_HOST` manquante → Ajouter `OLLAMA_HOST=0.0.0.0:11434` dans l'environnement Docker
3. Firewall → `sudo ufw allow 11434` (si applicable, mais garder interne de préférence)

---

### ❌ Latence d'inférence élevée (>10s par token)

**Symptôme** : Les réponses Mistral prennent > 30 secondes

**Causes / Solutions** :
1. SWAP actif → `sudo swapoff -a` + vérifier `/etc/fstab`
2. Modèle non chargé en RAM → Ajouter `OLLAMA_KEEP_ALIVE=15m`
3. HugePages non configurées → Relancer `scripts/install_ai_core.sh` + reboot

---

### ❌ n8n : Webhook inaccessible

**Symptôme** : `curl` vers `:5678/webhook/chat-gateway` retourne 404

**Causes / Solutions** :
1. Workflow non activé → n8n UI → Toggle "Active" en haut à droite
2. Authentification n8n active → Ajouter header `Authorization: Basic ...`
3. Webhook URL incorrecte → Vérifier `WEBHOOK_URL=http://192.168.10.216:5678`

---

### ❌ Service Rust lab_monitor ne démarre pas

**Symptôme** : `sudo systemctl status lab-monitor` → failed

**Causes / Solutions** :

```bash
# Voir les logs détaillés
journalctl -u lab-monitor -f

# Vérifier que le binaire existe
ls -la /home/an02/Agentic-One/services/monitoring/target/release/lab_monitor

# Recompiler si absent
cd /home/an02/Agentic-One/services/monitoring && cargo build --release
```

---

### ❌ Ingestion RAG échoue (Python)

**Symptôme** : `python3 ingest.py` → erreur d'import ou timeout Ollama

**Causes / Solutions** :

```bash
# Vérifier les dépendances
pip3 install -r requirements.txt --break-system-packages

# Vérifier Ollama accessible depuis Python
curl http://192.168.10.216:11434/api/tags

# Vérifier que mxbai-embed-large est téléchargé
ollama list
```

---

### ❌ Port 7070 inaccessible depuis Windows

**Symptôme** : Dashboard vide dans le navigateur

**Causes / Solutions** :
1. Service non démarré → `sudo systemctl start lab-monitor`
2. Firewall Docker → `sudo ufw allow 7070` (temporaire)
3. Service écoute sur 127.0.0.1 → Vérifier `main.rs` : `bind("0.0.0.0:7070")`

---

## Logs utiles

```bash
# Logs Monitoring Rust
journalctl -u lab-monitor -f

# Logs Docker (tous les conteneurs)
docker ps --format '{{.Names}}' | xargs -I{} docker logs {} --tail 50

# Logs Ollama spécifiquement
docker logs ollama --tail 100 -f

# Logs n8n
docker logs n8n --tail 100 -f
```
