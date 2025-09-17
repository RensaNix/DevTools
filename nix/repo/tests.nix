{inputs, ...}: let
  inherit (inputs) pkgs ntlib devshell;
in {
  tests = ntlib.mkNixtest {
    modules = ntlib.autodiscover {dir = "${inputs.self}/lib/modules";};
    args = {
      inherit ntlib devshell pkgs;
    };
  };
}
