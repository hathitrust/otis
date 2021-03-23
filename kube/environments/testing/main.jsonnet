(import 'otis/otis.libsonnet') +
{
  _config+:: {
    otis+: {
      web+: {
        host: 'testing.otis.kubernetes.hathitrust.org',
        relative_url_root: '/otis-testing'
      },
    }
  }
}
