# Description
#  scripts for slack
#
Path        = require("path")
Events      = require(Path.join(__dirname, ".", "lib", "event"))
Auth        = require(Path.join(__dirname, ".", "lib", "auth"))
DeploymentMessage = Events.DeploymentMessage

module.exports = (robot) ->
  DeployAuth = new Auth.DeployAuth()
  hubot = if !robot.alias then robot.name else obot.alias

  ###########pullrequest:created############
  robot.on "pullrequest:created", (pullRequest) ->
    room = DeployAuth.getRoomByRepo(pullRequest.repoName)
    title = "[#{pullRequest.repoName}]: pull request from #{pullRequest.actorDisp}"
    jobUrl = "joburl.jenkins"

    attachments = [
      {
        "color": 'good',
        "text": "\n     *to Approve*: #{pullRequest.linkApprove}" +
                "\n *to Decline*: #{pullRequest.linkDecline}"
        "title":title,
        "title_link": pullRequest.link,
        "ts": new Date().getMilliseconds(),
        "mrkdwn_in": ["text", "pretext"]
      }
    ]

    robot.adapter.client.web.chat.postMessage(room, 'Request Submitted', {as_user: true, unfurl_links: true, attachments: attachments })

  ###########pullrequest:fulfilled############
  robot.on "pullrequest:fulfilled", (pullRequest) ->
    repo = pullRequest.repoName
    room = DeployAuth.getRoomByRepo(repo)
    user = pullRequest.actor
    commit = pullRequest.mergeCommit
    namespace = DeployAuth.getNamespaceByRepo(repo)
    console.log('room: ' + room + ' namespace: ' + namespace)

    title = "Deployment #{pullRequest.mergeCommit} ready for #{room.toUpperCase()}"
    appove_message = ''
    text = '\n       will be trigerred automatically'
    if room in ['sit', 'uat', 'stag', 'prod']
      appove_message = "\n       to *approve :* `@#{hubot} approve #{commit}`"
      text = appove_message + "\n to *deploy :* `@#{hubot} deploy #{commit}`"

    attachments = [
      {
        "color": 'good',
        "text": text,
        "title":title,
        "title_link": pullRequest.link,
        "ts": (new Date()).getMilliseconds()/1000,
        "mrkdwn_in": ["text", "pretext"]
      }
    ]
    robot.adapter.client.web.chat.postMessage(room, '*Deployment Request*', {as_user: true, unfurl_links: true, attachments: attachments })
    robot.emit Events.DeployEvent, new DeploymentMessage {user: user, namespace: namespace, commit: commit}

  ###########devops:event############
  robot.on "#{Events.DevOpsEvent}", (message) ->
    room = DeployAuth.getRoomByRepo('devops')
    title = "Ops, please take a look at the following"

    console.log('room:' + JSON.stringify(room))
    console.log('message:' + JSON.stringify(message))

    attachments = [
      {
        "color": 'warning',
        "text": "\n  *user:* `#{message.user}` " + "\n  *action:* `#{message.action}` " + "\n  *message:* `#{message.message}` ",
        "title":title,
        "title_link": 'link',
        "ts": (new Date()).getMilliseconds(),
        "mrkdwn_in": ["text", "pretext"]
      }
    ]

    robot.adapter.client.web.chat.postMessage(room, '*DevOps Event*', {as_user: true, unfurl_links: true, attachments: attachments })

  ###########jenkins:event############
  robot.on "#{Events.JenkinsEvent}", (build) ->
    room = DeployAuth.getRoomByNamespace(build.namespace)

    title = "Jenkins » #{build.name} ##{build.number}"
    color = 'good'
    if build.status in ['FAILURE']
      color = 'warning'

    attachments = [
      {
        "color": color,
        "text": "\n*User:* `#{build.actor}` \n*Build:* `#{build.phase}`" + if build.status then "\n*Status:* `#{build.status}`" else "",
        "title": title,
        "title_link": build.link,
        "ts": build.timestamp/1000,
        "mrkdwn_in": ["text", "pretext"]
      }
    ]

    robot.adapter.client.web.chat.postMessage(room, '*Jenkins Message*', {as_user: true, unfurl_links: true, attachments: attachments })

  ###########hubot:event############
  robot.on "#{Events.HubotEvent}", (msg) ->
    room = msg.room
    color = 'warning'
    title = "#{hubot} message"

    attachments = [
      {
        "color": msg.color,
        "title": title,
        "text":  msg.toSimpleString()
      }
    ]

    robot.adapter.client.web.chat.postMessage(room, '', {as_user: true, unfurl_links: true, attachments: attachments })

