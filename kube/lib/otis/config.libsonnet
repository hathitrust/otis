{
  _config+:: {
    otis: {
      web: {
        name: 'otis',
        port: 80,
        host: 'otis.macc.kubernetes.hathitrust.org',
        relative_url_root: '/otis',
        app_config: {
          configmap: 'production-config',
          # path to mount above configmap
          path: '/usr/src/app/config/settings',
          # key from configmap to use for application config
          key: 'production.local.yml'
        }
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
