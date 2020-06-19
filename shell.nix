let
  moz_overlay = import (
    builtins.fetchTarball
        https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz
  );
  nixpkgs = import (
    builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz
  ) {
    overlays = [ moz_overlay ];
    config = { allowUnfree = true; };
  };
  frameworks = nixpkgs.darwin.apple_sdk.frameworks;
  rustChannels = (
    nixpkgs.rustChannelOf {
      date = "2020-01-30";
      channel = "stable";
    }
  ); # UPDATE: './rust-toolchain' to reflect on heroku
in
  with nixpkgs;
  stdenv.mkDerivation {
    name = "amitu-env";
    buildInputs = [ rustChannels.rust rustChannels.rust-src rustChannels.clippy-preview ];

    nativeBuildInputs = [
      elmPackages.elm-format
      elmPackages.elm
      stdenv.cc.cc.lib
      clang
      llvm
      file
      zsh
      wget
      locale
      wrk
      vim
      less
      htop
      awscli
      sqlite
      fzf
      tree
      curl
      ripgrep
      taskwarrior
      tokei
      man
      bat
      git
      gitAndTools.diff-so-fancy
      heroku
      openssl
      pkgconfig
      perl
      nixpkgs-fmt
      cacert
      libiconv
      ngrok

      python37
    ]
    ++ (
         stdenv.lib.optionals stdenv.isDarwin [
           frameworks.CoreServices
           frameworks.Security
           frameworks.CoreFoundation
           frameworks.Foundation
           frameworks.AppKit
         ]
    );

    RUST_BACKTRACE = 1;
    SOURCE_DATE_EPOCH = 315532800;

    shellHook = (
      if pkgs.stdenv.isDarwin then
        ''export NIX_LDFLAGS="-F${frameworks.AppKit}/Library/Frameworks -framework AppKit -F${frameworks.CoreServices}/Library/Frameworks -framework CoreServices -F${frameworks.CoreFoundation}/Library/Frameworks -framework CoreFoundation $NIX_LDFLAGS";''
      else
        ""
    )
      +
    ''
      export LD_LIBRARY_PATH=$(rustc --print sysroot)/lib:${stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH;
      export LIBCLANG_PATH="${llvmPackages.libclang}/lib"
      export ZDOTDIR=`pwd`;
      export HISTFILE=~/.zsh_history
      export CARGO_TARGET_DIR=`pwd`/target-nix
      echo "Using ${python37.name}, ${elmPackages.elm.name}, and ${rustChannels.rust.name}."
      unset MACOSX_DEPLOYMENT_TARGET
      source auto.sh
    '';
  }
