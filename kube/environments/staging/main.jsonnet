(import 'otis/otis.libsonnet') +
{
  _config+:: {
    otis+: {
      web+: {
        host: 'staging.otis.kubernetes.hathitrust.org'
      },
    }
  }
}
