{ lib
, stdenv
, meson
, ninja
, pkg-config
, vala
, desktop-file-utils
, wrapGAppsHook4
, gobject-introspection
, makeWrapper
, gtk4
, libadwaita
, glib
, glib-networking
, json-glib
, libgee
, libsoup_3
, libsecret
, gnutls
, zstd
, libseccomp
, wayland
, wayland-scanner
, squashfsTools
, squashfuse
, dwarfs
, rustPlatform
, bubblewrap
, xdg-dbus-proxy
}:

let
  # Delta update client: the zsync-rs library plus progress output, installed
  # as zsync-rs like the bundled build.
  zsync-rs = rustPlatform.buildRustPackage {
    pname = "app-manager-zsync";
    version = "0.1.0";
    src = ./tools/zsync-rs;
    cargoLock.lockFile = ./tools/zsync-rs/Cargo.lock;
    doCheck = false;
  };
in
stdenv.mkDerivation(finalAttrs: {
  pname = "app-manager";
  version = let
    # Match only the project version, including prerelease suffixes.
    match = builtins.match ".*project\\([^)]*[[:space:]]version: '([^']+)'.*" (builtins.readFile ./meson.build);
  in lib.head match;

  src = ./.;

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    vala
    desktop-file-utils
    gobject-introspection
    wrapGAppsHook4
    makeWrapper
    wayland-scanner
  ];

  buildInputs = [
    gtk4
    libadwaita
    glib
    glib-networking
    json-glib
    libgee
    libsoup_3
    libsecret
    gnutls
    zstd
    # Sandbox hardening: seccomp filter and Wayland security context.
    libseccomp
    wayland
  ];

  mesonFlags = [
    "-Dbundle_dwarfs=false"
    "-Dbundle_zsync=false"
    "-Dbundle_unsquashfs=false"
    "-Dbundle_squashfuse=false"
    "-Dseccomp=enabled"
    "-Dwayland_security_context=enabled"
  ];

  dontWrapGApps = true;

  postFixup = let
    binPath = lib.makeBinPath [
      squashfsTools
      squashfuse
      dwarfs
      zsync-rs
      # Sandbox runtime dependencies, resolved from PATH at launch.
      bubblewrap
      xdg-dbus-proxy
    ];
  in ''
    wrapProgram $out/bin/app-manager \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : "${binPath}:/run/wrappers/bin"
  '';

  meta = {
    description = "MacOS-style AppImage installer and manager for Linux";
    homepage = "https://github.com/kem-a/AppManager";
    license = lib.licenses.gpl3Plus;
    maintainers = [ ];
    platforms = lib.platforms.linux;
    mainProgram = "app-manager";
  };
})
