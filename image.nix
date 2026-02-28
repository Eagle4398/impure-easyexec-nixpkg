{ pkgs }:

pkgs.dockerTools.pullImage {
  imageName      = import ./address.nix;
  imageDigest    = import ./digestHash.nix;
  sha256         = import ./imageHash.nix;
  finalImageName = "impure-env";
  finalImageTag  = "latest";
}
