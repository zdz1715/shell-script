#!/bin/bash

# 开始时间
START_TIME=$(date +'%Y-%m-%d %H:%M:%S')
START_SECONDS=$(date --date="$START_TIME" +%s)


docker_rm()
{
  log_command "docker rm -f $1"
  log_command "docker rmi $2"
}

step()
{
  echo "# ========================================================= #"
  echo "# $1 "
  echo "# ========================================================= #"
}

log()
{
  echo "$1：$2"
}

log_error()
{
  log "[ERROR]" "$1"
}

log_info()
{
  log "[INFO]" "$1"
}

log_success()
{
  log "[SUCCESS]" "$1"
}

log_command()
{
  log "[COMMAND]" "$1"
  if [[ -z $2 ]]; then
    bash -c "$1"
  fi
}

if [ -z "$NGINX_CONF_DIR" ]; then
  log_error "nginx配置文件目录不能为空"
  exit 1
fi

if [ -z "$NGINX_SSL_CERTIFICATE" ]; then
  log_error "ssl公钥路径不能为空"
  exit 1
fi

if [ -z "$NGINX_SSL_CERTIFICATE_KEY" ]; then
  log_error "ssl私钥路径不能为空"
  exit 1
fi

step "配置信息"
log_info "NGINX_CONF_DIR=${NGINX_CONF_DIR}"
log_info "NGINX_SSL_CERTIFICATE=${NGINX_SSL_CERTIFICATE}"
log_info "NGINX_SSL_CERTIFICATE_KEY=${NGINX_SSL_CERTIFICATE_KEY}"


## 循环替换目录下配置的ssl路径，如若存在
conf_list=$(ls "$NGINX_CONF_DIR")

step "开始处理"

file_count=0
suc_count=0
err_count=0

for f in $conf_list
do
  ((file_count++))
  echo "$file_count、$f"
  cat $f
done

step "result"

END_TIME=$(date +'%Y-%m-%d %H:%M:%S')
END_SECONDS=$(date --date="$END_TIME" +%s)
log_success "执行成功：$((END_SECONDS-START_SECONDS))s，总共处理$file_count条，成功$suc_count条，失败$err_count条"


