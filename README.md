# electrocounters
Скрипты обмена со счетчиками электроэнергии Меркурий

Форк с https://hi.dp.ua/svn/electo_counters/trunk/

Для вычитки данных из Меркурия 200 в файле electro_counter.conf нужно указать:
# файл протокола обмена со счетчиком
COUNTER_TYPE="merc200.sh"
# устройство-порт, к которому подключен счетчик
DEVICE="/dev/ваш_девайс"
# серийный номер счетчика
COUNTER_SN=номер_вашего_счетчика (8 цифр)
# AUTO, FREEBSD, LINUX
OS=ваша_ОС

указать параметры COM-порта:

для FreeBSD
DEV_FLAGS=" ixany ignbrk opost cread cs8 -ixon -ixoff -parenb -parodd -hupcl -clocal -cstopb raw"

для Linux Raspberry
DEV_FLAGS_LINUX=" speed 9600 baud; rows 0; columns 0; line = 0;
intr = ^C; quit = ^\; erase = ^?; kill = ^U; eof = ^D; eol = <undef>; eol2 = <undef>; swtch = <undef>; start = ^Q; stop
-parenb -parodd -cmspar cs8 -hupcl -cstopb cread -clocal -crtscts
-ignbrk -brkint -ignpar -parmrk -inpck -istrip -inlcr -igncr -icrnl -ixon -ixoff -iuclc -ixany -imaxbel -iutf8
-opost -olcuc -ocrnl -onlcr -onocr -onlret -ofill -ofdel nl0 cr0 tab0 bs0 vt0 ff0
-isig -icanon -iexten -echo -echoe -echok -echonl -noflsh -xcase -tostop -echoprt -echoctl -echoke"

для Linux Debian
DEV_FLAGS_LINUX=" cs8 9600 ignbrk -brkint -icrnl -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -ech


запускать: sh electro_counter.sh <КОМАНДА>
где <КОМАНДА> для Меркурий 200:
kwatthour        Опрос накопленной энергии
amper            Сила тока A (А)
power            Мощность P (кВт)
volt             Напряжение U (В)
batvolt          Напряжение батареи
serialnum        Серийный номер счетчика
version          Дата версии ПО
datetime         Дата время по счетчику
datemake         Дата изготовления
last_on          Время последнего включения
last_off         Время последнего выключения
