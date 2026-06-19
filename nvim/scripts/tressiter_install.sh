#/bin/zsh
target=~/.local/share/nvim/site/parser/
mkdir -p $target

# install python
git clone --depth 1 https://github.com/tree-sitter/tree-sitter-python
cd tree-sitter-python/
tree-sitter build -o python.so
cp ./python.so $target
cd ../
rm -rf tree-sitter-python


# install bash
git clone --depth 1 https://github.com/tree-sitter/tree-sitter-bash
cd tree-sitter-bash/
tree-sitter build -o bash.so
cp ./sh.so $target
cd ../
rm -rf tree-sitter-bash

# install json
git clone --depth 1 https://github.com/tree-sitter/tree-sitter-json
cd tree-sitter-json/
tree-sitter build -o json.so
cp ./json.so $target
cd ../
rm -rf tree-sitter-json

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

