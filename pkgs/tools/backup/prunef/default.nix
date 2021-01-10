{ stdenv, buildGoModule, fetchgit, installShellFiles, scdoc }:

buildGoModule rec {
  pname = "prunef";
  version = "0.2.0";

  src = fetchgit {
    url = "https://git.sr.ht/~apreiml/prunef";
    rev = "v${version}";
    sha256 = "1pq3wnnnljhw877c0rcqr6b54wf66kp9vgi1ql09bkrr3m2md99v";
  };

  vendorSha256 = "0sjjj9z1dhilhpc8pq4154czrb79z9cm044jvn75kxcjv6v5l2m5";

  nativeBuildInputs = [ installShellFiles scdoc ];

  postBuild = ''
    scdoc < prunef.1.scd > prunef.1
    installManPage prunef.1
  '';

  meta = with stdenv.lib; {
    description = "A backup rotation filter for your shell";
    homepage = "https://git.sr.ht/~apreiml/prunef";
    license = licenses.mit;
    maintainers = [ maintainers.asymmetric ];
  };
}
