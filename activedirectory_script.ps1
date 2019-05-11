﻿<# 
.SYNOPSIS
    Lühikirjeldus sellest, kuidas skript töötab.
.DESCRIPTION
    See skript on tehtud Windows Operatsioonisüsteemide tunni raames.
    See skript aitab süsteemiadministraatoril csv faili abil importida
    andmed skripti ning seejärel teha suures koguses kasutajaid kasutades
    Windows Serveri Active Directory rolli.
.NOTES
    Faili Nimi      : activedirectory_script.ps1
    Autor           : Rait Nigol (rait.nigol@khk.ee)
    Eeltingimused   : Powershell V2 ja vähemalt Windows Server 2008 R2.
    Copyright 2019  - Rait Nigol/Tartu Kutsehariduskeskus
.LINK
    Skript on üleslaetud GitHubi:
    https://github.com/raitnigol/activedirectory
.EXAMPLE
    CSV tabel peab olema järgneval kujul:
    EESNIMI PEREKONNANIMI ROLL
    Rait    Nigol         IT
    Seda sellepärast, et skript töötab antud hetkel ainult nende pealkirjade järgi.
    Neid on alati võimalik muuta vastavalt oma soovile ning skripti laiet haarendada.
    Kasutades skripti väljastatakse tulemus $eesnimi.$perekonnanimi $roll
    ehk Rait.Nigol IT.
#>

# Importime kõigepealt activedirectory mooduli, et skript üldse töötaks.
# kui skripti ei jooksutata Windows Serveri peal, millel oleks Active Directory olemas,
# võib see koodijupp errorit visata.
# Seega peame alguses proovima, kas moodulit on võimalik importida ning kui ei ole,
# püütakse error kinni ning talletatakse tekstifailis errors.txt, mis asub töölaual.
$module = $("activedirectory")
Try {
    Start-Sleep -s 1
    Import-Module $module 
}
Catch {
    # kui kood lööb errorit, väljastatakse veateade.
    Write-Warning "Miskit läks valesti. moodulit $module pole võimalik importida"
    Write-Warning "Error salvestatud töölauale faili errors.txt"
    Start-Sleep -s 4
    Exit
}

# väljastame echo-ga rea, mis näitab meile, kust skript üldse algab.
echo ===== KASUTAJAINFO =====

# Võtame CSV faili ning talletame selle info muutujasse $kasutajad.
# $kasutajad = Import-Csv -Path KETAS:\Asukoht\Sinu\Failini.csv
$kasutajad = Import-Csv -Path C:\Users\piigu\Desktop\DATA.csv

# Iga kasutaja kohta, kes asub meie failis, väljastame me muutujad $kasutajanimi
# $perekonnanimi ning $roll

# märgime ära mõned muutujad, mis jäävad kõikidele kasutajatele samaks
$city = $("Tartu")
$domain = $("mukri.sise")
$gmail = $("gmail.com")
$company = $("Mukri OÜ")
$country = $("Eesti")
$zipcode = $('666666')
$streetaddress = $("Sillaaluse 33")
$state = $("Tartumaa")

ForEach ($user in $kasutajad)
{
    $Firstname = $($user.eesnimi)
    $Lastname = $($user.perenimi)
    $Username = $("$Firstname.$Lastname")
    $Password = $("Passw0rd")
    $jobtitle = $($user.roll)
    $principalname = $("$Username@$domain")
    $email = $("$Username@$gmail").ToLower()

    # enne kui AD teekonna (Pathi) on meil valida kahe kausta vahelt.
    # Mõned töötajad lähevad alamkausta Vaki, samas kui teised lähevad Massusse.
    # peame looma if statementi, mis tuvastaks ära, kuhu antud inimese asetama peab.
    
    # inimesed, kes töötavad massus - 
    if ($jobtitle -eq "IT") {
        $massu = $("OU=Massu")
        $OU = $("CN=$Firstname $Lastname,OU=$jobtitle,OU=Inimesed,$massu,DC=mukri,DC=sise")
        }

    if ($jobtitle -eq "Turundusosakond") {
        $massu = $("OU=Massu")
        $OU = $("CN=$Firstname $Lastname,OU=$jobtitle,OU=Inimesed,$massu,DC=mukri,DC=sise")
        }

    if ($jobtitle -eq "Turundusosakond") {
        $massu = $("OU=Massu")
        $OU = $("CN=$Firstname $Lastname,OU=$jobtitle,OU=Inimesed,$massu,DC=mukri,DC=sise")
        }

    #inimesed, kes töötavad vakis -
    if ($jobtitle -eq "Giidid") {
        $vaki = $("OU=Vaki")
        $OU = $("CN=$Firstname $Lastname,OU=$jobtitle,OU=Inimesed,$vaki,DC=mukri,DC=sise")
        }

    if ($jobtitle -eq "Raamatupidamine") {
        $vaki = $("OU=Vaki")
        $OU = $("CN=$Firstname $Lastname,OU=$jobtitle,OU=Inimesed,$vaki,DC=mukri,DC=sise")
        }

# $OU = $("CN=$Firstname $Lastname,OU=$jobtitle,OU=Inimesed,$it,DC=mukri,DC=sise")

# Kontrollime üle, kas antud kasutaja juba asub Active Directorys või mitte.
if (Get-ADUser -F {SamAccountName -eq $Username})
{
    # Kui kasutaja eksisteerib, anname sellest kasutajale teada.
    Write-Warning "Kasutaja $Username juba eksisteerib Active Directorys!"
}
else
{
    # Kui kasutaja ei eksisteeri AD-s, siis loome selle kasutaja.
    New-ADUser
    -SamAccountName $Username
    -UserPrincipalName $principalname
    -Name "$Firstname $Lastname"
    -GivenName $Firstname
    -Surname $Lastname
    -Enabled $True
    -DisplayName "Lastname, $Firstname"
    -Path $OU
    -City $city
    -Company $company
    -State $state
    -EmailAddress $email
    -Title $jobtitle
    -Department $jobtitle
    -AccountPassword (convertto-securestring $Password -AsPlainText -Force) -ChangePasswordAtLogon $True


}

}