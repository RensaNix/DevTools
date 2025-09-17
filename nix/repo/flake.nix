{
  inputs = {
    nixtest-lib.url = "gitlab:TECHNOFAB/nixtest?dir=lib";
    nixmkdocs.url = "gitlab:TECHNOFAB/nixmkdocs?dir=lib";
    devshell.url = "gitlab:rensa-nix/devshell?dir=lib";
    soonix-lib.url = "gitlab:TECHNOFAB/soonix?dir=lib";
    nix-gitlab-ci-lib.url = "gitlab:TECHNOFAB/nix-gitlab-ci/3.0.0-alpha.2?dir=lib";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      flake = false;
    };
  };
  outputs = i:
    i
    // {
      ntlib = i.nixtest-lib.lib {inherit (i.parent) pkgs;};
      doclib = i.nixmkdocs.lib {inherit (i.parent) pkgs;};
      devshell = i.devshell.lib {inherit (i.parent) pkgs;};
      soonix = i.soonix-lib.lib {inherit (i.parent) pkgs;};
      cilib = i.nix-gitlab-ci-lib.lib {inherit (i.parent) pkgs;};
      devtools = import "${i.parent.self}/lib" {inherit (i.parent) pkgs;};
      treefmt = import i.treefmt-nix;
    };
}
