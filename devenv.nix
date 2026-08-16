{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  # ---------------------------------------------------------------------------
  # 1. Built-in TeX Live Language Module (devenv options for TeX)
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
  # 2. Additional Packages for PDF Processing, Pandoc & Pygments
  # ---------------------------------------------------------------------------
  packages = with pkgs; [
    pandoc # Document converter (LaTeX <-> Markdown/HTML/Docx)
    ghostscript # PostScript / PDF rendering engine
    poppler-utils # PDF utilities (pdfimages, pdftotext, pdftoppm, pdfinfo)
    python3Packages.pygments # Syntax highlighting for LaTeX 'minted' package
  ];

  # ---------------------------------------------------------------------------
  # 3. Environment Variables
  # ---------------------------------------------------------------------------
  env = {
    TEXINPUTS = ".:./include//:";
  };

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
        "latex-workshop.latex.autoBuild.run" = "onSave";
        "latex-workshop.view.pdf.viewer" = "tab";
        "texlab.build.onSave" = true;
      };
    };
  };

  # ---------------------------------------------------------------------------
  # 6. Built-in Tasks
  # ---------------------------------------------------------------------------
  tasks = {
    "latex:clean" = {
      exec = "${pkgs.texlive.combined.scheme-full}/bin/latexmk -C";
    };
  };

  # ---------------------------------------------------------------------------
  # 7. Helper Executable Scripts
  # ---------------------------------------------------------------------------
  scripts = {
    "build-pdf".exec = ''
      FILENAME="''${1:-main.tex}"
      echo "Compiling $FILENAME with latexmk..."
      latexmk -pdf -interaction=nonstopmode -synctex=1 "$FILENAME"
    '';
    "watch".exec = ''
      FILENAME="''${1:-main.tex}"
      echo "Watching $FILENAME for changes..."
      latexmk -pdf -pvc -interaction=nonstopmode -synctex=1 "$FILENAME"
    '';
    "clean-pdf".exec = ''
      echo "Cleaning build artifacts..."
      latexmk -C
    '';
    "lint-tex".exec = ''
      FILENAME="''${1:-main.tex}"
      echo "Linting $FILENAME with chktex..."
      chktex "$FILENAME"
    '';
  };

  # ---------------------------------------------------------------------------
  # 8. Shell Hook on Shell Entry
  # ---------------------------------------------------------------------------
  enterShell = ''
    echo "=========================================================="
    echo "     LaTeX Development Environment (Devenv / NixOS)       "
    echo "=========================================================="
    echo " Built-in Module: languages.texlive.enable = true"
    echo " LSP Language Server: texlab ($(texlab --version 2>/dev/null | head -n 1))"
    echo " TeX Engine: $(pdflatex --version 2>/dev/null | head -n 1)"
    echo "=========================================================="
    echo " Helper Commands:"
    echo "   build-pdf [file.tex] - Build PDF document using latexmk"
    echo "   watch [file.tex]     - Continuous compilation on file edit"
    echo "   clean-pdf            - Remove temporary LaTeX build files"
    echo "   lint-tex [file.tex]  - Run chktex syntax linter"
    echo "=========================================================="
  '';

  # ---------------------------------------------------------------------------
  # 9. Test Suite Verification
  # ---------------------------------------------------------------------------
  enterTest = ''
    echo "Testing pdflatex..."
    pdflatex --version | grep -q "pdfTeX"
    echo "Testing latexmk..."
    latexmk --version | grep -q "Latexmk"
    echo "Testing texlab LSP..."
    texlab --version | grep -q "texlab"
    echo "Building sample main.tex..."
    latexmk -pdf -interaction=nonstopmode main.tex
    echo "All LaTeX devenv tests passed successfully!"
  '';
}
