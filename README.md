# Scripts d'installation d'outils, de logiciels et de configuration d'environnement Linux

Il s'agit d'une série de scripts Bash conçus pour automatiser l'installation et la configuration d'outils et de logiciels essentiels sur les systèmes Linux afin de reproduire ma configuration habituelle.

Les scripts incluent des installations pour des outils de développement, des applications de productivité, des utilitaires système et bien plus encore. Ils sont conçus pour être exécutés sur des distributions basées sur Debian et Red Hat, et utilisent des gestionnaires de paquets tels que **APT** et **Homebrew**.

## 1. Prérequis (`1-prerequis.sh`)

### 1.1. Contenu

Ce premier script vérifie que le système est compatible avec les outils et logiciels à installer. Il installe également les différents éléments nécessaires aux autres scripts.

Il est divisé en 3 scripts Bash :

1. **1-prerequis.sh** : exécute les sous-scripts `system.sh` et `user.sh`.
2. **system.sh** : Vérifie la compatibilité du système puis installe `git`, `curl`, `wget`, `unzip`, `python3`, `python3-pip` et `zsh`.
3. **user.sh** : Configure `zsh` comme shell par défaut et installe le thème personnalisé `oh-my-posh`. Installe ensuite le gestionnaire de paquets `Homebrew` pour Linux ainsi que le paquet `Gum`, nécessaire au script suivant.

Tous ces scripts nécessitent que l'utilisateur dispose des droits **sudo** pour installer les paquets système et effectuer les configurations nécessaires.

### 1.2. Exécution

Pour exécuter le script principal, utilisez la commande suivante :

```bash
sudo bash 1-prerequis.sh
```

Une fois le script exécuté avec succès, redémarrer le terminal.

## 2. Essentiels (`2-essentiels.sh`)

### 2.1. Contenu

Ce script propose divers outils, logiciels, scripts utilitaires et configurations à installer au choix.

Les choix se font via des menus interactifs dans le terminal. Les installations s'effectuent de manière automatisée en arrière-plan via **APT**, **Homebrew**, **Pip** et **NPM**.

Ils se présentent sous 7 catégories :

1. Plugins ZSH et configuration .zshrc
    - Import de la configuration ZSH
    - Installation de plugins ZSH recommandés
2. Outils de développement
    - `GCC`
    - `Dotnet`
    - `OpenJDK`
    - `Go`
    - `Node.js` (+ `n` facultatif)
    - `Ruby`
    - `pipx`
    - `Docker` (seulement pour les environnements non WSL)
    - `Docker Compose` (seulement pour les environnements non WSL)
    - `Kubernetes` (seulement pour les environnements non WSL)
    - `MongoDB`
    - `SQLite`
3. Outils de sécurité
    - `semgrep`
    - `bearer`
    - `dependency-check`
    - `cdxgen`
    - `depscan`
    - `trivy`
    - `vault`
4. Outils cloud
    - `Azure CLI`
    - `AWS CLI`
    - `GCP CLI`
    - `Terraform`
5. Autres utilitaires
    - `fd` (better *find*)
    - `thefuck` (correction de la dernière commande)
    - `tldr` (man pages simplifiées)
    - `wtfis` (outil de recherche DNS et d'analyse de domaine)
6. Applications graphiques
    - `VSCode`
    - `Spotify`
    - `Firefox`
    - `VLC`
7. Scripts utilitaires
    - `add_dir_to_path` (ajoute un répertoire au PATH)
    - `semgrep-custom` (règles personnalisées pour Semgrep)

Certaines installations peuvent nécessiter les droits **sudo**.

### 2.2. Exécution

Pour exécuter le script, utilisez la commande suivante :

```bash
sudo bash 2-essentiels.sh
```
