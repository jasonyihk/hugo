# Description
#   HTTP Endpoint
#

Fs              = require "fs"
Path            = require "path"
Events          = require(Path.join(__dirname, ".", "lib", "event"))
Auth            = require(Path.join(__dirname, ".", "lib", "auth"))

BitBucketPullRequest  = Events.BitBucketPullRequest
JenkinsBuild          = Events.JenkinsBuild
DeploymentMessage     = Events.DeploymentMessage
DevOpsMessage         = Events.DevOpsMessage
BitBucketPrefix       = process.env.HUBOT_BITBUCKET_WEBHOOK_PREFIX or "/hubot/bitbucket"
JenkinsPrefix         = process.env.HUBOT_JENKINS_WEBHOOK_PREFIX or "/hubot/jenkins"

###########################################################################
module.exports = (robot) ->
  IPAuth = new Auth.IPAuth()

  # Description
  #   BitBucket Endpoint
  #
  robot.router.post BitBucketPrefix, (req, res) ->
    try
      BasicAuth = new Auth.BasicAuth("bitbucket")
      remoteIp = req.headers['x-forwarded-for'] or req.connection.remoteAddress
      console.log('remoteIp: ' + remoteIp)
      console.log('req.headers: ' + JSON.stringify(req.headers))
      console.log('req.body: ' + JSON.stringify(req.body))

      unless IPAuth.ipIsValid(remoteIp)
        res.writeHead 400, {'content-type': 'application/json' }
        return res.end(JSON.stringify({error: "Webhook requested from a non-BitBucket IP address."}))

      unless BasicAuth.valid(req)
        res.writeHead 403, {'content-type': 'application/json' }
        return res.end(JSON.stringify({message: "Not authorized"}))

      unless req.body && req.body.pullrequest
        res.writeHead 400, {'content-type': 'application/json' }
        return res.end(JSON.stringify({error: "Invalid payload"}))

      requestId = req.headers['x-request-uuid']
      event =  req.headers['x-event-key']
      pullRequest = new BitBucketPullRequest requestId, req.body
      if event and event in Events.BitBucketPullRequestEvents
        robot.emit event, pullRequest
        res.writeHead 200, {'content-type': 'application/json' }
        return res.end("{}")
      else
        res.writeHead 204, {'content-type': 'application/json' }
        return res.end(JSON.stringify({message: "Received but not processed."}))

    catch err
      robot.logger.error err
      message = "error: #{err}"
      ops_message = new DevOpsMessage {user: '', message: message, action: "#{BitBucketPrefix}"}
      robot.emit Events.DevOpsEvent, ops_message
      res.writeHead 500, {'content-type': 'application/json' }
      return res.end(JSON.stringify({error: "Something went crazy processing the request."}))

  # Description
  #   Jenkins Endpoint
  #
  robot.router.post JenkinsPrefix, (req, res) ->
    try
      BasicAuth = new Auth.BasicAuth("jenkins")
      remoteIp = req.headers['x-forwarded-for'] or req.connection.remoteAddress
      console.log('remoteIp: ' + remoteIp)
      console.log('req.headers: ' + JSON.stringify(req.headers))
      console.log('req.body: ' + JSON.stringify(req.body))

      unless IPAuth.ipIsValid(remoteIp)
        res.writeHead 400, {'content-type': 'application/json' }
        return res.end(JSON.stringify({error: "Webhook requested from a non-BitBucket IP address."}))

      unless BasicAuth.valid(req)
        res.writeHead 403, {'content-type': 'application/json' }
        return res.end(JSON.stringify({message: "Not authorized"}))

      unless req.body && req.body.build
        res.writeHead 400, {'content-type': 'application/json' }
        return res.end(JSON.stringify({error: "Invalid payload"}))

      jenkinsBuild = new JenkinsBuild req.body
      robot.emit Events.JenkinsEvent, jenkinsBuild
      res.writeHead 200, {'content-type': 'application/json' }
      return res.end("{}")

    catch err
      robot.logger.error err
      message = "error: #{err}"
      ops_message = new DevOpsMessage {user: '', message: message, action: "#{BitBucketPrefix}"}
      robot.emit Events.DevOpsEvent, ops_message
      res.writeHead 500, {'content-type': 'application/json' }
      return res.end(JSON.stringify({error: "Something went crazy processing the request."}))
