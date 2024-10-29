{
  stdenvNoCC,
  appimageTools,
  fetchurl,
  makeDesktopItem,
  copyDesktopItems,
  # makeWrapper,
}:
stdenvNoCC.mkDerivation rec {
  pname = "slippi-launcher";
  version = "2.11.6";

  src = appimageTools.wrapType2 rec {
    inherit pname version;

    src = fetchurl {
      url = "https://github.com/project-slippi/slippi-launcher/releases/download/v${version}/Slippi-Launcher-${version}-x86_64.AppImage";
      hash = "sha256-pdBPCQ0GL7TFM5o48noc6Tovmeq+f2M3wpallems8aE=";
    };

    # extraInstallCommands = ''
    #   source "${makeWrapper}/nix-support/setup-hook"
    #   wrapProgram $out/bin/slippi-launcher-${version} \
    #     --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
    # '';
  };

  desktopItems = [
    (makeDesktopItem {
      name = "slippi-launcher";
      exec = "slippi-launcher";
      icon = "slippi-launcher";
      desktopName = "Slippi Launcher";
      comment = "The way to play Slippi Online and watch replays";
      type = "Application";
      categories = ["Game"];
      keywords = ["slippi" "melee" "rollback"];
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    cp -r "$src/bin" "$out"

    runHook postInstall
  '';

  nativeBuildInputs = [copyDesktopItems];
}
