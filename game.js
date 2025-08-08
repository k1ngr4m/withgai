// 微信小游戏主入口文件 - 与 gai 同行
const eventSystem = require('./js/events.js');
const databus = require('./js/runtime/databus.js');

// 确保事件系统已正确加载
if (!eventSystem || !eventSystem.getEvent) {
  console.error('事件系统加载失败');
}

// 创建Canvas
const canvas = wx.createCanvas();
const ctx = canvas.getContext('2d');

// 角色精灵渲染函数
function renderCharacter() {
  // 绘制角色头像（使用像素风格图片）
  const img = wx.createImage();
  img.src = 'images/pixel/gai.png';
  img.onload = () => {
    ctx.drawImage(img, 20, 120, 80, 80);
  };
  
  // 绘制角色状态条
  // 心情条
  ctx.fillStyle = '#FF6B6B';
  ctx.fillRect(110, 120, databus.character.mood, 10);
  ctx.fillStyle = '#000';
  ctx.font = '12px Arial';
  ctx.fillText('心情', 110, 115);
  
  // 精力条
  ctx.fillStyle = '#4ECDC4';
  ctx.fillRect(110, 140, databus.character.energy, 10);
  ctx.fillStyle = '#000';
  ctx.fillText('精力', 110, 135);
  
  // 金钱条
  ctx.fillStyle = '#FFD166';
  ctx.fillRect(110, 160, Math.min(databus.character.money, 100), 10);
  ctx.fillStyle = '#000';
  ctx.fillText('金钱', 110, 155);
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
  
  ctx.fillStyle = '#000';
  ctx.font = '20px Arial';
  ctx.textAlign = 'center';
  ctx.fillText('与 gai 同行', canvas.width / 2, canvas.height / 2 - 50);
  ctx.fillText('点击屏幕开始游戏', canvas.width / 2, canvas.height / 2 + 50);
}

// 渲染游戏界面
function renderGameScreen() {
  // 填充背景色
  ctx.fillStyle = '#f0f0f0';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  
  // 渲染角色状态
  ctx.fillStyle = '#000';
  ctx.font = '16px Arial';
  ctx.textAlign = 'left';
  ctx.fillText(`时间: ${databus.gameTime.hour}:${databus.gameTime.minute < 10 ? '0' + databus.gameTime.minute : databus.gameTime.minute}`, 20, 30);
  
  // 渲染角色精灵和状态条
  renderCharacter();
  
  // 渲染当前事件
  if (databus.currentEvent) {
    ctx.fillText(databus.currentEvent.title, 20, 220);
    ctx.fillText(databus.currentEvent.description, 20, 240);
    
    // 渲染选择按钮
    for (let i = 0; i < databus.currentEvent.choices.length; i++) {
      const choice = databus.currentEvent.choices[i];
      ctx.fillText(`${i + 1}. ${choice.text}`, 20, 270 + i * 30);
    }
  }
}

// 渲染结束界面
function renderEndScreen() {
  // 填充背景色
  ctx.fillStyle = '#f0f0f0';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  
  ctx.fillStyle = '#000';
  ctx.font = '20px Arial';
  ctx.textAlign = 'center';
  ctx.fillText('一天结束了', canvas.width / 2, 30);
  
  // 显示角色最终状态
  ctx.font = '16px Arial';
  ctx.textAlign = 'left';
  ctx.fillText(`最终心情: ${databus.character.mood}/100`, 20, 70);
  ctx.fillText(`最终精力: ${databus.character.energy}/100`, 20, 100);
  ctx.fillText(`剩余金钱: ${databus.character.money}`, 20, 130);
  
  // 显示有趣的统计数据
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
  
  ctx.fillText(`今日心情${moodChange >= 0 ? '提升' : '下降'}了${Math.abs(moodChange)}点${moodDesc}`, canvas.width / 2, 170);
  ctx.fillText(`今日精力${energyChange >= 0 ? '增加' : '消耗'}了${Math.abs(energyChange)}点${energyDesc}`, canvas.width / 2, 200);
  ctx.fillText(`今日${moneyChange >= 0 ? '赚取' : '花费'}了${Math.abs(moneyChange)}元${moneyDesc}`, canvas.width / 2, 230);
  
  // 显示特殊统计数据
  ctx.font = '14px Arial';
  const shitEvents = databus.eventHistory.filter(event => 
    event.eventId.includes('shit') || event.eventId === 'hold_shit'
  ).length;
  if (shitEvents > 0) {
    ctx.fillText(`今日喷射成功率达${Math.min(100, 99.9 + Math.random() * 0.1).toFixed(1)}%`, canvas.width / 2, 250);
  }
  
  // 显示有趣的总结语句
  ctx.font = '16px Arial';
  let summaryText = '';
  if (databus.character.mood > 70 && databus.character.energy > 70) {
    summaryText = '今天是完美的一天！GAI过得非常开心！';
  } else if (databus.character.mood < 30 || databus.character.energy < 30) {
    summaryText = '今天过得有点糟糕，GAI需要好好休息一下了。';
  } else {
    summaryText = '平平淡淡的一天，GAI继续着自己的生活。';
  }
  ctx.fillText(summaryText, canvas.width / 2, shitEvents > 0 ? 270 : 260);
  
  // 显示重要事件摘要
  ctx.font = '14px Arial';
  const importantEvents = databus.eventHistory.filter(event => 
    event.eventId === 'overtime_work' || 
    event.eventId === 'found_money' || 
    event.eventId === 'shit_on_enemy'
  );
  if (importantEvents.length > 0) {
    ctx.fillText('今日重要事件:', canvas.width / 2, shitEvents > 0 ? 290 : 280);
    for (let i = 0; i < Math.min(importantEvents.length, 2); i++) {
      const event = importantEvents[i];
      ctx.fillText(`${event.eventTitle}: ${event.choice}`, canvas.width / 2, (shitEvents > 0 ? 310 : 300) + i * 20);
    }
  }
  
  // 显示解锁的成就
  if (databus.achievements.length > 0) {
    ctx.font = '18px Arial';
    ctx.fillText('解锁成就:', canvas.width / 2, importantEvents.length > 0 ? 
      (shitEvents > 0 ? 330 : 320) + Math.min(importantEvents.length, 2) * 20 : 
      (shitEvents > 0 ? 290 : 280));
    ctx.font = '14px Arial';
    const startY = importantEvents.length > 0 ? 
      (shitEvents > 0 ? 360 : 350) + Math.min(importantEvents.length, 2) * 20 : 
      (shitEvents > 0 ? 320 : 310);
    for (let i = 0; i < Math.min(databus.achievements.length, 3); i++) {
      const achievement = databus.achievements[i];
      ctx.fillText(`${achievement.name}: ${achievement.description}`, canvas.width / 2, startY + i * 25);
    }
    if (databus.achievements.length > 3) {
      ctx.fillText(`还有${databus.achievements.length - 3}个成就...`, canvas.width / 2, startY + 3 * 25);
    }
  } else {
    ctx.fillText('今天没有解锁任何成就，再接再厉！', canvas.width / 2, importantEvents.length > 0 ? 
      (shitEvents > 0 ? 330 : 320) + Math.min(importantEvents.length, 2) * 20 : 
      (shitEvents > 0 ? 290 : 280));
  }
  
  // 重新开始提示
  ctx.font = '16px Arial';
  ctx.fillText('点击屏幕重新开始', canvas.width / 2, canvas.height - 30);
}

// 处理触摸事件
if (typeof wx !== 'undefined') {
  wx.onTouchStart((res) => {
    if (databus.gameState === 'start') {
      // 开始游戏
      initGame();
    } else if (databus.gameState === 'end') {
      // 重新开始游戏
      databus.reset();
      databus.gameState = 'start';
    } else if (databus.gameState === 'playing' && databus.currentEvent) {
      // 处理选择（简化处理，实际应该根据点击位置判断选择）
      if (databus.currentEvent.choices.length > 0) {
        handleChoice(0); // 默认选择第一个选项
      }
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
  // 启动游戏
  initGame();
} else {
  console.error('未在微信环境中运行');
}