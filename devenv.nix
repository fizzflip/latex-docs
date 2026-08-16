{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  # ---------------------------------------------------------------------------
  # 1. Built-in TeX Live Language Module
  # ---------------------------------------------------------------------------
  languages.texlive = {
    enable = true;
    base = pkgs.texlive.combined.scheme-full;
    lsp = {
      enable = true;
      package = pkgs.texlab;
    };
  };

  # ---------------------------------------------------------------------------
  # 2. Additional Utility Packages for Document Processing & Conversion
  # ---------------------------------------------------------------------------
  packages = with pkgs; [
    pandoc # Document converter (LaTeX <-> Markdown/HTML/Docx)
    ghostscript # PostScript & PDF rendering engine
    poppler-utils # PDF utilities (pdfimages, pdftotext, pdftoppm, pdfinfo)
    python3Packages.pygments # Code syntax highlighting for LaTeX 'minted' package
    watchexec # File watcher utility for dev automation
  ];

  # ---------------------------------------------------------------------------
  # 3. Environment Variables & Shell Prompt
  # ---------------------------------------------------------------------------
  env = {
    TEXINPUTS = ".:./include//:";
  };

  starship.enable = true; # Custom shell prompt for devenv sessions

  # ---------------------------------------------------------------------------
  # 4. Built-in Pre-commit & Git Hooks (via git-hooks.nix)
  # ---------------------------------------------------------------------------
  git-hooks.hooks = {
    chktex = {
      enable = true;
      name = "chktex";
      entry = "${pkgs.texlive.combined.scheme-full}/bin/chktex";
      files = "\\.tex$";
    };
    latexindent = {
      enable = true;
      name = "latexindent";
      entry = "${pkgs.texlive.combined.scheme-full}/bin/latexindent -w -s";
      files = "\\.tex$";
    };
    nixfmt-rfc-style.enable = true; # Auto-format Nix expressions
  };

  # ---------------------------------------------------------------------------
  # 5. Built-in Devcontainer Integration
  # ---------------------------------------------------------------------------
  devcontainer = {
    enable = true;
    settings = {
      customizations.vscode.extensions = [
        "mkhl.direnv"
        "James-Yu.latex-workshop"
      ];
      customizations.vscode.settings = {
        "latex-workshop.latex.outDir" = "%DIR%/build";
        "latex-workshop.latex.autoBuild.run" = "onSave";
        "latex-workshop.view.pdf.viewer" = "tab";
        "texlab.build.onSave" = true;
        "texlab.build.args" = [
          "-pdf"
          "-outdir=build"
          "-interaction=nonstopmode"
          "-synctex=1"
          "%f"
        ];
      };
    };
  };

  # ---------------------------------------------------------------------------
  # 6. Managed Processes (devenv up)
  # ---------------------------------------------------------------------------
  processes = {
    "live-build" = {
      exec = ''
        mkdir -p build
        TARGETS="$(find . -maxdepth 1 -name '*.tex' ! -name '_*' -type f)"
        if [ -z "$TARGETS" ]; then
          TARGETS="main.tex"
        fi
        for TARGET in $TARGETS; do
          ${pkgs.texlive.combined.scheme-full}/bin/latexmk -pdf -outdir=build -pvc -interaction=nonstopmode -shell-escape -synctex=1 "$TARGET" &
        done
        wait
      '';
    };
  };

  # ---------------------------------------------------------------------------
  # 7. Built-in Tasks Framework (devenv tasks run ...)
  # ---------------------------------------------------------------------------
  tasks = {
    "latex:build" = {
      exec = "mkdir -p build && ${pkgs.texlive.combined.scheme-full}/bin/latexmk -pdf -outdir=build -interaction=nonstopmode -shell-escape -synctex=1 $(find . -maxdepth 1 -name '*.tex' -type f)";
    };
    "latex:xelatex" = {
      exec = "mkdir -p build && ${pkgs.texlive.combined.scheme-full}/bin/latexmk -xelatex -outdir=build -interaction=nonstopmode -shell-escape -synctex=1 $(find . -maxdepth 1 -name '*.tex' -type f)";
    };
    "latex:lualatex" = {
      exec = "mkdir -p build && ${pkgs.texlive.combined.scheme-full}/bin/latexmk -lualatex -outdir=build -interaction=nonstopmode -shell-escape -synctex=1 $(find . -maxdepth 1 -name '*.tex' -type f)";
    };
    "latex:clean" = {
      exec = "${pkgs.texlive.combined.scheme-full}/bin/latexmk -outdir=build -C && rm -rf build";
    };
    "latex:convert-html" = {
      exec = ''
        mkdir -p build
        for F in $(find . -maxdepth 1 -name '*.tex' -type f); do
          ${pkgs.pandoc}/bin/pandoc "$F" -s -o "build/''${F%.tex}.html"
        done
      '';
    };
    "latex:convert-markdown" = {
      exec = ''
        mkdir -p build
        for F in $(find . -maxdepth 1 -name '*.tex' -type f); do
          ${pkgs.pandoc}/bin/pandoc "$F" -s -o "build/''${F%.tex}.md"
        done
      '';
    };
  };

  # ---------------------------------------------------------------------------
  # 8. Smart Auto-Detecting Executable Helper Scripts
  # ---------------------------------------------------------------------------
  scripts = {
    "build-pdf".exec = ''
      ENGINE="''${2:-pdf}"
      mkdir -p build
      if [ -n "$1" ]; then
        FILES="$1"
      elif [ -f "main.tex" ]; then
        FILES="main.tex"
      else
        FILES=$(find . -maxdepth 1 -name "*.tex" ! -name "_*" -type f)
      fi
      if [ -z "$FILES" ]; then
        echo "Error: No .tex files found to build." >&2
        exit 1
      fi
      for F in $FILES; do
        echo "Compiling $F using latexmk (-$ENGINE, output to build/)..."
        latexmk -$ENGINE -outdir=build -interaction=nonstopmode -shell-escape -synctex=1 "$F"
        echo "Build complete: build/''${F#./}"
        echo "Output PDF: build/''${F%.tex}.pdf"
      done
    '';
    "build-xelatex".exec = ''
      build-pdf "$1" xelatex
    '';
    "build-lualatex".exec = ''
      build-pdf "$1" lualatex
    '';
    "watch".exec = ''
      mkdir -p build
      FILE="''${1:-main.tex}"
      if [ ! -f "$FILE" ]; then
        FILE=$(find . -maxdepth 1 -name "*.tex" ! -name "_*" -type f | head -n 1)
      fi
      if [ -z "$FILE" ]; then
        echo "Error: No .tex file found to watch." >&2
        exit 1
      fi
      echo "Watching $FILE for live changes (output to build/)..."
      latexmk -pdf -outdir=build -pvc -interaction=nonstopmode -shell-escape -synctex=1 "$FILE"
    '';
    "clean-pdf".exec = ''
      echo "Cleaning build directory and temporary artifacts..."
      latexmk -outdir=build -C 2>/dev/null || true
      rm -rf build *.bak* indent.log
      echo "Clean complete."
    '';
    "lint-tex".exec = ''
      if [ -n "$1" ]; then
        FILES="$1"
      else
        FILES=$(find . -maxdepth 1 -name "*.tex" -type f)
      fi
      for F in $FILES; do
        echo "Linting $F with chktex..."
        chktex "$F"
      done
    '';
    "convert-doc".exec = ''
      mkdir -p build
      if [ -n "$1" ]; then
        INPUT="$1"
        OUTPUT="''${2:-build/''${1%.tex}.html}"
        echo "Converting $INPUT -> $OUTPUT using pandoc..."
        pandoc "$INPUT" -s -o "$OUTPUT"
      else
        for F in $(find . -maxdepth 1 -name "*.tex" -type f); do
          OUT="build/''${F%.tex}.html"
          echo "Converting $F -> $OUT using pandoc..."
          pandoc "$F" -s -o "$OUT"
        done
      fi
    '';
  };

  # ---------------------------------------------------------------------------
  # 9. Shell Hook on Entry
  # ---------------------------------------------------------------------------
  enterShell = ''
    echo "=========================================================="
    echo "     LaTeX Development Environment (Devenv / NixOS)       "
    echo "=========================================================="
    echo " Built-in TeX Live:  $(pdflatex --version 2>/dev/null | head -n 1)"
    echo " LSP Server:         $(texlab --version 2>/dev/null | head -n 1)"
    echo " Document Converter: $(pandoc --version 2>/dev/null | head -n 1)"
    echo " Pre-commit Hooks:  chktex, latexindent, nixfmt"
    echo "=========================================================="
    echo " Smart Commands (auto-discovers .tex files if no arg given):"
    echo "   build-pdf [file.tex]     - Build PDF using pdflatex"
    echo "   build-xelatex [file.tex]  - Build PDF using XeLaTeX"
    echo "   build-lualatex [file.tex] - Build PDF using LuaLaTeX"
    echo "   watch [file.tex]         - Continuous live watch mode"
    echo "   convert-doc [in] [out]   - Convert LaTeX to HTML/Markdown via Pandoc"
    echo "   clean-pdf                - Remove build/ directory & temporary files"
    echo "   lint-tex [file.tex]      - Run chktex syntax linter"
    echo "=========================================================="
  '';

  # ---------------------------------------------------------------------------
  # 10. Automated Test Suite (devenv test)
  # ---------------------------------------------------------------------------
  enterTest = ''
    echo "==> Testing pdflatex binary..."
    pdflatex --version | grep -q "pdfTeX"

    echo "==> Testing latexmk binary..."
    latexmk --version | grep -q "Latexmk"

    echo "==> Testing texlab LSP binary..."
    texlab --version | grep -q "texlab"

    echo "==> Testing pandoc binary..."
    pandoc --version | grep -q "pandoc"

    echo "==> Building sample document with build-pdf..."
    build-pdf main.tex
    test -f build/main.pdf

    echo "==> Converting document to HTML with convert-doc..."
    convert-doc main.tex build/main.html
    test -f build/main.html

    echo "==> Cleaning up test build..."
    clean-pdf
    test ! -d build

    echo "==> All LaTeX devenv tests passed successfully!"
  '';
}
