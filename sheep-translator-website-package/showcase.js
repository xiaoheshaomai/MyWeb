const scriptPages = [...document.querySelectorAll('[data-script-page]')];
const scriptStack = document.querySelector('.script-pages');
const scriptNext = document.querySelector('.script-next');

if (scriptPages.length && scriptStack && scriptNext) {
  let currentScriptPage = 0;

  const showScriptPage = (index) => {
    currentScriptPage = index % scriptPages.length;
    scriptPages.forEach((page, pageIndex) => {
      const active = pageIndex === currentScriptPage;
      page.classList.toggle('is-active', active);
      page.setAttribute('aria-hidden', String(!active));
    });
    scriptNext.innerHTML = `${currentScriptPage === scriptPages.length - 1 ? '回到第一页' : '下一页'}&nbsp; ${currentScriptPage + 1} / ${scriptPages.length}&nbsp; →`;
  };

  const turnPage = () => showScriptPage(currentScriptPage + 1);
  scriptNext.addEventListener('click', (event) => {
    event.stopPropagation();
    turnPage();
  });
  scriptStack.addEventListener('click', (event) => {
    if (!event.target.closest('a, button, [contenteditable="true"]')) turnPage();
  });
}

const COPY_KEY = `sheep-translator-showcase-copy-v1:${location.pathname}`;
const editableSelectors = [
  'main h1', 'main h2', 'main h3', 'main p', 'main li',
  '.tech-detail > div > b', '.tech-detail > div > span',
  'footer b', 'footer span'
];
const editables = [];

editableSelectors.forEach((selector) => {
  document.querySelectorAll(selector).forEach((element, index) => {
    if (editables.includes(element) || element.closest('.mock-screen, .browser-bar')) return;
    const section = element.closest('section')?.id || 'footer';
    const className = [...element.classList].join('.') || element.tagName.toLowerCase();
    element.dataset.editKey = `${section}:${className}:${index}`;
    element.contentEditable = 'true';
    element.spellcheck = false;
    element.classList.add('editable-copy');
    editables.push(element);
  });
});

const saveStatus = document.createElement('div');
saveStatus.className = 'copy-save-status';
saveStatus.textContent = '文字可直接编辑 · 已保存';
document.body.appendChild(saveStatus);

try {
  const saved = JSON.parse(localStorage.getItem(COPY_KEY) || '{}');
  editables.forEach((element) => {
    if (Object.hasOwn(saved, element.dataset.editKey)) {
      element.innerHTML = saved[element.dataset.editKey];
    }
  });
} catch (error) {
  saveStatus.textContent = '本地文字读取失败';
}

let saveTimer;
const saveCopy = () => {
  try {
    const saved = {};
    editables.forEach((element) => {
      saved[element.dataset.editKey] = element.innerHTML;
    });
    localStorage.setItem(COPY_KEY, JSON.stringify(saved));
    saveStatus.textContent = '文字可直接编辑 · 已保存';
  } catch (error) {
    saveStatus.textContent = '保存失败，请先复制文字备份';
  }
};

editables.forEach((element) => {
  element.addEventListener('input', () => {
    saveStatus.textContent = '正在保存…';
    clearTimeout(saveTimer);
    saveTimer = setTimeout(saveCopy, 350);
  });
  element.addEventListener('blur', saveCopy);
});
