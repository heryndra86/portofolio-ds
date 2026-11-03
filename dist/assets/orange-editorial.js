(() => {
 const menu = document.querySelector('.menu-toggle');
 const nav = document.querySelector('.nav');
 const close = () => {nav.classList.remove('open'); menu.setAttribute('aria-expanded','false'); menu.textContent='Menu +';};
 menu.addEventListener('click', () => {const open=menu.getAttribute('aria-expanded')!=='true';nav.classList.toggle('open',open);menu.setAttribute('aria-expanded',String(open));menu.textContent=open?'Close −':'Menu +';});
 nav.querySelectorAll('a').forEach(a=>a.addEventListener('click',close));
 document.addEventListener('keydown',e=>{if(e.key==='Escape' && nav.classList.contains('open')){close();menu.focus();}});
 const hero=document.querySelector('.hero');
 const reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;
 if(hero){
  let visible=true;
  let userPaused=reduced;
  const control=document.querySelector(".motion-toggle");
  if(control){if(reduced)control.hidden=true;control.setAttribute("aria-pressed",String(userPaused));control.textContent=userPaused?"Resume animation":"Pause animation";control.addEventListener("click",()=>{userPaused=!userPaused;control.setAttribute("aria-pressed",String(userPaused));control.textContent=userPaused?"Resume animation":"Pause animation";updatePause();});}
  const updatePause=()=>hero.classList.toggle('motion-paused',userPaused || !visible || document.hidden);
  new IntersectionObserver(entries=>{visible=entries[0].isIntersecting;updatePause();},{threshold:0}).observe(hero);
  document.addEventListener('visibilitychange',updatePause);
  updatePause();
 }
 if(!reduced){
  const observer=new IntersectionObserver(entries=>entries.forEach(e=>{if(e.isIntersecting){e.target.classList.remove('pending');observer.unobserve(e.target);}}),{threshold:.08});
  document.querySelectorAll('.intro-grid,.three>div,.work-top,.notebook-card,.edu-line,.cred-future-item,.contact h2').forEach(el=>{el.classList.add('orange-reveal','pending');observer.observe(el);});
 }
})();
