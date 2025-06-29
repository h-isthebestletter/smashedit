{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }:
  let
    pkgs = import nixpkgs { inherit system; };
    system = "x86_64-linux";
  in rec {
    devShells.${system}.default = pkgs.mkShell rec {
      buildInputs = with pkgs; [
        nushell # shell
        love
        luajit
      ];
      # shell
      shellHook = ''
        exec ${pkgs.nushell}/bin/nu
      '';
    };
  };
}
