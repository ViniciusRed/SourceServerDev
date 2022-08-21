@echo off
echo --[For more information enter https://github.com/ViniciusRed/SourceServerDev]--
setlocal
for /f "delims==; tokens=1,2 eol=;" %%G in (config.cfg) do set %%G=%%H
title Install Counter Strike Source Offensive
call :ChangeLog
call :Check
call :Clear
pause
exit /b

:Install_CsWarzone
call :BinBkp
call :Download_Resources
call :Download
call :Install_Resources
timeout 3 >> %temp%\InstallLog.txt
if exist "%CsSoFile%" (
  echo File CsSo exist [Yes] 
) else (
  echo File CsSo exist [No]
  call :Install_CsWarzone
)
goto :eof

:Install_Launcher
call :BinBkp
call :Download_Resources
call :Download
call :Install_Resources
timeout 3 >> %temp%\InstallLog.txt
if exist "%CsSoFile%" (
  echo File CsSo exist [Yes] 
) else (
  echo File CsSo exist [No]
  call :Install_Launcher
)
goto :eof

:Install_Steam
call :BinBkp
call :Download_Resources
call :Download
call :Install_Resources
timeout 3 >> %temp%\InstallLog.txt
if exist "%CsSoFile%" (
  echo File CsSo exist [Yes] 
) else (
  echo File CsSo exist [No]
  call :Install_Steam
)
goto :eof

:BkpSteam
md %SteamBkp%\BinBkp
md %SteamBkp%\BinBkp\Bin_Cstrike
Xcopy %SteamBkp%\Bin %SteamBkp%\BinBkp\Bin_Cstrike /E /H /C /I >> %temp%\InstallLog.txt
pause
goto :eof

:BkpWarzone
md %WarzoneBkp%\BinBkp
md %WarzoneBkp%\BinBkp\Bin_Cstrike
Xcopy %WarzoneBkp%\Bin %WarzoneBkp%\BinBkp\Bin_Cstrike /E /H /C /I >> %temp%\InstallLog.txt
pause
goto :eof

:BkpLauncher
md %LauncherBkp%\BinBkp
md %LauncherBkp%\BinBkp\Bin_Cstrike
Xcopy %LauncherBkp%\Bin %LauncherBkp%\BinBkp\Bin_Cstrike /E /H /C /I >> %temp%\InstallLog.txt
pause
goto :eof

:BinBkp
title BkpBin
echo [BkpBin]
if exist %SteamBkp%\BinBkp (
  echo BinBkp Steam [Yes]
) else (
  call :BkpSteam
)
if exist %CSWarzone%\BinBkp (
  echo BinBkp Warzone [Yes] 
) else (
  call :BkpWarzone
)
if exist %Launcher%\BinBkp (
  echo BinBkp 7Launcher [Yes] 
) else (
  call :BkpLauncher
)
goto :eof

:bin_steam
title "Change bin"
echo [Change bin]
echo (1) "Change bin to cstrike"
echo (2) "Change bin to csso"
echo (3) "Exit"
set /p choice=
if %choice% == 1 (
echo test
pause
exit
)
if %choice% == 2 (
  echo test
)
if %choice% == 3 exit

:bin_warzone
title "Change bin"
echo [Change bin]
echo (1) "Change bin to cstrike"
echo (2) "Change bin to csso"
echo (3) "Exit"
set /p choice=
if %choice% == 1 (
echo test
pause
exit
)
if %choice% == 2 (
  echo test
)
if %choice% == 3 exit

:bin_launcher
title "Change bin"
echo [Change bin]
echo (1) "Change bin to cstrike"
echo (2) "Change bin to csso"
echo (3) "Exit"
set /p choice=
if %choice% == 1 (
echo test
pause
exit
)
if %choice% == 2 (
  echo test
)
if %choice% == 3 exit


:CsSo_Installed
title CsSo_Installed
echo [CsSo_Installed]
if exist %Steam%\csso (
  echo Steam CsSo Installed Yes 
  call :bin_steam
) else (
  echo Steam CsSo Installed No
)
if exist %CSWarzone%\csso (
  echo CsWarzone CsSo Installed Yes 
  call :bin_warzone
) else (
  echo CsWarzone CsSo Installed No
)
if exist "%Launcher%\csso" (
  echo 7Launcher CsSo Installed Yes 
  call :bin_launcher
) else (
  echo 7Launcher CsSo Installed No
)
goto :eof

:Install_Resources
title Install_Resources
echo [Install_Resources]
msiexec /i "%temp%\7z(x64).msi" /quiet /norestart /log %temp%\Install_Resources.txt
msiexec /i "%temp%\7z(x86).msi" /quiet /norestart /log %temp%\Install_Resources.txt
goto :oef

:Clear 
rd %temp% /s /q
md %temp%
rd /s /q C:\Windows\SoftwareDistribution
md C:\Windows\SoftwareDistribution

:ChangeLog
%SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %ChangeLog% "%temp%/%Name4%"
echo [ChangeLog:]
type %temp%\ChangeLog.txt
timeout 5 >> %temp%\InstallLog.txt
cls
goto :eof

:Download_Resources
title Download_Resources
echo [Download_Resources in progress]
%SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %zipx86% "%temp%/%Name3%"
%SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %zipx64% "%temp%/%Name2%"
goto :eof

:Download
title Download CsSo
echo [Download CsSo in progress]
%SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %CsSo% "%temp%/%Name%"
goto :eof

:Check
title Check Folder Game
if exist %Steam% (
  echo Folder Cs Source Steam exist [Yes] 
  call :Install_Steam
) else (
  echo Folder Cs Source Steam exist [No]
)
if exist %CSWarzone% (
  echo Folder CsWarzone exist [Yes] 
  call :Install_CsWarzone
) else (
  echo Folder CsWarzone exist [No]
)
if exist %Launcher% (
  echo Folder 7Launcher exist [Yes] 
  call :Install_Launcher
) else (
  echo Folder 7Launcher exist [No]
)
goto :eof