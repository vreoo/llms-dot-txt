# Generate AI-Agent Friendly Documentation from a Website

This guide explains how to convert a documentation website into a **clean, LLM-friendly text file** that can be used as context for AI agents or chat-based assistants.

The process downloads the docs locally, extracts the useful content, and compiles it into a single file such as:

```
docs/rabbitmq-llm.txt
```

We will demonstrate the process using the documentation of **RabbitMQ**.

---

# Overview

The pipeline consists of four steps:

```
Documentation Website
        ↓
Mirror the site (HTTrack)
        ↓
Extract clean text (Trafilatura)
        ↓
Merge pages into a single LLM-friendly document
```

This avoids complex solutions such as vector databases, embeddings, or RAG pipelines.
Instead, it creates **static documentation files optimized for AI agents**.

---

# Prerequisites

Install the following tools on your system.

### System tools

* **HTTrack** – downloads a website locally

### Python

* Python **3.10+**
* pip

### Python packages

Install required libraries:

```bash
pip install trafilatura beautifulsoup4 tqdm
```

---

# Project Structure

Create a working directory for the documentation pipeline.

```
llm-docs/
└── rabbitmq/
    ├── site/        # mirrored documentation website
    ├── extracted/   # cleaned text extracted from HTML
    ├── docs/        # final LLM documentation
    ├── extract_docs.py
    └── build_llm_file.py
```

Create the directories:

```bash
mkdir -p llm-docs/rabbitmq
cd llm-docs/rabbitmq

mkdir site extracted docs
```

---

# Step 1 — Download the Documentation Website

Use **HTTrack** to mirror the documentation locally.

```bash
httrack https://www.rabbitmq.com/docs \
  -O site \
  "+*.rabbitmq.com/*" \
  -v
```

This command:

* downloads all documentation pages
* preserves the link structure
* stores the website in the `site/` directory

After completion you should see files similar to:

```
site/www.rabbitmq.com/docs/
   index.html
   queues.html
   exchanges.html
   clustering.html
```

---

# Step 2 — Extract Clean Text from HTML

Create the script:

```
extract_docs.py
```

```python
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

for file_path in tqdm(html_files):
    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        html = f.read()

    text = trafilatura.extract(
        html,
        include_comments=False,
        include_tables=True
    )

    if not text:
        continue

    name = Path(file_path).stem
    out_file = os.path.join(OUTPUT_DIR, name + ".txt")

    with open(out_file, "w", encoding="utf-8") as f:
        f.write(text)
```

Run the script:

```bash
python extract_docs.py
```

Output:

```
extracted/
   index.txt
   queues.txt
   exchanges.txt
   clustering.txt
```

Each file now contains **clean documentation text without HTML noise**.

---

# Step 3 — Build the LLM Documentation File

Create another script:

```
build_llm_file.py
```

```python
import os

INPUT_DIR = "extracted"
OUTPUT_FILE = "docs/rabbitmq-llm.txt"

files = sorted(os.listdir(INPUT_DIR))

with open(OUTPUT_FILE, "w", encoding="utf-8") as out:
    out.write("# RabbitMQ Documentation for AI Agents\n\n")

    for file in files:
        path = os.path.join(INPUT_DIR, file)

        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        title = file.replace(".txt", "").replace("-", " ").title()

        out.write(f"\n\n## {title}\n\n")
        out.write(content)
```

Run:

```bash
python build_llm_file.py
```

This generates:

```
docs/rabbitmq-llm.txt
```

---

# Step 4 — Verify the Output

Open the generated file:

```bash
less docs/rabbitmq-llm.txt
```

Example structure:

```
# RabbitMQ Documentation for AI Agents

## Queues
Queues store messages until they are consumed...

## Exchanges
An exchange routes messages to queues...

## Clustering
RabbitMQ nodes can be clustered together...
```

The file is now **clean, structured, and AI-friendly**.

---

# Step 5 — Using the Documentation with AI Agents

You can now supply this file as context to an AI system.

Example prompt:

```
Context:
docs/rabbitmq-llm.txt

Task:
Create a Python producer that sends messages to a RabbitMQ queue.
```

This allows the AI agent to reason using **accurate official documentation**.

---

# Notes and Best Practices

### Prefer multiple smaller files for large projects

Instead of one file:

```
docs/rabbitmq-llm.txt
```

You may eventually split into:

```
docs/rabbitmq/
   queues.md
   exchanges.md
   clustering.md
```

This improves **agent reasoning and retrieval**.

---

### Remove duplicated sections

Web documentation often contains:

* navigation text
* repeated headers
* page footers

If needed, perform a **manual cleanup or LLM compression pass**.

---

# Result

After completing the pipeline you will have:

```
docs/rabbitmq-llm.txt
```

A **clean, LLM-optimized documentation file** that can be used with:

* AI agents
* chat assistants
* code copilots
* local LLMs
* automated development tools

---

# Future Improvements

Possible upgrades:

* automatic documentation compression
* semantic splitting into multiple files
* automated doc pipelines for multiple tools
* incremental updates when docs change

---

# License

Use the generated documentation according to the license of the original documentation website.
