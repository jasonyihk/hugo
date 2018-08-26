# hugo

hugo is a chat bot built on the [Hubot][hubot] framework.

### Running hugo Locally

with [environment variables](#configuration) being set properly

Install all dependencies by running

    % npm install

Start om-hubot locally by running:

    % ./hubot.sh

Interact with om-hubot by typing `hugo help`.

    hugo> hugo help
    hugo help - Displays all of the help commands that om-hubot knows about.
    ...

### Deploying to kubernetes

Setup Jenkins pipelines with Jenkinsfile and Jenkinsfile.deploy, it will handle all the thing necessary.
It read kube/*.yaml for the deployement config.

### Setup Jenkins Hugo integration

Visit https://jenkins.example.com/configure and fill in necessary information for each site.