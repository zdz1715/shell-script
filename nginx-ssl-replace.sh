#!/bin/bash

# 开始时间
START_TIME=$(date +'%Y-%m-%d %H:%M:%S')
START_SECONDS=$(date --date="$START_TIME" +%s)


get_conf()
{
  conf=$(grep -w "$1" "$2" | sed 's/^\s*\|\s*$/''/')
  echo "$conf"
  return 0
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

log_warn()
{
  log "[WARN]" "$1"
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


if [ -z "$NGINX_CONF_BACKUP_DIR" ]; then
  NGINX_CONF_BACKUP_DIR=/tmp/nginx-ssl-replace-conf-backup
fi

if [ -z "$NGINX_SSL_CERTIFICATE" ]; then
  log_error "ssl公钥路径不能为空"
  exit 1
fi

if [ -z "$NGINX_SSL_CERTIFICATE_KEY" ]; then
  log_error "ssl私钥路径不能为空"
  exit 1
fi

if [ ! -d "$NGINX_CONF_DIR" ] || [ ! -f "$NGINX_SSL_CERTIFICATE" ] ||  [ ! -f "$NGINX_SSL_CERTIFICATE_KEY" ]; then
  log_error "nginx配置文件目录不存在或者公钥、私钥的文件不存在"
  exit 1
fi

step "配置信息"
log_info "NGINX_CONF_DIR=${NGINX_CONF_DIR}"
log_info "NGINX_SSL_CERTIFICATE=${NGINX_SSL_CERTIFICATE}"
log_info "NGINX_SSL_CERTIFICATE_KEY=${NGINX_SSL_CERTIFICATE_KEY}"

step "备份文件"
log_command "cp -a $NGINX_CONF_DIR $NGINX_CONF_BACKUP_DIR"


## 循环替换目录下配置的ssl路径，如若存在
conf_list=$(ls "$NGINX_CONF_DIR")

step "开始处理"

file_count=0
suc_count=0
err_count=0
# 格式化字符串
NGINX_CONF_DIR=${NGINX_CONF_DIR%/}
NGINX_SSL_CERTIFICATE=${NGINX_SSL_CERTIFICATE%;}
NGINX_SSL_CERTIFICATE_KEY=${NGINX_SSL_CERTIFICATE_KEY%;}


for f in $conf_list
do

  ((file_count++))
  CONF_PATH="$NGINX_CONF_DIR/$f"

  echo "$file_count、$CONF_PATH"

  # 获取当前ssl证书路径
  CURRENT_SSL_CERTIFICATE=$(get_conf 'ssl_certificate' "$CONF_PATH")
  CURRENT_SSL_CERTIFICATE_KEY=$(get_conf 'ssl_certificate_key' "$CONF_PATH")

  log_info "ssl配置：${CURRENT_SSL_CERTIFICATE} ${CURRENT_SSL_CERTIFICATE_KEY}"


  if [ -n "$CURRENT_SSL_CERTIFICATE" ] && [ -n "$CURRENT_SSL_CERTIFICATE_KEY" ] ; then


    if ! log_command "sed -i 's|\<\(ssl_certificate\s*\)\>.*|\1 ${NGINX_SSL_CERTIFICATE};|' ${CONF_PATH}" ||
    ! log_command "sed -i 's|\<\(ssl_certificate_key\s*\)\>.*|\1 ${NGINX_SSL_CERTIFICATE_KEY};|' ${CONF_PATH}"; then
      log_error "替换失败"
      ((err_count++))
    else
      ((suc_count++))
      log_success "$(get_conf 'ssl_certificate' "$CONF_PATH") $(get_conf 'ssl_certificate_key' "$CONF_PATH")"
    fi


  else
    log_warn '未找到ssl_certificate、ssl_certificate_key配置，跳过'
    ((err_count++))
  fi

done

step "result"

END_TIME=$(date +'%Y-%m-%d %H:%M:%S')
END_SECONDS=$(date --date="$END_TIME" +%s)
log_success "执行完毕：$((END_SECONDS-START_SECONDS))s，总共处理$file_count条，成功$suc_count条，失败$err_count条"

step "nginx 配置检测"
nginx -t


