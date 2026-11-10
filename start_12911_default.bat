@echo off
"D:\server2\cfx//FXServer.exe" +set serverProfile "default"
pause

wmic process get Name >nul 2>&1