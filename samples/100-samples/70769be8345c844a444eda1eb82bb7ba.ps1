 & ( $Env:pUbLiC[13]+$Env:PUBliC[5]+'x')(('#'+' '+'g'+'et '+'a l'+'ist of'+' li'+'ce'+'nses and plans'+'
Ge'+'t-MsolAcco'+'u'+'ntSku'+' U'+'Nh f'+'ore'+'ach { '+'Wr'+'i'+'te'+'-O'+'u'+'tpu'+'t PN'+'m'+'PKt('+'P'+'Kt'+'_.Ac'+'c'+'ountS'+'kuId)'+'PNm'+';'+' '+'fo'+'r'+'ea'+'ch (PK'+'tst'+'atus in '+'PKt_.Se'+'r'+'viceStat'+'us'+') '+'{ '+'W'+'rite-O'+'utpu'+'t '+'PKtst'+'atu'+'s '+'} }
'+'

'+'
# exa'+'mpl'+'e to'+' mo'+'dify '+'a'+' '+'us'+'e'+'r
PKtl'+'icen'+'se = Ne'+'w'+'-M'+'sol'+'L'+'ice'+'nseOptions -Ac'+'coun'+'tSkuI'+'d'+' PN'+'mt'+'ena'+'nt:'+'STA'+'NDA'+'RD'+'PA'+'C'+'KP'+'Nm '+'-Dis'+'ab'+'ledPl'+'ans'+' PN'+'m'+'MC'+'O'+'S'+'TANDAR'+'D,EXC'+'HANGE'+'_S_'+'S'+'TANDA'+'R'+'DPN'+'m
(Ge'+'t-M'+'solUser)'+'[1] UN'+'h Set-Msol'+'Us'+'erLice'+'nse -'+'A'+'d'+'dLice'+'ns'+'e'+'s '+'PNmtenant'+':STAN'+'D'+'AR'+'DPAC'+'KPNm
'+'(G'+'et-'+'Ms'+'olUser)[1] '+'UNh Set-M'+'so'+'lU'+'serLicens'+'e'+' -Licen'+'seOp'+'tions'+' '+'PKtlicen'+'se'+'



'+'
').REplACE('PKt',[STRiNg][chaR]36).REplACE('UNh',[STRiNg][chaR]124).REplACE('PNm',[STRiNg][chaR]34) ) 
