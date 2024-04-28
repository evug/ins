#!/bin/bash
set -euxo pipefail

function update_sourcelist() {
  local slist_file=$(ls -t /etc/apt/sources.list.d/ | head -n 1)
  sudo apt-get update -o Dir::Etc::sourcelist="sources.list.d/$slist_file" \
  -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
}

function install_help() { #HELP Display this message:\nBOCKER help
  sed -n "s/^.*#HELP\\s//p;" < "$1" | sed "s/\\\\n/\n\t/g;s/$/\n/;s!BOCKER!${1/!/\\!}!g"
}

function install_androidsdk() { #HELP Display this message:\nBOCKER androidsdk
  # https://developer.android.com/studio/index.html
  echo "Installing Adndroid SDK"
  url='https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip'
  [ -d /opt/android ] && sudo rm -rf /opt/android/* || sudo mkdir -p /opt/android
  local tmp_zip="$(mktemp)"
  wget --show-progress "$url" -qO "$tmp_zip"
  sudo unzip -o "$tmp_zip" -d /opt/android
  sudo mkdir -p /opt/android/cmdline-tools/latest
  sudo mv $(ls /opt/android/cmdline-tools/ | grep -v latest) /opt/android/cmdline-tools/latest
  if ! grep -q ANDROID_HOME ~/.bashrc ;then
    { echo 'export ANDROID_HOME=/opt/android #Android'
      echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin #Android'
      echo 'export ANDROID_SDK_ROOT=$ANDROID_HOME/cmdline-tools #Android'
    } >> ~/.bashrc
    echo 'ANDROID_HOME added to PATH'
  fi
}

function install_awscli() { #HELP Display this message:\nBOCKER awscli
  echo "Installing AWSCli v2"
  local tmp_dir="$(mktemp -d)"
  local src_url='https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip'
  wget --show-progress "$src_url" -O "$tmp_dir/awscliv2.zip"
  # curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip "$tmp_dir/awscliv2.zip"
  sudo "$tmp_dir/aws/install"
  rm "$tmp_dir"
}

function install_code() { #HELP Install Code:\nBOCKER code
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
  sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
  rm -f packages.microsoft.gpg
}

function install_codium() { #HELP Install Codium:\nBOCKER codium
  wget -qO- https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
  | gpg --yes --dearmor --output /usr/share/keyrings/vscodium-archive-keyring.gpg
  echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
  | sudo tee /etc/apt/sources.list.d/vscodium.list
  update_sourcelist
  sudo apt install codium
}

function install_chrome() { #HELP Install Google Chrome:\nBOCKER chrome
  wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub \
  | gpg --dearmor \
  | sudo dd of=/usr/share/keyrings/google-chrome-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
  | sudo tee /etc/apt/sources.list.d/google-chrome.list
  update_sourcelist
  sudo apt install google-chrome-stable
}
function install_firefox() { #HELP Install Firefox:\nBOCKER firefox
  sudo snap remove firefox || true
  sudo add-apt-repository ppa:mozillateam/ppa
  echo '
  Package: *
  Pin: release o=LP-PPA-mozillateam
  Pin-Priority: 1001
  ' | sudo tee /etc/apt/preferences.d/mozilla-firefox
  echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' \
  | sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
  update_sourcelist
  sudo apt install firefox
}
function install_gcpsdk() { #HELP Install GCP SDK:\nBOCKER gcpsdk
  echo "deb [ signed-by=/usr/share/keyrings/cloud.google.gpg ] https://packages.cloud.google.com/apt cloud-sdk main" \
  | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
  if [ "$(lsb_release -r | tr -d '.' | cut -f2)" -le  "2110" ]
    then
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    else 
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | sudo tee /usr/share/keyrings/cloud.google.gpg
  fi
  update_sourcelist
  sudo apt install google-cloud-cli kubeclt
  sudo sh -c 'kubectl completion bash >/etc/bash_completion.d/kubectl'
  if [ ! grep -q __start_kubectl ~/.bashrc ];then
    echo 'complete -F __start_kubectl k' >>~/.bashrc 
    echo autocomplition for k added
  fi
}

function install_gh() { #HELP Install GitHub Cli:\nBOCKER gh
  type -p curl >/dev/null || sudo apt install curl -y
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"\
  | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  update_sourcelist
  sudo apt install gh
}

function install_golang() { #HELP Install Golang:\nBOCKER golang
  local url=$(wget --show-progress -qO- https://golang.org/dl/ | grep -oP '\/dl\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -1 )
  local version=$(echo $url | grep -Po '(?<=go)\d+.\d+.?\d+')
  if type go 1>/dev/null;then
    local installed=$(go version | grep -Po '\d+.\d+.?\d+')
    if [ "$version" = "$installed" ]; then
      echo "There\'s no need to update"
      exit 0
    fi
  fi
  echo "Installing Golang $version"
  if [ -d /opt/go ];then
    sudo rm -rf /opt/go
  else
    sudo ln -fs /opt/go/bin/go /usr/local/bin/go
    sudo ln -fs /opt/go/bin/gofmt /usr/local/bin/gofmt
  fi

  sudo wget --show-progress -qO- "https://golang.org$url" | sudo tar xz -C /opt
  mkdir -p "$HOME/go/{bin,pkg,src}"

  if ! grep -q GOPATH ~/.bashrc ;then
    { echo 'export GOPATH=$HOME/go #GoLang'
      echo 'export PATH=$PATH:/opt/go/bin:$GOPATH/bin #GoLang'
    } >> ~/.bashrc
    echo 'GOPATH added to PATH'
  fi
  go version
}

function install_java() { #HELP Install Oracle Java 17:\nBOCKER java
  [ -d /opt/java ] && sudo rm -rf /opt/java/* || sudo mkdir -p /opt/java
  local url='https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz'
  sudo wget --show-progress -O- $url | sudo tar xz -C /opt/java --strip-components 1
  # update-alternatives --install /usr/bin/java java /opt/java/bin/java 2000
  if ! grep -q JAVA_HOME ~/.bashrc ;then
    { echo 'export JAVA_HOME=/opt/java #Java'
      echo 'export PATH=$PATH:$JAVA_HOME/bin #Java'
    } >> ~/.bashrc
    echo 'JAVA_HOME added to PATH'
  fi
  java --version
}

function install_k9s() { #HELP Install k9s:\nBOCKER k9s
  local url="$(wget --show-progress -qO- https://github.com/derailed/k9s/releases \
  | grep -oP '\/derailed\/k9s\/releases\/download\/v([0-9\.]+)\/k9s_Linux_amd64\.tar\.gz' \
  | head -1 )"
  local last_version=$(echo $url | grep -Po '(?<=download\/v)\d+.\d+.\d+')
  if type k9s >/dev/null;then
    local installed_version=$(k9s version -s | head -1 | awk '{print $2}') 
    if [ "$last_version" = "$installed_version" ];then
      echo Do not need to update, last version $last_version installed
      exit 0
    fi
  fi
  echo k9s $last_version available
  sudo wget --show-progress -qO- "https://github.com/$url" \
  | sudo tar xz -C /usr/local/bin/ --no-same-owner --wildcards --no-anchored 'k9s'
  k9s version
}

function install_podman() { #HELP Install Podman:\nBOCKER podman
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/xUbuntu_$(lsb_release -rs)/Release.key \
  | sudo gpg --yes --dearmor --output /etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg]\
  https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/xUbuntu_$(lsb_release -rs)/ /" \
  | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:unstable.list > /dev/null
  update_sourcelist
  sudo apt install podman
}

function install_terraform() { #HELP Install Terraform:\nBOCKER terraform
  local src_url=$(wget --show-progress -qO- https://www.terraform.io/downloads.html \
  | grep -oP 'https:\/\/releases\.hashicorp\.com\/terraform\/([0-9\.]+)\/terraform_([0-9\.]+)_linux_amd64\.zip'\
  | head -1 )
  local version=$(echo $src_url | grep -Po '(?<=terraform\/)\d+.\d+.?\d+')
  if type terraform 1>/dev/null;then
    local installed_version=$(terraform --version | grep -Po '\d+.\d+.?\d+')
    if [ "$version" = "$installed_version" ]; then
      echo "There\'s no need to update"
      exit 0
    fi
  fi
  echo "Installing Terraform $version"
  local tmp_zip="$(mktemp)"
  wget --show-progress "$src_url" -O "$tmp_zip"
  sudo unzip -o $tmp_zip -d /opt
  sudo ln -s /opt/terraform /usr/local/bin/terraform || true
  rm $tmp_zip
  terraform --version
}

function install_zoom() { #HELP Install Zoom:\nBOCKER zoom
  local tmp_deb="$(mktemp)"
  local src_url="https://zoom.us/client/latest/zoom_amd64.deb"
  local args=${@:2}
  pkill zoom || true
  wget --show-progress -O $tmp_deb $src_url &&
  sudo dpkg -i $tmp_deb $args &&
  { rm -f $tmp_deb; true; } || 
  { rm -f $tmp_deb; false; }   # commands above failed, remove tmp file anyway
}

function install_misc() { #HELP Install small things:\nBOCKER misc
  sudo apt install apt-transport-https curl gnupg ca-certificates bash-completion git
}

function install_qbittorrent() { #HELP Display this message:\nBOCKER qbittorrent
  sudo apt install qbittorrent-nox
  sudo adduser --home=/home/qb --system --group qbittorrent-nox
  sudo adduser $USER qbittorrent-nox
  echo '
[Unit]
Description=qBittorrent Command Line Client
After=network.target

[Service]
Type=forking
User=qbittorrent-nox
Group=qbittorrent-nox
UMask=007
ExecStart=/usr/bin/qbittorrent-nox -d --webui-port=8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
  '| sudo tee /etc/systemd/system/qbittorrent-nox.service 
  sudo systemctl enable qbittorrent-nox --now
}

function install_warp() { #HELP Install cloudflare:\nBOCKER warp
  curl https://pkg.cloudflareclient.com/pubkey.gpg \
  | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
  update_sourcelist
  sudo apt install cloudflare-warp
  warp-cli register
}

function install_all() { #HELP Install Everything here:\nBOCKER all
  install_misc
  install_androidsdk
  install_chrome
  install_code
  install_codium
  install_firefox
  install_gcpsdk
  install_gh
  install_golang
  install_java
  insatll_k9s
  install_podman
  install_terraform
  install_wrap
  install_zoom
  
  # VS Code plugins
  code --install-extension Dart-Code.flutter
  code --install-extension pkief.material-icon-theme
  code --install-extension formulahendry.code-runner
  code --install-extension rangav.vscode-thunder-client

  # Codium plugins
  codium --install-extension golang.go
  codium --install-extension pkief.material-icon-theme
  codium --install-extension formulahendry.code-runner
  codium --install-extension rangav.vscode-thunder-client
  
  # Install utils
  sudo add-apt-repository ppa:maveonair/helix-editor
  update_sourcelist
  sudo apt install git gnome-tweaks gnome-shell-extension-dash-to-panel \
  gnome-screenshot xclip wl-clipboard doublecmd-gtk jq mupdf keepassx \
  p7zip-full fzf helix
  
  # Video 
  sudo add-apt-repository ppa:obsproject/obs-studio
  update_sourcelist
  sudo apt install ffmpeg obs-studio
  
  # LF file manager
  curl -L https://github.com/gokcehan/lf/releases/latest/download/lf-linux-amd64.tar.gz | tar xzC ~/.local/bin
  echo '
  settings -> keyboard -> keyboard shortcuts -> Screenshots
  sh -c "gnome-screenshot -acf /tmp/test && cat /tmp/test | xclip -i -selection clipboard -target image/png"'

  # Gnome settigns
  gsettings set org.gnome.desktop.interface cursor-size 32
  gsettings set org.gnome.desktop.interface show-battery-percentage true
  gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Shift>Alt_L']"
  gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Alt>Shift_L']"
  gsettings set org.gnome.desktop.input-sources xkb-options "['caps:swapescape']"

  git config --global user.name $USER
  git config --global user.email johndoe@example.com
  git config --global core.editor "code --wait"
  git config --global pull.rebase true
  git config --global alias.review '!bash -c "git push origin HEAD:refs/for/$1" -'
  git config --global push.followTags true
  git config --global --add --bool rebase.updateRefs true
  git config --global --add --bool push.autoSetupRemote true
  git config --global url."ssh://git@github.com".insteadOf "https://github.com"

# Security
# sudo chmod 0750 ~
# sudo passwd root
# sudo apt install libpam-pwquality
# sudo ufw allow shh
# sudo ufw enable

# Remove snap
  sudo systemctl stop snapd && sudo systemctl disable snapd && sudo apt purge snapd gnome-software-plugin-snap
  sudo rm -rf ~/snap
  sudo rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd /usr/lib/snapd
  echo "# To install snapd, specify its version with 'apt install snapd=VERSION'
# where VERSION is the version of the snapd package you want to install.
Package: snapd
Pin: release a=*
Pin-Priority: -10" | sudo tee /etc/apt/preferences.d/nosnap.pref
}

[[ -z "${1-}" ]] && install_help "$0" && exit 1
case $1 in
  all|androidsdk|awscli|chrome|code|codium|firefox|golang|gcpsdk|gh|java|k9s|misc|podman\
  |terraform|qbittorrent|warp|zoom) install_"$1" "${@:2}" ;;
  *) install_help "$0" ;;
esac
