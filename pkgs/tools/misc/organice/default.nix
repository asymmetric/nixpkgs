{ stdenv, bash, nodejs, nodePackages, fetchFromGitHub }:

let
  node_modules = "${nodePackages."organice-build-deps-../../tools/misc/organice"}/lib/node_modules/organice-build-deps/node_modules";
  fef = "${nodePackages."organice-build-deps-../../tools/misc/organice"}/lib/node_modules";
in
  stdenv.mkDerivation rec {
    pname = "organice";
    version = "2020-05-06";

    src = fetchFromGitHub {
      owner = "200ok-ch";
      repo = pname;
      rev = "5fbb2818e9c6f2e201a0465283eef375941ec07c";
      sha256 = "1mvg6ddjmq3ya32jmjdnqm1giw1p95pj55b1h2bgkyslsp7f2szg";
    };

    nativeBuildInputs = [
      nodejs
      nodePackages."organice-build-deps-../../tools/misc/organice"
    ];

    patchPhase = ''
      patchShebangs bin/compile_search_parser.sh
      sed -i 's,npx,${nodejs}/bin/npx,' bin/compile_search_parser.sh
    '';

    buildPhase = ''
      set -x
      # npm run build --no-update-notifier
      export PATH=${node_modules}/.bin:$PATH

      ${bash}/bin/bash bin/compile_search_parser.sh

      ${nodejs}/bin/npx react-scripts build

      # ${node_modules}/.bin/react-scripts build

      # cp -R ${node_modules} .
      # node_modules/react-scripts/bin/react-scripts.js build
    '';

    installPhase = ''
      install build $out
    '';

    meta = with stdenv.lib; {
      description = "An implementation of Org mode without the dependency of Emacs - built for mobile and desktop browsers";
      homepage = "https://organice.200ok.ch/";
      license = licenses.agpl3;
      maintainers = [ maintainers.asymmetric ];
      platforms = platforms.all;
    };
  }
