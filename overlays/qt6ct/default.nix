self: super:

{
  kdePackages = super.kdePackages.overrideScope' (_: _: {
    qt6ct = (import ../.. { pkgs = super; }).qt5ct;
  });
}
