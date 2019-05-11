<# 
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

# kasutaja peab sisestama CSV faili asukoh
# Importime kõigepealt activedirectory mooduli, et skript üldse töötaks.
# kui skripti ei jooksutata Windows Serveri peal, millel oleks Active Directory olemas,
# võib see koodijupp errorit visata.
# Seega peame alguses proovima, kas moodulit on võimalik importida ning kui ei ole,
# kuvatakse kasutajale, et midagi on valesti ning fail talletatakse samma kohta, kus asub
# skript.

Try {
    Start-Sleep -s 1
    Import-Module activedirectory
}
Catch {
    # kui kood lööb errorit, väljastatakse veateade.
    Import-Module activedirectory 2>> C:\CSV\errors.txt
    Write-Warning "Miskit läks valesti. moodulit pole võimalik importida"
    Write-Warning "Error salvestatud asukohta C:\CSV\errors.txt"
    Start-Sleep -s 4
    Exit
}

# Võtame CSV faili ning talletame selle info muutujasse $kasutajad.
# $kasutajad = Import-Csv -Path KETAS:\Asukoht\Sinu\Failinimi.csv
# PALUN ASETADA CSV FAIL ASUKOHTA C:\CSV\DATA.csv !!!!!
$kasutajad = Import-Csv C:\CSV\DATA.csv
# Iga kasutaja kohta, kes asub meie failis, väljastame me muutujad erinevad muutujad.

# nüüd loome muutujad, mis on pidevas muutuses ning ei jää kõikidele kasutajatele samaks.

ForEach ($user in $kasutajad)
{
    $Firstname = $($user.eesnimi)
    $Lastname = $($user.perenimi)
    $Username = $("$Firstname.$Lastname")
    $Password = $("Passw0rd")
    $jobtitle = $($user.roll)
    $principalname = $("$Username@$domain")
    $email = $("$Username@$gmail").ToLower()
    # samuti lisame muutujad, mis kõikide kasutajate vahel samaks
    $domain = $("mukri.sise")
    $gmail = $("gmail.com")

    # enne kui loome AD teekonna (Pathi) on meil valida kahe kausta vahelt.
    # Mõned töötajad lähevad alamkausta Vaki, samas kui teised lähevad Massusse.
    # peame looma if statementi, mis tuvastaks ära, kuhu antud inimese asetama peab.
    
    # inimesed, kes töötavad Massus - 
    if ($jobtitle -eq "IT") {
        $OU = $("OU=it,OU=inimesed,OU=massu,DC=mukri,DC=sise")
        }

    if ($jobtitle -eq "Turundusosakond") {
        $OU = $("OU=turundusosakond,OU=inimesed,OU=massu,DC=mukri,DC=sise")
        }

    #inimesed, kes töötavad Vakis -
    if ($jobtitle -eq "Giidid") {
        $OU = $("OU=giidid,OU=inimesed,OU=vaki,DC=mukri,DC=sise")
        }

    if ($jobtitle -eq "Raamatupidamine") {
        $OU = $("OU=raamatupidamine,OU=inimesed,OU=vaki,DC=mukri,DC=sise")
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
        New-ADUser -SamAccountName $Username -UserPrincipalName $principalname -Name "$Firstname $Lastname" -GivenName $Firstname -Surname $Lastname -Enabled $True -DisplayName "Lastname, $Firstname" -Path $OU -EmailAddress $email -Title $jobtitle -Department $jobtitle -ChangePasswordAtLogon $True -AccountPassword (convertto-securestring $Password -AsPlainText -Force)
    }

}