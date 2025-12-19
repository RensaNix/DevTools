{
  ntlib,
  devshell,
  ...
}: let
  module = ./process_compose.nix;
in {
  suites."Process-Compose" = {
    pos = __curPos;
    tests = [
      {
        name = "basic";
        type = "script";
        script = let
          shell = devshell.mkShell {
            imports = [module];
            process-compose."default" = {};
          };
        in
          # sh
          ''
            ${ntlib.helpers.scriptHelpers}
            assert "-f ${shell}/bin/pc" "/bin/pc should exist"
          '';
      }
      {
        name = "alias";
        type = "script";
        script = let
          shell = devshell.mkShell {
            imports = [module];
            process-compose."pctest" = {};
          };
        in
          # sh
          ''
            ${ntlib.helpers.scriptHelpers}
            assert "-f ${shell}/bin/pctest" "/bin/pctest should exist"
          '';
      }
    ];
  };
}
