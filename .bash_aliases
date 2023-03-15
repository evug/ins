# Archives
alias ltar="tar -ztvf"
alias untar="tar -zxvf"
alias atar="tar -cvzf"

# Cloudflare
alias cc='warp-cli connect'
alias cdi='warp-cli disconnect'
alias cs='warp-cli status'
alias ct='curl https://www.cloudflare.com/cdn-cgi/trace/'

# Git
alias gacp='f(){ git add . ; git commit -m "$*"; git push origin HEAD; unset -f f; }; f'
alias g-staged='git diff --name-only --cached'
alias gc='git commit -m'
alias gdb='git symbolic-ref refs/remotes/origin/HEAD' # default branch 
alias gf='git fetch'
alias gl='git log --oneline --graph'
alias glr='git ls-remote --tags'
alias gp='git pull'
alias gpr='git pull --rebase'
alias gs='git status'
alias gsw='git switch'

# Go
alias glv='go list -m -versions'
alias gb='go build -ldflags="-s -w"'

# Files
alias ageof='f(){ echo $(( $(date +%s) - $(date -r "$1" +%s) )) ; unset -f f; }; f'

# Vagrant
alias vd='vagrant destroy'
alias vd2='killall -9 VBoxHeadless && vagrant destroy'
alias vh='vagrant halt'
alias vs='vagrant ssh'
alias vst='vagrant global-status'
alias vu='vagrant up'

# Kubernetes
alias k='kubectl'
alias kd='kubectl describe'
alias kg='kubectl get'
alias kge='kubectl get ev --field-selector=type=Warning --sort-by=metadata.creationTimestamp'
alias kk='kubectl --kubeconfig=config'
alias kcgc='kubectl config get-contexts'
alias kcsc='kubectl config set-context --current --namespace'
alias kra='kubectl run --restart=Never --rm -it --image=alpine test-alpine'

# Movement
alias cl='f(){ dir="$1";if [ -z "$dir" ];then dir=$HOME;fi;builtin cd "${dir}" && ls -F --color=auto; unset -f f;};f'
alias lsd="ls -d */"
alias mkcd='f() { mkdir -p -- "$1" && cd -P -- "$1"; unset -f f; }; f'

# Network
alias furl='curl --silent --location --head --output /dev/null --write-out %{url_effective} --'
alias myip='curl ipinfo.io'
alias up="ip -f inet addr show tun0 | echo \"http://\`grep -Po 'inet \K[\d.]+'\`/\"; echo $PWD; python3 -m http.server"

# Prompt
PS1='\[\033[0;32m\]\[\033[0m\033[0;32m\]\u\[\033[0;36m\] @ \[\033[0;36m\]\h \w\[\033[0;32m\]$(__git_ps1)\n\[\033[0;32m\]└─\[\033[0m\033[0;32m\] \$\[\033[0m\033[0;32m\] ▶\[\033[0m\] '

# Python
alias pvec="python3 -m venv venv --system-site-packages"
alias pvea="deactivate &> /dev/null; surce ./venv/bin/activate"
alias pved="deactivate"

# Encoding
alias ffmpeg='ffmpeg -hide_banner'
alias ffplay='ffplay -hide_banner -autoexit'
alias ffprobe='ffprobe -hide_banner'
alias pofu="python3 ~/prj/py/put_one_folder_up.py"
alias zr="python3 ~/prj/py/zero_renamer.py"
function audioToOpus { ffmpeg -i "$2" -c:a libopus -b:a "$1" "${2%.*}.opus" ; }
alias mp3opus='for f in *.mp3; do nice -n 10 ffmpeg -i "$f" -c:a libopus -b:a 32k "${f%.mp3}.opus"; done'
alias mp4mp3='for f in *.mp4; do nice -n 10 ffmpeg -i "$f" -acodec libmp3lame -vn -b:a 64k "${f%.mp4}.mp3"; done'
alias mp3con='ls *.mp3;sleep 4; nice -n 10 ffmpeg -f concat -safe 0 -i <(for f in ./*.mp3; do echo "file '"'"'$PWD/$f'"'"'"; done) -c copy "${PWD##*/}".mp3'
alias mp4con='ls *.mp4;sleep 4; nice -n 10 ffmpeg -f concat -safe 0 -i <(for f in ./*.mp4; do echo "file '"'"'$PWD/$f'"'"'"; done) -c copy "${PWD##*/}".mp4'
alias mp4small='shopt -s globstar; for f in **/*.mp4 ; do nice -n 10 ffmpeg -i "$f" -c:v libx265 -crf 40  -preset fast -vf "fps=5" -c:a aac -b:a 64k "${f%.*}_small.mp4"; done'
alias mp4fhd='shopt -s globstar; for f in **/*.mp4 ; do nice -n 10 ffmpeg -i "$f" -c:v libx265 -crf 40  -preset fast -vf "fps=5,scale=w=1920:h=1080:force_original_aspect_ratio=decrease" -c:a aac -b:a 64k "${f%.*}_small.mp4"; done'
alias mp4remove='ls -Q **/*mp4 | egrep  -v *small.mp4\"$ | xargs rm'

alias png2jpg='for i in *.png ; do convert -quality 80% "$i" "${i%.*}.jpg" ; done'

# System
alias auu='sudo apt update && sudo apt upgrade'
alias h=history
alias empty-trash='rm -rf ~/.local/share/Trash/*'
alias inf="uname -sr && uptime|sed 's/ //' && lscpu|grep 'CPU MHz:' && acpi && \
           echo -n 'Memory in use: ' && free -m|grep Mem|awk '{print \$3+\$5\" megs\"}'"
alias upd='rm ~/.bash_aliases && wget -qP ~ https://raw.githubusercontent.com/evug/ins/main/.bash_aliases && echo Updated'
alias aliasf='compgen -A function | grep -v ^_'
alias zzz="systemctl suspend"


tra() { [[ "$1" ]] || { echo "Error: Missing the phrase to translate" >&2; return 1; }
      curl -s -X POST 'https://api-free.deepl.com/v2/translate' \
            -H "Authorization: DeepL-Auth-Key $LLLLL" \
            -d "text=$*" \
            -d "target_lang=FR" \
      | jq .translations[0].text
}
alias тра=tra
