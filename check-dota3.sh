#!/bin/bash



step()
{
  echo "# ========================================================= #"
  echo "# $1 "
  echo "# ========================================================= #"
}

item() {
  printf '> [ %s ]:\n' "$1"
}

line() {
   return 0
#  echo
#  echo "------------------------------------------------------------------------"
}

REMOTE_IP=('45.9.148.*')
REMOTE_PROCESS=('rsync' './kswapd0')
FILES=('kswapd0' 'tsm32')
# netstat -antp | grep "45.9.148.*"

step "用户列表"

# shellcheck disable=SC2002
users=$(lslogins -u)
echo "${users[@]}"

line

step "正在登录的用户"

# shellcheck disable=SC2002
w
line

step "异常ip通信"

for ip in "${REMOTE_IP[@]}"
do
  item "$ip"
  netstat -antp | grep "$ip"
done
line

step "异常进程"

for process in "${REMOTE_PROCESS[@]}"
do
  item "$process"
  ps -aux | grep -v 'grep' | grep "$process"
done
line
step "定时任务"
all_user=( $(cat /etc/passwd | cut -f 1 -d :) )

for user in "${all_user[@]}"
do
  crontab_text=$(crontab -l -u "$user" 2> /dev/null)
  if [[ -n "$crontab_text" ]]; then
    item "$user"
    echo "$crontab_text"
  fi

done
line
step "木马文件"


for file in "${FILES[@]}"
do
  item "$file"
  find / | grep "$file"
done
line
#cat >> .ssh/authorized_keys << EOF
#EOF

#ssh-copy-id -i ./id_rsa.pub root@172.16.120.41
#/bin/bash -c "$(curl -s http://gupo-tools.oss-cn-hangzhou.aliyuncs.com/shell/check-dota3.sh)"