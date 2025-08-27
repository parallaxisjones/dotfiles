# This overlay removes the LICENSE file from the prettier package to avoid
# collisions with other packages that also have a LICENSE file.
_: prev: {
  prettier = prev.prettier.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      rm -f $out/LICENSE
    '';
  });
}
