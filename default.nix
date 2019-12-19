{ pkgs ? import <nixpkgs> {} }:

with pkgs;

rec {
	kotatogram-desktop = qt5.callPackage ./pkgs/kotatogram-desktop {
		inherit libtgvoip rlottie-tdesktop;
	};
	libtgvoip = callPackage ./pkgs/libtgvoip {};
	rlottie-tdesktop = callPackage ./pkgs/rlottie-tdesktop {};
}
