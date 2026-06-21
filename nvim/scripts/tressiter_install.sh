#/bin/zsh
target=~/.local/share/nvim/site/parser/
mkdir -p $target

# install python (pinned to v0.25.0; master has breaking query incompatibilities)
git clone --depth 1 --branch v0.25.0 https://github.com/tree-sitter/tree-sitter-python
cd tree-sitter-python/
tree-sitter build -o python.so
cp ./python.so $target
cd ../
rm -rf tree-sitter-python


# install bash
git clone --depth 1 https://github.com/tree-sitter/tree-sitter-bash
cd tree-sitter-bash/
tree-sitter build -o bash.so
cp ./bash.so $target
cd ../
rm -rf tree-sitter-bash

# install json
git clone --depth 1 https://github.com/tree-sitter/tree-sitter-json
cd tree-sitter-json/
tree-sitter build -o json.so
cp ./json.so $target
cd ../
rm -rf tree-sitter-json

# install yaml
git clone --depth 1 https://github.com/tree-sitter-grammars/tree-sitter-yaml
cd tree-sitter-yaml/
tree-sitter build -o yaml.so
cp ./yaml.so $target
cd ../
rm -rf tree-sitter-yaml

# install toml
git clone --depth 1 https://github.com/tree-sitter-grammars/tree-sitter-toml
cd tree-sitter-toml/
tree-sitter build -o toml.so
cp ./toml.so $target
cd ../
rm -rf tree-sitter-toml

# install rust
git clone --depth 1 https://github.com/tree-sitter/tree-sitter-rust
cd tree-sitter-rust
tree-sitter build -o rust.so
cp ./rust.so $target
cd ../
rm -rf tree-sitter-rust

# install tcl
git clone --depth 1 https://github.com/tree-sitter-grammars/tree-sitter-tcl
cd tree-sitter-tcl/
tree-sitter build -o tcl.so
cp ./tcl.so $target
cd ../
rm -rf tree-sitter-tcl

# install systemverilog
git clone --depth 1 https://github.com/gmlarumbe/tree-sitter-systemverilog
cd tree-sitter-systemverilog
tree-sitter build -o systemverilog.so
cp ./systemverilog.so $target
cd ../
rm -rf tree-sitter-systemverilog

# install just
git clone --depth 1 https://github.com/casey/tree-sitter-just
cd tree-sitter-just/
tree-sitter build -o just.so
cp ./just.so $target
cd ../
rm -rf tree-sitter-just

# install make
git clone --depth 1 https://github.com/tree-sitter-grammars/tree-sitter-make
cd tree-sitter-make/
tree-sitter build -o make.so
cp ./make.so $target
cd ../
rm -rf tree-sitter-make

