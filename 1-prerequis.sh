#!/bin/bash

# Script installant les prérequis au script d'installation des modules et outils essentiels

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

show_help() {
    print_colored "Argument invalide" "danger"
    print_colored "Vous pouvez passer l'option --cli pour afficher uniquement les paquets CLI" "info"
    exit 1
}

invalid_input(){
    print_colored "Entrée invalide..." "danger"
}

APT_GET_DIR=$(which apt-get)
# Obtenir le nom de l'utilisateur réel (même si le script est exécuté avec sudo)
REAL_USER=${SUDO_USER:-$(whoami)}
REAL_HOME=$(eval echo ~$REAL_USER)

sudo true

#****************
# Vérification des arguments de la ligne de commande
#****************
print_colored "Vérification de la compatibilité" ""
if [ -z "$APT_GET_DIR" ]; then
    print_colored "La vérification de la compatibilité a échoué. Impossible de trouver apt-get." "danger"
    print_colored "Sortie" "danger"
    exit 1
else
    print_colored "La vérification de la compatibilité a réussi." "success"
fi

#****************
# Installation des paquets requis :
# - Git
# - Curl
# - Wget
# - Unzip
# - Python
# - Pip
# - ZSH + paramètres de configuration
# - Oh-my-posh + thème personnalisé
# - Homebrew
# - Gum (pour les menus interactifs des scripts suivants)
#****************

sudo apt-get update
print_colored "Installation des paquets requis..." ""
print_colored "Installation de git, curl, wget, unzip, python3 et python3-pip..." "info"

sudo apt-get install -y git curl wget unzip python3 python3-pip > /dev/null
if [ $? -ne 0 ]; then
    print_colored "Échec de l'installation des paquets requis." "danger"
    exit 1
else
    print_colored "Paquets requis installés avec succès." "success"
fi

# Installation de ZSH
print_colored "Installation de ZSH..." "info"
sudo apt-get install -y zsh > /dev/null
if [ $? -ne 0 ]; then
    print_colored "Échec de l'installation de ZSH." "danger"
    exit 1
else
    print_colored "ZSH installé avec succès." "success"
fi

#****************
# À partir d'ici, toutes les commandes doivent être exécutées SANS sudo
# pour que les configurations s'appliquent à l'utilisateur courant et non à root
#****************

# Configuration de ZSH comme shell par défaut
print_colored "Configuration de ZSH comme shell par défaut..." "info"
# Utilisation de sudo -u pour exécuter la commande en tant qu'utilisateur réel
sudo -u $REAL_USER chsh -s $(which zsh)
if [ $? -ne 0 ]; then
    print_colored "Échec de la configuration de ZSH comme shell par défaut." "danger"
    exit 1
else
    print_colored "ZSH configuré comme shell par défaut." "success"
fi

# Installation d'Oh My Posh
print_colored "Installation d'Oh My Posh..." "info"
# Exécution en tant qu'utilisateur réel pour installer dans son répertoire home
sudo -u $REAL_USER bash -c "curl -s https://ohmyposh.dev/install.sh | bash -s"
if [ $? -ne 0 ]; then
    print_colored "Échec de l'installation d'Oh My Posh." "danger"
    exit 1
else
    print_colored "Oh My Posh installé avec succès." "success"
    # Modification du .zshrc de l'utilisateur réel
    sudo -u $REAL_USER bash -c "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> $REAL_HOME/.zshrc"
    sudo -u $REAL_USER bash -c "echo 'eval \"\$(oh-my-posh --init --shell zsh --config ~/.montheme.omp.json)\"' >> $REAL_HOME/.zshrc"
fi

# Copie du thème personnalisé pour Oh My Posh
print_colored "Copie du thème personnalisé pour Oh My Posh..." "info"
sudo -u $REAL_USER cp ./zsh/.montheme.omp.json $REAL_HOME/.montheme.omp.json
if [ $? -ne 0 ]; then
    print_colored "Échec de la copie du thème personnalisé." "danger"
    exit 1
else
    if [ -f $REAL_HOME/.montheme.omp.json ]; then
        print_colored "Thème personnalisé copié avec succès." "success"
    else
        print_colored "Échec de la copie du thème personnalisé." "danger"
        exit 1
    fi
fi

# Installation de Homebrew
print_colored "Installation de Homebrew..." "info"
# Homebrew ne doit JAMAIS être installé en tant que root
sudo -u $REAL_USER bash -c "NONINTERACTIVE=1 /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
if [ $? -ne 0 ]; then
    print_colored "Échec de l'installation de Homebrew." "danger"
    exit 1
else
    print_colored "Homebrew installé avec succès." "success"
    # Ajout de l'environnement Homebrew au .zshrc de l'utilisateur réel
    sudo -u $REAL_USER bash -c "echo 'eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"' >> $REAL_HOME/.zshrc"
fi

# Installation de Gum
print_colored "Installation de Gum..." "info"
# Utilisation de l'installation Homebrew de l'utilisateur réel
sudo -u $REAL_USER /home/linuxbrew/.linuxbrew/bin/brew install gum
if [ $? -ne 0 ]; then
    print_colored "Échec de l'installation de Gum." "danger"
    exit 1
else
    print_colored "Gum installé avec succès." "success"
fi

print_colored "Installation des prérequis terminée." "success"
print_colored "Veuillez redémarrer votre terminal ou exécuter 'source $REAL_HOME/.zshrc' pour appliquer les changements." "info"
print_colored "Vous pourrez ensuite exécuter le script d'installation des modules et outils essentiels." "info"

# Fin du script d'installation des prérequis
#****************