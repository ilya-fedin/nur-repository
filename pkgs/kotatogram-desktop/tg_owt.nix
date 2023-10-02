{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, cmake
, ninja
, yasm
, libjpeg
, openssl
, libopus
, ffmpeg
, protobuf
, openh264
, crc32c
, libvpx
, libX11
, libXtst
, libXcomposite
, libXdamage
, libXext
, libXrender
, libXrandr
, libXi
, glib
, abseil-cpp
, pipewire
, mesa
, libdrm
, libGL
, Cocoa
, AppKit
, IOKit
, IOSurface
, Foundation
, AVFoundation
, CoreMedia
, VideoToolbox
, CoreGraphics
, CoreVideo
, OpenGL
, Metal
, MetalKit
, CoreFoundation
, ApplicationServices
}:

stdenv.mkDerivation {
  pname = "tg_owt";
  version = "unstable-2023-09-21";

  src = fetchFromGitHub {
    owner = "desktop-app";
    repo = "tg_owt";
    rev = "592b14d13bf9103226e90a83571e24c49f6bfdcd";
    sha256 = "sha256-MtqsJIFLZYpEjyTpI52s0cTGOAvuZI1VLNENk/5tF9I=";
    fetchSubmodules = true;
  };

  postPatch = lib.optionalString stdenv.isLinux ''
    substituteInPlace src/modules/desktop_capture/linux/wayland/egl_dmabuf.cc \
      --replace '"libEGL.so.1"' '"${libGL}/lib/libEGL.so.1"' \
      --replace '"libGL.so.1"' '"${libGL}/lib/libGL.so.1"' \
      --replace '"libgbm.so.1"' '"${mesa}/lib/libgbm.so.1"' \
      --replace '"libdrm.so.2"' '"${libdrm}/lib/libdrm.so.2"'
  '';

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [ pkg-config cmake ninja yasm ];

  propagatedBuildInputs = [
    libjpeg
    openssl
    libopus
    ffmpeg
    protobuf
    openh264
    crc32c
    libvpx
    abseil-cpp
  ] ++ lib.optionals stdenv.isLinux [
    libX11
    libXtst
    libXcomposite
    libXdamage
    libXext
    libXrender
    libXrandr
    libXi
    glib
    pipewire
    mesa
    libdrm
    libGL
  ] ++ lib.optionals stdenv.isDarwin [
    Cocoa
    AppKit
    IOKit
    IOSurface
    Foundation
    AVFoundation
    CoreMedia
    VideoToolbox
    CoreGraphics
    CoreVideo
    OpenGL
    Metal
    MetalKit
    CoreFoundation
    ApplicationServices
  ];

  enableParallelBuilding = true;

  meta.license = lib.licenses.bsd3;
}
