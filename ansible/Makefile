.PHONY: homelab%
homelab%:
	ansible-playbook -i hosts.yaml -e @"../secrets.yaml" $(if $*,-t $(subst -,,$*),) $(ARGS) homelab.yaml
