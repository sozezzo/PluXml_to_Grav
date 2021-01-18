Clear-Host

#############################
## Pandoc Config           ##
## pandoc : https://pandoc.org/
$pandocApp  = ".\pandoc.exe"
$pandocPath = "D:\User\Github\Powershell-Html-to-Markdown\bin\pandoc"
#$pandocConfig = " -f html -t markdown "

#$pandocConfig = " -f html -t markdown_strict "

$pandocConfig = " -f html -t markdown_strict "



# markdown_phpextra (PHP Markdown Extra)
# markdown_github (deprecated GitHub-Flavored Markdown)
# markdown_mmd (MultiMarkdown)
# markdown_strict (Markdown.pl)
# commonmark (CommonMark)
# gfm (Github-Flavored Markdown)
# commonmark_x (CommonMark with many pandoc extensions)



#############################
## PluXml Config           ##
## Path to PluXml\Data
$PluXmlDataPath = "D:\User\Github\SitePluXml"

#############################
## Grav Config             ##
## Path to Grav\user
#$GravUserPath   = "D:\User\Github\Grav\user"
#$GravImageName  = "imgGrav"
$GravUrlMedia  = ""
$script:GravPathMedia  = ""


#Grav blog
$GravUserBlogPath   = "D:\User\Github\Grav\user\pages\01.Blog"
$GravFileName   = "item.md"
#$GravSummary    = "==="
$script:GravImageIndex = 0
$script:GravImageArr   = @()

Clear-Host

$newline = "`r`n"
$newShortcodeSH = "``````"

##
## Info 
##

## https://wiki.pluxml.org/developper/developpement/#comprendre-le-nom-des-fichiers-xml-des-articles
## _0001.002,003,004.001.201304251142.premier-article.xml

#Si nous détaillons le nom du fichier, nous avons:

#    _ est un caractère optionnel. Il indique que l'article est en attente de validation.
#    0001 est l'identifiant de l'article. Il peut aller jusqu'à 9999, donc 9999 articles.
#    002,003,004 contient l'identifiant de la catégorie dans laquelle l'article est classé. 
#    Il peut avoir plusieurs identifiants séparés par des virgules (exemple 001,002). 
#    Ici l'article est donc classé dans la catégorie 002,003,004. 
#    Il n'y a pas de limite dans le nombre de catégories possibles, du moment qu'elles sont bien séparées par des virgules. 
#    Il est possible d'avoir également la valeur draft qui indique que l'article est un brouillon, ou la valeur home qui indique que l'article est publié dans la catégorie Page d'accueil. 
#    Il est donc tout a fait possible d'avoir 0001.001,002,draft.001.201304251142.premier-article.xml
#    001 est l'identifiant de l'utilisateur qui a rédigé l'article.
#    201304251142 est la date de publication de l'article. Cela peut être une date future. Cette date est de la forme AAAAMMJJHHMM où:
#        AAAA = année
#        MM = mois
#        JJ = jour
#        HH = heure
#        MM = minute
#    premier-article est l'url de l'article. On la retrouve dans : http://mondomaine.com/index.php?article1/premier-article
#    xml est l'extension du fichier



# Word wrap function, return word wrapped version of passed string
function wrap-string($str, $length)
{
    # https://gist.github.com/theunrepentantgeek/e768a6fd5af45712554440aca74d8706

    if ($str.length -lt $length) 
    {
        return $str
    }
    
	# Holds the final version of $str with newlines
	$strWithNewLines = ""
	# current line, never contains more than screen width
	$curLine = 0
	# Loop over the words and write a line out just short of window size
	foreach ($word in $str.Split(" "))
	{
		# Lets see if adding a word makes our string longer then window width
		if (($curLine + 1 + $word.length) -gt $length)
		{
			# With the new word we've gone over width
			# append newline before we append new word
			$strWithNewLines += "`r`n" + $word
			# Reset current line
			$curLine = $word.length
		}
        else
        {
            # Append word to current line and final str
            if ($curLine -gt 0)
            {
                $strWithNewLines += " "
            }
            
            $curLine += $word.Length + 1
            $strWithNewLines += $word
        }
	}
	# return our word wrapped string
	return $strWithNewLines
}
function Process-ShotCode-SH-to-Markdown($content)
{

    #Check shortcode
    if ( $content.Substring(0,3) -ne '[SH')
    {
        Write-Error -message "Warning : *begin* shortcode was not found."
        return ""
    }

    if ( $content.Substring($content.Length-5,5) -ne '[/SH]')
    {
        Write-Error -message "Warning : *end* shortcode was not found."
        return ""
    }

    $pTag = 0
    $pBegin = $content.IndexOf(']', $pTag) + 1
    $pTagName = $content.Substring($pTag + 4, $pBegin - $pTag - 5)

    if ($pTagName -eq 'sql' -or $pTagName -eq 'log' -or  $pTagName -eq 'csharp' -or $pTagName -eq 'scala' -or $pTagName -eq 'shell' )
    {
        $content = $content.Replace('&nbsp;', ' ')
        $content = $content.Replace('<p>', '')
        $content = $content.Replace('</p>', '')
        $content = $content.Replace('&gt;', '>')
        $content = $content.Replace('&lt;', '<')
        $content = $content.Replace('&quot;', '"')
        $content = $content.Replace('&#39;', '''')
    }


    #Get len
    $pLen = $content.Length-$pBegin-5

    #get text
    $str = $content.Substring($pBegin, $pLen)

    #remove </BR > from each end line
    ## ex : * Syntax :<br />
    ##      * Syntax :
    $strResult = ""
    $LineArr = $str.Split([char]10)
    ForEach ($Line in $LineArr)
    {
        if($Line.Length -ge 6)
        {
            $LineLastChars = $Line.Substring($Line.Length-6, 6)
            if ($LineLastChars -eq '<br />' -or  $Line -eq '<br />' )
            {
                $Line = $Line.Substring(0, $Line.Length - 6)
            }
        }
        $strResult = $strResult + $Line + $newline
    }

    #Replace shortcode
    $strResult = $newShortcodeSH+$pTagName + $newline + $strResult + $newline + $newShortcodeSH 
    return $strResult
    
}

function Convert-Html-to-Markdown($content)
{

    Set-Location $pandocPath

    #Save
    $pandocTempFilePathHtml  = $pandocPath+"\convert_html_to_markdown.input.html"
    $pandocTempFilePathDM    = $pandocPath+"\convert_html_to_markdown.output.md"
    $content | Out-File  $pandocTempFilePathHtml -Encoding "utf8NoBOM" 
    
    if (Test-Path $pandocTempFilePathDM -PathType leaf)
    {
        Remove-Item $pandocTempFilePathDM
    }

    $ExecPandoc = $pandocApp + $pandocConfig + $pandocTempFilePathHtml + " -o " + $pandocTempFilePathDM
    Invoke-expression $ExecPandoc

    $content = [IO.File]::ReadAllText("$pandocTempFilePathDM")

    return $content 
}
function save-img($path, $EncodedText)
{
    $Image = [Drawing.Bitmap]::FromStream([IO.MemoryStream][Convert]::FromBase64String($EncodedText))
    $Image.Save($path)
}

function save-img-url($path, $urlImg)
{
    #WebClient
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($urlImg, $path)

    ##Solution 2 - never tried this before
    #Invoke-WebRequest $url -OutFile C:\temp\test.jpg
}

function ReplaceAll($text, $find, $replaceby)
{

    if ( $find -eq $replaceby)
    {
        return $text
    }
    $pos = $text.IndexOf($find)
    while ($pos -gt 0)
    {
        $text = $text.Replace($find, $replaceby)
        $pos = $text.IndexOf($find)
    }
    return $text
}

function get-hex($oid) { 	
    $len = $oid.length
    $hex = @() 	
    for($j=0;$j -lt $len;$j++)
    {
      $b = "{0:X}" -f ([int]$oid[$j])
      $hex = $hex + $b
    }
    return $hex
  }
function Process-HotFix-CleanUp($Markdown)
{
    $ret = ""
    $LineArr = $Markdown.Split([char]10)
    $whiteLine = 0
    ForEach ($Line in $LineArr)
    {
        $Line = $Line.TrimEnd()
        if ($Line -eq '') 
        {
            $whiteLine = $whiteLine + 1 
        }
        else 
        {
            $whiteLine = 0
        }
        if ($whiteLine -lt 2)
        {
           $ret = $ret + $Line + $newline    
        }
    }

    return $ret

}

function Process-HotFix-DownloadRemoteImage($ImageRootName, $Markdown)
{
    
    # ![](http://www.domain.com/image.png)

    $pos = $Markdown.IndexOf('![](http')
    while ($pos -gt 0)
    {
        $script:GravImageIndex = $script:GravImageIndex + 1
        $posEnd = $Markdown.IndexOf(')', $pos)
        $urlImg = $Markdown.SubString($pos+4, $posEnd - $pos - 4)

        $ext = $urlImg.Substring($urlImg.lastIndexOf('.') + 1)
        if ($urlImg.IndexOf(' ') -gt 0) { 
            $ext = $urlImg.SubString(0, $urlImg.IndexOf(' '))
            $ext = $ext.Substring($ext.lastIndexOf('.') + 1) 
        }
        $filename = $script:GravPathMedia+"\"+$ImageRootName+'_'+$script:GravImageIndex +"."+$ext
        #$urlname = $script:GravUrlMedia+"/"+$ImageRootName+'_'+$script:GravImageIndex +"."+$ext
        $urlname = $ImageRootName+'_'+$script:GravImageIndex +"."+$ext
        save-img-url $filename $urlImg
        
        $tag    = $Markdown.SubString($pos, $posEnd - $pos + 2)
        $tagNew = "![]($urlname)"
        $Markdown = $Markdown.Replace($tag, $tagnew)

        $pos = $Markdown.IndexOf('![](http')

    }

    return $Markdown

}
function Process-HotFixEncodedImage($ImageRootName, $imgtag, $ext, $content)
{
    $imgtagEnd  = '"'
    $imgHtmlEnd  = '/>'
    #$GravImageName  = "img"
    #$script:GravImageIndex = 0

    $posBegin = $content.IndexOf($imgtag)
    while ($posBegin -gt 0)
    {
        $posEnd = $content.IndexOf($imgtagEnd, $posBegin+$imgtag.Length)
        if ($posEnd -eq -1)
        {
            Write-Error -Message "Warning : Bad tag image $imgtag"
            return $content
        }

        $EcodedImage =  $content.Substring($posBegin+$imgtag.Length, $posEnd - $posBegin - $imgtag.Length)
        $EcodedImage = $EcodedImage.Trim()

        $script:GravImageIndex = $script:GravImageIndex + 1
        $filename = $ImageRootName+'_'+$script:GravImageIndex +"."+$ext
        $fullfilename = $GravPathMedia+"\"+$filename
        save-img $fullfilename $EcodedImage

        ## Next loop
        $posEnd  = $content.IndexOf($imgHtmlEnd, $posEnd+$imgHtmlEnd.Length)  #remove full tag html/image
        $content = $content.Remove($posBegin, $posEnd - $posBegin + $imgtagEnd.Length + 1)

        $GravImageGui = "img"+([string]([guid]::NewGuid())).Replace("-", "")
        $GravImageCode = "![](" + $GravUrlMedia + "/" + $filename + ")"
        $script:GravImageArr += ,(@($GravImageGui, $GravImageCode))

        $content  = $content.insert($posBegin, $GravImageGui)
        $posBegin = $content.IndexOf($imgtag)

    }
    return $content

}
function Process-Pluxml-to-Grav-Post($content)
{

    #Split text to convert to markdown

    $strRet = ''
    $posShortcodeBegin = 0
    $posShortcodeEnd = 0

    $posText = 0

    while ($content.Length -ge 1)
    {

        $posShortcodeBegin = $content.IndexOf('[SH ')
        if ($posShortcodeBegin -eq -1)
        {
            $TextMD = Convert-Html-to-Markdown($content)
            $strRet = $strRet + $TextMD
            return $strRet
        }

        $posTextBegin = $content.IndexOf(']', $posShortcodeBegin)
        $posTextEnd = $content.IndexOf('[/SH]', $posShortcodeBegin)
        if ($posTextBegin -eq -1)
        {
            Write-Error -Message "Warning : Shotcode is missing end-tag"
            return ""
        }

        $TextHtml = $content.Substring(0, $posShortcodeBegin)
        $TextMD = Convert-Html-to-Markdown($TextHtml)
        $strRet = $strRet + $TextMD + $newline

        $TextShortcode = $content.Substring($posShortcodeBegin, $posTextEnd-$posShortcodeBegin+5)
        $TextShortcodeMD = Process-ShotCode-SH-to-Markdown($TextShortcode)
        $strRet = $strRet + $TextShortcodeMD + $newline

        $content = $content.Substring($posTextEnd+5, $content.Length-$posTextEnd-5)

    }

    return $strRet

}

function Convert-date-PLUXML-TO-Grav($Date)
{
    ##012345678901
    ##YYYYMMDDhhmm to DD-MM-YYYY hh:mm
    $ret = ""

    $ret = $ret + $Date.Substring(6, 2)+'-' ## DD
    $ret = $ret + $Date.Substring(4, 2)+'-' ## MM
    $ret = $ret + $Date.Substring(0, 4)+' ' ## YYYY

    $ret = $ret + $Date.Substring(8, 2)+':' ## hh
    $ret = $ret + $Date.Substring(10, 2) ## mm

    return $ret
}

function Convert-list-PLUXML-TO-Grav-Array($type , $lst)
{
    ## PluXml
    ##    "item1, item2"
    
    ## Grav
    ##     $type: [item 1, item 2]
    $ret = ""
    if ($lst.Length -gt 0 )
    {
        $ret = "    "+$type + ": ["+$lst+"]"+$newline+$ret
    }
    return $ret

}


function Convert-list-PLUXML-TO-Grav($type , $lst)
{
    ## PluXml
    ##    "item1, item2"
    
    ## Grav
    ##     $type: 
    ##         - item 1
    ##         - item 2

    $arr = $lst.Split(",")
    $ret = ""
    
    foreach($item in $arr)
    {
        if ($item.length -gt 1)
        { 
            $ret = $ret + "        - "+$item.Trim()+$newline
        }
    }

    if ($ret.length -gt 1)
    {
        $ret = "    "+$type + ":"+$newline+$ret
    }
    
    return $ret

}

function Convert-Categories-CodeToName($PluXmlCategories)
{
    $arr = $PluXmlCategories.Split(",")
    $ret = ""

    foreach($item in $arr)
    {

        if ($item.length -gt 1)
        {
            if ($ret.Length -gt 1 )
            {
                $ret = $ret + ", "
            }
            $r = Get-PluXml-CategorieUrlByNumber($item)
            $ret = $ret + $r
        }
    }

    return $ret

}

#########################################
## Get categories
$PluXmlCategorieFileNameFullPath = $PluXmlDataPath+"\data\configuration\categories.xml"
[xml]$xmlPluXmlCategories = Get-Content $PluXmlCategorieFileNameFullPath

function Get-PluXml-CategorieUrlByNumber($CategorieNumber)
{
    $ret = ""
    foreach ($nodeXML1 in $xmlPluXmlCategories.document.categorie)
    {
        if ($nodeXML1.Number -eq $CategorieNumber)
        {
            $ret = $nodeXML1.url
        }
    }
    return $ret
}

#Get-PluXml-CategorieUrlByNumber "003"
#########################################



### ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## Get all the article files into an object and store it in a variable

Clear-Host

$PluXmlArticlesPath = $PluXmlDataPath+"\data\articles\"
#Write-Host  $PluXmlArticlesPath
$PluXmlArticlefiles = Get-ChildItem $PluXmlArticlesPath -Filter *.xml

$test = 150 ## articles 

# For Loop 
ForEach ($PluXmlArticle in $PluXmlArticlefiles) {
    
    ## STOP TEST ##
    $test = $test - 1;
    if ($test -eq -1) 
    {
        break
    }
    ## STOP TEST ##
    
    $script:GravImageIndex = 0
    $script:GravImageArr   = @()

    $name = $PluXmlArticle.name
    "-- Convert file $name"

    #PluXmlDraft
    $PublishedPostStr = "true"
    $PluXmlisDraft = 0
    if ($name.Substring(0, 1) -eq "_")
    {
        $PluXmlisDraft = 1
        $PublishedPostStr = "false"
    }
    else
    {
        "-- -- Draft"
    }
    
    #PluXmlArticleNumber
    $p1 = $name.IndexOf('.')
    $PluXmlArticleNumber = $name.Substring($PluXmlisDraft, 4)
    "-- -- Number $PluXmlArticleNumber"

    #PluXmlCategories
    $p2 = $name.IndexOf('.', $p1+1)
    $PluXmlCategories = $name.Substring($p1+1, $p2-$p1-1)
    "-- -- Categorie $PluXmlCategories"

    #PluXmlUser
    $p3 = $name.IndexOf('.', $p2+1)
    $PluXmlUser = $name.Substring($p2+1, $p3-$p2-1)
    "-- -- User $PluXmlUser"


    #PluXmlPublicationDate
    $p4 = $name.IndexOf('.', $p3+1)
    $PluXmlPublicationDate = $name.Substring($p3+1, $p4-$p3-1)
    "-- -- Date $PluXmlPublicationDate"

    #PluXmlFilename
    $p5 = $name.IndexOf('.xml', $p4+1)
    $PluXmlFilename = $name.Substring($p4+1, $p5-$p4-1)
    "-- -- Date $PluXmlPublicationDate"


    ## Read article file
    $PluXmlArticleFullPath = "$PluXmlArticle"
    $PluXmlArticleFullPath
    [xml]$xmlPluXmlArticle = Get-Content $PluXmlArticleFullPath
    $PluXmltitle = $xmlPluXmlArticle.document.title.InnerText
    $PluXmlChapo = $xmlPluXmlArticle.document.chapo.InnerText
    $PluXmlContent = $xmlPluXmlArticle.document.content.InnerText
    $PluXmlTags = $xmlPluXmlArticle.document.tags.InnerText
    $PluXmlDate_creation = $xmlPluXmlArticle.document.date_creation.InnerText
    $PluXmlDate_update = $xmlPluXmlArticle.document.date_update.InnerText

    #####################
    #Grav Folder
    $GravItemFolderName = $GravUserBlogPath+"\"+$PluXmlArticleNumber+"."+$PluXmlFilename

    #Grav Image-Folder-name
    $script:GravPathMedia = $GravItemFolderName

    # Delete old folder and files
    Get-ChildItem -Path $GravItemFolderName -Recurse | Remove-Item -force -recurse

    # Create folder
    New-Item -ItemType directory -Path $GravItemFolderName

    # Make sure the filename and path is proper and store in a variable
    #####################


    ##################################
    ## Begin : Fix for old blog files ##

    ## If $PluXmlDate_creation is Null then $PluXmlDate_creation = $PluXmlPublicationDate
    if ( !$PluXmlDate_creation )
    {
        $PluXmlDate_creation = $PluXmlPublicationDate
    }

    ## If $PluXmlDate_update is Null then $PluXmlDate_update = $PluXmlPublicationDate
    if ( !$PluXmlDate_update )
    {
        $PluXmlDate_update = $PluXmlPublicationDate
    }

    ## End : Fix for old blog files ##
    ##################################

    $PluXmlPost = ''  
    if ($PluXmlChapo -ne '')
    {
        $PluXmlPost = $PluXmlPost + $PluXmlChapo + $newline
    }
    if ($PluXmlContent -ne '')
    {
        $PluXmlPost = $PluXmlPost + $PluXmlContent
    }
    #Save html file
    $GravItemSourceFileName = $GravItemFolderName + "\itemSource.html"  
    Set-Content $GravItemSourceFileName $PluXmlPost -Force

    ## fix encoded images
    $ImageRootName = $PluXmlArticleNumber+"."+$PluXmlFilename
                                                             
    $PluXmlPost = Process-HotFixEncodedImage $ImageRootName '<img src="data:image/png;base64,' 'png' $PluXmlPost
    $PluXmlPost = Process-HotFixEncodedImage $ImageRootName '<img alt="" src="data:image/png;base64,' 'png' $PluXmlPost

    #Convert Content to Markdown
    $GravMarkdown = ''
    $GravMarkdown = Process-Pluxml-to-Grav-Post($PluXmlPost)

    #Download remote images
    $GravMarkdown = Process-HotFix-DownloadRemoteImage $ImageRootName $GravMarkdown

    #Fix images
    foreach ($item in $script:GravImageArr)
    {
        $GravMarkdown = $GravMarkdown.Replace($item[0], $item[1])
    }

    # fix local images
    if ($GravMarkdown.IndexOf("data/medias/OLW/") -gt 0)
    {
        $GravMarkdown = $GravMarkdown.Replace('./data/medias/OLW/', '/media/OLW/')
        $GravMarkdown = $GravMarkdown.Replace("data/medias/OLW/"  , "/media/OLW/")
        $GravMarkdown = $GravMarkdown.Replace('[<img src="/media/OLW/'  , '![<img src="/media/OLW/')
        $GravMarkdown = $GravMarkdown.Replace('!![<img src="/media/OLW/'  , '![<img src="/media/OLW/')
        $posBadOLWImage = $GravMarkdown.IndexOf('![<img src="/media/OLW/')
        while ($posBadOLWImage -gt 0)
        {
            $posBadOLWImageEnd = $GravMarkdown.IndexOf(']', $posBadOLWImage)
            $GravMarkdown = $GravMarkdown.Remove($posBadOLWImage, $posBadOLWImageEnd-$posBadOLWImage+1)
            $GravMarkdown = $GravMarkdown.Insert($posBadOLWImage, '![]')
            $posBadOLWImage = $GravMarkdown.IndexOf('![<img src="/media/OLW/')
        }
        ##move images from pluxml folder to grav-item-blog
        $posMediaImage = $GravMarkdown.IndexOf('/media/OLW/')
        $subFolderPluXml = $GravMarkdown.Substring($posMediaImage, $GravMarkdown.IndexOf(')', $posMediaImage)-$posMediaImage)
        $subFolderPluXml
        $posMediaImage = $subFolderPluXml.LastIndexOfAny('/')
        $subFolderImage = $subFolderPluXml.Substring(0, $posMediaImage)

        $subFolderPluXml = $subFolderImage.Replace('/media/OLW/','\medias\OLW\')
        $subFolderPluXml = $PluXmlDataPath + '\data\' + $subFolderPluXml

        $originalfiles = Get-ChildItem -Path  $subFolderPluXml
        $originalfiles
        foreach ($file in $originalfiles) {
            Write-Host
            Write-Host File Name: -ForegroundColor DarkYellow
            Write-Host $file.Name
            Write-Host File Path: -ForegroundColor DarkYellow
            Write-Host $file.FullName
            $src = $file.FullName
            $dest = $GravItemFolderName+"\$($file.Name)"
            Copy-Item $src $dest
        }
        $GravMarkdown = $GravMarkdown.Replace($subFolderImage+'/','')

    }

    ##############################
    # fix
    # cut off end-spaces 
    # change 3 lines or more in to 2 lines
    $GravMarkdown = Process-HotFix-CleanUp($GravMarkdown)

    #Print markdown post
    $GravMarkdown

    ## Converts
    $GravPublicationDate = Convert-date-PLUXML-TO-Grav($PluXmlPublicationDate)
    $GravDate_creation = Convert-date-PLUXML-TO-Grav($PluXmlDate_creation)
    $GravTag = Convert-list-PLUXML-TO-Grav-Array 'tag'  $PluXmlTags

    $PluXmlCategoriesList = Convert-Categories-CodeToName($PluXmlCategories)
    $GravCategory = Convert-list-PLUXML-TO-Grav-Array 'category'  $PluXmlCategoriesList
    "----"

    $gravItem = ""
    $gravItem = $gravItem+"---" + $newline
    $gravItem = $gravItem+"title: $PluXmltitle" + $newline
    $gravItem = $gravItem+"published: $PublishedPostStr" + $newline
    $gravItem = $gravItem+"date: '$GravDate_creation'" + $newline
    $gravItem = $gravItem+"publish_date: '$GravPublicationDate'" + $newline
    $gravItem = $gravItem+"taxonomy:" + $newline
    $gravItem = $gravItem+$GravCategory
    $gravItem = $gravItem+$GravTag
    $gravItem = $gravItem+"visible: $PublishedPostStr" + $newline
    $gravItem = $gravItem+"---" + $newline
    $gravItem = $gravItem+$newline
    $gravItem = $gravItem+$GravMarkdown+$newline

    ################################
    ## Write down the new post Grav

    ##$PluXmlContent = $PluXmlContent -replace "[SH sql]", "<pre><code class=""language-sql"">"
    ##$PluXmlContent = $PluXmlContent -replace "[/SH]", "</code></pre>"
    #$gravItem =  $gravItem -ireplace [regex]::Escape("\[SH sql\]"), "``````sql"
    #$gravItem =  $gravItem -ireplace [regex]::Escape("\[/SH\]"), "``````"

    #Save Grav file
    $GravItemFileName = $GravItemFolderName + "\" + $GravFileName
    Set-Content $GravItemFileName $gravItem -Force

<#
---
title: Blog1
published: true
date: '13-09-2020 15:32'
publish_date: '22-09-2020 20:32'
taxonomy:
    category:
        - firefox
        - cat2
        - cat3
    tag:
        - sqlscript
        - Tag2
visible: true
---
**Content**
#>
    

}
