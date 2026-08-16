# LaTeX Development Environment for NixOS & Devenv

A reproducible, hermetic LaTeX development environment for NixOS built with [`devenv`](https://devenv.sh).

---

## 🛠 Features & Built-in Devenv Options

This environment incorporates **built-in `devenv` options** alongside helper scripts and editor configurations:

| Category | Option / Tool | Purpose |
| :--- | :--- | :--- |
| **TeX Live Module** | `languages.texlive.enable = true` | Built-in devenv TeX Live module |
| **TeX Live Base** | `languages.texlive.base = pkgs.texlive.combined.scheme-full` | Complete TeX Live distribution (`pdflatex`, `xelatex`, `lualatex`, `latexmk`, `chktex`, `biber`, TikZ, etc.) |
| **Language Server** | `languages.texlive.lsp.enable = true` | `texlab` Language Server for auto-complete, diagnostics & symbol resolution |
| **Git Hooks** | `git-hooks.hooks.chktex` & `git-hooks.hooks.nixfmt-rfc-style` | Automatic pre-commit linting for LaTeX and Nix expressions |
| **Devcontainer** | `devcontainer.enable = true` | VS Code / GitHub Codespaces container integration |
| **Tasks** | `tasks."latex:clean"` | Built-in task runner integration |
| **Conversion Tools** | `pandoc`, `ghostscript`, `poppler-utils`, `pygments` | Convert documents, render graphics, and format code with `minted` |
| **IDE Integration** | `.vscode/settings.json` | Preconfigured VS Code LaTeX Workshop and `texlab` settings |
| **Automatic Shell** | `.envrc` (`use devenv`) | Auto-activates environment upon entering directory via `direnv` |

---

## 🚀 Quick Start

### 1. Entering the Shell

If you have `direnv` installed:
```bash
direnv allow
```

Otherwise, manually enter the devenv shell:
```bash
devenv shell
```

### 2. Available Helper Commands

Once inside the environment (or via `devenv shell <command>`):

* **Compile Document**:
  ```bash
  build-pdf main.tex
  ```
* **Continuous Watch Mode** (auto-recompiles on file save):
  ```bash
  watch main.tex
  ```
* **Lint Document**:
  ```bash
  lint-tex main.tex
  ```
* **Clean Build Artifacts**:
  ```bash
  clean-pdf
  ```

### 3. Run Devenv Test Suite

Validate all tools and compilation pipelines:
```bash
devenv test
```

---

## 📁 Workspace Files

* **[`devenv.nix`](file:///home/mrbot/.temp/latex-docs/devenv.nix)**: The primary environment configuration leveraging `languages.texlive`, `git-hooks`, `devcontainer`, and `tasks`.
* **[`devenv.yaml`](file:///home/mrbot/.temp/latex-docs/devenv.yaml)**: Flake inputs definition (`nixpkgs` and `git-hooks.nix`).
* **[`.envrc`](file:///home/mrbot/.temp/latex-docs/.envrc)**: `direnv` hook for automatic environment activation.
* **[`main.tex`](file:///home/mrbot/.temp/latex-docs/main.tex)**: Starter document featuring AMS math, TikZ diagrams, code listings, and hyperref links.
* **[`references.bib`](file:///home/mrbot/.temp/latex-docs/references.bib)**: BibTeX bibliography sample.
* **[`.vscode/settings.json`](file:///home/mrbot/.temp/latex-docs/.vscode/settings.json)**: VS Code LaTeX Workshop & `texlab` LSP configuration.
* **[`.gitignore`](file:///home/mrbot/.temp/latex-docs/.gitignore)**: Configured to ignore LaTeX build artifacts (`.aux`, `.log`, `.synctex.gz`, etc.).
