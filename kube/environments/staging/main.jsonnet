(import 'otis/otis.libsonnet') +
{
  _config+:: {
    otis+: {
      web+: {
        host: 'staging.otis.kubernetes.hathitrust.org'
        relative_url_root: '/otis-staging'
      },
    }
  }
}
