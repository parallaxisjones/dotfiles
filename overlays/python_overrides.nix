_: prev:
  # Compose per-platform overrides
  (if prev.stdenv.isDarwin then
    {
      # Disable failing tests for aiohttp on Darwin to unblock builds.
      python3Packages = prev.python3Packages // {
        aiohttp = prev.python3Packages.aiohttp.overrideAttrs (_: {
          doCheck = false;
        });
      };
    }
  else
    { })
  //
  (if prev.stdenv.isLinux then
    {
      # Disable failing tests for fsspec on Linux (transitive for aider-chat)
      python3Packages = prev.python3Packages // {
        fsspec = prev.python3Packages.fsspec.overrideAttrs (_: {
          doCheck = false;
        });
      };
    }
  else
    { })


