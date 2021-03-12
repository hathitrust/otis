(import 'ksonnet-util/kausal.libsonnet') +
(import './external_ip_service.libsonnet') +
(import './config.libsonnet') +
{
  local deploy = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,

  local config = $._config.otis,
  local images = $._images.otis,

  otis: {
    web: {
      deployment: deploy.new(
        name=config.web.name,
        replicas=1,
        containers=[
          container.new(config.web.name, images.web)
                   .withPorts([port.new('ui', config.web.port)])
        ]
      ),

      service: $.util.serviceFor(self.deployment) + $.core.v1.service.mixin.spec.withPorts($.core.v1.service.mixin.spec.portsType.newNamed(
        name=config.web.name,
        port=config.web.port,
        targetPort=config.web.port,
      )),

    },

    database: $.phineas.external_ip_service.new("mysql",config.database.ip,config.database.port),
  },
}
