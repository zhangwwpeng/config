# 用本仓库覆盖 ~/.config 与 ~/ 下的 dotfiles（以仓库为准，目标端多余文件会被删除）。
CONFIG_DIRS := bettercmdtab karabiner kitty neovide nvim sketchybar
DOTFILES    := .common_sh .zshrc .bashrc

RSYNC := rsync -a --delete \
	--exclude .git/ --exclude .claude/ --exclude .DS_Store \
	--exclude .venv/ --exclude .ruff_cache/ --exclude .rumdl_cache/ \
	--exclude __pycache__/ --exclude '*.pyc' --exclude node_modules/

.PHONY: install config dotfiles $(CONFIG_DIRS)

install: config dotfiles

config: $(CONFIG_DIRS)

$(CONFIG_DIRS):
	@mkdir -p $(HOME)/.config/$@
	$(RSYNC) $@/ $(HOME)/.config/$@/

dotfiles:
	@for f in $(DOTFILES); do install -m 0644 $$f $(HOME)/$$f && echo "$$f -> $(HOME)/$$f"; done
