pkgs: with pkgs; with kdePackages; with qt6Packages; qt6ct.overrideAttrs(oldAttrs: rec {
  buildInputs = oldAttrs.buildInputs ++ ([
    qtdeclarative kconfig kcolorscheme kiconthemes
  ]);

  nativeBuildInputs =  [
    cmake wrapQtAppsHook qttools
  ];

  patches = [
    ./qt6ct-shenanigans.patch
  ];

  cmakeFlags = [
    "-DPLUGINDIR=${placeholder "out"}/${qtbase.qtPluginPrefix}"
  ];
})
