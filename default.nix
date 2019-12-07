{ pkgs ? import <nixpkgs> {} }:

with pkgs;

rec {
	kotatogram-desktop = qt5.callPackage ./kotatogram-desktop {
		inherit libtgvoip rlottie;
	};
	libtgvoip = callPackage ./libtgvoip {};
	rlottie = callPackage ./rlottie {};
}
