<!DOCTYPE html>
<html lang="uz">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ARCADE GALAXY — O'yinlar Olami</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
  :root{
    --bg: #05060a;
    --panel: rgba(255,255,255,0.03);
    --violet: #6c5ce7;
    --cyan: #00d9ff;
    --gold: #ffd166;
    --magenta: #ff3cac;
    --green: #2ecc71;
    --red: #ff5c5c;
    --star: #e8ecf9;
    --dim: #8890a8;
  }
  *{ margin:0; padding:0; box-sizing:border-box; }
  html,body{ width:100%; min-height:100%; background:var(--bg); color:var(--star); font-family:'Inter',sans-serif; -webkit-font-smoothing:antialiased; overflow-x:hidden; }
  #bgstars{ position:fixed; inset:0; z-index:-1; display:block; }
  h1,h2,h3,.disp{ font-family:'Space Grotesk',sans-serif; }
  button{ font-family:inherit; cursor:pointer; border:none; }
  input{ font-family:inherit; }

  .screen{ min-height:100vh; width:100%; display:flex; flex-direction:column; align-items:center; justify-content:center; padding:24px; }
  .hidden{ display:none !important; }

  /* ---------- Name screen ---------- */
  #screen-name h1{
    font-size:clamp(38px,8vw,80px); font-weight:700; letter-spacing:-0.02em; text-align:center;
    background:linear-gradient(135deg,var(--star) 15%,var(--cyan) 55%,var(--violet) 95%);
    -webkit-background-clip:text; background-clip:text; color:transparent;
    filter:drop-shadow(0 0 30px rgba(0,217,255,0.3));
  }
  #screen-name p{ color:var(--dim); margin-top:14px; text-align:center; font-size:clamp(14px,2vw,17px); max-width:420px; }
  #name-form{ margin-top:36px; display:flex; gap:10px; flex-wrap:wrap; justify-content:center; }
  #name-input{
    background:rgba(255,255,255,0.06); border:1px solid rgba(232,236,249,0.18); color:var(--star);
    padding:14px 20px; border-radius:14px; font-size:16px; width:260px; outline:none; transition:border-color .2s;
  }
  #name-input:focus{ border-color:var(--cyan); }
  #name-form button{
    background:linear-gradient(135deg,var(--cyan),var(--violet)); color:#05060a; font-weight:700;
    padding:14px 26px; border-radius:14px; font-size:15px; letter-spacing:0.02em; transition:transform .15s;
  }
  #name-form button:hover{ transform:translateY(-2px) scale(1.03); }

  /* ---------- Menu screen ---------- */
  #screen-menu{ justify-content:flex-start; padding-top:56px; }
  .menu-head{ text-align:center; margin-bottom:36px; }
  .menu-head h2{ font-size:clamp(26px,5vw,44px); font-weight:700; }
  .menu-head h2 span{ color:var(--gold); }
  .menu-head p{ color:var(--dim); margin-top:8px; font-size:14px; }

  .game-grid{
    display:grid; grid-template-columns:repeat(auto-fill,minmax(220px,1fr));
    gap:18px; width:100%; max-width:1100px;
  }
  .game-card{
    background:var(--panel); border:1px solid rgba(232,236,249,0.1); border-radius:20px;
    padding:24px 20px; text-align:left; color:var(--star); transition:transform .2s, border-color .2s, background .2s;
    display:flex; flex-direction:column; gap:8px;
  }
  .game-card:hover{ transform:translateY(-6px); border-color:var(--cyan); background:rgba(0,217,255,0.06); }
  .gc-emoji{ font-size:34px; filter:drop-shadow(0 0 10px rgba(255,255,255,0.15)); }
  .gc-title{ font-family:'Space Grotesk',sans-serif; font-weight:700; font-size:18px; }
  .gc-desc{ font-size:13px; color:var(--dim); line-height:1.4; }

  /* ---------- Game screen ---------- */
  #screen-game{ justify-content:flex-start; padding-top:24px; }
  .game-top{ display:flex; align-items:center; justify-content:space-between; width:100%; max-width:900px; margin-bottom:16px; }
  #back-btn{
    background:rgba(255,255,255,0.06); border:1px solid rgba(232,236,249,0.15); color:var(--star);
    padding:10px 18px; border-radius:12px; font-size:13px; letter-spacing:0.04em;
  }
  #back-btn:hover{ border-color:var(--cyan); }
  #game-title-el{ font-weight:700; font-size:20px; }
  #game-area{
    position:relative; width:100%; max-width:900px; height:min(64vh,560px); min-height:420px;
    background:rgba(255,255,255,0.02); border:1px solid rgba(232,236,249,0.08); border-radius:22px; overflow:hidden;
  }
  .game-wrap{ position:relative; width:100%; height:100%; z-index:1; }
  .game-wrap.center{ display:flex; flex-direction:column; align-items:center; justify-content:center; gap:16px; padding:24px; text-align:center; }
  .game-wrap canvas{ position:absolute; inset:0; width:100%; height:100%; touch-action:none; cursor:crosshair; }
  .game-icon-bg{
    position:absolute; inset:0; display:flex; align-items:center; justify-content:center;
    font-size:min(45vw,240px); opacity:0.06; z-index:0; pointer-events:none; filter:blur(1px);
  }
  .hud-bar{
    position:absolute; top:0; left:0; right:0; z-index:2; display:flex; justify-content:space-between; gap:12px;
    padding:14px 20px; font-size:13px; background:linear-gradient(to bottom, rgba(5,6,10,0.85), transparent);
    pointer-events:none;
  }
  .hud-bar b{ color:var(--gold); }

  /* ---------- Tic Tac Toe ---------- */
  .ttt-status{ color:var(--dim); font-size:14px; }
  .ttt-board{ display:grid; grid-template-columns:repeat(3,84px); grid-template-rows:repeat(3,84px); gap:8px; }
  .ttt-cell{
    background:rgba(255,255,255,0.05); border:1px solid rgba(232,236,249,0.15); border-radius:14px;
    font-size:34px; color:var(--star); display:flex; align-items:center; justify-content:center; transition:background .15s;
  }
  .ttt-cell:not(:disabled):hover{ background:rgba(0,217,255,0.12); }

  /* ---------- Memory ---------- */
  .mem-status{ position:absolute; top:14px; left:0; right:0; text-align:center; font-size:13px; color:var(--dim); z-index:2; }
  .mem-status b{ color:var(--gold); }
  .mem-grid{
    position:absolute; inset:0; top:44px; display:grid; grid-template-columns:repeat(4,1fr); grid-auto-rows:1fr;
    gap:10px; padding:16px;
  }
  .mem-card{
    background:rgba(255,255,255,0.06); border:1px solid rgba(232,236,249,0.15); border-radius:12px;
    font-size:clamp(20px,4vw,30px); display:flex; align-items:center; justify-content:center; color:var(--star);
    transition:background .15s, transform .15s;
  }
  .mem-card.flipped, .mem-card.matched{ background:rgba(108,92,231,0.18); border-color:var(--violet); }
  .mem-card.matched{ opacity:0.55; }

  /* ---------- Reaction ---------- */
  .rx-box{
    width:100%; height:100%; display:flex; align-items:center; justify-content:center;
    background:#2a1414; transition:background .15s;
  }
  .rx-box.wait{ background:#2a1414; }
  .rx-box.go{ background:#0f3d24; }
  .rx-text{ font-family:'Space Grotesk',sans-serif; font-size:clamp(20px,4vw,32px); font-weight:700; text-align:center; padding:20px; }

  /* ---------- RPS ---------- */
  .rps-score{ font-size:15px; color:var(--dim); }
  .rps-score b{ color:var(--gold); }
  .rps-result{ font-size:16px; font-weight:600; min-height:24px; }
  .rps-choices{ display:flex; gap:14px; }
  .rps-btn{
    background:rgba(255,255,255,0.05); border:1px solid rgba(232,236,249,0.15); border-radius:16px;
    padding:16px 20px; font-size:15px; color:var(--star); line-height:1.6; transition:transform .15s, border-color .15s;
  }
  .rps-btn:hover{ transform:translateY(-4px); border-color:var(--magenta); }

  /* ---------- Snake ---------- */
  .sn-score{ position:absolute; top:14px; left:18px; font-size:13px; z-index:2; }
  .sn-score b{ color:var(--gold); }
  .sn-dpad{ position:absolute; bottom:14px; left:0; right:0; display:flex; flex-direction:column; align-items:center; gap:6px; z-index:2; }
  .sn-dpad-row{ display:flex; gap:6px; }
  .sn-dbtn{
    width:44px; height:44px; background:rgba(255,255,255,0.08); border:1px solid rgba(232,236,249,0.2);
    border-radius:10px; color:var(--star); font-size:18px; display:flex; align-items:center; justify-content:center;
  }
  .sn-dbtn:active{ background:rgba(0,217,255,0.25); }

  /* ---------- Catch stars ---------- */
  .cs-hud{ position:absolute; top:14px; left:0; right:0; text-align:center; font-size:13px; z-index:2; }
  .cs-hud b{ color:var(--gold); }

  /* ---------- Guess number ---------- */
  .gn-wrap p{ color:var(--dim); font-size:14px; max-width:360px; }
  .gn-input-row{ display:flex; gap:10px; }
  #gn-input{
    background:rgba(255,255,255,0.06); border:1px solid rgba(232,236,249,0.2); color:var(--star);
    padding:12px 16px; border-radius:12px; width:140px; text-align:center; font-size:18px; outline:none;
  }
  #gn-input:focus{ border-color:var(--cyan); }
  #gn-btn{
    background:linear-gradient(135deg,var(--gold),var(--magenta)); color:#05060a; font-weight:700;
    padding:12px 22px; border-radius:12px; font-size:14px;
  }
  .gn-hint{ font-size:17px; font-weight:600; min-height:26px; }
  .gn-attempts{ color:var(--dim); font-size:13px; }
  .gn-attempts b{ color:var(--gold); }

  /* ---------- 2048 ---------- */
  .g2-grid{ position:absolute; inset:44px 16px 16px 16px; display:grid; grid-template-columns:repeat(4,1fr); grid-template-rows:repeat(4,1fr); gap:10px; }
  .g2-cell{ background:rgba(255,255,255,0.06); border-radius:10px; display:flex; align-items:center; justify-content:center; font-family:'Space Grotesk',sans-serif; font-weight:700; font-size:clamp(16px,3vw,26px); color:var(--star); transition:background .15s; }
  .g2-cell.v2{ background:rgba(0,217,255,0.15); } .g2-cell.v4{ background:rgba(0,217,255,0.28); }
  .g2-cell.v8{ background:rgba(108,92,231,0.4); color:#fff; } .g2-cell.v16{ background:rgba(108,92,231,0.55); color:#fff; }
  .g2-cell.v32{ background:rgba(255,60,172,0.45); color:#fff; } .g2-cell.v64{ background:rgba(255,60,172,0.65); color:#fff; }
  .g2-cell.v128{ background:rgba(255,209,102,0.55); color:#05060a; } .g2-cell.v256{ background:rgba(255,209,102,0.75); color:#05060a; }
  .g2-cell.v512{ background:rgba(255,209,102,0.9); color:#05060a; } .g2-cell.v1024{ background:var(--gold); color:#05060a; }
  .g2-cell.v2048{ background:var(--green); color:#05060a; }

  /* ---------- Wordle ---------- */
  .wd-grid{ display:flex; flex-direction:column; gap:6px; }
  .wd-row{ display:flex; gap:6px; }
  .wd-cell{ width:38px; height:38px; border:1px solid rgba(232,236,249,0.2); border-radius:8px; display:flex; align-items:center; justify-content:center; font-weight:700; font-family:'Space Grotesk',sans-serif; }
  .wd-cell.green{ background:var(--green); color:#05060a; border-color:var(--green); }
  .wd-cell.yellow{ background:var(--gold); color:#05060a; border-color:var(--gold); }
  .wd-cell.gray{ background:rgba(255,255,255,0.08); color:var(--dim); }

  /* ---------- Color diff ---------- */
  .cd-grid{ position:absolute; inset:44px 16px 16px 16px; display:grid; gap:8px; }
  .cd-swatch{ border-radius:10px; border:none; }

  /* ---------- Blackjack ---------- */
  .bj-cards{ display:flex; gap:8px; margin-top:6px; flex-wrap:wrap; justify-content:center; min-height:64px; }
  .bj-card{ width:44px; height:60px; background:#fff; color:#111; border-radius:8px; display:flex; align-items:center; justify-content:center; font-weight:700; font-size:16px; }
  .bj-actions{ display:flex; gap:10px; margin-top:22px; }

  /* ---------- Wheel ---------- */
  .wheel-wrap{ position:relative; width:220px; height:220px; }
  .wheel{ width:100%; height:100%; border-radius:50%; border:4px solid rgba(232,236,249,0.3); }
  .wheel-pointer{ position:absolute; top:-16px; left:50%; transform:translateX(-50%); font-size:26px; color:var(--gold); z-index:2; filter:drop-shadow(0 0 6px rgba(255,209,102,0.6)); }

  /* ---------- Mash button ---------- */
  .mash-btn{ background:linear-gradient(135deg,var(--magenta),var(--gold)); color:#05060a; font-weight:700; font-size:20px; padding:22px 40px; border-radius:20px; }

  /* ---------- Simon Says ---------- */
  .simon-grid{ display:grid; grid-template-columns:repeat(2,90px); grid-template-rows:repeat(2,90px); gap:10px; }
  .simon-btn{ border-radius:16px; opacity:0.75; transition:filter .1s; border:none; }

  /* ---------- Whack-a-mole ---------- */
  .wk-grid{ display:grid; grid-template-columns:repeat(3,80px); grid-template-rows:repeat(3,80px); gap:10px; }
  .wk-hole{ background:rgba(255,255,255,0.05); border:1px solid rgba(232,236,249,0.15); border-radius:50%; font-size:34px; display:flex; align-items:center; justify-content:center; }
  .wk-hole.up{ background:rgba(46,204,113,0.2); }

  /* ---------- Trivia ---------- */
  .tv-opts{ display:grid; grid-template-columns:repeat(2,1fr); gap:10px; max-width:420px; width:100%; }

  /* ---------- Lights Out ---------- */
  .lo-grid{ display:grid; grid-template-columns:repeat(5,50px); grid-template-rows:repeat(5,50px); gap:6px; }
  .lo-cell{ background:rgba(255,255,255,0.06); border:1px solid rgba(232,236,249,0.15); border-radius:8px; }
  .lo-cell.on{ background:var(--gold); box-shadow:0 0 14px rgba(255,209,102,0.6); }

  /* ---------- Slot machine ---------- */
  .slot-reels{ display:flex; gap:12px; }
  .slot-reel{ width:70px; height:70px; background:rgba(255,255,255,0.06); border:2px solid rgba(232,236,249,0.2); border-radius:14px; display:flex; align-items:center; justify-content:center; font-size:36px; }

  /* ---------- Number order ---------- */
  .no-grid{ position:absolute; inset:44px 16px 16px 16px; display:grid; grid-template-columns:repeat(5,1fr); grid-template-rows:repeat(4,1fr); gap:8px; }
  .no-cell{ background:rgba(255,255,255,0.06); border:1px solid rgba(232,236,249,0.15); border-radius:10px; font-weight:700; font-size:16px; color:var(--star); }
  .no-cell.done{ background:rgba(46,204,113,0.3); border-color:var(--green); opacity:0.5; }

  /* ---------- Result modal ---------- */
  .modal-overlay{
    position:fixed; inset:0; background:rgba(5,6,10,0.75); backdrop-filter:blur(6px);
    display:flex; align-items:center; justify-content:center; z-index:50; padding:20px;
  }
  .modal-box{
    background:#0b0d15; border:1px solid rgba(232,236,249,0.15); border-radius:24px; padding:36px 32px;
    max-width:420px; width:100%; text-align:center; box-shadow:0 20px 60px rgba(0,0,0,0.5);
    animation:pop .25s ease;
  }
  @keyframes pop{ from{ transform:scale(0.85); opacity:0; } to{ transform:scale(1); opacity:1; } }
  .modal-title{ font-family:'Space Grotesk',sans-serif; font-weight:700; font-size:clamp(24px,5vw,32px); margin-bottom:14px; }
  .modal-msg{ color:var(--star); font-size:15px; line-height:1.6; margin-bottom:26px; }
  .modal-actions{ display:flex; gap:10px; justify-content:center; flex-wrap:wrap; }
  .modal-actions button{
    padding:12px 22px; border-radius:12px; font-size:14px; font-weight:600; transition:transform .15s;
  }
  .modal-actions button:hover{ transform:translateY(-2px); }
  #retryBtn{ background:linear-gradient(135deg,var(--cyan),var(--violet)); color:#05060a; }
  #menuBtn{ background:rgba(255,255,255,0.08); color:var(--star); border:1px solid rgba(232,236,249,0.2); }

  @media (max-width:480px){
    .ttt-board{ grid-template-columns:repeat(3,70px); grid-template-rows:repeat(3,70px); }
    .simon-grid{ grid-template-columns:repeat(2,76px); grid-template-rows:repeat(2,76px); }
    .wk-grid{ grid-template-columns:repeat(3,68px); grid-template-rows:repeat(3,68px); }
    .lo-grid{ grid-template-columns:repeat(5,42px); grid-template-rows:repeat(5,42px); }
  }
</style>
</head>
<body>

<canvas id="bgstars"></canvas>

<!-- ADMIN BUTTON -->
<button id="admin-toggle-btn" title="Admin panel" style="position:fixed;top:16px;right:16px;z-index:40;background:rgba(255,255,255,0.06);border:1px solid rgba(232,236,249,0.15);color:var(--star);width:42px;height:42px;border-radius:12px;font-size:18px;">⚙️</button>

<!-- ADMIN MODAL -->
<div class="modal-overlay hidden" id="adminModal">
  <div class="modal-box" style="max-width:440px;">
    <div class="modal-title" style="font-size:22px;">⚙️ Admin panel</div>

    <div id="admin-setup-mode">
      <p style="color:var(--dim);font-size:13px;margin-bottom:14px;">Bu birinchi marta ochilyapti — o'zingizga admin parol o'rnating. Shu paroldan boshqa hech kim admin panelga kira olmaydi.</p>
      <div style="display:flex;flex-direction:column;gap:10px;align-items:center;">
        <input id="admin-new-pass" type="password" placeholder="Yangi parol..." style="background:rgba(255,255,255,0.06);border:1px solid rgba(232,236,249,0.2);color:var(--star);padding:12px 16px;border-radius:12px;width:220px;text-align:center;outline:none;">
        <input id="admin-new-pass2" type="password" placeholder="Parolni tasdiqlang..." style="background:rgba(255,255,255,0.06);border:1px solid rgba(232,236,249,0.2);color:var(--star);padding:12px 16px;border-radius:12px;width:220px;text-align:center;outline:none;">
        <button id="admin-setup-btn" style="background:linear-gradient(135deg,var(--cyan),var(--violet));color:#05060a;font-weight:700;padding:12px 22px;border-radius:12px;width:220px;">Parolni o'rnatish</button>
      </div>
      <div id="admin-setup-error" style="color:var(--red);font-size:12px;margin-top:10px;min-height:16px;"></div>
    </div>

    <div id="admin-login-mode" class="hidden">
      <p style="color:var(--dim);font-size:13px;margin-bottom:14px;">Admin parolini kiriting</p>
      <div class="gn-input-row" style="justify-content:center;">
        <input id="admin-pass" type="password" placeholder="Admin parol...">
        <button id="admin-pass-btn">Kirish</button>
      </div>
      <div id="admin-login-error" style="color:var(--red);font-size:12px;margin-top:10px;min-height:16px;"></div>
      <button id="admin-forgot-btn" style="background:none;color:var(--dim);font-size:11px;margin-top:8px;text-decoration:underline;">Parolni unutdim (qayta o'rnatish)</button>
    </div>

    <div id="admin-controls" class="hidden">
      <p style="color:var(--dim);font-size:13px;margin-bottom:12px;text-align:left;">O'yinlarni yoq/o'chir (faqat shu brauzeringizda saqlanadi):</p>
      <div id="admin-game-list" style="text-align:left;max-height:280px;overflow-y:auto;padding-right:6px;"></div>
    </div>
    <div class="modal-actions" style="margin-top:20px;"><button id="adminCloseBtn" style="background:rgba(255,255,255,0.08);color:var(--star);border:1px solid rgba(232,236,249,0.2);">Yopish</button></div>
  </div>
</div>

<!-- NAME SCREEN -->
<div class="screen" id="screen-name">
  <h1>ARCADE GALAXY</h1>
  <p>40 ta qiziqarli o'yin, bitta koinot. Boshlashdan oldin ismingni ayt!</p>
  <form id="name-form">
    <input id="name-input" type="text" placeholder="Ismingni yoz..." maxlength="20" autocomplete="off">
    <button type="submit">Kirish 🚀</button>
  </form>
</div>

<!-- MENU SCREEN -->
<div class="screen hidden" id="screen-menu">
  <div class="menu-head">
    <h2 id="greet">Salom!</h2>
    <p>Bitta o'yinni tanla va boshla. Yutsang — chempion, yutqazsang — kula olasanmi? 😏</p>
  </div>
  <div class="game-grid" id="game-grid"></div>
</div>

<!-- GAME SCREEN -->
<div class="screen hidden" id="screen-game">
  <div class="game-top">
    <button id="back-btn">← Menyu</button>
    <div id="game-title-el"></div>
    <div style="width:80px"></div>
  </div>
  <div id="game-area"></div>
</div>

<!-- RESULT MODAL -->
<div class="modal-overlay hidden" id="resultModal">
  <div class="modal-box">
    <div class="modal-title" id="resultTitle"></div>
    <div class="modal-msg" id="resultMsg"></div>
    <div class="modal-actions">
      <button id="retryBtn">Qayta urinish 🔁</button>
      <button id="menuBtn">Menyuga qaytish</button>
    </div>
  </div>
</div>

<script>
/* ============ Background starfield (always alive) ============ */
(function(){
  const c = document.getElementById('bgstars');
  const ctx = c.getContext('2d');
  let stars = [];
  function resize(){ c.width = innerWidth; c.height = innerHeight; init(); }
  function init(){
    stars = [];
    const count = Math.floor((c.width*c.height)/6000);
    for(let i=0;i<count;i++){
      stars.push({x:Math.random()*c.width, y:Math.random()*c.height, r:Math.random()*1.2+0.2, tw:Math.random()*Math.PI*2, sp:Math.random()*0.4+0.1});
    }
  }
  window.addEventListener('resize', resize);
  resize();
  function loop(){
    ctx.clearRect(0,0,c.width,c.height);
    stars.forEach(s=>{
      s.tw += 0.02*s.sp;
      ctx.globalAlpha = Math.max(0.15, 0.5+Math.sin(s.tw)*0.4);
      ctx.fillStyle = '#e8ecf9';
      ctx.beginPath(); ctx.arc(s.x,s.y,s.r,0,Math.PI*2); ctx.fill();
    });
    ctx.globalAlpha=1;
    requestAnimationFrame(loop);
  }
  loop();
})();

/* ============ Themed canvas backgrounds ============ */
function paintBG(ctx, w, h, theme, t){
  t = t || 0;
  switch(theme){
    case 'ocean': {
      const horizon = h*0.4;
      const sky = ctx.createLinearGradient(0,0,0,horizon);
      sky.addColorStop(0,'#1b3a6b'); sky.addColorStop(1,'#4a8fc7');
      ctx.fillStyle = sky; ctx.fillRect(0,0,w,horizon);
      ctx.fillStyle = 'rgba(255,232,160,0.9)';
      ctx.beginPath(); ctx.arc(w*0.83, horizon*0.35, 24,0,Math.PI*2); ctx.fill();
      const water = ctx.createLinearGradient(0,horizon,0,h);
      water.addColorStop(0,'#0f5c8c'); water.addColorStop(1,'#062f4d');
      ctx.fillStyle = water; ctx.fillRect(0,horizon,w,h-horizon);
      ctx.strokeStyle = 'rgba(255,255,255,0.14)'; ctx.lineWidth = 2;
      for(let i=0;i<4;i++){
        ctx.beginPath();
        for(let x=0;x<=w;x+=12){
          const y = horizon+26+i*34 + Math.sin((x*0.03)+t*0.0018+i)*4;
          if(x===0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
        }
        ctx.stroke();
      }
      break;
    }
    case 'sky': {
      const g = ctx.createLinearGradient(0,0,0,h);
      g.addColorStop(0,'#4a90c9'); g.addColorStop(1,'#c7e2f4');
      ctx.fillStyle = g; ctx.fillRect(0,0,w,h);
      ctx.fillStyle = 'rgba(255,255,255,0.85)';
      [[0.15,0.18,22],[0.42,0.1,17],[0.75,0.22,26]].forEach(([cx,cy,r])=>{
        ctx.beginPath();
        ctx.arc(w*cx,h*cy,r,0,Math.PI*2);
        ctx.arc(w*cx+r*0.85,h*cy+4,r*0.7,0,Math.PI*2);
        ctx.arc(w*cx-r*0.85,h*cy+4,r*0.7,0,Math.PI*2);
        ctx.fill();
      });
      break;
    }
    case 'space': {
      const g = ctx.createLinearGradient(0,0,0,h);
      g.addColorStop(0,'#0b0f2e'); g.addColorStop(1,'#05060a');
      ctx.fillStyle = g; ctx.fillRect(0,0,w,h);
      break;
    }
    case 'grass': {
      const g = ctx.createLinearGradient(0,0,0,h);
      g.addColorStop(0,'#0d1f13'); g.addColorStop(1,'#132a18');
      ctx.fillStyle = g; ctx.fillRect(0,0,w,h);
      break;
    }
    case 'road': {
      const g = ctx.createLinearGradient(0,0,0,h);
      g.addColorStop(0,'#1a1a22'); g.addColorStop(1,'#2b2b38');
      ctx.fillStyle = g; ctx.fillRect(0,0,w,h);
      break;
    }
    case 'sunset': {
      const g = ctx.createLinearGradient(0,0,0,h);
      g.addColorStop(0,'#ff9a6c'); g.addColorStop(0.55,'#c96ba8'); g.addColorStop(1,'#3a2560');
      ctx.fillStyle = g; ctx.fillRect(0,0,w,h);
      break;
    }
    case 'desert': {
      const g = ctx.createLinearGradient(0,0,0,h);
      g.addColorStop(0,'#f3c969'); g.addColorStop(1,'#c98a3f');
      ctx.fillStyle = g; ctx.fillRect(0,0,w,h);
      ctx.fillStyle = 'rgba(255,255,255,0.9)';
      ctx.beginPath(); ctx.arc(w*0.8,h*0.2,22,0,Math.PI*2); ctx.fill();
      break;
    }
    case 'dungeon': {
      const g = ctx.createLinearGradient(0,0,0,h);
      g.addColorStop(0,'#1d1d26'); g.addColorStop(1,'#0c0c12');
      ctx.fillStyle = g; ctx.fillRect(0,0,w,h);
      break;
    }
    case 'arena': {
      const g = ctx.createRadialGradient(w/2,h/2,10,w/2,h/2,Math.max(w,h)*0.7);
      g.addColorStop(0,'#171d33'); g.addColorStop(1,'#05060a');
      ctx.fillStyle = g; ctx.fillRect(0,0,w,h);
      break;
    }
    case 'stadium': {
      const horizon = h*0.18;
      const sky = ctx.createLinearGradient(0,0,0,horizon);
      sky.addColorStop(0,'#0d3a24'); sky.addColorStop(1,'#155c36');
      ctx.fillStyle = sky; ctx.fillRect(0,0,w,horizon);
      const field = ctx.createLinearGradient(0,horizon,0,h);
      field.addColorStop(0,'#1e6b3d'); field.addColorStop(1,'#0d3a20');
      ctx.fillStyle = field; ctx.fillRect(0,horizon,w,h-horizon);
      ctx.strokeStyle = 'rgba(255,255,255,0.25)'; ctx.lineWidth = 2;
      for(let i=0;i<6;i++){
        ctx.fillStyle = i%2===0 ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.05)';
        ctx.fillRect(0, horizon+(h-horizon)*i/6, w, (h-horizon)/6);
      }
      break;
    }
    default: {
      ctx.fillStyle = '#05060a'; ctx.fillRect(0,0,w,h);
    }
  }
}

/* ============ App state ============ */
let playerName = 'Mehmon';
let activeGame = null;
let currentGameId = null;
let hiddenGames = [];
try { hiddenGames = JSON.parse(localStorage.getItem('arcade_hidden_games') || '[]'); } catch(e){ hiddenGames = []; }
let adminPasswordSet = null;
try { adminPasswordSet = localStorage.getItem('arcade_admin_password'); } catch(e){ adminPasswordSet = null; }

const adminToggleBtn = document.getElementById('admin-toggle-btn');
const adminModal = document.getElementById('adminModal');
const adminSetupMode = document.getElementById('admin-setup-mode');
const adminLoginMode = document.getElementById('admin-login-mode');
const adminNewPass = document.getElementById('admin-new-pass');
const adminNewPass2 = document.getElementById('admin-new-pass2');
const adminSetupBtn = document.getElementById('admin-setup-btn');
const adminSetupError = document.getElementById('admin-setup-error');
const adminControls = document.getElementById('admin-controls');
const adminPass = document.getElementById('admin-pass');
const adminPassBtn = document.getElementById('admin-pass-btn');
const adminLoginError = document.getElementById('admin-login-error');
const adminForgotBtn = document.getElementById('admin-forgot-btn');
const adminGameList = document.getElementById('admin-game-list');
const adminCloseBtn = document.getElementById('adminCloseBtn');

const screenName = document.getElementById('screen-name');
const screenMenu = document.getElementById('screen-menu');
const screenGame = document.getElementById('screen-game');
const nameForm = document.getElementById('name-form');
const nameInput = document.getElementById('name-input');
const greetEl = document.getElementById('greet');
const gameGrid = document.getElementById('game-grid');
const gameArea = document.getElementById('game-area');
const gameTitleEl = document.getElementById('game-title-el');
const backBtn = document.getElementById('back-btn');
const resultModal = document.getElementById('resultModal');
const resultTitle = document.getElementById('resultTitle');
const resultMsg = document.getElementById('resultMsg');
const retryBtn = document.getElementById('retryBtn');
const menuBtn = document.getElementById('menuBtn');

const winLines = [
  "{name}, ajoyib! Sen yutding! 🏆",
  "Voy-bo'y, {name}! Bu haqiqiy g'alaba!",
  "{name}, sen chempion ekansan! 🎉",
  "Zo'r, {name}! Bugun kun seniki!",
  "{name}, hatto kompyuter ham hayratda qoldi!"
];
const loseLines = [
  "{name}, sen yutqazding! 😅",
  "Voy, {name}... bu safar omad yor bo'lmadi. Sen yutqazding!",
  "{name}, kompyuter kulib turibdi. Sen yutqazding!",
  "Afsus, {name}! Sen yutqazding, lekin urinish chiroyli edi 😄",
  "{name}, koinot senga qarshi chiqdi. Sen yutqazding!"
];
const drawLines = [
  "Durrang, {name}! Hech kim yutmadi, hech kim yutqazmadi 🤝"
];

function pick(arr){ return arr[Math.floor(Math.random()*arr.length)]; }

function finish(status, detail){
  if(activeGame && activeGame.stop) activeGame.stop();
  let title, pool;
  if(status==='win'){ title='🏆 G\'ALABA!'; pool=winLines; }
  else if(status==='lose'){ title='💀 YUTQAZDING!'; pool=loseLines; }
  else { title='🤝 DURRANG'; pool=drawLines; }
  resultTitle.textContent = title;
  let msg = pick(pool).replace('{name}', playerName);
  if(detail) msg += ' ' + detail;
  resultMsg.textContent = msg;
  resultModal.classList.remove('hidden');
}

function goToMenu(){
  if(activeGame && activeGame.stop) activeGame.stop();
  activeGame = null;
  resultModal.classList.add('hidden');
  screenGame.classList.add('hidden');
  screenMenu.classList.remove('hidden');
}

const THEMES = {
  supernova:  { bg:'linear-gradient(135deg,#12102a,#05060a 65%)', icon:'💥' },
  tictactoe:  { bg:'linear-gradient(135deg,#181828,#0c0c14)', icon:'❌' },
  memory:     { bg:'linear-gradient(135deg,#1b1330,#0d0a1a)', icon:'🧠' },
  reaction:   { bg:'linear-gradient(135deg,#2a1414,#150a0a)', icon:'⚡' },
  rps:        { bg:'linear-gradient(135deg,#1a2a1a,#0d150d)', icon:'✂️' },
  snake:      { bg:'linear-gradient(135deg,#0d1f13,#0a150d)', icon:'🐍' },
  catch:      { bg:'linear-gradient(180deg,#0e1338,#05060a)', icon:'🌟' },
  guess:      { bg:'linear-gradient(135deg,#1a1030,#0d0818)', icon:'🔢' },
  game2048:   { bg:'linear-gradient(135deg,#2a1f10,#150f08)', icon:'🧩' },
  pong:       { bg:'linear-gradient(135deg,#12142a,#05060a)', icon:'🏓' },
  aim:        { bg:'linear-gradient(135deg,#2a1420,#150a10)', icon:'🎯' },
  flappy:     { bg:'linear-gradient(180deg,#4a90c9,#bcd9ef)', icon:'🐦' },
  breakout:   { bg:'linear-gradient(135deg,#1a1030,#0a0818)', icon:'🧱' },
  wordle:     { bg:'linear-gradient(135deg,#14261e,#0a140f)', icon:'🔤' },
  math:       { bg:'linear-gradient(135deg,#101a2a,#080d15)', icon:'🧮' },
  colordiff:  { bg:'linear-gradient(135deg,#1a1a2a,#0a0a12)', icon:'🎨' },
  blackjack:  { bg:'linear-gradient(135deg,#0d2818,#08150c)', icon:'🃏' },
  lie:        { bg:'linear-gradient(135deg,#2a1a10,#150d08)', icon:'🤥' },
  wheel:      { bg:'linear-gradient(135deg,#2a1030,#150818)', icon:'🎡' },
  mash:       { bg:'linear-gradient(135deg,#2a1010,#150808)', icon:'👊' },
  simon:      { bg:'linear-gradient(135deg,#1a1030,#0d0818)', icon:'🔴' },
  maze:       { bg:'linear-gradient(135deg,#1d1d26,#0c0c12)', icon:'🌀' },
  balloon:    { bg:'linear-gradient(180deg,#4a90c9,#bcd9ef)', icon:'🎈' },
  whack:      { bg:'linear-gradient(135deg,#1a2a1a,#0d150d)', icon:'🦫' },
  traffic:    { bg:'linear-gradient(135deg,#1a1a22,#2b2b38)', icon:'🚗' },
  penalty:    { bg:'linear-gradient(180deg,#0d3a24,#0a1f15)', icon:'⚽' },
  meteor:     { bg:'linear-gradient(180deg,#0e1338,#05060a)', icon:'☄️' },
  trivia:     { bg:'linear-gradient(135deg,#101a2a,#080d15)', icon:'🧠' },
  coin:       { bg:'linear-gradient(135deg,#2a2010,#15100a)', icon:'🪙' },
  lightsout:  { bg:'linear-gradient(135deg,#1a1a2a,#0a0a12)', icon:'💡' },
  nummem:     { bg:'linear-gradient(135deg,#1a1030,#0d0818)', icon:'🔢' },
  typing:     { bg:'linear-gradient(135deg,#101a2a,#080d15)', icon:'⌨️' },
  stack:      { bg:'linear-gradient(180deg,#ff9a6c,#3a2560)', icon:'🏗️' },
  fishing:    { bg:'linear-gradient(180deg,#1b3a6b,#062f4d)', icon:'🎣' },
  dino:       { bg:'linear-gradient(180deg,#f3c969,#c98a3f)', icon:'🦖' },
  duckhunt:   { bg:'linear-gradient(180deg,#3a6b8a,#123044)', icon:'🦆' },
  slot:       { bg:'linear-gradient(135deg,#2a1030,#150818)', icon:'🎰' },
  stopwatch:  { bg:'linear-gradient(135deg,#101a2a,#080d15)', icon:'⏱️' },
  numorder:   { bg:'linear-gradient(135deg,#1a1a2a,#0a0a12)', icon:'🔟' },
  anagram:    { bg:'linear-gradient(135deg,#14261e,#0a140f)', icon:'🔠' },
};

function launchGame(id){
  const g = GAMES.find(x=>x.id===id);
  if(!g) return;
  currentGameId = id;
  gameArea.innerHTML = '';
  const theme = THEMES[id];
  if(theme){
    gameArea.style.background = theme.bg;
    gameArea.style.backgroundSize = 'cover';
  }
  gameTitleEl.textContent = g.emoji + ' ' + g.title;
  screenMenu.classList.add('hidden');
  screenGame.classList.remove('hidden');
  resultModal.classList.add('hidden');
  activeGame = g.init(gameArea, { name: playerName, finish });
  const iconBg = document.createElement('div');
  iconBg.className = 'game-icon-bg';
  iconBg.textContent = theme ? theme.icon : g.emoji;
  gameArea.appendChild(iconBg);
}

backBtn.onclick = goToMenu;
menuBtn.onclick = goToMenu;
retryBtn.onclick = () => { resultModal.classList.add('hidden'); launchGame(currentGameId); };

nameForm.addEventListener('submit', e=>{
  e.preventDefault();
  const v = nameInput.value.trim();
  playerName = v || 'Mehmon';
  screenName.classList.add('hidden');
  screenMenu.classList.remove('hidden');
  greetEl.innerHTML = `Salom, <span>${playerName}</span>! Nima o'ynaymiz?`;
  renderMenu();
});

function renderMenu(){
  gameGrid.innerHTML = '';
  GAMES.filter(g => !hiddenGames.includes(g.id)).forEach(g=>{
    const card = document.createElement('button');
    card.className = 'game-card';
    card.innerHTML = `<div class="gc-emoji">${g.emoji}</div><div class="gc-title">${g.title}</div><div class="gc-desc">${g.desc}</div>`;
    card.onclick = () => launchGame(g.id);
    gameGrid.appendChild(card);
  });
  if(!gameGrid.children.length){
    gameGrid.innerHTML = `<p style="color:var(--dim);grid-column:1/-1;text-align:center;">Hozircha faol o'yin yo'q — admin paneldan yoqing.</p>`;
  }
}

/* ============ Admin panel ============ */
adminToggleBtn.onclick = () => {
  adminModal.classList.remove('hidden');
  adminControls.classList.add('hidden');
  if(adminPasswordSet){
    adminSetupMode.classList.add('hidden');
    adminLoginMode.classList.remove('hidden');
    adminPass.value = '';
    adminLoginError.textContent = '';
  } else {
    adminSetupMode.classList.remove('hidden');
    adminLoginMode.classList.add('hidden');
    adminNewPass.value = ''; adminNewPass2.value = '';
    adminSetupError.textContent = '';
  }
};
adminCloseBtn.onclick = () => { adminModal.classList.add('hidden'); };

adminSetupBtn.onclick = () => {
  const p1 = adminNewPass.value, p2 = adminNewPass2.value;
  if(p1.length < 4){ adminSetupError.textContent = "Parol kamida 4 belgidan iborat bo'lsin."; return; }
  if(p1 !== p2){ adminSetupError.textContent = "Parollar mos kelmadi."; return; }
  try { localStorage.setItem('arcade_admin_password', p1); } catch(e){}
  adminPasswordSet = p1;
  adminSetupMode.classList.add('hidden');
  adminControls.classList.remove('hidden');
  renderAdminList();
};

adminPassBtn.onclick = () => {
  if(adminPass.value === adminPasswordSet){
    adminLoginMode.classList.add('hidden');
    adminControls.classList.remove('hidden');
    renderAdminList();
  } else {
    adminLoginError.textContent = "Admin parol xato.";
  }
};
adminPass.addEventListener('keydown', e=>{ if(e.key==='Enter') adminPassBtn.click(); });
adminNewPass2.addEventListener('keydown', e=>{ if(e.key==='Enter') adminSetupBtn.click(); });

adminForgotBtn.onclick = () => {
  if(confirm("Admin parolni tiklaysizmi? Bu eski parolni o'chirib, yangisini o'rnatish imkonini beradi.")){
    try { localStorage.removeItem('arcade_admin_password'); } catch(e){}
    adminPasswordSet = null;
    adminLoginMode.classList.add('hidden');
    adminSetupMode.classList.remove('hidden');
    adminNewPass.value=''; adminNewPass2.value=''; adminSetupError.textContent='';
  }
};

function renderAdminList(){
  adminGameList.innerHTML = '';
  GAMES.forEach(g=>{
    const row = document.createElement('label');
    row.style.cssText = 'display:flex;align-items:center;gap:10px;padding:9px 4px;border-bottom:1px solid rgba(232,236,249,0.08);cursor:pointer;';
    const cb = document.createElement('input');
    cb.type = 'checkbox';
    cb.checked = !hiddenGames.includes(g.id);
    cb.style.cssText = 'width:18px;height:18px;flex-shrink:0;';
    cb.onchange = () => {
      if(cb.checked) hiddenGames = hiddenGames.filter(id => id !== g.id);
      else if(!hiddenGames.includes(g.id)) hiddenGames.push(g.id);
      try { localStorage.setItem('arcade_hidden_games', JSON.stringify(hiddenGames)); } catch(e){}
      renderMenu();
    };
    const label = document.createElement('span');
    label.textContent = `${g.emoji} ${g.title}`;
    label.style.fontSize = '14px';
    row.appendChild(cb);
    row.appendChild(label);
    adminGameList.appendChild(row);
  });
}

/* ============ GAME 1: SUPERNOVA ============ */
function initSupernova(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Maqsad: <b>350</b></span><span id="sv-timer">20.0s</span><span>Ochko: <b id="sv-score">0</b></span></div>
      <canvas id="sv-canvas"></canvas>
    </div>`;
  const canvas = container.querySelector('#sv-canvas');
  const ctx = canvas.getContext('2d');
  function resize(){ canvas.width = container.clientWidth; canvas.height = container.clientHeight; }
  resize();
  window.addEventListener('resize', resize);

  let particles = [];
  let score = 0;
  let timeLeft = 20;
  const target = 350;
  const scoreEl = container.querySelector('#sv-score');
  const timerEl = container.querySelector('#sv-timer');
  const COLORS = ['#00d9ff','#6c5ce7','#ff3cac','#ffd166'];

  function explode(x,y){
    const color = COLORS[Math.floor(Math.random()*COLORS.length)];
    for(let i=0;i<22;i++){
      const angle = Math.random()*Math.PI*2;
      const speed = Math.random()*6+2;
      particles.push({x,y,vx:Math.cos(angle)*speed, vy:Math.sin(angle)*speed, life:1, color, r:Math.random()*2.5+1});
    }
    score += 10;
    scoreEl.textContent = score;
  }
  function onDown(e){
    const rect = canvas.getBoundingClientRect();
    const x = (e.touches ? e.touches[0].clientX : e.clientX) - rect.left;
    const y = (e.touches ? e.touches[0].clientY : e.clientY) - rect.top;
    explode(x,y);
  }
  canvas.addEventListener('mousedown', onDown);
  canvas.addEventListener('touchstart', onDown, {passive:true});

  let raf;
  function loop(){
    ctx.clearRect(0,0,canvas.width,canvas.height);
    particles.forEach(p=>{
      p.vx*=0.97; p.vy*=0.97;
      p.x+=p.vx; p.y+=p.vy;
      p.life -= 0.02;
      ctx.globalAlpha = Math.max(p.life,0);
      ctx.fillStyle = p.color;
      ctx.shadowColor = p.color; ctx.shadowBlur = 10;
      ctx.beginPath(); ctx.arc(p.x,p.y,p.r,0,Math.PI*2); ctx.fill();
      ctx.shadowBlur = 0;
    });
    ctx.globalAlpha = 1;
    particles = particles.filter(p=>p.life>0);
    raf = requestAnimationFrame(loop);
  }
  loop();

  const timerInt = setInterval(()=>{
    timeLeft -= 0.1;
    timerEl.textContent = Math.max(timeLeft,0).toFixed(1)+'s';
    if(timeLeft<=0){
      clearInterval(timerInt);
      if(score>=target) api.finish('win', `(${score} ochko to'pladi!)`);
      else api.finish('lose', `(faqat ${score}/${target} ochko yig'ding)`);
    }
  }, 100);

  function stop(){
    cancelAnimationFrame(raf);
    clearInterval(timerInt);
    window.removeEventListener('resize', resize);
  }
  return { stop };
}

/* ============ GAME 2: TIC TAC TOE ============ */
function initTicTacToe(container, api){
  container.innerHTML = `
    <div class="game-wrap center">
      <div class="ttt-status" id="ttt-status">Sen: ❌ &nbsp;|&nbsp; Kompyuter: ⭕</div>
      <div class="ttt-board" id="ttt-board"></div>
    </div>`;
  const boardEl = container.querySelector('#ttt-board');
  const statusEl = container.querySelector('#ttt-status');
  let board = Array(9).fill(null);
  let over = false;
  const lines = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];

  function checkWinner(b){
    for(const [a,c,d] of lines){ if(b[a] && b[a]===b[c] && b[a]===b[d]) return b[a]; }
    if(b.every(x=>x)) return 'draw';
    return null;
  }
  function render(){
    boardEl.innerHTML = '';
    board.forEach((v,i)=>{
      const cell = document.createElement('button');
      cell.className = 'ttt-cell';
      cell.textContent = v==='X' ? '❌' : v==='O' ? '⭕' : '';
      cell.disabled = !!v || over;
      cell.onclick = () => playerMove(i);
      boardEl.appendChild(cell);
    });
  }
  function playerMove(i){
    if(board[i] || over) return;
    board[i] = 'X';
    render();
    const w = checkWinner(board);
    if(w){ endGame(w); return; }
    statusEl.textContent = "Kompyuter o'ylayapti...";
    setTimeout(computerMove, 450);
  }
  function computerMove(){
    if(over) return;
    const move = findBestMove();
    board[move] = 'O';
    render();
    const w = checkWinner(board);
    if(w){ endGame(w); return; }
    statusEl.textContent = "Sen: ❌ &nbsp;|&nbsp; Kompyuter: ⭕";
  }
  function findBestMove(){
    for(let i=0;i<9;i++){ if(!board[i]){ board[i]='O'; if(checkWinner(board)==='O'){ board[i]=null; return i; } board[i]=null; } }
    for(let i=0;i<9;i++){ if(!board[i]){ board[i]='X'; if(checkWinner(board)==='X'){ board[i]=null; return i; } board[i]=null; } }
    if(!board[4]) return 4;
    const corners = [0,2,6,8].filter(i=>!board[i]);
    if(corners.length) return corners[Math.floor(Math.random()*corners.length)];
    const empties = board.map((v,i)=>v?null:i).filter(i=>i!==null);
    return empties[Math.floor(Math.random()*empties.length)];
  }
  function endGame(w){
    over = true;
    render();
    if(w==='X') api.finish('win', "(Kompyuterni mag'lub qilding!)");
    else if(w==='O') api.finish('lose', "(Kompyuter g'alaba qozondi)");
    else api.finish('draw', "(Hech kim yutmadi)");
  }
  render();
  return { stop(){} };
}

/* ============ GAME 3: MEMORY ============ */
function initMemory(container, api){
  const icons = ['🚀','🪐','⭐','🌙','☄️','👽'];
  let cards = [...icons, ...icons];
  cards.sort(()=>Math.random()-0.5);
  container.innerHTML = `
    <div class="game-wrap">
      <div class="mem-status">Yurishlar: <b id="mem-moves">0</b>/<b>16</b> &nbsp;|&nbsp; Juftlar: <b id="mem-pairs">0</b>/6</div>
      <div class="mem-grid" id="mem-grid"></div>
    </div>`;
  const grid = container.querySelector('#mem-grid');
  const movesEl = container.querySelector('#mem-moves');
  const pairsEl = container.querySelector('#mem-pairs');
  const limit = 16;
  let moves=0, pairsFound=0, flipped=[], lock=false, over=false;

  cards.forEach((icon)=>{
    const card = document.createElement('button');
    card.className = 'mem-card';
    card.dataset.icon = icon;
    card.textContent = '❔';
    card.onclick = () => flip(card);
    grid.appendChild(card);
  });

  function flip(card){
    if(lock || over || card.classList.contains('flipped') || card.classList.contains('matched')) return;
    card.classList.add('flipped');
    card.textContent = card.dataset.icon;
    flipped.push(card);
    if(flipped.length===2){
      moves++; movesEl.textContent = moves;
      lock = true;
      const [a,b] = flipped;
      if(a.dataset.icon===b.dataset.icon){
        a.classList.add('matched'); b.classList.add('matched');
        pairsFound++; pairsEl.textContent = pairsFound;
        flipped = []; lock = false;
        if(pairsFound===6){ over=true; api.finish('win', `(${moves} yurishda tugatding!)`); }
      } else {
        setTimeout(()=>{
          a.classList.remove('flipped'); a.textContent = '❔';
          b.classList.remove('flipped'); b.textContent = '❔';
          flipped = []; lock = false;
          if(moves>=limit && !over){ over=true; api.finish('lose', `(${limit} yurish tugadi, hammasi topilmadi)`); }
        }, 700);
      }
    }
  }
  return { stop(){} };
}

/* ============ GAME 4: REACTION ============ */
function initReaction(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="rx-box wait" id="rx-box"><div class="rx-text" id="rx-text">Tayyorlanyapti...</div></div>
    </div>`;
  const box = container.querySelector('#rx-box');
  const text = container.querySelector('#rx-text');
  let state = 'waiting';
  let startTime, timeout;

  function startRound(){
    state = 'waiting';
    box.className = 'rx-box wait';
    text.textContent = "Kut... qizil ekanda BOSMA!";
    const delay = 1000 + Math.random()*3000;
    timeout = setTimeout(()=>{
      state = 'go';
      box.className = 'rx-box go';
      text.textContent = 'HOZIR BOS!';
      startTime = performance.now();
    }, delay);
  }
  function onClick(){
    if(state==='waiting'){
      clearTimeout(timeout);
      api.finish('lose', "(Juda erta bosding, sabr qilishni o'rgan!)");
      return;
    }
    if(state==='go'){
      const rt = Math.round(performance.now()-startTime);
      state = 'done';
      if(rt<=400) api.finish('win', `(Reaksiya vaqting: ${rt}ms — chaqqonsan!)`);
      else api.finish('lose', `(Reaksiya vaqting: ${rt}ms — juda sekin)`);
    }
  }
  box.addEventListener('mousedown', onClick);
  box.addEventListener('touchstart', onClick, {passive:true});
  startRound();

  function stop(){ clearTimeout(timeout); box.removeEventListener('mousedown', onClick); box.removeEventListener('touchstart', onClick); }
  return { stop };
}

/* ============ GAME 5: ROCK PAPER SCISSORS ============ */
function initRPS(container, api){
  container.innerHTML = `
    <div class="game-wrap center">
      <div class="rps-score">Sen <b id="rps-p">0</b> : <b id="rps-c">0</b> Kompyuter &nbsp;(3 tagacha)</div>
      <div class="rps-result" id="rps-result">Birini tanla!</div>
      <div class="rps-choices">
        <button class="rps-btn" data-c="tosh">🪨<br>Tosh</button>
        <button class="rps-btn" data-c="qaychi">✂️<br>Qaychi</button>
        <button class="rps-btn" data-c="qogoz">📄<br>Qog'oz</button>
      </div>
    </div>`;
  const pEl = container.querySelector('#rps-p');
  const cEl = container.querySelector('#rps-c');
  const resEl = container.querySelector('#rps-result');
  const btns = container.querySelectorAll('.rps-btn');
  let p=0, c=0, over=false;
  const beats = { tosh:'qaychi', qaychi:'qogoz', qogoz:'tosh' };
  const emoji = { tosh:'🪨', qaychi:'✂️', qogoz:'📄' };

  function round(choice){
    if(over) return;
    const opts = Object.keys(beats);
    const comp = opts[Math.floor(Math.random()*3)];
    let outcome;
    if(choice===comp) outcome = 'tie';
    else if(beats[choice]===comp) outcome = 'win';
    else outcome = 'lose';

    if(outcome==='win'){ p++; pEl.textContent=p; resEl.textContent = `${emoji[choice]} vs ${emoji[comp]} — bu raundni sen yutding!`; }
    else if(outcome==='lose'){ c++; cEl.textContent=c; resEl.textContent = `${emoji[choice]} vs ${emoji[comp]} — bu raundni kompyuter yutdi!`; }
    else { resEl.textContent = `${emoji[choice]} vs ${emoji[comp]} — durrang!`; }

    if(p===3){ over=true; api.finish('win', "(3 ta raundni birinchi yutding!)"); }
    else if(c===3){ over=true; api.finish('lose', "(Kompyuter 3 ta raundni birinchi yutdi)"); }
  }
  btns.forEach(b => b.onclick = () => round(b.dataset.c));
  return { stop(){} };
}

/* ============ GAME 6: SNAKE ============ */
function initSnake(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <canvas id="sn-canvas"></canvas>
      <div class="sn-score">Ochko: <b id="sn-score">0</b> (15 tada g'alaba)</div>
      <div class="sn-dpad">
        <div class="sn-dpad-row"><button class="sn-dbtn" data-d="up">↑</button></div>
        <div class="sn-dpad-row">
          <button class="sn-dbtn" data-d="left">←</button>
          <button class="sn-dbtn" data-d="down">↓</button>
          <button class="sn-dbtn" data-d="right">→</button>
        </div>
      </div>
    </div>`;
  const canvas = container.querySelector('#sn-canvas');
  const ctx = canvas.getContext('2d');
  const scoreEl = container.querySelector('#sn-score');
  const cellSize = 18;
  let cols, rows;

  function resize(){
    cols = Math.floor(container.clientWidth / cellSize);
    rows = Math.floor(container.clientHeight / cellSize);
    canvas.width = cols*cellSize;
    canvas.height = rows*cellSize;
  }
  resize();

  let snake, dir, nextDir, food, score, over, interval;
  function reset(){
    snake = [{x:Math.floor(cols/2), y:Math.floor(rows/2)}];
    dir = {x:1,y:0}; nextDir = dir;
    score = 0; over = false;
    placeFood();
    scoreEl.textContent = score;
  }
  function placeFood(){
    food = { x: Math.floor(Math.random()*cols), y: Math.floor(Math.random()*rows) };
  }
  function setDir(d){
    if(d==='up' && dir.y===0) nextDir = {x:0,y:-1};
    else if(d==='down' && dir.y===0) nextDir = {x:0,y:1};
    else if(d==='left' && dir.x===0) nextDir = {x:-1,y:0};
    else if(d==='right' && dir.x===0) nextDir = {x:1,y:0};
  }
  function onKey(e){
    const map = { ArrowUp:'up', ArrowDown:'down', ArrowLeft:'left', ArrowRight:'right' };
    if(map[e.key]){ setDir(map[e.key]); e.preventDefault(); }
  }
  window.addEventListener('keydown', onKey);
  container.querySelectorAll('.sn-dbtn').forEach(b=>{
    b.addEventListener('touchstart', e=>{ e.preventDefault(); setDir(b.dataset.d); }, {passive:false});
    b.addEventListener('mousedown', ()=> setDir(b.dataset.d));
  });

  function tick(){
    if(over) return;
    dir = nextDir;
    const head = { x: snake[0].x+dir.x, y: snake[0].y+dir.y };
    if(head.x<0 || head.x>=cols || head.y<0 || head.y>=rows || snake.some(s=>s.x===head.x && s.y===head.y)){
      over = true;
      clearInterval(interval);
      if(score>=15) api.finish('win', `(${score} ochko bilan ustasan!)`);
      else api.finish('lose', `(${score} ochko — devorga yoki o'ziga urilding)`);
      return;
    }
    snake.unshift(head);
    if(head.x===food.x && head.y===food.y){
      score++; scoreEl.textContent = score; placeFood();
    } else {
      snake.pop();
    }
    draw();
  }
  function draw(){
    paintBG(ctx, canvas.width, canvas.height, 'grass', performance.now());
    ctx.fillStyle = '#ffd166';
    ctx.fillRect(food.x*cellSize, food.y*cellSize, cellSize-2, cellSize-2);
    snake.forEach((s,i)=>{
      ctx.fillStyle = i===0 ? '#00d9ff' : '#6c5ce7';
      ctx.fillRect(s.x*cellSize, s.y*cellSize, cellSize-2, cellSize-2);
    });
  }
  reset();
  draw();
  interval = setInterval(tick, 140);

  function stop(){ clearInterval(interval); window.removeEventListener('keydown', onKey); }
  return { stop };
}

/* ============ GAME 7: CATCH STARS ============ */
function initCatch(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="cs-hud">Tutilgan: <b id="cs-score">0</b>/15 &nbsp;|&nbsp; O'tkazib yuborilgan: <b id="cs-miss">0</b>/3</div>
      <canvas id="cs-canvas"></canvas>
    </div>`;
  const canvas = container.querySelector('#cs-canvas');
  const ctx = canvas.getContext('2d');
  function resize(){ canvas.width = container.clientWidth; canvas.height = container.clientHeight; }
  resize();
  window.addEventListener('resize', resize);

  const scoreEl = container.querySelector('#cs-score');
  const missEl = container.querySelector('#cs-miss');
  let basketX = canvas.width/2;
  const basketW = 70, basketH = 16;
  let stars = [];
  let score=0, miss=0, over=false, raf, spawnTimer;

  function spawnStar(){
    stars.push({ x: Math.random()*(canvas.width-20)+10, y:-10, speed: 2+Math.random()*2+score*0.05 });
  }
  function onMove(e){
    const rect = canvas.getBoundingClientRect();
    const x = (e.touches ? e.touches[0].clientX : e.clientX) - rect.left;
    basketX = Math.max(basketW/2, Math.min(canvas.width-basketW/2, x));
  }
  canvas.addEventListener('mousemove', onMove);
  canvas.addEventListener('touchmove', onMove, {passive:true});

  function loop(){
    ctx.clearRect(0,0,canvas.width,canvas.height);
    ctx.fillStyle = '#00d9ff';
    ctx.fillRect(basketX-basketW/2, canvas.height-30, basketW, basketH);

    stars.forEach(s=>{
      s.y += s.speed;
      ctx.fillStyle = '#ffd166';
      ctx.shadowColor = '#ffd166'; ctx.shadowBlur = 10;
      ctx.beginPath(); ctx.arc(s.x, s.y, 6, 0, Math.PI*2); ctx.fill();
      ctx.shadowBlur = 0;
    });

    stars = stars.filter(s=>{
      if(s.y > canvas.height-30 && s.y < canvas.height-10 && Math.abs(s.x-basketX) < basketW/2){
        score++; scoreEl.textContent = score;
        if(score>=15 && !over){ over=true; cleanup(); api.finish('win', `(${score} ta yulduz tutding!)`); }
        return false;
      }
      if(s.y > canvas.height){
        miss++; missEl.textContent = miss;
        if(miss>=3 && !over){ over=true; cleanup(); api.finish('lose', `(${miss} tasini o'tkazib yubording)`); }
        return false;
      }
      return true;
    });

    if(!over) raf = requestAnimationFrame(loop);
  }
  spawnTimer = setInterval(spawnStar, 900);
  loop();

  function cleanup(){
    cancelAnimationFrame(raf);
    clearInterval(spawnTimer);
    window.removeEventListener('resize', resize);
    canvas.removeEventListener('mousemove', onMove);
    canvas.removeEventListener('touchmove', onMove);
  }
  return { stop: cleanup };
}

/* ============ GAME 8: GUESS THE NUMBER ============ */
function initGuess(container, api){
  const target = Math.floor(Math.random()*100)+1;
  let attemptsLeft = 7;
  let over = false;
  container.innerHTML = `
    <div class="game-wrap center gn-wrap">
      <p>1 dan 100 gacha bo'lgan sonni o'yladim. Topib ko'r!</p>
      <div class="gn-input-row">
        <input type="number" id="gn-input" min="1" max="100" placeholder="Son...">
        <button id="gn-btn">Tekshir</button>
      </div>
      <div class="gn-hint" id="gn-hint"></div>
      <div class="gn-attempts">Qolgan urinishlar: <b id="gn-left">${attemptsLeft}</b></div>
    </div>`;
  const input = container.querySelector('#gn-input');
  const btn = container.querySelector('#gn-btn');
  const hint = container.querySelector('#gn-hint');
  const leftEl = container.querySelector('#gn-left');

  function guess(){
    if(over) return;
    const val = parseInt(input.value);
    if(!val || val<1 || val>100){ hint.textContent = "1-100 oralig'ida son kirit!"; return; }
    attemptsLeft--;
    leftEl.textContent = attemptsLeft;
    if(val===target){
      over = true;
      api.finish('win', `(Sonni ${7-attemptsLeft} ta urinishda topding: ${target}!)`);
      return;
    }
    const diff = Math.abs(val-target);
    let h;
    if(diff<=3) h = '🔥🔥 Deyarli yondi!';
    else if(diff<=10) h = '🔥 Issiq!';
    else if(diff<=25) h = '🙂 Iliqroq...';
    else h = '❄️ Juda sovuq!';
    h += val<target ? ' (Kattaroq son kerak)' : ' (Kichikroq son kerak)';
    hint.textContent = h;

    if(attemptsLeft<=0 && !over){
      over = true;
      api.finish('lose', `(Son ${target} ekan, topolmading)`);
    }
    input.value = '';
    input.focus();
  }
  btn.onclick = guess;
  input.addEventListener('keydown', e => { if(e.key==='Enter') guess(); });
  return { stop(){} };
}

/* ============ GAME 9: 2048 ============ */
function initGame2048(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>2048 gacha yig'!</span><span id="g2-score">Ochko: 0</span></div>
      <div class="g2-grid" id="g2-grid"></div>
    </div>`;
  const gridEl = container.querySelector('#g2-grid');
  const scoreEl = container.querySelector('#g2-score');
  let cells, score, over;
  const size = 4;

  function empty(){ return cells.map((v,i)=>v===0?i:null).filter(i=>i!==null); }
  function addRandom(){
    const e = empty();
    if(!e.length) return;
    const i = e[Math.floor(Math.random()*e.length)];
    cells[i] = Math.random()<0.9 ? 2 : 4;
  }
  function reset(){ cells = Array(16).fill(0); score = 0; over = false; addRandom(); addRandom(); render(); }
  function render(){
    gridEl.innerHTML = '';
    cells.forEach(v=>{
      const c = document.createElement('div');
      c.className = 'g2-cell' + (v ? ' v'+v : '');
      c.textContent = v || '';
      gridEl.appendChild(c);
    });
    scoreEl.textContent = 'Ochko: ' + score;
  }
  function slideRow(row){
    let arr = row.filter(v=>v!==0);
    for(let i=0;i<arr.length-1;i++){ if(arr[i]===arr[i+1]){ arr[i]*=2; score+=arr[i]; arr.splice(i+1,1); } }
    while(arr.length<size) arr.push(0);
    return arr;
  }
  function getRow(r){ return [0,1,2,3].map(c=>cells[r*4+c]); }
  function setRow(r,arr){ arr.forEach((v,c)=>cells[r*4+c]=v); }
  function getCol(c){ return [0,1,2,3].map(r=>cells[r*4+c]); }
  function setCol(c,arr){ arr.forEach((v,r)=>cells[r*4+c]=v); }
  function canMerge(){
    for(let r=0;r<4;r++) for(let c=0;c<4;c++){
      const v = cells[r*4+c];
      if(c<3 && cells[r*4+c+1]===v) return true;
      if(r<3 && cells[(r+1)*4+c]===v) return true;
    }
    return false;
  }
  function move(dir){
    if(over || !dir) return;
    const before = cells.slice();
    if(dir==='left'){ for(let r=0;r<4;r++) setRow(r, slideRow(getRow(r))); }
    if(dir==='right'){ for(let r=0;r<4;r++) setRow(r, slideRow(getRow(r).reverse()).reverse()); }
    if(dir==='up'){ for(let c=0;c<4;c++) setCol(c, slideRow(getCol(c))); }
    if(dir==='down'){ for(let c=0;c<4;c++) setCol(c, slideRow(getCol(c).reverse()).reverse()); }
    const changed = cells.some((v,i)=>v!==before[i]);
    if(changed){
      addRandom(); render();
      if(cells.some(v=>v>=2048) && !over){ over=true; api.finish('win', `(${score} ochko bilan 2048 ga yetding!)`); return; }
      if(!empty().length && !canMerge()){ over=true; api.finish('lose', `(${score} ochko — joy qolmadi)`); }
    }
  }
  function onKey(e){
    const map = { ArrowLeft:'left', ArrowRight:'right', ArrowUp:'up', ArrowDown:'down' };
    if(map[e.key]){ move(map[e.key]); e.preventDefault(); }
  }
  window.addEventListener('keydown', onKey);
  let sx, sy;
  function ts(e){ sx = e.touches[0].clientX; sy = e.touches[0].clientY; }
  function te(e){
    const dx = e.changedTouches[0].clientX-sx, dy = e.changedTouches[0].clientY-sy;
    if(Math.abs(dx)>Math.abs(dy)) move(dx>30?'right':dx<-30?'left':null);
    else move(dy>30?'down':dy<-30?'up':null);
  }
  gridEl.addEventListener('touchstart', ts, {passive:true});
  gridEl.addEventListener('touchend', te, {passive:true});
  reset();
  function stop(){ window.removeEventListener('keydown', onKey); gridEl.removeEventListener('touchstart', ts); gridEl.removeEventListener('touchend', te); }
  return { stop };
}

/* ============ GAME 10: PING-PONG ============ */
function initPong(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Sen</span><span id="pg-score">0 : 0</span><span>Kompyuter</span></div>
      <canvas id="pg-canvas"></canvas>
    </div>`;
  const canvas = container.querySelector('#pg-canvas');
  const ctx = canvas.getContext('2d');
  function resize(){ canvas.width = container.clientWidth; canvas.height = container.clientHeight; }
  resize();
  window.addEventListener('resize', resize);
  const scoreEl = container.querySelector('#pg-score');

  const paddleH = 70, paddleW = 10;
  let py = canvas.height/2-paddleH/2, ay = canvas.height/2-paddleH/2;
  let bx, by, bvx, bvy, ps=0, as=0, over=false, raf;

  function onMove(e){
    const rect = canvas.getBoundingClientRect();
    const y = (e.touches ? e.touches[0].clientY : e.clientY)-rect.top;
    py = Math.max(0, Math.min(canvas.height-paddleH, y-paddleH/2));
  }
  canvas.addEventListener('mousemove', onMove);
  canvas.addEventListener('touchmove', onMove, {passive:true});

  function resetBall(){ bx=canvas.width/2; by=canvas.height/2; bvx=(Math.random()<0.5?-1:1)*4; bvy=(Math.random()*4-2); }
  function loop(){
    const target = by-paddleH/2;
    ay += (target-ay)*0.08;
    ay = Math.max(0, Math.min(canvas.height-paddleH, ay));
    bx += bvx; by += bvy;
    if(by<0 || by>canvas.height) bvy*=-1;
    if(bx<30 && bx>16 && by>py && by<py+paddleH){ bvx=Math.abs(bvx); bx=31; }
    if(bx>canvas.width-30 && bx<canvas.width-16 && by>ay && by<ay+paddleH){ bvx=-Math.abs(bvx); bx=canvas.width-31; }
    if(bx<0){ as++; scoreEl.textContent=ps+' : '+as; resetBall(); if(as>=5 && !over){ over=true; finishGame(false); } }
    if(bx>canvas.width){ ps++; scoreEl.textContent=ps+' : '+as; resetBall(); if(ps>=5 && !over){ over=true; finishGame(true); } }

    paintBG(ctx, canvas.width, canvas.height, 'arena', performance.now());
    ctx.fillStyle='#00d9ff'; ctx.fillRect(20,py,paddleW,paddleH);
    ctx.fillStyle='#ff3cac'; ctx.fillRect(canvas.width-30,ay,paddleW,paddleH);
    ctx.fillStyle='#ffd166'; ctx.beginPath(); ctx.arc(bx,by,7,0,Math.PI*2); ctx.fill();
    ctx.strokeStyle='rgba(255,255,255,0.1)'; ctx.setLineDash([6,8]);
    ctx.beginPath(); ctx.moveTo(canvas.width/2,0); ctx.lineTo(canvas.width/2,canvas.height); ctx.stroke(); ctx.setLineDash([]);
    if(!over) raf = requestAnimationFrame(loop);
  }
  function finishGame(won){
    cancelAnimationFrame(raf);
    if(won) api.finish('win', `(${ps}:${as} hisobida g'alaba!)`);
    else api.finish('lose', `(${ps}:${as} hisobida mag'lubiyat)`);
  }
  resetBall(); loop();
  function stop(){ cancelAnimationFrame(raf); window.removeEventListener('resize', resize); canvas.removeEventListener('mousemove', onMove); canvas.removeEventListener('touchmove', onMove); }
  return { stop };
}

/* ============ GAME 11: AIM TRAINER ============ */
function initAim(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Nishonlar: <b id="am-hits">0</b>/10</span><span id="am-timer">20.0s</span></div>
      <canvas id="am-canvas"></canvas>
    </div>`;
  const canvas = container.querySelector('#am-canvas');
  const ctx = canvas.getContext('2d');
  function resize(){ canvas.width=container.clientWidth; canvas.height=container.clientHeight; }
  resize();
  window.addEventListener('resize', resize);
  const hitsEl = container.querySelector('#am-hits');
  const timerEl = container.querySelector('#am-timer');
  let target=null, hits=0, timeLeft=20, over=false, raf, timerInt, spawnTimeout;
  const R = 26;

  function spawn(){
    target = { x: R+Math.random()*(canvas.width-2*R), y: R+Math.random()*(canvas.height-2*R), born: performance.now() };
    spawnTimeout = setTimeout(()=>{ if(!over){ target=null; spawn(); } }, 1100);
  }
  function onClick(e){
    if(over || !target) return;
    const rect = canvas.getBoundingClientRect();
    const x = (e.touches ? e.touches[0].clientX : e.clientX)-rect.left;
    const y = (e.touches ? e.touches[0].clientY : e.clientY)-rect.top;
    if(Math.hypot(x-target.x, y-target.y)<=R){
      hits++; hitsEl.textContent = hits;
      clearTimeout(spawnTimeout); target=null;
      if(hits>=10 && !over){ over=true; finishGame(true); return; }
      spawn();
    }
  }
  canvas.addEventListener('mousedown', onClick);
  canvas.addEventListener('touchstart', onClick, {passive:true});

  function loop(){
    paintBG(ctx, canvas.width, canvas.height, 'arena', performance.now());
    if(target){
      const age = (performance.now()-target.born)/1100;
      ctx.globalAlpha = 1-age*0.3;
      const grad = ctx.createRadialGradient(target.x,target.y,0,target.x,target.y,R);
      grad.addColorStop(0,'#ff3cac'); grad.addColorStop(1,'#6c5ce7');
      ctx.fillStyle = grad;
      ctx.beginPath(); ctx.arc(target.x,target.y,R*(1-age*0.15),0,Math.PI*2); ctx.fill();
      ctx.globalAlpha=1;
    }
    if(!over) raf = requestAnimationFrame(loop);
  }
  timerInt = setInterval(()=>{
    timeLeft -= 0.1;
    timerEl.textContent = Math.max(timeLeft,0).toFixed(1)+'s';
    if(timeLeft<=0 && !over){ over=true; finishGame(false); }
  }, 100);
  function finishGame(won){
    cancelAnimationFrame(raf); clearInterval(timerInt); clearTimeout(spawnTimeout);
    if(won) api.finish('win', `(${hits} ta nishonni urding!)`);
    else api.finish('lose', `(faqat ${hits}/10 nishon urding)`);
  }
  spawn(); loop();
  function stop(){ cancelAnimationFrame(raf); clearInterval(timerInt); clearTimeout(spawnTimeout); window.removeEventListener('resize', resize); canvas.removeEventListener('mousedown', onClick); canvas.removeEventListener('touchstart', onClick); }
  return { stop };
}

/* ============ GAME 12: FLAPPY ============ */
function initFlappy(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Ochko: <b id="fl-score">0</b>/10</span><span>Bosib uch!</span></div>
      <canvas id="fl-canvas"></canvas>
    </div>`;
  const canvas = container.querySelector('#fl-canvas');
  const ctx = canvas.getContext('2d');
  function resize(){ canvas.width=container.clientWidth; canvas.height=container.clientHeight; }
  resize();
  window.addEventListener('resize', resize);
  const scoreEl = container.querySelector('#fl-score');
  let birdY, birdV, pipes, score, over, raf, spawnTimer;
  const gravity=0.4, flap=-7, gap=150, pipeW=50, pipeSpeed=3;

  function reset(){ birdY=canvas.height/2; birdV=0; pipes=[]; score=0; over=false; scoreEl.textContent=score; }
  function doFlap(){ if(!over) birdV = flap; }
  function onKey(e){ if(e.code==='Space'){ doFlap(); e.preventDefault(); } }
  function onTouch(e){ e.preventDefault(); doFlap(); }
  window.addEventListener('keydown', onKey);
  canvas.addEventListener('mousedown', doFlap);
  canvas.addEventListener('touchstart', onTouch, {passive:false});

  function spawnPipe(){
    const top = 40+Math.random()*(canvas.height-gap-80);
    pipes.push({x:canvas.width, top, passed:false});
  }
  spawnTimer = setInterval(()=>{ if(!over) spawnPipe(); }, 1600);

  function loop(){
    birdV += gravity; birdY += birdV;
    pipes.forEach(p=> p.x -= pipeSpeed);
    pipes = pipes.filter(p=>p.x>-pipeW);
    const birdX=60, birdR=10;
    if(birdY-birdR<0 || birdY+birdR>canvas.height){ endGame(false); return; }
    pipes.forEach(p=>{
      if(birdX+birdR>p.x && birdX-birdR<p.x+pipeW){
        if(birdY-birdR<p.top || birdY+birdR>p.top+gap){ endGame(false); }
      }
      if(!p.passed && p.x+pipeW<birdX){ p.passed=true; score++; scoreEl.textContent=score; if(score>=10){ endGame(true); } }
    });
    if(over) return;
    paintBG(ctx, canvas.width, canvas.height, 'sky', performance.now());
    ctx.fillStyle='#2ecc71';
    pipes.forEach(p=>{ ctx.fillRect(p.x,0,pipeW,p.top); ctx.fillRect(p.x,p.top+gap,pipeW,canvas.height-p.top-gap); });
    ctx.save();
    ctx.translate(birdX, birdY);
    ctx.scale(-1, 1);
    ctx.rotate(-Math.max(-0.5, Math.min(0.9, birdV*0.06)));
    ctx.font='26px sans-serif'; ctx.textAlign='center'; ctx.textBaseline='middle';
    ctx.fillText('🐦', 0, 0);
    ctx.restore();
    raf = requestAnimationFrame(loop);
  }
  function endGame(won){
    if(over) return;
    over=true; cancelAnimationFrame(raf); clearInterval(spawnTimer);
    if(won) api.finish('win', `(${score} ta to'siqdan o'tding!)`);
    else api.finish('lose', `(${score} ochko bilan yiqilding)`);
  }
  reset(); loop();
  function stop(){ cancelAnimationFrame(raf); clearInterval(spawnTimer); window.removeEventListener('keydown', onKey); window.removeEventListener('resize', resize); canvas.removeEventListener('mousedown', doFlap); canvas.removeEventListener('touchstart', onTouch); }
  return { stop };
}

/* ============ GAME 13: BREAKOUT ============ */
function initBreakout(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Jonlar: <b id="bo-lives">3</b></span><span>G'ishtlar: <b id="bo-bricks">0</b></span></div>
      <canvas id="bo-canvas"></canvas>
    </div>`;
  const canvas = container.querySelector('#bo-canvas');
  const ctx = canvas.getContext('2d');
  function resize(){ canvas.width=container.clientWidth; canvas.height=container.clientHeight; }
  resize();
  window.addEventListener('resize', resize);
  const livesEl = container.querySelector('#bo-lives');
  const bricksEl = container.querySelector('#bo-bricks');

  const paddleW=80, paddleH=12;
  let paddleX = canvas.width/2-paddleW/2;
  let ballX=canvas.width/2, ballY=canvas.height-40, ballVX=3, ballVY=-3, ballR=6;
  let lives=3, over=false, raf, bricks=[];
  const cols=7, rowsN=4, brickW=Math.floor(canvas.width/cols)-6, brickH=18;

  function setupBricks(){
    bricks = [];
    for(let r=0;r<rowsN;r++) for(let c=0;c<cols;c++) bricks.push({x:c*(brickW+6)+3, y:r*(brickH+6)+40, w:brickW, h:brickH, alive:true});
    bricksEl.textContent = bricks.length;
  }
  setupBricks();

  function onMove(e){
    const rect = canvas.getBoundingClientRect();
    const x = (e.touches ? e.touches[0].clientX : e.clientX)-rect.left;
    paddleX = Math.max(0, Math.min(canvas.width-paddleW, x-paddleW/2));
  }
  canvas.addEventListener('mousemove', onMove);
  canvas.addEventListener('touchmove', onMove, {passive:true});

  function loop(){
    ballX += ballVX; ballY += ballVY;
    if(ballX<ballR || ballX>canvas.width-ballR) ballVX*=-1;
    if(ballY<ballR) ballVY*=-1;
    if(ballY>canvas.height-20-paddleH && ballY<canvas.height-20 && ballX>paddleX && ballX<paddleX+paddleW){
      ballVY=-Math.abs(ballVY);
      ballVX = ((ballX-(paddleX+paddleW/2))/(paddleW/2))*4;
    }
    if(ballY>canvas.height){
      lives--; livesEl.textContent = lives;
      if(lives<=0){ endGame(false); return; }
      ballX=canvas.width/2; ballY=canvas.height-40; ballVX=3; ballVY=-3;
    }
    let aliveCount=0;
    bricks.forEach(b=>{
      if(!b.alive) return;
      aliveCount++;
      if(ballX+ballR>b.x && ballX-ballR<b.x+b.w && ballY+ballR>b.y && ballY-ballR<b.y+b.h){ b.alive=false; ballVY*=-1; aliveCount--; }
    });
    bricksEl.textContent = aliveCount;
    if(aliveCount===0){ endGame(true); return; }

    paintBG(ctx, canvas.width, canvas.height, 'arena', performance.now());
    const colors=['#00d9ff','#6c5ce7','#ff3cac','#ffd166'];
    bricks.forEach((b,i)=>{ if(b.alive){ ctx.fillStyle=colors[Math.floor(i/cols)%colors.length]; ctx.fillRect(b.x,b.y,b.w,b.h); } });
    ctx.fillStyle='#e8ecf9'; ctx.fillRect(paddleX,canvas.height-20,paddleW,paddleH);
    ctx.fillStyle='#ffd166'; ctx.beginPath(); ctx.arc(ballX,ballY,ballR,0,Math.PI*2); ctx.fill();
    raf = requestAnimationFrame(loop);
  }
  function endGame(won){
    if(over) return;
    over=true; cancelAnimationFrame(raf);
    if(won) api.finish('win', "(Barcha g'ishtlarni buzding!)");
    else api.finish('lose', "(Jonlar tugadi)");
  }
  loop();
  function stop(){ cancelAnimationFrame(raf); window.removeEventListener('resize', resize); canvas.removeEventListener('mousemove', onMove); canvas.removeEventListener('touchmove', onMove); }
  return { stop };
}

/* ============ GAME 14: WORDLE ============ */
function initWordle(container, api){
  const words = ['QALAM','KATTA','DARYO','BAHOR','OLTIN','TARIX','YOZUV','SABZI'];
  const answer = words[Math.floor(Math.random()*words.length)];
  let attempts = [];
  let over = false;
  const maxAttempts = 6;
  container.innerHTML = `
    <div class="game-wrap center">
      <p style="color:var(--dim);font-size:13px;">5 harfli o'zbekcha so'zni ${maxAttempts} urinishda top!</p>
      <div class="wd-grid" id="wd-grid"></div>
      <div class="gn-input-row">
        <input type="text" id="wd-input" maxlength="5" placeholder="So'z..." style="text-transform:uppercase;">
        <button id="wd-btn">Tekshir</button>
      </div>
      <div class="gn-hint" id="wd-hint" style="font-size:12px;color:var(--dim);">🟩 to'g'ri joyda &nbsp; 🟨 so'zda bor &nbsp; ⬜ yo'q</div>
    </div>`;
  const grid = container.querySelector('#wd-grid');
  const input = container.querySelector('#wd-input');
  const btn = container.querySelector('#wd-btn');
  const hint = container.querySelector('#wd-hint');

  function render(){
    grid.innerHTML = '';
    for(let r=0;r<maxAttempts;r++){
      const row = document.createElement('div');
      row.className = 'wd-row';
      const g = attempts[r];
      for(let c=0;c<5;c++){
        const cell = document.createElement('div');
        cell.className = 'wd-cell';
        if(g){ cell.textContent = g.letters[c]; cell.classList.add(g.state[c]); }
        row.appendChild(cell);
      }
      grid.appendChild(row);
    }
  }
  function evaluate(word){
    const letters = word.split('');
    const state = Array(5).fill('gray');
    const ansArr = answer.split('');
    const used = Array(5).fill(false);
    for(let i=0;i<5;i++){ if(letters[i]===ansArr[i]){ state[i]='green'; used[i]=true; } }
    for(let i=0;i<5;i++){
      if(state[i]==='green') continue;
      const idx = ansArr.findIndex((l,j)=>l===letters[i] && !used[j]);
      if(idx!==-1){ state[i]='yellow'; used[idx]=true; }
    }
    return { letters, state };
  }
  function submit(){
    if(over) return;
    const val = input.value.toUpperCase().trim();
    if(val.length!==5){ hint.textContent = "Aynan 5 ta harf kirit!"; return; }
    attempts.push(evaluate(val));
    render();
    input.value = '';
    if(val===answer){ over=true; api.finish('win', `(So'zni ${attempts.length}-urinishda topding: ${answer})`); return; }
    if(attempts.length>=maxAttempts){ over=true; api.finish('lose', `(So'z "${answer}" ekan)`); return; }
    hint.textContent = "🟩 to'g'ri joyda  🟨 so'zda bor  ⬜ yo'q";
  }
  btn.onclick = submit;
  input.addEventListener('keydown', e=>{ if(e.key==='Enter') submit(); });
  render();
  return { stop(){} };
}

/* ============ GAME 15: QUICK MATH ============ */
function initMath(container, api){
  container.innerHTML = `
    <div class="game-wrap center">
      <div style="display:flex;gap:20px;font-size:14px;color:var(--dim);"><span>To'g'ri: <b id="mh-correct" style="color:var(--gold);">0</b>/8</span><span id="mh-timer">30.0s</span></div>
      <div id="mh-problem" style="font-family:'Space Grotesk',sans-serif;font-size:clamp(28px,6vw,44px);font-weight:700;"></div>
      <div class="gn-input-row">
        <input type="number" id="mh-input" placeholder="Javob...">
        <button id="mh-btn">Tekshir</button>
      </div>
    </div>`;
  const probEl = container.querySelector('#mh-problem');
  const input = container.querySelector('#mh-input');
  const btn = container.querySelector('#mh-btn');
  const correctEl = container.querySelector('#mh-correct');
  const timerEl = container.querySelector('#mh-timer');
  let correct=0, over=false, timeLeft=30, answer, timerInt;

  function newProblem(){
    const ops = ['+','-','×'];
    const op = ops[Math.floor(Math.random()*3)];
    let a,b;
    if(op==='×'){ a=Math.floor(Math.random()*12)+1; b=Math.floor(Math.random()*12)+1; answer=a*b; }
    else { a=Math.floor(Math.random()*50)+1; b=Math.floor(Math.random()*50)+1; answer = op==='+'? a+b : a-b; }
    probEl.textContent = `${a} ${op} ${b} = ?`;
  }
  function submit(){
    if(over) return;
    if(parseInt(input.value)===answer){
      correct++; correctEl.textContent = correct;
      if(correct>=8){ over=true; finishGame(true); return; }
    }
    input.value = '';
    newProblem();
  }
  btn.onclick = submit;
  input.addEventListener('keydown', e=>{ if(e.key==='Enter') submit(); });
  timerInt = setInterval(()=>{
    timeLeft -= 0.1;
    timerEl.textContent = Math.max(timeLeft,0).toFixed(1)+'s';
    if(timeLeft<=0 && !over){ over=true; finishGame(false); }
  }, 100);
  function finishGame(won){
    clearInterval(timerInt);
    if(won) api.finish('win', `(${correct} ta misolni to'g'ri yechding!)`);
    else api.finish('lose', `(faqat ${correct}/8 to'g'ri javob berding)`);
  }
  newProblem();
  function stop(){ clearInterval(timerInt); }
  return { stop };
}

/* ============ GAME 16: COLOR DIFF ============ */
function initColorDiff(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Bosqich: <b id="cd-round">1</b>/5</span><span id="cd-timer">5.0s</span></div>
      <div class="cd-grid" id="cd-grid"></div>
    </div>`;
  const grid = container.querySelector('#cd-grid');
  const roundEl = container.querySelector('#cd-round');
  const timerEl = container.querySelector('#cd-timer');
  let round=1, over=false, timerInt, timeLeft;

  function startRound(){
    timeLeft = 5;
    roundEl.textContent = round;
    const count = 4+round*3;
    const diff = 28-round*4;
    const hue = Math.floor(Math.random()*360);
    const oddIndex = Math.floor(Math.random()*count);
    grid.innerHTML = '';
    grid.style.gridTemplateColumns = `repeat(${Math.ceil(Math.sqrt(count))},1fr)`;
    for(let i=0;i<count;i++){
      const sq = document.createElement('button');
      sq.className = 'cd-swatch';
      const l = i===oddIndex ? 45+diff : 45;
      sq.style.background = `hsl(${hue},55%,${l}%)`;
      sq.onclick = () => pick(i===oddIndex);
      grid.appendChild(sq);
    }
    clearInterval(timerInt);
    timerInt = setInterval(()=>{
      timeLeft -= 0.1;
      timerEl.textContent = Math.max(timeLeft,0).toFixed(1)+'s';
      if(timeLeft<=0 && !over){ over=true; clearInterval(timerInt); api.finish('lose', `(${round}-bosqichda vaqt tugadi)`); }
    }, 100);
  }
  function pick(correct){
    if(over) return;
    clearInterval(timerInt);
    if(correct){
      if(round>=5){ over=true; api.finish('win', "(Barcha 5 bosqichni topding!)"); return; }
      round++; startRound();
    } else { over=true; api.finish('lose', `(${round}-bosqichda xato bosding)`); }
  }
  startRound();
  function stop(){ clearInterval(timerInt); }
  return { stop };
}

/* ============ GAME 17: BLACKJACK (21) ============ */
function initBlackjack(container, api){
  container.innerHTML = `
    <div class="game-wrap center">
      <div>
        <div>Diler: <span id="bj-dealer-score">?</span></div>
        <div class="bj-cards" id="bj-dealer-cards"></div>
        <div style="margin-top:14px;">Sen: <span id="bj-player-score">0</span></div>
        <div class="bj-cards" id="bj-player-cards"></div>
      </div>
      <div class="bj-actions">
        <button id="bj-hit" class="rps-btn">🃏 Yana kart</button>
        <button id="bj-stand" class="rps-btn">✋ To'xtash</button>
      </div>
    </div>`;
  const dealerCardsEl = container.querySelector('#bj-dealer-cards');
  const playerCardsEl = container.querySelector('#bj-player-cards');
  const dealerScoreEl = container.querySelector('#bj-dealer-score');
  const playerScoreEl = container.querySelector('#bj-player-score');
  const hitBtn = container.querySelector('#bj-hit');
  const standBtn = container.querySelector('#bj-stand');
  const suits = ['♠','♥','♦','♣'];
  const ranks = ['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
  function newDeck(){ const d=[]; suits.forEach(s=>ranks.forEach(r=>d.push({r,s}))); return d.sort(()=>Math.random()-0.5); }
  function value(hand){
    let total=0, aces=0;
    hand.forEach(c=>{ if(c.r==='A'){ total+=11; aces++; } else if(['J','Q','K'].includes(c.r)) total+=10; else total+=parseInt(c.r); });
    while(total>21 && aces>0){ total-=10; aces--; }
    return total;
  }
  let deck = newDeck();
  let player = [deck.pop(), deck.pop()];
  let dealer = [deck.pop(), deck.pop()];
  let over = false;
  function renderCard(c){ return `<div class="bj-card">${c.r}${c.s}</div>`; }
  function render(hideDealer){
    playerCardsEl.innerHTML = player.map(renderCard).join('');
    playerScoreEl.textContent = value(player);
    if(hideDealer){ dealerCardsEl.innerHTML = renderCard(dealer[0])+'<div class="bj-card">🂠</div>'; dealerScoreEl.textContent = '?'; }
    else { dealerCardsEl.innerHTML = dealer.map(renderCard).join(''); dealerScoreEl.textContent = value(dealer); }
  }
  function endRound(){
    over = true; hitBtn.disabled = true; standBtn.disabled = true;
    const pv = value(player);
    if(pv>21){ render(false); api.finish('lose', `(Sen 21 dan oshib ketding: ${pv})`); return; }
    let dealerVal = value(dealer);
    while(dealerVal<17){ dealer.push(deck.pop()); dealerVal = value(dealer); }
    render(false);
    if(dealerVal>21){ api.finish('win', `(Diler 21 dan oshdi: ${dealerVal})`); return; }
    if(pv>dealerVal) api.finish('win', `(${pv} vs ${dealerVal})`);
    else if(pv<dealerVal) api.finish('lose', `(${pv} vs ${dealerVal})`);
    else api.finish('draw', `(Ikkalasi ham ${dealerVal})`);
  }
  hitBtn.onclick = () => { if(over) return; player.push(deck.pop()); render(true); if(value(player)>21) endRound(); };
  standBtn.onclick = () => { if(!over) endRound(); };
  render(true);
  return { stop(){} };
}

/* ============ GAME 18: LIE DETECTOR (funny) ============ */
function initLieDetector(container, api){
  const questions = [
    "Sen hech qachon uxlab qolib darsga kechikkanmisan?",
    "Sen hech qachon ovqatni yashirincha yeb qo'yganmisan?",
    "Sen hech qachon \"men uydaman\" deb yolg'on gapirganmisan?",
    "Sen hech qachon biror narsani sindirib, \"shunday edi\" deganmisan?",
    "Sen hech qachon do'stingning sirini oshkor qilganmisan?"
  ];
  let idx = 0, over = false;
  container.innerHTML = `
    <div class="game-wrap center">
      <div style="font-size:13px;color:var(--dim);">Savol <span id="ld-num">1</span>/${questions.length}</div>
      <div id="ld-question" style="font-size:clamp(16px,3vw,20px);font-weight:600;max-width:420px;"></div>
      <div class="rps-choices">
        <button class="rps-btn" id="ld-yes">✅ Ha</button>
        <button class="rps-btn" id="ld-no">❌ Yo'q</button>
      </div>
    </div>`;
  const qEl = container.querySelector('#ld-question');
  const numEl = container.querySelector('#ld-num');
  function showQ(){ qEl.textContent = questions[idx]; numEl.textContent = idx+1; }
  function answer(){
    if(over) return;
    idx++;
    if(idx>=questions.length){
      over = true;
      const pct = Math.floor(Math.random()*100)+1;
      if(pct>=50) api.finish('lose', `(Yolg'on detektor darajasi: ${pct}% — sen yolg'onchisan! 🤥)`);
      else api.finish('win', `(Rostgo'ylik darajasi: ${100-pct}% — senga ishonsa bo'ladi! 😇)`);
      return;
    }
    showQ();
  }
  container.querySelector('#ld-yes').onclick = answer;
  container.querySelector('#ld-no').onclick = answer;
  showQ();
  return { stop(){} };
}

/* ============ GAME 19: WHEEL OF FORTUNE (funny) ============ */
function initWheel(container, api){
  const segments = [
    { text:"Bugun hamma senga yaxshi kayfiyatda duch keladi!", win:true },
    { text:"Telefoning batareyasi doim 1%da qoladi 😅", win:false },
    { text:"Kutilmagan sovg'a olasan!", win:true },
    { text:"Bugun Wi-Fi sekin ishlaydi", win:false },
    { text:"Sevimli taomingni yeysan!", win:true },
    { text:"Ertaga soyabon unutasan", win:false },
    { text:"Omad butun kun sen tarafda!", win:true },
    { text:"Kimdir sendan pul so'raydi 😂", win:false },
  ];
  const n = segments.length;
  container.innerHTML = `
    <div class="game-wrap center">
      <div class="wheel-wrap"><div class="wheel-pointer">▼</div><div class="wheel" id="wheel"></div></div>
      <button class="rps-btn" id="spin-btn">🎡 Aylantirish</button>
    </div>`;
  const wheel = container.querySelector('#wheel');
  const spinBtn = container.querySelector('#spin-btn');
  const colors = ['#00d9ff','#6c5ce7','#ff3cac','#ffd166'];
  const seg = 360/n;
  wheel.style.background = `conic-gradient(${segments.map((s,i)=>`${colors[i%colors.length]} ${i*seg}deg ${(i+1)*seg}deg`).join(',')})`;
  let spinning = false;
  let timeoutId;
  spinBtn.onclick = () => {
    if(spinning) return;
    spinning = true;
    const chosen = Math.floor(Math.random()*n);
    const rotation = 360*5 + (360-(chosen*seg+seg/2));
    wheel.style.transition = 'transform 3.5s cubic-bezier(0.2,0.8,0.2,1)';
    wheel.style.transform = `rotate(${rotation}deg)`;
    timeoutId = setTimeout(()=>{
      const s = segments[chosen];
      if(s.win) api.finish('win', `("${s.text}")`);
      else api.finish('lose', `("${s.text}")`);
    }, 3600);
  };
  function stop(){ clearTimeout(timeoutId); }
  return { stop };
}

/* ============ GAME 20: BUTTON MASH ============ */
function initMash(container, api){
  container.innerHTML = `
    <div class="game-wrap center">
      <div style="font-size:14px;color:var(--dim);">5 soniyada 30 marta bos!</div>
      <div id="mash-count" style="font-family:'Space Grotesk',sans-serif;font-size:64px;font-weight:700;color:var(--gold);">0</div>
      <div id="mash-timer" style="font-size:16px;">5.0s</div>
      <button id="mash-btn" class="mash-btn">BOS! 👊</button>
    </div>`;
  const countEl = container.querySelector('#mash-count');
  const timerEl = container.querySelector('#mash-timer');
  const btn = container.querySelector('#mash-btn');
  let clicks=0, timeLeft=5, over=false, started=false, timerInt;
  function start(){
    if(started) return;
    started = true;
    timerInt = setInterval(()=>{
      timeLeft -= 0.1;
      timerEl.textContent = Math.max(timeLeft,0).toFixed(1)+'s';
      if(timeLeft<=0 && !over){
        over = true; clearInterval(timerInt);
        if(clicks>=30) api.finish('win', `(${clicks} marta bosding!)`);
        else api.finish('lose', `(faqat ${clicks} marta bosding, 30 kerak edi)`);
      }
    }, 100);
  }
  function onClick(){ if(over) return; start(); clicks++; countEl.textContent = clicks; }
  function onTouch(e){ e.preventDefault(); onClick(); }
  btn.addEventListener('mousedown', onClick);
  btn.addEventListener('touchstart', onTouch, {passive:false});
  function stop(){ clearInterval(timerInt); }
  return { stop };
}

/* ============ GAME 21: SIMON SAYS ============ */
function initSimon(container, api){
  container.innerHTML = `
    <div class="game-wrap center">
      <div style="font-size:14px;color:var(--dim);">Bosqich: <b id="sm-level" style="color:var(--gold);">1</b>/8</div>
      <div class="simon-grid" id="simon-grid">
        <button class="simon-btn" data-i="0" style="background:#ff5c5c;"></button>
        <button class="simon-btn" data-i="1" style="background:#2ecc71;"></button>
        <button class="simon-btn" data-i="2" style="background:#00d9ff;"></button>
        <button class="simon-btn" data-i="3" style="background:#ffd166;"></button>
      </div>
      <div id="simon-status" style="font-size:13px;color:var(--dim);">Tomosha qil...</div>
    </div>`;
  const btns = container.querySelectorAll('.simon-btn');
  const levelEl = container.querySelector('#sm-level');
  const statusEl = container.querySelector('#simon-status');
  let sequence=[], playerIdx=0, level=1, over=false, locked=true, timeouts=[];
  function addStep(){ sequence.push(Math.floor(Math.random()*4)); }
  function flash(i){ const b=btns[i]; b.style.filter='brightness(1.9)'; timeouts.push(setTimeout(()=>{ b.style.filter=''; }, 400)); }
  function playSequence(){
    locked=true; playerIdx=0; statusEl.textContent="Tomosha qil...";
    sequence.forEach((s,idx)=> timeouts.push(setTimeout(()=>flash(s), idx*650)));
    timeouts.push(setTimeout(()=>{ locked=false; statusEl.textContent="Endi sen qaytar!"; }, sequence.length*650+200));
  }
  function onPress(i){
    if(locked || over) return;
    flash(i);
    if(i===sequence[playerIdx]){
      playerIdx++;
      if(playerIdx===sequence.length){
        if(level>=8){ over=true; api.finish('win', "(8 bosqichni yodlab chiqding!)"); return; }
        level++; levelEl.textContent=level; locked=true;
        timeouts.push(setTimeout(()=>{ addStep(); playSequence(); }, 800));
      }
    } else { over=true; api.finish('lose', `(${level}-bosqichda adashding)`); }
  }
  btns.forEach(b=> b.onclick = () => onPress(parseInt(b.dataset.i)));
  addStep();
  timeouts.push(setTimeout(playSequence, 700));
  function stop(){ timeouts.forEach(t=>clearTimeout(t)); }
  return { stop };
}

/* ============ GAME 22: MAZE ============ */
function initMaze(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Chiqish yo'lini top!</span><span id="mz-timer">30.0s</span></div>
      <canvas id="mz-canvas"></canvas>
      <div class="sn-dpad">
        <div class="sn-dpad-row"><button class="sn-dbtn" data-d="up">↑</button></div>
        <div class="sn-dpad-row">
          <button class="sn-dbtn" data-d="left">←</button>
          <button class="sn-dbtn" data-d="down">↓</button>
          <button class="sn-dbtn" data-d="right">→</button>
        </div>
      </div>
    </div>`;
  const canvas = container.querySelector('#mz-canvas');
  const ctx = canvas.getContext('2d');
  const timerEl = container.querySelector('#mz-timer');
  const maze = [
    [0,0,1,0,0,0,1,0,0,0,0],
    [1,0,1,0,1,0,1,0,1,1,0],
    [0,0,0,0,1,0,0,0,1,0,0],
    [0,1,1,1,1,1,1,0,1,0,1],
    [0,0,0,0,0,0,1,0,0,0,1],
    [1,1,1,1,1,0,1,1,1,0,0],
    [0,0,0,0,1,0,0,0,1,1,0],
    [0,1,1,0,1,1,1,0,0,0,0],
    [0,1,0,0,0,0,1,1,1,1,0],
    [0,1,0,1,1,0,0,0,0,1,0],
    [0,0,0,1,0,0,1,0,0,0,0],
  ];
  const rows = maze.length, cols = maze[0].length;
  let px=0, py=0;
  const exitX = cols-1, exitY = rows-1;
  let over=false, timeLeft=30, timerInt, cell;
  function resize(){ canvas.width=container.clientWidth; canvas.height=container.clientHeight; cell=Math.min(canvas.width/cols, canvas.height/rows); draw(); }
  window.addEventListener('resize', resize);
  function draw(){
    paintBG(ctx, canvas.width, canvas.height, 'dungeon', performance.now());
    for(let r=0;r<rows;r++) for(let c=0;c<cols;c++){
      ctx.fillStyle = maze[r][c] ? 'rgba(108,92,231,0.5)' : 'rgba(255,255,255,0.03)';
      ctx.fillRect(c*cell, r*cell, cell-2, cell-2);
    }
    ctx.fillStyle='#2ecc71'; ctx.fillRect(exitX*cell, exitY*cell, cell-2, cell-2);
    ctx.fillStyle='#00d9ff'; ctx.beginPath(); ctx.arc(px*cell+cell/2, py*cell+cell/2, cell/2.6, 0, Math.PI*2); ctx.fill();
  }
  function move(d){
    if(over) return;
    let nx=px, ny=py;
    if(d==='up') ny--; if(d==='down') ny++; if(d==='left') nx--; if(d==='right') nx++;
    if(nx<0||nx>=cols||ny<0||ny>=rows||maze[ny][nx]===1) return;
    px=nx; py=ny; draw();
    if(px===exitX && py===exitY){ over=true; clearInterval(timerInt); api.finish('win', `(${timeLeft.toFixed(1)}s qoldi!)`); }
  }
  function onKey(e){ const map={ArrowUp:'up',ArrowDown:'down',ArrowLeft:'left',ArrowRight:'right'}; if(map[e.key]){ move(map[e.key]); e.preventDefault(); } }
  window.addEventListener('keydown', onKey);
  container.querySelectorAll('.sn-dbtn').forEach(b=>{
    b.addEventListener('touchstart', e=>{ e.preventDefault(); move(b.dataset.d); }, {passive:false});
    b.addEventListener('mousedown', ()=> move(b.dataset.d));
  });
  timerInt = setInterval(()=>{
    timeLeft -= 0.1; timerEl.textContent = Math.max(timeLeft,0).toFixed(1)+'s';
    if(timeLeft<=0 && !over){ over=true; api.finish('lose', "(vaqt tugadi, chiqishni topolmading)"); }
  }, 100);
  resize();
  function stop(){ clearInterval(timerInt); window.removeEventListener('keydown', onKey); window.removeEventListener('resize', resize); }
  return { stop };
}

/* ============ GAME 23: BALLOON POP ============ */
function initBalloon(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Portlatilgan: <b id="bl-score">0</b>/15</span><span id="bl-timer">20.0s</span></div>
      <canvas id="bl-canvas"></canvas>
    </div>`;
  const canvas = container.querySelector('#bl-canvas');
  const ctx = canvas.getContext('2d');
  function resize(){ canvas.width=container.clientWidth; canvas.height=container.clientHeight; }
  resize();
  window.addEventListener('resize', resize);
  const scoreEl = container.querySelector('#bl-score');
  const timerEl = container.querySelector('#bl-timer');
  let balloons=[], score=0, over=false, timeLeft=20, raf, spawnTimer, timerInt;
  const colors=['#ff5c5c','#00d9ff','#6c5ce7','#ffd166','#2ecc71'];
  function spawn(){ balloons.push({ x:30+Math.random()*(canvas.width-60), y:canvas.height+20, speed:1.2+Math.random()*1.3, r:22, bomb:Math.random()<0.18, color:colors[Math.floor(Math.random()*colors.length)] }); }
  function onClick(e){
    if(over) return;
    const rect = canvas.getBoundingClientRect();
    const x=(e.touches? e.touches[0].clientX:e.clientX)-rect.left, y=(e.touches? e.touches[0].clientY:e.clientY)-rect.top;
    for(let i=balloons.length-1;i>=0;i--){
      const b = balloons[i];
      if(Math.hypot(x-b.x,y-b.y)<=b.r){
        if(b.bomb){ endGame(false,'bomb'); return; }
        balloons.splice(i,1); score++; scoreEl.textContent=score;
        if(score>=15 && !over){ endGame(true); }
        return;
      }
    }
  }
  canvas.addEventListener('mousedown', onClick);
  canvas.addEventListener('touchstart', onClick, {passive:true});
  function loop(){
    paintBG(ctx, canvas.width, canvas.height, 'sky', performance.now());
    balloons.forEach(b=>{
      b.y -= b.speed;
      ctx.font = (b.r*2.1)+'px sans-serif'; ctx.textAlign='center'; ctx.textBaseline='middle';
      ctx.fillText(b.bomb ? '💣' : '🎈', b.x, b.y);
    });
    balloons = balloons.filter(b=>b.y>-30);
    if(!over) raf = requestAnimationFrame(loop);
  }
  spawnTimer = setInterval(()=>{ if(!over) spawn(); }, 700);
  timerInt = setInterval(()=>{ timeLeft-=0.1; timerEl.textContent=Math.max(timeLeft,0).toFixed(1)+'s'; if(timeLeft<=0 && !over) endGame(false,'time'); }, 100);
  function endGame(won, reason){
    if(over) return;
    over=true; cancelAnimationFrame(raf); clearInterval(spawnTimer); clearInterval(timerInt);
    if(won) api.finish('win', `(${score} ta balon portlatding!)`);
    else if(reason==='bomb') api.finish('lose', "(Bombani bosib yubording! 💥)");
    else api.finish('lose', `(faqat ${score}/15 balon portlatding)`);
  }
  loop();
  function stop(){ cancelAnimationFrame(raf); clearInterval(spawnTimer); clearInterval(timerInt); window.removeEventListener('resize', resize); canvas.removeEventListener('mousedown', onClick); canvas.removeEventListener('touchstart', onClick); }
  return { stop };
}

/* ============ GAME 24: WHACK-A-MOLE ============ */
function initWhack(container, api){
  container.innerHTML = `
    <div class="game-wrap center">
      <div style="display:flex;gap:20px;font-size:14px;color:var(--dim);"><span>Urilgan: <b id="wk-score" style="color:var(--gold);">0</b>/12</span><span id="wk-timer">20.0s</span></div>
      <div class="wk-grid" id="wk-grid"></div>
    </div>`;
  const grid = container.querySelector('#wk-grid');
  const scoreEl = container.querySelector('#wk-score');
  const timerEl = container.querySelector('#wk-timer');
  let holes = [];
  for(let i=0;i<9;i++){ const h=document.createElement('button'); h.className='wk-hole'; grid.appendChild(h); holes.push(h); }
  let score=0, over=false, timeLeft=20, activeIdx=-1, moleTimeout, spawnTimeout, timerInt;
  function popMole(){
    if(over) return;
    activeIdx = Math.floor(Math.random()*9);
    holes[activeIdx].textContent='🦫'; holes[activeIdx].classList.add('up');
    moleTimeout = setTimeout(()=>{
      holes[activeIdx].textContent=''; holes[activeIdx].classList.remove('up'); activeIdx=-1;
      spawnTimeout = setTimeout(popMole, 250+Math.random()*300);
    }, 750);
  }
  holes.forEach((h,i)=> h.onclick = () => {
    if(over || i!==activeIdx) return;
    clearTimeout(moleTimeout);
    h.textContent=''; h.classList.remove('up'); activeIdx=-1;
    score++; scoreEl.textContent=score;
    if(score>=12 && !over){ over=true; finishGame(true); return; }
    spawnTimeout = setTimeout(popMole, 200);
  });
  timerInt = setInterval(()=>{ timeLeft-=0.1; timerEl.textContent=Math.max(timeLeft,0).toFixed(1)+'s'; if(timeLeft<=0 && !over){ over=true; finishGame(false); } }, 100);
  function finishGame(won){
    clearTimeout(moleTimeout); clearTimeout(spawnTimeout); clearInterval(timerInt);
    if(won) api.finish('win', `(${score} ta kalxatni urding!)`);
    else api.finish('lose', `(faqat ${score}/12 urding)`);
  }
  popMole();
  function stop(){ clearTimeout(moleTimeout); clearTimeout(spawnTimeout); clearInterval(timerInt); }
  return { stop };
}

/* ============ GAME 25: TRAFFIC DODGE ============ */
function initTraffic(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Omon qol!</span><span id="tf-timer">20.0s</span></div>
      <canvas id="tf-canvas"></canvas>
      <div class="sn-dpad" style="flex-direction:row;bottom:14px;">
        <button class="sn-dbtn" data-d="left">←</button>
        <button class="sn-dbtn" data-d="right">→</button>
      </div>
    </div>`;
  const canvas = container.querySelector('#tf-canvas');
  const ctx = canvas.getContext('2d');
  function resize(){ canvas.width=container.clientWidth; canvas.height=container.clientHeight; }
  resize();
  window.addEventListener('resize', resize);
  const timerEl = container.querySelector('#tf-timer');
  let lane=1, cars=[], over=false, timeLeft=20, raf, spawnTimer, timerInt;
  function laneX(l){ return canvas.width*((l+0.5)/3); }
  function move(d){ if(over) return; if(d==='left' && lane>0) lane--; if(d==='right' && lane<2) lane++; }
  function onKey(e){ if(e.key==='ArrowLeft'){ move('left'); e.preventDefault(); } if(e.key==='ArrowRight'){ move('right'); e.preventDefault(); } }
  window.addEventListener('keydown', onKey);
  container.querySelectorAll('.sn-dbtn').forEach(b=>{
    b.addEventListener('touchstart', e=>{ e.preventDefault(); move(b.dataset.d); }, {passive:false});
    b.addEventListener('mousedown', ()=> move(b.dataset.d));
  });
  function spawnCar(){ cars.push({ lane:Math.floor(Math.random()*3), y:-40, speed:3+Math.random()*2 }); }
  spawnTimer = setInterval(()=>{ if(!over) spawnCar(); }, 800);
  function loop(){
    cars.forEach(c=> c.y+=c.speed);
    cars = cars.filter(c=>c.y<canvas.height+50);
    const playerY = canvas.height-60, px = laneX(lane);
    cars.forEach(c=>{ const cx=laneX(c.lane); if(Math.abs(c.y-playerY)<30 && cx===px) endGame(false); });
    if(over) return;
    paintBG(ctx, canvas.width, canvas.height, 'road', performance.now());
    ctx.strokeStyle='rgba(255,255,255,0.08)';
    for(let i=1;i<3;i++){ ctx.beginPath(); ctx.moveTo(canvas.width*i/3,0); ctx.lineTo(canvas.width*i/3,canvas.height); ctx.stroke(); }
    ctx.font='34px sans-serif'; ctx.textAlign='center'; ctx.textBaseline='middle';
    cars.forEach(c=>{
      ctx.save(); ctx.translate(laneX(c.lane), c.y); ctx.rotate(-Math.PI/2);
      ctx.fillText('🚗', 0, 0); ctx.restore();
    });
    ctx.save(); ctx.translate(px, playerY); ctx.rotate(Math.PI/2);
    ctx.fillText('🚙', 0, 0); ctx.restore();
    raf = requestAnimationFrame(loop);
  }
  timerInt = setInterval(()=>{ timeLeft-=0.1; timerEl.textContent=Math.max(timeLeft,0).toFixed(1)+'s'; if(timeLeft<=0 && !over) endGame(true); }, 100);
  function endGame(won){
    if(over) return;
    over=true; cancelAnimationFrame(raf); clearInterval(spawnTimer); clearInterval(timerInt);
    if(won) api.finish('win', "(20 soniya omon qolding!)");
    else api.finish('lose', "(Mashinaga urilib qolding!)");
  }
  loop();
  function stop(){ cancelAnimationFrame(raf); clearInterval(spawnTimer); clearInterval(timerInt); window.removeEventListener('keydown', onKey); window.removeEventListener('resize', resize); }
  return { stop };
}

/* ============ GAME 26: PENALTY ============ */
function initPenalty(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Zarba: <b id="pn-round">1</b>/5</span><span>Gol: <b id="pn-goals">0</b></span></div>
      <canvas id="pn-canvas"></canvas>
      <div id="pn-result" style="position:absolute;left:0;right:0;bottom:92px;text-align:center;font-size:15px;font-weight:600;z-index:2;min-height:22px;text-shadow:0 2px 8px rgba(0,0,0,0.8);"></div>
      <div class="rps-choices" id="pn-choices" style="position:absolute;left:0;right:0;bottom:16px;justify-content:center;z-index:2;">
        <button class="rps-btn" data-d="left">⬅️ Chap</button>
        <button class="rps-btn" data-d="mid">⬆️ O'rta</button>
        <button class="rps-btn" data-d="right">➡️ O'ng</button>
      </div>
    </div>`;
  const canvas = container.querySelector('#pn-canvas');
  const ctx = canvas.getContext('2d');
  function resize(){ canvas.width=container.clientWidth; canvas.height=container.clientHeight; }
  resize();
  window.addEventListener('resize', resize);
  const roundEl = container.querySelector('#pn-round');
  const goalsEl = container.querySelector('#pn-goals');
  const resultEl = container.querySelector('#pn-result');
  const btns = container.querySelectorAll('#pn-choices .rps-btn');

  let round=1, goals=0, over=false, animating=false, raf;
  const dirs = ['left','mid','right'];
  const dirLabel = { left:'chap', mid:"o'rta", right:"o'ng" };
  const zoneX = { left:0.28, mid:0.5, right:0.72 };
  let ball = { x:0.5, y:0.86 };
  let keeper = { x:0.5, y:0.26 };
  let ballTarget=null, keeperTarget=null, animStart=0, animDur=650, pendingResult=null;

  function draw(){
    const w = canvas.width, h = canvas.height;
    paintBG(ctx, w, h, 'stadium', performance.now());
    const gx1=w*0.18, gx2=w*0.82, gy=h*0.16, gh=h*0.16;
    ctx.strokeStyle = '#f4f4f4'; ctx.lineWidth = 5;
    ctx.strokeRect(gx1, gy, gx2-gx1, gh);
    ctx.lineWidth = 1; ctx.strokeStyle = 'rgba(255,255,255,0.35)';
    for(let i=1;i<10;i++){ ctx.beginPath(); ctx.moveTo(gx1+(gx2-gx1)*i/10, gy); ctx.lineTo(gx1+(gx2-gx1)*i/10, gy+gh); ctx.stroke(); }
    for(let j=1;j<4;j++){ ctx.beginPath(); ctx.moveTo(gx1, gy+gh*j/4); ctx.lineTo(gx2, gy+gh*j/4); ctx.stroke(); }
    const kx = w*keeper.x, ky = h*keeper.y;
    ctx.fillStyle = '#ffd166';
    ctx.beginPath(); ctx.arc(kx, ky-14, 9, 0, Math.PI*2); ctx.fill();
    ctx.fillRect(kx-12, ky-6, 24, 26);
    const bx = w*ball.x, by = h*ball.y;
    ctx.fillStyle = '#e8ecf9';
    ctx.beginPath(); ctx.arc(bx, by, 10, 0, Math.PI*2); ctx.fill();
    ctx.strokeStyle = 'rgba(0,0,0,0.3)'; ctx.lineWidth = 1; ctx.stroke();
  }
  function idleLoop(){ draw(); if(!animating) raf = requestAnimationFrame(idleLoop); }

  function kick(d){
    if(over || animating) return;
    animating = true;
    btns.forEach(b=>b.disabled=true);
    resultEl.textContent = '';
    const keeperDir = dirs[Math.floor(Math.random()*3)];
    ballTarget = { x: zoneX[d], y: 0.28 };
    keeperTarget = { x: zoneX[keeperDir], y: 0.24 };
    const startBall = { x: ball.x, y: ball.y };
    const startKeeper = { x: keeper.x, y: keeper.y };
    animStart = performance.now();
    pendingResult = { chosen:d, keeperDir, saved: keeperDir===d };
    function animate(){
      const t = Math.min((performance.now()-animStart)/animDur, 1);
      const ease = t<0.5 ? 2*t*t : -1+(4-2*t)*t;
      ball.x = startBall.x + (ballTarget.x-startBall.x)*ease;
      ball.y = startBall.y + (ballTarget.y-startBall.y)*ease;
      keeper.x = startKeeper.x + (keeperTarget.x-startKeeper.x)*Math.min(t*1.3,1);
      draw();
      if(t<1) raf = requestAnimationFrame(animate);
      else finishKick();
    }
    animate();
  }
  function finishKick(){
    const { chosen, keeperDir, saved } = pendingResult;
    if(saved){ resultEl.textContent = `🧤 Ushladi! (ikkalasi ham ${dirLabel[chosen]})`; }
    else { goals++; goalsEl.textContent = goals; resultEl.textContent = `⚽ GOL! (darvozabon ${dirLabel[keeperDir]}ga otildi)`; }
    if(round>=5){
      over = true; animating = false;
      setTimeout(()=>{
        if(goals>=3) api.finish('win', `(${goals}/5 gol urding!)`);
        else api.finish('lose', `(faqat ${goals}/5 gol urding)`);
      }, 700);
      return;
    }
    round++; roundEl.textContent = round;
    setTimeout(()=>{
      ball = { x:0.5, y:0.86 }; keeper = { x:0.5, y:0.26 };
      animating = false;
      btns.forEach(b=>b.disabled=false);
      idleLoop();
    }, 900);
  }
  btns.forEach(b=> b.onclick = () => kick(b.dataset.d));
  idleLoop();
  function stop(){ cancelAnimationFrame(raf); window.removeEventListener('resize', resize); }
  return { stop };
}

/* ============ GAME 27: METEOR DODGE ============ */
function initMeteor(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Omon qol!</span><span id="mt-timer">20.0s</span></div>
      <canvas id="mt-canvas"></canvas>
    </div>`;
  const canvas = container.querySelector('#mt-canvas');
  const ctx = canvas.getContext('2d');
  function resize(){ canvas.width=container.clientWidth; canvas.height=container.clientHeight; }
  resize();
  window.addEventListener('resize', resize);
  const timerEl = container.querySelector('#mt-timer');
  let px = canvas.width/2;
  let meteors=[], over=false, timeLeft=20, raf, spawnTimer, timerInt;
  function onMove(e){
    const rect = canvas.getBoundingClientRect();
    px = (e.touches? e.touches[0].clientX:e.clientX)-rect.left;
    px = Math.max(20, Math.min(canvas.width-20, px));
  }
  canvas.addEventListener('mousemove', onMove);
  canvas.addEventListener('touchmove', onMove, {passive:true});
  function spawn(){ meteors.push({ x:Math.random()*canvas.width, y:-20, r:14+Math.random()*10, speed:2.5+Math.random()*2.5 }); }
  spawnTimer = setInterval(()=>{ if(!over) spawn(); }, 500);
  function loop(){
    meteors.forEach(m=> m.y+=m.speed);
    meteors = meteors.filter(m=>m.y<canvas.height+30);
    const py = canvas.height-40;
    meteors.forEach(m=>{ if(Math.hypot(m.x-px, m.y-py)<m.r+16) endGame(false); });
    if(over) return;
    paintBG(ctx, canvas.width, canvas.height, 'space', performance.now());
    ctx.font='30px sans-serif'; ctx.textAlign='center'; ctx.textBaseline='middle';
    meteors.forEach(m=> ctx.fillText('☄️', m.x, m.y));
    ctx.font='32px sans-serif'; ctx.fillText('🧑‍🚀', px, py);
    raf = requestAnimationFrame(loop);
  }
  timerInt = setInterval(()=>{ timeLeft-=0.1; timerEl.textContent=Math.max(timeLeft,0).toFixed(1)+'s'; if(timeLeft<=0 && !over) endGame(true); }, 100);
  function endGame(won){
    if(over) return;
    over=true; cancelAnimationFrame(raf); clearInterval(spawnTimer); clearInterval(timerInt);
    if(won) api.finish('win', "(Meteor yomg'iridan omon qolding!)");
    else api.finish('lose', "(Meteorga urilib qolding!)");
  }
  loop();
  function stop(){ cancelAnimationFrame(raf); clearInterval(spawnTimer); clearInterval(timerInt); window.removeEventListener('resize', resize); canvas.removeEventListener('mousemove', onMove); canvas.removeEventListener('touchmove', onMove); }
  return { stop };
}

/* ============ GAME 28: TRIVIA ============ */
function initTrivia(container, api){
  const questions = [
    { q:"O'zbekistonning poytaxti qaysi shahar?", opts:["Samarqand","Toshkent","Buxoro","Andijon"], a:1 },
    { q:"Yer necha kunda Quyosh atrofida aylanadi?", opts:["30","365","12","100"], a:1 },
    { q:"Suvning kimyoviy formulasi?", opts:["CO2","O2","H2O","NaCl"], a:2 },
    { q:"Quyosh sistemasidagi eng katta sayyora?", opts:["Mars","Yupiter","Yer","Venera"], a:1 },
    { q:"1 soatda necha daqiqa bor?", opts:["50","60","100","90"], a:1 },
  ];
  let idx=0, correct=0, over=false;
  container.innerHTML = `
    <div class="game-wrap center">
      <div style="font-size:13px;color:var(--dim);">Savol <span id="tv-num">1</span>/${questions.length}</div>
      <div id="tv-q" style="font-size:clamp(16px,3vw,20px);font-weight:600;max-width:440px;"></div>
      <div class="tv-opts" id="tv-opts"></div>
    </div>`;
  const qEl = container.querySelector('#tv-q');
  const numEl = container.querySelector('#tv-num');
  const optsEl = container.querySelector('#tv-opts');
  function render(){
    const item = questions[idx];
    qEl.textContent = item.q; numEl.textContent = idx+1;
    optsEl.innerHTML = '';
    item.opts.forEach((o,i)=>{
      const b = document.createElement('button');
      b.className = 'rps-btn'; b.textContent = o;
      b.onclick = () => answer(i);
      optsEl.appendChild(b);
    });
  }
  function answer(i){
    if(over) return;
    if(i===questions[idx].a) correct++;
    idx++;
    if(idx>=questions.length){
      over = true;
      if(correct>=4) api.finish('win', `(${correct}/${questions.length} to'g'ri javob berding!)`);
      else api.finish('lose', `(faqat ${correct}/${questions.length} to'g'ri javob berding)`);
      return;
    }
    render();
  }
  render();
  return { stop(){} };
}

/* ============ GAME 29: COIN FLIP ============ */
function initCoin(container, api){
  container.innerHTML = `
    <div class="game-wrap center">
      <div style="font-size:14px;color:var(--dim);">Urinish: <b id="cn-round" style="color:var(--gold);">1</b>/5 &nbsp;|&nbsp; To'g'ri: <b id="cn-correct" style="color:var(--gold);">0</b></div>
      <div style="font-size:70px;">🪙</div>
      <div id="cn-result" style="font-size:15px;min-height:22px;">Tanga qaysi tarafga tushadi?</div>
      <div class="rps-choices">
        <button class="rps-btn" data-c="head">👑 Gerb</button>
        <button class="rps-btn" data-c="tail">🔢 Raqam</button>
      </div>
    </div>`;
  const roundEl = container.querySelector('#cn-round');
  const correctEl = container.querySelector('#cn-correct');
  const resultEl = container.querySelector('#cn-result');
  let round=1, correct=0, over=false;
  function flip(choice){
    if(over) return;
    const outcome = Math.random()<0.5 ? 'head' : 'tail';
    const label = outcome==='head' ? '👑 Gerb' : '🔢 Raqam';
    if(choice===outcome){ correct++; correctEl.textContent=correct; resultEl.textContent = `${label} chiqdi — TOPDING!`; }
    else { resultEl.textContent = `${label} chiqdi — adashding.`; }
    if(round>=5){
      over=true;
      if(correct>=3) api.finish('win', `(${correct}/5 to'g'ri taxmin qilding!)`);
      else api.finish('lose', `(faqat ${correct}/5 to'g'ri taxmin qilding)`);
      return;
    }
    round++; roundEl.textContent = round;
  }
  container.querySelectorAll('.rps-choices .rps-btn').forEach(b=> b.onclick = () => flip(b.dataset.c));
  return { stop(){} };
}

/* ============ GAME 30: LIGHTS OUT ============ */
function initLightsOut(container, api){
  const size = 5;
  let grid = Array(size*size).fill(false);
  function idx(r,c){ return r*size+c; }
  function toggle(r,c){
    [[0,0],[1,0],[-1,0],[0,1],[0,-1]].forEach(([dr,dc])=>{
      const nr=r+dr, nc=c+dc;
      if(nr>=0&&nr<size&&nc>=0&&nc<size) grid[idx(nr,nc)] = !grid[idx(nr,nc)];
    });
  }
  for(let i=0;i<15;i++) toggle(Math.floor(Math.random()*size), Math.floor(Math.random()*size));
  container.innerHTML = `
    <div class="game-wrap center">
      <div style="font-size:13px;color:var(--dim);">Yurishlar: <b id="lo-moves" style="color:var(--gold);">0</b>/20 — barcha chiroqni o'chir!</div>
      <div class="lo-grid" id="lo-grid"></div>
    </div>`;
  const gridEl = container.querySelector('#lo-grid');
  const movesEl = container.querySelector('#lo-moves');
  let moves=0, over=false;
  function render(){
    gridEl.innerHTML = '';
    for(let r=0;r<size;r++) for(let c=0;c<size;c++){
      const b = document.createElement('button');
      b.className = 'lo-cell' + (grid[idx(r,c)] ? ' on' : '');
      b.onclick = () => press(r,c);
      gridEl.appendChild(b);
    }
  }
  function press(r,c){
    if(over) return;
    toggle(r,c); moves++; movesEl.textContent = moves;
    render();
    if(grid.every(v=>!v)){ over=true; api.finish('win', `(${moves} yurishda barchasini o'chirding!)`); return; }
    if(moves>=20 && !over){ over=true; api.finish('lose', "(20 yurish tugadi, chiroqlar qolib ketdi)"); }
  }
  render();
  return { stop(){} };
}

/* ============ GAME 31: NUMBER MEMORY ============ */
function initNumberMemory(container, api){
  container.innerHTML = `
    <div class="game-wrap center">
      <div style="font-size:13px;color:var(--dim);">Bosqich: <b id="nm-level" style="color:var(--gold);">1</b>/6</div>
      <div id="nm-display" style="font-family:'Space Grotesk',sans-serif;font-size:clamp(28px,6vw,42px);font-weight:700;letter-spacing:0.1em;"></div>
      <div class="gn-input-row" id="nm-input-row" style="display:none;">
        <input type="text" id="nm-input" inputmode="numeric" placeholder="Raqamni yoz...">
        <button id="nm-btn">Tasdiqlash</button>
      </div>
    </div>`;
  const displayEl = container.querySelector('#nm-display');
  const levelEl = container.querySelector('#nm-level');
  const inputRow = container.querySelector('#nm-input-row');
  const input = container.querySelector('#nm-input');
  const btn = container.querySelector('#nm-btn');
  let level=1, over=false, current='', timeouts=[];
  function nextRound(){
    let digits = 3+level;
    current = '';
    for(let i=0;i<digits;i++) current += Math.floor(Math.random()*10);
    displayEl.textContent = current;
    inputRow.style.display = 'none';
    timeouts.push(setTimeout(()=>{ displayEl.textContent='???'; inputRow.style.display='flex'; input.value=''; input.focus(); }, 1000+digits*350));
  }
  function submit(){
    if(over) return;
    if(input.value.trim()===current){
      if(level>=6){ over=true; api.finish('win', "(6 bosqichni yodlab chiqding!)"); return; }
      level++; levelEl.textContent=level; nextRound();
    } else { over=true; api.finish('lose', `(To'g'ri raqam ${current} edi)`); }
  }
  btn.onclick = submit;
  input.addEventListener('keydown', e=>{ if(e.key==='Enter') submit(); });
  nextRound();
  function stop(){ timeouts.forEach(t=>clearTimeout(t)); }
  return { stop };
}

/* ============ GAME 32: TYPING SPEED ============ */
function initTyping(container, api){
  const words = ["OLMA","KITOB","QUYOSH","BAHOR","YULDUZ","DARYO","SEVGI","DOSTLIK"];
  const list = [...words].sort(()=>Math.random()-0.5).slice(0,5);
  let idx=0, over=false, timeLeft=20, timerInt;
  container.innerHTML = `
    <div class="game-wrap center">
      <div style="display:flex;gap:20px;font-size:14px;color:var(--dim);"><span>So'z: <b id="tp-idx" style="color:var(--gold);">1</b>/5</span><span id="tp-timer">20.0s</span></div>
      <div id="tp-word" style="font-family:'Space Grotesk',sans-serif;font-size:clamp(28px,6vw,42px);font-weight:700;letter-spacing:0.05em;"></div>
      <input type="text" id="tp-input" placeholder="Shu yerga yoz..." style="background:rgba(255,255,255,0.06);border:1px solid rgba(232,236,249,0.2);color:var(--star);padding:12px 16px;border-radius:12px;font-size:18px;text-align:center;width:220px;outline:none;">
    </div>`;
  const wordEl = container.querySelector('#tp-word');
  const idxEl = container.querySelector('#tp-idx');
  const timerEl = container.querySelector('#tp-timer');
  const input = container.querySelector('#tp-input');
  function showWord(){ wordEl.textContent = list[idx]; input.value=''; input.focus(); }
  function onInput(){
    if(over) return;
    if(input.value.toUpperCase()===list[idx]){
      idx++;
      if(idx>=list.length){ over=true; finishGame(true); return; }
      idxEl.textContent = idx+1;
      showWord();
    }
  }
  input.addEventListener('input', onInput);
  timerInt = setInterval(()=>{ timeLeft-=0.1; timerEl.textContent=Math.max(timeLeft,0).toFixed(1)+'s'; if(timeLeft<=0 && !over){ over=true; finishGame(false); } }, 100);
  function finishGame(won){
    clearInterval(timerInt);
    if(won) api.finish('win', `(Barcha ${list.length} so'zni terding!)`);
    else api.finish('lose', `(faqat ${idx}/${list.length} so'zni terding)`);
  }
  showWord();
  function stop(){ clearInterval(timerInt); }
  return { stop };
}

/* ============ GAME 33: STACK TOWER ============ */
function initStack(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Balandlik: <b id="st-height">0</b>/10</span><span>Bosib tashla!</span></div>
      <canvas id="st-canvas"></canvas>
    </div>`;
  const canvas = container.querySelector('#st-canvas');
  const ctx = canvas.getContext('2d');
  function resize(){ canvas.width=container.clientWidth; canvas.height=container.clientHeight; }
  resize();
  window.addEventListener('resize', resize);
  const heightEl = container.querySelector('#st-height');
  const blockH = 26;
  let blocks=[], baseW=120, over=false, raf, current, dir=1, speed=3, cameraY=0;
  function reset(){
    blocks = [{ x:canvas.width/2-baseW/2, w:baseW, y:canvas.height-blockH }];
    current = { x:0, w:baseW, y:canvas.height-blockH*2 };
    dir=1; speed=3; cameraY=0; over=false;
    heightEl.textContent = 0;
  }
  function onDrop(){
    if(over) return;
    const top = blocks[blocks.length-1];
    const overlap = Math.min(current.x+current.w, top.x+top.w) - Math.max(current.x, top.x);
    if(overlap<=4){ endGame(false); return; }
    const nx = Math.max(current.x, top.x);
    blocks.push({ x:nx, w:overlap, y:current.y });
    heightEl.textContent = blocks.length-1;
    if(blocks.length-1>=10){ endGame(true); return; }
    current = { x:0, w:overlap, y:current.y-blockH };
    dir = Math.random()<0.5?-1:1;
    speed = Math.min(3+blocks.length*0.25, 8);
    if(current.y < canvas.height*0.4+cameraY) cameraY += blockH;
  }
  canvas.addEventListener('mousedown', onDrop);
  canvas.addEventListener('touchstart', e=>{ e.preventDefault(); onDrop(); }, {passive:false});
  function loop(){
    if(!over){ current.x += dir*speed; if(current.x<0 || current.x+current.w>canvas.width) dir*=-1; }
    paintBG(ctx, canvas.width, canvas.height, 'sunset', performance.now());
    ctx.save(); ctx.translate(0, cameraY);
    const colors=['#00d9ff','#6c5ce7','#ff3cac','#ffd166','#2ecc71'];
    blocks.forEach((b,i)=>{ ctx.fillStyle=colors[i%colors.length]; ctx.fillRect(b.x,b.y,b.w,blockH-3); });
    if(!over){ ctx.fillStyle='#e8ecf9'; ctx.fillRect(current.x,current.y,current.w,blockH-3); }
    ctx.restore();
    if(!over) raf = requestAnimationFrame(loop);
  }
  function endGame(won){
    if(over) return;
    over=true; cancelAnimationFrame(raf);
    if(won) api.finish('win', "(10 qavatli minora qurding!)");
    else api.finish('lose', `(${blocks.length-1}-qavatda yiqilib tushding)`);
  }
  reset(); loop();
  function stop(){ cancelAnimationFrame(raf); window.removeEventListener('resize', resize); canvas.removeEventListener('mousedown', onDrop); }
  return { stop };
}

/* ============ GAME 34: FISHING ============ */
function initFishing(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Tutilgan: <b id="fh-score">0</b>/10</span><span id="fh-timer">20.0s</span></div>
      <canvas id="fh-canvas"></canvas>
    </div>`;
  const canvas = container.querySelector('#fh-canvas');
  const ctx = canvas.getContext('2d');
  function resize(){ canvas.width=container.clientWidth; canvas.height=container.clientHeight; }
  resize();
  window.addEventListener('resize', resize);
  const scoreEl = container.querySelector('#fh-score');
  const timerEl = container.querySelector('#fh-timer');
  let items=[], score=0, over=false, timeLeft=20, raf, spawnTimer, timerInt;
  function spawn(){
    const isTrash = Math.random()<0.3, fromLeft = Math.random()<0.5;
    items.push({ x: fromLeft?-30:canvas.width+30, y:40+Math.random()*(canvas.height-80), vx:(fromLeft?1:-1)*(1.5+Math.random()*2), trash:isTrash, r:16 });
  }
  function onClick(e){
    if(over) return;
    const rect = canvas.getBoundingClientRect();
    const x=(e.touches? e.touches[0].clientX:e.clientX)-rect.left, y=(e.touches? e.touches[0].clientY:e.clientY)-rect.top;
    for(let i=items.length-1;i>=0;i--){
      const it = items[i];
      if(Math.hypot(x-it.x,y-it.y)<=it.r+8){
        items.splice(i,1);
        if(it.trash){ endGame(false); return; }
        score++; scoreEl.textContent=score;
        if(score>=10 && !over){ endGame(true); }
        return;
      }
    }
  }
  canvas.addEventListener('mousedown', onClick);
  canvas.addEventListener('touchstart', onClick, {passive:true});
  spawnTimer = setInterval(()=>{ if(!over) spawn(); }, 650);
  function loop(){
    paintBG(ctx, canvas.width, canvas.height, 'ocean', performance.now());
    items.forEach(it=>{
      it.x += it.vx;
      ctx.font='26px sans-serif'; ctx.textAlign='center'; ctx.textBaseline='middle';
      ctx.save(); ctx.translate(it.x, it.y);
      if(!it.trash && it.vx>0) ctx.scale(-1,1);
      ctx.fillText(it.trash? '🥾' : '🐟', 0, 0);
      ctx.restore();
    });
    items = items.filter(it=> it.x>-50 && it.x<canvas.width+50);
    if(!over) raf = requestAnimationFrame(loop);
  }
  timerInt = setInterval(()=>{ timeLeft-=0.1; timerEl.textContent=Math.max(timeLeft,0).toFixed(1)+'s'; if(timeLeft<=0 && !over) endGame(false); }, 100);
  function endGame(won){
    if(over) return;
    over=true; cancelAnimationFrame(raf); clearInterval(spawnTimer); clearInterval(timerInt);
    if(won || score>=10) api.finish('win', `(${score} ta baliq tutding!)`);
    else api.finish('lose', `(faqat ${score}/10 baliq tutding)`);
  }
  loop();
  function stop(){ cancelAnimationFrame(raf); clearInterval(spawnTimer); clearInterval(timerInt); window.removeEventListener('resize', resize); canvas.removeEventListener('mousedown', onClick); canvas.removeEventListener('touchstart', onClick); }
  return { stop };
}

/* ============ GAME 35: DINO RUN ============ */
function initDino(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Masofa: <b id="dn-score">0</b>/300</span><span>Sakrash uchun bos!</span></div>
      <canvas id="dn-canvas"></canvas>
    </div>`;
  const canvas = container.querySelector('#dn-canvas');
  const ctx = canvas.getContext('2d');
  function resize(){ canvas.width=container.clientWidth; canvas.height=container.clientHeight; }
  resize();
  window.addEventListener('resize', resize);
  const scoreEl = container.querySelector('#dn-score');
  const groundY = () => canvas.height-40;
  let dinoY, dinoVY, jumping, obstacles, score, speed, over, raf, spawnTimer;
  function reset(){ dinoY=0; dinoVY=0; jumping=false; obstacles=[]; score=0; speed=4; over=false; scoreEl.textContent=0; }
  function jump(){ if(!jumping && !over){ dinoVY=-11; jumping=true; } }
  function onKey(e){ if(e.code==='Space'){ jump(); e.preventDefault(); } }
  function onTouch(e){ e.preventDefault(); jump(); }
  window.addEventListener('keydown', onKey);
  canvas.addEventListener('mousedown', jump);
  canvas.addEventListener('touchstart', onTouch, {passive:false});
  function spawnObstacle(){ obstacles.push({ x:canvas.width+20, w:18+Math.random()*14, h:30+Math.random()*20 }); }
  spawnTimer = setInterval(()=>{ if(!over) spawnObstacle(); }, 1400);
  function loop(){
    dinoVY += 0.6; dinoY += dinoVY;
    if(dinoY>0){ dinoY=0; dinoVY=0; jumping=false; }
    obstacles.forEach(o=> o.x -= speed);
    obstacles = obstacles.filter(o=> o.x>-40);
    score += 0.5; scoreEl.textContent = Math.floor(score);
    speed = Math.min(4+score*0.01, 10);
    const dinoX=60, dinoSize=30, dinoBottom = groundY()+dinoY;
    obstacles.forEach(o=>{ if(dinoX+dinoSize/2>o.x && dinoX-dinoSize/2<o.x+o.w && dinoBottom>groundY()-o.h+8) endGame(false); });
    if(over) return;
    if(score>=300){ endGame(true); return; }
    paintBG(ctx, canvas.width, canvas.height, 'desert', performance.now());
    ctx.strokeStyle='rgba(120,70,20,0.4)';
    ctx.beginPath(); ctx.moveTo(0,groundY()+30); ctx.lineTo(canvas.width,groundY()+40); ctx.stroke();
    ctx.font='45px sans-serif'; ctx.textAlign='center'; ctx.textBaseline='middle';
    obstacles.forEach(o=> ctx.fillText('🌵', o.x+o.w/2, groundY()-o.h/2+30));
    ctx.save();
    ctx.translate(dinoX, dinoBottom+15);
    ctx.scale(-1, 1);
    if(jumping) ctx.rotate(0.1);
    ctx.font='36px sans-serif';
    ctx.fillText('🦖', 0, 0);
    ctx.restore();
    raf = requestAnimationFrame(loop);
  }
  function endGame(won){
    if(over) return;
    over=true; cancelAnimationFrame(raf); clearInterval(spawnTimer);
    if(won) api.finish('win', "(300 masofani bosib o'tding!)");
    else api.finish('lose', `(${Math.floor(score)} masofada to'siqqa urilding)`);
  }
  reset(); loop();
  function stop(){ cancelAnimationFrame(raf); clearInterval(spawnTimer); window.removeEventListener('keydown', onKey); window.removeEventListener('resize', resize); canvas.removeEventListener('mousedown', jump); canvas.removeEventListener('touchstart', onTouch); }
  return { stop };
}

/* ============ GAME 36: DUCK HUNT ============ */
function initDuckHunt(container, api){
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Urilgan: <b id="dh-score">0</b>/10</span><span>O'q: <b id="dh-ammo">15</b></span></div>
      <canvas id="dh-canvas"></canvas>
    </div>`;
  const canvas = container.querySelector('#dh-canvas');
  const ctx = canvas.getContext('2d');
  function resize(){ canvas.width=container.clientWidth; canvas.height=container.clientHeight; }
  resize();
  window.addEventListener('resize', resize);
  const scoreEl = container.querySelector('#dh-score');
  const ammoEl = container.querySelector('#dh-ammo');
  let ducks=[], score=0, ammo=15, over=false, raf, spawnTimer;
  function spawn(){
    const fromLeft = Math.random()<0.5;
    ducks.push({ x: fromLeft?-30:canvas.width+30, y:40+Math.random()*(canvas.height-100), vx:(fromLeft?1:-1)*(2+Math.random()*2), vy:(Math.random()-0.5)*1.5, r:18 });
  }
  function onClick(e){
    if(over || ammo<=0) return;
    const rect = canvas.getBoundingClientRect();
    const x=(e.touches? e.touches[0].clientX:e.clientX)-rect.left, y=(e.touches? e.touches[0].clientY:e.clientY)-rect.top;
    ammo--; ammoEl.textContent = ammo;
    for(let i=ducks.length-1;i>=0;i--){
      const d = ducks[i];
      if(Math.hypot(x-d.x,y-d.y)<=d.r){
        ducks.splice(i,1); score++; scoreEl.textContent=score;
        if(score>=10 && !over){ endGame(true); }
        break;
      }
    }
    if(ammo<=0 && score<10 && !over) setTimeout(()=>{ if(!over) endGame(false); }, 600);
  }
  canvas.addEventListener('mousedown', onClick);
  canvas.addEventListener('touchstart', onClick, {passive:true});
  spawnTimer = setInterval(()=>{ if(!over) spawn(); }, 900);
  function loop(){
    paintBG(ctx, canvas.width, canvas.height, 'ocean', performance.now());
    ducks.forEach(d=>{
      d.x+=d.vx; d.y+=d.vy;
      ctx.font='30px sans-serif'; ctx.textAlign='center'; ctx.textBaseline='middle';
      ctx.save(); ctx.translate(d.x, d.y);
      if(d.vx>0) ctx.scale(-1,1);
      ctx.fillText('🦆', 0, 0);
      ctx.restore();
    });
    ducks = ducks.filter(d=> d.x>-50 && d.x<canvas.width+50);
    if(!over) raf = requestAnimationFrame(loop);
  }
  function endGame(won){
    if(over) return;
    over=true; cancelAnimationFrame(raf); clearInterval(spawnTimer);
    if(won) api.finish('win', `(${score} ta o'rdakni urding!)`);
    else api.finish('lose', `(faqat ${score}/10 o'rdakni urding, o'q tugadi)`);
  }
  loop();
  function stop(){ cancelAnimationFrame(raf); clearInterval(spawnTimer); window.removeEventListener('resize', resize); canvas.removeEventListener('mousedown', onClick); canvas.removeEventListener('touchstart', onClick); }
  return { stop };
}

/* ============ GAME 37: SLOT MACHINE ============ */
function initSlot(container, api){
  const symbols = ['🍒','🍋','🍇','⭐','💎','🔔'];
  container.innerHTML = `
    <div class="game-wrap center">
      <div class="slot-reels"><div class="slot-reel">🍒</div><div class="slot-reel">🍋</div><div class="slot-reel">🍇</div></div>
      <button class="rps-btn" id="slot-btn">🎰 Aylantirish</button>
    </div>`;
  const reels = container.querySelectorAll('.slot-reel');
  const btn = container.querySelector('#slot-btn');
  let spinning = false, timers = [];
  btn.onclick = () => {
    if(spinning) return;
    spinning = true;
    const results = [0,0,0].map(()=> symbols[Math.floor(Math.random()*symbols.length)]);
    reels.forEach((r,i)=>{
      let count=0;
      const t = setInterval(()=>{
        r.textContent = symbols[Math.floor(Math.random()*symbols.length)];
        count++;
        if(count> 8+i*4){
          clearInterval(t);
          r.textContent = results[i];
          if(i===2){
            spinning = false;
            setTimeout(()=>{
              if(results[0]===results[1] && results[1]===results[2]) api.finish('win', `(${results[0]}${results[1]}${results[2]} — JEKPOT!)`);
              else api.finish('lose', `(${results[0]}${results[1]}${results[2]} — mos kelmadi)`);
            }, 300);
          }
        }
      }, 80);
      timers.push(t);
    });
  };
  function stop(){ timers.forEach(t=>clearInterval(t)); }
  return { stop };
}

/* ============ GAME 38: STOPWATCH PRECISION ============ */
function initStopwatch(container, api){
  const target = 5.00;
  container.innerHTML = `
    <div class="game-wrap center">
      <p style="color:var(--dim);font-size:13px;">Soat ${target.toFixed(2)} ga yaqinroq to'xtat!</p>
      <div id="sw-display" style="font-family:'Space Grotesk',sans-serif;font-size:clamp(40px,8vw,64px);font-weight:700;color:var(--gold);">0.00</div>
      <button class="rps-btn" id="sw-btn">⏱️ To'xtatish</button>
    </div>`;
  const display = container.querySelector('#sw-display');
  const btn = container.querySelector('#sw-btn');
  let val=0, dir=1, raf, over=false;
  function loop(){
    val += dir*0.03;
    if(val>10){ val=10; dir=-1; }
    if(val<0){ val=0; dir=1; }
    display.textContent = val.toFixed(2);
    if(!over) raf = requestAnimationFrame(loop);
  }
  btn.onclick = () => {
    if(over) return;
    over = true; cancelAnimationFrame(raf);
    const diff = Math.abs(val-target);
    if(diff<=0.15) api.finish('win', `(${val.toFixed(2)} — target ${target.toFixed(2)}ga judayam yaqin!)`);
    else api.finish('lose', `(${val.toFixed(2)} — target ${target.toFixed(2)} edi, ${diff.toFixed(2)} farq bilan)`);
  };
  loop();
  function stop(){ cancelAnimationFrame(raf); }
  return { stop };
}

/* ============ GAME 39: NUMBER ORDER ============ */
function initNumberOrder(container, api){
  const total = 20;
  let numbers = Array.from({length: total}, (_,i)=>i+1).sort(()=>Math.random()-0.5);
  container.innerHTML = `
    <div class="game-wrap">
      <div class="hud-bar"><span>Keyingi: <b id="no-next">1</b></span><span id="no-timer">25.0s</span></div>
      <div class="no-grid" id="no-grid"></div>
    </div>`;
  const grid = container.querySelector('#no-grid');
  const nextEl = container.querySelector('#no-next');
  const timerEl = container.querySelector('#no-timer');
  let next=1, over=false, timeLeft=25, timerInt;
  numbers.forEach(n=>{
    const b = document.createElement('button');
    b.className = 'no-cell'; b.textContent = n;
    b.onclick = () => press(n, b);
    grid.appendChild(b);
  });
  function press(n, btn){
    if(over) return;
    if(n===next){
      btn.classList.add('done'); btn.disabled = true; next++; nextEl.textContent = next;
      if(next>total){ over=true; clearInterval(timerInt); api.finish('win', `(${(25-timeLeft).toFixed(1)}s da tugatding!)`); }
    }
  }
  timerInt = setInterval(()=>{
    timeLeft -= 0.1; timerEl.textContent = Math.max(timeLeft,0).toFixed(1)+'s';
    if(timeLeft<=0 && !over){ over=true; api.finish('lose', `(${next-1}/${total} gacha yetding)`); }
  }, 100);
  function stop(){ clearInterval(timerInt); }
  return { stop };
}

/* ============ GAME 40: ANAGRAM ============ */
function initAnagram(container, api){
  const words = ['MAKTAB','DARAXT','QALAM','SAYYORA','DARYO','QUYOSH','KITOB','OLTIN'];
  const list = [...words].sort(()=>Math.random()-0.5).slice(0,5);
  let idx=0, over=false, timeLeft=60, timerInt;
  function scramble(w){
    let arr = w.split('');
    do{ arr.sort(()=>Math.random()-0.5); } while(arr.join('')===w && w.length>1);
    return arr.join('');
  }
  container.innerHTML = `
    <div class="game-wrap center">
      <div style="display:flex;gap:20px;font-size:14px;color:var(--dim);"><span>So'z: <b id="an-idx" style="color:var(--gold);">1</b>/5</span><span id="an-timer">60.0s</span></div>
      <div id="an-scrambled" style="font-family:'Space Grotesk',sans-serif;font-size:clamp(24px,5vw,36px);font-weight:700;letter-spacing:0.1em;"></div>
      <div class="gn-input-row">
        <input type="text" id="an-input" placeholder="Javob..." style="text-transform:uppercase;">
        <button id="an-btn">Tekshir</button>
      </div>
    </div>`;
  const scrambledEl = container.querySelector('#an-scrambled');
  const idxEl = container.querySelector('#an-idx');
  const timerEl = container.querySelector('#an-timer');
  const input = container.querySelector('#an-input');
  const btn = container.querySelector('#an-btn');
  function showWord(){ scrambledEl.textContent = scramble(list[idx]); input.value=''; input.focus(); }
  function submit(){
    if(over) return;
    if(input.value.toUpperCase().trim()===list[idx]){
      idx++;
      if(idx>=list.length){ over=true; finishGame(true); return; }
      idxEl.textContent = idx+1;
      showWord();
    }
  }
  btn.onclick = submit;
  input.addEventListener('keydown', e=>{ if(e.key==='Enter') submit(); });
  timerInt = setInterval(()=>{ timeLeft-=0.1; timerEl.textContent=Math.max(timeLeft,0).toFixed(1)+'s'; if(timeLeft<=0 && !over){ over=true; finishGame(false); } }, 100);
  function finishGame(won){
    clearInterval(timerInt);
    if(won) api.finish('win', `(Barcha ${list.length} so'zni yechding!)`);
    else api.finish('lose', `(faqat ${idx}/${list.length} so'zni yechding)`);
  }
  showWord();
  function stop(){ clearInterval(timerInt); }
  return { stop };
}

/* ============ Game registry ============ */
const GAMES = [
  { id:'supernova', title:'Supernova', emoji:'💥', desc:"20 soniyada bos-bos yulduz portlat, 350 ochko top", init:initSupernova },
  { id:'tictactoe', title:"X-O O'yini", emoji:'❌⭕', desc:"Kompyuterga qarshi klassik X-O jangi", init:initTicTacToe },
  { id:'memory', title:"Xotira O'yini", emoji:'🧠', desc:"Juftlarni top, lekin yurishlar cheklangan", init:initMemory },
  { id:'reaction', title:'Tezkorlik Testi', emoji:'⚡', desc:"Yashil yonganda bos — refleksingni sina", init:initReaction },
  { id:'rps', title:"Tosh-Qaychi-Qog'oz", emoji:'✂️', desc:"Kompyuterni 3 marta yutib chiq", init:initRPS },
  { id:'snake', title:'Ilon', emoji:'🐍', desc:"Ilonni boshqar, o'ziga urilib qolma", init:initSnake },
  { id:'catch', title:'Yulduz Tutish', emoji:'🌟', desc:"Tushayotgan yulduzlarni savatchada tut", init:initCatch },
  { id:'guess', title:'Raqamni Top', emoji:'🔢', desc:"1-100 orasidan sonni 7 urinishda top", init:initGuess },
  { id:'game2048', title:'2048', emoji:'🧩', desc:"Raqamlarni birlashtirib 2048 ga yet", init:initGame2048 },
  { id:'pong', title:'Ping-Pong', emoji:'🏓', desc:"Kompyuterga qarshi klassik ping-pong", init:initPong },
  { id:'aim', title:'Nishonga Ur', emoji:'🎯', desc:"20 soniyada 10 ta nishonni ur", init:initAim },
  { id:'flappy', title:'Uchuvchi Qush', emoji:'🐦', desc:"Bosib uch, to'siqlardan o'tib ket", init:initFlappy },
  { id:'breakout', title:"G'isht Buzish", emoji:'🧱', desc:"To'p bilan barcha g'ishtlarni buz", init:initBreakout },
  { id:'wordle', title:"So'z Toping", emoji:'🔤', desc:"5 harfli o'zbekcha so'zni 6 urinishda top", init:initWordle },
  { id:'math', title:'Tez Hisoblash', emoji:'🧮', desc:"30 soniyada 8 ta misolni yech", init:initMath },
  { id:'colordiff', title:'Ranglarni Farqla', emoji:'🎨', desc:"Boshqacha rangni tez top, 5 bosqich", init:initColorDiff },
  { id:'blackjack', title:'21 (Blackjack)', emoji:'🃏', desc:"Dilerga qarshi 21 ga yaqinlash", init:initBlackjack },
  { id:'lie', title:"Yolg'on Detektor", emoji:'🤥', desc:"5 ta savolga javob ber, natija kulgili!", init:initLieDetector },
  { id:'wheel', title:"Baxt G'ildiragi", emoji:'🎡', desc:"Aylantir va kulgili taqdiringni bil", init:initWheel },
  { id:'mash', title:'Tugma Urish', emoji:'👊', desc:"5 soniyada 30 marta bos, tezligingni sina", init:initMash },
  { id:'simon', title:'Simon Says', emoji:'🔴', desc:"Rang ketma-ketligini yodlab qayta bos", init:initSimon },
  { id:'maze', title:'Labirint', emoji:'🌀', desc:"30 soniyada chiqish yo'lini top", init:initMaze },
  { id:'balloon', title:'Balon Otish', emoji:'🎈', desc:"15 ta balonni portlat, bombani otma", init:initBalloon },
  { id:'whack', title:'Kalxat Urish', emoji:'🦫', desc:"20 soniyada 12 ta kalxatni ur", init:initWhack },
  { id:'traffic', title:'Yo\'l Harakati', emoji:'🚗', desc:"Mashinalardan qochib 20 soniya omon qol", init:initTraffic },
  { id:'penalty', title:'Penalti', emoji:'⚽', desc:"5 ta zarbadan 3 tasini gol qil", init:initPenalty },
  { id:'meteor', title:"Meteor Yomg'iri", emoji:'☄️', desc:"20 soniya meteorlardan qochib omon qol", init:initMeteor },
  { id:'trivia', title:'Bilimdonlar', emoji:'🧠', desc:"5 ta savoldan 4 tasini to'g'ri top", init:initTrivia },
  { id:'coin', title:'Tanga Tashlash', emoji:'🪙', desc:"5 tadan 3 tasini taxmin qil", init:initCoin },
  { id:'lightsout', title:"Chiroqlarni O'chir", emoji:'💡', desc:"20 yurishda barcha chiroqni o'chir", init:initLightsOut },
  { id:'nummem', title:'Raqamlar Xotirasi', emoji:'🔢', desc:"Raqam ketma-ketligini yodlab yoz", init:initNumberMemory },
  { id:'typing', title:'Tez Terish', emoji:'⌨️', desc:"20 soniyada 5 ta so'zni tez ter", init:initTyping },
  { id:'stack', title:'Minora Qur', emoji:'🏗️', desc:"Bloklarni to'g'ri joylab 10 qavat qur", init:initStack },
  { id:'fishing', title:'Baliq Ovi', emoji:'🎣', desc:"10 ta baliq tut, axlatni tutma", init:initFishing },
  { id:'dino', title:'Dino Yugurish', emoji:'🦖', desc:"To'siqlardan sakrab 300 masofani bos", init:initDino },
  { id:'duckhunt', title:"O'rdak Ovi", emoji:'🦆', desc:"15 o'q bilan 10 ta o'rdakni ur", init:initDuckHunt },
  { id:'slot', title:'Baxt Mashinasi', emoji:'🎰', desc:"3 ta belgi mos kelsa — jekpot!", init:initSlot },
  { id:'stopwatch', title:"Aniq To'xtatish", emoji:'⏱️', desc:"Soatni maqsadli vaqtga yaqin to'xtat", init:initStopwatch },
  { id:'numorder', title:'Raqam Tartibi', emoji:'🔟', desc:"1 dan 20 gacha tartib bilan tez bos", init:initNumberOrder },
  { id:'anagram', title:'Anagram', emoji:'🔠', desc:"Aralashgan harflardan so'zni top", init:initAnagram },
];
</script>
</body>
</html>
