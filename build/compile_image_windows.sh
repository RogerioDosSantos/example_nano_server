#!/usr/bin/env bash

pushd "$(dirname "$0")" > /dev/null

main::GetProxyConfig()
{
  # Usage GetProxyConfig

  local proxy_config=""
  local temp="$(printenv http_proxy)"
  if [ "${temp}" != "" ]; then
    proxy_config="${proxy_config} --build-arg http_proxy=${temp}"
  fi

  temp="$(printenv https_proxy)"
  if [ "${temp}" != "" ]; then
    proxy_config="${proxy_config} --build-arg https_proxy=${temp}"
  fi

  temp="$(printenv no_proxy)"
  if [ "${temp}" != "" ]; then
    proxy_config="${proxy_config} --build-arg no_proxy=${temp}"
  fi

  echo "${proxy_config}"
}

proxy_config="$(main::GetProxyConfig)"
docker build -f ./os_windows.docker ${proxy_config} -t "rogersantos/nano_server_example:os_windows" .
docker build --no-cache -f ./app_windows.docker ${proxy_config} -t "rogersantos/nano_server_example:dev_windows" .
docker inspect rogersantos/nano_server_example:dev_windows | grep product_uri | head -1
docker inspect rogersantos/nano_server_example:dev_windows | grep flavor | head -1

popd > /dev/null
