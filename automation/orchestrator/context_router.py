H={'firebase':['docs/FIREBASE_ARCHITECTURE.md','docs/FIRESTORE_SCHEMA.md','docs/SECURITY.md'],'provider':['docs/PROVIDERS.md','docs/DOMAIN_MODEL.md','docs/TESTING.md'],'ui':['docs/UX_SPEC.md','docs/DESIGN_SYSTEM.md','docs/MOBILE_ARCHITECTURE.md'],'sync':['docs/SYNC_STRATEGY.md','docs/LOCAL_DATABASE.md','docs/FIRESTORE_SCHEMA.md'],'release':['docs/CI_CD_RELEASE.md','docs/STORE_AUTOMATION.md','docs/SECURITY.md']}
def route(task):
 docs=list(task.get('required_docs',[])); text=(task.get('title','')+' '+task.get('phase','')).lower()
 for k,v in H.items():
  if k in text: docs.extend(v)
 return list(dict.fromkeys(docs))
