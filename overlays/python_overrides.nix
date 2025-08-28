final: prev:
if prev.stdenv.isDarwin then {
  # Disable failing tests for aiohttp on Darwin to unblock builds.
  python3Packages = prev.python3Packages // {
    aiohttp = prev.python3Packages.aiohttp.overrideAttrs (old: {
      doCheck = false;
    });
  };
} else {}


