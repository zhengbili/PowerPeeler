import sys
import json
import base64

def parse(line,k=None):
    info=[]
    f=True
    i=0
    while i<len(line) and line[i] in ' \t':
        i+=1
    w1=i
    w2=-1
    while i<len(line):
        if line[i]=='\\':
            i+=2
            continue
        if f:
            if w1<w2 and line[i] not in ' \t':
                w1=i
                if k and len(info)>=k-1:
                    info.append(line[w1:])
                    return info
            elif w2<w1 and line[i] in ' \t':
                w2=i
                info.append(line[w1:w2])
        if line[i]=='"':
            f=not f
        i+=1
    if w2<w1:
        info.append(line[w1:])
    return info

index=0
def write(s):
    global index
    
    index+=1
    print(s)#open('out/%d.txt'%index,'w').write(s)

errors=[]
long_argvs=['-nologo', '-noexit', '-sta', '-mta', '-noprofile', '-noninteractive']
short_argvs=['-nol', '-noe', '-st', '-mta', '-nop', '-noni']
for line in open(sys.argv[1],encoding='utf-8').read().split('\n'):
    info=parse(line)
    if len(info)==0:
        continue
    if 'powershell' in info[0] or 'pwsh' in info[0]:
        if len(info)<2:
            errors.append(['Few args',line])
            continue
        f=False
        for i in range(1,len(info)):
            argv=info[i].lower()
            if argv.startswith('-e') and '-encodedcommand'.startswith(argv):
                try:
                    script=base64.b64decode(info[i+1]+'===').decode('utf-16')
                except:
                    script=base64.b64decode(info[i+1]+'A===').decode('utf-16')
                write(script)
                f=True
                break
            if argv.startswith('-c') and '-command'.startswith(argv):
                if not info[i+1].startswith('"'):
                    script=parse(line,i+2)[-1]
                    write(script)
                    break
                try:
                    script=json.loads(info[i+1])
                    write(script)
                except:
                    errors.append(['Wrong string',line])
                f=True
                break
        if f:
            continue
        i=1
        while i<len(info):
            argv=info[i].lower()
            if any([c.startswith(argv) for c in long_argvs]) and any([argv.startswith(c) for c in short_argvs]):
                i+=1
                continue
            if argv.startswith('-'):
                i+=2
                continue
            if info[i].startswith('"'):
                try:
                    script=json.loads(info[i])
                except:
                    errors.append(['Wrong string',line])
                break
            else:
                script=parse(line,i+1)[-1]
                write(script)
                break
        else:
            errors.append(['No argv found',line])
print("\033[31merrors:",len(errors),"\033[0m")
