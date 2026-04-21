@echo off
wt new-tab --title "Site" cmd /k "cd /d "%~dp0site" && npx serve" ^
; new-tab --title "API" cmd /k "cd /d "%~dp0api" && php -S 0.0.0.0:8000" ^
; new-tab --title "CMS" cmd /k "cd /d "%~dp0CMS" && dotnet watch run"
