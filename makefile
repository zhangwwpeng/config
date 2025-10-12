run:
	rm  -rf ~/.config/nvim/*
	mkdir -p ~/.config/nvim/lua
	cp -rf ./lua/init.lua ~/.config/nvim/
	cp -rf ./lua/config ~/.config/nvim/lua/
	cp -rf ./lua/lsp ~/.config/nvim/
	cp -rf ./lua/plugins ~/.config/nvim/lua/

