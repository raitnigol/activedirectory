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
    Neid on alati võimalik muuta vastavalt oma soovile ning niimoodi saab
    skripti laiet haarendada.
    Kasutades skripti saame teha suurtes kogustes kasutajaid.
    CSV faili abil saame muutujad $roll, $eesnimi ja $perenimi, mis on AD
    kontode loomiseks vajalikud.
#>

<#  
    Importime kõigepealt activedirectory mooduli, et skript üldse töötaks.
    Kui skripti ei jooksutata Windows Serveri peal, millel oleks
    Active Directory olemas, võib see koodijupp errorit visata.
    Seega peame alguses proovima, kas moodulit on võimalik importida ning kui ei ole,
    kuvatakse kasutajale, et midagi on valesti ning
    skript suletakse neli sekundit hiljem.
    Samuti salvestatakse tekstifail asukohta C:\CSV\errors.txt
#>

Try {
    # proovime importida activedirectory
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

<#  Võtame CSV faili ning talletame selle info muutujasse $kasutajad.
    $kasutajad = Import-Csv -Path KETAS:\Asukoht\Sinu\Failinimi.csv
    PALUN ASETADA CSV FAIL ASUKOHTA C:\CSV\DATA.csv !!!!!
    Iga kasutaja kohta meie failis, väljastame kahte sorti muutujad -
    staatilised kui ka muutuvad.
#>

$kasutajad = Import-Csv C:\CSV\DATA.csv

    # iga kasutaja kohta CSV failis me loome neile staatilised muutujad
    # kui ka muutuvad muutujad.
    # Alustame muutuvate muutujatega.
ForEach ($user in $kasutajad)
{
    # loome kasutajale eesnime (Rait)
    $Firstname = $($user.eesnimi)
    # loome kasutajale perekonnanime (Nigol)
    $Lastname = $($user.perenimi)
    # loome kasutajale kasutajanime kujul eesnimi.perenimi (rait.nigol)
    $Username = $("$Firstname.$Lastname").ToLower()
    # loome kasutajale rolli (IT)
    $jobtitle = $($user.roll)
    
    # enne kui loome j2rgmised muutujad, peame paika panema m6ned staatilised muutujad
    # loome domeeni mukri.sise
    $domain = $("mukri.sise")
    # loome kasutajale emaili aadressi kujul (rait.nigol@mukri.sise)
    $email = $("$Username@$domain").ToLower()
    # loome igale kasutajale sama parooli, sest niikuinii on see tarvis j2rgmisel
    # sisselogimisel 2ra muuta
    $Password = $("Passw0rd")
    # loome kasutajale peamise nime kujul kasutajanimi@domeen (rait.nigol@mukri.sise)
    $principalname = $("$Username@$domain")
    # loome kasutajale emaili kasutades muutuja $gmail abi.

<# 
    Meie systeemis on kaks alamkausta - Massu ja Vaki.
    Enne kui loome AD teekonna (pathi), on meil valida kahe kausta vahelt.
    Mõned töötajad lähevad alamkausta Vaki, samas kui teised lähevad Massusse.
    Peame looma if statementi, mis tuvastaks ära, kuhu antud inimese asetama peab.
#>

<#
    Loome if statementi inimestele, kes töötavad Massus.
    Erinevate rollide puhul on erinevad pathid, seega peame pidevalt muutma
    antud teekonda.
#>
    # Kui kasutajal on IT roll, on teekond j2rgmine:
    # mukri.sise/massu/inimesed/it 
    if ($jobtitle -eq "IT") {
        $OU = $("OU=it,OU=inimesed,OU=massu,DC=mukri,DC=sise")
        }
    
    # Kui kasutajal on Turundusosakonna roll, on teekond j2rgmine:
    # mukri.sise/massu/inimesed/turundusosakond 
    if ($jobtitle -eq "Turundusosakond") {
        $OU = $("OU=turundusosakond,OU=inimesed,OU=massu,DC=mukri,DC=sise")
        }

    # Loome if statementi inimestele, kes töötavad Vakis.
    # Kui kasutajal on Giidi roll, on teekond j2rgmine:
    # mukri.sise/vaki/inimesed/giidid
    if ($jobtitle -eq "Giidid") {
        $OU = $("OU=giidid,OU=inimesed,OU=vaki,DC=mukri,DC=sise")
        }

    # Kui kasutajal on Raamatupidaja roll, on teekond j2rgmine:
    # mukri.sise/vaki/inimesed/raamatupidamine
    if ($jobtitle -eq "Raamatupidamine") {
        $OU = $("OU=raamatupidamine,OU=inimesed,OU=vaki,DC=mukri,DC=sise")
        }
<#
    Viimase asjana enne l6petust kontrollime yle, kas antud kasutajad
    juba eksisteerivad systeemis v6i mitte. Kui kasutajaid ei eksisteeri,
    hakatakse kasutajaid tegema. Vastasel juhul kuvatakse veateade, et
    kasutaja juba eksisteerib.
#>

    # Kontrollime üle, kas antud kasutaja juba asub Active Directorys või mitte.
    if (Get-ADUser -F {SamAccountName -eq $Username})
    {
    # Kui kasutaja eksisteerib, anname sellest kasutajale teada.
        Write-Warning "Kasutaja $Username (Roll: $jobtitle) juba eksisteerib Active Directorys!"
    }
    else
    {
        # Kui kasutaja ei eksisteeri AD-s, siis loome selle kasutaja.
        New-ADUser -SamAccountName $Username -UserPrincipalName $principalname -Name "$Firstname $Lastname" -GivenName $Firstname -Surname $Lastname -Enabled $True -DisplayName "Lastname, $Firstname" -Path $OU -EmailAddress $email -Title $jobtitle -Department $jobtitle -ChangePasswordAtLogon $True -AccountPassword (convertto-securestring $Password -AsPlainText -Force)
    }

}
