# Description
#
# Commands:
#   hugo deploy commit - deploy commit
#
Path        = require("path")
Pattern     = require(Path.join(__dirname, ".", "lib", "pattern"))
Auth        = require(Path.join(__dirname, ".", "lib", "auth"))
Events      = require(Path.join(__dirname, ".", "lib", "event"))

DevOpsMessage  = Events.DevOpsMessage
HubotMessage   = Events.HubotMessage
DevOpsEvent    = Events.DevOpsEvent
HubotEvent     = Events.HubotEvent
DeployPrefix   = Pattern.DeployPrefix
ReleasePrefix  = Pattern.ReleasePrefix

DeployJobName = process.env.HUBOT_JENKINS_DEPLOY_JOB or "deploy_to_k8s"
ReleaseJobName = process.env.HUBOT_JENKINS_RELEASE_JOB or "release_to_k8s"

###########################################################################
# deploy on commit
#
# deploy commmit
DeployAuth = new Auth.DeployAuth()

reply = (robot, color, room, message, user, action) ->
    robot.emit HubotEvent, new HubotMessage {color: color, room: room, message: message, action: action, user: user}

###########################################################################
module.exports = (robot) ->
  unless process.env.HUBOT_JENKINS_URL
    message = "[HUBOT_JENKINS_URL] is not being setup, notification has been sent to DevOps team"
    robot.emit DevOpsEvent, new DevOpsMessage {message: message}
    return

  unless process.env.HUBOT_JENKINS_BASIC_AUTH_ID
    message = "[HUBOT_JENKINS_BASIC_AUTH_ID] is not being setup, notification has been sent to DevOps team"
    robot.emit DevOpsEvent, new DevOpsMessage {message: message}
    return

  unless process.env.HUBOT_JENKINS_BASIC_AUTH_PASSWD
    message = "[HUBOT_JENKINS_BASIC_AUTH_PASSWD] is not being setup, notification has been sent to DevOps team"
    robot.emit DevOpsEvent, new DevOpsMessage {message: message}
    return

  ###########PR:event############
  robot.on "pullrequest:fulfilled", (pullRequest) ->
    namespace = DeployAuth.getNamespaceByRepo(pullRequest.repoName)

    if namespace in ['dev']
      commit = pullRequest.mergeCommit
      commit = pullRequest.mergeCommit
      user = pullRequest.actor
      jenkinsDeploy(namespace, commit, user)

  ###########deploy:event############
  robot.on "#{Events.DeployEvent}", (deployMessage) ->
    user = deployMessage.user
    namespace = deployMessage.namespace
    commit = deployMessage.commit

    path = process.env.HUBOT_JENKINS_URL +  "/job/#{DeployJobName}/buildWithParameters?" +
          "DEPLOY_NAMESPACE=#{namespace}" + "&" +
          "DEPLOY_COMMIT=#{commit}" + "&" +
          "DEPLOY_USER=#{user}"

    console.log('path: ' + path)

    req = robot.http(path)
    auth = new Buffer("#{process.env.JENKINS_AUTH_USERID}:#{process.env.JENKINS_AUTH_PASSWD}").toString('base64')
    req.headers Authorization: "Basic #{auth}"
    req.header('Content-Length', 0)
    req.post() (err, res, body) ->
      room = DeployAuth.getRoomByNamespace(namespace)
      action = '`deploy`'
      if err
        reply 'danger', room, "`Jenkins says: #{err}`", user, action
      else if 200 <= res.statusCode < 400 # Or, not an error code.
        reply robot, 'good', room, "`(#{res.statusCode}) Proceeding with #{path} `", user, action
      else if res.statusCode in [400, 404]
        reply robot, 'warning', room, "`Build not found, double check that it exists and is spelt correctly.`", user, action
      else
        reply robot, 'good', room, "`Jenkins says: Status #{res.statusCode} #{body}`", user, action

  ###########release:event############
  robot.on "#{Events.ReleaseEvent}", (deployMessage) ->
    user = deployMessage.user
    namespace = deployMessage.namespace
    tag = deployMessage.tag

    path = process.env.HUBOT_JENKINS_URL +  "/job/#{ReleaseJobName}/buildWithParameters?" +
          "RELEASE_NAMESPACE=#{namespace}" + "&" +
          "RELEASE_TAG=#{tag}" + "&" +
          "RELEASE_USER=#{user}"

    console.log('path: ' + path)

    req = robot.http(path)
    auth = new Buffer("#{process.env.JENKINS_AUTH_USERID}:#{process.env.JENKINS_AUTH_PASSWD}").toString('base64')
    req.headers Authorization: "Basic #{auth}"
    req.header('Content-Length', 0)
    req.post() (err, res, body) ->
      room = DeployAuth.getRoomByNamespace(namespace)
      action = '`release`'
      if err
        reply 'danger', room, "`Jenkins says: #{err}`", user, action
      else if 200 <= res.statusCode < 400 # Or, not an error code.
        reply robot, 'good', room, "`(#{res.statusCode}) Proceeding with #{path} `", user, action
      else if res.statusCode in [400, 404]
        reply robot, 'warning', room, "`Build not found, double check that it exists and is spelt correctly.`", user, action
      else
        reply robot, 'good', room, "`Jenkins says: Status #{res.statusCode} #{body}`", user, action



