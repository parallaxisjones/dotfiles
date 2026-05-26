_: prev:
if prev.stdenv.isDarwin then rec {
  nodejs = prev.nodejs_22;
  nodePackages = prev.nodePackages.override { inherit nodejs; };
} else { }
