{ lib, python3Packages, fetchFromGitHub, bash }:

python3Packages.buildPythonApplication rec {
  pname = "pi-hole";
  version = "4.3.1";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "v${version}";
    sha256 = "0pa6j835fb55bcl02v05xnbayjnw1ksibmvgkfr1apqm98xw6389";
  };

  doCheck = false;
  postPatch = ''
    substituteInPlace pihole \
      --replace /bin/bash ${bash}/bin/bash
    # Is in setup_requires but not used in setup.py...
    substituteInPlace setup.py --replace "'pytest-runner'" ""
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv pihole $out/bin/pihole
  '';

  meta = with lib; {
    homepage = "https://pi-hole.org";
  };
}
