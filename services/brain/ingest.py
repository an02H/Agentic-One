#!/usr/bin/env python3
# ============================================================
# Agentic-One — Pipeline RAG (NotebookLM Style)
# Mode : LEARN — Ingestion de documents PDF vers ChromaDB
# VM   : 192.168.10.216 | Ollama : mxbai-embed-large
# ============================================================
# USAGE : python3 ingest.py
# ============================================================

import os
import sys
from pathlib import Path

from langchain_community.document_loaders import PyPDFLoader, DirectoryLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.embeddings import OllamaEmbeddings
from langchain_community.vectorstores import Chroma

# ── Configuration ─────────────────────────────────────────
OLLAMA_URL  = "http://192.168.10.216:11434"
EMBED_MODEL = "mxbai-embed-large"
LLM_MODEL   = "mistral-nemo"
DATA_PATH   = Path("./data")
DB_PATH     = "./chroma_db"

CHUNK_SIZE    = 1000
CHUNK_OVERLAP = 100


def check_prerequisites() -> bool:
    """Vérifie que les conditions préalables sont remplies."""
    import urllib.request
    try:
        urllib.request.urlopen(f"{OLLAMA_URL}/api/tags", timeout=5)
        print(f"    ✅ Ollama accessible sur {OLLAMA_URL}")
        return True
    except Exception:
        print(f"    ❌ Ollama inaccessible sur {OLLAMA_URL}")
        print(f"       Vérifiez que le conteneur est démarré (Portainer :9000)")
        return False


def ensure_data_dir() -> bool:
    """Crée le dossier data/ si inexistant et vérifie la présence de PDFs."""
    DATA_PATH.mkdir(parents=True, exist_ok=True)
    pdfs = list(DATA_PATH.glob("*.pdf"))

    if not pdfs:
        print(f"    ⚠️  Aucun PDF dans {DATA_PATH.resolve()}")
        print(f"       Déposez vos documents et relancez : python3 ingest.py")
        return False

    print(f"    ✅ {len(pdfs)} PDF(s) trouvé(s) dans {DATA_PATH.resolve()}")
    for pdf in pdfs:
        print(f"       → {pdf.name}")
    return True


def ingest() -> None:
    """Pipeline principal d'ingestion Vector-RAG."""
    print("")
    print("╔══════════════════════════════════════════════════════╗")
    print("║  Agentic-One — RAG Ingestion (NotebookLM Style)      ║")
    print("╚══════════════════════════════════════════════════════╝")
    print("")

    # --- Prérequis ---
    print("[1/4] 🔍 Vérification des prérequis...")
    if not check_prerequisites():
        sys.exit(1)

    print("[2/4] 📂 Vérification du dossier sources...")
    if not ensure_data_dir():
        sys.exit(0)

    # --- Chargement ---
    print("[3/4] 📖 Chargement et découpage des documents...")
    loader = DirectoryLoader(
        str(DATA_PATH),
        glob="*.pdf",
        loader_cls=PyPDFLoader,
        show_progress=True
    )
    docs = loader.load()
    print(f"    ✅ {len(docs)} pages chargées")

    splitter = RecursiveCharacterTextSplitter(
        chunk_size=CHUNK_SIZE,
        chunk_overlap=CHUNK_OVERLAP
    )
    chunks = splitter.split_documents(docs)
    print(f"    ✅ {len(chunks)} fragments générés (chunk={CHUNK_SIZE}, overlap={CHUNK_OVERLAP})")

    # --- Indexation ---
    print(f"[4/4] 🧠 Indexation via {EMBED_MODEL} → ChromaDB...")
    print(f"    (Cette étape peut prendre plusieurs minutes selon le volume)")

    embeddings = OllamaEmbeddings(
        model=EMBED_MODEL,
        base_url=OLLAMA_URL
    )

    db = Chroma.from_documents(
        documents=chunks,
        embedding=embeddings,
        persist_directory=DB_PATH
    )
    db.persist()

    print("")
    print("╔══════════════════════════════════════════════════════╗")
    print(f"║  ✅ INGESTION TERMINÉE                               ║")
    print(f"║  → {len(chunks):4d} fragments indexés dans {DB_PATH}    ║")
    print(f"║  Le Cerveau est prêt pour le Mode RUN (n8n → RAG)   ║")
    print("╚══════════════════════════════════════════════════════╝")
    print("")


if __name__ == "__main__":
    ingest()
