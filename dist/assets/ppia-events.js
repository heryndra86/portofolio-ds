(() => {
 const root=document.querySelector('.ppia-interactive-journal');
 const tabs=root?[...root.querySelectorAll('[role=tab]')]:[];
 const panels=root?[...root.querySelectorAll('[role=tabpanel]')]:[];
 const reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;
 let selected=0;
 function activate(index,{focus=false,announce=true,updateUrl=true,scroll=false}={}){
  selected=(index+tabs.length)%tabs.length;
  tabs.forEach((tab,i)=>{tab.setAttribute('aria-selected',String(i===selected));tab.tabIndex=i===selected?0:-1;panels[i].hidden=i!==selected;});
  root.querySelector('.ppia-event-position').textContent=`0${selected+1} / 0${tabs.length}`;
  if(announce)root.querySelector('.ppia-event-status').textContent=`Showing event ${selected+1} of ${tabs.length}: ${tabs[selected].textContent.trim()}`;
  if(updateUrl)history.replaceState(null,'','#'+panels[selected].id);
  if(focus)tabs[selected].focus({preventScroll:true});
  tabs[selected].scrollIntoView({block:'nearest',inline:'nearest',behavior:reduced?'auto':'smooth'});
  if(scroll)root.querySelector('.ppia-event-tabs').scrollIntoView({block:'start',behavior:reduced?'auto':'smooth'});
 }
 if(root && tabs.length){
  root.classList.add('is-enhanced');
  const initial=panels.findIndex(p=>'#'+p.id===location.hash);
  // Avoid changing the reader's initial scroll position during enhancement.
  selected=initial<0?0:initial;
  tabs.forEach((tab,i)=>{tab.setAttribute('aria-selected',String(i===selected));tab.tabIndex=i===selected?0:-1;panels[i].hidden=i!==selected;
   tab.addEventListener('click',e=>{e.preventDefault();activate(i);});
   tab.addEventListener('keydown',e=>{let target;if(e.key==='ArrowRight')target=(i+1)%tabs.length;else if(e.key==='ArrowLeft')target=(i-1+tabs.length)%tabs.length;else if(e.key==='Home')target=0;else if(e.key==='End')target=tabs.length-1;else return;e.preventDefault();activate(target,{focus:true});});
  });
  root.querySelector('.ppia-event-position').textContent=`0${selected+1} / 0${tabs.length}`;
  root.querySelectorAll('[data-event-step]').forEach(b=>b.addEventListener('click',()=>activate(selected+Number(b.dataset.eventStep),{focus:true,scroll:true})));
  addEventListener('hashchange',()=>{const i=panels.findIndex(p=>'#'+p.id===location.hash);if(i>=0)activate(i,{updateUrl:false,announce:false});});
 }
 const dialog=document.querySelector('.ppia-lightbox');
 const photos=[...document.querySelectorAll('.ppia-photo-open')];
 if(!dialog || !photos.length)return;
 let index=0,opener=null,activePhotos=photos;
 const render=()=>{const button=activePhotos[index],img=dialog.querySelector('img');img.src=button.dataset.photo;img.alt=button.querySelector('img').alt;dialog.querySelector('figcaption').textContent=button.dataset.caption;dialog.querySelector('.ppia-lightbox-count').textContent=`${index+1} / ${activePhotos.length}`;dialog.querySelector('.ppia-lightbox-navigation').hidden=activePhotos.length===1;};
 photos.forEach(button=>button.addEventListener('click',()=>{const panel=button.closest('.ppia-story-panel');activePhotos=panel?[...panel.querySelectorAll('.ppia-photo-open')]:photos;index=activePhotos.indexOf(button);opener=button;render();dialog.showModal();}));
 dialog.querySelector('.ppia-lightbox-close').addEventListener('click',()=>dialog.close());
 const step=direction=>{index=(index+direction+activePhotos.length)%activePhotos.length;render();};
 dialog.querySelector('.ppia-lightbox-prev').addEventListener('click',()=>step(-1));
 dialog.querySelector('.ppia-lightbox-next').addEventListener('click',()=>step(1));
 dialog.addEventListener('keydown',e=>{if(e.key==='ArrowLeft'){e.preventDefault();step(-1);}if(e.key==='ArrowRight'){e.preventDefault();step(1);}});
 dialog.addEventListener('close',()=>{if(opener)opener.focus({preventScroll:true});});
 dialog.addEventListener('click',e=>{if(e.target===dialog){const r=dialog.getBoundingClientRect();if(e.clientX<r.left || e.clientX>r.right || e.clientY<r.top || e.clientY>r.bottom)dialog.close();}});
})();
