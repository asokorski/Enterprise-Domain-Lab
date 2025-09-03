@echo off
:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as administrator.
    timeout /t 5 >nul
    exit /b
)

echo Enabling virtualization features...
dism /Online /Enable-Feature /FeatureName:VirtualMachinePlatform /All /NoRestart
dism /Online /Enable-Feature /FeatureName:HypervisorPlatform /All /NoRestart
echo Setting hypervisorlaunchtype to Auto...
bcdedit /set {default} hypervisorlaunchtype Auto
echo.

for /l %%i in (5,-1,1) do (
    echo Restarting in %%i...
    timeout /t 1 >nul
)

echo Restarting now into Advanced Startup (to pick Hyper‑V Enabled entry)...
shutdown /r /o /t 0
