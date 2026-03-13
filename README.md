# LLM Docs Generator

Generate **LLM-friendly documentation files** from any documentation website.

This tool downloads a documentation site, extracts the useful content, and produces a **clean text file optimized for AI agents and LLMs**.

This project follows the concept proposed by the **llms.txt initiative** — a simple standard for providing LLM-friendly context files for AI systems.  
Learn more: https://llmstxt.org/

The process follows a simple pipeline:

```

Documentation Website
↓
Mirror site (HTTrack)
↓
Extract clean content (Trafilatura)
↓
Build LLM-friendly documentation file

````

The output can be used as **context for AI agents, copilots, and chat assistants**.

---

# Requirements

Install the following dependencies.

### System

- **HTTrack**

### Python

- Python **3.10+**
- pip

### Python packages

```bash
pip install trafilatura tqdm
````

---

# Installation

Clone the repository:

```bash
git clone https://github.com/vreoo/llms-dot-txt.git
cd llms-dot-txt
```

Make the script executable:

```bash
chmod +x run.sh
```

---

# Usage

Run the script with:

```
./run.sh --name <project-name> --url <docs-url>
```

Example:

```bash
./run.sh --name rabbitmq --url https://rabbitmq.com/docs
```

---

# Output

After the process finishes, the following structure will be created:

```
llm-docs/
└── rabbitmq/
    ├── site/        # mirrored documentation website
    ├── extracted/   # extracted text content
    └── docs/
        └── rabbitmq-llm.txt
        └── rabbitmq-rag.jsonl
```

The generated file:

```
rabbitmq-llm.txt
```

contains **clean documentation formatted for LLM consumption**.

---

# Using the Documentation with AI

Example prompt:

```
Context:
docs/rabbitmq-llm.txt

Task:
Create a Python producer that sends messages to a RabbitMQ queue.
```

This allows AI agents to reason using **official documentation as context**.

---

# License

Generated documentation is derived from the original documentation website and follows the **license of the source documentation**.

Scripts in this repository are licensed under the **MIT License**.