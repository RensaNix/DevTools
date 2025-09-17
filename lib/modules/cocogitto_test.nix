{
  ntlib,
  devshell,
  ...
}: let
  module = ./cocogitto.nix;
in {
  suites."Cocogitto" = {
    pos = __curPos;
    tests = [
      {
        name = "basic";
        type = "script";
        script = let
          shell = devshell.mkShell {
            imports = [module];
            cocogitto.enable = true;
          };
        in
          # sh
          ''
            ${ntlib.helpers.scriptHelpers}
            assert "-f ${shell}/bin/cog" "/bin/cog should exist"
          '';
      }
    ];
  };
}
