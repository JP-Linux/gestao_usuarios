#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Configurações
declare -r SYSLOG_TAG="ferramenta-admin"
declare -A COR=(
    [reset]="\033[0m"
    [vermelho]="\033[0;31m"
    [verde]="\033[0;32m"
    [amarelo]="\033[0;33m"
    [azul]="\033[0;34m"
)

# Dependências
declare -a COMANDOS_NECESSARIOS=("getent" "useradd" "groupadd" "usermod" "deluser" "delgroup")
declare -A UI_COMANDO=(
    ['dialog']="dialog --clear --backtitle 'Gestão de Usuários/Grupos'"
    ['whiptail']="whiptail --clear --backtitle 'Gestão de Usuários/Grupos'"
)

principal() {
    verificar_dependencias
    iniciar_ui
    menu_principal
}

verificar_dependencias() {
    local comando faltando=()
    for comando in "${COMANDOS_NECESSARIOS[@]}"; do
        if ! command -v "$comando" >/dev/null 2>&1; then
            faltando+=("$comando")
        fi
    done
    ((${#faltando[@]})) && {
        log_erro "Faltam comandos essenciais: ${faltando[*]}"
        exit 1
    }
    return 0
}

iniciar_ui() {
    for ui in "${!UI_COMANDO[@]}"; do
        if command -v "$ui" >/dev/null 2>&1; then
            declare -g UI="${UI_COMANDO[$ui]}"
            return
        fi
    done
    UI="cli"
}

menu_principal() {
    while true; do
        case $(obter_selecao "Menu Principal" "Gerenciar Usuários;Gerenciar Grupos;Sair") in
            "Gerenciar Usuários") gerenciar_usuarios ;;
            "Gerenciar Grupos") gerenciar_grupos ;;
            *) exit 0 ;;
        esac
    done
}

gerenciar_usuarios() {
    local acao
    acao=$(obter_selecao "Gerenciamento de Usuários" \
        "Criar Usuário;Excluir Usuário;Modificar Usuário;Listar Usuários;Voltar")
    
    case $acao in
        "Criar Usuário") criar_usuario ;;
        "Excluir Usuário") excluir_usuario ;;
        "Modificar Usuário") modificar_usuario ;;
        "Listar Usuários") listar_usuarios ;;
    esac
}

gerenciar_grupos() {
    local acao
    acao=$(obter_selecao "Gerenciamento de Grupos" \
        "Criar Grupo;Excluir Grupo;Listar Grupos;Voltar")
    
    case $acao in
        "Criar Grupo") criar_grupo ;;
        "Excluir Grupo") excluir_grupo ;;
        "Listar Grupos") listar_grupos ;;
    esac
}

criar_usuario() {
    local usuario grupos grupo_primario senha
    usuario=$(obter_entrada "Digite o nome do usuário: " "Novo Usuário")
    [[ -z "$usuario" ]] && return
    
    if getent passwd "$usuario" >/dev/null; then
        mostrar_mensagem "Usuário '$usuario' já existe!" "erro"
        return
    fi

    grupo_primario=$(selecionar_grupo "Selecione o grupo primário:")
    [[ -z "$grupo_primario" ]] && grupo_primario="$usuario" && criar_grupo "$usuario"

    grupos=$(selecionar_multiplos_grupos "Selecione grupos secundários (espaço para selecionar):")
    
    senha=$(definir_senha "$usuario")
    [[ -z "$senha" ]] && return

    if ! useradd -m -g "$grupo_primario" -G "$grupos" -s "/bin/bash" "$usuario"; then
        log_erro "Falha ao criar usuário $usuario"
        exit 1
    fi

    echo "$usuario:$senha" | chpasswd
    configurar_home_dir "$usuario" "$grupo_primario"
    
    log_syslog "Usuário criado: $usuario (grupos: $grupo_primario,$grupos)"
    mostrar_mensagem "Usuário $usuario criado com sucesso" "sucesso"
}

configurar_home_dir() {
    local usuario="$1" grupo="$2"
    chmod 750 "/home/$usuario"
    chown "$usuario":"$grupo" "/home/$usuario"
    setfacl -m "g:$grupo:r-x" "/home/$usuario"
}

excluir_usuario() {
    local usuarios=() usuario
    mapfile -t usuarios < <(getent passwd | cut -d: -f1 | sort)
    usuario=$(selecionar_item "Selecione o usuário para excluir:" "${usuarios[@]}")
    [[ -z "$usuario" ]] && return

    if ! deluser --remove-home "$usuario"; then
        log_erro "Falha ao excluir usuário $usuario"
        exit 1
    fi
    
    log_syslog "Usuário excluído: $usuario"
    mostrar_mensagem "Usuário $usuario excluído" "info"
}

modificar_usuario() {
    local usuario grupos grupos_atual novos_grupos
    usuario=$(selecionar_usuario)
    [[ -z "$usuario" ]] && return

    grupos_atual=$(id -Gn "$usuario" | tr ' ' ',')
    novos_grupos=$(selecionar_multiplos_grupos "Selecione novos grupos (atuais: $grupos_atual):")
    
    if usermod -G "$novos_grupos" "$usuario"; then
        log_syslog "Usuário $usuario modificado - grupos: $novos_grupos"
        mostrar_mensagem "Usuário $usuario atualizado" "sucesso"
    else
        log_erro "Falha ao modificar usuário $usuario"
    fi
}

criar_grupo() {
    local grupo
    grupo=$(obter_entrada "Digite o nome do grupo: " "Criar Grupo")
    [[ -z "$grupo" ]] && return

    if groupadd "$grupo"; then
        log_syslog "Grupo criado: $grupo"
        mostrar_mensagem "Grupo $grupo criado" "sucesso"
    else
        log_erro "Falha ao criar grupo $grupo"
    fi
}

excluir_grupo() {
    local grupos=() grupo
    mapfile -t grupos < <(getent group | cut -d: -f1 | sort)
    grupo=$(selecionar_item "Selecione o grupo para excluir:" "${grupos[@]}")
    [[ -z "$grupo" ]] && return

    if ! delgroup "$grupo"; then
        log_erro "Falha ao excluir grupo $grupo"
        exit 1
    fi
    
    log_syslog "Grupo excluído: $grupo"
    mostrar_mensagem "Grupo $grupo excluído" "info"
}

# Funções auxiliares e UI
selecionar_grupo() {
    local grupos=() mensagem="$1"
    mapfile -t grupos < <(getent group | cut -d: -f1 | sort)
    selecionar_item "$mensagem" "${grupos[@]}" "Criar Novo Grupo"
}

selecionar_multiplos_grupos() {
    local grupos=() selecionados=()
    mapfile -t grupos < <(getent group | cut -d: -f1 | sort)
    selecionar_multiplos_itens "$1" "${grupos[@]}" | tr '\n' ',' | sed 's/,$//'
}

definir_senha() {
    local senha1 senha2
    while :; do
        senha1=$(obter_entrada_segura "Digite a senha para $1: ")
        senha2=$(obter_entrada_segura "Digite novamente a senha: ")
        [[ "$senha1" == "$senha2" ]] && break
        mostrar_mensagem "As senhas não coincidem!" "erro"
    done
    echo -n "$senha1"
}

# Sistema de UI adaptativo
obter_selecao() {
    local titulo="$1" opcoes=() i=0
    shift
    for opt; do opcoes+=("$i" "$opt"); ((i++)); done
    
    if [[ "$UI" != "cli" ]]; then
        eval "$UI --title '$titulo' --menu 'Escolha uma opção:' 15 40 $((i)) ${opcoes[*]}" 3>&1 1>&2 2>&3
    else
        echo "$titulo" >&2
        PS3="Selecione uma opção: "
        select opt in "$@"; do [[ -n "$opt" ]] && echo "$opt" && break; done
    fi
}

selecionar_item() {
    local mensagem="$1" itens=() i=0
    shift
    for item; do itens+=("$i" "$item"); ((i++)); done
    
    if [[ "$UI" != "cli" ]]; then
        eval "$UI --title 'Seleção' --menu '$mensagem' 20 50 $((i)) ${itens[*]}" 3>&1 1>&2 2>&3
    else
        echo "$mensagem" >&2
        PS3="Escolha: "
        select opt in "$@"; do [[ -n "$opt" ]] && echo "$opt" && break; done
    fi
}

# Logging e utilitários
log_erro() { echo -e "${COR[vermelho]}[ERRO] $* ${COR[reset]}" >&2; logger -t "$SYSLOG_TAG" "ERRO: $*"; }
log_syslog() { logger -t "$SYSLOG_TAG" "$*"; }
mostrar_mensagem() { 
    case "$2" in
        "erro") cor=${COR[vermelho]} ;;
        "sucesso") cor=${COR[verde]} ;;
        *) cor=${COR[azul]} ;;
    esac
    echo -e "${cor}$1${COR[reset]}" >&2
    sleep 1
}

principal "$@"
