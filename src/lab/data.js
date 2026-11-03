// Deliberately illustrative UI response, unrelated to fitted wine models.
export function illustrativeScore({alcohol,acidity,sulphates}) {
  return Math.max(0,Math.min(10,5.5+.15*(alcohol-10)+.03*(acidity-6)+.2*(sulphates-.6)));
}
export function industryView(yearData,industry='All') {
  const entries=Object.entries(yearData.industries).filter(([name])=>industry==='All'||name===industry).sort((a,b)=>b[1]-a[1]);
  return {entries,total:entries.reduce((s,[,kg])=>s+kg,0),facilities:yearData.facilities.filter(f=>industry==='All'||f.industry===industry)};
}
