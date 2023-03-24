{ lib, stdenv, fetchFromGitHub, fetchpatch, rustPlatform, darwin }:

rustPlatform.buildRustPackage rec {
  pname = "nixdoc";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "nix-community";
    repo  = "nixdoc";
    rev = "v${version}";
    sha256 = "sha256-eUgFE6dyEzNqc85dRs8qaRZVXXvIuJ+PPhWA5YtydfE=";
  };

  cargoSha256 = "sha256-6a4tWUMlCelS7dtQSv0XC5NQzQTPRcPRYhUifHKw1b8=";

  meta = with lib; {
    description = "Generate documentation for Nix functions";
    homepage    = "https://github.com/nix-community/nixdoc";
    license     = [ licenses.gpl3 ];
    maintainers = with maintainers; [ tazjin asymmetric ];
    platforms   = platforms.unix;
  };
}
