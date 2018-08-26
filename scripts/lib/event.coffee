Path                     = require "path"

exports.BitBucketPullRequest      = require(Path.join(__dirname, '..', "models", "pull_request")).BitBucketPullRequest
exports.DevOpsMessage             = require(Path.join(__dirname, '..', "models", "devops_message")).DevOpsMessage
exports.HubotMessage               = require(Path.join(__dirname, '..', "models", "hubot_message")).HubotMessage
exports.JenkinsBuild              = require(Path.join(__dirname, '..', "models", "jenkins_build")).JenkinsBuild
exports.DeploymentMessage         = require(Path.join(__dirname, '..', "models", "deployment_message")).DeploymentMessage

exports.DevOpsEvent               = 'devops:event'
exports.JenkinsEvent              = 'jenkins:event'
exports.HubotEvent                = 'hubot:event'
exports.DeployEvent               = 'deployment:deploy'
exports.ReleaseEvent              = 'deployment:release'
exports.BitBucketPullRequestEvents= ['pullrequest:created', 'pullrequest:approved', 'pullrequest:rejected', 'pullrequest:fulfilled']
