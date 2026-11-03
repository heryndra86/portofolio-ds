(() => {
 // Preserve bookmarks to the previous single-page sections.
 const routes={work:'work.html',about:'about.html',approach:'about.html#approach',experience:'about.html#experience',education:'about.html#education',organisation:'about.html#organisation',leadership:'about.html#organisation',credentials:'expertise.html',trajectory:'journey.html',contact:'contact.html'};
 if(document.body.classList.contains('portfolio-home')){
  const target=routes[location.hash.slice(1)];
  if(target)location.replace(target);
 }
})();
