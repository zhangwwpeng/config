# 用本仓库覆盖 ~/.config 与 ~/ 下的 dotfiles（以仓库为准，目标端多余文件会被删除）。
CONFIG_DIRS := bettercmdtab karabiner kitty neovide nvim sketchybar
DOTFILES    := .common_sh .zshrc .bashrc
CLAUDE_FILES := settings.json settings.local.json
AGY_FILES    := settings.json
OMP_FILES    := config.yml models.yml

RSYNC := rsync -a --delete \
	--exclude .git/ --exclude .claude/ --exclude .DS_Store \
	--exclude .venv/ --exclude .ruff_cache/ --exclude .rumdl_cache/ \
	--exclude __pycache__/ --exclude '*.pyc' --exclude node_modules/

.PHONY: install config dotfiles claude agy omp $(CONFIG_DIRS)

install: config dotfiles claude agy omp

config: $(CONFIG_DIRS)

$(CONFIG_DIRS):
	@mkdir -p $(HOME)/.config/$@
	$(RSYNC) $@/ $(HOME)/.config/$@/

dotfiles:
	@for f in $(DOTFILES); do install -m 0644 $$f $(HOME)/$$f && echo "$$f -> $(HOME)/$$f"; done

# Claude Code 设置与自定义主题（在 /theme 中选择 bamboo）
claude:
	@mkdir -p $(HOME)/.claude/themes
	@for f in $(CLAUDE_FILES); do install -m 0600 claude/$$f $(HOME)/.claude/$$f && echo "claude/$$f -> $(HOME)/.claude/$$f"; done
	$(RSYNC) claude/themes/ $(HOME)/.claude/themes/

# Antigravity CLI 设置、标题脚本与 Stop 通知 hook
agy:
	@mkdir -p $(HOME)/.gemini/antigravity-cli $(HOME)/.gemini/config
	@for f in $(AGY_FILES); do install -m 0600 agy/$$f $(HOME)/.gemini/antigravity-cli/$$f && echo "agy/$$f -> $(HOME)/.gemini/antigravity-cli/$$f"; done
	install -m 0755 agy/title.sh $(HOME)/.gemini/antigravity-cli/title.sh
	install -m 0644 agy/hooks.json $(HOME)/.gemini/config/hooks.json

# omp 模型/provider、主题与 composer 扩展
omp:
	@mkdir -p $(HOME)/.omp/agent/themes $(HOME)/.omp/agent/extensions
	@for f in $(OMP_FILES); do install -m 0600 omp/$$f $(HOME)/.omp/agent/$$f && echo "omp/$$f -> $(HOME)/.omp/agent/$$f"; done
	$(RSYNC) omp/themes/ $(HOME)/.omp/agent/themes/
	$(RSYNC) omp/extensions/ $(HOME)/.omp/agent/extensions/
