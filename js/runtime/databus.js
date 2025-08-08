// 游戏数据管理器
class DataBus {
  constructor() {
    this.reset();
  }

  reset() {
    // 游戏状态
    this.gameState = 'start'; // start, playing, end
    
    // 角色属性
    this.character = {
      name: 'gai',
      mood: 50, // 心情值 0-100
      energy: 100, // 精力值 0-100
      money: 100 // 金钱 0-999
    };
    
    // 当前事件
    this.currentEvent = null;
    
    // 事件历史
    this.eventHistory = [];
    
    // 成就列表
    this.achievements = [];
    
    // 可获得的成就
    this.availableAchievements = this.initAchievements();
    
    // 游戏时间
    this.gameTime = {
      hour: 8,
      minute: 0
    };
    
    // 触发初始事件
    this.triggerInitialEvent = true;
  }

  // 初始化成就系统
  initAchievements() {
    return [
      {
        id: 'steel_intestine',
        name: '钢铁直肠',
        description: '连续憋了3次屎',
        condition: (eventHistory) => {
          let count = 0;
          for (let i = eventHistory.length - 1; i >= 0 && i >= eventHistory.length - 10; i--) {
            if (eventHistory[i].eventId === 'hold_shit') {
              count++;
            }
          }
          return count >= 3;
        }
      },
      {
        id: 'shopaholic',
        name: '购物狂',
        description: '一天花费超过100元',
        condition: (eventHistory) => {
          let totalSpent = 0;
          for (const event of eventHistory) {
            if (event.effects && event.effects.money && event.effects.money < 0) {
              totalSpent += Math.abs(event.effects.money);
            }
          }
          return totalSpent > 100;
        }
      },
      {
        id: 'workaholic',
        name: '工作狂',
        description: '加班到很晚',
        condition: (eventHistory) => {
          return eventHistory.some(event => event.eventId === 'overtime_work');
        }
      },
      {
        id: 'health_conscious',
        name: '健康达人',
        description: '自带便当且午休小憩',
        condition: (eventHistory) => {
          return eventHistory.some(event => event.eventId === 'home_made_lunch') && 
                 eventHistory.some(event => event.eventId === 'nap_break');
        }
      },
      {
        id: 'money_grabber',
        name: '赚钱能手',
        description: '通过加班赚取20元以上',
        condition: (eventHistory) => {
          return eventHistory.some(event => 
            event.eventId === 'overtime_work' && 
            event.effects && 
            event.effects.money >= 20
          );
        }
      },
      {
        id: 'honest_person',
        name: '诚实的人',
        description: '拾金不昧上交现金',
        condition: (eventHistory) => {
          return eventHistory.some(event => event.eventId === 'give_to_police');
        }
      },
      {
        id: 'kind_hearted',
        name: '善良的心',
        description: '主动寻找失主归还现金',
        condition: (eventHistory) => {
          return eventHistory.some(event => event.eventId === 'find_owner');
        }
      },
      {
        id: 'naughty_kid',
        name: '调皮鬼',
        description: '在同事座位上恶作剧',
        condition: (eventHistory) => {
          return eventHistory.some(event => event.eventId === 'shit_on_enemy');
        }
      },
      {
        id: 'lucky_day',
        name: '幸运日',
        description: '一天内金钱增加超过50元',
        condition: (eventHistory) => {
          let totalGained = 0;
          for (const event of eventHistory) {
            if (event.effects && event.effects.money && event.effects.money > 0) {
              totalGained += event.effects.money;
            }
          }
          return totalGained > 50;
        }
      },
      {
        id: 'mood_master',
        name: '情绪大师',
        description: '一天结束时心情值超过80',
        condition: (eventHistory) => {
          // 这个成就需要在游戏结束时检查
          return false; // 在游戏结束时单独检查
        }
      },
      {
        id: 'energy_master',
        name: '精力充沛',
        description: '一天结束时精力值超过80',
        condition: (eventHistory) => {
          // 这个成就需要在游戏结束时检查
          return false; // 在游戏结束时单独检查
        }
      },
      {
        id: 'frugal_living',
        name: '节俭生活',
        description: '一天结束时金钱不少于初始值',
        condition: (eventHistory) => {
          // 这个成就需要在游戏结束时检查
          return false; // 在游戏结束时单独检查
        }
      },
      {
        id: 'adventure_seeker',
        name: '冒险家',
        description: '触发了所有随机事件',
        condition: (eventHistory) => {
          const randomEvents = ['shit_event', 'found_money'];
          const triggeredEvents = new Set();
          for (const event of eventHistory) {
            if (randomEvents.includes(event.eventId)) {
              triggeredEvents.add(event.eventId);
            }
          }
          return triggeredEvents.size === randomEvents.length;
        }
      },
      {
        id: 'decision_maker',
        name: '决策大师',
        description: '一天内做出了10个重要决策',
        condition: (eventHistory) => {
          return eventHistory.length >= 10;
        }
      }
    ];
  }

  // 更新角色属性
  updateCharacter(stats) {
    if (stats.mood !== undefined) {
      this.character.mood = Math.min(100, Math.max(0, this.character.mood + stats.mood));
    }
    
    if (stats.energy !== undefined) {
      this.character.energy = Math.min(100, Math.max(0, this.character.energy + stats.energy));
    }
    
    if (stats.money !== undefined) {
      this.character.money = Math.max(0, this.character.money + stats.money);
    }
  }

  // 检查并解锁成就
  checkAndUnlockAchievements() {
    const newAchievements = [];
    for (const achievement of this.availableAchievements) {
      // 检查是否已经解锁过该成就
      if (!this.achievements.some(a => a.id === achievement.id)) {
        // 特殊处理需要在游戏结束时检查的成就
        if (achievement.id === 'mood_master') {
          if (this.character.mood > 80) {
            newAchievements.push({
              id: achievement.id,
              name: achievement.name,
              description: achievement.description
            });
          }
        } else if (achievement.id === 'energy_master') {
          if (this.character.energy > 80) {
            newAchievements.push({
              id: achievement.id,
              name: achievement.name,
              description: achievement.description
            });
          }
        } else if (achievement.id === 'frugal_living') {
          if (this.character.money >= 100) {
            newAchievements.push({
              id: achievement.id,
              name: achievement.name,
              description: achievement.description
            });
          }
        } else if (achievement.condition(this.eventHistory)) {
          newAchievements.push({
            id: achievement.id,
            name: achievement.name,
            description: achievement.description
          });
        }
      }
    }
    
    // 添加新解锁的成就
    this.achievements.push(...newAchievements);
    return newAchievements;
  }
}

module.exports = new DataBus();