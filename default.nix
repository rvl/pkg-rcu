{ pkgs ? import <nixpkgs> { overlays = [(import ./overlay.nix)]; }
# Build LaTeX manual -- will download the full texlive if enabled
, buildUserManual ? false
# Supply --argstr productKey CODE to download
, productKey ? null
}:

pkgs.rcu.override {
  inherit buildUserManual productKey;
}
