#!/bin/sh
#

#set -x

# подгрузка начальных параметров/функций
. "/etc/libs/initial"
# подгрузить библиотеку функций
load_libfunc

 # тариф 2(полупик-день) или 3(ночь)
 T_num=${1}
 T_num=${T_num:=2}

 # кол-во Ватт в час
 WattH=${2}
 WattH=${WattH:=1}

 T_hours="2:07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22
3:00 01 02 03 04 05 06 23"

 T_minuts=0
 ret=0

#---------  штатное завершение работы сценария --------------
trap_x()
{
  case "$1" in
     0) #echo_ex "Normal end ${BASE_NAME}."
        ;;
     2) echo_ex "Abort(Ctrl+C) ${BASE_NAME}!"
        ;;
     *) echo_ex "Trap code(${1}) unknown ${BASE_NAME}!".
        ;;
  esac
  #  [ "${NO_LOG}" = "Y" ] || exec <&-
  [ $ret -eq 0 ] && {
     #echo "Error: $? "
     exit 0
  }
}

trap "trap_x 0" 0

 T_curr=`date +%Y%m%d%H%M%S`
 # T_curr=20150818070000
 if [ -r ${BASE_DIR}/merc230_last ]; then
      T_last=`sed -n '/^T'$T_num'	/{; s/^T'$T_num'	\(.*\)/\1/p;q;}' ${BASE_DIR}/merc230_last`
      [ -z "$T_last" ] && {
          echo 0
          exit 1
      }

      T_last=${T_last:=$T_curr}
      #echo $T_last
      s_diff=$((`date -j -f %Y%m%d%H%M%S $T_curr +%s` - `date -j -f %Y%m%d%H%M%S $T_last +%s`))

      #echo "T_last=$T_last T_curr=$T_curr s_diff=$s_diff"
      [ $s_diff -le 0 ] && {
          echo 0
          exit 0
      }

      #echo $s_diff
      d_diff=$(($s_diff/(3600*24)))
      c_diff=$(($s_diff%(3600*24)))
      h_diff=$(($c_diff/3600))
      c_diff=$(($c_diff%3600))
      m_diff=$(($c_diff/60))
      #c_diff=$(($c_diff%60))

      #echo "$d_diff $h_diff $m_diff"

      # учесть кол-во целых дней
      if [ 0$d_diff -gt 0 ]; then
          T_lastn=`date -v +${d_diff}d -j -f %Y%m%d%H%M%S $T_last +%Y%m%d%H%M%S`
          if [ $T_num -eq 2 ]; then
             T_minuts=$(($d_diff*16*60))
          else
             T_minuts=$(($d_diff*8*60))
          fi
      else
          T_lastn=$T_last
      fi
      #echo "T_minuts_d=$T_minuts"

      h_diff_n=0
      # выравнять минуты
      [ $h_diff -gt 0 ] && {
         T_last_m=$((60 - `date -j -f %Y%m%d%H%M%S $T_last +%M`))
         [ $T_last_m -eq 60 ] && T_last_m=0
         [ $T_last_m -gt 0 ] && {
             T_last_h=`date -j -f %Y%m%d%H%M%S $T_last +%H`
             T_m="`echo "$T_hours" | sed -n 's/^\([^:]*\):.*'${T_last_h}'.*/\1/p'`"
             [ $T_m -eq $T_num ] && T_minuts=$(($T_minuts+$T_last_m))
             T_lastn=`date -v +${T_last_m}M -j -f %Y%m%d%H%M%S $T_lastn +%Y%m%d%H%M%S`
             if [ $h_diff -gt 0 ]; then
                h_diff_n=$(($h_diff-1))
             else
                h_diff_n=$h_diff
             fi
         }
      }
      #echo "T_minuts_m1=$T_minuts"

      [ $h_diff_n -gt 0 ] && {
         for i in `jot $h_diff_n 0 $h_diff_n 1`
         do
           T_lastn_="`date -v +${i}H -j -f %Y%m%d%H%M%S ${T_lastn} +%Y%m%d%H%M%S`"
           T_lastm=$T_lastn_
           T_last_h=`date -j -f %Y%m%d%H%M%S $T_lastn_ +%H`
           T_m="`echo "$T_hours" | sed -n 's/^\([^:]*\):.*'${T_last_h}'.*/\1/p'`"
           [ $T_m -eq $T_num ] && T_minuts=$(($T_minuts+60))
         done
         T_lastm="`date -v +1H -j -f %Y%m%d%H%M%S ${T_lastm} +%Y%m%d%H%M%S`"
         T_lastn=$T_lastm
      }
      #echo "T_minuts_h=$T_minuts"

      # минуты
      if [ $h_diff -gt 0 ]; then
         T_last_m=`date -j -f %Y%m%d%H%M%S $T_curr +%M`
      else
         T_last_m=$m_diff
      fi
      [ $T_last_m -gt 0 ] && {
          T_last_h=`date -j -f %Y%m%d%H%M%S $T_curr +%H`
          T_m="`echo "$T_hours" | sed -n 's/^\([^:]*\):.*'${T_last_h}'.*/\1/p'`"
          #T_last_m=$((10#$T_last_m))
          [ $T_m -eq $T_num ] && T_minuts=$(($T_minuts + $T_last_m))
          T_lastn=`date -v +${T_last_m}M -j -f %Y%m%d%H%M%S $T_lastn +%Y%m%d%H%M%S`
      }
      #}
      #echo "T_minuts_m2=$T_minuts"

      #echo "$T_last ($d_diff days, $h_diff hours, $m_diff minutes) = $T_lastn = $T_curr T_minuts=$T_minuts"
     ret=0
 else
     ret=1
 fi
 #echo "T_minuts=$T_minuts WattH=$WattH $(($T_minuts*$WattH/60))"
 echo $(($T_minuts*$WattH/6000))

 exit $ret

