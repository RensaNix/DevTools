{
  ntlib,
  devshell,
  ...
}: let
  module = ./lefthook.nix;
in {
  suites."Lefthook" = {
    pos = __curPos;
    tests = [
      {
        name = "basic";
        type = "script";
        script = let
          shell = devshell.mkShell {
            imports = [module];
            lefthook.enable = true;
          };
        in
          # sh
          ''
            ${ntlib.helpers.scriptHelpers}
            assert "-f ${shell}/bin/lefthook" "/bin/lefthook should exist"
          '';
      }
      {
        name = "alias";
        type = "script";
        script = let
          shell = devshell.mkShell {
            imports = [module];
            lefthook = {
              enable = true;
              alias = "hooks";
            };
          };
        in
          # sh
          ''
            ${ntlib.helpers.scriptHelpers}
            assert "-f ${shell}/bin/hooks" "/bin/hooks should exist"
          '';
      }
    ];
  };
}
