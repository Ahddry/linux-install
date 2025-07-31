#!/bin/bash

# Script installant les modules et outils essentiels choisis par l'utilisateur

# ***************
# Utils - Fonctions utilitaires
# ***************

# Fonction pour afficher un message coloré dans le terminal
# Utilisation : print_colored "message" "color" | "color" peut être "danger", "success", "debug", "info" ou vide pour aucune couleur
print_colored() {
    case "$2" in
        danger)
            gum log --time kitchen --structured --level error "DANGER: $1"
            ;;
        debug)
            gum log --time kitchen --structured --level debug "DEBUG: $1"
            ;;
        success)
            gum style --foreground green --bold "SUCCESS: $1"
            ;;
        info)
            gum log --time kitchen --structured --level info "INFO: $1"
            ;;
        *)
            echo "$1"
            ;;
    esac
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