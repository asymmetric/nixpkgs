{ lib
, python2Packages
, fetchFromGitHub
, bash
, pytest
, testinfra
}:

python2Packages.buildPythonApplication rec {
  pname = "pi-hole";
  version = "4.3.1";

  src = fetchFromGitHub {
    owner = pname;
    repo  = pname;
    rev = "v${version}";
    sha256 = "0pa6j835fb55bcl02v05xnbayjnw1ksibmvgkfr1apqm98xw6389";
  };

  checkInputs = [ pytest testinfra ];

  postPatch = ''
    substituteInPlace pihole \
      --replace /bin/bash ${bash}/bin/bash \
      --replace /opt/pihole $out/opt/pihole

    # Is in setup_requires but not used in setup.py...
    substituteInPlace setup.py --replace "'pytest-runner'" ""
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv pihole $out/bin/pihole
    mkdir -p $out/opt/pihole
    mv advanced/Scripts/* $out/opt/pihole
  '';

  meta = with lib; {
    description = "A black hole for Internet advertisements";
    homepage = "https://pi-hole.org";
    license = linceses.eupl12;
    maintainers = [ maintainers.asymmetric ];
  };
}
