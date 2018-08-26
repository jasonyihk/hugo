class HubotMessage
  constructor: (payload) ->
    @color         = if payload.color then payload.color else 'good'
    @room          = payload.room
    @action        = payload.action
    @user          = payload.user
    @message       = payload.message

  toSimpleString: ->
    "user: #{@user} \n action: #{@action} \n hubot message : #{@message}"

exports.HubotMessage = HubotMessage
