@echo off
echo --[For more information enter https://github.com/ViniciusRed/SourceServerDev]--
setlocal
for /f "delims==; tokens=1,2 eol=;" %%G in (config.cfg) do set %%G=%%H
Title Cs Source Server

goto Check
goto Check Server
goto Update
goto Download
goto InstallServer