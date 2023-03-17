pkgs: with pkgs; with libsForQt5; qt5ct.overrideAttrs(oldAttrs: rec {
  buildInputs = oldAttrs.buildInputs ++ ([
    qtquickcontrols2 kconfig kconfigwidgets kiconthemes
  ]);

  nativeBuildInputs =  [
    cmake wrapQtAppsHook qttools
  ];

  patches = [
    ./qt5ct-shenanigans.patch
  ];

  cmakeFlags = [
    "-DPLUGINDIR=${placeholder "out"}/${qtbase.qtPluginPrefix}"
  ];
})
