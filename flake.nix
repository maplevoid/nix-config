{
  inputs = {
    # packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # unstable packages
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # home-manager
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # age-encrypted secrets
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    # declarative flatpak manager
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # theming framework
    stylix.url = "github:nix-community/stylix/release-26.05";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    # chinese fonts from windows iso
    chinese-fonts.url = "github:brsvh/chinese-fonts-overlay/main";

    # latest opencode from official repo
    # opencode.url = "github:sst/opencode";

    # run unpatched dynamic binaries on NixOS
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";

    # ai coding agents and development tools
    llm-agents.url = "github:numtide/llm-agents.nix";

    # hex local-first voice dictation
    hex.url = "github:anomalyco/hex";

  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    ...
  }: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    nixosConfigurations.thinkbook = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        username = "zway";
        hostname = "thinkbook";
      };

      modules = [
        ./hosts/thinkbook

        # nix-ld module for managing nix-ld
        inputs.nix-ld.nixosModules.nix-ld

        # agenix module for managing secrets
        inputs.agenix.nixosModules.default

        # home-manager module
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.extraSpecialArgs = {
            inherit inputs;
            username = "zway";
            hostname = "thinkbook";
          };
          home-manager.users."zway".imports = [
            ./users/zway

            inputs.nix-flatpak.homeManagerModules.nix-flatpak
            inputs.stylix.homeModules.stylix
            inputs.hex.homeManagerModules.hex
          ];
        }
      ];
    };
    # this is actually a root user configuration for the vps, but I don't want to name it "root" to avoid confusion
    homeConfigurations.fkgfw = home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

      extraSpecialArgs = {
        username = "root";
        homeDirectory = "/root";
        flakeRootPath = ./.;
        agenix = inputs.agenix;
      };

      modules = [
        ./users/fkgfw

        inputs.agenix.homeManagerModules.default
      ];
    };
  };
}
