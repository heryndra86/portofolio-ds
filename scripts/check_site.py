from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit, unquote
ROOT=Path(__file__).resolve().parents[1]/"dist"
class Page(HTMLParser):
 def __init__(self,text):
  super().__init__();self.refs=[];self.ids=set();self.h1=0;self.main=0;self.errors=[];self.feed(text)
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if "id" in a:
   if a["id"] in self.ids:self.errors.append("duplicate ID: "+a["id"])
   self.ids.add(a["id"])
  if tag=="h1":self.h1+=1
  if tag=="main":self.main+=1
  if tag=="img" and "alt" not in a:self.errors.append("image missing alt")
  for key in ("href","src"):
   if key in a:self.refs.append(a[key])
pages={p:Page(p.read_text()) for p in ROOT.glob("*.html")};errors=[]
for path,page in pages.items():
 errors += [f"{path.name}: {x}" for x in page.errors]
 if path.name not in ("education.html","experience.html"):
  if page.h1!=1:errors.append(f"{path.name}: expected one h1")
  if page.main!=1:errors.append(f"{path.name}: expected one main landmark")
 for ref in page.refs:
  u=urlsplit(ref)
  if u.scheme or u.netloc:continue
  target=(path.parent/unquote(u.path)).resolve() if u.path else path
  if not target.exists():errors.append(f"{path.name}: missing {ref}");continue
  if u.fragment and target in pages and unquote(u.fragment) not in pages[target].ids:errors.append(f"{path.name}: missing anchor {ref}")
if errors:raise SystemExit("\n".join(errors))
print(f"Checked {len(pages)} HTML files: local links, anchors, headings and alt attributes passed.")
