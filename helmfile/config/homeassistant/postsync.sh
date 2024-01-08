#!/bin/bash

if [[ "${1}" == "install" ]]; then
	kubectl -n "${2}" apply -f config/homeassistant/traefik-middleware.yaml
elif [[ "${1}" == "postuninstall" ]]; then
	kubectl -n "${2}" delete -f config/homeassistant/traefik-middleware.yaml
fi
