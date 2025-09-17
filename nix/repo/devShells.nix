{
  inputs,
  cell,
  ...
}: let
  inherit (inputs) self pkgs devshell soonix treefmt;
  inherit (cell) ci;

  treefmtWrapper = treefmt.mkWrapper pkgs {
    programs = {
      alejandra.enable = true;
      deadnix.enable = true;
      statix.enable = true;
      mdformat.enable = true;
    };
  };
in {
  default = devshell.mkShell {
    imports = [
      "${self}/lib/modules"
      soonix.devshellModule
    ];
    soonix.hooks.ci = ci.soonix;
    packages = [
      pkgs.hello
      treefmtWrapper
    ];

    task = {
      alias = ",";
      tasks = {
        "hello" = {
          cmd = "echo world!";
        };
      };
    };

    lefthook.config = {
      skip_output = ["meta" "execution_out"];
      "pre-commit" = {
        parallel = true;
        jobs = [
          {
            name = "treefmt";
            stage_fixed = true;
            run = "${treefmtWrapper}/bin/treefmt";
            env.TERM = "dumb";
          }
        ];
      };
    };

    cocogitto.config.changelog = {
      path = "CHANGELOG.md";
      template = "remote";
      remote = "gitlab.com";
      repository = "devtools";
      owner = "rensa-nix";
    };
  };
}
