#!/bin/bash

[[ -z "$CURL_METHOD" ]] && CURL_METHOD=GET
[[ -z "$CURL_COUNT" ]] && CURL_COUNT=1
[[ -z "$CURL_SLEEP" ]] && CURL_SLEEP=1

ERROR() {
  echo "[ERROR] $*" >&2 && exit 1
}

INFO() {
  echo "[INFO] $*"
}

SUCCESS() {
  echo "[SUCCESS] $*"
}

usage() {
    echo "Usage: $0 [OPTIONS]

    Options:
      -h, --help                    帮助
          --count int               请求次数，默认：1
          --url string              请求地址，必填
          --method string           请求方法，默认：GET
          --header string           请求header
          --data string             请求数据
          --sleep int               间隔时间（秒），默认：1s
    "
}

TEMP=$(getopt -o h --long help,count:,url:,method:,data:,sleep: -- "$@" 2>/dev/null)
[ $? != 0 ]  && usage && exit 1

eval set -- "${TEMP}"
while :; do
  [ -z "$1" ] && break;
  case "$1" in
    -h|--help)
      usage; exit 0
      ;;
    --count)
      if [[ ! "$2" =~ ^[0-9]{1,}$  ]] || [[ "$2" -lt 1 ]];then
        ERROR "$1 次数必须大于1"
      fi
      CURL_COUNT=$2; shift 2
      ;;
    --url)
      CURL_URL=$2; shift 2
      ;;
    --method)
      CURL_METHOD=$2; shift 2
      ;;
    --header)
      CURL_HEADER=$2; shift 2
      ;;
    --data)
      CURL_DATA="$2"; shift 2
      ;;
    --sleep)
      if [[ ! "$2" =~ ^[0-9]{1,}$  ]] || [[ "$2" -lt 1 ]];then
        ERROR "$1 必须大于1"
      fi
      CURL_SLEEP="$2"; shift 2
      ;;
    --)
      shift
      ;;
    *)
      echo "${CWARNING}ERROR: unknown argument! $1" >&2 && usage && exit 1
  esac
done



[[ -z "$CURL_URL" ]] && ERROR "url必须"

INFO "url=$CURL_URL"
INFO "count=$CURL_COUNT"
INFO "method=$CURL_METHOD"
[[ -n "$CURL_HEADER" ]] && INFO "header=$CURL_HEADER"
[[ -n "$CURL_DATA" ]] && INFO "date=$CURL_DATA"

times=()
total_time=0

for (( i=1; i<="$CURL_COUNT";i++ ));
do
  temp_result=($(curl -o /dev/null -k -g -H "$CURL_HEADER" -d "$CURL_DATA" -X "$CURL_METHOD" -sS -w "%{http_code} %{time_total}" "$CURL_URL"))
  temp_time=${temp_result[1]}
  echo ">>$i 状态码：${temp_result[0]}，响应时间：${temp_time}s"
  [[ $CURL_COUNT -gt 1 ]] && sleep "${CURL_SLEEP}s"
  total_time=$(awk 'BEGIN{print "'$total_time'" + "'$temp_time'" }')
done

avg_time=$(awk 'BEGIN{print "'$total_time'" / "'$CURL_COUNT'" }')

SUCCESS "总用时：${total_time}s，次数：$CURL_COUNT，平均响应：${avg_time}s"
