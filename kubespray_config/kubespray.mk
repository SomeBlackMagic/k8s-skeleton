#Upgrading man in kubespray - https://github.com/kubernetes-sigs/kubespray/blob/master/docs/upgrades.md
KS_DOCKER_SHELL=docker run --rm -v ${PWD}:/app/inventory -v ${SSH_AUTH_SOCK}:/root/.ssh-agent -e SSH_AUTH_SOCK=/root/.ssh-agent -it ${KS_DOCKER}:latest ansible-playbook -i inventory/kubespray_config/inventory.ini

docker_build: ## Build docker image for run kubespray_* commands
	docker build --build-arg KS_VERSION=${KS_VERSION} -t ${KS_DOCKER}:latest .

docker_exec: ## Enter to docker container
	docker run --rm -it ${KS_DOCKER}:latest bash

docker_clean: ## Remove image
	docker rmi ${KS_DOCKER}:latest

kubespray_create: ## Create new cluster(only in new installation)
	${KS_DOCKER_SHELL} --become -u root cluster.yml

kubespray_update: ## Update cluster config(if vars change in kubespray_config folder)
	${KS_DOCKER_SHELL} --become -u root upgrade-cluster.yml

kubespray_scale: ## TODO add help
	${KS_DOCKER_SHELL} --become -u root scale.yml

kubespray_update_network: ## Update cluster network config(if setup network in kubespray)
	${KS_DOCKER_SHELL} --become -u root cluster.yml --tags=network

kubespray_update_master: ## Update cluster network config(if setup network in kubespray)
	${KS_DOCKER_SHELL} --become -u root cluster.yml --tags=master


kubespray_delete: ## Remove node from cluster
	${KS_DOCKER_SHELL} --become -u root remove-node.yml -e node=$(node)

kubespray_reset: ## Remove all nodes and destroy cluster
	${KS_DOCKER_SHELL} --become -u root reset.yml

kubespray_delete_offline: ## TODO add help
	${KS_DOCKER_SHELL} --become -u root remove-node.yml -e node=$(node) -e reset_nodes=false