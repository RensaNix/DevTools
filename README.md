# Rensa Devtools

Utilities and dev tools with integration into the Rensa ecosystem (mainly devshell).

## Usage

```nix
let 
  devshell = inputs.devshell.lib { inherit pkgs; };
in
devshell.mkShell {
  imports = [inputs.devtools.devshellModule];

  # use the modules
  lefthook.enable = true;
}
```

## Docs

See [docs](https://devtools.rensa.projects.tf).
