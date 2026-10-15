{
  pkgs,
  ...
}:
{
  programs.pi.coding-agent = {
    enable = true;

    settings = {
      packages = [
        "npm:pi-ask-user"
        "npm:pi-hashline-edit"
        "npm:pi-mcp-adapter"
        "npm:pi-observational-memory"
        "npm:pi-permission-system"
        "npm:pi-zentui"
      ];

      defaultProvider = "820010-grok";
      defaultModel = "grok-4.7";

      followUpMode = "all";
      quietStartup = true;
      steeringMode = "all";
      httpIdleTimeoutMs = 60000;
      npmCommand = [ "npm" ];

      "observational-memory" = {
        observeAfterTokens = 10000;
        reflectAfterTokens = 20000;
        compactAfterTokens = 81000;
        compactAfterTokensMode = "ratio";
        compactAfterTokensRatio = 0.618;
        observationsPoolMaxTokens = 20000;
        observationsPoolTargetTokens = 10000;
        agentMaxTurns = 16;
        passive = false;
        debugLog = false;
      };
    };

    extensions = [
      ../.config/pi/extensions/rtk.ts
      ../.config/pi/extensions/plan-mode
      ../.config/pi/extensions/subagent
    ];

    skills = [
      ../.config/pi/skills/rmux
    ];
  };

  home.packages = with pkgs; [
    fd
    ripgrep
    nodejs
    unstable.rmux
    unstable.rtk
  ];

  home.file.".pi/agent/pi-permissions.jsonc".source = ../.config/pi/pi-permissions.jsonc;
  home.file.".pi/agent/zentui.json".source = ../.config/pi/zentui.json;
  home.file.".pi/agent/npm/.npmrc".source = ../.config/pi/.npmrc;

  home.file.".pi/agent/agents/scout.md".source = ../.config/pi/agents/scout.md;
  home.file.".pi/agent/agents/planner.md".source = ../.config/pi/agents/planner.md;
  home.file.".pi/agent/agents/reviewer.md".source = ../.config/pi/agents/reviewer.md;
  home.file.".pi/agent/agents/worker.md".source = ../.config/pi/agents/worker.md;
  home.file.".pi/agent/prompts/implement.md".source = ../.config/pi/prompts/implement.md;
  home.file.".pi/agent/prompts/scout-and-plan.md".source = ../.config/pi/prompts/scout-and-plan.md;
  home.file.".pi/agent/prompts/implement-and-review.md".source = ../.config/pi/prompts/implement-and-review.md;
}