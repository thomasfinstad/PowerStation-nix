{
  lib,
  rustPlatform,
  pkgs,
  fetchFromGitHub,
  ...
}:

rustPlatform.buildRustPackage rec {
  gitOwner = "ShadowBlip";
  pname = "PowerStation";
  version = "v0.3.0";
  gitHash = "sha256-RiuXEMQUijsBiyFA/OLn6AE2Qv7IXye483eWwSEosNY=";

  src = fetchFromGitHub {
    owner = gitOwner;
    repo = pname;
    rev = version;
    hash = gitHash;
  };

  cargoLock =
    let
      fixupLockFile = path: (builtins.readFile path);
    in
    {
      lockFileContents = fixupLockFile ./Cargo.lock;
      allowBuiltinFetchGit = true;
    };

  postPatch = ''
    ln -f -s ${./Cargo.lock} Cargo.lock
  '';

  cargoHash = "sha256-0ws3p0bpvap8rgrhksghcic8ppj26w60ig8i2cnw6yb4jf6g3yg1=";

  # buildInputs - Dependencies that should exist in the runtime environment.
  # propagatedBuildInputs - Dependencies that should exist in the runtime environment and also propagated to downstream runtime environments.
  buildInputs = with pkgs; [
    dbus
    systemd
    pciutils
  ];
  # nativeBuildInputs - Dependencies that should only exist in the build environment.
  # propagatedNativeBuildInputs - Dependencies that should only exist in the build environment and also propagated to downstream build environments.
  nativeBuildInputs = with pkgs; [
    pkg-config
    cmake
    rustPlatform.bindgenHook
  ];

  postInstall = ''
    install -D -m 644 rootfs/usr/share/dbus-1/system.d/org.shadowblip.PowerStation.conf $out/share/dbus-1/system.d/org.shadowblip.PowerStation.conf
    install -D -m 644 rootfs/usr/lib/systemd/system/powerstation.service $out/lib/systemd/system/powerstation.service

    sed -i \
      -e "s|\[Service\]|[Service]\nBusName=org.shadowblip.PowerStation|" \
      -e "s|\[Service\]|[Service]\nType=dbus|" \
      -e "s|ExecStart=/usr|ExecStart=$out|" \
      "$out/lib/systemd/system/powerstation.service"

    mkdir -p $out/share/dbus-1/system-services
    cat <<END > $out/share/dbus-1/system-services/org.shadowblip.PowerStation.service
    [D-BUS Service]
    Name=org.shadowblip.PowerStation
    Exec=$out/bin/powerstation
    User=root
    SystemdService=powerstation.service
    END
  '';

  meta = {
    description = "Open source TDP control and performance daemon with DBus interface";
    homepage = "https://github.com/ShadowBlip/PowerStation";
    license = lib.licenses.gpl3;
    maintainers = [ ];
  };
}
