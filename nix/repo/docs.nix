{inputs, ...}: let
  inherit (inputs) pkgs devtools doclib;

  optionsDoc = doclib.mkOptionDocs {
    module = devtools.devshellModule;
    roots = [
      {
        url = "https://gitlab.com/rensa-nix/devtools/-/blob/main/lib";
        path = "${inputs.self}/lib";
      }
    ];
  };
  optionsDocs = pkgs.runCommand "options-docs" {} ''
    mkdir -p $out
    ln -s ${optionsDoc} $out/options.md
  '';
in
  (doclib.mkDocs {
    docs."default" = {
      base = "${inputs.self}";
      path = "${inputs.self}/docs";
      material = {
        enable = true;
        colors = {
          primary = "red";
          accent = "red";
        };
        umami = {
          enable = true;
          src = "https://analytics.tf/umami";
          siteId = "db90861a-0b7f-4654-b7ca-f45ce80c44b3";
          domains = ["devtools.rensa.projects.tf"];
        };
      };
      macros = {
        enable = true;
        includeDir = toString optionsDocs;
      };
      config = {
        site_name = "DevTools";
        site_url = "https://devtools.rensa.projects.tf";
        repo_name = "rensa-nix/devtools";
        repo_url = "https://gitlab.com/rensa-nix/devtools";
        extra_css = ["style.css"];
        theme = {
          logo = "images/logo.svg";
          icon.repo = "simple/gitlab";
          favicon = "images/logo.svg";
        };
        nav = [
          {"Introduction" = "index.md";}
          {"Options" = "options.md";}
        ];
        markdown_extensions = [
          {
            "pymdownx.highlight".pygments_lang_class = true;
          }
          "pymdownx.inlinehilite"
          "pymdownx.snippets"
          "pymdownx.superfences"
          "pymdownx.escapeall"
          "fenced_code"
        ];
      };
    };
  }).packages
  // {
    inherit optionsDocs;
  }
