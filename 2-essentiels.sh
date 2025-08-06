#!/bin/bash

# Script installant les modules et outils essentiels choisis par l'utilisateur

# ***************
# Utils - Fonctions utilitaires
# ***************

# Fonction pour les messages informatifs avec horodatage
log_info() {
    gum log --time kitchen --structured --level info "$1"
}

# Fonction pour les messages de debug
log_debug() {
    gum log --time kitchen --structured --level debug "$1"
}

# Fonction pour les erreurs
log_error() {
    gum log --time kitchen --structured --level error "$1"
}

# Fonction d'installation avec gestion d'erreur améliorée
install_with_brew() {
    local tool_name="$1"
    local package_name="$2"
    local extra_args="$3"

    log_info "Installation de $tool_name"

    # Vérification si déjà installé
    if $BREW_PATH list "$package_name" >/dev/null 2>&1; then
        log_debug "$tool_name déjà installé"
        return 0
    fi

    # Installation avec capture des erreurs
    local temp_log=$(mktemp)
    log_debug "Commande : $BREW_PATH install $extra_args $package_name"
    if $BREW_PATH install $extra_args "$package_name" 2>"$temp_log"; then
        log_debug "$tool_name installé avec succès"
        rm -f "$temp_log"
        return 0
    else
        log_error "Échec de l'installation de $tool_name"
        if [ -s "$temp_log" ]; then
            log_error "Détails de l'erreur : $(cat "$temp_log")"
        fi
        rm -f "$temp_log"
        return 1
    fi
}

# Fonction d'installation avec tap Homebrew (pour les packages nécessitant un tap spécial)
install_with_brew_tap() {
    local tool_name="$1"
    local tap_name="$2"
    local package_name="$3"
    local extra_args="$4"

    log_info "Installation de $tool_name"

    # Vérification si déjà installé
    if $BREW_PATH list "$package_name" >/dev/null 2>&1; then
        log_debug "$tool_name déjà installé"
        return 0
    fi

    # Ajout du tap si nécessaire
    local temp_log=$(mktemp)
    if ! $BREW_PATH tap | grep -q "^$tap_name$"; then
        log_debug "Ajout du tap $tap_name"
        if ! $BREW_PATH tap "$tap_name" 2>"$temp_log"; then
            log_error "Échec de l'ajout du tap $tap_name"
            if [ -s "$temp_log" ]; then
                log_error "Détails de l'erreur : $(cat "$temp_log")"
            fi
            rm -f "$temp_log"
            return 1
        fi
        log_debug "Tap $tap_name ajouté avec succès"
    fi

    # Installation avec capture des erreurs
    log_debug "Commande : $BREW_PATH install $extra_args $package_name"
    if $BREW_PATH install $extra_args "$package_name" 2>"$temp_log"; then
        log_debug "$tool_name installé avec succès"
        rm -f "$temp_log"
        return 0
    else
        log_error "Échec de l'installation de $tool_name"
        if [ -s "$temp_log" ]; then
            log_error "Détails de l'erreur : $(cat "$temp_log")"
        fi
        rm -f "$temp_log"
        return 1
    fi
}

# Fonction d'installation avec APT
install_with_apt() {
    local tool_name="$1"
    local package_name="$2"

    log_info "Installation de $tool_name"

    local temp_log=$(mktemp)
    if sudo apt-get install -y "$package_name" 2>"$temp_log"; then
        log_debug "$tool_name installé avec succès"
        rm -f "$temp_log"
        return 0
    else
        log_error "Échec de l'installation de $tool_name"
        if [ -s "$temp_log" ]; then
            log_error "Détails de l'erreur : $(cat "$temp_log")"
        fi
        rm -f "$temp_log"
        return 1
    fi
}
# Fonction pour les messages stylés (sans horodatage)
print_styled() {
    local color="$2"
    case "$color" in
        "green"|"success")
            gum style --foreground green --bold "$1"
            ;;
        "red"|"danger")
            gum style --foreground red --bold "$1"
            ;;
        "blue"|"info")
            gum style --foreground blue "$1"
            ;;
        "yellow"|"warning")
            gum style --foreground yellow "$1"
            ;;
        *)
            gum style "$1"
            ;;
    esac
}

show_help() {
    log_error "Argument invalide"
    print_styled "Vous pouvez passer l'option --cli pour afficher uniquement les paquets CLI" "info"
    exit 1
}

invalid_input(){
    log_error "Entrée invalide..."
}

# Vérification que gum est installé
if ! command -v gum &> /dev/null; then
    echo "Gum n'est pas installé. Veuillez d'abord exécuter ./1-prerequis.sh"
    exit 1
fi

# Variables globales
HAS_GUI=false
IS_WSL=false
BREW_PATH=""

# Variables pour stocker les sélections utilisateur
INSTALL_ZSH_CONFIG=false
INSTALL_ZSH_AUTOCOMPLETE=false
SELECTED_DEV_TOOLS=""
INSTALL_N=false
SELECTED_SECURITY_TOOLS=""
SELECTED_CLOUD_TOOLS=""
SELECTED_UTILITY_TOOLS=""
SELECTED_GUI_APPS=""
SELECTED_SCRIPT_TOOLS=""

# Détection du chemin Homebrew
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    BREW_PATH="/home/linuxbrew/.linuxbrew/bin/brew"
elif [ -d "$HOME/.linuxbrew" ]; then
    BREW_PATH="$HOME/.linuxbrew/bin/brew"
else
    log_error "Homebrew non trouvé. Impossible de continuer."
    exit 1
fi

# Vérification que Homebrew fonctionne
if ! $BREW_PATH --version >/dev/null 2>&1; then
    log_error "Homebrew non fonctionnel à $BREW_PATH"
    exit 1
fi

log_debug "Homebrew détecté à $BREW_PATH"

#****************
# Configuration initiale et questions préliminaires
#****************

print_styled "Configuration des outils essentiels " "blue"
echo

# Question 1 : Interface graphique
if gum confirm "Votre environnement dispose-t-il d'une interface graphique (bureau, gestionnaire de fenêtres) ?"; then
    HAS_GUI=true
    print_styled "Interface graphique détectée - les applications graphiques seront proposées" "green"
else
    HAS_GUI=false
    print_styled "Environnement en ligne de commande détecté" "blue"

    # Question 2 : WSL si pas d'interface graphique
    if gum confirm "Êtes-vous sur Windows Subsystem for Linux (WSL) ?"; then
        IS_WSL=true
        print_styled "Environnement WSL détecté - certaines options seront adaptées" "yellow"
    fi
fi

echo

#****************
# Phase 1 : Collecte des choix utilisateur
#****************

print_styled "PHASE 1 : Sélection des outils à installer" "blue"
echo

#****************
# 1. Plugins ZSH et configuration .zshrc
#****************

print_styled "1. Configuration ZSH et plugins" "blue"

if gum confirm "Souhaitez-vous importer la configuration ZSH avec les plugins recommandés ?"; then
    INSTALL_ZSH_CONFIG=true
    print_styled "✓ Configuration ZSH sélectionnée" "green"
    if gum confirm "Souhaitez-vous également installer zsh-autocomplete ?"; then
        INSTALL_ZSH_AUTOCOMPLETE=true
    fi
else
    print_styled "✗ Configuration ZSH ignorée" "yellow"
fi

echo

#****************
# 2. Outils de développement
#****************

print_styled "2. Outils de développement" "blue"

# Préparation de la liste des outils de développement
DEV_TOOLS=("gcc" "dotnet" "openJDK" "go" "NodeJS" "ruby" "pipx" "mongodb" "sqlite")

# Ajout conditionnel des outils Docker/Kubernetes
if [ "$IS_WSL" = false ]; then
    DEV_TOOLS+=("docker" "docker-compose" "Kubernetes")
fi

# Sélection des outils de développement
SELECTED_DEV_TOOLS=$(gum choose --no-limit --header "Sélectionnez les outils de développement à installer :" "${DEV_TOOLS[@]}")

if [ -n "$SELECTED_DEV_TOOLS" ]; then
    # Vérification spéciale pour NodeJS et n
    if echo "$SELECTED_DEV_TOOLS" | grep -q "NodeJS"; then
        if gum confirm "Souhaitez-vous également installer 'n' (gestionnaire de versions Node.js) ?"; then
            INSTALL_N=true
        fi
    fi
    print_styled "✓ Outils de développement sélectionnés : $(echo $SELECTED_DEV_TOOLS | tr '\n' ', ' | sed 's/,$//')" "green"
else
    print_styled "✗ Aucun outil de développement sélectionné" "yellow"
fi

echo

#****************
# 3. Outils de sécurité
#****************

print_styled "3. Outils de sécurité" "blue"

SECURITY_TOOLS=("semgrep" "bearer" "dependency-check" "cdxgen" "depscan" "trivy" "vault")
SELECTED_SECURITY_TOOLS=$(gum choose --no-limit --header "Sélectionnez les outils de sécurité à installer :" "${SECURITY_TOOLS[@]}")

if [ -n "$SELECTED_SECURITY_TOOLS" ]; then
    print_styled "✓ Outils de sécurité sélectionnés : $(echo $SELECTED_SECURITY_TOOLS | tr '\n' ', ' | sed 's/,$//')" "green"
else
    print_styled "✗ Aucun outil de sécurité sélectionné" "yellow"
fi

echo

#****************
# 4. Outils cloud
#****************

print_styled "4. Outils cloud" "blue"

CLOUD_TOOLS=("Azure CLI" "AWS CLI" "GCP CLI" "Terraform")
SELECTED_CLOUD_TOOLS=$(gum choose --no-limit --header "Sélectionnez les outils cloud à installer :" "${CLOUD_TOOLS[@]}")

if [ -n "$SELECTED_CLOUD_TOOLS" ]; then
    print_styled "✓ Outils cloud sélectionnés : $(echo $SELECTED_CLOUD_TOOLS | tr '\n' ', ' | sed 's/,$//')" "green"
else
    print_styled "✗ Aucun outil cloud sélectionné" "yellow"
fi

echo

#****************
# 5. Autres utilitaires
#****************

print_styled "5. Autres utilitaires" "blue"

UTILITY_TOOLS=("fd" "thefuck" "tldr" "wtfis")
SELECTED_UTILITY_TOOLS=$(gum choose --no-limit --header "Sélectionnez les utilitaires à installer :" "${UTILITY_TOOLS[@]}")

if [ -n "$SELECTED_UTILITY_TOOLS" ]; then
    print_styled "✓ Utilitaires sélectionnés : $(echo $SELECTED_UTILITY_TOOLS | tr '\n' ', ' | sed 's/,$//')" "green"
else
    print_styled "✗ Aucun utilitaire sélectionné" "yellow"
fi

echo

#****************
# 6. Applications graphiques (uniquement si interface graphique)
#****************

if [ "$HAS_GUI" = true ]; then
    print_styled "6. Applications graphiques" "blue"

    GUI_APPS=("VSCode" "Spotify" "Firefox" "VLC")
    SELECTED_GUI_APPS=$(gum choose --no-limit --header "Sélectionnez les applications graphiques à installer :" "${GUI_APPS[@]}")

    if [ -n "$SELECTED_GUI_APPS" ]; then
        print_styled "✓ Applications graphiques sélectionnées : $(echo $SELECTED_GUI_APPS | tr '\n' ', ' | sed 's/,$//')" "green"
    else
        print_styled "✗ Aucune application graphique sélectionnée" "yellow"
    fi

    echo
fi

#****************
# 7. Scripts utilitaires
#****************

print_styled "7. Scripts utilitaires" "blue"

# TODO: Ajouter d'autres scripts utilitaires selon les besoins futurs
SCRIPT_TOOLS=("add_dir_to_path")
SELECTED_SCRIPT_TOOLS=$(gum choose --no-limit --header "Sélectionnez les scripts utilitaires à installer :" "${SCRIPT_TOOLS[@]}")

if [ -n "$SELECTED_SCRIPT_TOOLS" ]; then
    print_styled "✓ Scripts utilitaires sélectionnés : $(echo $SELECTED_SCRIPT_TOOLS | tr '\n' ', ' | sed 's/,$//')" "green"
else
    print_styled "✗ Aucun script utilitaire sélectionné" "yellow"
fi

echo

#****************
# Phase 2 : Installation des outils sélectionnés
#****************

print_styled "PHASE 2 : Installation des outils sélectionnés" "blue"
print_styled "Les installations vont maintenant commencer. Cela peut prendre du temps..." "yellow"
echo

#****************
# Installation 1. Configuration ZSH
#****************

if [ "$INSTALL_ZSH_CONFIG" = true ]; then
    log_info "Début de l'installation de la configuration ZSH"

    # Installation des plugins via Homebrew
    install_with_brew "zoxide" "zoxide"
    install_with_brew "zsh-autosuggestions" "zsh-autosuggestions"
    install_with_brew "zsh-syntax-highlighting" "zsh-syntax-highlighting"
    if [ "$INSTALL_ZSH_AUTOCOMPLETE" = true ]; then
        install_with_brew "zsh-autocomplete" "zsh-autocomplete"
    fi

    # Sauvegarde et remplacement du .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        log_debug "Ancienne configuration sauvegardée"
    fi

    if [ -f "./zsh/.zshrc" ]; then
        cp "./zsh/.zshrc" "$HOME/.zshrc"
        log_info "Configuration ZSH importée avec succès"
    else
        log_error "Fichier de configuration ./zsh/.zshrc introuvable"
    fi

    print_styled "✓ Configuration ZSH terminée" "green"
    echo
fi

#****************
# Installation 2. Outils de développement
#****************

if [ -n "$SELECTED_DEV_TOOLS" ]; then
    log_info "Début de l'installation des outils de développement"

    # Installation de NodeJS en premier si sélectionné
    if echo "$SELECTED_DEV_TOOLS" | grep -q "NodeJS"; then
        log_info "Installation de NodeJS"
        if gum spin --spinner dot --title "Installation de NodeJS..." -- bash -c "curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs" 2>/dev/null; then
            log_debug "NodeJS installé avec succès"

            if [ "$INSTALL_N" = true ]; then
                log_info "Installation de n (gestionnaire de versions Node.js)"
                if gum spin --spinner dot --title "Installation de n..." -- sudo npm install -g n 2>/dev/null; then
                    log_debug "n installé avec succès"
                else
                    log_error "Échec de l'installation de n"
                fi
            fi
        else
            log_error "Échec de l'installation de NodeJS"
        fi
    fi

    # Installation des autres outils via Homebrew ou APT
    for tool in $SELECTED_DEV_TOOLS; do
        case $tool in
            "NodeJS")
                # Déjà installé ci-dessus
                ;;
            "gcc")
                install_with_apt "GCC" "build-essential"
                ;;
            "dotnet")
                log_info "Installation de .NET"
                local temp_log=$(mktemp)
                if gum spin --spinner dot --title "Installation de .NET..." -- bash -c "wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && sudo dpkg -i packages-microsoft-prod.deb && sudo apt-get update && sudo apt-get install -y dotnet-sdk-8.0" 2>"$temp_log"; then
                    log_debug ".NET installé avec succès"
                    rm -f packages-microsoft-prod.deb
                else
                    log_error "Échec de l'installation de .NET"
                    if [ -s "$temp_log" ]; then
                        log_error "Détails de l'erreur : $(cat "$temp_log")"
                    fi
                fi
                rm -f "$temp_log"
                ;;
            "openJDK")
                install_with_apt "OpenJDK" "openjdk-17-jdk"
                ;;
            "go")
                install_with_brew "Go" "go"
                ;;
            "ruby")
                install_with_brew "Ruby" "ruby"
                ;;
            "pipx")
                log_info "Installation de pipx"
                local temp_log=$(mktemp)
                if gum spin --spinner dot --title "Installation de pipx..." -- pip3 install pipx 2>"$temp_log"; then
                    log_debug "pipx installé avec succès"
                    # Ajout au PATH
                    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
                        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
                        log_debug "pipx ajouté au PATH"
                    fi
                else
                    log_error "Échec de l'installation de pipx"
                    if [ -s "$temp_log" ]; then
                        log_error "Détails de l'erreur : $(cat "$temp_log")"
                    fi
                fi
                rm -f "$temp_log"
                ;;
            "docker")
                log_info "Installation de Docker"
                local temp_log=$(mktemp)
                log_debug "Téléchargement du script d'installation Docker..."
                if curl -fsSL https://get.docker.com -o get-docker.sh 2>"$temp_log"; then
                    log_debug "Exécution du script d'installation Docker..."
                    if sudo sh get-docker.sh >>"$temp_log" 2>&1; then
                        log_debug "Ajout de l'utilisateur au groupe docker..."
                        sudo usermod -aG docker "$USER"
                        log_debug "Docker installé avec succès"
                        log_debug "Utilisateur ajouté au groupe docker"
                        rm -f get-docker.sh
                    else
                        log_error "Échec de l'installation de Docker"
                        if [ -s "$temp_log" ]; then
                            log_error "Détails de l'erreur : $(cat "$temp_log")"
                        fi
                        rm -f get-docker.sh
                    fi
                else
                    log_error "Échec du téléchargement du script Docker"
                    if [ -s "$temp_log" ]; then
                        log_error "Détails de l'erreur : $(cat "$temp_log")"
                    fi
                fi
                rm -f "$temp_log"
                ;;
            "docker-compose")
                log_info "Installation de Docker Compose"
                local temp_log=$(mktemp)
                log_debug "Téléchargement de Docker Compose..."
                local COMPOSE_VERSION=$(git ls-remote https://github.com/docker/compose | grep refs/tags | grep -oE "[0-9]+\.[0-9][0-9]+\.[0-9]+$" | sort --version-sort | tail -n 1)
                if curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; then
                    sudo chmod +x /usr/local/bin/docker-compose
                    sudo sh -c "curl -L https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose"
                else
                    log_error "Échec de l'installation de Docker Compose"
                    if [ -s "$temp_log" ]; then
                        log_error "Détails de l'erreur : $(cat "$temp_log")"
                    fi
                fi
                rm -f "$temp_log"
                ;;
            "Kubernetes")
                install_with_brew "kubectl" "kubectl"
                ;;
            "mongodb")
                log_info "Installation de MongoDB"
                local temp_log=$(mktemp)
                if gum spin --spinner dot --title "Installation de MongoDB..." -- bash -c "wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add - && echo 'deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse' | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list && sudo apt-get update && sudo apt-get install -y mongodb-org" 2>"$temp_log"; then
                    log_debug "MongoDB installé avec succès"
                else
                    log_error "Échec de l'installation de MongoDB"
                    if [ -s "$temp_log" ]; then
                        log_error "Détails de l'erreur : $(cat "$temp_log")"
                    fi
                fi
                rm -f "$temp_log"
                ;;
            "sqlite")
                install_with_apt "SQLite" "sqlite3 libsqlite3-dev"
                ;;
            *)
                install_with_brew "$tool" "$tool"
                ;;
        esac
    done

    print_styled "✓ Outils de développement installés" "green"
    echo
fi

#****************
# Installation 3. Outils de sécurité
#****************

if [ -n "$SELECTED_SECURITY_TOOLS" ]; then
    log_info "Début de l'installation des outils de sécurité"

    for tool in $SELECTED_SECURITY_TOOLS; do
        case $tool in
            "semgrep")
                install_with_brew "Semgrep" "semgrep"
                ;;
            "bearer")
                install_with_brew_tap "Bearer" "bearer/tap" "bearer"
                ;;
            "dependency-check")
                install_with_brew "dependency-check" "dependency-check"
                ;;
            "cdxgen")
                install_with_brew_tap "cdxgen" "cyclonedx/cyclonedx" "cdxgen"
                ;;
            "depscan")
                log_info "Installation de depscan"
                local temp_log=$(mktemp)
                if gum spin --spinner dot --title "Installation de depscan..." -- pip3 install appthreat-depscan 2>"$temp_log"; then
                    log_debug "depscan installé avec succès"
                else
                    log_error "Échec de l'installation de depscan"
                    if [ -s "$temp_log" ]; then
                        log_error "Détails de l'erreur : $(cat "$temp_log")"
                    fi
                fi
                rm -f "$temp_log"
                ;;
            "trivy")
                install_with_brew "Trivy" "trivy"
                ;;
            "vault")
                install_with_brew "Vault" "vault"
                ;;
            *)
                install_with_brew "$tool" "$tool"
                ;;
        esac
    done

    print_styled "✓ Outils de sécurité installés" "green"
    echo
fi

#****************
# Installation 4. Outils cloud
#****************

if [ -n "$SELECTED_CLOUD_TOOLS" ]; then
    log_info "Début de l'installation des outils cloud"

    for tool in $SELECTED_CLOUD_TOOLS; do
        case $tool in
            "Azure CLI")
                log_info "Installation d'Azure CLI"
                if gum spin --spinner dot --title "Installation d'Azure CLI..." -- bash -c "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash" 2>/dev/null; then
                    log_debug "Azure CLI installé avec succès"
                else
                    log_error "Échec de l'installation d'Azure CLI"
                fi
                ;;
            "AWS CLI")
                log_info "Installation d'AWS CLI"
                local temp_log=$(mktemp)
                log_debug "Téléchargement d'AWS CLI..."
                if curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" 2>"$temp_log"; then
                    log_debug "Extraction d'AWS CLI..."
                    if unzip -q awscliv2.zip 2>>"$temp_log"; then
                        log_debug "Installation d'AWS CLI..."
                        if sudo ./aws/install 2>>"$temp_log"; then
                            log_debug "AWS CLI installé avec succès"
                            rm -rf aws awscliv2.zip
                        else
                            log_error "Échec de l'installation d'AWS CLI"
                            if [ -s "$temp_log" ]; then
                                log_error "Détails de l'erreur : $(cat "$temp_log")"
                            fi
                            rm -rf aws awscliv2.zip
                        fi
                    else
                        log_error "Échec de l'extraction d'AWS CLI"
                        if [ -s "$temp_log" ]; then
                            log_error "Détails de l'erreur : $(cat "$temp_log")"
                        fi
                        rm -f awscliv2.zip
                    fi
                else
                    log_error "Échec du téléchargement d'AWS CLI"
                    if [ -s "$temp_log" ]; then
                        log_error "Détails de l'erreur : $(cat "$temp_log")"
                    fi
                fi
                rm -f "$temp_log"
                ;;
            "GCP CLI")
                install_with_brew "GCP CLI" "google-cloud-sdk"
                ;;
            "Terraform")
                install_with_brew "Terraform" "terraform"
                ;;
        esac
    done

    print_styled "✓ Outils cloud installés" "green"
    echo
fi

#****************
# Installation 5. Autres utilitaires
#****************

if [ -n "$SELECTED_UTILITY_TOOLS" ]; then
    log_info "Début de l'installation des utilitaires"

    for tool in $SELECTED_UTILITY_TOOLS; do
        if install_with_brew "$tool" "$tool"; then
            # Ajouts spéciaux au .zshrc
            case $tool in
                "thefuck")
                    if ! grep -q 'eval $(thefuck --alias)' "$HOME/.zshrc" 2>/dev/null; then
                        echo 'eval $(thefuck --alias)' >> "$HOME/.zshrc"
                        log_debug "Alias 'fuck' ajouté au .zshrc"
                    fi
                    ;;
            esac
        fi
    done

    print_styled "✓ Utilitaires installés" "green"
    echo
fi

#****************
# Installation 6. Applications graphiques
#****************

if [ "$HAS_GUI" = true ] && [ -n "$SELECTED_GUI_APPS" ]; then
    log_info "Début de l'installation des applications graphiques"

    for app in $SELECTED_GUI_APPS; do
        case $app in
            "VSCode")
                log_info "Installation de VSCode"
                if gum spin --spinner dot --title "Installation de VSCode..." -- $BREW_PATH install --cask visual-studio-code 2>/dev/null; then
                    log_debug "VSCode installé avec succès"
                else
                    log_error "Échec de l'installation de VSCode"
                fi
                ;;
            "Spotify")
                log_info "Installation de Spotify"
                if gum spin --spinner dot --title "Installation de Spotify..." -- $BREW_PATH install --cask spotify 2>/dev/null; then
                    log_debug "Spotify installé avec succès"
                else
                    log_error "Échec de l'installation de Spotify"
                fi
                ;;
            "Firefox")
                log_info "Installation de Firefox"
                if gum spin --spinner dot --title "Installation de Firefox..." -- $BREW_PATH install --cask firefox 2>/dev/null; then
                    log_debug "Firefox installé avec succès"
                else
                    log_error "Échec de l'installation de Firefox"
                fi
                ;;
            "VLC")
                log_info "Installation de VLC"
                if gum spin --spinner dot --title "Installation de VLC..." -- $BREW_PATH install --cask vlc 2>/dev/null; then
                    log_debug "VLC installé avec succès"
                else
                    log_error "Échec de l'installation de VLC"
                fi
                ;;
        esac
    done

    print_styled "✓ Applications graphiques installées" "green"
    echo
fi

#****************
# Installation 7. Scripts utilitaires
#****************

if [ -n "$SELECTED_SCRIPT_TOOLS" ]; then
    log_info "Début de l'installation des scripts utilitaires"

    # Création du répertoire bin utilisateur si nécessaire
    mkdir -p "$HOME/.local/bin"
    log_debug "Répertoire ~/.local/bin créé"

    for script in $SELECTED_SCRIPT_TOOLS; do
        if [ -f "./2-essentiels/scripts-bash/$script" ]; then
            cp "./2-essentiels/scripts-bash/$script" "$HOME/.local/bin/"
            chmod +x "$HOME/.local/bin/$script"
            log_info "Script $script installé dans ~/.local/bin"
            log_debug "Permissions d'exécution accordées à $script"
        else
            log_error "Script $script introuvable dans ./2-essentiels/scripts-bash/"
        fi
    done

    # Vérification que ~/.local/bin est dans le PATH
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
        log_debug "~/.local/bin ajouté au PATH dans .zshrc"
    fi

    print_styled "✓ Scripts utilitaires installés" "green"
    echo
fi

#****************
# Finalisation
#****************

print_styled "Installation terminée" "green"
print_styled "Tous les outils sélectionnés ont été installés !" "green"
print_styled "Redémarrez votre terminal ou exécutez 'source ~/.zshrc' pour appliquer tous les changements." "blue"

# Fin du script d'installation des outils essentiels
#****************

