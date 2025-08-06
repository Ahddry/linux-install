#!/bin/bash

# Script installant les prérequis utilisateur (à exécuter SANS sudo)
# À exécuter APRÈS 1-prerequis-system.sh

# ***************
# Utils - Fonctions utilitaires
# ***************

# Fonction pour afficher un message coloré dans le terminal
# Utilisation : print_colored "message" "color"
print_colored() {
    COLOR_PREFIX="\033[0;"
    GREEN="32m"
    RED="31m"
    GREY="37m"
    INFO="96m"
    NO_COLOR="\033[0m"
    if [ "$2" == "danger" ]; then
        COLOR="${COLOR_PREFIX}${RED}"
    elif [ "$2" == "success" ]; then
        COLOR="${COLOR_PREFIX}${GREEN}"
    elif [ "$2" == "debug" ]; then
        COLOR="${COLOR_PREFIX}${GREY}"
    elif [ "$2" == "info" ]; then
        COLOR="${COLOR_PREFIX}${INFO}"
    else
        COLOR="${NO_COLOR}"
    fi
    printf "${COLOR}%b${NO_COLOR}\n" "$1"
}

# Vérification que le script N'EST PAS exécuté avec sudo
if [ "$EUID" -eq 0 ]; then
    print_colored "Ce script NE DOIT PAS être exécuté avec sudo" "danger"
    print_colored "Usage: ./1-prerequis-user.sh" "info"
    exit 1
fi

#****************
# Configuration utilisateur :
# - Configuration de ZSH comme shell par défaut
# - Installation d'Oh My Posh
# - Configuration du thème personnalisé
# - Installation de Homebrew
# - Installation de Gum
#****************

# Configuration de ZSH comme shell par défaut
print_colored "Configuration de ZSH comme shell par défaut..." "info"
chsh -s $(which zsh)
if [ $? -ne 0 ]; then
    print_colored "Échec de la configuration de ZSH comme shell par défaut." "danger"
    print_colored "Vous devrez peut-être entrer votre mot de passe." "info"
    exit 1
else
    print_colored "ZSH configuré comme shell par défaut." "success"
fi

# Installation d'Oh My Posh
print_colored "Installation d'Oh My Posh..." "info"
curl -s https://ohmyposh.dev/install.sh | bash -s
if [ $? -ne 0 ]; then
    print_colored "Échec de l'installation d'Oh My Posh." "danger"
    exit 1
else
    print_colored "Oh My Posh installé avec succès." "success"
    # Ajout au PATH et configuration dans .zshrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    echo 'eval "$(oh-my-posh --init --shell zsh --config ~/.montheme.omp.json)"' >> ~/.zshrc
fi

# Copie du thème personnalisé pour Oh My Posh
print_colored "Copie du thème personnalisé pour Oh My Posh..." "info"
if [ -f "./zsh/.montheme.omp.json" ]; then
    cp ./zsh/.montheme.omp.json ~/.montheme.omp.json
    if [ $? -ne 0 ]; then
        print_colored "Échec de la copie du thème personnalisé." "danger"
        exit 1
    else
        print_colored "Thème personnalisé copié avec succès." "success"
    fi
else
    print_colored "Fichier de thème ./zsh/.montheme.omp.json introuvable." "danger"
    print_colored "Vérifiez que vous exécutez le script depuis le bon répertoire." "info"
    exit 1
fi

# Installation de Homebrew
print_colored "Installation de Homebrew..." "info"
if ! command -v brew &> /dev/null; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ $? -ne 0 ]; then
        print_colored "Échec de l'installation de Homebrew." "danger"
        exit 1
    else
        print_colored "Homebrew installé avec succès." "success"

        # Détection du chemin d'installation de Homebrew
        if [ -d "/home/linuxbrew/.linuxbrew" ]; then
            BREW_PATH="/home/linuxbrew/.linuxbrew/bin/brew"
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
        elif [ -d "$HOME/.linuxbrew" ]; then
            BREW_PATH="$HOME/.linuxbrew/bin/brew"
            echo 'eval "$($HOME/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
        else
            print_colored "Installation alternative de Homebrew..." "info"
            # Installation manuelle si l'installation standard échoue
            git clone https://github.com/Homebrew/brew.git ~/.linuxbrew/Homebrew
            mkdir -p ~/.linuxbrew/bin
            ln -s ../Homebrew/bin/brew ~/.linuxbrew/bin/brew
            ~/.linuxbrew/bin/brew update --force --quiet
            BREW_PATH="$HOME/.linuxbrew/bin/brew"
            echo 'eval "$($HOME/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
        fi
    fi
else
    print_colored "Homebrew est déjà installé." "debug"
fi


# Installation de Gum
print_colored "Installation de Gum..." "info"
if command -v gum &> /dev/null; then
    print_colored "Gum est déjà installé." "debug"
    exit 0
else
    if [ -f "$BREW_PATH" ]; then
        $BREW_PATH install gum
        if [ $? -eq 0 ]; then
            print_colored "Gum installé avec succès via Homebrew." "success"
        else
            print_colored "Échec de l'installation de Gum via Homebrew, tentative alternative..." "info"
            # Installation alternative depuis GitHub
            cd /tmp
            curl -s https://api.github.com/repos/charmbracelet/gum/releases/latest | grep 'browser_download_url.*linux_amd64.tar.gz' | cut -d : -f 2,3 | tr -d '"' | wget -qi -
            tar -xzf gum_*_linux_amd64.tar.gz
            mkdir -p ~/.local/bin
            cp gum_*_linux_amd64/gum ~/.local/bin/
            rm -rf gum_*_linux_amd64*
            cd - > /dev/null
            print_colored "Gum installé avec succès via GitHub." "success"
        fi
    else
        print_colored "Homebrew non trouvé, installation de Gum via GitHub..." "info"
        # Installation directe depuis GitHub
        cd /tmp
        curl -s https://api.github.com/repos/charmbracelet/gum/releases/latest | grep 'browser_download_url.*linux_amd64.tar.gz' | cut -d : -f 2,3 | tr -d '"' | wget -qi -
        tar -xzf gum_*_linux_amd64.tar.gz
        mkdir -p ~/.local/bin
        cp gum_*_linux_amd64/gum ~/.local/bin/
        rm -rf gum_*_linux_amd64*
        cd - > /dev/null
        print_colored "Gum installé avec succès via GitHub." "success"
    fi
fi

print_colored "Installation des prérequis utilisateur terminée." "success"
print_colored "Veuillez redémarrer votre terminal ou exécuter 'source ~/.zshrc' pour appliquer les changements." "info"
print_colored "Vous pourrez ensuite exécuter le script d'installation des modules et outils essentiels." "info"

# Fin du script d'installation des prérequis utilisateur
#****************
