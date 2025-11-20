{
  description = "Daemon which connects to active mpv instances, saving a history of what I watch/listen to";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Define the main package with all dependencies
        python-mpv-jsonipc = pkgs.python3Packages.buildPythonPackage rec {
          pname = "python-mpv-jsonipc";
          version = "1.2.1";

          src = pkgs.fetchPypi {
            inherit pname version;
            hash = "sha256-lvSGQVj+OjXoCojve7LdrhS4mejsXS1yhofH+1HIB8w=";
          };

          format = "setuptools";
          propagatedBuildInputs = [
            pkgs.python3Packages.click
            pkgs.python3Packages.simplejson
          ];

          # pythonImportsCheck = [ "mpv_jsonipc" ];  # Import check disabled due to module name differences in packaging
        };

        python-kompress = pkgs.python3Packages.buildPythonPackage rec {
          pname = "kompress";
          version = "0.3.20250823"; # Use the latest version from PyPI

          src = pkgs.fetchPypi {
            inherit pname version;
            hash = "sha256-w8gNlQVhqF8xDm69gt9wuJ/luBuiIvswkeSh3gbK2Yo=";
          };

          pyproject = true;
          build-system = [
            pkgs.python3Packages.hatchling
            pkgs.python3Packages.hatch-vcs
          ];
          dependencies = [
            pkgs.python3Packages.typing-extensions
          ];

          pythonImportsCheck = [ "kompress" ];
        };

        mpv-history-daemon = pkgs.python3Packages.buildPythonApplication rec {
          pname = "mpv-history-daemon";
          version = "0.2.6";
          format = "setuptools";

          src = ./.;

          nativeBuildInputs = with pkgs.python3Packages; [
            setuptools
          ];

          propagatedBuildInputs = with pkgs.python3Packages; [
            click
            logzero
            simplejson
          ] ++ [
            python-mpv-jsonipc
            python-kompress
          ];

          # Include the script from bin/
          postInstall = ''
            install -Dm755 $src/bin/mpv_history_daemon_restart -t $out/bin/
          '';

          doCheck = false; # Disable tests during build

          pythonImportsCheck = [ "mpv_history_daemon" ];
        };
      in
      {
        packages = {
          default = mpv-history-daemon;
          inherit mpv-history-daemon python-mpv-jsonipc python-kompress;
        };

        apps = {
          default = flake-utils.lib.mkApp {
            drv = mpv-history-daemon;
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python3
            python3Packages.pip
            python3Packages.setuptools
            python3Packages.wheel
            python-mpv-jsonipc
            python-kompress
            mpv-history-daemon
          ];
        };
      }
    );
}