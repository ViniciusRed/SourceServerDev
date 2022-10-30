@echo off
setlocal
for /f "delims==; tokens=1,2 eol=;" %%G in (readme.md) do set %%G=%%H
echo %image%
pause