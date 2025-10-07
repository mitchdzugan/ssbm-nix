{
  stdenv,
  lib,
  makeDesktopItem,
  # slippi-desktop,
  playbackSlippi,
  fetchFromGitHub,
  makeWrapper,
  mesa,
  pkg-config,
  cmake,
  bluez,
  ffmpeg,
  libao,
  libGLU,
  gtk2,
  gtk3,
  wrapGAppsHook,
  glib,
  glib-networking,
  gettext,
  xorg,
  readline,
  openal,
  libevdev,
  portaudio,
  libusb1,
  libpulseaudio,
  udev,
  gnumake,
  wxGTK32,
  gdk-pixbuf,
  soundtouch,
  miniupnpc,
  mbedtls_2,
  curl,
  lzo,
  sfml,
  enet,
  xdg-utils,
  hidapi,
  webkitgtk_6_0,
  vulkan-loader,
  rustc,
  cargo,
  rustPlatform,
  alsa-lib,
  ...
}: let
  netplay-desktop = makeDesktopItem {
    name = "Slippi Online";
    exec = "slippi-netplay";
    comment = "Play Melee Online!";
    desktopName = "Slippi-Netplay";
    genericName = "Wii/GameCube Emulator";
    categories = ["Game" "Emulator"];
    startupNotify = false;
  };

  playback-desktop = makeDesktopItem {
    name = "Slippi Playback";
    exec = "slippi-playback";
    comment = "Watch Your Slippi Replays";
    desktopName = "Slippi-Playback";
    genericName = "Wii/GameCube Emulator";
    categories = ["Game" "Emulator"];
    startupNotify = false;
  };
in
  stdenv.mkDerivation rec {
    pname =
      if playbackSlippi
      then "slippi-ishiiruka-playback"
      else "slippi-ishiiruka-netplay";
    version =
      if playbackSlippi
      then "3.5.1"
      else "3.5.1";
    name = "${pname}-${version}";
    src = fetchFromGitHub {
      owner = "project-slippi";
      repo = "Ishiiruka";
      rev =
        if playbackSlippi
        then "90f18e459a757f6112859c6a2526179359f3c0d6"
        else "v3.5.1";

      hash =
        if playbackSlippi
        then "sha256-yiu0ObLc0qbE3r9xUnm0ktpoH/i1k16JqGxgm5KIkGI="
        else "sha256-VW49r3cgMwfrukeAYglffMlkgwDAky5yumJLqnaoWAA=";
      fetchSubmodules = true;
    };

    cargoRoot = "Externals/SlippiRustExtensions";

    cargoDeps = rustPlatform.importCargoLock {
      lockFile = "${src}/${cargoRoot}/Cargo.lock";
      outputHashes = {
        "cpal-0.16.0" = "sha256-4C7YWUx6SZnZy6pwy0CCL3yPgaMflN1atN3cUNMbcmU=";
      };
    };

    outputs = ["out"];
    makeFlags = ["VERSION=us" "-s" "VERBOSE=1"];
    hardeningDisable = ["format"];

    cmakeFlags =
      [
        "-DLINUX_LOCAL_DEV=true"
        "-DGTK3_GLIBCONFIG_INCLUDE_DIR=${glib.out}/lib/glib-2.0/include"
        "-DENABLE_LTO=True"
        "-DCMAKE_SKIP_BUILD_RPATH=ON"
      ]
      ++ lib.optional playbackSlippi "-DIS_PLAYBACK=true";

    postBuild = ''
      cp -r -n ../Data/Sys/ Binaries/
      libPath="$out/lib/netplay"
      if [ "${if playbackSlippi then "1" else "0"}" == "1" ]; then
        libPath="$out/lib/playback"
        rm -rf Binaries/Sys/GameSettings
        cp -r ../Data/PlaybackGeckoCodes/. Binaries/Sys/GameSettings
        echo "" >> Binaries/Sys/GameSettings/GALE01r2.ini
        echo "" >> Binaries/Sys/GameSettings/GALE01r2.ini
        echo "\$Optional: Prevent Character Crowd Chants [Fizzi]" >> Binaries/Sys/GameSettings/GALE01r2.ini
        echo "* Disables crowd chanting for characters" >> Binaries/Sys/GameSettings/GALE01r2.ini
        echo "04321D70 38600000" >> Binaries/Sys/GameSettings/GALE01r2.ini
        echo "" >> Binaries/Sys/GameSettings/GALE01r2.ini
        echo "\$Optional: Prevent Crowd Noises [Fizzi]" >> Binaries/Sys/GameSettings/GALE01r2.ini
        echo "* Disables all other crowd oohs, ahs and whoahs" >> Binaries/Sys/GameSettings/GALE01r2.ini
        echo "04024170 3860FFFF" >> Binaries/Sys/GameSettings/GALE01r2.ini
      fi
      cp -r Binaries/ $out
      mkdir -p $libPath
      cp $build/build/source/build/Source/Core/DolphinWX/libslippi_rust_extensions.so $libPath
      mkdir -p $out/bin
    '';

    installPhase =
      if playbackSlippi
      then ''
        mkdir -p "$out/playbackDir"
        mv "$out/dolphin-emu" "$out/playbackDir/dolphin-emu"
        mv "$out/traversal_server" "$out/playbackDir/traversal_server"
        mv "$out/Sys" "$out/playbackDir/Sys"
        wrapProgram "$out/playbackDir/dolphin-emu" \
          --set "GDK_BACKEND" "x11" \
          --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules" \
          --prefix LD_LIBRARY_PATH : "${vulkan-loader}/lib" \
          --prefix LD_LIBRARY_PATH : "$out/lib/playback" \
          --prefix PATH : "${xdg-utils}/bin"
        ln -s $out/playbackDir/dolphin-emu $out/bin/slippi-playback
        ln -s ${playback-desktop}/share/applications $out/share
      ''
      else ''
        wrapProgram "$out/dolphin-emu" \
          --set "GDK_BACKEND" "x11" \
          --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules" \
          --prefix LD_LIBRARY_PATH : "${vulkan-loader}/lib" \
          --prefix LD_LIBRARY_PATH : "$out/lib/netplay" \
          --prefix PATH : "${xdg-utils}/bin"
        ln -s $out/dolphin-emu $out/bin/slippi-netplay
        ln -s ${netplay-desktop}/share/applications $out/share
      '';

    nativeBuildInputs = [
      pkg-config
      cmake
      wrapGAppsHook
      rustc
      cargo
      rustPlatform.cargoSetupHook
    ];

    buildInputs = [
      vulkan-loader
      makeWrapper
      mesa
      pkg-config
      bluez
      ffmpeg
      libao
      libGLU
      glib
      glib-networking
      gettext
      xorg.libpthreadstubs
      xorg.libXrandr
      xorg.libXext
      xorg.libX11
      xorg.libSM
      readline
      openal
      libevdev
      xorg.libXdmcp
      portaudio
      libusb1
      libpulseaudio
      udev
      gnumake
      wxGTK32
      gtk2
      gtk3
      gdk-pixbuf
      soundtouch
      miniupnpc
      mbedtls_2
      curl
      lzo
      sfml
      enet
      xdg-utils
      hidapi
      webkitgtk_6_0
      alsa-lib
    ];
  }
