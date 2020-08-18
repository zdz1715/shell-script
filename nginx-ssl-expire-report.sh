#!/bin/bash


get_conf()
{
  conf=$(grep -w "$1" "$2" | sed 's/^[\s\t]*\|[\s\t]*$/''/')
  echo "$conf"
  return 0
}

get_server_name()
{
  echo | get_conf "$1" "$2" | awk '{print $2}' | sed 's/;/''/'
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


dos2unix -V >/dev/null 2>&1 || { log_error "请安装dos2unix，它是必须的"; exit 1; }




# 开始时间
START_TIME=$(date +'%Y-%m-%d %H:%M:%S')
START_SECONDS=$(date --date="$START_TIME" +%s)




if [ -z "$NGINX_CONF_DIR" ]; then
  log_error "nginx配置文件目录不能为空"
  exit 1
fi




step "配置信息"
log_info "NGINX_CONF_DIR=${NGINX_CONF_DIR}"

## 循环替换目录下配置的ssl路径，如若存在
conf_list=$(ls "$NGINX_CONF_DIR")
# 格式化字符串
NGINX_CONF_DIR=${NGINX_CONF_DIR%/}

step "BEGIN"

file_count=0
suc_count=0
err_count=0
fail_no=()


for f in $conf_list
do

  ((file_count++))
  CONF_PATH="$NGINX_CONF_DIR/$f"

  echo "$file_count、$CONF_PATH"

  # 格式化文件，防止windows上传上来出错
  log_command "dos2unix $CONF_PATH"

  # 获取当前域名
  HOST_NAME=$(get_server_name 'server_name' "$CONF_PATH")

  log_info "server_name"
  echo "$HOST_NAME"
  log_info "host"
  echo "https://$HOST_NAME"


  if [ -n "$HOST_NAME" ] && [ "$HOST_NAME" != '_' ]; then
    if log_command "echo | openssl s_client -servername $HOST_NAME -connect $HOST_NAME:443 2>/dev/null | openssl x509 -noout -dates" ; then
      ((suc_count++))
    else
      ((err_count++))
      fail_no["$file_count"]="$file_count"
    fi

  else
    log_warn '未找到server_name配置或者server_name为_，跳过'
    ((err_count++))
    fail_no["$file_count"]="$file_count"
  fi
  echo '----------------------------------------------------------------------'
done

step "END"

END_TIME=$(date +'%Y-%m-%d %H:%M:%S')
END_SECONDS=$(date --date="$END_TIME" +%s)
log_success "执行完毕：$((END_SECONDS-START_SECONDS))s，总共$file_count条，成功获取$suc_count条，失败$err_count条，失败序号为：${fail_no[*]}"


