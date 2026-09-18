# Pin linux-firmware to 20260810.
#
# linux-firmware-20260910 ships yellow_carp_dmcub.bin 0x0400004A, which
# Rembrandt/Yellow Carp (1002:1681) PSP rejects:
#   failed to load ucode DMCUB(0x3D)
#   psp gfx command LOAD_IP_FW(0x6) failed ... (0xFFFF0008)
#   Wait for DMUB auto-load failed: 3
# After that amdgpu spam-logs DMCUB diagnostics and the machine stutters.
# 20260810 loads DMCUB 0x0400004C successfully.
#
# Override the uncompressed source package. NixOS then wraps it with
# compressFirmwareZstd, so changing only the outer -zstd drv would miss.
final: prev: {
  linux-firmware = prev.linux-firmware.overrideAttrs (_old: rec {
    version = "20260810";
    src = prev.fetchzip {
      url = "https://gitlab.com/api/v4/projects/kernel-firmware%2Flinux-firmware/repository/archive.tar.gz?sha=refs%2Ftags%2F${version}";
      hash = "sha256-P/fPpqaatp8Z2GV+I/OChiWGn6AhV+8w1RMFuX/LqHc=";
    };
  });
}
