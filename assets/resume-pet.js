(() => {
  if (document.querySelector('.resume-pet')) return;
  const source = new URL(document.currentScript.src);
  const pet = document.createElement('div');
  pet.className = 'resume-pet';
  const link = document.createElement('a');
  link.href = new URL('../v2/assets/张宜砚_简历.pdf', source).href;
  link.download = '张宜砚_简历.pdf';
  link.textContent = '下载简历';
  const handle = document.createElement('button');
  handle.type = 'button';
  handle.setAttribute('aria-label', '拖动小人调整位置，也可用方向键移动');
  const img = document.createElement('img');
  img.src = new URL('resume-dance.gif', source).href;
  img.alt = '';
  img.draggable = false;
  handle.append(img);
  pet.append(link, handle);
  const style = document.createElement('style');
  style.textContent = `
    .resume-pet{position:fixed;right:max(12px,calc(6vw - 14px));bottom:calc(18vh - 20px);width:110px;z-index:10001;display:flex;flex-direction:column;align-items:center;user-select:none}
    .resume-pet>a{position:relative;display:block;padding:10px 14px;margin-bottom:12px;border:2px solid #111;border-radius:18px;background:#fff;color:#111;text-decoration:none;white-space:nowrap;font:700 14px/1.2 Arial,"PingFang SC",sans-serif}
    .resume-pet>a:after{content:"";position:absolute;bottom:-7px;left:46px;width:10px;height:10px;background:#fff;border-right:2px solid #111;border-bottom:2px solid #111;transform:rotate(45deg)}
    .resume-pet>button{display:block;width:110px;height:110px;padding:0;border:0;background:transparent;cursor:grab;touch-action:none}
    .resume-pet>button:active{cursor:grabbing}
    .resume-pet img{display:block;width:100%;height:100%;object-fit:contain;pointer-events:none}
    .resume-pet a:focus-visible,.resume-pet button:focus-visible{outline:3px solid #ff4fc8;outline-offset:4px}
  `;
  document.head.append(style);
  document.body.append(pet);
  const dancers = [
    {file:'resume-dance.gif', hue:295},
    {file:'resume-blue.gif', hue:207},
    {file:'resume-yellow.gif', hue:60},
    {file:'resume-green.gif', hue:100},
    {file:'home-dance.gif', hue:172}
  ];
  let lastPage = '';
  let lastDancer = -1;
  function rotateDancer() {
    const active = document.querySelector('.page.active, .slide.active, .slide.is-active, section.active');
    const key = location.pathname + location.hash + (active?.dataset.slide || active?.id || '');
    if (key === lastPage) return;
    lastPage = key;
    let bg = active || document.body;
    let rgb;
    while (bg) {
      const color = getComputedStyle(bg).backgroundColor;
      if (color !== 'rgba(0, 0, 0, 0)' && color !== 'transparent') {
        rgb = color.match(/[\d.]+/g)?.slice(0,3).map(Number);
        break;
      }
      bg = bg.parentElement;
    }
    let hue = null;
    if (rgb) {
      const [r,g,b] = rgb.map(v => v/255), max = Math.max(r,g,b), min = Math.min(r,g,b), d = max-min;
      if (d > .15) {
        hue = max===r ? ((g-b)/d)%6 : max===g ? (b-r)/d+2 : (r-g)/d+4;
        hue = (hue*60+360)%360;
      }
    }
    const seed = [...key].reduce((n,c) => n+c.charCodeAt(0),0);
    const candidates = dancers.map((d,i)=>i).filter(i => {
      const diff = hue === null ? 180 : Math.abs(dancers[i].hue-hue);
      return i !== lastDancer && Math.min(diff,360-diff) > 55;
    });
    const chosen = candidates[seed % candidates.length] ?? 0;
    lastDancer = chosen;
    img.src = new URL(dancers[chosen].file, source).href;
  }
  rotateDancer();
  addEventListener('hashchange', rotateDancer);
  new MutationObserver(rotateDancer).observe(document.body, {subtree:true,attributes:true,attributeFilter:['class']});
  function place(x, y) {
    pet.style.right = 'auto';
    pet.style.bottom = 'auto';
    pet.style.left = Math.max(0, Math.min(x, innerWidth - pet.offsetWidth)) + 'px';
    pet.style.top = Math.max(0, Math.min(y, innerHeight - pet.offsetHeight)) + 'px';
  }
  let moved = false;
  function initialPosition() {
    const cloud = document.querySelector('.cover.active .cover-cloud:last-of-type');
    const clouds = document.querySelectorAll('.cover.active .cover-cloud');
    const anchor = clouds.length ? clouds[clouds.length - 1] : cloud;
    if (anchor) {
      const r = anchor.getBoundingClientRect();
      place(r.left + r.width / 2 - pet.offsetWidth / 2, r.top + 20 - pet.offsetHeight);
    }
  }
  requestAnimationFrame(initialPosition);
  let drag;
  handle.addEventListener('pointerdown', e => {
    if (e.button !== 0) return;
    const r = pet.getBoundingClientRect();
    drag = {x: e.clientX - r.left, y: e.clientY - r.top};
    handle.setPointerCapture(e.pointerId);
  });
  handle.addEventListener('pointermove', e => {
    if (drag) {
      moved = true;
      place(e.clientX - drag.x, e.clientY - drag.y);
    }
  });
  const end = () => { drag = null; };
  handle.addEventListener('pointerup', end);
  handle.addEventListener('pointercancel', end);
  handle.addEventListener('lostpointercapture', end);
  handle.addEventListener('keydown', e => {
    const delta = {ArrowLeft:[-12,0],ArrowRight:[12,0],ArrowUp:[0,-12],ArrowDown:[0,12]}[e.key];
    if (!delta) return;
    e.preventDefault();
    moved = true;
    const r = pet.getBoundingClientRect();
    place(r.left + delta[0], r.top + delta[1]);
  });
  addEventListener('resize', () => {
    if (!moved && document.querySelector('.cover.active')) {
      initialPosition();
      return;
    }
    const r = pet.getBoundingClientRect();
    place(r.left, r.top);
  });
})();
