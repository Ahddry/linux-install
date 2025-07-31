#!/bin/bash

# Script installant les prérequis système (nécessite sudo)
# À exécuter AVANT 1-prerequis-user.sh

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

# Vérification que le script est exécuté avec sudo
if [ "$EUID" -ne 0 ]; then
    print_colored "Ce script doit être exécuté avec sudo" "danger"
    print_colored "Usage: sudo ./1-prerequis-system.sh" "info"
    exit 1
fi

APT_GET_DIR=$(which apt-get)

#****************
# Vérification de la compatibilité
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
# Installation des paquets système requis :
# - Git
# - Curl
# - Wget
# - Unzip
# - Python3
# - Python3-pip
# - ZSH
#****************

print_colored "Mise à jour de la liste des paquets..." "info"
apt-get update

print_colored "Installation des paquets système requis..." ""
print_colored "Installation de git, curl, wget, unzip, python3, python3-pip et zsh..." "info"

apt-get install -y git curl wget unzip python3 python3-pip zsh > /dev/null
if [ $? -ne 0 ]; then
    print_colored "Échec de l'installation des paquets requis." "danger"
    exit 1
else
    print_colored "Paquets système installés avec succès." "success"
fi

print_colored "Installation des prérequis système terminée." "success"
print_colored "Vous pouvez maintenant exécuter ./1-prerequis-user.sh SANS sudo" "info"

# Fin du script d'installation des prérequis système
#****************
