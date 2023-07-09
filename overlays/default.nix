{
  indicator = import ./indicator;
  mate-wayland = import ./mate-wayland;
  portal = import ./portal;
  qt5ct = import ./qt5ct;
  default = self: super: super.lib.filterAttrs
    (name: _: name != "modules" && name != "overlays")
    (import ../. {
      pkgs = super;
      inputs = (import ../flake-compat.nix).inputs;
    });
}
