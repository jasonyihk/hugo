# Description
#   Cut GitHub deployments from chat that deploy via hooks - https://github.com/atmos/hubot-deploy
#
# Commands:
#   hugo deploy commit - deploy commit
#
Path        = require("path")

###########################################################################
module.exports = (robot) ->
  ###########################################################################
  # deploy on commit
  #
  # deploy commmit
  robot.catchAll (msg) ->
    if !msg.message.text
      return

    r = new RegExp "(?:@#{robot.alias}|#{robot.name})(.*)", "i"
    matches = if msg.message.text then msg.message.text.match(r)
    if matches && matches.length > 1
      msg.reply "pardon? I'm afraid I don't follow you."
