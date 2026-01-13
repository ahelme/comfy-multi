#!/bin/bash
# Run this on Verda to create a dotfiles backup

set -e

echo "🔧 Creating dotfiles repository..."

# Create dotfiles repo directory
mkdir -p ~/dotfiles

# Copy configuration files
echo "  Copying config files..."
cp ~/.zshrc ~/dotfiles/ 2>/dev/null || echo "    Warning: .zshrc not found"
cp ~/.vimrc ~/dotfiles/ 2>/dev/null || true
cp ~/.tmux.conf ~/dotfiles/ 2>/dev/null || true
cp ~/.gitconfig ~/dotfiles/ 2>/dev/null || true

# Copy oh-my-zsh custom theme
if [ -d ~/.oh-my-zsh/custom/themes ]; then
    echo "  Copying oh-my-zsh themes..."
    mkdir -p ~/dotfiles/oh-my-zsh-themes
    cp -r ~/.oh-my-zsh/custom/themes/* ~/dotfiles/oh-my-zsh-themes/
fi

# Create installation script
echo "  Creating install.sh..."
cat > ~/dotfiles/install.sh << 'INSTALL'
#!/bin/bash
set -e

echo "🚀 Installing dev environment..."

# Install base packages
sudo apt-get update
sudo apt-get install -y zsh git curl wget

# Install oh-my-zsh
if [ ! -d ~/.oh-my-zsh ]; then
    echo "  Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install Tailscale
if ! command -v tailscale &> /dev/null; then
    echo "  Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    echo "  ⚠️  Run 'sudo tailscale up' to authenticate"
fi

# Symlink dotfiles
echo "  Symlinking dotfiles..."
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/.vimrc ~/.vimrc 2>/dev/null || true
ln -sf ~/dotfiles/.tmux.conf ~/.tmux.conf 2>/dev/null || true
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig 2>/dev/null || true

# Install custom oh-my-zsh themes
if [ -d ~/dotfiles/oh-my-zsh-themes ]; then
    echo "  Installing oh-my-zsh themes..."
    mkdir -p ~/.oh-my-zsh/custom/themes
    cp -r ~/dotfiles/oh-my-zsh-themes/* ~/.oh-my-zsh/custom/themes/
fi

# Change default shell to zsh
echo "  Changing default shell to zsh..."
sudo chsh -s $(which zsh) $USER

echo ""
echo "✅ Dev environment installed!"
echo "   Run 'exec zsh' to start using your shell"
INSTALL

chmod +x ~/dotfiles/install.sh

# Create README
cat > ~/dotfiles/README.md << 'README'
# Development Environment Dotfiles

Quick setup for zsh, oh-my-zsh, custom themes, and Tailscale.

## Installation

```bash
git clone https://github.com/ahelme/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Files

- `.zshrc` - Zsh configuration with custom theme
- `.vimrc` - Vim configuration (if present)
- `.tmux.conf` - tmux configuration (if present)
- `.gitconfig` - Git configuration (if present)
- `oh-my-zsh-themes/` - Custom oh-my-zsh themes (bullet-train, etc.)

## Requirements

- Ubuntu/Debian-based system
- sudo access
- Git installed

## Post-Installation

1. Authenticate Tailscale: `sudo tailscale up`
2. Start zsh: `exec zsh`
3. Enjoy your customized environment!
README

# Initialize git repo
cd ~/dotfiles
git init
git add .
git commit -m "Initial dotfiles backup - zsh, oh-my-zsh, custom themes"

echo ""
echo "✅ Dotfiles repo created at ~/dotfiles"
echo ""
echo "Next steps:"
echo "  1. Create GitHub repo: https://github.com/new"
echo "  2. Push dotfiles:"
echo "     cd ~/dotfiles"
echo "     git remote add origin git@github.com:ahelme/dotfiles.git"
echo "     git branch -M main"
echo "     git push -u origin main"
echo ""
echo "To restore on a new machine:"
echo "  git clone https://github.com/ahelme/dotfiles.git ~/dotfiles"
echo "  cd ~/dotfiles && ./install.sh"
