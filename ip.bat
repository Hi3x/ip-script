@echo off
@setlocal enabledelayedexpansion enableextensions
::ip script v.0.5 by @hi3xx

::Get the language from the system
	call :LangENG
	for /f "tokens=3 delims= " %%a in ('reg query "hklm\system\controlset001\control\nls\language" /v Installlanguage') DO (
		if "%%a" == "0419" (
			call :LangRUS
		)
	)
	set strLetters=abcdefghijklmnopqrstuvwxyz

::Copy the script file to %windir%
	if not exist %windir%\ip.bat (
		copy /b /y "%~f0" %windir%\ip.bat>0
		echo.旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
		echo.%langWarn1%
		echo.%langWarn2%
		echo.%langWarn3%
		echo.읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
	)

::Processing script arguments
	set strArg1=%~1

	if /i "%strArg1%" == "" (
		call :Help
		call :List
		call :OnOff
		exit/b
	)

	if /i "%strArg1%" == "auto"   goto DHCP
	if /i "%strArg1%" == "dhcp"   goto DHCP
	if /i "%strArg1%" == "rename" goto Rename
	if /i "%strArg1%" == "scan"   goto Scan
	if /i "%strArg1%" == "list"     (call :List& exit/b)
	if /i "%strArg1:~-1%" == "?"    (call :Help& exit/b)
	if /i "%strArg1:~-4%" == "help" (call :Help& exit/b)
	
	set argAddress=%strArg1%
	
	if "%strArg1:~-2,1%"=="/" (
		set argPrefix=%strArg1:~-1%
		set argAddress=%strArg1:~0,-2%
	)
	
	if "%strArg1:~-3,1%"=="/" (
		set argPrefix=%strArg1:~-2%
		set argAddress=%strArg1:~0,-3%
	)
	
	if defined argPrefix (
		call :subPrefixToMask !argPrefix!
		if "%~2" NEQ "" set argGateway=%~2
		
	) else (
		if "%~2" NEQ "" set argMask=%~2
		if "%~3" NEQ "" set argGateway=%~3
	)

	goto Main

:Help
	echo.
	echo. %langSyntax%: ip address[/prefix]^쿪uto^쿭hcp^쿹ist^퀂can^퀁ename [mask] [gateway]
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

:List
	call :subShowAdaptersList
	exit/b
	
:OnOff
	choice /c !strChoice!0 /n /m "%langSelectOnOff%"
	set /a iChoice=%errorlevel%
	echo.
	if %iChoice% GTR %countNA% exit /b
	call :subOnOffAdapter %iChoice%
	timeout /t 3 /nobreak>0
	call :subShowAdaptersList	
	pause
	exit/b

:Rename
	call :subShowAdaptersList
	choice /c !strChoice!0 /n /m "%langSelectRename%"
	set /a iChoice=%errorlevel%
	echo.
	if %iChoice% GTR %countNA% exit /b
	set/p strNewName=%langNewName% "!strNAname%iChoice%!": 
	netsh interface set interface name="!strNAname%iChoice%!" newname="%strNewName%"
	call :subShowAdaptersList	
	pause
	exit/b
	
:Scan
	call :subShowAdaptersList
	choice /c !strChoice!0 /n /m "%langSelectScan%"
	set /a iChoice=%errorlevel%
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
			for /f %%b in ('ping %strSubnet%.%%a -n 1 -w 100 ^| find /c "(0"') do (
				if %%b GTR 0 (
					echo %strSubnet%.%%a %langAnswers%.
					set /a iFound=!iFound!+1
				)
			)
		)
	)
	echo %langFound%: %iFound%
	pause
	exit/b
	
:DHCP
	set argDHCP=1
	
:Main
	call :subShowAdaptersList

	::Ask which adapter to work with
	choice /c !strChoice!0 /n /m "%langSelectApply%"
	
	set /a iChoice=%errorlevel%
	
	if %iChoice% GTR %countNA% exit /b
	
	set strSelNA=!strNAname%iChoice%!
	set bSelNAconn=!bNAconn%iChoice%!

	::Turn on the adapter if it is turned off
	if "%bSelNAconn%"=="%langOFF%" (
		call :subOnOffAdapter %iChoice%
		set bUseTimeout=1
	)

	::Set the address from specified parameters
	if defined argDHCP (
		netsh interface ipv4 set address name="%strSelNA%" source=dhcp
		if !errorlevel!==0 (
			echo %langNow% "%strSelNA%" %langDHCP%
			set bUseTimeout=1
		)
	) else (
		if defined argGateway (
			netsh interface ipv4 set address name="%strSelNA%" static %argAddress% %argMask% %argGateway%
			if !errorlevel!==0 echo %langNow% "%strSelNA%" %langHasAddress% %argAddress% ^(%argMask%^) %langAndGate% %argGateway%.
			
		) else (
			if defined argMask (
				netsh interface ipv4 set address name="%strSelNA%" static %argAddress% %argMask%
				if !errorlevel!==0 echo %langNow% "%strSelNA%" %langHasAddress% %argAddress% ^(%argMask%^).
			
			) else (
				netsh interface ipv4 set address name="%strSelNA%" static %argAddress%
				if !errorlevel!==0 echo %langNow% "%strSelNA%" %langHasAddress% %argAddress%.
			)
		)
	)
	
	if "%bUseTimeout%"=="1" timeout /t 3 /nobreak>0
	
	call :subShowAdaptersList				

	pause
	exit/b

:subShowAdaptersList
	::Get names of adapters from "show interface" and count them
	set countNA=0
	
	for /f "skip=3 tokens=1,2,3,*" %%a in ('netsh interface show interface') do (
	
		set /a countNA=countNA+1
		
		if /i "%%b"=="룼ㄺヮ曄�" set bNAconn!countNA!=%langON%
		if /i "%%b"=="Connected" set bNAconn!countNA!=%langON%

		if /i "%%b"=="롡か蹟��" (
			set bNAconn!countNA!=%langOFF%
			if /i "%%a"=="맆㏅θ��" set bNAconn!countNA!=%langCABLE%)
			
		if /i "%%b"=="Disconnected" (
			set bNAconn!countNA!=%langOFF%
			if /i "%%a"=="Enabled"  set bNAconn!countNA!=%langCABLE%)
		
		set strNAname!countNA!=%%d
		set "strNAaddress!countNA!=           "
		set "strNAmask!countNA!=           "
		set "strNAgateway!countNA!=           "
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
		
			if /i "%%a"=="DHCP" if "%%c"=="꽑" set strNAtype%%x=DHCP
			if /i "%%a"=="DHCP" if "%%c"=="뜢�" set strNAtype%%x=static
			if /i "%%a"=="DHCP" if "%%c"=="Yes" set strNAtype%%x=DHCP
			if /i "%%a"=="DHCP" if "%%c"=="No" set strNAtype%%x=static
			if /i "%%b"=="獄材:" set strNAGateway%%x=%%c
			if /i "%%b"=="Gateway:" set strNAGateway%%x=%%c
			if /i "%%a"=="IP-젮誓�" set strNAaddress%%x=%%b
			if /i "%%a"=="IP" set strNAaddress%%x=%%c
			if /i "%%a"=="Subnet" (
				set strNAmask=%%e
				set strNAmask%%x=!strNAmask:~0,-1!
			)
			if /i "%%b"=="��ㅱβ�:" (
				set strNAmask=%%e
				set strNAmask%%x=!strNAmask:~0,-1!
			)
		)
	)

	::Display a list of adapters
	set strChoice=
	echo.
	echo  %langTitles%
	
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

:subOnOffAdapter [#]
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

:subPrefixToMask [prefix]
::Transform a prefix length to a mask
	if "%1" == "0" (
		set argMask=0.0.0.0
		exit/b
	)
	if "%1" == "31" (
		set argMask=255.255.255.254
		exit/b
	)
	if "%1" == "32" (
		set argMask=255.255.255.255
		exit/b
	)

	set strMasks=128.0.0.0 192.0.0.0 224.0.0.0 240.0.0.0 248.0.0.0 252.0.0.0 254.0.0.0 255.0.0.0 255.128.0.0 255.192.0.0
	set strMasks=%strMasks% 255.224.0.0 255.240.0.0 255.248.0.0 255.252.0.0 255.254.0.0 255.255.0.0 255.255.128.0 255.255.192.0
	set strMasks=%strMasks% 255.255.224.0 255.255.240.0 255.255.248.0 255.255.252.0 255.255.254.0 255.255.255.0 255.255.255.128
	set strMasks=%strMasks% 255.255.255.192 255.255.255.224 255.255.255.240 255.255.255.248 255.255.255.252
	for /f "tokens=%1" %%a in ("%strMasks%") do set argMask=%%a

	exit/b
	
:LangRUS
	set "langWarn1=^�                       굧닃�뜄�.                            ^�"
	set "langWarn2=^� 뫇黍�� 〓� 稅��ⓣ�쥯� � 歲飡�Л莘 ㄸ誓も�黍� ^(%windir%^). ^�"
	set "langWarn3=^� 뮙��閃 쭬�信� 稅黍��� ¡㎚�┘� �� ヮ‘� ぎ쵟�ㄾ� 飡昔え.   ^�"
	set "langSyntax=뫅��젶歲�"
	set "langHelp1=^/prefix	뇿쩆竣 쵟稅� ��ㅱβ� � ˘ㄵ ㄻÞ� �誓十め� 醒殊."
	set "langHelp2=auto � dhcp	궒젴М쭬Д�畑щ. 궕ヮ�젰� 젪獸쵟殊曄稅��"
	set "langHelp3= 		췅㎛좂��⑨ 젮誓�� �� DHCP-醒舒���."
	set "langHelp4=list		귣¡ㄸ� 召ⓤ�� 醒收�音 젮젽收昔�."
	set "langHelp5=scan		뫇젺ⓣ濕� 젮誓�� � ��ㅱβ�."
	set "langHelp6=rename		룯誓º����猶젰� 醒收¡� 젮젽收�."
	set "langHelp7=뤲º�贍:"
	set "langSelectOnOff=궋ⅳⓥ� # 젮젽收��, 譽�〓 ˚ヮ葉筍 Œ� �洙ヮ葉筍 ⅲ� (0 ㄻ� �燧���): "
	set "langSelectRename=궋ⅳⓥ� # 젮젽收��, ぎ獸贍� 笹ⅳ濕� ��誓º���쥯筍 (0 ㄻ� �燧���): "
	set "langSelectScan=궋ⅳⓥ� # 젮젽收��, ㄻ� 稅젺ⓣ�쥯�⑨ ⅲ� ��ㅱβ� (0 ㄻ� �燧���): "
	set "langSelectApply=궋ⅳⓥ� # 젮젽收�� ㄻ� �黍Д���⑨ 캙�젹β昔� (0 ㄻ� �燧���): "
	set "langNewName=궋ⅳⓥ� ��¡� º� ㄻ�"
	set "langNow=꽞�"
	set "langDHCP=˚ヮ曄� 誓┬� DHCP."
	set "langHasAddress=췅㎛좂�� 젮誓�"
	set "langAndGate=� 獄材"
	set "langTurnOn=궕ヮ曄���"
	set "langTurnOff=롡か蹟����"
	set "langScanFrom=뫇젺ⓣ�쥯��� 젮誓貰� �"
	set "langTo=ㄾ"
	set "langChecking=뤲�´夕�"
	set "langFound=뜝ħ���"
	set "langAnswers=�手η젰�"
	set "langON=굤� "
	set "langOFF=럲뒎"
	set "langCABLE=뒥∥"
	set "langTitles=#  맓�. 뮜�	�ㅰα		뙛稅�		삮材		뜝㎖젺��"
	exit/b
	
:LangENG
	set "langWarn1=^�                       WARNING.                             ^�"
	set "langWarn2=^� Script file was copied to the system folder ^(%windir%^).  ^�"
	set "langWarn3=^� Now the script could be run from any command line.         ^�"
	set "langSyntax=Syntax"
	set "langHelp1=^/prefix	Sets a mask in the form of a network prefix length."
	set "langHelp2=auto and dhcp	Interchangeable. Enables getting"
	set "langHelp3= 		the address from a DHCP-server."
	set "langHelp4=list		Displays the list of adapters."
	set "langHelp5=scan		Scans addresses in the subnet."
	set "langHelp6=rename		Renames the adapter."
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
	set "langScanFrom=Scanning addresses from"
	set "langTo=to"
	set "langChecking=Checking"
	set "langFound=Found"
	set "langAnswers=answers"
	set "langON=ON  "
	set "langOFF=OFF "
	set "langCABLE=Cabl"
	set "langTitles=#  Mode Type	Address		Mask		Gateway		Name"
	exit/b
