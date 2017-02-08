#!/bin/sh
#
# Чтение данных из счетчиков электроэнергии с помощью cat
# 2016-04-18
# kohan pavel e-mail: hidersoft@gmail.com ICQ:92819905
#
#
# version 1
#


# каталог скрипта
BASE_DIR="$(dirname "$0")/"
BASE_NAME="$(basename "$0")"

#. ${BASE_DIR}lib_funct.sh

trap_x()
{
  case "$1" in
      0) ;; #echo_ex "Normal end ${BASE_NAME}." ;;
      2) ;; #echo "Abort(Ctrl+C) ${BASE_NAME}!"  ;;
      *) ;; #echo "Trap code(${1}) unknown ${BASE_NAME}!" ;;
  esac

  if kill -0 ${outport} 2>/dev/null; then
    kill ${outport}
    wait ${outport} >/dev/null 2>&1
  fi
  return 10
}

trap "trap_x 0" 0
trap "trap_x 2" 2

 cm=${1}
 lenc=${2}

 [ $DEBUG -gt 1 ] && echo "METHOD_COMMUNITY=CAT len=$lenc" >&2

 cat ${DEVICE} > "${TMPFL}" &
 [ -z "$!" ] || outport=$!

 HexToChar "${cm}" > ${DEVICE}

 [ "${DEV_EMULATOR}" = "YES" ] && Dev_Enulator "${cm}" "${TMPFL}"

 #set -x
 ii=0
 while [ `GetFileSize "${TMPFL}"` -lt $lenc ]
 do
   ii=$(($ii + 1))
   [ $ii -gt ${WAITTICK} ] && break
   sleep .050
 done
 #set +x

