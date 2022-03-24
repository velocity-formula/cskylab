#
#   Source file for building mod-tenant-config.yaml file
#

# This script is designed to be sourced
# No shebang intentionally
# shellcheck disable=SC2148
# shellcheck disable=SC2002

config_env="$(cat config.env | base64 -w0)" 
source_mod_tenant_config="$(
  cat <<EOF
#
# WARNING!: Do not modify this file!
#           
#           This file is automatically generated
#           from environment variables declared
#           in file config.env.
#
#           You should modify config.env file 
#           without adding any comments to 
#           EXPORT directives.        
#

apiVersion: v1
data:
  config.env: "${config_env}"
kind: Secret
metadata:
  name: tenant-config
  namespace: {{ .namespace.name }}
type: Opaque

EOF
)"

echo "${source_mod_tenant_config}" > mod-tenant-config.yaml
