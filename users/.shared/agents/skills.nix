# Combined agent skills: local skills from users/.config/agents/skills plus
# third-party skills (see https://www.skills.sh/) fetched and pinned by Nix.
# To add one: add an entry to `thirdParty`, set `hash = lib.fakeHash`, rebuild,
# then paste the hash from the error. To update: bump `rev` and the hash.
{ pkgs }:
let
  inherit (pkgs) lib;

  localSkills = ../../.config/agents/skills;

  anthropicsSkills = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "dbd4588f9e1033efb41dad4bef2f7947c8993d44";
    hash = "sha256-+UIqBnzyeIOvJSKYaDaE3GYPEpLw7qQqyUw5S971AfU=";
  };

  riekeltTechnicalWriter = pkgs.fetchFromGitHub {
    owner = "riekelt";
    repo = "technical-writer";
    rev = "85e53729dd959a2795d593d6769068e342cf3486";
    hash = "sha256-+I8K1L9PxTutVeUAOyjTqWdZfM8Oat1K7VoLKkXvKqE=";
  };

  bladerHumanizer = pkgs.fetchFromGitHub {
    owner = "blader";
    repo = "humanizer";
    rev = "b48c832f0f809c1b5658edbb838c2521b72f2413";
    hash = "sha256-brVRFNvqMttKMZdlxrgmU01VOlxbyU6zQ8zd6qT4eZ8=";
  };

  # name -> path to the skill directory
  thirdParty = {
    skill-creator = "${anthropicsSkills}/skills/skill-creator";

    technical-writing = "${riekeltTechnicalWriter}/plugins/technical-writer/skills/technical-writing";
    humanizer = "${bladerHumanizer}";
  };
in
pkgs.runCommand "agent-skills" { } ''
  mkdir -p $out
  cp -r ${localSkills}/. $out/
  ${lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: path: "ln -s ${path} $out/${name}") thirdParty
  )}
''
