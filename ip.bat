@echo off
@setlocal enabledelayedexpansion enableextensions
::ip script v.1.0 by @hi3xx

::Get the language from the system
	call :LangENG
	for /f "tokens=3 delims= " %%a in ('reg query "hklm\system\controlset001\control\nls\language" /v Installlanguage') DO (
		if "%%a" == "0419" (
			call :LangRUS
		)
	)

::Copy the script file to %windir%
	if not exist %windir%\ip.bat (
		copy /b /y "%~f0" %windir%\ip.bat>0
		echo.┌────────────────────────────────────────────────────────────┐
		echo.%langWarn1%
		echo.%langWarn2%
		echo.%langWarn3%
		echo.└────────────────────────────────────────────────────────────┘
	)

::Parsing script arguments
	set strArg1=%~1
	set strArg2=%~2
	set strArg3=%~3
	set strArg4=%~4
	
	for /l %%a in (1,1,4) do (
	
		set strCurrentArg=!strArg%%a!
		
		if "!strCurrentArg!" NEQ "" (
			set iArgProcessed=0
		
			if /i "!strCurrentArg!" == "auto"     set iArgProcessed=1& set strArgMode=dhcp
			if /i "!strCurrentArg!" == "dhcp"     set iArgProcessed=1& set strArgMode=dhcp
			if /i "!strCurrentArg!" == "list"     set iArgProcessed=1& set strArgMode=list
			if /i "!strCurrentArg!" == "rename"   set iArgProcessed=1& set strArgMode=rename
			if /i "!strCurrentArg:~-1!" == "?"    set iArgProcessed=1& set strArgMode=help
			if /i "!strCurrentArg:~-4!" == "help" set iArgProcessed=1& set strArgMode=help
			
			if /i "!strCurrentArg!" == "scan" (
				set iArgProcessed=1
				set strArgMode=scan
				set iScanArg=%%a
			)
			
			::"names" should be after "scan"
			if /i "!strCurrentArg!" == "names" (
				set iArgProcessed=1
				if "%%a" GTR "!iScanArg!" (
					set "strArgScanNames=-a"
				)
			)
			
			::try to parse IP-like arg - xxx.xxx.xxx.xxx/xx
			for /f "tokens=1-5 delims=./" %%i in ("!strCurrentArg!") do (
				if "%%l" NEQ "" (
					call :isNumber %%i
					if errorlevel == 1 (
						call :isNumber %%j
						if errorlevel == 1 (
							call :isNumber %%k
							if errorlevel == 1 (
								call :isNumber %%l
								if errorlevel == 1 (
									if defined strArgIP (
										if defined strArgMask (
											set iArgProcessed=1
											set strArgGateway=%%i.%%j.%%k.%%l
										) else (
											set iArgProcessed=1
											set strArgMask=%%i.%%j.%%k.%%l
										)
									) else (
										set iArgProcessed=1
										set strArgMode=set
										set strArgIP=%%i.%%j.%%k.%%l
									)
								)
								
								call :isNumber %%m
								if errorlevel == 1 (
									if "!strCurrentArg:~-2,1!" == "/" set strArgPrefix=%%m
									if "!strCurrentArg:~-3,1!" == "/" set strArgPrefix=%%m
								)
								
								if defined strArgPrefix (
									call :convertPrefixToMask !strArgPrefix!
								)
								
							)
						)
					)
				)
			)

			::if it is just a number - consider it is a adapter's number
			call :isNumber !strCurrentArg!
			if errorlevel == 1 (
				set iArgProcessed=1
				set iArgNumberNA=!strCurrentArg!
			)
			
			::if arg is still not processed - consider it is a adapter's name
			if !iArgProcessed! == 0 (
				if defined strArgNameNA (
					set strArgNewName=!strCurrentArg!
				) else (
					set strArgNameNA=!strCurrentArg!
				)
				
				if defined iArgNumberNA (
					set strArgNewName=!strCurrentArg!
				)
			)
		)
	)	

:Main	
::Processing script arguments
	if /i "%strArgMode%" == "help" (
		call :showHelp
		exit/b)
	
	call :getAdaptersInfo
	
	if not defined strArgMode (
		if not defined iArgNumberNA call :showHelp
		call :showAdaptersList
		call :selectToTurnOnOff
		exit/b
	)

	if /i "%strArgMode%" == "auto"   set bDHCP=1
	if /i "%strArgMode%" == "dhcp"   set bDHCP=1
	if /i "%strArgMode%" == "rename" goto renameNA
	if /i "%strArgMode%" == "scan"   goto scanSubnet
	
	call :showAdaptersList

	if /i "%strArgMode%" == "list" exit/b
	
	if defined iArgNumberNA (
		set /a iChoice=iArgNumberNA
	) else (
		::Ask which adapter to work with
		choice /c !strChoice!0 /n /m "%langSelectApply%"
		set /a iChoice=!errorlevel!
	)
	
	if %iChoice% GTR %countNA% exit /b
	
	set strSelNA=!strNAname%iChoice%!
	set bSelNAconn=!bNAconn%iChoice%!

	::Turn on the adapter if it is turned off
	if "%bSelNAconn%"=="%langOFF%" (
		call :turnOnOffAdapter %iChoice%
		set bUseTimeout=1
	)

	::Set the address from specified parameters
	if defined bDHCP (
		netsh interface ipv4 set address name="%strSelNA%" source=dhcp
		if !errorlevel!==0 (
			echo %langNow% "%strSelNA%" %langDHCP%
			set bUseTimeout=1
		)
	) else (
		if defined strArgGateway (
			netsh interface ipv4 set address name="%strSelNA%" static %strArgIP% %strArgMask% %strArgGateway%
			if !errorlevel!==0 echo %langNow% "%strSelNA%" %langHasAddress% %strArgIP% ^(%strArgMask%^) %langAndGate% %strArgGateway%.
			
		) else (
			if defined strArgMask (
				netsh interface ipv4 set address name="%strSelNA%" static %strArgIP% %strArgMask%
				if !errorlevel!==0 echo %langNow% "%strSelNA%" %langHasAddress% %strArgIP% ^(%strArgMask%^).
			
			) else (
				netsh interface ipv4 set address name="%strSelNA%" static %strArgIP%
				if !errorlevel!==0 echo %langNow% "%strSelNA%" %langHasAddress% %strArgIP%.
			)
		)
	)
	
	if "%bUseTimeout%"=="1" timeout /t 3 /nobreak>0
	
	call :getAdaptersInfo
	call :showAdaptersList				

	pause
	exit/b
	
:selectToTurnOnOff
	if defined iArgNumberNA (
		set /a iChoice=iArgNumberNA
	) else (
		choice /c !strChoice!0 /n /m "%langSelectOnOff%"
		set /a iChoice=!errorlevel!
	)

	echo.
	if %iChoice% GTR %countNA% exit /b
	call :turnOnOffAdapter %iChoice%
	timeout /t 3 /nobreak>0
	call :getAdaptersInfo
	call :showAdaptersList
	pause
	exit/b

:turnOnOffAdapter [#]
::Turning ON or OFF the adapter
	set strSelNA=!strNAname%1!
	
	if "!bNAconn%1!"=="%langOFF%" (
		echo.%langTurnOn% "%strSelNA%"...
		netsh interface set interface name="%strSelNA%" admin=ENABLE	
		
	) else (
		echo.%langTurnOff% "%strSelNA%"...
		netsh interface set interface name="%strSelNA%" admin=DISABLE
	)

	exit/b
	
:renameNA
	if defined iArgNumberNA (
		set /a iChoice=iArgNumberNA
	) else (	
		call :showAdaptersList
		choice /c !strChoice!0 /n /m "%langSelectRename%"
		set /a iChoice=!errorlevel!
	)
	if %iChoice% GTR %countNA% exit /b
	
	if not defined strArgNewName (
		set/p strArgNewName=%langNewName% "!strNAname%iChoice%!": 
	)
	netsh interface set interface name="!strNAname%iChoice%!" newname="%strArgNewName%"
	call :getAdaptersInfo
	call :showAdaptersList	
	pause
	exit/b
	
:scanSubnet
	call :showAdaptersList
	if defined iArgNumberNA (
		set /a iChoice=iArgNumberNA
	) else (
		choice /c !strChoice!0 /n /m "%langSelectScan%"
		set /a iChoice=!errorlevel!
	)
	echo.
	if %iChoice% GTR %countNA% exit /b
	
	set strSelNAaddress=!strNAaddress%iChoice%!
	
	if "%strSelNAaddress:~-2,1%"=="." (
		set strSubnet=%strSelNAaddress:~0,-2%
	) else (
		if "%strSelNAaddress:~-3,1%"=="." (
			set strSubnet=%strSelNAaddress:~0,-3%
		) else (
			if "%strSelNAaddress:~-4,1%"=="." set strSubnet=%strSelNAaddress:~0,-4%
		)
	)
	set iFound=0
	echo %langScanFrom% %strSubnet%.1 %langTo% %strSubnet%.254...
	
	for /l %%a in (1,1,254) do (
		if "%strSubnet%.%%a" NEQ "%strSelNAaddress%" (
			title %langChecking% %strSubnet%.%%a

			set "strHostName="

			for /f "delims=" %%b in ('ping %strArgScanNames% %strSubnet%.%%a -n 1 -w 100 ^| findstr "[ (0"') do (
				
				for /f %%c in ('echo %%b ^| find /c "["') do (
					if %%c GTR 0 (
						for /f "tokens=%langHostNameToken%" %%d in ("%%b") do (
							set strHostName=^(%%d^)
						)

					)
				)
				
				for /f %%c in ('echo %%b ^| find /c "(0"') do (
					if %%c GTR 0 (
						echo %strSubnet%.%%a %langAnswers%. !strHostName!
						set /a iFound=!iFound!+1
					)
				)
			)
		)
	)

	echo %langFound%: %iFound%
	pause
	exit/b

:getAdaptersInfo
	::Get names of adapters from "show interface" and count them
	set countNA=0
	
	for /f "skip=3 tokens=1,2,3,*" %%a in ('netsh interface show interface') do (
	
		set /a countNA=countNA+1
		
		if /i "%%b"=="Подключен" set bNAconn!countNA!=%langON%
		if /i "%%b"=="Connected" set bNAconn!countNA!=%langON%

		if /i "%%b"=="Отключен" (
			set bNAconn!countNA!=%langOFF%
			if /i "%%a"=="Разрешен" set bNAconn!countNA!=%langCABLE%)
			
		if /i "%%b"=="Disconnected" (
			set bNAconn!countNA!=%langOFF%
			if /i "%%a"=="Enabled"  set bNAconn!countNA!=%langCABLE%)
		
		set strNAname!countNA!=%%d
		set "strNAaddress!countNA!=           "
		set "strNAmask!countNA!=           "
		set "strNAgateway!countNA!=           "
		
		if /i "%strArgNameNA%" == "%%d" set /a iArgNumberNA=!countNA!
	)
	
	if !countNA! GTR 35 set countNA=35
		
	::Get the info about disconnected adapters from "ipv4 dump"
	for /f "tokens=3,4,5*" %%a in ('netsh interface ipv4 dump') do (
	
		for /l %%x in (1,1,!countNA!) do (
		
			if "%%b" == "interface="!strNAname%%x!"" ( 
				for /f "tokens=2* delims==" %%z in ("%%c") do set strNAgateway%%x=%%z
			)
			
			if "%%a" == "name="!strNAname%%x!"" (
				set strNAtype%%x=static
				for /f "tokens=2* delims==" %%z in ("%%b") do set strNAaddress%%x=%%z
				for /f "tokens=2* delims==" %%z in ("%%c") do set strNAmask%%x=%%z
			)
		)
	)

	::Get the info about connected adapters from "show addresses"
	for /l %%x in (1,1,!countNA!) do (
	
		if "!strNAtype%%x!"=="" set strNAtype%%x=DHCP
		
		for /f "usebackq tokens=1-5 delims= " %%a in (`netsh interface ipv4 show addresses name^="!strNAname%%x!"`) do (
		
			if /i "%%a"=="DHCP" if "%%c"=="Да" set strNAtype%%x=DHCP
			if /i "%%a"=="DHCP" if "%%c"=="Нет" set strNAtype%%x=static
			if /i "%%a"=="DHCP" if "%%c"=="Yes" set strNAtype%%x=DHCP
			if /i "%%a"=="DHCP" if "%%c"=="No" set strNAtype%%x=static
			if /i "%%b"=="шлюз:" set strNAGateway%%x=%%c
			if /i "%%b"=="Gateway:" set strNAGateway%%x=%%c
			if /i "%%a"=="IP-адрес" set strNAaddress%%x=%%b
			if /i "%%a"=="IP" set strNAaddress%%x=%%c
			if /i "%%a"=="Subnet" (
				set strNAmask=%%e
				set strNAmask%%x=!strNAmask:~0,-1!
			)
			if /i "%%b"=="подсети:" (
				set strNAmask=%%e
				set strNAmask%%x=!strNAmask:~0,-1!
			)
		)
	)
	exit/b
	
:showAdaptersList
	::show dialog to select an adapter
	set strChoice=
	set strLetters=abcdefghijklmnopqrstuvwxyz
	echo.
	echo  %langColumns%
	
	for /l %%x in (1,1,!countNA!) do (
		
		if %%x GEQ 10 (
			set /a iOffset=%%x-10
			for /f %%z in ("!iOffset!") do set strSymbol=!strLetters:~%%z,1!
			
		) else (
			set strSymbol=%%x
		)
			
		set strChoice=!strChoice!!strSymbol!
		
		echo [!strSymbol!]=!bNAconn%%x! !strNAtype%%x!	!strNAaddress%%x!	!strNAmask%%x!	!strNAgateway%%x!	!strNAname%%x!
	)
	echo.
	exit/b
	
:convertPrefixToMask [prefix]
::Transform a prefix length to a mask
	if "%1" == "0"  set strArgMask=0.0.0.0
	if "%1" == "31" set strArgMask=255.255.255.254
	if "%1" == "32" set strArgMask=255.255.255.255
	
	if defined strArgMask exit/b
	
	set strMasks=128.0.0.0 192.0.0.0 224.0.0.0 240.0.0.0 248.0.0.0 252.0.0.0 254.0.0.0 255.0.0.0 255.128.0.0 255.192.0.0
	set strMasks=%strMasks% 255.224.0.0 255.240.0.0 255.248.0.0 255.252.0.0 255.254.0.0 255.255.0.0 255.255.128.0 255.255.192.0
	set strMasks=%strMasks% 255.255.224.0 255.255.240.0 255.255.248.0 255.255.252.0 255.255.254.0 255.255.255.0 255.255.255.128
	set strMasks=%strMasks% 255.255.255.192 255.255.255.224 255.255.255.240 255.255.255.248 255.255.255.252
	for /f "tokens=%1" %%a in ("%strMasks%") do set strArgMask=%%a

	exit/b

:isNumber [arg]
::returns 1 if arg is number else 0
	set iResult=1
	for /f "tokens=1 delims=0123456789" %%x in ("%~1") do set iResult=0
	if %iResult% == 1 exit /b 1
	exit /b 0

:showHelp
	echo. ip address[/prefix] [mask] [gateway]^│auto^│dhcp^│rename^│scan [names]^│list [#/name]
	echo.
	echo. %langHelp1%
	echo. %langHelp2%
	echo. %langHelp3%
	echo. %langHelp4%
	echo. %langHelp5%
	echo. %langHelp6%
	echo.
	echo. %langHelp7%
	echo. ip auto
	echo. ip 192.168.0.10
	echo. ip 192.168.0.10^/24
	echo. ip 192.168.0.10 255.255.255.0 192.168.0.1
	exit/b

:LangRUS
	set "langWarn1=^│                       ВНИМАНИЕ.                            ^│"
	set "langWarn2=^│ Скрипт был скопирован в системную директорию ^(%windir%^). ^│"
	set "langWarn3=^│ Теперь запуск скрипта возможен из любой командой строки.   ^│"
	set "langHelp1=^/prefix	Задать маску подсети в виде длины префикса сети."
	set "langHelp2=auto или dhcp	Включить автоматическое назначение адреса от DHCP-сервера."
	set "langHelp3=rename		Переименовать сетевой адаптер."
	set "langHelp4=scan		Сканировать адреса в подсети. scan names выведет имена хостов (долго)."
	set "langHelp5=list		Вывести список сетевых адаптеров."
	set "langHelp6=#/name		Выбор адаптера по его # или имени (можно указать в любом месте строки)."
	set "langHelp7=Примеры:"
	set "langSelectOnOff=Введите # адаптера, чтобы включить или отключить его (0 для отмены): "
	set "langSelectRename=Введите # адаптера, который следует переименовать (0 для отмены): "
	set "langSelectScan=Введите # адаптера для сканирования его подсети (0 для отмены): "
	set "langSelectApply=Введите # адаптера для применения параметров (0 для отмены): "
	set "langNewName=Введите новое имя для"
	set "langNow=Для"
	set "langDHCP=включен режим DHCP."
	set "langHasAddress=назначен адрес"
	set "langAndGate=и шлюз"
	set "langTurnOn=Включение"
	set "langTurnOff=Отключение"
	set "langHostNameToken=4"
	set "langScanFrom=Сканирование адресов с"
	set "langTo=до"
	set "langChecking=Проверка"
	set "langFound=Найдено"
	set "langAnswers=отвечает"
	set "langON=ВКЛ "
	set "langOFF=ОТКЛ"
	set "langCABLE=Кабл"
	set "langColumns=#  Реж. Тип	Адрес		Маска		Шлюз		Название"
	exit/b
	
:LangENG
	set "langWarn1=^│                       WARNING.                             ^│"
	set "langWarn2=^│ Script file was copied to the system folder ^(%windir%^).  ^│"
	set "langWarn3=^│ Now the script could be run from any command line.         ^│"
	set "langHelp1=^/prefix	Set a mask in the form of a network prefix length."
	set "langHelp2=auto or dhcp	Enable getting the address from a DHCP-server."
	set "langHelp3=rename		Rename the adapter."
	set "langHelp4=scan		Scan addresses in the subnet. scan names will print hostnames (slow)."
	set "langHelp5=list		Display the list of adapters."
	set "langHelp6=#/name		Select the adapter by its # or name (at any place in the line)."
	set "langHelp7=Examples:"
	set "langSelectOnOff=Select # of the adapter to turn it ON or OFF (0 - cancel): "
	set "langSelectRename=Select # of the adapter to rename it (0 - cancel): "
	set "langSelectScan=Select # of the adapter to scan its subnet (0 - cancel): "
	set "langSelectApply=Select # of the adapter to apply new parameters (0 - cancel): "
	set "langNewName=Enter a new name for"
	set "langNow=Now"
	set "langDHCP=is in DHCP mode."
	set "langHasAddress=has address"
	set "langAndGate=and gateway"
	set "langTurnOn=Turning on"
	set "langTurnOff=Turning off"
	set "langHostNameToken=2"
	set "langScanFrom=Scanning addresses from"
	set "langTo=to"
	set "langChecking=Checking"
	set "langFound=Found"
	set "langAnswers=answers"
	set "langON=ON  "
	set "langOFF=OFF "
	set "langCABLE=Cabl"
	set "langColumns=#  Mode Type	Address		Mask		Gateway		Name"
	exit/b
