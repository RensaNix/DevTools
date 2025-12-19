{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ren.url = "gitlab:rensa-nix/core?dir=lib";
  };

  outputs = {
    ren,
    self,
    ...
  } @ inputs:
    ren.buildWith
    {
      inherit inputs;
      cellsFrom = ./nix;
      transformInputs = system: i:
        i
        // {
          pkgs = import i.nixpkgs {inherit system;};
        };
      cellBlocks = with ren.blocks; [
        (simple "devShells")
        (simple "tests")
        (simple "docs")
        (simple "ci")
        (simple "soonix")
      ];
    }
    {
      packages = ren.select self [
        ["repo" "tests"]
        ["repo" "docs"]
        ["repo" "ci" "packages"]
        ["repo" "soonix" "packages"]
      ];
    };
}
