#!/usr/bin/env bash

set -euo pipefail

########################################
# Defaults
########################################

DEPTH=5
WORKERS=4
BASE_DIR="llm-docs"

########################################
# Logging
########################################

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

log() {
  echo "[$(timestamp)] INFO  $1"
}

success() {
  echo "[$(timestamp)] OK    $1"
}

error() {
  echo "[$(timestamp)] ERROR $1"
  exit 1
}

########################################
# CLI
########################################

usage() {
  echo "Usage:"
  echo "  ./run.sh --name rabbitmq --url https://rabbitmq.com/docs"
  exit 1
}

PROJECT=""
URL=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --name)
      PROJECT="$2"
      shift 2
      ;;
    --url)
      URL="$2"
      shift 2
      ;;
    --depth)
      DEPTH="$2"
      shift 2
      ;;
    --workers)
      WORKERS="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

[[ -z "$PROJECT" || -z "$URL" ]] && usage

########################################
# Paths
########################################

ROOT="$BASE_DIR/$PROJECT"
SITE="$ROOT/site"
EXTRACT="$ROOT/extracted"
DOCS="$ROOT/docs"

LLM_FILE="$DOCS/$PROJECT-llm.txt"
RAG_FILE="$DOCS/$PROJECT-rag.jsonl"

########################################
# Dependency checks
########################################

log "Checking dependencies..."

command -v httrack >/dev/null || error "httrack not installed"
command -v python3 >/dev/null || error "python3 not installed"

python3 - <<EOF || error "Install python deps: pip install trafilatura tqdm"
import trafilatura
import tqdm
EOF

success "Dependencies satisfied"

########################################
# Workspace
########################################

log "Preparing workspace..."

mkdir -p "$SITE" "$EXTRACT" "$DOCS"

success "Workspace ready"

########################################
# Step 1 — Crawl docs
########################################

log "Mirroring documentation..."

httrack "$URL" \
  -O "$SITE" \
  "+${URL}/*" \
  "-*/blog/*" \
  "-*/news/*" \
  "-*/archive/*" \
  "-*.jpg" "-*.png" "-*.gif" "-*.pdf" \
  --depth="$DEPTH" \
  --quiet

success "Website mirrored"

########################################
# Step 2 — Extract clean text
########################################

log "Extracting documentation content..."

python3 <<PYTHON
import os
import json
import hashlib
from pathlib import Path
import trafilatura
from tqdm import tqdm
from concurrent.futures import ProcessPoolExecutor

SITE = "$SITE"
EXTRACT = "$EXTRACT"
WORKERS = $WORKERS

Path(EXTRACT).mkdir(exist_ok=True)

html_files = []

for root, _, files in os.walk(SITE):
    for f in files:
        if f.endswith(".html"):
            html_files.append(os.path.join(root, f))

seen_hashes = set()

def process_file(path):
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        html = f.read()

    result = trafilatura.extract(
        html,
        include_tables=True,
        include_comments=False,
        with_metadata=True
    )

    if not result:
        return None

    text = result

    h = hashlib.md5(text.encode()).hexdigest()
    if h in seen_hashes:
        return None

    seen_hashes.add(h)

    title = trafilatura.extract_metadata(html)
    title = title.title if title and title.title else Path(path).stem

    return {
        "title": title,
        "content": text
    }

docs = []

with ProcessPoolExecutor(max_workers=WORKERS) as ex:
    for r in tqdm(ex.map(process_file, html_files), total=len(html_files)):
        if r:
            docs.append(r)

out = Path(EXTRACT) / "docs.json"

with open(out, "w") as f:
    json.dump(docs, f)

print("Extracted", len(docs), "documents")
PYTHON

success "Extraction completed"

########################################
# Step 3 — Build LLM file
########################################

log "Generating LLM documentation..."

python3 <<PYTHON
import json
from pathlib import Path

DATA="$EXTRACT/docs.json"
LLM="$LLM_FILE"
RAG="$RAG_FILE"
URL="$URL"
PROJECT="$PROJECT"

docs=json.load(open(DATA))

docs=sorted(docs, key=lambda d: d["title"])

with open(LLM,"w") as out:

    out.write(f"# {PROJECT} Documentation (LLM Optimized)\\n\\n")
    out.write(f"Source: {URL}\\n\\n")
    out.write("Each section represents one documentation page.\\n")
    out.write("---\\n")

    for d in docs:
        out.write(f"\\n## {d['title']}\\n\\n")
        out.write(d["content"])
        out.write("\\n\\n---\\n")

with open(RAG,"w") as out:
    for d in docs:
        out.write(json.dumps(d)+"\\n")

print("LLM + RAG files created")
PYTHON

success "Documentation generated"

########################################
# Done
########################################

echo
echo "Output files:"
echo "  $LLM_FILE"
echo "  $RAG_FILE"
echo
success "Process completed"