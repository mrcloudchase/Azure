$shareSrcPrivIP = "<private_ip_of_share_host>"
$shareName = "<share_name>
$sharePath = "\\$shareSrcPrivIP\$shareName"
$localUserName = "<local_username>"
$localUserPassword = "<local_user_passwd>"

$storageAccountName = "<storage_account_name>"
$storageAccountKey = "<storage_account_key>"
$sasToken = '<sas_token>'
$sasToken = $sasToken.Replace("&", "`"&`"")
$storageAccountFQDN = "$storageAccountName.file.core.windows.net"
$storageAccountPrivateIP = "<private_ip_of_stg_acct_private_endpoint>"
$storageAccountFQDNEntry = "$storageAccountPrivateIP $storageAccountFQDN"
$hostsFile = "$env:windir\system32\drivers\etc\hosts"
$hostsFileContent = Get-Content -Path $hostsFile
$hostsFileContent | Where-Object { $_ -ne $storageAccountFQDNEntry } | Set-Content -Path $hostsFile
Add-Content -Path $hostsFile -Value $storageAccountFQDNEntry



Invoke-WebRequest -Uri "https://aka.ms/downloadazcopy-v10-windows" -OutFile "$env:USERPROFILE\Downloads\azcopy.zip"
Expand-Archive -Path "$env:USERPROFILE\Downloads\azcopy.zip" -DestinationPath "$env:USERPROFILE\Downloads\" -Force

$azCopyDirPath = (Get-ChildItem -Path "$env:USERPROFILE\Downloads\" -Recurse -Filter "azcopy.exe" | Select-Object -First 1).DirectoryName
$azCopyPath = "$azCopyDirPath\azcopy.exe"

$testConn = Test-NetConnection -ComputerName $shareSrcPrivIP -Port 445
if ($testConn.TcpTestSucceeded) {
    $driveY = (Get-PSDrive).Name | Where-Object { $_ -eq "Y" }

    if ($driveY) {
        Write-Host "The Y: drive is already mounted. Please unmount the drive and try again. Use the command 'net use Y: /delete /y' to unmount the drive."
        exit
    }

    cmd.exe /C "cmdkey /add:`"$shareSrcPrivIP`" /user:`"$localUserName`" /pass:`"$localUserPassword`""
    New-PSDrive -Name Y -PSProvider FileSystem -Root $sharePath -Persist
    
    $winShareFolders = Get-ChildItem -Path Y:\ -Directory | Select-Object Name
    $counter = 0

    foreach ($winFolderName in $winShareFolders) {

        $counter++
        $winFolderName = $winFolderName.Name
        $azFilesShareName = $winFolderName.ToLower()

        Write-Host "Local Share Folder: $winFolderName"
        Write-Host "Creating Azure Files share named: $azFilesShareName"
    
        Invoke-Expression -Command "$azCopyPath make https://$storageAccountName.file.core.windows.net/$azFilesShareName$sasToken"
    
        $connectTestResult = Test-NetConnection -ComputerName "$storageAccountName.file.core.windows.net" -Port 445
        if ($connectTestResult.TcpTestSucceeded) {
            $driveZ = (Get-PSDrive).Name | Where-Object { $_ -eq "Z" }

            if ($driveZ) {
                Write-Host "The Z: drive is already mounted. Please unmount the drive and try again. Use the command 'net use Z: /delete /y' to unmount the drive."
                exit
            }

            Write-Host "Mounting Azure Files share named: $azFilesShareName to Z: drive"

            cmd.exe /C "cmdkey /add:`"$storageAccountName.file.core.windows.net`" /user:`"localhost\$storageAccountName`" /pass:`"$storageAccountKey`""
            New-PSDrive -Name Z -PSProvider FileSystem -Root "\\$storageAccountName.file.core.windows.net\$azFilesShareName" -Persist

            robocopy.exe Y:\$winFolderName Z:\ /E /COPYALL /Z /R:3 /W:1 /MT:32 /TEE /log+:"$env:USERPROFILE\robocopy.log"
            
            Write-Host "Copying: local folder $winFolderName -> cloud share $azFilesShareName"
            Write-Host ""

            Write-Host "Unmounting Azure File share named: $azFilesShareName from Z: drive"
            Remove-PSDrive -Name Z -ErrorAction SilentlyContinue | Out-Null
            #net use Z: /delete | Out-Null
        
        }
        else {
            Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
        }   
    }
}
else {
    Write-Error -Message "Unable to reach the Windows File Share device via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN"
}
Write-Host "Unmounting local file share from Y:"
Remove-PSDrive -Name Y -ErrorAction SilentlyContinue | Out-Null
#net use Y: /delete | Out-Null
