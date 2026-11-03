import {build} from 'esbuild';
import {mkdir,writeFile,copyFile,readFile,readdir,unlink} from 'node:fs/promises';
import {gzipSync} from 'node:zlib';
await mkdir('dist/assets/lab',{recursive:true});
for(const file of await readdir('dist/assets/lab'))if(/^scene-.*\.js$/.test(file))await unlink('dist/assets/lab/'+file);
const saved=JSON.parse(await readFile('dist/assets/shiny/explorer.json','utf8')),preview={};
for(const [year,d]of Object.entries(saved)){const industries={};for(const [industry,,kg]of d.flows)industries[industry]=(industries[industry]||0)+kg;const facilities=Object.keys(industries).flatMap(industry=>d.facilities.filter(f=>f.industry===industry).sort((a,b)=>b.kg-a.kg).slice(0,12));preview[year]={industries,total:Object.values(industries).reduce((s,x)=>s+x,0),facilities};}
await writeFile('dist/assets/lab/emissions.json',JSON.stringify(preview));
const result=await build({entryPoints:['src/lab/controller.js'],outdir:'dist/assets/lab',entryNames:'featured-lab',chunkNames:'[name]-[hash]',bundle:true,splitting:true,format:'esm',target:'es2020',minify:true,metafile:true,legalComments:'eof'});
await copyFile('src/lab/loader.js','dist/assets/featured-lab-loader.js');
const stats={};for(const [p,v]of Object.entries(result.metafile.outputs))stats[p]={bytes:v.bytes,gzipBytes:gzipSync(await readFile(p)).length};
await writeFile('src/lab/build-stats.json',JSON.stringify(stats,null,2));console.log('Built lazy-loaded project lab:',stats);
