#!/usr/bin/env bash

brews(
  awscli
  aws-shell
  coreutils
  findutils
  fzf
  git
  git-extras
  git-lfs  
  gnu-sed --with-default-names
  go
  gpg
  jq
  moreutils
  node --with-full-icu
  python
  python3  
  swagger-codegen
  tmux
  wget
  zsh-syntax-highlighting
)

casks(
  1password
  bartender
  betterzipql
  cakebrew
  chefdk
  cyberduck
  docker
  dropbox
  evernote
  firefox
  github-desktop
  google-chrome
  google-drive
  #no ia-writer
  iterm2
  licecap
  logitech-options
  #no magnet
  microsoft-office
  #microsoft-r-open
  #microsoft-teams
  #microsoft-azure-storage-explorer
  #no microsoft-remote-desktop
  #mysqlworkbench
  # no pastebox
  podcastmenu
  qlmarkdown
  quicklook-json
  quicklook-csv  
  #skype-for-business
  slack
  spotify
  textwrangler
  unrarx
  #no wunderlist
  vagrant
  #vagrant-manager
  virtualbox
  visual-studio
  visual-studio-code
)

pips=(
  pip
  boto3
  botocore
  docutils
  numpy
  python-dateutil
  six
  glances
  ohmu
  pythonpy
)

gems=(
  bundle
)

npms=(
  fenix-cli
  gitjk
  kill-tabs
  n
  nuclide-installer
)

git_configs=(
  "branch.autoSetupRebase always"
  "color.ui auto"
  "core.autocrlf input"
  "core.pager cat"
  "credential.helper osxkeychain"
  "merge.ff false"
  "pull.rebase true"
  "push.default simple"
  "rebase.autostash true"
  "rerere.autoUpdate true"
  "core.whitespace trailing-space,space-before-tab"
  "apply.whitespace fix"
  "rerere.enabled true"
  "user.name Matt Adorjan"
  "user.email matt.adorjan@gmail.com"
)

codeexts (
  aws-scripting-guy.cform
  donjayamanne.python
  JerryHong.autofilename
  ms-vscode.PowerShell
  naumovs.color-highlight
  shinnn.standard
  qinjia.seti-icons
)

fonts=(
  font-source-code-pro
)

######################################## End of app list ########################################
set +e
set -x

if test ! $(which brew); then
  echo "Installing Xcode ..."
  xcode-select --install

  echo "Installing Homebrew ..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Updating Homebrew ..."
  brew update
  brew upgrade
fi
brew doctor
brew tap homebrew/dupes

fails=()

function print_red {
  red='\x1B[0;31m'
  NC='\x1B[0m' # no color
  echo -e "${red}$1${NC}"
}

function install {
  cmd=$1
  shift
  for pkg in $@;
  do
    exec="$cmd $pkg"
    echo "Executing: $exec"
    if $exec ; then
      echo "Installed $pkg"
    else
      fails+=($pkg)
      print_red "Failed to execute: $exec"
    fi
  done
}

echo "Installing ruby ..."
brew install ruby-install chruby
ruby-install ruby
# TODO: enable auto switch here by following instructions
echo "ruby-2.3.1" > ~/.ruby-version
ruby -v

echo "Installing Java ..."
brew cask install java

echo "Installing packages ..."
brew info ${brews[@]}
install 'brew install' ${brews[@]}

echo "Tapping casks ..."
brew tap caskroom/fonts
brew tap caskroom/versions

echo "Installing software ..."
brew cask info ${casks[@]}
install 'brew cask install' ${casks[@]}

echo "Installing secondary packages ..."
install 'pip install --upgrade' ${pips[@]}
install 'gem install' ${gems[@]}
install 'npm install --global' ${npms[@]}
install 'code --install-extension' ${codeexts[@]}
install 'brew cask install' ${fonts[@]}

echo "Upgrading bash ..."
brew install bash
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
mv ~/.bash_profile ~/.bash_profile_backup
mv ~/.bashrc ~/.bashrc_backup
mv ~/.gitconfig ~/.gitconfig_backup
cd; curl -#L https://github.com/barryclark/bashstrap/tarball/master | tar -xzv --strip-components 1 --exclude={README.md,screenshot.png}
source ~/.bash_profile

echo "Setting git defaults ..."
for config in "${git_configs[@]}"
do
  git config --global ${config}
done

echo "Installing mac CLI ..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/guarinogabriel/mac-cli/master/mac-cli/tools/install)"

echo "Setting up iTerm2 and ZSH"
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
# https://gist.github.com/kevin-smets/8568070
sh -c "$(curl -fsSL https://github.com/powerline/fonts/blob/master/Meslo/Meslo%20LG%20M%20DZ%20Regular%20for%20Powerline.otf?raw=true)"
cp "Meslo LG M DZ Regular for Powerline.otf" ~/Library/Fonts/
cp .zshrc ~/.zshrc

echo "Updating ..."
pip install --upgrade setuptools
pip install --upgrade pip
gem update --system
mac update

echo "Cleaning up ..."
brew cleanup
brew cask cleanup
brew linkapps

for fail in ${fails[@]}
do
  echo "Failed to install: $fail"
done

echo "Done!"