{ lib
, stdenv
, fetchurl
, directoryListingUpdater
, meson
, ninja
, pkg-config
, python3
, wayland-scanner
, wrapGAppsHook4
, libadwaita
, libhandy
, libxkbcommon
, libgudev
, callaudiod
, pulseaudio
, evince
, glib
, gtk4
, gnome
, gnome-desktop
, gcr
, pam
, systemd
, upower
, wayland
, dbus
, xvfb-run
, phoc
, feedbackd
, networkmanager
, polkit
, libsecret
, evolution-data-server
, nixosTests
, gmobile
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "phosh";
  version = "0.41.0";

  src = fetchurl {
    # Release tarball which includes subprojects gvc and libcall-ui
    url = with finalAttrs; "https://sources.phosh.mobi/releases/${pname}/${pname}-${version}.tar.xz";
    hash = "sha256-HXuD9YC7gqGqAq2YmhXI3WRGsvyBc6PgSW3YSYTOdI4=";
  };

  nativeBuildInputs = [
    libadwaita
    meson
    ninja
    pkg-config
    python3
    wayland-scanner
    wrapGAppsHook4
  ];

  buildInputs = [
    evince
    phoc
    libhandy
    libsecret
    libxkbcommon
    libgudev
    callaudiod
    evolution-data-server
    pulseaudio
    glib
    gcr
    networkmanager
    polkit
    gmobile
    gnome.gnome-bluetooth
    gnome.gnome-control-center
    gnome-desktop
    gnome.gnome-session
    gtk4
    pam
    systemd
    upower
    wayland
    feedbackd
  ];

  nativeCheckInputs = [
    dbus
    xvfb-run
  ];

  # Temporarily disabled - Test is broken (SIGABRT)
  doCheck = false;

  mesonFlags = [
    "-Dcompositor=${phoc}/bin/phoc"
    # Save some time building if tests are disabled
    "-Dtests=${lib.boolToString finalAttrs.finalPackage.doCheck}"
  ];

  checkPhase = ''
    runHook preCheck
    export NO_AT_BRIDGE=1
    xvfb-run -s '-screen 0 800x600x24' dbus-run-session \
      --config-file=${dbus}/share/dbus-1/session.conf \
      meson test --print-errorlogs
    runHook postCheck
  '';

  # Depends on GSettings schemas in gnome-shell
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix XDG_DATA_DIRS : "${gnome.gnome-shell}/share/gsettings-schemas/${gnome.gnome-shell.name}"
      --set GNOME_SESSION "${gnome.gnome-session}/bin/gnome-session"
    )
  '';

  passthru = {
    providedSessions = [ "phosh" ];
    tests.phosh = nixosTests.phosh;
    updateScript = directoryListingUpdater { };
  };

  meta = with lib; {
    description = "Pure Wayland shell prototype for GNOME on mobile devices";
    homepage = "https://gitlab.gnome.org/World/Phosh/phosh";
    changelog = "https://gitlab.gnome.org/World/Phosh/phosh/-/blob/v${finalAttrs.version}/debian/changelog";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ masipcat zhaofengli ];
    platforms = platforms.linux;
    mainProgram = "phosh-session";
  };
})
