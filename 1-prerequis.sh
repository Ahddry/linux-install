#!/bin/bash

# Script principal d'installation des prérequis
# Orchestre l'exécution des scripts système et utilisateur

# ***************
# Utils - Fonctions utilitaires
# ***************

# Fonction pour afficher un message coloré dans le terminal
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

print_colored "Installation des prérequis Linux" "info"
print_colored "Ce script va installer tous les prérequis nécessaires en deux étapes :" ""
print_colored "1. Installation des paquets système (avec sudo)" "info"
print_colored "2. Configuration utilisateur (sans sudo)" "info"
echo

# Étape 1 : Installation des paquets système
print_colored "ÉTAPE 1: Installation des paquets système" "info"
print_colored "Exécution de 1-prerequis/system.sh avec sudo..." "info"

sudo ./1-prerequis/system.sh
if [ $? -ne 0 ]; then
    print_colored "Erreur lors de l'installation des paquets système." "danger"
    exit 1
fi

echo
print_colored "ÉTAPE 2: Configuration utilisateur" "info"
print_colored "Exécution de 1-prerequis/user.sh (sans sudo)..." "info"

# Étape 2 : Configuration utilisateur
./1-prerequis/user.sh
if [ $? -ne 0 ]; then
    print_colored "Erreur lors de la configuration utilisateur." "danger"
    exit 1
fi

echo
print_colored "INSTALLATION TERMINÉE" "success"
print_colored "Tous les prérequis ont été installés avec succès !" "success"
print_colored "Redémarrez votre terminal ou exécutez 'source ~/.zshrc' pour appliquer les changements." "info"
