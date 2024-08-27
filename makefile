.PHONY: build

build:
	@echo Installing dependencies with aftman
	@aftman install
	@echo Installing dependencies with pesde
	@pesde install

rojo:
	@rojo serve darklua.project.json

darklua:
	@darklua process src build -c .darklua.json --watch

zap:
	@zap config.zap