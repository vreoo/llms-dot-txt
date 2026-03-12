#!/usr/bin/env bash

set -euo pipefail

############################################
# Configuration
############################################

PROJECT_NAME="${1:-}"
DOCS_URL="${2:-}"

BASE_DIR="llm-docs"
SITE_DIR="site"
EXTRACTED_DIR="extracted"
DOCS_DIR="docs"

############################################
# Logging Helpers
############################################

log() {
  echo "[INFO] $1"
}

success() {
  echo "[SUCCESS] $1"
}

error() {
  echo "[ERROR] $1"
  exit 1
}

############################################
# Validate Input
############################################

if [[ -z "$PROJECT_NAME" || -z "$DOCS_URL" ]]; then
  error "Usage: ./generate-llm-docs.sh <project-name> <docs-url>"
fi

OUTPUT_ROOT="${BASE_DIR}/${PROJECT_NAME}"
FINAL_DOC="${DOCS_DIR}/${PROJECT_NAME}-llm.txt"

############################################
# Dependency Checks
############################################

log "Checking dependencies..."

command -v httrack >/dev/null 2>&1 || error "HTTrack is not installed."
command -v python3 >/dev/null 2>&1 || error "Python3 is not installed."

python3 - <<EOF || error "Required Python packages missing. Run: pip install trafilatura tqdm"
import trafilatura
import tqdm
EOF

success "All dependencies are installed."

############################################
# Create Directory Structure
############################################

log "Creating directory structure..."

mkdir -p "${OUTPUT_ROOT}/${SITE_DIR}"
mkdir -p "${OUTPUT_ROOT}/${EXTRACTED_DIR}"
mkdir -p "${OUTPUT_ROOT}/${DOCS_DIR}"

cd "$OUTPUT_ROOT"

success "Workspace ready at ${OUTPUT_ROOT}"

############################################
# Step 1 — Mirror Documentation
############################################

log "Step 1: Downloading documentation site..."

httrack "$DOCS_URL" \
  -O "$SITE_DIR" \
  "+*" \
  -v > /dev/null

success "Website mirrored successfully."

############################################
# Step 2 — Extract Clean Text
############################################

log "Step 2: Extracting clean text from HTML..."

python3 <<'PYTHON'
import os
from pathlib import Path
import trafilatura
from tqdm import tqdm

INPUT_DIR = "site"
OUTPUT_DIR = "extracted"

Path(OUTPUT_DIR).mkdir(exist_ok=True)

html_files = []

for root, _, files in os.walk(INPUT_DIR):
    for file in files:
        if file.endswith(".html"):
            html_files.append(os.path.join(root, file))

for file_path in tqdm(html_files, desc="Processing HTML"):
    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        html = f.read()

    text = trafilatura.extract(
        html,
        include_tables=True,
        include_comments=False
    )

    if not text:
        continue

    name = Path(file_path).stem
    out_path = os.path.join(OUTPUT_DIR, f"{name}.txt")

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(text)
PYTHON

success "Text extraction completed."

############################################
# Step 3 — Build LLM Documentation File
############################################

log "Step 3: Building final LLM documentation..."

python3 <<PYTHON
import os

INPUT_DIR = "${EXTRACTED_DIR}"
OUTPUT_FILE = "${FINAL_DOC}"

files = sorted(os.listdir(INPUT_DIR))

with open(OUTPUT_FILE, "w", encoding="utf-8") as out:
    out.write("# ${PROJECT_NAME} Documentation for AI Agents\n\n")
    out.write("Source: ${DOCS_URL}\n\n")

    for file in files:
        path = os.path.join(INPUT_DIR, file)

        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        title = file.replace(".txt","").replace("-"," ").title()

        out.write(f"\n\n## {title}\n\n")
        out.write(content)
PYTHON

success "LLM documentation file created."

############################################
# Final Output
############################################

log "Process completed."

echo
echo "Generated file:"
echo "${OUTPUT_ROOT}/${FINAL_DOC}"
echo