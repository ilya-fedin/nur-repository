{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, callPackage
, pkg-config
, cmake
, ninja
, clang
, python3
, wrapQtAppsHook
, removeReferencesTo
, qtbase
, qtimageformats
, qtsvg
, qtwayland
, qt5compat
, lz4
, xxHash
, ffmpeg
, openalSoft
, minizip
, libopus
, alsa-lib
, libpulseaudio
, range-v3
, tl-expected
, hunspell
, gobject-introspection
, glibmm_2_68
, jemalloc
, rnnoise
, abseil-cpp
, microsoft_gsl
, boost
, fmt
, wayland
, libicns
, Cocoa
, CoreFoundation
, CoreServices
, CoreText
, CoreGraphics
, CoreMedia
, OpenGL
, AudioUnit
, ApplicationServices
, Foundation
, AGL
, Security
, SystemConfiguration
, Carbon
, AudioToolbox
, VideoToolbox
, VideoDecodeAcceleration
, AVFoundation
, CoreAudio
, CoreVideo
, CoreMediaIO
, QuartzCore
, AppKit
, CoreWLAN
, WebKit
, IOKit
, GSS
, MediaPlayer
, IOSurface
, Metal
, MetalKit
, NaturalLanguage
}:

with lib;

let
  tg_owt = callPackage ./tg_owt.nix {
    abseil-cpp = abseil-cpp.override {
      # abseil-cpp should use the same compiler
      inherit stdenv;
      cxxStandard = "20";
    };

    # tg_owt should use the same compiler
    inherit stdenv;

    inherit Cocoa AppKit IOKit IOSurface Foundation AVFoundation CoreMedia VideoToolbox
      CoreGraphics CoreVideo OpenGL Metal MetalKit CoreFoundation ApplicationServices;
  };

  cppgirPatch = fetchpatch {
    url = "https://gitlab.com/mnauw/cppgir/-/commit/960fe054ffaab7cf55722fea6094c56a8ee8f18e.patch";
    sha256 = "sha256-puflGBLr7uilAGPNMmktJ4BXyDMYwwdO+XQtVur5Zp8=";
  };

  mainProgram = if stdenv.isLinux then "kotatogram-desktop" else "Kotatogram";
in
stdenv.mkDerivation rec {
  pname = "kotatogram-desktop";
  version = "unstable-2023-10-03";

  src = fetchFromGitHub {
    owner = "ilya-fedin";
    repo = "kotatogram-desktop";
    rev = "d66ac95e45696499dd21fe1b7d0a19d031a64649";
    sha256 = "sha256-bf/m77PytoGLf8iCc08eVUsz7CMzTEit4UKhgzWoMr0=";
    fetchSubmodules = true;
  };

  patches = [
    ./macos.patch
    # lib_base: Add missing include for Qt 6.6
    (fetchpatch {
      url = "https://github.com/desktop-app/lib_base/commit/5ca91dbb811c84591780236abc31431e313faf39.patch";
      stripLen = 1;
      extraPrefix = "Telegram/lib_base/";
      hash = "sha256-eZkyMnPaAmUFYXiCmPhLRTw2Xdx0lylY+UVOckCsiaA=";
    })
  ];

  postPatch = optionalString stdenv.isLinux ''
    patch -p1 -d cmake/external/glib/cppgir < ${cppgirPatch}
    substituteInPlace Telegram/ThirdParty/libtgvoip/os/linux/AudioInputALSA.cpp \
      --replace '"libasound.so.2"' '"${alsa-lib}/lib/libasound.so.2"'
    substituteInPlace Telegram/ThirdParty/libtgvoip/os/linux/AudioOutputALSA.cpp \
      --replace '"libasound.so.2"' '"${alsa-lib}/lib/libasound.so.2"'
    substituteInPlace Telegram/ThirdParty/libtgvoip/os/linux/AudioPulse.cpp \
      --replace '"libpulse.so.0"' '"${libpulseaudio}/lib/libpulse.so.0"'
  '';

  # Wrapping the inside of the app bundles, avoiding double-wrapping
  dontWrapQtApps = stdenv.isDarwin;

  nativeBuildInputs = [
    pkg-config
    cmake
    ninja
    python3
    wrapQtAppsHook
    removeReferencesTo
  ] ++ optionals stdenv.isLinux [
    # to build bundled libdispatch
    clang
  ];

  buildInputs = [
    qtbase
    qtimageformats
    qtsvg
    lz4
    xxHash
    ffmpeg
    openalSoft
    minizip
    libopus
    range-v3
    tl-expected
    rnnoise
    tg_owt
    microsoft_gsl
  ] ++ optionals stdenv.isLinux [
    qtwayland
    alsa-lib
    libpulseaudio
    hunspell
    gobject-introspection
    glibmm_2_68
    jemalloc
    boost
    fmt
    wayland
  ] ++ optionals stdenv.isDarwin [
    Cocoa
    CoreFoundation
    CoreServices
    CoreText
    CoreGraphics
    CoreMedia
    OpenGL
    AudioUnit
    ApplicationServices
    Foundation
    AGL
    Security
    SystemConfiguration
    Carbon
    AudioToolbox
    VideoToolbox
    VideoDecodeAcceleration
    AVFoundation
    CoreAudio
    CoreVideo
    CoreMediaIO
    QuartzCore
    AppKit
    CoreWLAN
    WebKit
    IOKit
    GSS
    MediaPlayer
    IOSurface
    Metal
    NaturalLanguage
    libicns
  ];

  enableParallelBuilding = true;

  cmakeFlags = [
    "-DTDESKTOP_API_TEST=ON"
  ];

  installPhase = optionalString stdenv.isDarwin ''
    mkdir -p $out/Applications
    cp -r ${mainProgram}.app $out/Applications
    ln -s $out/{Applications/${mainProgram}.app/Contents/MacOS,bin}
  '';

  preFixup = ''
    remove-references-to -t ${stdenv.cc.cc} $out/bin/${mainProgram}
    remove-references-to -t ${microsoft_gsl} $out/bin/${mainProgram}
    remove-references-to -t ${tg_owt.dev} $out/bin/${mainProgram}
  '';

  postFixup = optionalString stdenv.isDarwin ''
    wrapQtApp $out/Applications/${mainProgram}.app/Contents/MacOS/${mainProgram}
  '';

  passthru = {
    inherit tg_owt;
  };

  meta = {
    inherit mainProgram;
    description = "Kotatogram – experimental Telegram Desktop fork";
    longDescription = ''
      Unofficial desktop client for the Telegram messenger, based on Telegram Desktop.

      It contains some useful (or purely cosmetic) features, but they could be unstable. A detailed list is available here: https://kotatogram.github.io/changes
    '';
    license = licenses.gpl3;
    platforms = platforms.all;
    homepage = "https://kotatogram.github.io";
    changelog = "https://github.com/kotatogram/kotatogram-desktop/releases/tag/k{version}";
    maintainers = with maintainers; [ ilya-fedin ];
  };
}
