{ src ? ./.
# Supply --argstr productKey CODE to download
, productKey ? null
}:

let
  lock = builtins.fromJSON (builtins.readFile (src + /flake.lock));
  flake-compat-input = lock.nodes.root.inputs.flake-compat;
  nixpkgs-input = lock.nodes.root.inputs.nixpkgs;
  flakeCompat = import (builtins.fetchTarball {
    url = "https://api.github.com/repos/input-output-hk/flake-compat/tarball/${lock.nodes.${flake-compat-input}.locked.rev}";
    sha256 = lock.nodes.${flake-compat-input}.locked.narHash;
  });
  pkgs = import
    (builtins.fetchTarball {
      url = "https://api.github.com/repos/NixOS/nixpkgs/tarball/${lock.nodes.${nixpkgs-input}.locked.rev}";
      sha256 = lock.nodes.${nixpkgs-input}.locked.narHash;
    })
    { };
in
  flakeCompat {
    inherit src pkgs;
    override-inputs = {
      customConfig.rcu = { inherit productKey; };
    };
  }
