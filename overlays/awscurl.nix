# awscurl is not in nixpkgs, so package it from PyPI as a Python application.
# https://github.com/okigan/awscurl
_: prev: {
  awscurl = prev.python3Packages.buildPythonApplication rec {
    pname = "awscurl";
    version = "0.44";
    pyproject = true;

    src = prev.fetchPypi {
      inherit pname version;
      hash = "sha256-EwVuhnrDP1VvKdNmIQK/w8QCWeoDfG2BfFkU27K72Ug=";
    };

    build-system = with prev.python3Packages; [ setuptools ];

    dependencies = with prev.python3Packages; [
      requests
      configargparse
      configparser
      urllib3
      boto3
      botocore
      awscrt
    ];

    # Upstream test suite hits the network and pulls extra dev deps.
    doCheck = false;

    pythonImportsCheck = [ "awscurl" ];
  };
}
