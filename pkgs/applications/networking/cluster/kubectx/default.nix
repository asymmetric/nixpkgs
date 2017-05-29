{ stdenv, lib, fetchFromGitHub }:

with lib;

stdenv.mkDerivation rec {
  pname = "kubectx";
  version = "0.3.0";
  name = "${pname}-${version}";

  src = fetchFromGitHub {
    owner = "ahmetb";
    repo = pname;
    rev = "v${version}";
    sha256 = "1vyyj0r2ccw93plv3lp9kv5wzzjjs21wyiairnmqmkz4mzknfxmn";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin $out/include
    cp kubectx $out/bin
    cp utils.bash $out/include
  '';
}
