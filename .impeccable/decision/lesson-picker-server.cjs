const http=require('http'),fs=require('fs'),path=require('path');
const root=path.resolve(__dirname,'../..');
const mime={'.html':'text/html; charset=utf-8','.png':'image/png','.ttf':'font/ttf'};
const server=http.createServer((req,res)=>{
 if(req.method==='POST'&&req.url==='/selection'){
  let body='';req.on('data',c=>{body+=c;if(body.length>4096)req.destroy()});req.on('end',()=>{try{const v=JSON.parse(body);if(!['story','notes','caption'].includes(v.design)||!['warm','night','grove','orbit'].includes(v.palette))throw Error();fs.writeFileSync(path.join(__dirname,'lesson-card-selection.json'),JSON.stringify(v,null,2));res.writeHead(200,{'Content-Type':'application/json'});res.end('{"saved":true}')}catch{res.writeHead(400);res.end()}});return;
 }
 if(req.method!=='GET'){res.writeHead(405);res.end();return}
 let url;try{url=decodeURIComponent(req.url.split('?')[0])}catch{res.writeHead(400);res.end();return}
 if(url==='/')url='/.impeccable/decision/lesson-cards.html';
 const allowed=url==='/.impeccable/decision/lesson-cards.html'||/^\/\.impeccable\/review\/outline-stage-[0-3]\.png$/.test(url)||url==='/neighborhood_assets/preview/fonts/Fredoka.ttf';
 if(!allowed){res.writeHead(404);res.end();return}
 const file=path.join(root,url);fs.readFile(file,(err,data)=>{if(err){res.writeHead(404);res.end();return}res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});res.end(data)});
});server.listen(56671,'127.0.0.1',()=>console.log('Lesson picker: http://127.0.0.1:56671'));
