#!/usr/bin/env python
import argparse,json
from state_engine import load_state,load_tasks,next_ready,save_state,checkpoint
from context_router import route as rc
from tool_router import route as rt
p=argparse.ArgumentParser(); p.add_argument('command',choices=['status','next','checkpoint']); p.add_argument('--note',default='manual checkpoint'); a=p.parse_args()
if a.command=='status': print(json.dumps(load_state(),indent=2,ensure_ascii=False))
elif a.command=='checkpoint': checkpoint(a.note); print('checkpoint written')
else:
 t=next_ready(load_tasks())
 if not t: print('No ready task.')
 else:
  s=load_state(); s.update({'activeTask':t['id'],'phase':t['phase'],'status':'ready','nextAction':f"Execute {t['id']}: {t['title']}"}); save_state(s)
  print(json.dumps({'task':t,'context':rc(t),'tools':rt(t)},indent=2,ensure_ascii=False))
