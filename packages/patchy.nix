{ stdenvNoCC, fennel, coreutils, ... }:
let inherit (import ../constants.nix) FNL_ROOT;
in stdenvNoCC.mkDerivation rec {
  pname = "patchy-${version}";
  version = "config";
  nativeBuildInputs = [ coreutils fennel ];
  dontUnpack = true; # there's no src, don't unpack.

  buildPhase = ''
    # map $1 to where the Fennel source files are.
    function map_source {
      echo "${FNL_ROOT}/$1"
    }
    # map $1 to where the compiled Lua is placed in the /nix/store.
    function map_out {
      echo "$out/lua/patchy/$1"
    }
    # recursively compiles all files at FNL_ROOT.
    function compile_fnl {
      for entry in $(map_source "$1/*"); do
        relentry=$(basename "$entry")

        if [[ -f $entry ]]; then
          filename="''${relentry%.*}"
          echo "compiled $relentry into $(map_out \"$filename.lua\")"
          fennel -c $entry > $(map_out "$1/$filename.lua") && echo "compiled '$relentry'."

        elif [[ -d $entry ]]; then
          mkdir -p $(map_out $relentry)
          compile_fnl "$1/$relentry"
        fi
      done
    }

    mkdir -p $out/lua/patchy
    echo -e "require \"patchy\"" > $out/init.lua
    compile_fnl ""
  '';
}
