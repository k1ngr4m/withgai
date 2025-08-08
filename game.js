// 微信小游戏主入口文件 - 与 gai 同行
const eventSystem = require('./js/events.js');
const databus = require('./js/runtime/databus.js');

// 按钮交互状态
let buttonStates = {
  startButton: false, // 开始按钮是否被按下
  restartButton: false // 重新开始按钮是否被按下
};

// 确保事件系统已正确加载
if (!eventSystem || !eventSystem.getEvent) {
  console.error('事件系统加载失败');
}

// 创建Canvas
const canvas = wx.createCanvas();
const ctx = canvas.getContext('2d');

// 角色精灵渲染函数
function renderCharacter() {
  // 绘制像素风格角色头像框
  ctx.strokeStyle = '#000';
  ctx.lineWidth = 2;
  ctx.strokeRect(20, 70, 80, 80);
  
  // 绘制角色头像（使用像素风格图片）
  try {
    const img = wx.createImage();
    img.src = 'images/pixel/gai.png';
    img.onload = () => {
      ctx.drawImage(img, 25, 75, 70, 70);
    };
  } catch (e) {
    // 如果图片加载失败，绘制简单的像素风格头像
    ctx.fillStyle = '#FF6B6B';
    ctx.fillRect(25, 75, 70, 70);
    
    // 绘制简单的眼睛和嘴巴
    ctx.fillStyle = '#000';
    ctx.fillRect(40, 90, 8, 8);
    ctx.fillRect(65, 90, 8, 8);
    ctx.fillRect(45, 115, 25, 5);
  }
  
  // 绘制角色状态条背景
  ctx.fillStyle = '#DDD';
  ctx.fillRect(110, 70, 100, 15);
  ctx.fillRect(110, 95, 100, 15);
  ctx.fillRect(110, 120, 100, 15);
  
  // 绘制角色状态条
  // 心情条
  ctx.fillStyle = '#FF6B6B';
  ctx.fillRect(110, 70, databus.character.mood, 15);
  ctx.strokeStyle = '#000';
  ctx.lineWidth = 1;
  ctx.strokeRect(110, 70, 100, 15);
  ctx.fillStyle = '#000';
  ctx.font = '12px monospace';
  ctx.fillText('心情', 110, 65);
  
  // 精力条
  ctx.fillStyle = '#4ECDC4';
  ctx.fillRect(110, 95, databus.character.energy, 15);
  ctx.strokeStyle = '#000';
  ctx.strokeRect(110, 95, 100, 15);
  ctx.fillStyle = '#000';
  ctx.fillText('精力', 110, 90);
  
  // 金钱条
  ctx.fillStyle = '#FFD166';
  ctx.fillRect(110, 120, Math.min(databus.character.money, 100), 15);
  ctx.strokeStyle = '#000';
  ctx.strokeRect(110, 120, 100, 15);
  ctx.fillStyle = '#000';
  ctx.fillText('金钱', 110, 115);
  
  // 绘制数值
  ctx.fillText(`${databus.character.mood}/100`, 215, 82);
  ctx.fillText(`${databus.character.energy}/100`, 215, 107);
  ctx.fillText(`${databus.character.money}`, 215, 132);
}

// 初始化游戏
function initGame() {
  // 初始化游戏数据
  databus.reset();
  databus.gameState = 'playing';
  databus.triggerInitialEvent = true;
  
  // 开始游戏循环
  gameLoop();
}

// 触发事件
function triggerEvent(eventId) {
  // 确保事件系统已加载
  if (!eventSystem || !eventSystem.getEvent) {
    console.error('事件系统未正确加载');
    return;
  }
  
  // 有一定概率触发随机事件
  if (Math.random() < 0.1 && eventId !== 'morning_start' && eventId !== 'end_game') { // 10%概率触发随机事件
    const randomEvents = ['shit_event', 'found_money'];
    const randomEventId = randomEvents[Math.floor(Math.random() * randomEvents.length)];
    const randomEvent = eventSystem.getEvent(randomEventId);
    if (randomEvent) {
      databus.currentEvent = randomEvent;
      return;
    }
  }
  
  // 根据事件历史记录触发特定事件
  if (eventId === 'lunch_time') {
    // 检查是否之前触发过拉屎事件，如果是则可能触发相关事件
    const shitEvents = databus.eventHistory.filter(event => 
      event.eventId.includes('shit') || event.eventId === 'hold_shit'
    );
    if (shitEvents.length > 0 && Math.random() < 0.3) {
      // 30%概率触发肚子不舒服事件
      const stomachEvent = eventSystem.getEvent('stomach_pain');
      if (stomachEvent) {
        databus.currentEvent = stomachEvent;
        return;
      }
    }
  }
  
  // 根据金钱情况触发事件
  if (eventId === 'going_to_work' && databus.character.money < 20) {
    // 如果金钱不足，可能触发借钱事件
    if (Math.random() < 0.4) {
      const borrowEvent = eventSystem.getEvent('borrow_money');
      if (borrowEvent) {
        databus.currentEvent = borrowEvent;
        return;
      }
    }
  }
  
  // 根据心情值触发事件
  if (eventId === 'start_working' && databus.character.mood > 80) {
    // 心情很好时可能触发心情愉悦事件
    if (Math.random() < 0.3) {
      const moodEvent = eventSystem.getEvent('good_mood_boost');
      if (moodEvent) {
        databus.currentEvent = moodEvent;
        return;
      }
    }
  }
  
  // 根据精力值触发事件
  if (eventId === 'start_working' && databus.character.energy < 30) {
    // 精力不足时可能触发疲惫事件
    if (Math.random() < 0.4) {
      const energyEvent = eventSystem.getEvent('tired_slump');
      if (energyEvent) {
        databus.currentEvent = energyEvent;
        return;
      }
    }
  }
  
  const event = eventSystem.getEvent(eventId);
  if (event) {
    databus.currentEvent = event;
  } else {
    console.error('未找到事件:', eventId);
  }
}

// 游戏主循环
function gameLoop() {
  // 清空画布
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  
  // 根据游戏状态渲染不同内容
  if (databus.gameState === 'start') {
    renderStartScreen();
  } else if (databus.gameState === 'playing') {
    // 触发初始事件
    if (databus.triggerInitialEvent) {
      databus.triggerInitialEvent = false;
      triggerEvent('morning_start');
    }
    renderGameScreen();
  } else if (databus.gameState === 'end') {
    renderEndScreen();
  }
  
  // 继续循环
  requestAnimationFrame(gameLoop);
}

// 渲染开始界面
function renderStartScreen() {
  // 填充背景色
  ctx.fillStyle = '#f0f0f0';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  
  // 绘制像素风格边框
  ctx.strokeStyle = '#000';
  ctx.lineWidth = 2;
  ctx.strokeRect(20, 20, canvas.width - 40, canvas.height - 40);
  
  // 绘制像素风格标题
  ctx.fillStyle = '#000';
  ctx.font = '24px monospace';
  ctx.textAlign = 'center';
  
  // 添加闪烁动画效果
  const blink = Math.floor(Date.now() / 500) % 2;
  
  ctx.fillText('与 gai 同行', canvas.width / 2, canvas.height / 2 - 80);
  
  // 绘制像素风格GAI字符
  drawPixelGai(canvas.width / 2 - 30, canvas.height / 2 - 30, 3);
  
  // 绘制副标题
  ctx.font = '16px monospace';
  ctx.fillText('一个像素风格的冒险游戏', canvas.width / 2, canvas.height / 2 + 20);
  
  // 绘制开始按钮
  const buttonX = canvas.width / 2 - 80;
  const buttonY = canvas.height / 2 + 60;
  const buttonWidth = 160;
  const buttonHeight = 40;
  
  // 按钮背景（根据按钮状态改变颜色）
  if (buttonStates.startButton) {
    ctx.fillStyle = '#3DBDB4'; // 按下时的颜色
  } else {
    ctx.fillStyle = '#4ECDC4'; // 默认颜色
  }
  ctx.fillRect(buttonX, buttonY, buttonWidth, buttonHeight);
  
  // 按钮边框
  ctx.strokeStyle = '#000';
  ctx.lineWidth = 2;
  ctx.strokeRect(buttonX, buttonY, buttonWidth, buttonHeight);
  
  // 按钮文字
  ctx.fillStyle = '#000';
  ctx.font = '16px monospace';
  ctx.fillText('开始游戏', canvas.width / 2, buttonY + 25);
  
  // 绘制闪烁提示文字
  if (blink) {
    ctx.fillStyle = '#FF6B6B';
    ctx.font = '14px monospace';
    ctx.fillText('点击按钮开始', canvas.width / 2, canvas.height - 50);
  }
}

// 绘制像素风格GAI字符
function drawPixelGai(x, y, scale) {
  ctx.fillStyle = '#FF6B6B';
  
  // 绘制简单的像素风格人物头像
  for (let i = 0; i < 5; i++) {
    for (let j = 0; j < 5; j++) {
      // 简单的像素图案
      if ((i === 0 && j >= 1 && j <= 3) || 
          (i === 1 && (j === 0 || j === 4)) ||
          (i === 2 && j === 2) ||
          (i === 3 && (j === 1 || j === 3)) ||
          (i === 4 && (j === 0 || j === 4))) {
        ctx.fillRect(x + j * scale, y + i * scale, scale, scale);
      }
    }
  }
}

// 渲染游戏界面
function renderGameScreen() {
  // 填充背景色
  ctx.fillStyle = '#f8f8f8';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  
  // 绘制顶部状态栏背景
  ctx.fillStyle = '#4ECDC4';
  ctx.fillRect(0, 0, canvas.width, 50);
  
  // 绘制边框
  ctx.strokeStyle = '#000';
  ctx.lineWidth = 2;
  ctx.strokeRect(0, 0, canvas.width, 50);
  
  // 渲染角色状态
  ctx.fillStyle = '#000';
  ctx.font = '16px monospace';
  ctx.textAlign = 'left';
  ctx.fillText(`时间: ${databus.gameTime.hour}:${databus.gameTime.minute < 10 ? '0' + databus.gameTime.minute : databus.gameTime.minute}`, 20, 30);
  
  // 渲染角色精灵和状态条
  renderCharacter();
  
  // 渲染当前事件区域
  if (databus.currentEvent) {
    // 绘制事件区域背景
    ctx.fillStyle = '#FFF';
    ctx.fillRect(15, 160, canvas.width - 30, canvas.height - 220);
    
    // 绘制事件区域边框
    ctx.strokeStyle = '#000';
    ctx.lineWidth = 2;
    ctx.strokeRect(15, 160, canvas.width - 30, canvas.height - 220);
    
    // 绘制事件标题
    ctx.fillStyle = '#000';
    ctx.font = '18px monospace';
    ctx.textAlign = 'center';
    ctx.fillText(databus.currentEvent.title, canvas.width / 2, 190);
    
    // 绘制事件描述
    ctx.font = '14px monospace';
    ctx.textAlign = 'left';
    wrapText(ctx, databus.currentEvent.description, 30, 220, canvas.width - 60, 20);
    
    // 渲染选择按钮
    const startY = canvas.height - 150;
    for (let i = 0; i < databus.currentEvent.choices.length; i++) {
      const choice = databus.currentEvent.choices[i];
      const buttonY = startY + i * 40;
      
      // 绘制按钮背景
      ctx.fillStyle = '#FFD166';
      ctx.fillRect(30, buttonY, canvas.width - 60, 35);
      
      // 绘制按钮边框
      ctx.strokeStyle = '#000';
      ctx.lineWidth = 1;
      ctx.strokeRect(30, buttonY, canvas.width - 60, 35);
      
      // 绘制按钮文字
      ctx.fillStyle = '#000';
      ctx.font = '14px monospace';
      ctx.textAlign = 'center';
      ctx.fillText(`${i + 1}. ${choice.text}`, canvas.width / 2, buttonY + 22);
    }
  }
}

// 文字换行函数
function wrapText(context, text, x, y, maxWidth, lineHeight) {
  const words = text.split('');
  let line = '';
  let currentY = y;
  
  for (let i = 0; i < words.length; i++) {
    const testLine = line + words[i];
    const metrics = context.measureText(testLine);
    const testWidth = metrics.width;
    
    if (testWidth > maxWidth && i > 0) {
      context.fillText(line, x, currentY);
      line = words[i];
      currentY += lineHeight;
    } else {
      line = testLine;
    }
  }
  
  context.fillText(line, x, currentY);
}

// 渲染结束界面
function renderEndScreen() {
  // 填充背景色
  ctx.fillStyle = '#f8f8f8';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  
  // 绘制标题背景
  ctx.fillStyle = '#FF6B6B';
  ctx.fillRect(0, 0, canvas.width, 60);
  ctx.strokeStyle = '#000';
  ctx.lineWidth = 2;
  ctx.strokeRect(0, 0, canvas.width, 60);
  
  ctx.fillStyle = '#000';
  ctx.font = '24px monospace';
  ctx.textAlign = 'center';
  ctx.fillText('一天结束了', canvas.width / 2, 40);
  
  // 显示角色最终状态卡片
  ctx.fillStyle = '#FFF';
  ctx.fillRect(20, 70, canvas.width - 40, 100);
  ctx.strokeStyle = '#000';
  ctx.lineWidth = 2;
  ctx.strokeRect(20, 70, canvas.width - 40, 100);
  
  ctx.fillStyle = '#000';
  ctx.font = '16px monospace';
  ctx.textAlign = 'left';
  ctx.fillText(`最终心情: ${databus.character.mood}/100`, 40, 100);
  ctx.fillText(`最终精力: ${databus.character.energy}/100`, 40, 130);
  ctx.fillText(`剩余金钱: ${databus.character.money}`, 40, 160);
  
  // 绘制状态条
  const barWidth = 150;
  const barHeight = 15;
  
  // 心情条
  ctx.fillStyle = '#DDD';
  ctx.fillRect(180, 90, barWidth, barHeight);
  ctx.fillStyle = '#FF6B6B';
  ctx.fillRect(180, 90, (databus.character.mood / 100) * barWidth, barHeight);
  ctx.strokeStyle = '#000';
  ctx.strokeRect(180, 90, barWidth, barHeight);
  
  // 精力条
  ctx.fillStyle = '#DDD';
  ctx.fillRect(180, 120, barWidth, barHeight);
  ctx.fillStyle = '#4ECDC4';
  ctx.fillRect(180, 120, (databus.character.energy / 100) * barWidth, barHeight);
  ctx.strokeStyle = '#000';
  ctx.strokeRect(180, 120, barWidth, barHeight);
  
  // 金钱条
  ctx.fillStyle = '#DDD';
  ctx.fillRect(180, 150, barWidth, barHeight);
  ctx.fillStyle = '#FFD166';
  ctx.fillRect(180, 150, Math.min((databus.character.money / 200) * barWidth, barWidth), barHeight);
  ctx.strokeStyle = '#000';
  ctx.strokeRect(180, 150, barWidth, barHeight);
  
  // 显示有趣的统计数据
  const startY = 190;
  ctx.textAlign = 'center';
  const moodChange = databus.character.mood - 50;
  const energyChange = databus.character.energy - 100;
  const moneyChange = databus.character.money - 100;
  
  // 根据数值生成有趣的描述
  let moodDesc = '';
  if (databus.character.mood >= 80) moodDesc = '，今天心情超棒！';
  else if (databus.character.mood >= 60) moodDesc = '，心情还不错！';
  else if (databus.character.mood >= 40) moodDesc = '，心情一般般。';
  else moodDesc = '，今天心情有点糟糕。';
  
  let energyDesc = '';
  if (databus.character.energy >= 80) energyDesc = '，精力充沛！';
  else if (databus.character.energy >= 60) energyDesc = '，精力还行。';
  else if (databus.character.energy >= 40) energyDesc = '，有点疲惫。';
  else energyDesc = '，累得不行了！';
  
  let moneyDesc = '';
  if (moneyChange > 50) moneyDesc = '，财运亨通！';
  else if (moneyChange > 0) moneyDesc = '，略有盈余。';
  else if (moneyChange === 0) moneyDesc = '，收支平衡。';
  else moneyDesc = '，有点小亏。';
  
  ctx.font = '14px monospace';
  ctx.fillText(`今日心情${moodChange >= 0 ? '提升' : '下降'}了${Math.abs(moodChange)}点${moodDesc}`, canvas.width / 2, startY);
  ctx.fillText(`今日精力${energyChange >= 0 ? '增加' : '消耗'}了${Math.abs(energyChange)}点${energyDesc}`, canvas.width / 2, startY + 25);
  ctx.fillText(`今日${moneyChange >= 0 ? '赚取' : '花费'}了${Math.abs(moneyChange)}元${moneyDesc}`, canvas.width / 2, startY + 50);
  
  // 显示特殊统计数据
  const shitEvents = databus.eventHistory.filter(event => 
    event.eventId.includes('shit') || event.eventId === 'hold_shit'
  ).length;
  if (shitEvents > 0) {
    ctx.fillText(`今日喷射成功率达${Math.min(100, 99.9 + Math.random() * 0.1).toFixed(1)}%`, canvas.width / 2, startY + 75);
  }
  
  // 显示有趣的总结语句
  ctx.font = '16px monospace';
  let summaryText = '';
  if (databus.character.mood > 70 && databus.character.energy > 70) {
    summaryText = '今天是完美的一天！GAI过得非常开心！';
  } else if (databus.character.mood < 30 || databus.character.energy < 30) {
    summaryText = '今天过得有点糟糕，GAI需要好好休息一下了。';
  } else {
    summaryText = '平平淡淡的一天，GAI继续着自己的生活。';
  }
  ctx.fillText(summaryText, canvas.width / 2, shitEvents > 0 ? startY + 105 : startY + 90);
  
  // 显示重要事件摘要
  const importantEventsStartY = shitEvents > 0 ? startY + 130 : startY + 115;
  const importantEvents = databus.eventHistory.filter(event => 
    event.eventId === 'overtime_work' || 
    event.eventId === 'found_money' || 
    event.eventId === 'shit_on_enemy'
  );
  if (importantEvents.length > 0) {
    ctx.font = '16px monospace';
    ctx.fillText('今日重要事件:', canvas.width / 2, importantEventsStartY);
    ctx.font = '14px monospace';
    for (let i = 0; i < Math.min(importantEvents.length, 2); i++) {
      const event = importantEvents[i];
      ctx.fillText(`${event.eventTitle}: ${event.choice}`, canvas.width / 2, importantEventsStartY + 25 + i * 20);
    }
  }
  
  // 显示解锁的成就
  const achievementsStartY = importantEvents.length > 0 ? 
    importantEventsStartY + 30 + Math.min(importantEvents.length, 2) * 20 : 
    importantEventsStartY;
  
  if (databus.achievements.length > 0) {
    ctx.font = '18px monospace';
    ctx.fillText('解锁成就:', canvas.width / 2, achievementsStartY + 20);
    ctx.font = '14px monospace';
    const startY = achievementsStartY + 50;
    for (let i = 0; i < Math.min(databus.achievements.length, 3); i++) {
      const achievement = databus.achievements[i];
      
      // 绘制成就卡片
      ctx.fillStyle = '#FFF';
      ctx.fillRect(30, startY + i * 60, canvas.width - 60, 50);
      ctx.strokeStyle = '#000';
      ctx.strokeRect(30, startY + i * 60, canvas.width - 60, 50);
      
      // 绘制成就名称和描述
      ctx.fillStyle = '#000';
      ctx.textAlign = 'left';
      ctx.fillText(achievement.name, 50, startY + 25 + i * 60);
      ctx.font = '12px monospace';
      ctx.fillText(achievement.description, 50, startY + 45 + i * 60);
      ctx.font = '14px monospace';
    }
    if (databus.achievements.length > 3) {
      ctx.fillText(`还有${databus.achievements.length - 3}个成就...`, canvas.width / 2, startY + 30 + 3 * 60);
    }
  } else {
    ctx.fillText('今天没有解锁任何成就，再接再厉！', canvas.width / 2, achievementsStartY + 30);
  }
  
  // 重新开始按钮
  const buttonY = canvas.height - 80;
  // 根据按钮状态改变颜色
  if (buttonStates.restartButton) {
    ctx.fillStyle = '#3DBDB4'; // 按下时的颜色
  } else {
    ctx.fillStyle = '#4ECDC4'; // 默认颜色
  }
  ctx.fillRect(canvas.width / 2 - 100, buttonY, 200, 40);
  ctx.strokeStyle = '#000';
  ctx.lineWidth = 2;
  ctx.strokeRect(canvas.width / 2 - 100, buttonY, 200, 40);
  
  ctx.fillStyle = '#000';
  ctx.font = '16px monospace';
  ctx.fillText('重新开始', canvas.width / 2, buttonY + 25);
}

// 处理触摸事件
if (typeof wx !== 'undefined') {
  wx.onTouchStart((res) => {
    const touch = res.touches[0];
    const x = touch.clientX;
    const y = touch.clientY;
    
    if (databus.gameState === 'start') {
      // 检查是否点击了开始按钮
      const buttonX = canvas.width / 2 - 80;
      const buttonY = canvas.height / 2 + 60;
      const buttonWidth = 160;
      const buttonHeight = 40;
      
      if (x >= buttonX && x <= buttonX + buttonWidth && 
          y >= buttonY && y <= buttonY + buttonHeight) {
        buttonStates.startButton = true;
      }
    } else if (databus.gameState === 'end') {
      // 检查是否点击了重新开始按钮
      const buttonX = canvas.width / 2 - 100;
      const buttonY = canvas.height - 80;
      const buttonWidth = 200;
      const buttonHeight = 40;
      
      if (x >= buttonX && x <= buttonX + buttonWidth && 
          y >= buttonY && y <= buttonY + buttonHeight) {
        buttonStates.restartButton = true;
      }
    } else if (databus.gameState === 'playing' && databus.currentEvent) {
      // 处理选择按钮点击
      const startY = canvas.height - 150;
      for (let i = 0; i < databus.currentEvent.choices.length; i++) {
        const buttonY = startY + i * 40;
        if (x >= 30 && x <= canvas.width - 30 && 
            y >= buttonY && y <= buttonY + 35) {
          handleChoice(i);
          break;
        }
      }
    }
  });
  
  wx.onTouchEnd((res) => {
    if (databus.gameState === 'start' && buttonStates.startButton) {
      // 开始游戏
      buttonStates.startButton = false;
      initGame();
    } else if (databus.gameState === 'end' && buttonStates.restartButton) {
      // 重新开始游戏
      buttonStates.restartButton = false;
      databus.reset();
      databus.gameState = 'start';
    } else {
      buttonStates.startButton = false;
      buttonStates.restartButton = false;
    }
  });
}

// 处理选择
function handleChoice(choiceIndex) {
  const choice = databus.currentEvent.choices[choiceIndex];
  console.log('选择了:', choice);
  
  // 添加到事件历史
  databus.eventHistory.push({
    eventId: databus.currentEvent.id,
    eventTitle: databus.currentEvent.title,
    choice: choice.text,
    effects: choice.effects || {},
    timestamp: new Date().getTime()
  });
  
  // 应用选择的效果到角色属性
  if (choice.effects) {
    databus.updateCharacter(choice.effects);
  }
  
  // 根据选择执行相应动作
  if (choice.action === 'trigger_event' && choice.eventId) {
    // 触发下一个事件
    triggerEvent(choice.eventId);
  } else if (choice.action === 'end_game') {
    // 结束游戏
    databus.gameState = 'end';
    calculateAchievements(); // 计算成就
  }
}

// 计算成就
function calculateAchievements() {
  const newAchievements = databus.checkAndUnlockAchievements();
  console.log('解锁成就:', newAchievements);
}

// 确保在微信环境中运行
if (typeof wx !== 'undefined') {
  // 启动游戏循环，初始状态为start
  databus.gameState = 'start';
  gameLoop();
} else {
  console.error('未在微信环境中运行');
}