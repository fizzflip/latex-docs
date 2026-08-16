# LaTeX Development Environment for NixOS & Devenv

A reproducible, hermetic, and feature-rich LaTeX development environment for NixOS built with [`devenv`](https://devenv.sh).

---

## 🛠 Features & Built-in Devenv Options

| Category | Option / Tool | Description |
| :--- | :--- | :--- |
| **TeX Live Module** | `languages.texlive.enable = true` | Native devenv TeX Live module |
| **TeX Distribution** | `languages.texlive.base = pkgs.texlive.combined.scheme-full` | Full TeX Live suite (`pdflatex`, `xelatex`, `lualatex`, `latexmk`, `chktex`, `biber`, TikZ, etc.) |
| **Language Server** | `languages.texlive.lsp.enable = true` | `texlab` Language Server for auto-complete, diagnostics & symbol resolution |
| **Git Hooks** | `git-hooks.hooks.chktex` & `git-hooks.hooks.nixfmt-rfc-style` | Automatic pre-commit linting for LaTeX and Nix code |
| **Devcontainer** | `devcontainer.enable = true` | VS Code / GitHub Codespaces integration |
| **Process Manager** | `processes.live-build` | Managed background auto-compilation service via `devenv up` |
| **Task Runner** | `tasks` | Structured tasks (`latex:build`, `latex:xelatex`, `latex:lualatex`, `latex:clean`, `latex:convert-html`, `latex:convert-markdown`) |
| **Doc Conversion** | `pandoc` | Convert LaTeX documents to HTML, Markdown, or Word Docx |
| **PDF & Code Tools** | `ghostscript`, `poppler-utils`, `pygments` | Process graphics and format code listings with `minted` |
| **Clean Build Tree** | `build/` | All compilation artifacts and outputs generated neatly inside `build/` |

---

## 🚀 Quick Start

### 1. Enter Environment

With `direnv` enabled:
```bash
direnv allow
```

Or manually launch the shell:
```bash
devenv shell
```

### 2. Available Commands

* **Compile Document (pdfLaTeX)**:
  ```bash
  build-pdf main.tex
  ```

* **Compile Document (XeLaTeX)**:
  ```bash
  build-xelatex main.tex
  ```

* **Compile Document (LuaLaTeX)**:
  ```bash
  build-lualatex main.tex
  ```

* **Live Continuous Watch Mode**:
  ```bash
  watch main.tex
  ```

* **Convert Document (HTML / Markdown)**:
  ```bash
  convert-doc main.tex build/main.html
  convert-doc main.tex build/main.md
  ```

* **Lint Document**:
  ```bash
  lint-tex main.tex
  ```

* **Clean Build Output**:
  ```bash
  clean-pdf
  ```

### 3. Background Process Manager (`devenv up`)

Start live background watching with `devenv`:
```bash
devenv up
```

### 4. Run Automated Test Suite

Validate all tools and compilation pipelines:
```bash
devenv test
```

---

## 📁 Repository Structure

* **[`devenv.nix`](file:///home/mrbot/.temp/latex-docs/devenv.nix)**: Primary environment configuration with `languages.texlive`, `git-hooks`, `devcontainer`, `processes`, `tasks`, and helper scripts.
* **[`devenv.yaml`](file:///home/mrbot/.temp/latex-docs/devenv.yaml)** & **[`devenv.lock`](file:///home/mrbot/.temp/latex-docs/devenv.lock)**: Flake input definitions and lockfile.
* **[`.envrc`](file:///home/mrbot/.temp/latex-docs/.envrc)**: `direnv` integration.
* **[`main.tex`](file:///home/mrbot/.temp/latex-docs/main.tex)** & **[`references.bib`](file:///home/mrbot/.temp/latex-docs/references.bib)**: Starter project demonstrating math, TikZ graphics, code listings, and references.
* **[`.vscode/settings.json`](file:///home/mrbot/.temp/latex-docs/.vscode/settings.json)**: VS Code LaTeX Workshop and `texlab` LSP setup (configured for `build/` output directory).
* **[`.gitignore`](file:///home/mrbot/.temp/latex-docs/.gitignore)**: Ignores `build/` directory and temporary artifacts.
