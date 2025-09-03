@echo off
:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as administrator.
    timeout /t 5 >nul
    exit /b
)

echo Disabling virtualization features...
dism /Online /Disable-Feature /FeatureName:VirtualMachinePlatform /NoRestart
dism /Online /Disable-Feature /FeatureName:HypervisorPlatform /NoRestart
echo Setting hypervisorlaunchtype to Off for No‑Hyper‑V entry...
bcdedit /set {boot-entry-number} hypervisorlaunchtype off
echo.

for /l %%i in (5,-1,1) do (
    echo Restarting in %%i...
    timeout /t 1 >nul
)

echo Restarting now into Advanced Startup (to pick Hyper‑V Enabled entry)...
shutdown /r /o /t 0
