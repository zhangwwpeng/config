.PHONY: sync install update

CURRENT_DIR = `pwd`


sync:
	git add .
	git commit -m "update"
	git push origin main

update:
	git pull origin main

install:
	ln -s ${CURRENT_DIR}/kitty ~/.config/kitty
