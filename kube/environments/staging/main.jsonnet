(import 'otis/otis.libsonnet') +
{
  _config+:: {
    otis+: {
      web+: {
        host: 'staging.otis.kubernetes.hathitrust.org',
        log_level: 'debug'
      },
    }
  },
  _images+:: {
    otis: {
      web: 'hathitrust/otis',
    },
  },
}
