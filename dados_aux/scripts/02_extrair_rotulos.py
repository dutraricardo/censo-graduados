import re, csv, sys
out = sys.argv[1]
def sheet(f, name):
    rows=[]; on=False
    for line in open(f):
        line=line.rstrip('\n')
        if line.startswith('=== SHEET '):
            on = (line[10:]==name); continue
        if on: rows.append([c.strip() for c in line.split(' | ')])
    return rows
res=[]
def add(ano,var,code,label):
    label=re.sub(r'\s+',' ',label).strip()
    if code!='' and re.fullmatch(r'\d+',code) and label: res.append((ano,var,int(code),label))
for r in sheet('dict_1960.txt','v214'): add(1960,'V214',r[0],r[1] if len(r)>1 else '')
for r in sheet('dict_1960.txt','v223b'): add(1960,'V223B',r[0],r[1] if len(r)>1 else '')
for r in sheet('dict_1970.txt','curso_concluido_V039'): add(1970,'V039',r[0],r[1])
for r in sheet('dict_1970.txt','atividade_V045'): add(1970,'V045',r[0],r[1])
for r in sheet('dict_1980.txt','ensino_superior_V525'): add(1980,'V525',r[0],r[1])
for r in sheet('dict_1980.txt','Finalidade_negocio_V532'): add(1980,'V532',r[0],r[1])
for r in sheet('dict_1991.txt','atividade_V0347'): add(1991,'V0347',r[0],r[1])
# 1991 V0329: categorias inline no PESS
for r in sheet('dict_1991.txt','PESS'):
    if r[0]=='V0329':
        for c,l in re.findall(r'(\d+)- (.*?)(?= \d+- |$)', r[2]): add(1991,'V0329',c,l.replace(' - Pessoas com menos de 10 anos',''))
# 2000 V4354: texto "142  Ciências da educação"
for r in sheet('dict_2000.txt','cursos_V4354'):
    for c in r:
        m=re.match(r'^(\d{3})\s+(.*)$',c)
        if m: add(2000,'V4354',m.group(1),m.group(2))
for r in sheet('dict_2000.txt','cnae_V4462'): add(2000,'V4462',r[0],r[1])
for r in sheet('dict_2010.txt','cursos_superiores'):
    if re.fullmatch(r'\d{3}',r[0]) or (r[0]=='85' and 'SABE' in r[1]): add(2010,'V6352',r[0],r[1])
for r in sheet('dict_2010.txt','cnae_2.0_dom'):
    if len(r)>3 and re.fullmatch(r'\d{5}',r[2]): add(2010,'V6471',r[2],r[3])
with open(out,'w',newline='') as o:
    w=csv.writer(o); w.writerow(['ano','variavel','codigo','rotulo']); w.writerows(res)
from collections import Counter; print(Counter((a,v) for a,v,_,_ in res))
