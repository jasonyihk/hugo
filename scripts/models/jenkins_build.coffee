class JenkinsBuild
  constructor: (payload) ->
    @name   = payload.name
    @number = payload.build.number
    @phase  = payload.build.phase
    @status = payload.build.status
    @link   = payload.build.full_url
    @timestamp = payload.build.timestamp
    @actor   = payload.build.parameters.DEPLOY_USER
    @namespace = payload.build.parameters.DEPLOY_NAMESPACE

  toSimpleString: ->
    "jenkins build: *#{@status}* " +
    "\n   job: #{@name} \n  " +
    "\n   user: #{@actor} " +
    "\n   link: #{@link} "

exports.JenkinsBuild = JenkinsBuild
