#!/bin/sh
#
# Чтение данных из счетчиков электроэнергии
# Merciry 200
#
# 2016-05-15 version 1
# kohan pavel e-mail: hidersoft@gmail.com ICQ:92819905
#
#
# version 1
#


RETRY_QUERY=1
MIN_BLOCK_SIZE=4
MAX_BLOCK_SIZE=255
START_BLOCK_DATA=5

PASS_R=`StrToHex "${PASS_READ}"`
PASS_W=`StrToHex "${PASS_WRITE}"`

# modes list
MODES='all_time	0
curr_year	1
prior_year	2
month	3
today	4
yesterday	5
all_time_phase	6'

# tarifs list
ZONES='T1	01
T2	02
T3	03
T4	04'



# commands list
# alias	command	size answer	parser format	description
COMMANDS='test	`form_com x00${CSN}x00`	4		Тестирование связи
#close	`form_com x00${CSN}x02`	4		Завершение сеанса

kwatthour	`form_com x00${CSN}x27`	23	"02x$((${zona} * 4 - 3)),02x$((${zona} * 4 - 2)),02x$((${zona} * 4 - 1)),02x$((${zona} * 4))#Aprintf(\"%0.3f\",^b0/1000)"	Опрос накопленной энергии

amper	`form_com x00${CSN}x63`	14	"02x3,02x4#Aprintf(\"%0.2f\",^b0/100)"	Сила тока A (А)
power	`form_com x00${CSN}x63`	14	"02x5,02x6,02x7#Aprintf(\"%0.3f\",^b0/1000)"	Мощность P (кВт)
volt	`form_com x00${CSN}x63`	14	"02x1,02x2#Aprintf(\"%0.1f\",^b0/10)"	Напряжение U (В)

null	`form_com x00${CSN}${mode}`	${MAX_BLOCK_SIZE}	"${OutParser}"	Произвольная команда

batvolt	`form_com x00${CSN}x29`	${MAX_BLOCK_SIZE}	"2x1#Battery\0=\0\t.#0#2#\t\0V"	Напряжение батареи
serialnum	`form_com x00${CSN}x2f`	${MAX_BLOCK_SIZE}	"1,2,3,4#d#Sn\0=\0\t"	Серийный номер счетчика
version	`form_com x00${CSN}x28`	${MAX_BLOCK_SIZE}	"02x4#\t.#0#02x5#\t.#0#02x6"	Дата версии ПО
datetime	`form_com x00${CSN}x21`	${MAX_BLOCK_SIZE}	"2#0#3#:\t:#0#4#\t\0#0#5#\t.#0#6#\t.#0#7"	Дата время по счетчику
datemake	`form_com x00${CSN}x66`	${MAX_BLOCK_SIZE}	"02x1#0#02x2#.\t.#0#02x3"	Дата изготовления
last_on	`form_com x00${CSN}x2c`	${MAX_BLOCK_SIZE}	"2#0#3#:\t:#0#4#\t\0#0#5#\t.#0#6#\t.#0#7"	Время последнего включения
last_off	`form_com x00${CSN}x2b`	${MAX_BLOCK_SIZE}	"2#0#3#:\t:#0#4#\t\0#0#5#\t.#0#6#\t.#0#7"	Время последнего выключения'



Dev_Enulator()
{
  #_0x00_0x00_0x00_0x01_0x00_0x25_0x90
  local command="`echo "${1}" | cut -d"x" -f6 | cut -c1-2`"
  local answer=""

  case $command in
   # Мгновенные значения
   # 00 0E 1F CE 63 |03 67
   # 00 0E 1F CE 63 22 87 02 11 00 06 38 | - ответ : 228.7В, 2.11A, 638Вт
   '63') answer="`form_com x00${CSN}x${command}x22x87x01x50x00x06x38`" ;;
   # Дата время по счетчику
   # 00 0E 1F CE 21 |
   # 00 0E 1F CE 21 ?? ?? ?? ?? ?? |
   '21') answer="`form_com x00${CSN}x${command}x01x11x24x06x18x04x11`" ;;
   # Показания счетчика
   # 00 0E 1F CE 27 |03 54
   # 00 0E 1F CE 27 00_00_04_16 00_00_01_70 00_00_00_00 00_00_00_00 |12 5B
   #                 00000416    00000170    00000000    00000000
   #         кВтч    4,16 (Т1); 1,70 (Т2);    0 (Т3);     0 (Т4)
   '27') answer="`form_com x00${CSN}x${command}x00x00x04x16x00x00x01x70x00x00x00x00x00x00x00x00`" ;;
   # Чтение мощности ?
   # 00 0E 1F CE 26 |C2 94
   # 00 0E 1F CE 26 00 00 |50 CF
   '26') answer="`form_com x00${CSN}x${command}x00x00`" ;;
   # Дата выхода версии
   # 00 0E 1F CE 28 |43 50
   # 00 0E 1F CE 28 08 03 00 01 03 10 |DB 4B  = 1.03.10
   '28') answer="`form_com x00${CSN}x${command}x08x03x00x01x03x10`" ;;
   # Серийный номер
   # 00 0E 1F CE 2F |02 92
   # 00 0E 1F CE 2F 00 69 AD 4E |8C ED  = 69AD4E(6925646)
   '2f') answer="`form_com x00${CSN}x${command}x00x69xADx4E`" ;;
   # Напряжение батареи
   #  00 0E 1F CE 29 |82 90
   # -00 0E 1F CE 29 03 05 |A0 3F  = 3,05В
   '29') answer="`form_com x00${CSN}x${command}x03x05`" ;;
   # Дата изготовления
   #  00 0E 1F CE 66 |C3 64
   # -00 0E 1F CE 66 29 10 10 |07 38  = 29.10.10
   '66') answer="`form_com x00${CSN}x${command}x29x10x10`" ;;
   #  00 0E 1F CE 65 |83 65
   # -00 0E 1F CE 65 00 03 |E1 1A
   '65') answer="`form_com x00${CSN}x${command}x00x03`" ;;
   # Время последнего включения
   #  00 0E 1F CE 2C |42 93
   # -00 0E 1F CE 2C 01 11 24 06 18 04 11 |5E A2  = 18.04.11 11:24:06
   '2c') answer="`form_com x00${CSN}x${command}x01x11x24x06x18x04x11`" ;;
   # Время последнего выключения
   #  00 0E 1F CE 2B |03 51
   # -00 0E 1F CE 2B 03 17 02 35 13 04 11 |4B A3  = 13.04.11 17:02:35
   '2b') answer="`form_com x00${CSN}x${command}x03x17x02x35x13x04x11`" ;;
  esac

  #echo "answer=${answer}" >&2
  HexToChar "${answer}" > "${2}"
}

SetCounterSN()
{
 COUNTER_SN=${COUNTER_SN:='00000000'}
 CSN=`echo "${COUNTER_SN}" | awk '{r=sprintf("%06x", substr($0,length($0)-5,6)); for(i=1; i<length(r); i=i+2) { printf "x"substr(r, i, 2); }; }'`
 #CSN=`echo "${COUNTER_SN}" | awk '{r=sprintf("%06x", substr($0,length($0)-5,6)); for(i=1; i<length(r); i=i+2) { /* if(i!=1){printf "x"}; */ printf substr(r, i, 2); }; }'`
}


SetParams()
{
  # определить имя команды
  com_string=${1}
  [ -z "${com_string}" ] && com_string="kwatthour"
  com_name="`echo ${com_string} | cut -d":" -f1`"
  [ -z "$com_name" ] && com_name=$com_string

  com="${com_name}	`CheckParameter "command" "${com_name}" "${COMMANDS}" "" "Command \"$com_name\" unknown!"`"
  [ $? -ne 0 ] && return 1

  cmd="`echo "${com}" | cut -d"	" -f2`"
  com_size="`echo "${com}" | cut -d"	" -f3`"
  outparser="`echo "${com}" | cut -d"	" -f4`"
  name="`echo "${com}" | cut -d"	" -f5`"

  #echo "$com_name $cmd $com_size" >&2

  case $com_name in
    'null') {
         ParseNullCom "${com_string}"

         PARAMS="\"${com_string}\"> mode=${mode}"
    };;
    'kwatthour') {
         zoner=`echo ${com_string} | sed -n 's/^[^:]*:\(.*\)$/\1/p'`
         zona="`CheckParameter zona "${zoner}" "${ZONES}" '01'`"

         PARAMS="\"${com_string}\"> zona="${zona}
    };;
    *) PARAMS="none" ;;
  esac

  [ $DEBUG -gt 0 ] && echo "COMMAND: $com_name; PARAMS: ${PARAMS}; SIZE: $com_size; OUTPARSER: $outparser; DESCRIBE: ${name}" >&2

  eval cmd=$cmd
  eval com_size=$com_size
  eval outparser="$outparser"
  #echo "$com_name	$cmd	$com_size	$outparser	$name"
  return 0
}


Parser_com()
{
  com=$1
  request=$2
  leng=$3
  outparser="$4"
  #echo $outparser >&2

  lenn=${#request}

  #echo $com $request $leng

  de=`expr ${lenn} - 6`
  sn=`echo $request | cut -c1-3`
  snd=`printf "%d" 0$sn`
  data=`echo $request | cut -c4-$de`
  crc=`echo $request | cut -c$(expr $de + 1)-$lenn`

  #echo sn=$sn data=$data crc=$crc

  if [ $leng -eq $MIN_BLOCK_SIZE ]; then
     case $data in
      # Ok
      x00) {
         echo "$com - Ok [${snd}]"
         return 0
      };;
      # Недопустимая команда или параметр.
      x01) {
         echo "Invalid command or parameter [${snd}]"
         return 1
      };;
      # Внутренняя ошибка счетчика.
      x02) {
         echo "Internal error counter [${snd}]"
         return 2
      };;
      # Не достаточен уровень доступа для удовлетворения запроса.
      x03) {
         echo "Not sufficient level of access to satisfy the request [${snd}]"
         return 3
      };;
      # Внутренние часы счетчика уже корректировались в течение текущих суток
      x04) {
         echo "The internal clock counter has been adjusted for the current day [${snd}]"
         return 4
      };;
      # Не открыт канал связи
      x05) {
         echo "Do not open the link [${snd}]. Need openread"
         return 5
      };;
        *) {
         echo "Unknown code \"$data\" [${snd}]"
         return 6
      };;
     esac
  else

     # ParserCommand $data "01D1"
     if [ -n "$outparser" ]; then
          #echo $outparser >&2

          rezout="`DoOutParser $outparser`"
          echo "${rezout}"
          return 255
     fi

     case $com in
      'null') {
             echo $data outparser=$outparser >&2
      };;
     esac
     return 255
 fi
}

