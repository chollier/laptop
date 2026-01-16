#!/bin/bash

fancy_echo() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
  printf "#####################################\n"
  printf "\n$fmt\n" "$@"
  printf "#####################################\n"
}

ask_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local response

  if [[ "$default" == "y" ]]; then
    printf "%s [Y/n]: " "$prompt"
  else
    printf "%s [y/N]: " "$prompt"
  fi

  read -r response

  # Handle empty response (just pressed Enter)
  if [[ -z "$response" ]]; then
    response="$default"
  fi

  [[ "$response" =~ ^[Yy]$ ]]
}

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e

# Accept Xcode license
fancy_echo "Accepting Xcode license..."
sudo xcodebuild -license accept 2>/dev/null || true

# Install Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  fancy_echo "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "Press any key after the Command Line Tools installation completes..."
  read -r
else
  fancy_echo "Xcode Command Line Tools already installed"
fi

# Install Homebrew
if ! command -v brew >/dev/null; then
  fancy_echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for Apple Silicon Macs
  if [[ $(uname -m) == 'arm64' ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    export PATH="/usr/local/bin:$PATH"
  fi
else
  fancy_echo "Homebrew already installed. Skipping..."
fi

# Install rcm for dotfile management
if ! command -v lsrc >/dev/null; then
  fancy_echo "Installing rcm..."
  brew tap thoughtbot/formulae
  brew install rcm
else
  fancy_echo "rcm already installed. Skipping..."
fi

# Clone laptop repo
cd ~
if [ ! -d "$HOME/laptop" ]; then
  fancy_echo "Cloning laptop repository..."
  git clone https://github.com/chollier/laptop.git
else
  fancy_echo "laptop repo already exists. Updating..."
  cd ~/laptop
  git pull
fi

# Clone dotfiles repo
cd ~
if [ ! -d "$HOME/mydotfiles" ]; then
  fancy_echo "Cloning mydotfiles repository..."
  git clone https://github.com/chollier/mydotfiles.git
else
  fancy_echo "mydotfiles already exists. Updating..."
  cd ~/mydotfiles
  git pull
fi

# Install Homebrew packages from Brewfile
fancy_echo "Installing Homebrew packages from Brewfile..."
cd ~/laptop
brew bundle

# Set zsh as default shell
if [[ "$SHELL" != "$(which zsh)" ]]; then
  fancy_echo "Setting zsh as default shell..."
  chsh -s "$(which zsh)"
fi

# Install oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  fancy_echo "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  fancy_echo "oh-my-zsh already installed. Skipping..."
fi

# Install powerlevel10k theme for oh-my-zsh
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
  fancy_echo "Installing powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
  fancy_echo "powerlevel10k already installed. Updating..."
  cd ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
  git pull
fi

# Install dotfiles
fancy_echo "Installing dotfiles with rcm..."
env RCRC=$HOME/mydotfiles/rcrc rcup

# macOS Settings - Interactive configuration
echo ""
fancy_echo "macOS Settings Configuration"
echo "The following sections will configure various macOS settings."
echo "You can choose which categories to apply."
echo ""

# Note: Safari settings are sandboxed in modern macOS and can't be modified via defaults write
# Enable developer features manually: Safari > Settings > Advanced > Show features for web developers

# Finder Settings
if ask_yes_no "Configure Finder? (Show hidden files, extensions, status bar, path bar)"; then
  echo "Configuring Finder..."
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
  defaults write com.apple.finder AppleShowAllFiles -bool true
  chflags nohidden ~/Library

  defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
  defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
  defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
  defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
fi

# Keyboard Settings
if ask_yes_no "Configure keyboard? (Enable key repeat, faster repeat rate)"; then
  echo "Configuring keyboard..."
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
fi

# Dock Settings
if ask_yes_no "Configure Dock? (Auto-hide, position left, magnification)"; then
  echo "Configuring Dock..."
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock magnification -bool true
  defaults write com.apple.dock minimize-to-application -bool true
  defaults write com.apple.dock orientation left
  defaults write com.apple.dock largesize -float 68
fi

# Screenshot Settings
if ask_yes_no "Configure screenshots? (Save to ~/Screenshots)"; then
  echo "Configuring screenshots..."
  mkdir -p ~/Screenshots
  defaults write com.apple.screencapture location -string "$HOME/Screenshots"
fi

# Mouse Settings
if ask_yes_no "Enable right-click for Bluetooth mouse?"; then
  echo "Configuring mouse..."
  defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode TwoButton
fi

# Software Update Settings
if ask_yes_no "Check for software updates daily?"; then
  echo "Configuring software updates..."
  defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
fi

# Apply changes
echo ""
echo "Applying changes..."
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

fancy_echo "Setup complete!"
echo ""
echo "Manual steps remaining:"
echo "  - Transfer ~/.aws credentials"
echo "  - Transfer ~/.ssh keys"
echo "  - Transfer .docker/config (if needed)"
echo "  - Transfer zsh history"
echo "  - Run 'p10k configure' to customize your prompt"
echo "  - Enable Safari developer features: Safari > Settings > Advanced > Show features for web developers"
echo "  - Restart your terminal or run: source ~/.zshrc"
