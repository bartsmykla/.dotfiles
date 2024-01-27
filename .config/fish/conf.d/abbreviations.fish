abbr -a -- awsbt 'op connect server list &> /dev/null || eval $(op signin); set otp $(op item get "BT - AWS" --otp) && awsume bt --mfa-token $otp && aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 273030768099.dkr.ecr.eu-west-1.amazonaws.com' # imported from a universal variable, see `help abbr`
abbr -a -- pgc git_clone_to_projects
abbr -a -- e2e_clean 'make kind/stop/all; docker stop (docker ps -aq)'
abbr -a -- gcs 'git commit -sS'
abbr -a -- cp 'rsync -aP'
abbr -a -- gcb 'git checkout -b'
abbr -a -- bi 'brew install'
abbr -a -- ggp 'git push origin (git branch --show-current)'
abbr -a -- bic 'brew install --cask'
abbr -a -- msync 'set name (basename (pwd)); mutagen sync create --name=$name (pwd) bart@smyk.la:~/$name'
abbr -a -- b. 'cd /Users/bart.smykla@konghq.com/Projects/github.com/bart.smykla@konghq.com/.dotfiles/'
abbr -a -- binf 'brew info'
abbr -a -- bs 'brew search'
abbr -a -- ggpf 'git push --force origin (git branch --show-current)'
abbr -a -- gaa 'git add -A'
abbr -a -- gcm 'git checkout master'
abbr -a -- ga 'git add'
abbr -a -- cdl 'cd $__LAST_CLONED_REPO_PATH'
abbr -a -- gbda git_clean_branches
abbr -a -- gco 'git checkout'
abbr -a -- gst 'git status'
abbr -a -- forget 'ssh-keygen -R'
abbr -a -- k kubectl
abbr -a -- mux tmuxinator
abbr -a -- p 'cd /Users/bart.smykla@konghq.com/Projects/github.com/'
abbr -a -- td 'tmuxinator dev'
abbr -a -- b 'cd /Users/bart.smykla@konghq.com/Projects/github.com/bart.smykla@konghq.com/'
abbr -a -- purge_kuma kubectl\ get\ endpointslice,replicaset,mutatingwebhookconfiguration,validatingwebhookconfiguration,configmap,secret,crd,svc,clusterrole,clusterrolebinding,role,rolebinding,deploy,serviceaccount,ingress\ -A\ -o\ json\ \|\ jq\ -r\ \'.items\[\]\ \|\ select\(.metadata.name\ \|\ contains\(\"kong-mesh\"\)\ or\ contains\(\"kuma\"\)\)\ \|\ select\(.kind\ !=\ \"Namespace\"\ and\ .kind\ !=\ \"Pod\"\)\ \|\ select\(.kind\ !=\ \"Secret\"\ or\ .metadata.name\ !=\ \"kong-mesh-license\"\)\ \|\ .metadata.namespace\ as\ \ \|\ \"\\\(.kind\ \|\ ascii_downcase\)/\\\(.metadata.name\)\"\ as\ \ \|\ if\ \ then\ \"-n\ \\\(\)\ \\\(\)\"\ else\ \"\\\(\)\"\ end\'\ \|\ xargs\ -d\ \"\\n\"\ -I\ \"\{\}\"\ /bin/bash\ -c\ \'kubectl\ delete\ \{\}\ \&\'\;\ wait
abbr -a -- sshno 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
abbr -a -- set-ns 'kubectl config set-context --current --namespace'
abbr -a -- l 'eza --all --long --icons'
abbr -a -- lt 'eza --all --long --icons --tree'
abbr -a -- awslogin 'saml2aws -a kong-sandbox-mesh login && eval (saml2aws script -a kong-sandbox-mesh)'
