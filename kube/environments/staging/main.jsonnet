(import 'otis/otis.libsonnet') +
{
  _config+:: {
    otis+: {
      web+: {
        host: 'staging.otis.kubernetes.hathitrust.org'
      },
    }
  },
  _images+:: {
    otis: {
      web: 'hathitrust/otis',
    },
  },
}
