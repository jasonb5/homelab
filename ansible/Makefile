.PHONY: deploy%
deploy%:
	ansible-playbook -i hosts.yaml -e @"../secrets.yaml" $(if $*,-t $(subst -,,$*),) $(ARGS) deploy.yaml
