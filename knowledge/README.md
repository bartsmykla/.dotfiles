# Knowledge

## List all `iptables` rules

```sh
# -L | list rules
# -v | verbose output
# -n | numeric output for IP addresses and ports
iptables -L -v -n
```

## Ignore path in git repository without adding it to the `.gitignore` file

You can add the path (glob patterns allowed) in the `.git/info/exclude` file in a repository

```sh
echo "tmp/*.go" >> .git/info/exclude
```

## Clean all kuma/kong-mesh resources except the kong-mesh-license secret if present

```sh
kubectl get endpointslice,replicaset,mutatingwebhookconfiguration,validatingwebhookconfiguration,configmap,secret,crd,svc,clusterrole,clusterrolebinding,role,rolebinding,deploy,serviceaccount,ingress -A -o json \
  | jq -r '.items[]
    | select(.metadata.name | contains("kong-mesh") or contains("kuma")) 
    | select(.kind != "Namespace" and .kind != "Pod")
    | select(.kind != "Secret" or .metadata.name != "kong-mesh-license") 
    | .metadata.namespace as $namespace
    | "\(.kind | ascii_downcase)/\(.metadata.name)" as $resource 
    | if $namespace
      then
        "-n \($namespace) \($resource)"
      else
        "\($resource)"
      end' \
  | xargs -d "\n" -I "{}" /bin/bash -c 'kubectl delete {} &'; \
  wait
```

## Let to find and replace new lines in GNU `sed`

### Prerequisites

MacOS comes with the BSD verion of `sed`, so to use it, you have to install GNU `sed` first

```sh
brew install gnu-sed
```

After installing it, it will be available as a `gsed` command, but if you want you can put it in the `$PATH` variable to point `sed` binary to just installed GNU `sed` version (remember to put it at the beginning of the `$PATH`):

bash

```bash
PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
```

fish

```fish
set -gx PATH /usr/local/opt/gnu-sed/libexec/gnubin $PATH
```

### Command

```sh
# -E | extended regexp expressions
# -z | separate lines by NUL characters (this flag is the one we are
#      interested in, and it's only available in GNU sed, not BSD's 
#      version of sed)
sed -Ez 's//'
```

## `jq`

### filter array by object properties

Filter an array of objects by the `name` property containing word `foo`

**Command**

```sh
json='[{"name": "foo"},{"name": "bar"},{"name": "foobar"}]'

echo $json | jq 'map(select(.name | contains("foo")))'
```

**Result**

```json
[
  {
    "name": "foo"
  },
  {
    "name": "foobar"
  }
]
```

**Other way of achieving the same result**

```sh
# [...]
echo $json | jq '[.[] | select(.name | contains("foo"))]'
```

### `jq` related links

* [Processing JSON using jq](https://gist.github.com/olih/f7437fb6962fb3ee9fe95bda8d2c8fa4)

## `tar`

```sh
# -x, --extract        | extract the archive
# -v                   | verbose
# -z, --gunzip, --gzip | uncompress archive with gzip - this option is
#                        ignored in most tar versions when extracting
#                        archives, so can be omitted
# -f, --file           | extract the provided file
tar -xvzf name.tar.gz
```

## Helpful links

### Linux general

* [Beginner's Guide to Installing from Source](https://moi.vonos.net/linux/beginners-installing-from-source/) - found when reading ["Linux From Scratch" prerequisites](https://www.linuxfromscratch.org/lfs/view/stable-systemd/prologue/prerequisites.html)
