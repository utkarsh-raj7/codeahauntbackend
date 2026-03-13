#!/bin/bash
mkdir -p ~/logs
python3 -c "
import random, datetime
levels = ['INFO','WARN','ERROR','DEBUG']
services = ['api','worker','db','cache']
base = datetime.datetime(2026,3,1,10,0,0)
with open('/home/labuser/logs/app.log','w') as f:
    for i in range(200):
        ts = base + datetime.timedelta(seconds=i*17)
        lvl = random.choices(levels, weights=[60,20,10,10])[0]
        svc = random.choice(services)
        msg = {'INFO':'Request processed','WARN':'High memory usage',
               'ERROR':'Connection refused','DEBUG':'Cache hit'}[lvl]
        f.write(f'{ts.strftime(\"%Y-%m-%d %H:%M:%S\")} [{lvl}] {svc}: {msg}\n')
"
echo "200 log lines generated in ~/logs/app.log"
echo "Tasks: count ERRORs, extract unique services, find peak error times"
