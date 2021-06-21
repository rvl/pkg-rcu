# TODO: The flake doesn't work yet.
{
  description = "RCU flake";

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, nixpkgs }: {
    overlay = ./overlay.nix;
    packages.x86_64-linux.rcu = nixpkgs.legacyPackages.x86_64-linux.rcu;
    defaultPackage.x86_64-linux = self.packages.x86_64-linux.rcu;
    defaultApp.x86_64-linux.program = "${self.defaultPackage.x86_64-linux}/bin/rcu";
  };
}
