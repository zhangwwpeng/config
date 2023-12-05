.PHONY: sync install update

CURRENT_DIR = `pwd`


sync:
	git add .
	git commit -m "update"
	git push origin main

update:
	git pull origin main

install:
	-ln -s ${CURRENT_DIR}/.p10k.zsh ~/.p10k.zsh
	-ln -s ${CURRENT_DIR}/.zimrc ~/.zimrc
	-ln -s ${CURRENT_DIR}/bat/config ~/.config/bat/config
	-ln -s ${CURRENT_DIR}/kitty ~/.config
	-ln -s ${CURRENT_DIR}/.zshrc ~/.zshrc
	-ln -s ${CURRENT_DIR}/lua ~/.config/nvim/lua
