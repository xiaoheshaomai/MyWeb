(() => {
  const source = new URL(document.currentScript.src);
  const section = /\/(hackathon|sheep-translator-website-package)\//.test(location.pathname) ? 'competition' : 'projects';
  const home = new URL('../v2/index.html#' + section, source);
  const button = document.createElement('a');
  button.className = 'portfolio-home-button';
  button.href = home.href;
  button.setAttribute('aria-label', section === 'competition' ? '返回比赛经历' : '返回项目经历');
  button.title = button.getAttribute('aria-label');
  button.innerHTML = '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M19 12H5m7-7-7 7 7 7" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  const style = document.createElement('style');
  style.textContent = `
    .portfolio-home-button{position:fixed;top:14px;left:18px;z-index:10000;display:flex;align-items:center;justify-content:center;width:48px;height:48px;padding:8px;background:transparent;color:#fff;mix-blend-mode:difference;border:0;border-radius:0;text-decoration:none;box-shadow:none;transition:transform .18s}
    .portfolio-home-button svg{display:block;width:30px;height:30px}
    .portfolio-home-button:hover{transform:translateX(-3px)}
    .portfolio-home-button:focus-visible{outline:3px solid #ff4fc8;outline-offset:4px}
    @media(max-width:600px){.portfolio-home-button{top:8px;left:10px}}
  `;
  document.head.append(style);
  document.body.append(button);
})();
