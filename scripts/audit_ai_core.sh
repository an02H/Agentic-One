#!/bin/bash
# ============================================================
# AUDIT AI-CORE — 192.168.10.216
# Projet : Agentic-One
# ============================================================
# USAGE : bash scripts/audit_ai_core.sh
# ============================================================

PASS=0
WARN=0
FAIL=0

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║       AGENTIC-ONE — AUDIT INFRASTRUCTURE             ║"
echo "║       VM : 192.168.10.216 (an02@docker)              ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── SECTION 1 : MÉMOIRE ───────────────────────────────────
echo "📊 [1/4] AUDIT MÉMOIRE"
echo "──────────────────────────────────────────────────────"

RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
RAM_USED=$(free -h  | awk '/^Mem:/ {print $3}')
echo "    RAM : $RAM_USED utilisé / $RAM_TOTAL total"

SWAP_TOTAL=$(free -m | awk '/^Swap:/ {print $2}')
if [ "$SWAP_TOTAL" -eq 0 ]; then
    echo "    ✅ SWAP : Désactivé (optimal pour LLM)"
    PASS=$((PASS+1))
else
    echo "    ❌ SWAP : ACTIF ($SWAP_TOTAL MB) → Risque latence critique !"
    echo "       FIX : sudo swapoff -a"
    FAIL=$((FAIL+1))
fi

HUGEPAGES=$(sysctl -n vm.nr_hugepages 2>/dev/null || echo "0")
if [ "$HUGEPAGES" -gt 0 ]; then
    echo "    ✅ HUGEPAGES : Configurées ($HUGEPAGES × 2Mo)"
    PASS=$((PASS+1))
else
    echo "    ⚠️  HUGEPAGES : Non configurées (0)"
    echo "       FIX : sudo bash scripts/install_ai_core.sh"
    WARN=$((WARN+1))
fi

SWAPPINESS=$(sysctl -n vm.swappiness 2>/dev/null || echo "60")
if [ "$SWAPPINESS" -eq 0 ]; then
    echo "    ✅ SWAPPINESS : 0 (optimal)"
    PASS=$((PASS+1))
else
    echo "    ⚠️  SWAPPINESS : $SWAPPINESS (recommandé: 0)"
    WARN=$((WARN+1))
fi

echo ""

# ── SECTION 2 : CPU ───────────────────────────────────────
echo "⚙️  [2/4] AUDIT CPU"
echo "──────────────────────────────────────────────────────"

CPUS=$(nproc)
echo "    vCPU disponibles : $CPUS (cible: 12)"
if [ "$CPUS" -ge 12 ]; then
    echo "    ✅ CPU : Sizing correct pour Ollama (≥12 vCPU)"
    PASS=$((PASS+1))
else
    echo "    ⚠️  CPU : $CPUS vCPU détectés (recommandé ≥12)"
    WARN=$((WARN+1))
fi

echo ""

# ── SECTION 3 : PORTS DOCKER ──────────────────────────────
echo "🔌 [3/4] AUDIT PORTS DOCKER"
echo "──────────────────────────────────────────────────────"

declare -A SERVICES=(
    [7070]="Lab Monitor (Rust)"
    [9000]="Portainer"
    [11434]="Ollama"
    [5678]="n8n Gateway"
)

for port in 7070 9000 11434 5678; do
    if ss -tuln | grep -q ":$port "; then
        echo "    ✅ Port $port — ${SERVICES[$port]} : EN LIGNE"
        PASS=$((PASS+1))
    else
        echo "    ❌ Port $port — ${SERVICES[$port]} : HORS LIGNE"
        FAIL=$((FAIL+1))
    fi
done

echo ""

# ── SECTION 4 : DOCKER & SERVICES ────────────────────────
echo "🐳 [4/4] AUDIT CONTENEURS DOCKER"
echo "──────────────────────────────────────────────────────"

if command -v docker &> /dev/null; then
    DOCKER_V=$(docker --version | awk '{print $3}' | tr -d ',')
    echo "    ✅ Docker installé : v$DOCKER_V"
    PASS=$((PASS+1))

    RUNNING=$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l)
    echo "    Conteneurs actifs : $RUNNING"
    docker ps --format "    → {{.Names}} ({{.Status}})" 2>/dev/null || true
else
    echo "    ❌ Docker : NON INSTALLÉ"
    echo "       FIX : sudo bash scripts/install_ai_core.sh"
    FAIL=$((FAIL+1))
fi

# ── RÉSUMÉ ────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  RÉSUMÉ AUDIT                                        ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  ✅ PASS : $PASS                                         ║"
echo "║  ⚠️  WARN : $WARN                                         ║"
echo "║  ❌ FAIL : $FAIL                                         ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "⛔ Des problèmes critiques ont été détectés."
    echo "   Exécutez : sudo bash scripts/install_ai_core.sh"
    exit 1
elif [ "$WARN" -gt 0 ]; then
    echo "⚠️  Infrastructure partiellement optimisée."
    echo "   Consultez docs/SETUP_GUIDE.md pour les ajustements."
    exit 0
else
    echo "🚀 Infrastructure prête pour le Mode RUN/LEARN."
    exit 0
fi
