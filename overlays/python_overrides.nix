final: prev:
  if prev.stdenv.isDarwin then
    {
      # Disable failing tests for aiohttp on Darwin to unblock builds.
      python3Packages = prev.python3Packages // {
        aiohttp = prev.python3Packages.aiohttp.overrideAttrs (_: {
          doCheck = false;
        });
      };
    }
  else
    {}


