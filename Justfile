install:
    just _backup_and_link "kitty" "kitty"
    just _backup_and_link "nvim" "nvim"
    just _backup_and_link "neovide" "neovide"
    just _backup_and_link "karabiner" "karabiner"
    just _backup_and_link "yabai" "yabai"
    just _backup_and_link "glide" "glide"
    just _backup_and_link_dotfile ".zshrc"
    just _backup_and_link_dotfile ".bashrc"

_backup_and_link name dest:
    @echo "Installing {{name}}..."
    -mkdir -p {{justfile_directory()}}/tmp/.config
    -if [ -d ~/.config/{{dest}} ]; then cp -r ~/.config/{{dest}} {{justfile_directory()}}/tmp/.config/{{name}}; fi
    -rm -rf ~/.config/{{dest}}
    -cp -r {{justfile_directory()}}/{{name}} ~/.config/{{dest}}

_backup_and_link_dotfile name:
    @echo "Installing {{name}}..."
    -if [ -f ~/{{name}} ]; then cp ~/{{name}} {{justfile_directory()}}/tmp/{{name}}; fi
    -rm -f ~/{{name}}
    -cp {{justfile_directory()}}/{{name}} ~/{{name}}
