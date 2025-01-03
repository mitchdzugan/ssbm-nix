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
  webkitgtk,
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
      then "3.4.3"
      else "3.4.2";
    name = "${pname}-${version}";
    src = fetchFromGitHub {
      owner = "project-slippi";
      repo = "Ishiiruka";
      rev =
        if playbackSlippi
        then "70328610bd751858d5677576dd3b2ebf9ced37a6"
        else "v3.4.2";

      hash =
        if playbackSlippi
        then "sha256-uqy9YQnvryTHmskzlX+4st1VacnHbpC2gdC+PgvFUlA="
        else "sha256-zvjGKneUjOXsRkWuNNK2X0MwfduCYGA9Sp0osa9fQsU";
      fetchSubmodules = true;
    };

    cargoRoot = "Externals/SlippiRustExtensions";

    cargoDeps = rustPlatform.importCargoLock {
      lockFile = "${src}/${cargoRoot}/Cargo.lock";
      outputHashes = {
        "cpal-0.15.2" = "sha256-4C7YWUx6SZnZy6pwy0CCL3yPgaMflN1atN3cUNMbcmU=";
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
      if [ "${if playbackSlippi then "1" else "0"}" == "1" ]; then
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
      mkdir -p $out/lib
      cp $build/build/source/build/Source/Core/DolphinWX/libslippi_rust_extensions.so $out/lib
      mkdir -p $out/bin
    '';

    installPhase =
      if playbackSlippi
      then ''
        wrapProgram "$out/dolphin-emu" \
          --set "GDK_BACKEND" "x11" \
          --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules" \
          --prefix LD_LIBRARY_PATH : "${vulkan-loader}/lib" \
          --prefix PATH : "${xdg-utils}/bin"
        ln -s $out/dolphin-emu $out/bin/slippi-playback
        ln -s ${playback-desktop}/share/applications $out/share
      ''
      else ''
        wrapProgram "$out/dolphin-emu" \
          --set "GDK_BACKEND" "x11" \
          --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules" \
          --prefix LD_LIBRARY_PATH : "${vulkan-loader}/lib" \
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
      mesa.drivers
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
      webkitgtk
      alsa-lib
    ];
  }
