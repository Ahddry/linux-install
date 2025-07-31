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

# Vérification que gum est installé
if ! command -v gum &> /dev/null; then
    print_colored "Gum n'est pas installé. Veuillez d'abord exécuter ./1-prerequis.sh" "danger"
    exit 1
fi

# Variables globales
HAS_GUI=false
IS_WSL=false
BREW_PATH=""

# Détection du chemin Homebrew
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    BREW_PATH="/home/linuxbrew/.linuxbrew/bin/brew"
elif [ -d "$HOME/.linuxbrew" ]; then
    BREW_PATH="$HOME/.linuxbrew/bin/brew"
else
    print_colored "Homebrew non trouvé. Certaines installations pourraient échouer." "danger"
fi

#****************
# Configuration initiale et questions préliminaires
#****************

print_colored "=== Configuration des outils essentiels ===" "info"
echo

# Question 1 : Interface graphique
if gum confirm "Votre environnement dispose-t-il d'une interface graphique (bureau, gestionnaire de fenêtres) ?"; then
    HAS_GUI=true
    print_colored "Interface graphique détectée - les applications graphiques seront proposées" "info"
else
    HAS_GUI=false
    print_colored "Environnement en ligne de commande détecté" "info"
    
    # Question 2 : WSL si pas d'interface graphique
    if gum confirm "Êtes-vous sur Windows Subsystem for Linux (WSL) ?"; then
        IS_WSL=true
        print_colored "Environnement WSL détecté - certaines options seront adaptées" "info"
    fi
fi

echo

#****************
# 1. Plugins ZSH et configuration .zshrc
#****************

print_colored "=== 1. Configuration ZSH et plugins ===" "info"

if gum confirm "Souhaitez-vous importer la configuration ZSH avec les plugins recommandés ?"; then
    print_colored "Installation des plugins ZSH..." "info"
    
    # Installation des plugins via Homebrew
    gum spin --spinner dot --title "Installation de zoxide..." -- $BREW_PATH install zoxide
    gum spin --spinner dot --title "Installation de zsh-autosuggestions..." -- $BREW_PATH install zsh-autosuggestions
    gum spin --spinner dot --title "Installation de zsh-syntax-highlighting..." -- $BREW_PATH install zsh-syntax-highlighting
    gum spin --spinner dot --title "Installation de zsh-autocomplete..." -- $BREW_PATH install zsh-autocomplete
    
    # Sauvegarde et remplacement du .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        print_colored "Ancienne configuration sauvegardée" "info"
    fi
    
    if [ -f "./zsh/.zshrc" ]; then
        cp "./zsh/.zshrc" "$HOME/.zshrc"
        print_colored "Configuration ZSH importée avec succès" "success"
    else
        print_colored "Fichier de configuration ./zsh/.zshrc introuvable" "danger"
    fi
else
    print_colored "Configuration ZSH ignorée" "info"
fi

echo

#****************
# 2. Outils de développement
#****************

print_colored "=== 2. Outils de développement ===" "info"

# Préparation de la liste des outils de développement
DEV_TOOLS=("gcc" "dotnet" "openJDK" "go" "NodeJS" "ruby" "pipx" "sqlite" "mongodb")

# Ajout conditionnel des outils Docker/Kubernetes
if [ "$IS_WSL" = false ]; then
    DEV_TOOLS+=("docker" "docker-compose" "Kubernetes")
fi

# Sélection des outils de développement
SELECTED_DEV_TOOLS=$(gum choose --no-limit --header "Sélectionnez les outils de développement à installer :" "${DEV_TOOLS[@]}")

if [ -n "$SELECTED_DEV_TOOLS" ]; then
    # Vérification spéciale pour NodeJS et n
    INSTALL_N=false
    if echo "$SELECTED_DEV_TOOLS" | grep -q "NodeJS"; then
        if gum confirm "Souhaitez-vous également installer 'n' (gestionnaire de versions Node.js) ?"; then
            INSTALL_N=true
        fi
    fi
    
    # Installation de NodeJS en premier si sélectionné
    if echo "$SELECTED_DEV_TOOLS" | grep -q "NodeJS"; then
        print_colored "Installation de NodeJS..." "info"
        gum spin --spinner dot --title "Installation de NodeJS..." -- curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs
        
        if [ "$INSTALL_N" = true ]; then
            gum spin --spinner dot --title "Installation de n..." -- sudo npm install -g n
        fi
    fi
    
    # Installation des autres outils via Homebrew
    for tool in $SELECTED_DEV_TOOLS; do
        case $tool in
            "NodeJS")
                # Déjà installé ci-dessus
                ;;
            "openJDK")
                gum spin --spinner dot --title "Installation d'OpenJDK..." -- $BREW_PATH install openjdk
                ;;
            "docker-compose")
                gum spin --spinner dot --title "Installation de docker-compose..." -- $BREW_PATH install docker-compose
                ;;
            "Kubernetes")
                gum spin --spinner dot --title "Installation de kubectl..." -- $BREW_PATH install kubectl
                ;;
            *)
                gum spin --spinner dot --title "Installation de $tool..." -- $BREW_PATH install $tool
                ;;
        esac
    done
    
    print_colored "Outils de développement installés" "success"
else
    print_colored "Aucun outil de développement sélectionné" "info"
fi

echo

#****************
# 3. Outils de sécurité
#****************

print_colored "=== 3. Outils de sécurité ===" "info"

SECURITY_TOOLS=("semgrep" "bearer" "dependency-check" "cdxgen" "depscan" "trivy" "vault")
SELECTED_SECURITY_TOOLS=$(gum choose --no-limit --header "Sélectionnez les outils de sécurité à installer :" "${SECURITY_TOOLS[@]}")

if [ -n "$SELECTED_SECURITY_TOOLS" ]; then
    for tool in $SELECTED_SECURITY_TOOLS; do
        case $tool in
            "semgrep")
                gum spin --spinner dot --title "Installation de Semgrep..." -- pip3 install semgrep
                ;;
            "dependency-check")
                gum spin --spinner dot --title "Installation de dependency-check..." -- $BREW_PATH install dependency-check
                ;;
            "cdxgen")
                gum spin --spinner dot --title "Installation de cdxgen..." -- npm install -g @cyclonedx/cdxgen
                ;;
            "depscan")
                gum spin --spinner dot --title "Installation de depscan..." -- pip3 install appthreat-depscan
                ;;
            *)
                gum spin --spinner dot --title "Installation de $tool..." -- $BREW_PATH install $tool
                ;;
        esac
    done
    
    print_colored "Outils de sécurité installés" "success"
else
    print_colored "Aucun outil de sécurité sélectionné" "info"
fi

echo

#****************
# 4. Outils cloud
#****************

print_colored "=== 4. Outils cloud ===" "info"

CLOUD_TOOLS=("Azure CLI" "AWS CLI" "GCP CLI" "Terraform")
SELECTED_CLOUD_TOOLS=$(gum choose --no-limit --header "Sélectionnez les outils cloud à installer :" "${CLOUD_TOOLS[@]}")

if [ -n "$SELECTED_CLOUD_TOOLS" ]; then
    for tool in $SELECTED_CLOUD_TOOLS; do
        case $tool in
            "Azure CLI")
                gum spin --spinner dot --title "Installation d'Azure CLI..." -- curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
                ;;
            "AWS CLI")
                gum spin --spinner dot --title "Installation d'AWS CLI..." -- $BREW_PATH install awscli
                ;;
            "GCP CLI")
                gum spin --spinner dot --title "Installation de GCP CLI..." -- $BREW_PATH install google-cloud-sdk
                ;;
            "Terraform")
                gum spin --spinner dot --title "Installation de Terraform..." -- $BREW_PATH install terraform
                ;;
        esac
    done
    
    print_colored "Outils cloud installés" "success"
else
    print_colored "Aucun outil cloud sélectionné" "info"
fi

echo

#****************
# 5. Autres utilitaires
#****************

print_colored "=== 5. Autres utilitaires ===" "info"

UTILITY_TOOLS=("fd" "thefuck" "tldr" "wtfis")
SELECTED_UTILITY_TOOLS=$(gum choose --no-limit --header "Sélectionnez les utilitaires à installer :" "${UTILITY_TOOLS[@]}")

if [ -n "$SELECTED_UTILITY_TOOLS" ]; then
    for tool in $SELECTED_UTILITY_TOOLS; do
        gum spin --spinner dot --title "Installation de $tool..." -- $BREW_PATH install $tool
        
        # Ajouts spéciaux au .zshrc
        case $tool in
            "thefuck")
                echo 'eval $(thefuck --alias)' >> "$HOME/.zshrc"
                print_colored "Alias 'fuck' ajouté au .zshrc" "info"
                ;;
        esac
    done
    
    print_colored "Utilitaires installés" "success"
else
    print_colored "Aucun utilitaire sélectionné" "info"
fi

echo

#****************
# 6. Applications graphiques (uniquement si interface graphique)
#****************

if [ "$HAS_GUI" = true ]; then
    print_colored "=== 6. Applications graphiques ===" "info"
    
    GUI_APPS=("VSCode" "Spotify" "Firefox" "VLC")
    SELECTED_GUI_APPS=$(gum choose --no-limit --header "Sélectionnez les applications graphiques à installer :" "${GUI_APPS[@]}")
    
    if [ -n "$SELECTED_GUI_APPS" ]; then
        for app in $SELECTED_GUI_APPS; do
            case $app in
                "VSCode")
                    gum spin --spinner dot --title "Installation de VSCode..." -- $BREW_PATH install --cask visual-studio-code
                    ;;
                "Spotify")
                    gum spin --spinner dot --title "Installation de Spotify..." -- $BREW_PATH install --cask spotify
                    ;;
                "Firefox")
                    gum spin --spinner dot --title "Installation de Firefox..." -- $BREW_PATH install --cask firefox
                    ;;
                "VLC")
                    gum spin --spinner dot --title "Installation de VLC..." -- $BREW_PATH install --cask vlc
                    ;;
            esac
        done
        
        print_colored "Applications graphiques installées" "success"
    else
        print_colored "Aucune application graphique sélectionnée" "info"
    fi
    
    echo
fi

#****************
# 7. Scripts utilitaires
#****************

print_colored "=== 7. Scripts utilitaires ===" "info"

# TODO: Ajouter d'autres scripts utilitaires selon les besoins futurs
SCRIPT_TOOLS=("add_dir_to_path")
SELECTED_SCRIPT_TOOLS=$(gum choose --no-limit --header "Sélectionnez les scripts utilitaires à installer :" "${SCRIPT_TOOLS[@]}")

if [ -n "$SELECTED_SCRIPT_TOOLS" ]; then
    # Création du répertoire bin utilisateur si nécessaire
    mkdir -p "$HOME/.local/bin"
    
    for script in $SELECTED_SCRIPT_TOOLS; do
        if [ -f "./2-essentiels/scripts-bash/$script" ]; then
            cp "./2-essentiels/scripts-bash/$script" "$HOME/.local/bin/"
            chmod +x "$HOME/.local/bin/$script"
            print_colored "Script $script installé dans ~/.local/bin" "success"
        else
            print_colored "Script $script introuvable dans ./2-essentiels/scripts-bash/" "danger"
        fi
    done
    
    # Vérification que ~/.local/bin est dans le PATH
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
        print_colored "~/.local/bin ajouté au PATH dans .zshrc" "info"
    fi
else
    print_colored "Aucun script utilitaire sélectionné" "info"
fi

echo

#****************
# Finalisation
#****************

print_colored "=== Installation terminée ===" "success"
print_colored "Tous les outils sélectionnés ont été installés !" "success"
print_colored "Redémarrez votre terminal ou exécutez 'source ~/.zshrc' pour appliquer tous les changements." "info"

# Fin du script d'installation des outils essentiels
#****************

