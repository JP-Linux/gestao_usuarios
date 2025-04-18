# Ferramenta de Gestão de Usuários e Grupos para Linux

[![Licença MIT](https://img.shields.io/badge/Licença-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell_Script-%23121011.svg?logo=gnu-bash)](https://www.gnu.org/software/bash/)

Ferramenta interativa para gestão avançada de usuários e grupos em sistemas Linux com controle de acesso granular.

## 📑 Descrição

Solução profissional para administração de sistemas que permite:
- Criação/remoção dinâmica de usuários e grupos
- Controle de permissões com política de segurança rígida
- Interface adaptativa (CLI ou gráfica)
- Logging detalhado de operações

## ✨ Funcionalidades Principais

- **Gestão Interativa**
  - Menus hierárquicos com navegação intuitiva
  - Seleção múltipla de grupos
  - Criação de grupos durante operações de usuário

- **Segurança**
  - Configuração automática de permissões (750 + ACLs)
  - Proteção de diretórios home
  - Validação de senhas complexas

- **Multiplataforma**
  - Compatível com Dialog e Whiptail
  - Funciona em qualquer distro Linux moderna
  - Suporte a sistemas legacy e novos kernels

## 📋 Pré-requisitos

- Pacotes essenciais:
  ```bash
  sudo apt install dialog whiptail -y  # Debian/Ubuntu
  sudo dnf install dialog newt -y     # Fedora/CentOS
  ```
- Acesso sudo/root
- Bash 4.4+
- Sistemas baseados em systemd

## ⚙️ Instalação

```bash
git clone https://github.com/JP-Linux/gestao_usuarios.git
cd gestao_usuarios
chmod +x gestao_usuarios.sh
```

## 🚀 Como Usar

```bash
sudo ./gestao_usuarios.sh
```

**Fluxo principal:**
1. Escolha entre gerenciar usuários ou grupos
2. Siga os menus interativos
3. Operações são validadas em tempo real
4. Logs automáticos no syslog (`journalctl -t ferramenta-admin`)

## 🔒 Modelo de Segurança

- **Permissões:**
  - Diretórios home com chmod 750
  - Sticky bit habilitado
  - ACLs configuradas via `setfacl`

- **Políticas:**
  - Senhas armazenadas com criptografia SHA-512
  - Prevenção contra grupos vazios
  - Validação de nomes de usuários

## 🧠 Detalhes Técnicos

- **Logging:**
  - Registro de todas operações no syslog
  - Marcação temporal precisa
  - Rastreamento de alterações

- **UI Adaptativa:**
  ```mermaid
  graph TD
    A[Interface] --> B{Dialog instalado?}
    B -->|Sim| C[Usa Dialog]
    B -->|Não| D{Whiptail instalado?}
    D -->|Sim| E[Usa Whiptail]
    D -->|Não| F[CLI Padrão]
  ```

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie sua branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## 📜 Licença

Distribuído sob licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

## ✉️ Autor

**Jorge Paulo Santos**  
[![GitHub](https://img.shields.io/badge/GitHub-JP--Linux-blue)](https://github.com/JP-Linux)
[![Email](https://img.shields.io/badge/Email-jorgepsan7%40gmail.com-red)](mailto:jorgepsan7@gmail.com)

## ⚠️ Aviso

Use este script apenas em ambientes controlados. O autor não se responsabiliza por:
- Perda de dados
- Configurações incorretas
- Problemas de segurança em implantações inadequadas

Sempre teste em ambiente de desenvolvimento antes de usar em produção!
