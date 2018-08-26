@Library('om.jenkins.pipeline.library') _

import com.pipeline.*

runPipeline([
	debug: true,
  shouldDeploy: false,
	docker: [
		image: 'om-hubot',
		buildPath: './build',
		shouldPush: true,
    registry: ['harbor'],
    project: 'devops'
	],
	stages: [
		dockerbuild: [
			label: 'Build Docker Image',
			run: true,
			script: "make docker-build"
		]
	]
]);
