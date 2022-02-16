(import 'otis/otis.libsonnet') +
{
  _config+:: {
    otis+: {
      web+: {
        host: 'testing.otis.kubernetes.hathitrust.org',
        log_level: 'debug',
        relative_url_root: '/otis'
      },
    }
  }
}
