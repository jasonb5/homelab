.PHONY: bootstrap
bootstrap:
	curl -sfL -o - https://github.com/go-task/task/releases/download/v3.19.0/task_linux_amd64.tar.gz | \
		sudo tar -xzf - --exclude=LICENSE --exclude=README.md --exclude=completion -C /usr/local/bin && \
		sudo chown root:root /usr/local/bin/task && \
		sudo chmod 0755 /usr/local/bin/task
