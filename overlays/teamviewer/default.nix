self: super: {
  teamviewer = super.teamviewer.overrideAttrs(oldAttrs: {
    buildInputs = [ dbus getconf qtbase qtx11extras libX11 ];
  });
}
