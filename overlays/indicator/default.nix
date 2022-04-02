self: super: {
  mate = super.mate // {
    extraPackages = with self.mate; [
      atril
      caja-extensions
      engrampa
      eom
      mate-applets
      mate-backgrounds
      mate-calc
      mate-indicator-applet
      mate-media
      mate-netbook
      mate-power-manager
      mate-screensaver
      mate-sensors-applet
      mate-system-monitor
      mate-terminal
      mate-user-guide
      # mate-user-share
      mate-utils
      mozo
      pluma
    ];

    mate-indicator-applet = super.mate.mate-indicator-applet.overrideAttrs(oldAttrs: {
      postPatch = ''
        substituteInPlace src/applet-main.c \
          --replace '/usr' '/run/current-system/sw'
      '';
    });
  };

  libindicator-gtk3 = super.libindicator-gtk3.overrideAttrs(oldAttrs: {
    postPatch = oldAttrs.postPatch + ''
      substituteInPlace libindicator/indicator3-0.4.pc.in.in \
        --replace 'indicatordir=''${libdir}' 'indicatordir=/run/current-system/sw/lib'
    '';
  });

  onboard = super.onboard.overrideAttrs(oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [ super.libappindicator-gtk3 ];
  });
}
