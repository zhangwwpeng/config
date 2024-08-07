install: install_zshrc
    rm -rf ~/.zimrc
    rm -rf ~/.p10k.zsh
    rm -rf ~/.config/kitty
    rm -rf ~/.config/bat
    rm -rf ~/.config/nvim/lua
    rm -rf ~/.config/neovide
    rm -rf ~/.gitconfig
    rm -rf ~/.config/lazygit
    rm -rf ~/.config/yazi
    -ln -s {{justfile_directory()}}/.zimrc ~/.zimrc
    -ln -s {{justfile_directory()}}/.p10k.zsh ~/.p10k.zsh
    -ln -s {{justfile_directory()}}/kitty ~/.config
    -ln -s {{justfile_directory()}}/bat ~/.config
    -ln -s {{justfile_directory()}}/lua ~/.config/nvim
    -ln -s {{justfile_directory()}}/neovide ~/.config/neovide
    -ln -s {{justfile_directory()}}/git/.gitconfig ~/.gitconfig
    -ln -s {{justfile_directory()}}/lazygit ~/.config/lazygit
    -ln -s {{justfile_directory()}}/yazi ~/.config/yazi
    # build bat theme
    bat cache --build

[macos]
install_zshrc:
    rm -rf ~/.zshrc
    -ln -s {{justfile_directory()}}/.zshrc_macos ~/.zshrc

[linux]
install_zshrc:
    rm -rf ~/.zshrc
    -ln -s {{justfile_directory()}}/.zshrc_linux ~/.zshrc

[macos]
install_pkt:
    brew install fd
    brew install rg
    brew install neovim
    brew install bottom
    brew install fzf
    brew install zoxide
    brew install bat
    brew install pipenv
    brew install git-delta
    brew install lazygit
    brew install yazi
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

[linux]
install_pkt:
    mkdir install_pkt
    cd install_pkt
    # install fd
    curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep "browser_download_url" | grep "_amd64.deb" | tail -n 1 | cut -d '"' -f 4 | wget -qi -
    sudo dpkg -i *.deb
    rm *.deb
    # install rg
    curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep "browser_download_url" | grep "deb" | head -n 1 | cut -d '"' -f 4 | wget -qi -
    sudo dpkg -i *.deb
    rm *.deb
    # install nvim
    curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep "browser_download_url" | grep "appimage" | head -n 1 | cut -d '"' -f 4 | wget -qi -
    mv nvim.appimage nvim
    mv ./nvim ~/.local/bin
    # install btm
    curl -s https://api.github.com/repos/ClementTsang/bottom/releases/latest | grep "browser_download_url" | grep "amd64.deb" | tail -n 1 | cut -d '"' -f 4 | wget -qi -
    sudo dpkg -i *.deb
    rm *.deb
    # install fzf
    curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep "browser_download_url" | grep "linux_amd64" | cut -d '"' -f 4 | wget -qi -
    tar -zxvf *.tar.gz
    mv ./fzf ~/.local/bin
    # install kitty
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    # install zoxide
    curl -s https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest | grep "browser_download_url" | grep "amd64.deb" | cut -d '"' -f 4 | wget -qi -
    sudo dpkg -i *.deb
    rm *.deb
    # install pipenv
    pip install --user pipenv
    # install bat
    curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep "browser_download_url" | grep "amd64.deb" | tail -n 1 | cut -d '"' -f 4 | wget -qi -
    sudo dpkg -i *.deb
    rm *.deb
    # install delta
    curl -s https://api.github.com/repos/dandavison/delta/releases/latest | grep "browser_download_url" | grep "amd64.deb" | tail -n 1 | cut -d '"' -f 4 | wget -qi -
    sudo dpkg -i *.deb
    rm *.deb
    # install lazygit
    curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep "browser_download_url" | grep "Linux_x86_64.tar.gz" | tail -n 1 | cut -d '"' -f 4 | wget -qi -
    tar -zxvf *.tar.gz
    mv ./lazygit ~/.local/bin
    # install yazi
    curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | grep "browser_download_url" | grep "unknown-linux-gnu.zip" | tail -n 1 | cut -d '"' -f 4 | wget -qi -
    mv ./yazi-x86_64-unknown-linux-gnu/yazi ~/.local/bin
    cd ..
    rm -rf install_pkt

check:
    @echo "{{check_git}}"
    @echo "{{check_fd}}"
    @echo "{{check_rg}}"
    @echo "{{check_nvim}}"
    @echo "{{check_btm}}"
    @echo "{{check_fzf}}"
    @echo "{{check_kitty}}"
    @echo "{{check_zoxide}}"
    @echo "{{check_pipenv}}"
    @echo "{{check_bat}}"
    @echo "{{check_delta}}"
    @echo "{{check_lazygit}}"
    @echo "{{check_yazi}}"


# make sure install
GIT_VERSION     := `git     --version > /dev/null 2>&1 ; if [ $? = 0 ] ; then git       --version ; else echo "mis_command" ; fi`
FD_VERSION      := `fd      --version > /dev/null 2>&1 ; if [ $? = 0 ] ; then fd        --version ; else echo "mis_command" ; fi`
RG_VERSION      := `rg      --version > /dev/null 2>&1 ; if [ $? = 0 ] ; then rg        --version ; else echo "mis_command" ; fi`
NVIM_VERSION    := `nvim    --version > /dev/null 2>&1 ; if [ $? = 0 ] ; then nvim      --version ; else echo "mis_command" ; fi`
BTM_VERSION     := `btm     --version > /dev/null 2>&1 ; if [ $? = 0 ] ; then btm       --version ; else echo "mis_command" ; fi`
FZF_VERSION     := `fzf     --version > /dev/null 2>&1 ; if [ $? = 0 ] ; then fzf       --version ; else echo "mis_command" ; fi`
KITTY_VERSION   := `kitty   --version > /dev/null 2>&1 ; if [ $? = 0 ] ; then kitty     --version ; else echo "mis_command" ; fi`
ZOXIDE_VERSION  := `zoxide  --version > /dev/null 2>&1 ; if [ $? = 0 ] ; then zoxide    --version ; else echo "mis_command" ; fi`
PIPENV_VERSION  := `pipenv  --version > /dev/null 2>&1 ; if [ $? = 0 ] ; then pipenv    --version ; else echo "mis_command" ; fi`
BAT_VERSION     := `bat     --version > /dev/null 2>&1 ; if [ $? = 0 ] ; then bat       --version ; else echo "mis_command" ; fi`
DELTA_VERSION   := `delta   --version > /dev/null 2>&1 ; if [ $? = 0 ] ; then delta     --version ; else echo "mis_command" ; fi`
LAZYGIT_VERSION := `lazygit --version > /dev/null 2>&1 ; if [ $? = 0 ] ; then lazygit   --version ; else echo "mis_command" ; fi`
YAZI_VERSION    := `yazi    --version > /dev/null 2>&1 ; if [ $? = 0 ] ; then yazi      --version ; else echo "mis_command" ; fi`

check_git       := if GIT_VERSION == "mis_command" { "[Error] can't find git" } else { "[Log  ] find git" }
check_fd        := if FD_VERSION == "mis_command" { "[Error] can't find fd" } else { "[Log  ] find fd" }
check_rg        := if RG_VERSION == "mis_command" { "[Error] can't find rg" } else { "[Log  ] find rg" }
check_nvim      := if NVIM_VERSION == "mis_command" { "[Error] can't find nvim" } else { "[Log  ] find nvim" }
check_btm       := if BTM_VERSION == "mis_command" { "[Error] can't find btm" } else { "[Log  ] find btm" }
check_fzf       := if FZF_VERSION == "mis_command" { "[Error] can't find fzf" } else { "[Log  ] find fzf" }
check_kitty     := if KITTY_VERSION == "mis_command" { "[Error] can't find kitty" } else { "[Log  ] find kitty" }
check_zoxide    := if ZOXIDE_VERSION == "mis_command" { "[Error] can't find zoxide" } else { "[Log  ] find zoxide" }
check_pipenv    := if PIPENV_VERSION == "mis_command" { "[Error] can't find pipenv" } else { "[Log  ] find pipenv" }
check_bat       := if BAT_VERSION == "mis_command" { "[Error] can't find bat" } else { "[Log  ] find bat" }
check_delta     := if DELTA_VERSION == "mis_command" { "[Error] can't find delta" } else { "[Log  ] find delta" }
check_lazygit   := if LAZYGIT_VERSION == "mis_command" { "[Error] can't find lazygit" } else { "[Log  ] find lazygit" }
check_yazi      := if YAZI_VERSION == "mis_command" { "[Error] can't find yazi" } else { "[Log  ] find yazi" }
