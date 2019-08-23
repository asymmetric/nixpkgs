{ lib, python3Packages, fetchFromGitHub
, curl
, dnsutils
, gawk
, gnused
, libidn2
, sqlite
, systemd
}:

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

  patches = [ ./patches/pi-hole.patch ];
  postPatch = ''
    patchShebangs pihole

    sed -i "s~pihole -f~$out/bin/pihole -f~" pihole
    sed -i "s~/opt~$out/opt~" advanced/Scripts/*.sh pihole gravity.sh
    sed -i "s~/usr/local/bin/~$out/bin/~" gravity.sh advanced/Scripts/*.sh
    sed -i "s~/etc/dnsmasq.d~/etc/pihole/dnsmasq.d~" advanced/Scripts/*.sh

    # No usable tests
    substituteInPlace setup.py --replace "'pytest-runner'" ""
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv pihole $out/bin/pihole

    mkdir -p $out/opt/pihole
    mv -t $out/opt/pihole \
      advanced/Scripts/* \
      gravity.sh
    chmod u+x $out/opt/pihole/*.sh

    mkdir -p $out/var/www/pihole
    mv -t $out/var/www/pihole \
      advanced/index.php \
      advanced/blockingpage.css

    wrapProgram $out/bin/pihole --prefix PATH : "${lib.makeBinPath ([ curl dnsutils gawk gnused libidn2 sqlite systemd ])}"
  '';

  meta = with lib; {
    homepage = "https://pi-hole.org";
    license = licenses.eupl12;
    maintainers = [ maintainers.asymmetric ];
  };
}
