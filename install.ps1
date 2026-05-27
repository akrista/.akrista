#!/usr/bin/env bash

function REM() { return; }
REM @'
REM '; : << "BASH"
BASH

echo "Unix: Bourne-Shell"
echo -e "\nCount to 10:\n"

for i in {1..10}; do
        echo "Count $i"
done

exit
'@

Write-Host "Windows: Powershell"
Write-Host "`r`nCount to 10:`r`n"

for ($i=1; $i -le 10; $i++) {
    Write-Host "Count $i"
}
