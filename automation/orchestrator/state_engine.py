from pathlib import Path
import json, yaml, datetime
ROOT=Path(__file__).resolve().parents[2]
STATE=ROOT/'automation/state/current.json'; TASKS=ROOT/'automation/state/tasks.yaml'; CHECKPOINTS=ROOT/'automation/state/checkpoints.jsonl'
def load_state(): return json.loads(STATE.read_text(encoding='utf-8'))
def save_state(s):
 s['updatedAt']=datetime.datetime.now(datetime.UTC).isoformat(); STATE.write_text(json.dumps(s,ensure_ascii=False,indent=2),encoding='utf-8')
def load_tasks(): return yaml.safe_load(TASKS.read_text(encoding='utf-8'))
def next_ready(doc):
 done={t['id'] for t in doc['tasks'] if t['status']=='DONE'}
 for t in doc['tasks']:
  if t['status'] in ('READY','BACKLOG') and all(d in done for d in t.get('depends_on',[])): return t
 return None
def checkpoint(note,agent=None):
 s=load_state(); row={'at':datetime.datetime.now(datetime.UTC).isoformat(),'agent':agent,'task':s.get('activeTask'),'status':s.get('status'),'note':note}
 with CHECKPOINTS.open('a',encoding='utf-8') as f: f.write(json.dumps(row,ensure_ascii=False)+'\n')
