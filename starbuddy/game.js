const canvas = document.getElementById('game');
const ctx = canvas.getContext('2d');
const scoreEl = document.getElementById('score');
const restartBtn = document.getElementById('restart');

const gravity = 0.5;
const scrollSpeed = 3;

const player = {
  x: 80,
  y: canvas.height - 60,
  size: 20,
  vy: 0,
  onGround: false,
  color: '#ff82c2',
  powerTimer: 0
};

let obstacles = [];
let powerUps = [];
let score = 0;
let frames = 0;
let gameOver = false;

function reset() {
  obstacles = [];
  powerUps = [];
  score = 0;
  frames = 0;
  gameOver = false;
  player.x = 80;
  player.y = canvas.height - 60;
  player.vy = 0;
  player.onGround = false;
  player.powerTimer = 0;
  restartBtn.style.display = 'none';
  update();
}

function spawnObstacle() {
  const height = 20 + Math.random() * 50;
  const width = 20 + Math.random() * 40;
  obstacles.push({
    x: canvas.width,
    y: canvas.height - height - 20,
    width,
    height,
    color: '#8e735b'
  });
}

function spawnPowerUp() {
  powerUps.push({
    x: canvas.width,
    y: 100 + Math.random() * 200,
    size: 15,
    color: '#ffd700'
  });
}

function handleInput(e) {
  if (e.code === 'Space') {
    if (player.onGround || player.powerTimer > 0) {
      player.vy = -10;
      player.onGround = false;
    }
    e.preventDefault();
  }
}

function update() {
  if (gameOver) return;
  frames++;

  ctx.clearRect(0, 0, canvas.width, canvas.height);

  // spawn logic
  if (frames % 90 === 0) spawnObstacle();
  if (frames % 150 === 0) spawnPowerUp();

  // update player
  player.vy += gravity;
  player.y += player.vy;
  if (player.y + player.size > canvas.height - 20) {
    player.y = canvas.height - 20 - player.size;
    player.vy = 0;
    player.onGround = true;
  }

  // draw player
  ctx.fillStyle = player.color;
  if (player.powerTimer > 0) {
    ctx.shadowColor = '#ffd700';
    ctx.shadowBlur = 20;
    player.powerTimer--;
  } else {
    ctx.shadowBlur = 0;
  }
  ctx.beginPath();
  ctx.arc(player.x, player.y, player.size, 0, Math.PI * 2);
  ctx.fill();

  // obstacles
  obstacles.forEach((o, i) => {
    o.x -= scrollSpeed;
    ctx.fillStyle = o.color;
    ctx.fillRect(o.x, o.y, o.width, o.height);

    if (collisionRect(player, o)) {
      gameOver = true;
      restartBtn.style.display = 'block';
    }

    if (o.x + o.width < 0) obstacles.splice(i, 1);
  });

  // power-ups
  powerUps.forEach((p, i) => {
    p.x -= scrollSpeed;
    drawStar(p.x, p.y, 5, p.size, p.size / 2, p.color);

    if (collisionCircle(player, p)) {
      score += 50;
      player.powerTimer = 300; // allow mid-air jumps
      powerUps.splice(i, 1);
    }

    if (p.x + p.size < 0) powerUps.splice(i, 1);
  });

  // score & looping
  score++;
  scoreEl.textContent = 'Score: ' + score;
  requestAnimationFrame(update);
}

function collisionRect(c, r) {
  return (
    c.x + c.size > r.x &&
    c.x - c.size < r.x + r.width &&
    c.y + c.size > r.y &&
    c.y - c.size < r.y + r.height
  );
}

function collisionCircle(c1, c2) {
  const dx = c1.x - c2.x;
  const dy = c1.y - c2.y;
  const distance = Math.sqrt(dx * dx + dy * dy);
  return distance < c1.size + c2.size;
}

function drawStar(x, y, points, outer, inner, color) {
  ctx.fillStyle = color;
  ctx.beginPath();
  let angle = Math.PI / points;
  for (let i = 0; i < 2 * points; i++) {
    const radius = i % 2 === 0 ? outer : inner;
    ctx.lineTo(
      x + Math.cos(i * angle) * radius,
      y + Math.sin(i * angle) * radius
    );
  }
  ctx.closePath();
  ctx.fill();
}

document.addEventListener('keydown', handleInput);
restartBtn.addEventListener('click', reset);

reset();
