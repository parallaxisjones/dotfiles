# overlays/nodejs-20-override.nix
_: prev:
if prev.stdenv.isDarwin then rec {
  # On Darwin, pin NodeJS to 20 for compatibility with local tooling
  nodejs = prev.nodejs_20;
  nodePackages = prev.nodePackages.override { inherit nodejs; };
} else { }
