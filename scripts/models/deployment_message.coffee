class DeploymentMessage
  constructor: (payload) ->
    @user       = payload.user
    @commit     = payload.commit
    @namespace  = payload.namespace
    @tag        = payload.tag

  toSimpleString: ->
    "\n *user*: `#{@user}`" +
    "\n *commit*: `#{@commit}` " +
    "\n *namespace*: `#{@namespace}` " +
    if @tag then "\n *tag*: `#{@tag}` " else ''

exports.DeploymentMessage = DeploymentMessage
