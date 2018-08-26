# Description
#
# Commands:
#   hugo deploy commit - deploy commit
#
Path        = require("path")
Pattern     = require(Path.join(__dirname, ".", "lib", "pattern"))
Auth        = require(Path.join(__dirname, ".", "lib", "auth"))
Events      = require(Path.join(__dirname, ".", "lib", "event"))

DevOpsMessage     = Events.DevOpsMessage
HubotMessage      = Events.HubotMessage
DeploymentMessage = Events.DeploymentMessage
DevOpsEvent       = Events.DevOpsEvent
HubotEvent        = Events.HubotEvent
DeployPrefix      = Pattern.DeployPrefix
ReleasePrefix     = Pattern.ReleasePrefix
ApprovePrefix     = Pattern.ApprovePrefix

BITBUCKET_API     = "https://api.bitbucket.org/2.0/repositories/jasonyihk"
BITBUCKET_AUTH    = new Buffer("#{process.env.BITBUCKET_DEPLOY_USERID}:#{process.env.BITBUCKET_DEPLOY_PASSWD}").toString('base64')

###########################################################################
# deploy on commit
#
# deploy commmit
DeployAuth = new Auth.DeployAuth()
global_robot = null

deploy = (msg, namespace, gitSlug, commit, finished) ->
  uri = "/refs/tags?q=target.hash+%7E+%22#{commit}%22"
  url = BITBUCKET_API + "/" + gitSlug + uri
  req = global_robot.http(url)
  req.headers Authorization: "Basic #{BITBUCKET_AUTH}"
  req.header('Content-Type', 'application/json')

  req.get() (err, res, body) ->
    if err
      msg.reply "`Bitbucket says: #{err}`"
    else if 400 <= res.statusCode
      msg.reply "`Bitbucket says: Status #{res.statusCode} #{body}`"
    else
      json = JSON.parse(body)
      tags = json.values
      if namespace in ['dev-x']
        finished true
      else
        qa_tag = tags.filter (it) ->
          it.name.match(/qa/)

        bau_tag = tags.filter (it) ->
          it.name.match(/bau/)

        if !tags.length
          msg.reply "`Commit has not been Approved. no further action`"
        else if !qa_tag.length
          msg.reply "`Commit has not been Approved by QA. no further action`"
        else if namespace in ['prod'] && !bau_tag.length
          msg.reply "`Commit has not been Approved by BAU. no further action`"
        else
          finished true

approve = (msg, namespace, gitSlug, commit, tag) ->
  uri = "/refs/tags?q=target.hash+%7E+%22#{commit}%22"
  url = BITBUCKET_API + "/" + gitSlug + uri
  req = global_robot.http(url)
  req.headers Authorization: "Basic #{BITBUCKET_AUTH}"
  req.header('Content-Type', 'application/json')

  req.get() (err, res, body) ->
    if err
      msg.reply "`Bitbucket says: #{err}`"
    else if 400 <= res.statusCode
      msg.reply "`Bitbucket says: Status #{res.statusCode} #{body}`"
    else
      json = JSON.parse(body)
      tags = json.values

      qa_tag = tags.filter (it) ->
        it.name.match(/qa/)

      bau_tag = tags.filter (it) ->
        it.name.match(/bau/)

      if tag in ['qa'] && qa_tag.length
        msg.reply "`Commit has Already been Approved by QA. no further action`"
      else if namespace in ['prod'] && tag in ['bau'] && bau_tag.length
        msg.reply "`Commit has Already been Approved by BAU. no further action`"
      else
        uri = "/refs/tags"
        path = BITBUCKET_API + "/" + gitSlug + uri
        auth = new Buffer("#{process.env.BITBUCKET_DEPLOY_USERID}:#{process.env.BITBUCKET_DEPLOY_PASSWD}").toString('base64')
        req = global_robot.http(path)
        req.headers Authorization: "Basic #{auth}"
        req.header('Content-Type', 'application/json')

        seconds = new Date().getTime() / 1000 | 0
        data =
          name: "#{tag}" + "_" + seconds
          target:
            hash: commit

        req.post(JSON.stringify(data)) (err, res, body) ->
          if err
            return msg.reply "`Bitbucket says: #{err}`"
          else if 400 <= res.statusCode
            return msg.reply "`Bitbucket says: Status #{res.statusCode} #{body}`"
          else
            tag = JSON.parse(body).name
            console.log('tag:' + tag)
            msg.reply "`Bitbucket says: commit *#{commit}* is Approved with tag *#{tag}*`"

release = (msg, namespace, gitSlug, tag, finished) ->
  uri = "/refs/tags/RELEASE_" + tag
  url = BITBUCKET_API + "/" + gitSlug + uri

  req = global_robot.http(url)
  req.headers Authorization: "Basic #{BITBUCKET_AUTH}"
  req.header('Content-Type', 'application/json')
  req.get() (err, res, body) ->
    if err
      return msg.reply "`Bitbucket says: #{err}`"
    else if 400 <= res.statusCode
      uri = "/refs/branches/master"
      url = BITBUCKET_API + "/" + gitSlug + uri
      req = global_robot.http(url)
      req.headers Authorization: "Basic #{BITBUCKET_AUTH}"
      req.header('Content-Type', 'application/json')

      req.get() (err, res, body) ->
        if err
          return msg.reply "`Bitbucket says: #{err}`"
        else if 400 <= res.statusCode
          return msg.reply "`Bitbucket says: Status #{res.statusCode} #{body}`"
        else
          @master_commit = JSON.parse(body).target.hash.substr(0,8)

          uri = "/refs/tags?q=target.hash+%7E+%22#{@master_commit}%22"
          url = BITBUCKET_API + "/" + gitSlug + uri
          req = global_robot.http(url)
          req.headers Authorization: "Basic #{BITBUCKET_AUTH}"
          req.header('Content-Type', 'application/json')

          req.get() (err, res, body) ->
            if err
              msg.reply "`Bitbucket says: #{err}`"
              finished
            else if 400 <= res.statusCode
              msg.reply "`Bitbucket says: Status #{res.statusCode} #{body}`"
              finished
            else
              json = JSON.parse(body)
              tags = json.values
              if namespace in ['dev']
                return finished true

              qa_tag = tags.filter (it) ->
                it.name.match(/qa/)

              bau_tag = tags.filter (it) ->
                it.name.match(/bau/)

              rel_tag = tags.filter (it) ->
                it.name.match(/RELEASE/)

              if !tags.length
                msg.reply "`Commit has not been Approved. no further action`"
              else if !qa_tag.length
                msg.reply "`Commit has not been Approved by QA. no further action`"
              else if namespace in ['prod'] && !bau_tag.length
                msg.reply "`Commit has not been Approved by BAU. no further action`"
              else if rel_tag.length
                msg.reply "`Master has already been released. no further action`"
              else
                #uri = "/refs/tags"
                #path = BITBUCKET_API + "/" + gitSlug + uri
                #eq = global_robot.http(path)
                #eq.headers Authorization: "Basic #{BITBUCKET_AUTH}"
                #req.header('Content-Type', 'application/json')

                #seconds = new Date().getTime() / 1000 | 0
                #data =
                #  name: tag
                #  target:
                #    hash: @master_commit

                #req.post(JSON.stringify(data)) (err, res, body) ->
                #  if err
                #    return msg.reply "`Bitbucket says: #{err}`"
                #  else if 400 <= res.statusCode
                #    return msg.reply "`Bitbucket says: Status #{res.statusCode} #{body}`"
                #  else
                #    tag = JSON.parse(body).name
                #    msg.reply "`Bitbucket says: master #{@master_commit} is tagged with #{tag} for release`"

                msg.reply "`Bitbucket says: master #{@master_commit} will be tagged with RELEASE_#{tag}`"
                return finished true
    else
      msg.reply "`Bitbucket says: RELEASE_#{tag} is duplicate, please use a different tag`"
      return finished false


validatePara = (cmd, action) ->
  para = null

  if cmd.length < 2
    return
  else
    if cmd[0].match(/action/)
      para = cmd[1]
    else
      if cmd.length < 3
        return
      else
        para = cmd[2]
  unless para
    return
  unless para.length >= 7
    return

  return para

module.exports = (robot) ->
  hubot = if !robot.alias then robot.name else robot.alias
  global_robot = robot

  unless process.env.BITBUCKET_DEPLOY_USERID
    message = "[BITBUCKET_DEPLOY_USERID] is not being setup, notification has been sent to DevOps team"
    robot.emit DevOpsEvent, new DevOpsMessage {user: '', message: message, action: 'deploy'}
    return

  unless process.env.BITBUCKET_DEPLOY_PASSWD
    message = "[BITBUCKET_DEPLOY_PASSWD] is not being setup, notification has been sent to DevOps team"
    robot.emit DevOpsEvent, new DevOpsMessage {user: '', message: message, action: 'deploy'}
    return

  robot.respond ///#{DeployPrefix}(.*)///i, (msg) ->
    try
      MSG_MISSING_COMMIT = "please provide a correct *COMMIT*?"
      cmd = msg.match[0].split " ", 3

      commit = validatePara(cmd, 'deploy')
      unless commit
        return msg.reply MSG_MISSING_COMMIT

      user  = msg.envelope.user.name
      email = msg.envelope.user.email_address
      roomId = msg.envelope.room
      console.log('user: ' + user + ' room: ' + roomId + ' email: ' +  email)

      unless DeployAuth.validAccess('accessDeploy', roomId, email)
        return msg.reply "sorry? you are not authorized to perform *Deploy*."

      namespace = DeployAuth.getNamespaceByRoomID(roomId)
      gitSlug = DeployAuth.getRepoByNamespace(namespace)
      unless gitSlug
        return msg.reply "unrecognized namespace #{gitSlug}, no further action"

      deploy msg, namespace, gitSlug, commit, (result) ->
        unless result
          return msg.reply "failed to perform *Release*."
        robot.emit Events.DeployEvent, new DeploymentMessage {user: user, namespace: namespace, commit: commit}

    catch err
      robot.logger.info "Exploded when deploy commit: #{err}"

  robot.respond ///#{ApprovePrefix}(.*)///i, (msg) ->
    try
      MSG_MISSING_COMMIT = "are you missing *COMMIT*?"
      cmd = msg.match[0].split " ", 3

      commit = validatePara(cmd, 'approve')
      unless commit
        return msg.reply MSG_MISSING_COMMIT

      user  = msg.envelope.user.name
      email = msg.envelope.user.email_address
      roomId  = msg.envelope.room
      console.log('user: ' + user + ' room: ' + roomId + ' email: ' +  email)

      namespace = DeployAuth.getNamespaceByRoomID(roomId)
      gitSlug = DeployAuth.getRepoByNamespace(namespace)
      unless gitSlug
        return msg.reply "unrecognized namespace #{gitSlug}, no further action"

      if namespace in ['dev']
        return msg.reply "no *Approve* required for #{namespace.toUpperCase()}"

      unless DeployAuth.validAccess('accessApprove', roomId, email)
        return msg.reply "sorry? you are not authorized to perform *Approve*."

      tag = DeployAuth.getTagByEmail(email)

      approve msg, namespace, gitSlug, commit, tag

    catch err
      robot.logger.info "Exploded when deploy commit: #{err}"

  robot.respond ///#{ReleasePrefix}(.*)///i, (msg) ->
    try
      TAG_MISSING_COMMIT = "please provide a *TAG* for this release. e.g. RELEASE_201808"
      cmd = msg.match[0].split " ", 3

      tag = validatePara(cmd, 'release')
      unless tag
        return msg.reply TAG_MISSING_COMMIT

      user  = msg.envelope.user.name
      email = msg.envelope.user.email_address
      roomId  = msg.envelope.room
      console.log('user: ' + user + ' room: ' + roomId + ' email: ' +  email)

      namespace = DeployAuth.getNamespaceByRoomID(roomId)
      gitSlug = DeployAuth.getRepoByNamespace(namespace)
      unless gitSlug
        return msg.reply "unrecognized namespace #{gitSlug}, no further action"

      if namespace in ['dev']
        msg.reply "no *Release* required for #{namespace.toUpperCase()}"
      else
        unless DeployAuth.validAccess('accessRelease', roomId, email)
          return msg.reply "sorry? you are not authorized to perform *Release*."

      release msg, namespace, gitSlug, tag, (result) ->
        unless result
          return msg.reply "failed to perform *Release*."

        robot.emit Events.ReleaseEvent, new DeploymentMessage {user: user, namespace: namespace, tag: tag}

    catch err
      robot.logger.info "Exploded when deploy commit: #{err}"
