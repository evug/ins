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
	wget "$url" -O "$tmp_zip"
	sudo unzip -o "$tmp_zip" -d /opt/android
	sudo mkdir -p /opt/android/cmdline-tools/latest
	sudo mv $(ls /opt/android/cmdline-tools/ | grep -v latest) /opt/android/cmdline-tools/latest
	if ! grep -q ANDROID_HOME ~/.bashrc ;then
	  { echo 'export ANDROID_HOME=/opt/android #Android'
	    echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin #Android'
	    echo 'export ANDROID_SDK_ROOT=$ANDROID_HOME/cmdline-tools #Android'
	  } >> ~/.bashrc
	  echo 'ANDROID_HOME added to PATH'
	  source ~/.bashrc
	fi
}

function install_argocd() { #HELP Install ArgoCD:\nBOCKER argocd
	curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
	sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
	rm argocd-linux-amd64
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

function install_gcp() { #HELP Install GCP SDK:\nBOCKER gcp
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
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y
}

function install_golang() { #HELP Install Golang:\nBOCKER golang
	local URL=$(wget -qO- https://golang.org/dl/ | grep -oP '\/dl\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -1 )
	local VERSION=$(echo $URL | grep -Po '(?<=go)\d+.\d+.?\d+')
	if type go 1>/dev/null;then
	  local INSTALLED=$(go version | grep -Po '\d+.\d+.?\d+')
	  if [ "$VERSION" = "$INSTALLED" ]; then
	  echo "There\'s no need to update"
	  exit 0
	  fi
	fi
	echo "Installing Golang $VERSION"
	if [ -d /opt/go ];then
	  sudo rm -rf /opt/go
	else
	  sudo ln -s /opt/go/bin/go /usr/local/bin/go
	  sudo ln -s /opt/go/bin/gofmt /usr/local/bin/gofmt
	fi

	sudo wget -O- "https://golang.org$URL" | sudo tar xz -C /opt
	mkdir -p ~/go/bin
	mkdir -p ~/go/pkg
	mkdir -p ~/go/src

	if ! grep -q GOPATH ~/.bashrc ;then
	  { echo 'export GOPATH=~/go #GoLang'
	    echo 'export PATH=$PATH:$GOPATH/bin #GoLang'
	  } >> ~/.bashrc
	  echo 'GOPATH added to PATH'
	fi
	go version
}

function install_java() { #HELP Install Oracle Java 17:\nBOCKER java
	[ -d /opt/java ] && sudo rm -rf /opt/java/* || sudo mkdir -p /opt/java
	local url='https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz'
  	sudo wget -O- $url | sudo tar xz -C /opt/java --strip-components 1
	update-alternatives --install /usr/bin/java java /opt/java/bin/java 2000
	if ! grep -q JAVA_HOME ~/.bashrc ;then
	  { echo 'export JAVA_HOME=/opt/java #Java'
	    echo 'export PATH=$PATH:$JAVA_HOME/bin #Java'
	  } >> ~/.bashrc
	  echo 'JAVA_HOME added to PATH'
	  source ~/.bashrc
	fi
	java --version
}
function install_k9s() {
	local url="$(wget -qO- https://github.com/derailed/k9s/releases \
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
	sudo wget --show-progress --https-only -qO- "https://github.com/$url" \
	| sudo tar xz -C /usr/local/bin/ --no-same-owner --wildcards --no-anchored 'k9s'
	k9s version
}

function install_podman() {
	sudo mkdir -p /etc/apt/keyrings
	curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/xUbuntu_$(lsb_release -rs)/Release.key \
	  | sudo gpg --yes --dearmor --output /etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg
	echo \
	  "deb [arch=amd64 signed-by=/etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg]\
	    https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/xUbuntu_$(lsb_release -rs)/ /" \
	  | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:unstable.list > /dev/null
	sudo apt-get update -qq
	sudo apt-get -qq -y install podman
}

function install_terraform() {
	local src_url=$(wget -qO- https://www.terraform.io/downloads.html \
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
	wget "$URL" -O $tmp_zip
	sudo unzip -o $tmp_zip -d /opt
	sudo ln -s /opt/terraform /usr/local/bin/terraform || true
	rm $tmp_zip
	terraform --version
}

function install_zoom() {
  local tmp_deb="$(mktemp)"
  local src_url="https://zoom.us/client/latest/zoom_amd64.deb"
  local args=${@:2}
  pkill zoom || true

  wget -O $tmp_deb $src_url &&
  sudo dpkg -i $tmp_deb $args &&
  { rm -f $tmp_deb; true; } || 
  { rm -f $tmp_deb; false; }   # commands above failed, remove tmp file anyway
}

function install_misc() {
	sudo apt install apt-transport-https curl gnupg ca-certificates bash-completion
}
function install_all() {

# VS Code plugins
code --install-extension golang.go
code --install-extension pkief.material-icon-theme
code --install-extension formulahendry.code-runner
code --install-extension rangav.vscode-thunder-client

# Gnome settigns
sudo apt install git gnome-tweaks gnome-shell-extension-dash-to-panel \
gnome-screenshot xclip wl-clipboard doublecmd-gtk jq mupdf keepassx \
p7zip-full fzf
# LF file manager
curl -L https://github.com/gokcehan/lf/releases/latest/download/lf-linux-amd64.tar.gz | tar xzC ~/.local/bin
echo '
settings -> keyboard -> keyboard shortcuts -> Screenshots
sh -c "gnome-screenshot -acf /tmp/test && cat /tmp/test | xclip -i -selection clipboard -target image/png"'

gsettings set org.gnome.desktop.interface cursor-size 32
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Shift>Alt_L']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Alt>Shift_L']"
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:swapescape']"

git config --global user.name "John Doe"
git config --global user.email johndoe@example.com
git config --global core.editor "code --wait"
git config --global pull.rebase true
git config --global alias.review '!bash -c "git push origin HEAD:refs/for/$1" -'
git config --global push.followTags true
git config --global --add --bool rebase.updateRefs true
git config --global --add --bool push.autoSetupRemote true

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
	all|androidsdk|codium|k9s|golang|gh|misc|podman\
	|run|exec|terraform|warp|zoom) install_"$1" "${@:2}" ;;
	*) install_help "$0" ;;
esac
