serve:
	mkdocs serve --config-file mkdocs.yml
build:
	mkdocs build --config-file mkdocs.yml
deploy:
	mkdocs gh-deploy --force --config-file mkdocs.yml
