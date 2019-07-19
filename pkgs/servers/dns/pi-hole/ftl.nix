{ stdenv, lib, gmp, nettle, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "pi-hole-ftl";
  version = "4.3.1";

  src = fetchFromGitHub {
    owner = "pi-hole";
    repo = "FTL";
    rev = "v${version}";
    sha256 = "05bvwmfqg52ic7f95d419hnqnxlixnqzx2fi93ki3axxz1g56l6p";
  };

  patches = [ ./patches/ftl.patch ];

  buildInputs = [ gmp nettle ];
}
