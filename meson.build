project('singularity-desktop', ['vala', 'c'],
  version: '0.1.0',
  default_options: ['buildtype=release', 'strip=true'],
)

gnome = import('gnome')
i18n = import('i18n')
fs = import('fs')

glibc_compat = ['-include', meson.current_source_dir() / 'compat' / 'glibc-compat.h']
glibc_compat_link = []
is_glibc = meson.get_compiler('c').get_define('__GLIBC__', prefix: '#include <features.h>') != ''
if is_glibc and host_machine.cpu_family() == 'x86_64'
  foreach fn : ['atan2f', 'fmod', 'fmodf', 'hypot', 'hypotf', 'sqrtf']
    glibc_compat_link += '-Wl,--wrap=' + fn
  endforeach
  glibc_compat_link += ['-Wl,--push-state,--no-as-needed', '-lm', '-Wl,--pop-state']
endif
add_global_arguments(glibc_compat, language: 'c')
add_global_link_arguments(glibc_compat_link, language: 'c')
if add_languages('cpp', required: false, native: false)
  add_global_arguments(glibc_compat, language: 'cpp')
  add_global_link_arguments(glibc_compat_link, language: 'cpp')
endif
go = find_program('go', required: false)
if go.found()
  vetro_bin = meson.current_build_dir() / 'tools' / 'vetro'
  message('Building vetro from subprojects/vetro')
  run_command(go, 'build', '-C', meson.current_source_dir() / 'subprojects' / 'vetro', '-o', vetro_bin, '.', check: true, env: {'GOTMPDIR': meson.current_build_dir()})
  meson.override_find_program('vetro', find_program(vetro_bin))
elif not find_program('vetro', required: false).found()
  error('Go is missing to build vetro from subprojects/vetro. Run make prepare-deps or install Go.')
endif

subdir('data')
subdir('po')

# Void (and other minimal distros) ship no cups.vapi, but the toolkit needs it
# for print support. Bundle one and add it to the Vala search path.
if not fs.is_file('/usr/share/vala/vapi/cups.vapi') and not fs.is_file('/usr/local/share/vala/vapi/cups.vapi')
  add_global_arguments('--vapidir', meson.current_source_dir() / 'compat' / 'vapi', language: 'vala')
endif

subproject('libsingularity')
subproject('singularity-loginui')

gestures = get_option('gestures')
gesture_runtime_ready = true
foreach runtime_file : [
  'subprojects/singularity-gestures/runtime/libmediapipe.so',
  'subprojects/singularity-gestures/runtime/hand_landmarker.task',
  'subprojects/singularity-gestures/runtime/face_landmarker.task',
  'subprojects/singularity-gestures/runtime/libonnxruntime.so',
  'subprojects/singularity-gestures/runtime/mobileone_s0_gaze.onnx',
  'subprojects/singularity-gestures/runtime/include/onnxruntime_c_api.h',
  'subprojects/singularity-gestures/runtime/include/onnxruntime_ep_c_api.h',
]
  if not fs.is_file(runtime_file)
    gesture_runtime_ready = false
  endif
endforeach
if gestures.enabled() and not gesture_runtime_ready
  error('Gesture runtime is missing. Run make gesture-runtime before configuring.')
endif
if gestures.enabled() or (gestures.auto() and gesture_runtime_ready)
  subproject('singularity-gestures')
endif

subproject('xdg-desktop-portal-singularity')
subproject('singularity-polkit-agent')
subproject('singularity-shell')

app_tiers = {'essential': 0, 'core': 1, 'extra': 2}
app_limit = {'essential': 0, 'core': 1, 'all': 2}[get_option('apps')]
app_entries = fs.read('apps.txt').strip().split('\n')
if fs.is_file('apps.local.txt')
  app_entries += fs.read('apps.local.txt').strip().split('\n')
endif
foreach entry : app_entries
  fields = entry.strip().split()
  if fields.length() == 2 and app_tiers[fields[1]] <= app_limit
    subproject(fields[0])
  endif
endforeach

subproject('singularity-greeter')
subproject('singularity-splash')
if get_option('installer')
  subproject('singularity-installer')
endif

# Built-in widgets (clock, calculator) live in the singularity-widgets submodule.
subproject('singularity-widgets')

# Wallpapers live in the singularity-wallpapers submodule (installs its own data).
subproject('singularity-wallpapers')

# GTK and icon themes live in the singularity-themes submodule.
subproject('singularity-themes')

# App icons (hicolor) stay in the meta repo.
install_subdir('data/icons/hicolor',
  install_dir: get_option('datadir') / 'icons',
  strip_directory: false)

subproject('singularity-plugins')
subproject('singularity-media-plugins')
subproject('singularity-keyring')
subproject('singularity-accounts')
subproject('singularity-sharing')
subproject('singularity-nearby')
subproject('singularity-session')
