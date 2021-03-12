(import 'otis/otis.libsonnet') +
{
  _config+:: {
    otis+: {
      web+: {
        host: 'production.otis.kubernetes.hathitrust.org'
      },
    }
  }

  _images+:: {
    otis: {
      web: 'hathitrust/otis',
    },
  },
}
