# Generates the documentation for library functions via nixdoc.

{ pkgs, locationsXml, libsets }:

with pkgs; stdenv.mkDerivation {
  name = "nixpkgs-lib-docs";
  src = ../../lib;

  buildInputs = [ nixdoc ];
  installPhase = ''
    function docgen {
      # TODO: wrap lib.$1 in <literal>, make nixdoc not escape it
      if [[ -e "../lib/$1.nix" ]]; then
        nixdoc --category "$1" --description "lib.$1: $2" --file "$1.nix" >> "$out/index.md"
      else
        nixdoc --category "$1" --description "lib.$1: $2" --file "$1/default.nix" >> "$out/index.md"
      fi
    }

    mkdir -p "$out"

    ${lib.concatMapStrings ({ name, description }: ''
      docgen ${name} ${lib.escapeShellArg description}
    '') libsets}

    ln -s ${locationsXml} $out/locations.xml
  '';
}
