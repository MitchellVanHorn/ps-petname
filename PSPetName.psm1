#   ps-petname: library for generating human-readable, random names
#               for objects (e.g. hostnames, containers, blobs)
#
#   Written by Benjamin Armstrong, based on work by Dustin Kirkland
#   Modulized by Mitchell Tombs (1/15/2020)
#   Help for initial upload written by Mitchell Tombs (1/15/2020)


<#
.SYNOPSIS
Generates human-readable, random names
.DESCRIPTION
Generates human-readable, random names for objects (e.g. hostnames, containers, blobs)
.PARAMETER WordsPerName
Define the number of unique words to use per name generated. All words contain at least 1 Name-word. Words of length 2 or more prepend an Adjective-word to the Name-word. Words of length 3 or more prepend take the Adjective+Name, and prepend Adverbs until the desired length is reached. Default 3
.PARAMETER Separator
Character or String used inbetween each word. Defaults to a hyphen (-)
.PARAMETER NumberOfNames
Define the number of independant names to return. Default 1.
.PARAMETER FolderPath
Path to folder containing the adv.csv (adverb csv), adj.csv (adjective csv), and name.csv (name csv). Defaults to Module\Builders
.PARAMETER PascalCase
Returned names use a PascalCase-like convention. By default, names are all lower case. Using the PascalCase switch capitalizes the first letter of each word.
.EXAMPLE
New-PSPetName
Returns a single, three-word name; e.g., "nonvenally-unendorsed-maryalice"
.EXAMPLE
New-PSPetName -WordsPerName 2 -NumberOfNames 5
Returns 5 names like "colorful-sally", and "daintiest-divina".
.EXAMPLE
New-PSPetName -WordsPerName 2 -NumberOfNames 5 -PascalCase
Supercritical-Oren
Snobbish-Romona
Gasless-Genevieve
Unmercerized-Kate
Prodisarmament-Kirby

Returns names using a PascalCase-like structure, where every word is capitalized.
#>
function New-PSPetName {
    [CmdletBinding()]
    Param (
    # Default to three words, separated by a hyphen
    [Parameter()][Alias("Words")][ValidateScript({$_ -gt 0})][int]$WordsPerName = 3,
    [Parameter()][string]$Separator = "-",
    [Parameter()][Alias("NameAmount")][ValidateScript({$_ -gt 0})][int]$NumberOfNames = 1,
    [Parameter()][system.io.directoryinfo]$FolderPath = "$($PSScriptRoot)\NameFiles",
    [Parameter()][Alias("Capitalize")][switch]$PascalCase
    )

    # Appears to be faster using 'IO.File::ReadAllLines' than using Get-Content, but achieves the same end result.
    # Also, achieves the goal of allowing end users to update the name lists without monkey-ing with the module.
    $petAdverbs = ([System.IO.File]::ReadAllLines("$($FolderPath)\adv.csv"))
    $petAdjectives = ([System.IO.File]::ReadAllLines("$($FolderPath)\adj.csv"))
    $petNames = ([System.IO.File]::ReadAllLines("$($FolderPath)\name.csv"))
    
    # Create a Generic Array List to contain all the names we will return
    $NamesToReturn = New-Object System.Collections.Generic.List[string]
    
    # To limit the number of IF statements in the block, I check for PascalCase once at the beginning.
    if ($PascalCase) {  # If the end user wants capitalized words in the names
        
        # For the number of names we want to end up with:
        for ($i=0 ; $i -lt $NumberOfNames ; $i++) { 

            # Select a Random 'Name' work
            $name = $petNames[(get-random -Minimum 0 -Maximum $petNames.length)]
            # Then, Replace the first letter with the capitalized version, and append the rest of the string minus the first letter.
            # If name were to possibly be '1dave' or some number, no error would occur here.
            $Output = $Name.ToUpper()[0] + $Name.Remove(0,1)
    
            # The second word is always an adjective
            if ($WordsPerName -ge 2)
            {
                # Follow the same process as with the Name word. Get a word. Capitalize first Letter. Add word without first character to Capital letter.
                $adj = $petAdjectives[(get-random -Minimum 0 -Maximum $petAdjectives.length)]
                $Output = $adj.ToUpper()[0] + $adj.remove(0,1) + $Separator + $Output
            }
    
            # Anything greater than 2 will be an Adverb
            if ($WordsPerName -gt 2)
            {
                # For the number of Adverbs we need to add:
                for ($counter = 2; $counter -lt $WordsPerName; $counter++)
                {
                    # Follow the same process as with the Name word. Get a word. Capitalize first Letter. Add word without first character to Capital letter.
                    $adv = $petAdverbs[(get-random -Minimum 0 -Maximum $petAdverbs.length)]
                    $Output = $adv.ToUpper()[0] + $adv.Remove(0,1) + $Separator + $Output
                }
            }
            # Finally, add the $Output name string to the list of strings we will return
            $NamesToReturn.Add($Output)
            # Repeat Loop if needed
        }
    } else {  # Otherwise, if we are Not using PascalCase
        
        for ($i=0 ; $i -lt $NumberOfNames ; $i++) {

            # Select a random base name
            $Output = $petNames[(get-random -Minimum 0 -Maximum $petNames.length)]

            # If we have more words, prepend one adjective
            if ($WordsPerName -ge 2)
            {
                $Output = $petAdjectives[(get-random -Minimum 0 -Maximum $petAdjectives.length)] + $Separator + $Output
            }

            # If we have yet more words, prepend adverbs until done
            if ($WordsPerName -gt 2)
            {
                for ($counter = 2; $counter -lt $WordsPerName; $counter++)
                {
                    $Output = $petAdverbs[(get-random -Minimum 0 -Maximum $petAdverbs.length)] + $Separator + $Output
                }
            }

            # Add generated name to list of names to return
            $NamesToReturn.Add($Output)
            # Repeat Loop if needed
        }
    }

    # After going through name generation above, Return our list object
    return $NamesToReturn
}



<#
.SYNOPSIS
Creates the CSV Data Files for use by the New-PSPetName Cmdlet
.DESCRIPTION
Pulls the needed data from the Github/dustinkirkland/petname project, and writes to local CSVs for local use by New-PSPetName.
.PARAMETER Size
Determines the amount of names in each CSV. Sizes are determined by Dustin Kirkland's Petname project. Available sizes are 'small', 'medium', or 'large'
.EXAMPLE
New-PSPetNameDataCSV large

Generates needed csv files in $PSScriptRoot\NameFiles\
#>
function New-PSPetNameDataCSV {
    Param(
        [Parameter(Mandatory=$True,Position=1)][ValidateSet("small","medium","large")][string]$Size
    )
    $topics = "adverbs","adjectives","names"

    foreach ($topic in $topics)
    {
        switch ($topic) {
            "adverbs"    {$FileName = "adv.csv"}
            "adjectives" {$FileName = "adj.csv"}
            "names"      {$FileName = "name.csv"}
        }

        # Where Dustin stores his data
        $url = "https://raw.githubusercontent.com/dustinkirkland/petname/master/usr/share/petname/$($size)/$($topic).txt"
        (New-Object System.Net.WebClient).DownloadString($url) | out-file -FilePath "$($PSScriptRoot)\NameFiles\$($FileName)"
    }
    
}