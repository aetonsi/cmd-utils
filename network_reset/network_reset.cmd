@echo off

echo :: release IP address on the active adapters
ipconfig /release

echo :: purge DNS resolver cache
ipconfig /flushdns

echo :: renew IP address on the active adapters
ipconfig /renew

echo :: reset winsock catalog to a clean state
netsh winsock reset

echo :: reset ipv4 interface information
netsh interface ipv4 reset

echo :: reset ipv6 interface information
netsh interface ipv6 reset

echo :: flushes the destination cache
netsh interface ip delete destinationcache

echo PLEASE RESTART YOUR DEVICE
pause