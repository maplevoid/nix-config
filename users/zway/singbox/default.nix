{
  writeShellApplication,
  curl,
  jq,
  yq-go,
  python3,
  sing-box,
  systemd,
  coreutils,
  gnused,
  gawk,
  gnugrep,
}:
writeShellApplication {
  name = "singbox-sync";
  runtimeInputs = [
    curl
    jq
    yq-go
    python3
    sing-box
    systemd
    coreutils
    gnused
    gawk
    gnugrep
  ];
  text = ''
    SCRIPT_DIR=${./.}
  ''
  + builtins.readFile ./sync.sh;
}
