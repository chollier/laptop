fancy_echo() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
  printf "\n$fmt\n" "$@"
}

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e

if [ ! -d "$HOME/.bin/" ]; then
  mkdir "$HOME/.bin"
fi

if [ ! -f "$HOME/.zshrc" ]; then
  touch "$HOME/.zshrc"
fi

case "$SHELL" in
  */zsh) : ;;
  *)
    fancy_echo "Changing your shell to zsh ..."
      chsh -s "$(which zsh)"
    ;;
esac

if ! command -v brew >/dev/null; then
  fancy_echo "Installing Homebrew ..."
    curl -fsS \
      'https://raw.githubusercontent.com/Homebrew/install/master/install' | ruby

    brew install caskroom/cask/brew-cask
    export PATH="/usr/local/bin:$PATH"
else
  fancy_echo "Homebrew already installed. Skipping ..."
fi

fancy_echo "Installing rcm..."
  brew install rcm

# Clone this repo
cd ~
fancy_echo "Downloading dotfiles"
  git clone git://github.com/chollier/mydotfiles

# Install homebrew
# Installing dotfiles
fancy_echo "Installing dotfiles"
  env RCRC=$HOME/mydotfiles/rcrc rcup

source ~/.zshrc

# install xcode CLI
fancy_echo "Installing XCode CLI Tools..."
  xcode-select --install

# Install oh my zsh
fancy_echo "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

source ~/.zshrc

#installing docker
fancy_echo "Installing and starting docker"
  brew cask install dockertoolbox
  docker-machine create -d virtualbox dev
  docker-machine start dev
  eval "$(docker-machine env dev)"


# Install Homebrew bundle and runs it
fancy_echo "Installing Homebrew bundle and running it..."
  brew tap Homebrew/bundle
  cd ~/mydotfiles &&  brew bundle

# Some OS X config
# safari dev
fancy_echo "Settings some OS X settings..."
  defaults write com.apple.Safari IncludeInternalDebugMenu -bool true && \
  defaults write com.apple.Safari IncludeDevelopMenu -bool true && \
  defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true && \
  defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true && \
  defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# Show finder status bar
  defaults write com.apple.finder ShowStatusBar -bool true

# Enable character repeat on keydown
  defaults write -g ApplePressAndHoldEnabled -bool false

# Set a shorter Delay until key repeat
  defaults write NSGlobalDomain InitialKeyRepeat -int 12

# Set a blazingly fast keyboard repeat rate
  defaults write NSGlobalDomain KeyRepeat -int 0

# Disable ext change warning
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Check for software updates daily, not just once per week
  defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Show icons for hard drives, servers, and removable media on the desktop
  defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true && \
  defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true && \
  defaults write com.apple.finder ShowMountedServersOnDesktop -bool true && \
  defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Avoid creating .DS_Store files on network volumes
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Disable disk image verification
  defaults write com.apple.frameworks.diskimages skip-verify -bool true && \
  defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true && \
  defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Show the ~/Library folder
  chflags nohidden ~/Library

# autohide dock
fancy_echo "Setting up Dock..."
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock magnification -bool true
  defaults write com.apple.dock minimize-to-application -bool true
  defaults write com.apple.dock orientation left
  defaults write com.apple.dock dashboard-in-overlay -bool true

  killall Dock

# install iterm2 solarized colors :
fancy_echo "Install iterm2 Solarized colors"
  cd ~/Downloads
  wget "https://raw.githubusercontent.com/altercation/solarized/master/iterm2-colors-solarized/Solarized%20Dark.itermcolors"
  wget https://raw.githubusercontent.com/altercation/solarized/master/iterm2-colors-solarized/Solarized%20Light.itermcolors
  open Solarized*

fancy_echo "Install Monaco for Powerline..."
  wget https://gist.github.com/baopham/1838072/raw/616d338cea8b9dcc3a5b17c12fe3070df1b738c0/Monaco%2520for%2520Powerline.otf
  open Monaco*

#install node and ruby last versions
source ~/.zshrc

fancy_echo "Running nvm install stable..."
  nvm install stable

brew unlink openssl && brew link openssl --force

eval "$(rbenv init - zsh)"
if ! rbenv versions | grep -Fq "2.2.1"; then
  rbenv install 2.2.1
fi

rbenv global 2.2.1
rbenv shell 2.2.1

fancy_echo "updage gem, install bundler"
  gem update --system
  gem install bundler

# config bundler
  number_of_cores=$(sysctl -n hw.ncpu)
  bundle config --global jobs $((number_of_cores - 1))

fancy_echo "DONE !!"
