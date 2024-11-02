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
      rev = "20a7c5ffd8265fc6e45203ea2536f7b1965be19a";
      hash = "sha256-guz5+RWL1y7gNcS56xvLcydBKedj3kG+lQsAe7IuPA4=";
    };
  in rec {
    qtbase = qt6.qtbase.overrideAttrs(oldAttrs: {
      patches = oldAttrs.patches ++ [
        "${patches}/qtbase_6.7.2/0001-spellcheck-underline-from-chrome.patch"
        "${patches}/qtbase_6.7.2/0002-improve-apostrophe-processing.patch"
        "${patches}/qtbase_6.7.2/0003-allow-creating-floating-panels-macos.patch"
        "${patches}/qtbase_6.7.2/0004-fix-file-dialog-on-windows.patch"
        "${patches}/qtbase_6.7.2/0005-fix-launching-mail-program-on-windows.patch"
        "${patches}/qtbase_6.7.2/0006-save-dirtyopaquechildren.patch"
        "${patches}/qtbase_6.7.2/0007-always-use-xft-font-conf.patch"
        "${patches}/qtbase_6.7.2/0008-catch-cocoa-dock-menu.patch"
        "${patches}/qtbase_6.7.2/0009-fix-race-in-windows-timers.patch"
        "${patches}/qtbase_6.7.2/0010-nicer-platformtheme-choosing.patch"
        "${patches}/qtbase_6.7.2/0011-reset-current-context-on-error.patch"
        "${patches}/qtbase_6.7.2/0012-reset-opengl-widget-on-context-loss.patch"
        "${patches}/qtbase_6.7.2/0013-no-jpeg-chroma-subsampling.patch"
        "${patches}/qtbase_6.7.2/0014-convert-qimage-to-srgb.patch"
        "${patches}/qtbase_6.7.2/0015-lcms2.patch"
        "${patches}/qtbase_6.7.2/0016-better-color-scheme-support.patch"
        "${patches}/qtbase_6.7.2/0017-translucent-captioned-window-on-windows.patch"
        "${patches}/qtbase_6.7.2/0018-allow-bordered-translucent-macos.patch"
        "${patches}/qtbase_6.7.2/0019-better-open-url-linux.patch"
        "${patches}/qtbase_6.7.2/0020-follow-highdpi-rounding-policy-for-platform-dpr.patch"
        "${patches}/qtbase_6.7.2/0021-fill-transparent-hidpi-backing-store.patch"
        "${patches}/qtbase_6.7.2/0022-fix-backing-store-rhi-unneeded-copy.patch"
        "${patches}/qtbase_6.7.2/0023-fix-backing-store-opengl-subimage-unneeded-copy.patch"
        "${patches}/qtbase_6.7.2/0024-portal-proxy-resolver.patch"
        "${patches}/qtbase_6.7.2/0025-fix-focus-in-hidden-window.patch"
        "${patches}/qtbase_6.7.2/0026-fix-only-emoji-line.patch"
        "${patches}/qtbase_6.7.2/0027-fix-rtl-cursor-move-up.patch"
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
        "${patches}/qtwayland_6.7.2/0001-always-fractional-scale.patch"
        "${patches}/qtwayland_6.7.2/0002-offload-transparency-filling-to-hidpi.patch"
        "${patches}/qtwayland_6.7.2/0003-fix-gtk4-embedding.patch"
        "${patches}/qtwayland_6.7.2/0004-QWaylandShmBackingStore-Preserve-buffer-contents-bet.patch"
        "${patches}/qtwayland_6.7.2/0005-avoid-needlessly-initiailizing-opengl.patch"
        # "${patches}/qtwayland_6.7.2/0006-fix-media-viewer-on-gnome.patch"
        "${patches}/qtwayland_6.7.2/0007-owning-rhi-backing-store.patch"
      ];
    });

    with-patched-qt = drv: (lib.foldr ({ oldDependency, newDependency }: drv:
      replaceDependency { inherit oldDependency newDependency drv; }
    ) drv ([
      {
        oldDependency = qt6.qtbase;
        newDependency = desktop-app.qtbase;
      }
    ] ++ lib.optionals stdenv.hostPlatform.isLinux [
      {
        oldDependency = qt6.qtwayland;
        newDependency = desktop-app.qtwayland;
      }
    ])).overrideAttrs {
      meta = drv.meta;
    };
  };

  exo2 = google-fonts.override { fonts = [ "Exo2" ]; };

  hplipWithPlugin = if stdenv.hostPlatform.isLinux then pkgs.hplipWithPlugin else null;

  kotatogram-desktop = kdePackages.callPackage ./pkgs/kotatogram-desktop {
    stdenv = if stdenv.hostPlatform.isDarwin
      then overrideSDK stdenv "11.0"
      else stdenv;
  };

  kotatogram-desktop-with-webkit = callPackage ./pkgs/kotatogram-desktop/with-webkit.nix {
    inherit kotatogram-desktop;
  };

  kotatogram-desktop-with-patched-qt = desktop-app.with-patched-qt kotatogram-desktop;

  kotatogram-desktop-with-patched-qt-and-webkit = if stdenv.hostPlatform.isLinux then desktop-app.with-patched-qt kotatogram-desktop-with-webkit else null;

  nerd-fonts-symbols = nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; };

  nixos-collect-garbage = writeShellScriptBin "nixos-collect-garbage" ''
    ${nix}/bin/nix-collect-garbage "$@"
    /run/current-system/bin/switch-to-configuration boot
  '';

  qt5ct = import ./pkgs/qt5ct pkgs;

  qt6ct = import ./pkgs/qt6ct pkgs;

  silver = callPackage ./pkgs/silver {};

  ttf-croscore = google-fonts.override { fonts = [ "Arimo" "Cousine" "Tinos" ]; };
}) { inherit pkgs; }
