_: prev:
if prev.stdenv.isDarwin then {
  _1password-gui = prev._1password-gui.overrideAttrs (old: {
    src = prev.fetchurl {
      inherit (old.src) url;
      hash = "sha256-bZD8LCLTGXRpNF/FqoSHvI69pquAcQGa1mdagWypgDU=";
    };
  });
} else { }
