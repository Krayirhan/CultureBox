def route(task):
 text=(task.get('title','')+' '+task.get('phase','')).lower(); tools=['graphify','serena']
 if any(k in text for k in ['flutter','provider','firebase','drift','ui']): tools.append('context7')
 if 'firebase' in text: tools.append('firebase')
 if any(k in text for k in ['ui','design','visual']): tools.append('figma')
 if any(k in text for k in ['release','store','github']): tools.append('github')
 return list(dict.fromkeys(tools))
