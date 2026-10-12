(() => {
 const fan = location.pathname.includes('fan-restaurant');
 // The podcast case study is intentionally a normal vertical story page.
 // Keep the deck treatment only for the FAN project.
 if (!fan) return;
 const root = document.createElement('main');
 root.className = 'case-deck';
 const slides = [];
 function add(node) {
   const slide = document.createElement('section');
   slide.className = 'case-slide';
   const inner = document.createElement('div');
   inner.className = 'case-inner';
   inner.append(node); slide.append(inner); root.append(slide); slides.push(slide);
 }
 function gallery(title, files, captions) {
   const el = document.createElement('div');
   el.className = 'case-gallery';
   const h = document.createElement('h2'); h.textContent = title; el.append(h);
   const grid = document.createElement('div'); grid.className = 'case-gallery-grid';
   files.forEach((file,i) => {
     const fig = document.createElement('figure'), img = document.createElement('img'), cap = document.createElement('figcaption');
     img.src = 'assets/' + file; img.alt = captions[i]; cap.textContent = captions[i];
     fig.append(img, cap); grid.append(fig);
   });
   el.append(grid); return el;
 }
 if(fan) {
   const hero = document.querySelector('.hero');
   const photo = document.createElement('img'); photo.className='case-hero-photo'; photo.src='assets/fan-card-kitchen.jpg'; photo.alt='FAN 餐厅厨房现场';
   hero.append(photo); add(hero);
   const poster = document.getElementById('poster');
   add(poster);
   slides[slides.length-1].classList.add('poster-slide');
   const sections = [...document.querySelectorAll('main.wrap > .section')];
   sections.forEach((section,i) => {
     if(i===0) {
       section.classList.add('fan-context');
       const copy=document.createElement('div');copy.className='fan-context-copy';
       while(section.firstChild)copy.append(section.firstChild);
       const dining=document.createElement('img');dining.className='fan-dining-photo';
       dining.src='assets/fan-dining.png';dining.alt='FAN 餐厅料理与餐桌陈设';
       section.append(dining,copy);
     }
     const solution = section.querySelector('.solution');
     if(solution) solution.remove();
     if(i===1) {
       section.classList.add('field-research-slide');
       const photos = gallery('', ['fan-field-1.jpeg','fan-field-2.jpeg','fan-field-3.jpeg'], ['库存现场 01','库存现场 02','库存现场 03']);
       photos.querySelector('h2').remove();
       section.append(photos);
     }
     add(section);
     if(solution) {
       const combined=document.createElement('div');
       combined.className='solution-showcase';
       const demo=document.createElement('div');demo.className='fan-video-demo';
       const phone=document.createElement('div');phone.className='fan-video-phone';
       const video=document.createElement('video');
       video.src='assets/fan-demo.mov';video.controls=true;video.playsInline=true;video.preload='metadata';
       video.setAttribute('aria-label','FAN 库存系统操作演示');
       phone.append(video);demo.append(phone);combined.append(solution,demo);
       add(combined);
       slides[slides.length-1].classList.add('solution-slide');
     }
   });
 } else {
   add(document.querySelector('.hero'));
   add(document.querySelector('.opening-media'));
   document.querySelectorAll('body > .section, body > .insight').forEach(add);
   document.querySelectorAll('.demo').forEach(add);
   add(document.querySelector('.outro'));
 }
 document.body.classList.add('case-mode', fan ? 'case-fan' : 'case-podcast');
 document.body.append(root);
 document.querySelectorAll('body > main.wrap, body > .demos-shell, body > footer').forEach(el=>el.remove());
 const controls = document.createElement('div'); controls.className='case-controls';
 const prev=document.createElement('button'), next=document.createElement('button'), count=document.createElement('span');
 const arrow = '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M5 12h14m-7-7 7 7-7 7" stroke="currentColor" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
 prev.innerHTML=arrow; prev.className='case-prev'; prev.setAttribute('aria-label','上一页');
 next.innerHTML=arrow; next.className='case-next';
 controls.append(prev,count,next); document.body.append(controls);
 let current=0;
 function fit() {
   const inner=slides[current].firstElementChild;
   inner.style.transform='none';
   const scale=Math.min(1,(innerHeight-(slides[current].classList.contains('poster-slide')?40:110))/inner.scrollHeight);
   inner.style.transform='scale('+scale+')';
 }
 function go(i) {
   current=Math.max(0,Math.min(slides.length-1,i));
   slides.forEach((slide,n)=>{slide.classList.toggle('is-current',n===current);slide.inert=n!==current;});
   slides.forEach((slide,n)=>{if(n!==current)slide.querySelectorAll('video').forEach(video=>video.pause());});
   prev.hidden=current===0;
   next.innerHTML=current===slides.length-1 ? '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M4 10a8 8 0 1 1 1 8M4 4v6h6" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>' : arrow;
   next.setAttribute('aria-label',current===slides.length-1?'重新播放':'下一页');
   count.textContent=String(current+1).padStart(2,'0')+' / '+String(slides.length).padStart(2,'0');
   fit();
 }
 prev.onclick=()=>go(current-1); next.onclick=()=>go(current===slides.length-1?0:current+1);
 addEventListener('keydown',e=>{
   if(e.target.closest('input,textarea,button,a,[contenteditable="true"]'))return;
   if(e.key==='ArrowRight'){e.preventDefault();go(current+1)}
   if(e.key==='ArrowLeft'){e.preventDefault();go(current-1)}
 });
 let touch;
 root.addEventListener('touchstart',e=>{touch=[e.touches[0].clientX,e.touches[0].clientY]}, {passive:true});
 root.addEventListener('touchend',e=>{
   if(!touch)return;const dx=e.changedTouches[0].clientX-touch[0],dy=e.changedTouches[0].clientY-touch[1];
   if(Math.abs(dx)>60&&Math.abs(dx)>Math.abs(dy)*1.5)go(current+(dx<0?1:-1));touch=null;
 },{passive:true});
 document.addEventListener('click',e=>{
   const a=e.target.closest('a[href^="#"]');if(!a)return;
   const target=document.getElementById(a.hash.slice(1));const index=slides.findIndex(s=>s.contains(target));
   if(index>=0){e.preventDefault();go(index)}
 });
 addEventListener('resize',fit);
 root.querySelectorAll('img').forEach(img=>img.addEventListener('load',fit));
 go(0);
})();
