@echo off
echo --[For more information enter https://github.com/ViniciusRed/SourceServerDev]--
setlocal
for /f "delims==; tokens=1,2 eol=;" %%G in (config.cfg) do set %%G=%%H
title Install Counter Strike Source Offensive
call :ChangeLog
call :Update
call :Check
call :Clear
pause
exit /b

:Install_CsWarzone
call :Download_Resources
call :Download
call :Install_Resources
timeout 3 > %temp%\InstallLog.txt
if exist "%CsSoFile%" (
  echo File CsSo exist [Yes] 
  call :Install_Steam
) else (
  echo File CsSo exist [No]
)
goto :eof
:Install_Launcher
call :Download_Resources
call :Download
call :Install_Resources
timeout 3 > %temp%\InstallLog.txt
if exist "%CsSoFile%" (
  echo File CsSo exist [Yes] 
  call :Install_Steam
) else (
  echo File CsSo exist [No]
)
goto :eof
:Install_Steam
call :Download_Resources
call :Download
call :Install_Resources
timeout 3 > %temp%\InstallLog.txt
if exist "%CsSoFile%" (
  echo File CsSo exist [Yes] 
  call :Install_Steam
) else (
  echo File CsSo exist [No]
)
goto :eof

:Update
title Update InstallCsSo
echo [Update InstallCsSo]
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
type %temp%\ChangeLog.txt
timeout 5 > %temp%\InstallLog.txt
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
if exist "%Steam%" (
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
if exist "%Launcher%" (
  echo Folder 7Launcher exist [Yes] 
  call :Install_Launcher
) else (
  echo Folder 7Launcher exist [No]
)
goto :eof