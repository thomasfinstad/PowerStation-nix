{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };
  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      forAllSys = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
    in
    {
      packages = forAllSys (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          # this calls a ./default.nix file using callPackage.
          # In that file, you will build your derivation,
          # which is what builds your package.
          # callPackage is a nice function you should know about.
          powerstation = pkgs.callPackage ./default.nix {
            inherit inputs;
            # you can pass more args here, which can
            # be overridden by yourdrv.override later
            # callPackage makes everything from
            # pkgs already available, however,
            # so you wont need to pass much
          };
        in
        {
          # output the package as yourflake.packages.${system}.default
          # so that the cli commands know where to look for it
          default = powerstation;
        }
      );
    };
}
