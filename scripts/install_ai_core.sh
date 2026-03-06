#!/bin/bash
# ============================================================
# SETUP AI-CORE — Ubuntu 24.04 LTS (12 vCPU / 32 Go RAM)
# Projet : Agentic-One | VM : 192.168.10.216
# ============================================================
# USAGE : sudo bash scripts/install_ai_core.sh
# ============================================================

set -e
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║       AGENTIC-ONE — OPTIMISATION AI-CORE             ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# --- 1. Désactivation du Swap ---
echo "[1/5] 🔧 Désactivation du Swap (Critique pour LLM)..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
echo "      ✅ Swap désactivé et retiré de /etc/fstab"

# --- 2. Optimisation Kernel ---
echo "[2/5] 🔧 Configuration HugePages et limites kernel..."
cat <<EOF | sudo tee -a /etc/sysctl.conf

# ===== AGENTIC-ONE OPTIMISATIONS =====
# HugePages (2Mo) pour accès tenseurs LLM optimisé
vm.nr_hugepages = 1024
# Désactivation agressivité swap
vm.swappiness = 0
# Limite fichiers ouverts (ChromaDB multi-segment)
fs.file-max = 65535
# Taille max socket buffer (requêtes n8n)
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
EOF
sudo sysctl -p
echo "      ✅ Paramètres kernel appliqués"

# --- 3. Limites système utilisateur ---
echo "[3/5] 🔧 Configuration des limites fichiers utilisateur..."
cat <<EOF | sudo tee -a /etc/security/limits.conf

# Agentic-One — Limites pour ChromaDB et Ollama
an02 soft nofile 65535
an02 hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF
echo "      ✅ Limites fichiers configurées"

# --- 4. Docker (si absent) ---
echo "[4/5] 🐳 Vérification Docker..."
if ! command -v docker &> /dev/null; then
    echo "      ⬇️  Installation Docker..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    sudo usermod -aG docker an02
    echo "      ✅ Docker installé (logout/login requis pour groupe)"
else
    DOCKER_V=$(docker --version)
    echo "      ✅ Docker déjà présent : $DOCKER_V"
fi

# --- 5. Rust Toolchain ---
echo "[5/5] 🦀 Vérification Rust Toolchain..."
if ! command -v cargo &> /dev/null; then
    echo "      ⬇️  Installation Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo "      ✅ Rust installé"
else
    RUST_V=$(rustc --version)
    echo "      ✅ Rust déjà présent : $RUST_V"
fi

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ✅ OPTIMISATION TERMINÉE                            ║"
echo "║  ⚠️  REBOOT REQUIS pour HugePages et limites         ║"
echo "║  → sudo reboot                                       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "PROCHAINE ÉTAPE :"
echo "  1. sudo reboot"
echo "  2. bash scripts/audit_ai_core.sh   ← Vérifier l'état"
echo "  3. ollama pull mistral-nemo"
echo "  4. ollama pull mxbai-embed-large"
