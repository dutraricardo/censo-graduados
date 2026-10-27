import sys, openpyxl, glob, os
for f in sorted(glob.glob('/tmp/claude-0/cache/*/*_dictionary_microdata.xlsx')):
    y=os.path.basename(f)[:4]; wb=openpyxl.load_workbook(f, read_only=True, data_only=True)
    with open(f'dict_{y}.txt','w') as o:
        for ws in wb.worksheets:
            o.write(f'=== SHEET {ws.title}\n')
            for r in ws.iter_rows(values_only=True):
                if any(c is not None for c in r): o.write(' | '.join('' if c is None else str(c).replace('\n',' ') for c in r)+'\n')
    print(y, [ws.title for ws in wb.worksheets])
