{
  description = "Fuck Screenshot — suppress the GNOME Shell screenshot notification banner";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default-linux";
  };

  outputs =
    { self, nixpkgs, systems, ... }:
    let
      uuid = "fuck-screenshot@local";
      eachSystem = nixpkgs.lib.genAttrs (import systems);
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = eachSystem (
        system:
        let
          pkgs = pkgsFor system;

          fuck-screenshot = pkgs.stdenvNoCC.mkDerivation {
            pname = "fuck-screenshot-gnome-extension";
            version = "1";
            src = ./.;
            dontConfigure = true;
            dontBuild = true;
            installPhase = ''
              runHook preInstall
              dir="$out/share/gnome-shell/extensions/${uuid}"
              mkdir -p "$dir"
              cp -r extension/. "$dir"/
              runHook postInstall
            '';
            passthru.extensionUuid = uuid;
            meta = {
              description = "Suppresses the GNOME Shell screenshot captured notification";
              license = pkgs.lib.licenses.agpl3Only;
              platforms = pkgs.lib.platforms.linux;
            };
          };

          # `nix run` friendly installer: copies the extension into the user's
          # extension directory and enables it.
          install = pkgs.writeShellApplication {
            name = "install-fuck-screenshot";
            runtimeInputs = with pkgs; [
              coreutils
              gnome-shell
            ];
            text = ''
              uuid="${uuid}"
              source="${fuck-screenshot}/share/gnome-shell/extensions/$uuid"
              dest="''${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions/$uuid"

              mkdir -p "$(dirname "$dest")"
              rm -rf "$dest"
              cp -r "$source" "$dest"
              chmod -R u+w "$dest"

              gnome-extensions enable "$uuid" || true

              echo "Installed $uuid to $dest"
              echo "On Wayland, log out and back in to load the extension."
            '';
          };
        in
        {
          inherit fuck-screenshot install;
          default = fuck-screenshot;
        }
      );

      apps = eachSystem (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.install}/bin/install-fuck-screenshot";
        };
      });

      checks = eachSystem (system: {
        inherit (self.packages.${system}) fuck-screenshot;
      });

      formatter = eachSystem (system: (pkgsFor system).nixpkgs-fmt);

      devShells = eachSystem (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              gjs
              glib
              gobject-introspection
              pkg-config
              nodejs
              jq
              zip
              unzip
            ];
          };
        }
      );
    };
}
