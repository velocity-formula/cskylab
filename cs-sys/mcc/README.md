# mcc - Mission Control Center<!-- omit in toc -->

This machine runs a management host (Mission Control Center) on Ubuntu Server 20.04 LTS.

It is intended to host VS Code Remote Server and to be accessed with VS Code Remote via ssh.

[comment]: <> (**Functional description goes here**)

`mcc` is deployed from template Ubuntu server 20.04 Mission Control Center version 22-03-23.

- [Prerequisites](#prerequisites)
- [How-to guides](#how-to-guides)
  - [Inject & Deploy configuration](#inject--deploy-configuration)
    - [1. SSH Authentication and sudoers file](#1-ssh-authentication-and-sudoers-file)
    - [2. Network configuration](#2-network-configuration)
    - [3. Install packages, updates and configuration tasks](#3-install-packages-updates-and-configuration-tasks)
    - [4. Configuration tasks](#4-configuration-tasks)
    - [5. Connect and operate](#5-connect-and-operate)
  - [Utilities](#utilities)
    - [Passwords and secrets](#passwords-and-secrets)
- [Reference](#reference)
  - [Scripts](#scripts)
    - [cs-deploy](#cs-deploy)
    - [cs-inject](#cs-inject)
    - [cs-connect](#cs-connect)
    - [cs-helloworld](#cs-helloworld)
  - [Template values](#template-values)
- [License](#license)

---

## Prerequisites

- Physical or virtual machine up and running, with a clean installation of Ubuntu server 20.04.

- Package `openssh-server` must be installed to allow remote ssh connections.

## How-to guides

### Inject & Deploy configuration

To install and configure the machine, open a terminal from the machine configuration directory in the management repository, and perform the following configuration steps:

#### 1. SSH Authentication and sudoers file

```bash
# Run csinject.sh in [ssh-sudoers] execution mode
./csinject.sh -k
```

> **NOTE:** If IP address has not been previously set in cloud-init or net-config, use `-r IPaddress`
until network configuration files are deployed.

This step injects ssh key and sudoers file into the machine.

Required before other configuration options. Its purpose is to allow automated and passwordless logins by using ssh protocol.

If ssh key has not been injected before, you must provide the password for username `kos@mcc` twice:

- First one to install ssh key (ssh-copy-id).
- Second one to deploy the sudoers file.

#### 2. Network configuration

```bash
# Run csinject.sh to inject & deploy configuration in [net-config] deploy mode
./csinject.sh -d -m net-config
```

> **NOTE:** If IP address has not been previously set in cloud-init or net-config, use `-r IPaddress`
until network configuration files are deployed.

This step deploys network configuration files that allow the machine to operate with specific IP address and hostname. Cloud-init configuration will be disabled from the next start.

Reboot is recommended when finished.

#### 3. Install packages, updates and configuration tasks

```bash
# Run csinject.sh to inject & deploy configuration in [install] deploy mode
./csinject.sh -d -m install
```

This step performs:

- Package installation
- Updates
- Configuration files deployment
- Configuration tasks

Required to run at least once in order to complete proper configuration. Reboot is recommended when finished.

#### 4. Configuration tasks

```bash
# Run csinject.sh to inject & deploy configuration in [config] deploy mode (default)
./csinject.sh -d
```

When configuration needs to be changed, this mode redeploys all configuration files into the machine, executing again all configuration tasks.

#### 5. Connect and operate

```bash
# Run csconnect.sh to establish a ssh session with sudoer (admin) user
./csconnect.sh
```

To run scripts and operate from inside the machine, establish an ssh connection with administrator (sudoer) user name `kos@mcc`.

### Utilities

#### Passwords and secrets

Generate passwords and secrets with:

```bash
# Screen
echo $(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 16)

# File (without newline)
printf $(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 16) > RESTIC-PASS.txt
```

Change the parameter `head -c 16` according with the desired length of the secret.

## Reference

### Scripts

#### cs-deploy

```console
Purpose:
  Machine installation and configuration deployment.
  This script is usually called by csinject.sh when executing Inject & Deploy
  operations. Exceptionally, it can also be run manually from inside the machine.

Usage:
  sudo cs-deploy.sh [-m <execution_mode>] [-h] [-q]

Execution modes:
  -m  <execution_mode>  - Valid modes are:
  
      [net-config]      - Network configuration. (Reboot when finished).
      [install]         - Package installation, updates and configuration tasks (Reboot when finished).
      [config]          - Redeploy config files and perform configuration tasks (Default mode).

Options and arguments:  
  -h  Help
  -q  Quiet (Nonstop) execution.

Examples:
  # Deploy configuration in [net-config] mode:
    sudo cs-deploy.sh -m net-config

  # Deploy configuration in [install] mode:
    sudo cs-deploy.sh -m install

  # Deploy configuration in [config] mode:
    sudo cs-deploy.sh -m config
```

**Tasks performed:**

| ${execution_mode}  | Tasks                              | Block / Description                                                                                    |
| ------------------ | ---------------------------------- | ------------------------------------------------------------------------------------------------------ |
| [net-config]       |                                    | **Network configuration**                                                                              |
|                    | Deploy /etc/hostname               | Configuration file `hostname` must exist in setup directory.                                           |
|                    | Deploy /etc/hosts                  | Configuration file `hosts` must exist in setup directory.                                              |
|                    | Deploy /etc/netplan/01-netcfg.yaml | Configuration file `01-netcfg.yaml` must exist in setup directory.                                     |
|                    | Disable cloud-init                 | Flag that signals that cloud-init should not run.                                                      |
|                    | Change systemd-resolved            | Change configuration of file `/etc/resolv.conf`.                                                       |
|                    | Try Netplan configuration          | Execute `netplan try` to test new network configuration.                                               |
|                    | Reboot                             | Reboot with confirmation message.                                                                      |
| [install]          |                                    | **Install and update packages**                                                                        |
|                    | Update installed packages          | Update package repositories, perform `dist-upgrade` and `autoremove`                                   |
|                    | Generate locales                   | Deploy file `locale.gen` if present in setup directory and execute `locale-gen`.                       |
|                    | Install chrony time sync           | Chrony time synchronization (https://chrony.tuxfamily.org)                                             |
|                    | Install docker-ce                  | Install docker-ce from docker repository                                                               |
|                    | Install shfmt                      | Install shell formatter shfmt via snap                                                                 |
|                    | Install jq JSON processor          | Install jq command-line JSON processor                                                                 |
|                    | Install go                         | Install golang from download                                                                           |
|                    | Install direnv                     | Install direnv shell extension from project installation script                                        |
|                    | Install kubectl                    | Install kubectl according to version in `${k8s_version}` variable                                      |
|                    | Install helm                       | Install helm via snap                                                                                  |
|                    | Install tree                       | Install tree directory                                                                                 |
|                    | Install restic                     | Install restic via snap                                                                                |
|                    | Install MinIO Client               | Install MinIO client via wget                                                                          |
|                    | Install shellcheck                 | Install shellcheck via snap                                                                            |
|                    | Install kustomize                  | Install kustomize via snap                                                                             |
| [install] [config] |                                    | **Deploy config files and execute configuration tasks**                                                |
|                    | Set timezone                       | Set time zone from `time_zone` variable.                                                               |
|                    | Set locale                         | Set locale from `system_locale` variable.                                                              |
|                    | Set keyboard                       | Set keyboard layout from `system_keyboard` variable.                                                   |
|                    | Deploy sudoers file                | Deploy sudoers configuration file `domadminsudo` (Must be present in setup directory).                 |
|                    | Git profile configuration          | Deploy git configuration file `gitconfig` (Must be present in setup directory).                        |
|                    | UFW firewall configuration         | UFW enabled with ssh allowed.                                                                          |
|                    | Change local passwords             | If file `kos-pass`is present in setup directory. (Template `tpl-kos-pass` provided).                   |
|                    | Deploy ssh authorized_keys         | If file `authorized_keys`is present in setup directory. (Template `tpl-authorized_keys` provided).     |
|                    | Deploy ssh id_rsa keys             | If files `id_rsa` and `id_rsa.pub` are present in setup directory. (Templates `tpl-id_rsa*` provided). |
|                    | Generate id_rsa                    | If doesn't exist for root and sudoer user.                                                             |
|                    | Deploy ca-certificates             | If files with name pattern `ca-*.crt` are present.                                                     |
|                    | Deploy machine certificate         | If files with name pattern `hostname.crt` and `hostname.key`are present.                               |
|                    | Deploy crontab files               | If files with name pattern `cron-cs-*` are present in setup directory.                                 |
| [install]          |                                    | **Reboot after install**                                                                               |
|                    | Reboot                             | Reboot with confirmation message.                                                                      |

#### cs-inject

> **Note:** This script runs from the "DevOps Computer", opening a terminal from the machine configuration directory in the management repository,.

```console
Purpose:
  Inject & Deploy configuration files into remote machine.
  This script runs from the management (DevOps) computer, copying all configuration
  files to the remote machine, and calling the script 'cs-deploy.sh' to run from
  inside the remote machine if 'deploy' mode [-d] is selected.

Usage:
  ./csinject.sh [-k] [-i] [-d] [-m <deploy_mode>] [-u <sudo_username>] [-r <remote_machine>] [-h] [-q]

Execution modes:
  -k  [ssh-sudoers] - install ssh key and sudoers file into the machine. Required before other actions.
  -i  [inject]      - Inject only. Inject configuration files into the machine for manual deployment.
  -d  [deploy]      - Inject & Deploy configuration. Calls 'cs-deploy.sh' to run from inside the machine.

Options and arguments:  
  -m  <deploy_mode>       - Deploy mode passed to 'cs-deploy.sh'. Valid modes are:

      [net-config]        - Network configuration. (Reboot when finished).
      [install]           - Package installation, updates and configuration tasks (Reboot when finished).
      [config]            - Redeploy config files and perform configuration tasks (Default mode).
  
  -u  <sudo_username>     - Remote administrator (sudoer) user name (Default value).
  -r  <remote_machine>    - Machine hostname or IPAddress (Default value).
  -h  Help
  -q  Quiet (Nonstop) execution.

Examples:
  # Copy ssh key and sudoers file into the machine:
    ./csinject.sh -k

  # Inject & Deploy configuration in [net-config] mode:
    ./csinject.sh -dm net-config

  # Inject & Deploy configuration in [install] mode:
    ./csinject.sh -dm install

  # Inject & Deploy configuration in [config] mode (default):
    ./csinject.sh -d
```

**Tasks performed:**

| ${execution_mode} | Tasks                                     | Block / Description                                                                           |
| ----------------- | ----------------------------------------- | --------------------------------------------------------------------------------------------- |
| [ssh-sudoers]     |                                           | **Inject ssh key and sudoers file**                                                           |
|                   | Perform ssh-copy-id                       | Insert your public key to be authorized in ssh authentication.                                |
|                   | Deploy sudoers file                       | Deploy sudoers configuration file `domadminsudo` (Must be present in setup directory).        |
|                   |                                           |                                                                                               |
| [inject] [deploy] |                                           | **Copy config files and deploy scripts**                                                      |
|                   | Prepare setup directory in remote machine | Remove setup directory if exist and create empty new one with permissions.                    |
|                   | Inject configuration files                | SCP configuration files from configuration management into machine setup directory.           |
|                   | Deploy scripts to `/usr/local/sbin`       | Delete old `cs-*.sh` scripts inside `/usr/local/sbin` and copy new ones from setup directory. |
|                   |                                           |                                                                                               |
| [deploy]          |                                           | **Run cs-deploy from inside the machine**                                                     |
|                   | Execute `cs-deploy.sh` inside the machine | Run `cs-deploy.sh` script inside the machine in mode specified by `deploy-mode` variable`.    |
|                   |                                           |                                                                                               |

#### cs-connect

> **Note:** This script runs from the "DevOps Computer", opening a terminal from the machine configuration directory in the management repository,.

```console
Purpose:
  SSH remote connection.
  Use this script to remote login into the machine and establish a ssh session.

Usage:
  csconnect.sh [-u <sudo_username>] [-r <remote_machine>] [-h]

Options and arguments:  
  -u  <sudo_username>   - Remote user name (Default value).
  -r  <remote_machine>  - Machine hostname or IPAddress (Default value).
  -h  Help

Examples:
  # Connect to the machine with default values
    ./csconnect.sh

  # Connect to IPAddress with specific user
    ./csconnect.sh -u sudo_username -r 192.168.2.99
```

**Tasks performed:**

| Tasks                  | Description                               |
| ---------------------- | ----------------------------------------- |
| Perform ssh connection | Passwordless ssh connection with timeout. |

#### cs-helloworld

```console
Purpose:
  Sequential block script model.
  Use this script as a model or skeleton to write other configuration scripts.

Usage:
  sudo cs-helloworld.sh [-l] [-m <execution_mode>] [-n <name>] [-h] [-q]

Execution modes:
  -l  [list-status]     - List current status.
  -m  <execution_mode>  - Valid modes are:

      [install]         - Install.
      [remove]          - Remove.
      [update]          - Update and reconfigure.

Options and arguments:  
  -n <name>             - Name of the person to report status.
                          (Optional in list-status. Default value) 
  -h  Help
  -q  Quiet (Nonstop) execution.

Examples:
  # Mode "install":
    sudo cs-helloworld.sh -m install

  # Mode "remove":
    sudo cs-helloworld.sh -m remove

  # Mode "list-status":
    sudo cs-helloworld.sh -l

  # Mode "list-status" with special name to report:
    sudo cs-helloworld.sh -l -n Bond
```

**Tasks performed:**

| ${execution_mode}                         | Tasks                          | Block / Description                                      |
| ----------------------------------------- | ------------------------------ | -------------------------------------------------------- |
| [install]                                 |                                | **Install apps and services**                            |
|                                           | Task 1                         | Task 1 description as commented in code.                 |
|                                           | Task 2                         | Task 2 description as commented in code.                 |
|                                           | Task n                         | Task n description as commented in code.                 |
| [remove]                                  |                                | **Remove apps and services**                             |
|                                           | Task 1                         | Task 1 description as commented in code.                 |
|                                           | Task 2                         | Task 2 description as commented in code.                 |
|                                           | Task n                         | Task n description as commented in code.                 |
| [update] [install]                        |                                | **Update and reconfigure apps and services**             |
|                                           | Task 1                         | Task 1 description as commented in code.                 |
|                                           | Task 2                         | Task 2 description as commented in code.                 |
|                                           | Task n                         | Task n description as commented in code.                 |
| [list-status] [install] [update] [remove] |                                | **Display status information**                           |
|                                           | Display hostname and variables | Show hostame and content of variables used in the script |
|                                           | Display report message         | Display report message with "some surprise"              |

### Template values

The following table lists template configuration parameters and their specified values, when machine configuration files were created from the template:

| Parameter                    | Description                                 | Values                                                     |
| ---------------------------- | ------------------------------------------- | ---------------------------------------------------------- |
| `_tplname`                   | template name                               | `ubt2004srv-mcc`                                          |
| `_tpldescription`            | template description                        | `Ubuntu server 20.04 Mission Control Center`                                   |
| `_tplversion`                | template version                            | `22-03-23`                                       |
| `machine.hostname`           | hostname                                    | `mcc`                                  |
| `machine.domainname`         | domain name                                 | `cskylab.net`                                |
| `machine.localadminusername` | local admin username                        | `kos`                        |
| `machine.localadminpassword` | local admin password                        | `NoFear21`                        |
| `machine.timezone`           | timezone                                    | `UTC`                                  |
| `machine.networkinterface`   | main network interface name                 | `enp1s0`                          |
| `machine.ipaddress`          | main IP address                             | `192.168.80.5`                                 |
| `machine.netmask`            | netmask                                     | `24`                                   |
| `machine.gateway4`           | default gateway                             | `192.168.80.1`                                  |
| `machine.searchdomainnames`  | search domain names                         | `cskylab.net, ` |
| `machine.nameservers`        | name servers IP addresses                   | `192.168.80.1, `       |
| `machine.setupdir`           | inject directory for setup and config files | `/etc/csky-setup`                                  |
| `machine.systemlocale`       | language configuration                      | `C.UTF-8`                              |
| `machine.systemkeyboard`     | keyboard layout configuration               | `us`                            |

## License

Copyright © 2021 cSkyLab.com ™

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
