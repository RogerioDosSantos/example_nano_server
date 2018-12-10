#!/usr/bin/env bash

pushd "$(dirname "$0")" > /dev/null

main::GetProxyConfig()
{
  # Usage GetProxyConfig

  local proxy_config=""
  local temp="$(printenv http_proxy)"
  if [ "${temp}" != "" ]; then
    proxy_config="${proxy_config} --env http_proxy=${temp}"
  fi

  temp="$(printenv https_proxy)"
  if [ "${temp}" != "" ]; then
    proxy_config="${proxy_config} --env https_proxy=${temp}"
  fi

  temp="$(printenv no_proxy)"
  if [ "${temp}" != "" ]; then
    proxy_config="${proxy_config} --env no_proxy=${temp}"
  fi

  echo "${proxy_config}"
}

main::execution_config()
{
  # echo "--rm -d"
  echo "--rm -it"
}

main::GetDebugConfig()
{
  # local host_dir="$(pwd -P)/stage/windows_x64/Debug"
  # host_dir="${host_dir//\/c\//c:\\}"
  # host_dir="${host_dir//\//\\}"
  # echo "-v ${host_dir}:c:\\workspace\\app"
  echo ""
}

docker run --name "test" $(main::execution_config) $(main::GetDebugConfig) rogersantos/nano_server_example:dev_windows 

popd > /dev/null
