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
      exec = "mkdir -p build && ${pkgs.texlive.combined.scheme-full}/bin/latexmk -pdf -outdir=build -pvc -interaction=nonstopmode -shell-escape -synctex=1 main.tex";
    };
  };

  # ---------------------------------------------------------------------------
  # 7. Built-in Tasks Framework (devenv tasks run ...)
  # ---------------------------------------------------------------------------
  tasks = {
    "latex:build" = {
      exec = "mkdir -p build && ${pkgs.texlive.combined.scheme-full}/bin/latexmk -pdf -outdir=build -interaction=nonstopmode -shell-escape -synctex=1 main.tex";
    };
    "latex:xelatex" = {
      exec = "mkdir -p build && ${pkgs.texlive.combined.scheme-full}/bin/latexmk -xelatex -outdir=build -interaction=nonstopmode -shell-escape -synctex=1 main.tex";
    };
    "latex:lualatex" = {
      exec = "mkdir -p build && ${pkgs.texlive.combined.scheme-full}/bin/latexmk -lualatex -outdir=build -interaction=nonstopmode -shell-escape -synctex=1 main.tex";
    };
    "latex:clean" = {
      exec = "${pkgs.texlive.combined.scheme-full}/bin/latexmk -outdir=build -C && rm -rf build";
    };
    "latex:convert-html" = {
      exec = "mkdir -p build && ${pkgs.pandoc}/bin/pandoc main.tex -s -o build/main.html";
    };
    "latex:convert-markdown" = {
      exec = "mkdir -p build && ${pkgs.pandoc}/bin/pandoc main.tex -s -o build/main.md";
    };
  };

  # ---------------------------------------------------------------------------
  # 8. Helper Executable Scripts (Available in PATH)
  # ---------------------------------------------------------------------------
  scripts = {
    "build-pdf".exec = ''
      FILENAME="''${1:-main.tex}"
      ENGINE="''${2:-pdf}"
      echo "Compiling $FILENAME using latexmk (-$ENGINE, output to build/)..."
      mkdir -p build
      latexmk -$ENGINE -outdir=build -interaction=nonstopmode -shell-escape -synctex=1 "$FILENAME"
      echo "Build complete: build/''${FILENAME%.tex}.pdf"
    '';
    "build-xelatex".exec = ''
      build-pdf "''${1:-main.tex}" xelatex
    '';
    "build-lualatex".exec = ''
      build-pdf "''${1:-main.tex}" lualatex
    '';
    "watch".exec = ''
      FILENAME="''${1:-main.tex}"
      echo "Watching $FILENAME for changes (output to build/)..."
      mkdir -p build
      latexmk -pdf -outdir=build -pvc -interaction=nonstopmode -shell-escape -synctex=1 "$FILENAME"
    '';
    "clean-pdf".exec = ''
      echo "Cleaning build directory and temporary artifacts..."
      latexmk -outdir=build -C 2>/dev/null || true
      rm -rf build
      echo "Clean complete."
    '';
    "lint-tex".exec = ''
      FILENAME="''${1:-main.tex}"
      echo "Linting $FILENAME with chktex..."
      chktex "$FILENAME"
    '';
    "convert-doc".exec = ''
      INPUT="''${1:-main.tex}"
      OUTPUT="''${2:-build/main.html}"
      mkdir -p build
      echo "Converting $INPUT -> $OUTPUT using pandoc..."
      pandoc "$INPUT" -s -o "$OUTPUT"
      echo "Conversion finished: $OUTPUT"
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
    echo "=========================================================="
    echo " Workflow Commands:"
    echo "   build-pdf [file.tex]     - Build PDF using pdflatex (output: build/)"
    echo "   build-xelatex [file.tex]  - Build PDF using XeLaTeX"
    echo "   build-lualatex [file.tex] - Build PDF using LuaLaTeX"
    echo "   watch [file.tex]         - Continuous live watch mode"
    echo "   convert-doc [in] [out]   - Convert LaTeX to HTML/Markdown via Pandoc"
    echo "   clean-pdf                - Remove build/ directory"
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
