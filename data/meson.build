install_data(
  'dev.sinty.desktop.gschema.xml',
  install_dir: get_option('datadir') / 'glib-2.0' / 'schemas'
)
install_data(
  'icons/hicolor/scalable/apps/emblem-singularity.svg',
  install_dir: get_option('datadir') / 'icons' / 'hicolor' / 'scalable' / 'apps'
)

install_data(
  'systemd/singularity-polkit-agent.service',
  'systemd/xdg-desktop-portal-singularity.service',
  install_dir: get_option('prefix') / 'lib' / 'systemd' / 'user'
)
install_data(
  'singularity.portal',
  install_dir: get_option('datadir') / 'xdg-desktop-portal' / 'portals'
)
install_data(
  'singularity-portals.conf',
  install_dir: get_option('datadir') / 'xdg-desktop-portal'
)

# Register the session with greetd/GDM without needing the deploy script.
_session_conf = configuration_data()
_session_bindir = get_option('bindir')
if not _session_bindir.startswith('/')
  _session_bindir = get_option('prefix') / _session_bindir
endif
_session_conf.set('bindir', _session_bindir)
configure_file(
  input: 'wayland-sessions/singularity.desktop.in',
  output: 'singularity.desktop',
  configuration: _session_conf,
  install: true,
  install_dir: get_option('datadir') / 'wayland-sessions',
)

# Session-bus activation of the portal backend. On runit hosts there is no
# systemd --user to start the unit, so xdg-desktop-portal must be able to
# activate the backend over D-Bus on its own. Only the /usr package gets these
# files: a source deploy to /opt/local must keep using the deploy script's
# wrapper (it sets LD_LIBRARY_PATH and preloads gtk4-layer-shell).
if get_option('prefix') == '/usr'
  _portal_libexecdir = get_option('libexecdir')
  if not _portal_libexecdir.startswith('/')
    _portal_libexecdir = get_option('prefix') / _portal_libexecdir
  endif
  _dbus_portal_conf = configuration_data()
  _dbus_portal_conf.set('libexecdir', _portal_libexecdir)
  foreach _name : [
      'org.freedesktop.impl.portal.desktop.singularity',
      'dev.sinty.ush.Portal',
    ]
    configure_file(
      input: 'dbus-1' / (_name + '.service.in'),
      output: _name + '.service',
      configuration: _dbus_portal_conf,
      install: true,
      install_dir: get_option('datadir') / 'dbus-1' / 'services',
    )
  endforeach
endif
install_data(
  'udev/60-singularity-ddc.rules',
  install_dir: get_option('prefix') / 'lib' / 'udev' / 'rules.d'
)
install_data(
  'udev/singularity-ddc.conf',
  install_dir: get_option('prefix') / 'lib' / 'modules-load.d'
)
install_data(
  'accountsservice/com.singularity.Desktop.xml',
  install_dir: get_option('datadir') / 'accountsservice' / 'interfaces'
)
custom_target('compile_schemas',
  input: ['dev.sinty.desktop.gschema.xml'],
  output: 'gschemas.compiled',
  command: ['glib-compile-schemas', meson.current_build_dir()],
  build_by_default: true
)

# Wallpapers are installed from the singularity-wallpapers submodule (see root meson.build).
