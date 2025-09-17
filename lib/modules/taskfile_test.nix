{
  ntlib,
  devshell,
  ...
}: let
  module = ./taskfile.nix;
in {
  suites."Taskfile" = {
    pos = __curPos;
    tests = [
      {
        name = "basic";
        type = "script";
        script = let
          shell = devshell.mkShell {
            imports = [module];
            task.enable = true;
          };
        in
          # sh
          ''
            ${ntlib.helpers.scriptHelpers}
            assert "-f ${shell}/bin/task" "/bin/task should exist"
          '';
      }
      {
        name = "alias";
        type = "script";
        script = let
          shell = devshell.mkShell {
            imports = [module];
            task = {
              enable = true;
              alias = ",";
            };
          };
        in
          # sh
          ''
            ${ntlib.helpers.scriptHelpers}
            assert "-f ${shell}/bin/," "/bin/, should exist"
          '';
      }
    ];
  };
}
