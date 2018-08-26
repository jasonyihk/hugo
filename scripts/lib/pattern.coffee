Inflection = require "inflection"

validSlug = "([-_\.0-9a-z]+)"

scriptPrefix = process.env['HUBOT_DEPLOY_PREFIX'] || "hugo deploy"

# The :hammer: regex that handles all /deploy requests
DEPLOY_SYNTAX = ///
  (#{scriptPrefix}(?:\:[^\s]+)?)        # / prefix
  (!)?\s+                               # Whether or not it was a forced deployment
  #{validSlug}                          # application name, from apps.json
  (?:\/([^\s]+))?                       # Branch or sha to deploy
  (?:\s+(?:to|in|on)\s+                 # http://i.imgur.com/3KqMoRi.gif
  #{validSlug}                          # Environment to release to
  (?:\/([^\s]+))?)?\s*                  # Host filter to try
  (?:([cbdefghijklnrtuv]{32,64}|\d{6})?\s*)?$ # Optional Yubikey
///i


# Supports tasks like
# /deploys github
#
# and
#
# /deploys github in staging
inflectedScriptPrefix = Inflection.pluralize(scriptPrefix)
DEPLOYS_SYNTAX = ///
  (#{inflectedScriptPrefix})      # / prefix
  \s+                             # hwhitespace
  #{validSlug}                    # application name, from apps.json
  (?:\/([^\s]+))?                 # Branch or sha to deploy
  (?:\s+(?:to|in|on)\s+           # http://i.imgur.com/3KqMoRi.gif
  #{validSlug})?                  # Environment to release to
///i

exports.DeployPrefix    = process.env['HUBOT_DEPLOY_PREFIX'] || "deploy"
exports.ReleasePrefix   = process.env['HUBOT_RELEASE_PREFIX'] || "release"
exports.ApprovePrefix   = process.env['HUBOT_APPROVE_PREFIX'] || "approve"
