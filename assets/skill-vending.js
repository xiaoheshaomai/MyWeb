(() => {
 const page=document.querySelector('.page[data-slide="5"]');
 if(!page)return;
 page.classList.add('vending-page');
 page.querySelector('.title').textContent='技能贩卖机';
 page.querySelector('.index').textContent='05 / A LITTLE MORE ABOUT ME';
 document.querySelector('.tab[data-page="5"]').textContent='其他技能';
 const stage=document.createElement('div');stage.className='vending-stage';
 stage.innerHTML=`<div class="skill-machine">
 <div class="machine-sign"><span>XIAOHE’S</span><strong>SKILL SHOP</strong><i>营业中 ●</i></div>
 <div class="machine-window">
 <button class="skill-shelf" data-skill="0"><span class="skill-can can-pink">Aa<small>ENGLISH</small></span><span class="shelf-name"><b>英语</b></span><span class="vend-key">01 ↘</span></button>
 <button class="skill-shelf" data-skill="1"><span class="skill-can can-green">&lt;/&gt;<small>CODE + AI</small></span><span class="shelf-name"><b>开发与 AI</b></span><span class="vend-key">02 ↘</span></button>
 <button class="skill-shelf" data-skill="2"><span class="skill-can can-yellow">✳<small>CREATE</small></span><span class="shelf-name"><b>创意工具</b></span><span class="vend-key">03 ↘</span></button>
 </div><div class="machine-bottom"><div class="vend-slot" aria-hidden="true"><span class="falling-can"></span><small>PICK UP HERE ↓</small></div></div>
 </div><div class="receipt-area"><div class="receipt-empty"><h3>选一项技能！</h3><p>点击左侧按钮，<br>查看对应的技能小票。</p></div><article class="skill-receipt" hidden aria-live="polite"></article></div>`;
 page.querySelector('.life-table').replaceWith(stage);
 const data=[
 {name:'英语',code:'01 / ENGLISH'},
 {name:'开发与 AI',code:'02 / CODE + AI',tools:[['Py','Python','python'],['JS','JavaScript','js'],['</>','HTML / CSS','html'],['>_','Codex','codex']]},
 {name:'创意工具',code:'03 / CREATIVE TOOLS',tools:[['Ps','Photoshop','ps'],['剪','剪映','capcut'],['B','Blender','blender']]}
 ];
 let busy=false;
 const receipt=stage.querySelector('.skill-receipt'),slot=stage.querySelector('.vend-slot'),buttons=[...stage.querySelectorAll('.skill-shelf')];
 buttons.forEach(button=>button.addEventListener('click',()=>{
   if(busy)return;busy=true;
   const i=+button.dataset.skill,item=data[i];
   buttons.forEach(b=>{b.disabled=true;b.classList.toggle('selected',b===button)});
   receipt.hidden=true;stage.querySelector('.receipt-empty').hidden=true;
   const can=slot.querySelector('.falling-can');
   can.textContent=['Aa','</>','✳'][i];can.style.background=['#ff4fc8','#00ff2a','#ffe32d'][i];
   slot.classList.remove('dispensing');void slot.offsetWidth;slot.classList.add('dispensing');
   setTimeout(()=>{
     receipt.replaceChildren();
     const h=document.createElement('h3');h.textContent=item.name;
     const content=document.createElement('div');
     if(i===0){
       content.className='language-score';
       content.innerHTML='<span class="ielts-wordmark">雅思</span><strong>7.5</strong><div class="cet-marks"><span>CET-4</span><span>CET-6</span></div>';
     }else{
       content.className='tool-marks';
       item.tools.forEach(([mark,name,color])=>{
         const tool=document.createElement('div');tool.className='tool-mark';
         const icon=document.createElement('span');icon.className='tool-symbol '+color;icon.textContent=mark;icon.setAttribute('aria-hidden','true');
         const label=document.createElement('b');label.textContent=name;tool.append(icon,label);content.append(tool);
       });
     }
     receipt.append(h,content);
     if(i===1){
       const usage=document.createElement('div');usage.className='codex-usage';
       usage.innerHTML='<span>Codex 累计 Token</span><strong>13.8 <small>亿</small></strong>';
       receipt.append(usage);
     }
     receipt.hidden=false;
     busy=false;buttons.forEach(b=>b.disabled=false);
   },matchMedia('(prefers-reduced-motion: reduce)').matches?0:650);
 }));
})();
