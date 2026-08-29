.PHONY: fmt lint sourcemap typecheck test build check dev

fmt:
	stylua src tests

lint:
	stylua --check src tests
	selene src tests

sourcemap:
	rojo sourcemap default.project.json --output sourcemap.json

typecheck: sourcemap
	luau-lsp analyze --platform roblox --sourcemap sourcemap.json --definitions=types/globalTypes.d.luau src tests

test:
	lune run tests/run.luau

build:
	mkdir -p build
	rojo build default.project.json --output build/BobaSim.rbxl

check: lint typecheck test build

dev:
	rojo serve default.project.json
