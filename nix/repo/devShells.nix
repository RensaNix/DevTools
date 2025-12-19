{
  inputs,
  cell,
  ...
}: let
  inherit (inputs) self pkgs devshell treefmt;
  inherit (cell) soonix;

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
    packages = [
      pkgs.hello
      treefmtWrapper
    ];

    task.",".tasks = {
      "hello" = {
        cmd = "echo world!";
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
          {
            name = "soonix";
            stage_fixed = true;
            run = "${soonix.shellHookFile}";
          }
        ];
      };
    };

    process-compose."default".config.processes = {
      hello.command = "echo 'Hello World'";
      pc = {
        command = "echo 'From Process Compose'";
        depends_on.hello.condition = "process_completed";
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
