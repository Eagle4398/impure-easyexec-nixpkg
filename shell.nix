{
  pkgs ? import <nixpkgs> { },
}:

let
  address = import ./address.nix;
  storedDigest = import ./digestHash.nix;

  ubuntuBase = pkgs.dockerTools.pullImage {
    imageName = "docker.io/library/ubuntu";
    imageDigest = "sha256:3ba65aa20f86a0fad9df2b2c259c613df006b2e6d0bfcc8a146afb8c525a9751";
    hash = "sha256-bCO5Mxwq7BHzutDpXqTz/GzfExI4PrmjlfOB7JZlHNE=";
    finalImageName = "ubuntu";
    finalImageTag = "22.04";
  };
in

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    podman
    nix-prefetch-docker
    jq
  ];

  shellHook = ''
            set -euo pipefail

            ADDRESS="${address}"
            TAG="$ADDRESS:latest"
            STORED_DIGEST="${storedDigest}"
            REPO_DIR="$(pwd)"

            echo ">>> Loading Ubuntu base from Nix store..."
            podman load < ${ubuntuBase}

            echo ">>> Building image from Dockerfile..."
            podman build -t "$TAG" "$REPO_DIR"

ID_FILE="$REPO_DIR/.last-image-id"
CURRENT_ID=$(podman inspect "$TAG" --format '{{.Id}}')
STORED_ID="$(cat $ID_FILE 2>/dev/null || true)"
STORED_DIGEST="${storedDigest}"

echo ">>> CURRENT_ID:    $CURRENT_ID"
echo ">>> STORED_ID:     $STORED_ID"
echo ">>> STORED_DIGEST: $STORED_DIGEST"
echo ">>> ID_FILE path:  $ID_FILE"
echo ">>> ID_FILE exists: $(test -f $ID_FILE && echo yes || echo no)"

            if [ "$CURRENT_ID" = "$STORED_ID" ] && [ -n "$STORED_DIGEST" ]; then
              echo ">>> Image unchanged, skipping push."
              echo ">>> Building default.nix..."
              nix-build "$REPO_DIR/default.nix"
            else
              echo ">>> Image changed or first run, pushing to $ADDRESS..."
              podman push "$TAG"
echo "$CURRENT_ID" > "$ID_FILE"
echo ">>> Saved image ID to $ID_FILE"

              PAT="$(${pkgs.libsecret}/bin/secret-tool lookup application ghcr)"

              REGISTRY_DIGEST=$(${pkgs.skopeo}/bin/skopeo inspect \
                --creds "eagle4398:$PAT" \
                docker://"$ADDRESS":latest \
                | ${pkgs.jq}/bin/jq -r '.Digest')

              echo ">>> Updating digestHash.nix..."
              echo "\"$REGISTRY_DIGEST\"" > "$REPO_DIR/digestHash.nix"

              echo ">>> Running nix-prefetch-docker for imageHash.nix..."
NIX_HASH=$(REGISTRY_AUTH_FILE="$HOME/.config/containers/auth.json" \
  nix-prefetch-docker \
  --image-name  "$ADDRESS" \
  --image-digest "$REGISTRY_DIGEST" \
  --final-image-name "impure-env" \
  --final-image-tag  "latest" \
  2>&1 | grep "ImageHash:" | awk '{print $3}')

echo "\"$NIX_HASH\"" > "$REPO_DIR/imageHash.nix"

              echo ""
              echo ">>> digestHash.nix and imageHash.nix updated."
              echo ">>> Commit these before running nixos-rebuild."
              echo ""
            fi

            echo ">>> Building default.nix..."
            nix-build "$REPO_DIR/default.nix"
  '';
}
