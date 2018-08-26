Path         = require "path"
Address4     = require("ip-address").Address4

###########################################################################
class BasicAuth
  constructor: (@application) ->
    if @application in ['bitbucket']
      unless process.env.HUBOT_BITBUCKET_BASIC_AUTH_ID?
        throw new Error("Please set a [HUBOT_BITBUCKET_BASIC_AUTH_ID] string in the environment")
      unless process.env.HUBOT_BITBUCKET_BASIC_AUTH_PASSWD?
        throw new Error("Please set a [HUBOT_BITBUCKET_BASIC_AUTH_SECRET] string in the environment")
      @token = new Buffer(process.env.HUBOT_BITBUCKET_BASIC_AUTH_ID + ":" + process.env.HUBOT_BITBUCKET_BASIC_AUTH_PASSWD).toString('base64')

    if @application in ['jenkins']
      unless process.env.HUBOT_JENKINS_BASIC_AUTH_ID?
        throw new Error("Please set a [HUBOT_JENKINS_BASIC_AUTH_ID] string in the environment")
      unless process.env.HUBOT_JENKINS_BASIC_AUTH_PASSWD?
        throw new Error("Please set a [HUBOT_JENKINS_BASIC_AUTH_SECRET] string in the environment")
      @token = new Buffer(process.env.HUBOT_JENKINS_BASIC_AUTH_ID + ":" + process.env.HUBOT_JENKINS_BASIC_AUTH_PASSWD).toString('base64')

    if !@token?
      throw new Error("#{@application} is not recongnized")

  valid: (req) ->
    if !req.headers?
      return false
    authToken = req.headers['authorization']?.match(/Basic (.+){1,128}/)?[1]
    if !authToken?
      return false
    if authToken != @token
      return false
    true

class IPAuth
  constructor: () ->
    bitBucketSubnets = process.env.HUBOT_BITBUCKET_SUBNETS || "127.0.0.1/24"
    @subnets = (new Address4(subnet.trim()) for subnet in bitBucketSubnets.split(','))

  ipIsValid: (ipAddress) ->
    return true  # Internal F5 does not forward IPs

    address = new Address4("#{ipAddress}/24")
    for subnet in @subnets
      return true if address.isInSubnet(subnet)
    false

class DeployAuth
  constructor: () ->
    @accessList = [
      {
        id: 'GC59ZA01H',
        room:  'dev',
        namespace: 'dev',
        repo: 'k8s.flux.dev',
        defaultReviewer: if process.env.HUBOT_FLUX_DEFAULT_REVIEWER_DEV then (process.env.HUBOT_DEPLOY_ACCESS_LIST_UAT).split(',') else ['jasonyihk@gmail.com']
      },
      {
        id: 'GCAE2F9J9',
        room:  'sit',
        namespace: 'sit',
        repo: 'k8s.flux.sit',
        accessDeploy: if process.env.HUBOT_DEPLOY_ACCESS_LIST_UAT then (process.env.HUBOT_DEPLOY_ACCESS_LIST_UAT).split(',') else ['jasonyihk@gmail.com'],
        defaultReviewer: if process.env.HUBOT_FLUX_DEFAULT_REVIEWER_SIT then (process.env.HUBOT_DEPLOY_ACCESS_LIST_UAT).split(',') else ['jasonyihk@gmail.com']
      },
      {
        id: 'GC2JK2B8R',
        room: 'uat',
        namespace: 'uat',
        repo: 'k8s.flux.dev',
        accessDeploy: if process.env.HUBOT_DEPLOY_ACCESS_LIST_UAT then (process.env.HUBOT_DEPLOY_ACCESS_LIST_UAT).split(',') else ['jasonyihk@gmail.com'],
        accessApprove: if process.env.HUBOT_APPROVE_ACCESS_LIST_UAT then (process.env.HUBOT_APPROVE_ACCESS_LIST_UAT).split(',') else ['jasonyihk@gmail.com'],
        accessRelease: if process.env.HUBOT_RELEASE_ACCESS_LIST_UAT then (process.env.HUBOT_RELEASE_ACCESS_LIST_UAT).split(',') else ['jasonyihk@gmail.com']
      },
      {
        id: 'GC570C8H2',
        room:  'stag',
        namespace: 'stag',
        repo: 'k8s.flux.stag',
        accessDeploy: if process.env.HUBOT_DEPLOY_ACCESS_LIST_STAG then (process.env.HUBOT_DEPLOY_ACCESS_LIST_STAG).split(',') else ['jasonyihk@gmail.com'],
        accessApprove: if process.env.HUBOT_APPROVE_ACCESS_LIST_STAG then (process.env.HUBOT_APPROVE_ACCESS_LIST_STAG).split(',') else ['jasonyihk@gmail.com'],
        accessRelease: if process.env.HUBOT_RELEASE_ACCESS_LIST_STAG then (process.env.HUBOT_RELEASE_ACCESS_LIST_STAG).split(',') else ['jasonyihk@gmail.com']
      },
      {
        id: 'GC6PEUJTG',
        room:  'prod',
        namespace: 'prod',
        repo: 'k8s.flux.prod',
        accessDeploy: if process.env.HUBOT_DEPLOY_ACCESS_LIST_PROD then (process.env.HUBOT_DEPLOY_ACCESS_LIST_PROD).split(',') else ['jasonyihk@gmail.com'],
        accessApprove: if process.env.HUBOT_APPROVE_ACCESS_LIST_PROD then (process.env.HUBOT_APPROVE_ACCESS_LIST_PROD).split(',') else ['jasonyihk@gmail.com'],
        accessRelease: if process.env.HUBOT_RELEASE_ACCESS_LIST_PROD then (process.env.HUBOT_RELEASE_ACCESS_LIST_PROD).split(',') else ['jasonyihk@gmail.com']
      },
      {
        id: 'GC6PEUJTG',
        room:  'devops',
        namespace: 'NULL',
        repo: 'devops'
      },
    ]

    @roleList = [
      {
        id: 'bau',
        tag: 'bau',
        memberList: if process.env.HUBOT_DEPLOY_ROLE_LIST_BAU then (process.env.HUBOT_DEPLOY_ROLE_LIST_BAU).split(',') else ['jasonyihk@gmail.com'],
      },
      {
        id: 'qa',
        tag: 'qa',
        memberList: if process.env.HUBOT_DEPLOY_ROLE_LIST_QA then (process.env.HUBOT_DEPLOY_ROLE_LIST_QA).split(',') else ['jasonyihk@gmail.com'],
      }
    ]

  validAccess: (type, id, email) ->
    if !email? || !id?
      return false

    accessList = @accessList.filter (it) ->
      it.id == id

    if !accessList?
      return true

    access = accessList[0]["#{type}"]
    if !access || !access.length?
      return true

    if email not in access
      return false
    true

  getNamespaceByRoomID: (id) ->
    accessList = @accessList.filter (it) ->
      it.id == id

    if !accessList?
      return null

    access = accessList[0]
    return access.namespace

  getNamespaceByRoomName: (room) ->
    accessList = @accessList.filter (it) ->
      it.room == room

    if !accessList?
      return null

    access = accessList[0]
    return access.namespace

  getNamespaceByRepo: (repo) ->
    accessList = @accessList.filter (it) ->
      it.repo == repo

    if !accessList?
      return null
    access = accessList[0]
    return access.namespace

  getRoomByRepo: (repo) ->
    accessList = @accessList.filter (it) ->
      it.repo == repo

    if !accessList?
      return 'dev'
    access = accessList[0]

    unless access?
      return 'dev'
    return access.room

  getRepoByNamespace: (namespace) ->
    accessList = @accessList.filter (it) ->
      it.namespace == namespace

    if !accessList?
      return null
    access = accessList[0]

    unless access?
      return null
    return access.repo

  getRoomByNamespace: (namespace) ->
    accessList = @accessList.filter (it) ->
      it.namespace == namespace

    if !accessList?
      return 'dev'
    access = accessList[0]
    unless access?
      return 'dev'
    return access.room

  getByRoomID: (id) ->
    accessList = @accessList.filter (it) ->
      it.id == id

    if !accessList?
      return null

    access = accessList[0]
    return access.namespace

  getTagByEmail: (email) ->
    roleList = @roleList.filter (it) ->
      email in it.memberList

    if !roleList?
      return null

    role = roleList[0]
    return role.tag

exports.BasicAuth      = BasicAuth
exports.IPAuth         = IPAuth
exports.DeployAuth     = DeployAuth
