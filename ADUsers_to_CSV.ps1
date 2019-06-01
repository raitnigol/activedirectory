<# 
.SYNOPSIS
    Description on how this script works.
.DESCRIPTION
    This script is made for System Administrators looking to import
    tons of accounts in one go. You need to use Windows Server and
    have Active Directory installed on your domain.
.NOTES
    File Name       : ADUsers_to_CSV.ps1
    Author          : Rait Nigol (rait.nigol@khk.ee)
    Prerequisites   : Powershell V2 and atleast Windows Server 2008 R2.
    Copyright 2019  - Rait Nigol/Tartu Kutsehariduskeskus
.LINK
    This script is uploaded to my github repository:
    https://github.com/raitnigol/activedirectory
.EXAMPLE
    The CSV file example is in the GitHub directory but feel free to
    change the code according to your will.

    You have free hands on making any updates and changes to this code as 
    this is open source and I want to make your life easier.
#>

<#  
    Import the active directory module
    On error, show error message and store the error in C:\CSV\errors.txt
#>

Try {
    # try to import the module
    Start-Sleep -s 1
    Import-Module activedirectory
}
Catch {
    # on error
    Import-Module activedirectory 2>> C:\CSV\errors.txt
    Write-Warning "Something went wrong, can't import the module."
    Write-Warning "Error saved to C:\CSV\errors.txt"
    Start-Sleep -s 4
    Exit
}

<#
    If the code succeeds, we will import the CSV file
    from the usen given location.
#>
$csv = Read-Host -Prompt "Please input the path for the CSV file (drag the file here): "

$users = Import-Csv $csv

# define variables for each user in CSV file.
ForEach ($user in $users)
{
    $Firstname = $($user.firstname)
    $Lastname = $($user.lastname)
    $Username = $($user.username).ToLower()
    $jobtitle = $($user.jobtitle)
    $domain = $($user.domain)
    $email = $($user.email).ToLower()
    $Password = $($user.password)
    $principalname = $($user.principalname)
    $OU = $($user.ou)

<#
    If you want to sort the OU-s, use this piece of code:

    if ($jobtitle -eq "your job title") {
        $OU = $("OU=YOUR OU")
        }
    
    if ($jobtitle -eq "Tyour job title") {
        $OU = $("OU=YOUR OU")
        }

    if ($jobtitle -eq "your job title") {
        $OU = $("OU=YOUR OU")
        }

    if ($jobtitle -eq "your job title") {
        $OU = $("OU=YOUR OU")
        }
#>

    if (Get-ADUser -F {SamAccountName -eq $Username})
    {
    # if user exists, we show a warning.
        Write-Warning "User $Username (role: $jobtitle) already exists inActive Directory!"
    }
    else
    {
        # if user doesn't exist, we generate one
        New-ADUser -SamAccountName $Username -UserPrincipalName $principalname -Name "$Firstname $Lastname" -GivenName $Firstname -Surname $Lastname -Enabled $True -DisplayName "Lastname, $Firstname" -Path $OU -EmailAddress $email -Title $jobtitle -Department $jobtitle -ChangePasswordAtLogon $True -AccountPassword (convertto-securestring $Password -AsPlainText -Force)
    }

}
