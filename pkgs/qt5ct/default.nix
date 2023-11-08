pkgs: with pkgs; with libsForQt5; qt5ct.overrideAttrs(oldAttrs: rec {
  version = "1.8";

  src = fetchurl {
    url = "mirror://sourceforge/${oldAttrs.pname}/${oldAttrs.pname}-${version}.tar.bz2";
    sha256 = "sha256-I7dAVEFepBJDKHcu+ab5UIOpuGVp4SgDSj/3XfrYCOk=";
  };

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
