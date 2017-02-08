#!/bin/sh
#
# Чтение данных из счетчиков электроэнергии с помощью dd
# 2016-04-18
# kohan pavel e-mail: hidersoft@gmail.com ICQ:92819905
#
#
# version 1
#

 BASE_DIR="$(dirname "$0")/"
 #. ${BASE_DIR}lib_funct.sh

 cm=${1}
 lenc=${2}

trap_x()
{
  case "$1" in
    0) ;; #echo_ex "Normal end ${BASE_NAME}." ;;
    2) ;; #echo "Abort(Ctrl+C) ${BASE_NAME}!"  ;;
    *) ;; #echo "Trap code(${1}) unknown ${BASE_NAME}!" ;;
  esac

  if kill -0 ${outport} 2>/dev/null; then
      #echo "Need Kill $outport" >&2
      kill $outport
      wait ${outport} >/dev/null 2>&1
  fi

  if kill -0 ${inport} 2>/dev/null; then
      kill $inport
      wait ${inport} >/dev/null 2>&1
  fi

  return 10
}

trap "trap_x 0" 0
trap "trap_x 2" 2


 [ $DEBUG -gt 1 ] && echo "METHOD_COMMUNITY=DD len=$lenc" >&2

 inport=0
 outport=0
 len_block=$lenc
 #len_block=`echo $len | rev | cut -d"," -f1 | rev`

 ( HexToChar "${cm}" > ${DEVICE} ) &
 [ -z "$!" ] || inport=$!
 ( dd if=${DEVICE} of="${TMPFL}" count=$len_block obs=1 ibs=1 > /dev/null 2>&1 ) &
 [ -z "$!" ] || outport=$!

 [ "${DEV_EMULATOR}" = "YES" ] && Dev_Enulator "${cm}" "${TMPFL}"

 ii=0
 while kill -0 ${outport} 2>/dev/null
 do
   ii=`expr $ii + 1`
   [ $ii -gt ${WAITTICK} ] && break
   sleep .050
 done



