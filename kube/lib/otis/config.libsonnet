{
  _config+:: {
    otis: {
      web: {
        name: 'otis',
        port: 80,
        host: 'otis.macc.kubernetes.hathitrust.org',
      },
      database: {
        port: 3306,
        ip: '10.255.8.249',
      }
    },
  },

  _images+:: {
    otis: {
      web: 'hathitrust/otis-unstable',
    },
  },
}
