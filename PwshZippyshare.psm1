
$Script:UserAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
$Script:DirUrl = "http://www.zippyshare.com/fragments/publicDir/filetable.jsp"
function Find-ZippyShareFileLinks {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject,        
        $Uri,
        $UserAgent = $Script:UserAgent
    )
    process{
        if($InputObject -is [Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject]){
            $Req = $InputObject
        } else {
            if(-not $Uri) {$Uri = $InputObject}
            $Req = Invoke-WebRequest -Uri $Uri -UserAgent $UserAgent
        }
        $Req.Links.href | ForEach-Object {
            if($_ -match '(www[0-9]*\.zippyshare\.com)/v/([0-9a-zA-Z]*)/file.html'){
                $server = $Matches[1]
                $id = $Matches[2]
                # Normalize output
                Write-Output "https://$server/v/$id/file.html";
            }}
    }
}
function Get-ZippyShareFileTable {
    [CmdletBinding()]
    param (
        $Uri,
        $UserAgent = $Script:UserAgent
    )
    process{
        if($Uri -match 'www\.zippyshare\.com/([^/]*)/([^/]*)/dir.html'){
            $user = $Matches[1]
            $dir = $Matches[2]
            # Only shows 250 right now, but good enough for most
            Invoke-WebRequest -Uri $Script:DirUrl -Method Post -Body @{
                page = 0
                user = $user
                dir = $dir
                sort = "nameasc"
                pageSize = 250
                viewType = "default"
            }
        } else {
            throw "Uri ($Uri) does not appear to be zippyshare dir link"
        }
    }
}
function Resolve-ZippyShareFileLink {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        $Uri,
        $UserAgent = $Script:UserAgent
    )
    process {
        if($Uri -match '^(https://www[0-9]*\.zippyshare\.com)/v/([0-9a-zA-Z]*)/file.html$'){
            $server = $Matches[1]
            $id = $Matches[2]
            
            $Req = Invoke-WebRequest -Uri $Uri -UserAgent $UserAgent
            # Also pretty fragile, but it works
            if($Req.RawContent -match 'document\.getElementById\(''dlbutton''\)\.href\s*=\s*"/d/[^/]*/"\s*\+\s*\(([^)]*)\)\s*\+\s*"/([^"]*)";'){
                $key = Script:ZippyMath -MathString $Matches[1]
                $filename = $Matches[2]
                return "$server/d/$id/$key/$filename"
            } else {
                throw "Document content does not contain secret calculation"
            }

        } else {
            throw "Uri ($Uri) does not appear to be zippyshare file link"
        }
    }
}

# This is probably pretty fragile, but could be adapted pretty easily
function Script:ZippyMath (
    [string] $MathString = "724422 % 51245 + 724422 % 913"
) {
    if($MathString -match '^\s*([0-9]*)\s*%\s*([0-9]*)\s*\+\s*([0-9]*)\s*%\s*([0-9]*)\s*$'){
        [Double]::Parse($Matches[1]) % [Double]::Parse($Matches[2]) + [Double]::Parse($Matches[3]) % [Double]::Parse($Matches[4]) 
    } else {
        throw "Cannot match $MathString to pattern ([0-9]* % [0-9]* + [0-9]* % [0-9]*)"
    }
}