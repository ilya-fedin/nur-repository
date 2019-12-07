{ pkgs ? import <nixpkgs> {} }:

with pkgs;

rec {
	kotatogram-desktop = qt5.callPackage ./kotatogram-desktop {
		libtgvoip = libtgvoip;
		rlottie = rlottie;
	};
	libtgvoip = callPackage ./libtgvoip {};
	rlottie = callPackage ./rlottie {};
}