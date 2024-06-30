{ pkgs ? null }: (args: let
  pkgs = if (builtins.tryEval args.pkgs).success && args.pkgs != null
    then args.pkgs
    else import (import ./flake-compat.nix).inputs.nixpkgs {
      config = import ./nixpkgs-config.nix;
    };
in with pkgs; rec {
  modules = import ./modules;

  overlays = import ./overlays;

  cascadia-code-powerline = runCommand "cascadia-code-powerline" {} ''
    install -m644 --target $out/share/fonts/opentype -D ${cascadia-code}/share/fonts/opentype/CascadiaCodePL-*.otf
    install -m644 --target $out/share/fonts/truetype -D ${cascadia-code}/share/fonts/truetype/CascadiaCodePL-*.ttf
  '';

  desktop-app = let
    patches = fetchFromGitHub {
      owner = "desktop-app";
      repo = "patches";
      rev = "803f1c2630f5eb0d3b00ba3f095b3079c0533156";
      sha256 = "sha256-hUCnoXOcAxvJbspK55fdF56dmMGA+tPoQGNFeEws8lE=";
    };
  in rec {
    qtbase = qt6.qtbase.overrideAttrs(oldAttrs: {
      patches = oldAttrs.patches ++ [
        "${patches}/qtbase_6.7.1/0001-spellcheck-underline-from-chrome.patch"
        "${patches}/qtbase_6.7.1/0002-improve-apostrophe-processing.patch"
        #"${patches}/qtbase_6.7.1/0003-fix-shortcuts-on-macos.patch"
        "${patches}/qtbase_6.7.1/0004-allow-creating-floating-panels-macos.patch"
        "${patches}/qtbase_6.7.1/0005-fix-file-dialog-on-windows.patch"
        "${patches}/qtbase_6.7.1/0006-fix-launching-mail-program-on-windows.patch"
        "${patches}/qtbase_6.7.1/0007-save-dirtyopaquechildren.patch"
        "${patches}/qtbase_6.7.1/0008-always-use-xft-font-conf.patch"
        "${patches}/qtbase_6.7.1/0009-catch-cocoa-dock-menu.patch"
        "${patches}/qtbase_6.7.1/0010-fix-race-in-windows-timers.patch"
        "${patches}/qtbase_6.7.1/0011-nicer-platformtheme-choosing.patch"
        "${patches}/qtbase_6.7.1/0012-reset-current-context-on-error.patch"
        "${patches}/qtbase_6.7.1/0013-reset-opengl-widget-on-context-loss.patch"
        "${patches}/qtbase_6.7.1/0014-no-jpeg-chroma-subsampling.patch"
        "${patches}/qtbase_6.7.1/0015-convert-qimage-to-srgb.patch"
        "${patches}/qtbase_6.7.1/0016-lcms2.patch"
        "${patches}/qtbase_6.7.1/0017-better-color-scheme-support.patch"
        "${patches}/qtbase_6.7.1/0018-translucent-captioned-window-on-windows.patch"
        "${patches}/qtbase_6.7.1/0019-allow-bordered-translucent-macos.patch"
        "${patches}/qtbase_6.7.1/0020-better-open-url-linux.patch"
        "${patches}/qtbase_6.7.1/0021-follow-highdpi-rounding-policy-for-platform-dpr.patch"
        "${patches}/qtbase_6.7.1/0022-highdpi-downscale-property.patch"
        "${patches}/qtbase_6.7.1/0023-highdpi-downscale-wayland.patch"
        "${patches}/qtbase_6.7.1/0024-fill-transparent-hidpi-backing-store.patch"
        #"${patches}/qtbase_6.7.1/0025-update-window-geometry-on-scale-change.patch"
        "${patches}/qtbase_6.7.1/0026-fix-backing-store-rhi-unneeded-copy.patch"
        "${patches}/qtbase_6.7.1/0027-fix-backing-store-opengl-subimage-unneeded-copy.patch"
        "${patches}/qtbase_6.7.1/0028-portal-proxy-resolver.patch"
        "${patches}/qtbase_6.7.1/0029-fix-focus-in-hidden-window.patch"
        "${patches}/qtbase_6.7.1/0030-fix-only-emoji-line.patch"
      ];
    });

    qtwayland = (qt6.qtwayland.override {
      inherit qtbase;
      qtdeclarative = replaceDependency {
        oldDependency = qt6.qtbase;
        newDependency = qtbase;
        drv = qt6.qtdeclarative;
      };
    }).overrideAttrs(oldAttrs: {
      patches = oldAttrs.patches ++ [
        "${patches}/qtwayland_6.7.1/0001-always-fractional-scale.patch"
        "${patches}/qtwayland_6.7.1/0002-offload-transparency-filling-to-hidpi.patch"
        "${patches}/qtwayland_6.7.1/0003-popup-reposition.patch"
        "${patches}/qtwayland_6.7.1/0004-fix-gtk4-embedding.patch"
        "${patches}/qtwayland_6.7.1/0005-QWaylandShmBackingStore-Preserve-buffer-contents-bet.patch"
        "${patches}/qtwayland_6.7.1/0006-avoid-needlessly-initiailizing-opengl.patch"
        #"${patches}/qtwayland_6.7.1/0007-fix-media-viewer-on-gnome.patch"
        "${patches}/qtwayland_6.7.1/0008-owning-rhi-backing-store.patch"
      ];
    });

    with-patched-qt = drv: (lib.foldr ({ oldDependency, newDependency }: drv:
      replaceDependency { inherit oldDependency newDependency drv; }
    ) drv ([
      {
        oldDependency = qt6.qtbase;
        newDependency = desktop-app.qtbase;
      }
    ] ++ lib.optionals stdenv.isLinux [
      {
        oldDependency = qt6.qtwayland;
        newDependency = desktop-app.qtwayland;
      }
    ])).overrideAttrs {
      meta = drv.meta;
    };
  };

  exo2 = callPackage ./pkgs/exo2 {};

  hplipWithPlugin = if stdenv.isLinux then pkgs.hplipWithPlugin else null;

  kotatogram-desktop = kdePackages.callPackage ./pkgs/kotatogram-desktop {
    stdenv = if stdenv.isDarwin
      then overrideSDK stdenv "11.0"
      else stdenv;
  };

  kotatogram-desktop-with-webkit = callPackage ./pkgs/kotatogram-desktop/with-webkit.nix {
    inherit kotatogram-desktop;
  };

  kotatogram-desktop-with-patched-qt = desktop-app.with-patched-qt kotatogram-desktop;

  kotatogram-desktop-with-patched-qt-and-webkit = if stdenv.isLinux then desktop-app.with-patched-qt kotatogram-desktop-with-webkit else null;

  nerd-fonts-symbols = callPackage ./pkgs/nerd-fonts-symbols {};

  nixos-collect-garbage = writeShellScriptBin "nixos-collect-garbage" ''
    ${nix}/bin/nix-collect-garbage "$@"
    /run/current-system/bin/switch-to-configuration boot
  '';

  qt5ct = import ./pkgs/qt5ct pkgs;

  qt6ct = import ./pkgs/qt6ct pkgs;

  silver = callPackage ./pkgs/silver {};

  ttf-croscore = (import (import ./flake-compat.nix).inputs.nixpkgs-croscore {
    system = stdenv.system;
  }).noto-fonts.overrideAttrs(oldAttrs: {
    pname = "ttf-croscore";

    installPhase = ''
      install -m444 -Dt $out/share/fonts/truetype/croscore hinted/*/{Arimo,Cousine,Tinos}/*.ttf
    '';

    meta = oldAttrs.meta // {
      description = "Chrome OS core fonts";
      longDescription = "This package includes the Arimo, Cousine, and Tinos fonts.";
    };
  });
}) { inherit pkgs; }
