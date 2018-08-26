class BitBucketPullRequest
  constructor: (@requestId, payload) ->
    @id          = payload.pullrequest.id
    @title       = payload.pullrequest.title
    @state       = payload.pullrequest.state
    @mergeCommit = payload.pullrequest.merge_commit ?.hash
    @repoName    = payload.repository.name
    @actor       = payload.actor.username
    @actorDisp   = payload.actor.display_name
    @branchSrc   = payload.pullrequest.source.branch.name
    @branchDest  = payload.pullrequest.destination.branch.name
    @link        = payload.pullrequest.links.self.href
    @linkApprove = payload.pullrequest.links.approve.href
    @linkDecline = payload.pullrequest.links.decline.href

  toSimpleString: ->
    "bitbucket pull-request: #{@title} \n from: #{@actor} " +
    "\n To view: #{@link} " +
    "\n To approve: #{@linkApprove} " +
    "\n To declide: #{@linkDecline} "

exports.BitBucketPullRequest = BitBucketPullRequest
