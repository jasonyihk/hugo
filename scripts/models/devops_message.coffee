class DevOpsMessage
  constructor: (payload) ->
    @user        = payload.user
    @message     = payload.message
    @action      = payload.action

  toSimpleString: ->
    "DevOps event: \n #{@user} has experienced the following " +
    "\n *action*: #{@action} " +
    "\n *message*: #{@message} "

exports.DevOpsMessage = DevOpsMessage
