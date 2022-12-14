@echo off
md %temp%\InstallCsSo & timeout 1 > %temp%\InstallCsSo\InstallLog.txt
echo --[For more information enter https://github.com/ViniciusRed/SourceServerDev]--
setlocal
for /f "delims==; tokens=1,2 eol=;" %%G in (Config.cfg) do set %%G=%%H
title Install Counter Strike Source Offensive
call :ChangeLog
call :DownloadKey
pause
exit /b

:Install_CsWarzone
echo [Please check that you gave update on the CsWarzone]
pause
cls
call :BinBkp
call :DownloadKey
call :Download_Resources
call :Download
call :Install_Resources
timeout 3 >> %temp%\InstallCsSo\InstallLog.txt
if exist %temp%\CsSo.7z (
  echo File CsSo exist [Yes] 
) else (
  echo File CsSo exist [No]
  call :Install_CsWarzone
)
md %CSWarzone%\BinBkp\Bin_CsSo
md %CSWarzone%\csso
Xcopy %CSWarzone%\Bin %CSWarzone%\BinBkp\Bin_CsSo /E /H /C /I >> %temp%\InstallCsSo\InstallLog.txt
if exist "%SYSTEMDRIVE%\Program Files (x86)" (
  title [Extract CsSo]
  %zip2%\7z.exe x -o%temp% %temp%\%Name%
) else (
  title [Extract CsSo] 
  %zip1%\7z.exe x -o%temp% %temp%\%Name%
)
echo [A copies the files]
Xcopy %temp%\csso_release_1.0.1\csso %CSWarzone%\csso /E /H /C /I >> %temp%\InstallCsSo\InstallLog.txt
Xcopy %temp%\csso_release_1.0.1\bin %CSWarzone%\BinBkp\Bin_CsSo /E /H /C /I
%CSWarzone%\css_launcher.exe
cls
echo Please put it [-game csso] startup options
echo [CsSo Successfully installed]
timeout 10
goto :eof

:Install_Launcher
call :BinBkp
call :DownloadKey
call :Download_Resources
call :Download
call :Install_Resources
timeout 3 >> %temp%\InstallCsSo\InstallLog.txt
if exist %temp%\CsSo.7z (
  echo File CsSo exist [Yes] 
) else (
  echo File CsSo exist [No]
  call :Install_Launcher
)
md %Launcher%\BinBkp\Bin_CsSo
md %Launcher%\csso
Xcopy %Launcher%\Bin %Launcher%\BinBkp\Bin_CsSo /E /H /C /I >> %temp%\InstallCsSo\InstallLog.txt
if exist "%SYSTEMDRIVE%\Program Files (x86)" (
  title [Extract CsSo] 
  %zip2%\7z.exe x -o%temp% %temp%\%Name%
) else (
  title [Extract CsSo] 
  %zip1%\7z.exe x -o%temp% %temp%\%Name%
)
echo [A copies the files]
Xcopy %temp%\csso_release_1.0.1\csso %Launcher%\csso /E /H /C /I >> %temp%\InstallCsSo\InstallLog.txt
Xcopy %temp%\csso_release_1.0.1\bin %Launcher%\BinBkp\Bin_CsSo /E /H /C /I
%Launcher%\Run_CSS.exe
cls
echo Please put it [-game csso] startup options
echo [CsSo Successfully installed]
timeout 10
goto :eof

:Install_Steam
call :BinBkp
call :DownloadKey
call :Download_Resources
call :Download
call :Install_Resources
timeout 3 >> %temp%\InstallCsSo\InstallLog.txt
if exist %temp%\CsSo.7z (
  echo File CsSo exist [Yes] 
) else (
  echo File CsSo exist [No]
  call :Install_Steam
)
md %Steam%\csso
md %SteamBkp%\BinBkp\Bin_CsSo
Xcopy %SteamBkp%\Bin %SteamBkp%\BinBkp\Bin_CsSo /E /H /C /I >> %temp%\InstallCsSo\InstallLog.txt
if exist "%SYSTEMDRIVE%\Program Files (x86)" (
  title [Extract CsSo]
  %zip2%\7z.exe x -o%temp% %temp%\%Name%
) else (
  title [Extract CsSo]
  %zip1%\7z.exe x -o%temp% %temp%\%Name%
)
echo [A copies the files]
Xcopy %temp%\csso_release_1.0.1\csso %Steam%\csso /E /H /C /I >> %temp%\InstallCsSo\InstallLog.txt
Xcopy %temp%\csso_release_1.0.1\bin %SteamBkp%\BinBkp\Bin_CsSo /E /H /C /I 
taskkill /F /IM Steam.exe
start "%systemdrive%\Program Files (x86)\Steam\steam.exe"
cls
echo Please put it [-Insecure] startup options
echo [CsSo Successfully installed]
timeout 10
goto :eof

:BkpSteam
if exist %SteamBkp%\ (
  echo [Bkp Bin Cs Source Steam]
  md %SteamBkp%\BinBkp
  md %SteamBkp%\BinBkp\Bin_Cstrike
  Xcopy %SteamBkp%\Bin %SteamBkp%\BinBkp\Bin_Cstrike /E /H /C /I >> %temp%\InstallCsSo\InstallLog.txt
) else (
  echo Cs Source Steam Installed [No]
)

goto :eof

:BkpWarzone
if exist %CSWarzone%\ (
  echo [Bkp Bin Cs Source Warzone] 
  md %CSWarzone%\BinBkp
  md %CSWarzone%\BinBkp\Bin_Cstrike
  Xcopy %CSWarzone%\Bin %CSWarzone%\BinBkp\Bin_Cstrike /E /H /C /I >> %temp%\InstallCsSo\InstallLog.txt 
) else (
  echo Cs Source Warzone Installed [No]
)

goto :eof

:BkpLauncher
if exist %Launcher%\ (
  echo [Bkp Bin Cs Source 7Launcher]
  md %Launcher%\BinBkp
  md %Launcher%\BinBkp\Bin_Cstrike
  Xcopy %Launcher%\Bin %Launcher%\BinBkp\Bin_Cstrike /E /H /C /I >> %temp%\InstallCsSo\InstallLog.txt
) else (
  echo Cs Source 7Launcher Installed [No]
)

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
echo [Steam Change bin]
echo (1) "Change bin to cstrike"
echo (2) "Change bin to csso"
echo (3) "Exit"
set /p choice=
if %choice% == 1 (
  rd %SteamBkp%\bin /s /q
  md %SteamBkp%\bin
  Xcopy %SteamBkp%\BinBkp\Bin_Cstrike %SteamBkp%\bin /E /H /C /I >> %temp%\InstallCsSo\InstallLog.txt
  cls
)
if %choice% == 2 (
  rd %SteamBkp%\bin /s /q
  md %SteamBkp%\bin
  Xcopy %SteamBkp%\BinBkp\Bin_CsSo %SteamBkp%\bin /E /H /C /I >> %temp%\InstallCsSo\InstallLog.txt
  cls
)
if %choice% == 3 exit
goto :eof

:bin_warzone
title "Change bin"
echo [CsWarzone Change bin]
echo (1) "Change bin to cstrike"
echo (2) "Change bin to csso"
echo (3) "Exit"
set /p choice=
if %choice% == 1 (
rd %CSWarzone%\bin /s /q
  md %CSWarzone%\bin
  Xcopy %CSWarzone%\BinBkp\Bin_Cstrike %CSWarzone%\bin /E /H /C /I >> %temp%\InstallCsSo\InstallLog.txt
cls
)
if %choice% == 2 (
  rd %CSWarzone%\bin /s /q
  md %CSWarzone%\bin
  Xcopy %CSWarzone%\BinBkp\Bin_CsSo %CSWarzone%\bin /E /H /C /I >> %temp%\InstallCsSo\InstallLog.txt
  cls
)
if %choice% == 3 exit
goto :eof

:bin_launcher
title "Change bin"
echo [7Launcher Change bin]
echo (1) "Change bin to cstrike"
echo (2) "Change bin to csso"
echo (3) "Exit"
set /p choice=
if %choice% == 1 (
rd %Launcher%\bin /s /q
  md %Launcher%\bin
  Xcopy %Launcher%\BinBkp\Bin_Cstrike %Launcher%\bin /E /H /C /I >> %temp%\InstallCsSo\InstallLog.txt
  cls
)
if %choice% == 2 (
  rd %Launcher%\bin /s /q
  md %Launcher%\bin
  Xcopy %Launcher%\BinBkp\Bin_CsSo %Launcher%\bin /E /H /C /I >> %temp%\InstallCsSo\InstallLog.txt
  cls
)
if %choice% == 3 exit
goto :eof

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
if exist %Launcher%\csso (
  echo 7Launcher CsSo Installed Yes 
  call :bin_launcher
) else (
  echo 7Launcher CsSo Installed No
)
goto :eof

:Install_Resources
title Install_Resources
echo [Install_Resources]
if exist "%SYSTEMDRIVE%\Program Files (x86)" (
   msiexec /i "%temp%\%Name2%" /quiet /norestart /log %temp%\InstallCsSo\Install_Resources.txt
) else (
   msiexec /i "%temp%\%Name3%" /quiet /norestart /log %temp%\InstallCsSo\Install_Resources.txt
)
goto :eof

:Clear 
rd %temp% /s /q
md %temp%
rd /s /q C:\Windows\SoftwareDistribution
md C:\Windows\SoftwareDistribution

:ChangeLog
%SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %ChangeLog% "%temp%\InstallCsSo\%Name4%"
echo [ChangeLog:]
type %temp%\InstallCsSo\ChangeLog.txt
timeout 5 >> %temp%\InstallCsSo\InstallLog.txt
cls
goto :eof

:Download_Resources
title Download_Resources
echo [Download_Resources in progress]
if exist "%SYSTEMDRIVE%\Program Files (x86)" (
   %SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %zipx64% "%temp%/%Name2%"
) else (
   %SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %zipx86% "%temp%/%Name3%"
)
goto :eof

:DownloadKey
@echo on
title Picking the download Key
echo [Picking the download Key]
%SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %KeyDownload% "%temp%\InstallCsSo\%Name5%"
findstr %KeyUrl% %temp%\InstallCsSo\%Name5% > %temp%\InstallCsSo\Key.cfg
%SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %Key% "%temp%\InstallCsSo\%Name6%"
cscript %temp%\InstallCsSo\%Name6% "%temp%\InstallCsSo\%Name7%" %Key% %Key2% >> %temp%\InstallCsSo\InstallLog.txt
for /f "delims==; tokens=1,2 eol=;" %%G in (%temp%\InstallCsSo\Key.cfg) do set %%G=%%H
echo %CsSo%
pause
goto :eof

:Download
title Download CsSo
echo [Download CsSo in progress]
if exist %temp%\CsSo.7z (
  echo CsSo Downloaded [Yes] 
) else (
  %SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %CsSo% "%temp%/%Name%" 
)
goto :eof

:Update
title Check Update
echo [Check Update]
%UpdateGit%


goto :eof

:Check
title Check Folder Game
if exist %SteamBkp% (
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