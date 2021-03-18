(import 'ksonnet-util/kausal.libsonnet') +
(import './external_ip_service.libsonnet') +
(import './config.libsonnet') +
{
  local deploy = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local env = container.envType,
  local port = $.core.v1.containerPort,
  local volumeMount = $.core.v1.volumeMount,
  local volume = $.core.v1.volume,

  local config = $._config.otis,
  local images = $._images.otis,
  local app_config = config.web.app_config,

  otis: {
    web: {
      deployment: deploy.new(
        name=config.web.name,
        replicas=1,
        containers=[
          container.new(config.web.name, images.web)
                   .withPorts([port.new('ui', config.web.port)])
                   .withEnv([
                     env.fromSecretRef("RAILS_MASTER_KEY","rails-master-key","rails-master-key"),
                     env.fromSecretRef("DB_URL","db-url","db-url"),
                     env.new("RAILS_RELATIVE_URL_ROOT",config.web.relative_url_root)])
                   .withVolumeMounts([
                     volumeMount.new(name=app_config.configmap,
                                     mountPath=app_config.path + "/" + app_config.key)
                                .withSubPath( subPath=app_config.key)])

        ]
      ).withVolumes([volume.fromConfigMap(name=app_config.configmap,configMapName=app_config.configmap)]),

      service: $.util.serviceFor(self.deployment) + $.core.v1.service.mixin.spec.withPorts($.core.v1.service.mixin.spec.portsType.newNamed(
        name=config.web.name,
        port=config.web.port,
        targetPort=config.web.port,
      )),

    },

    database: $.phineas.external_ip_service.new("mysql",config.database.ip,config.database.port),
  },
}
