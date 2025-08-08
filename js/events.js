// 事件系统配置文件
class EventSystem {
  constructor() {
    this.events = this.initEvents();
  }

  // 初始化所有事件
  initEvents() {
    return {
      // 第一幕：起床床
      'morning_start': {
        id: 'morning_start',
        title: '起床床',
        description: '[我叫GAI，是个上虞来的小甜心，每天只睡3小时嘻嘻...]',
        choices: [
          { 
            text: '赖床5分钟', 
            action: 'trigger_event',
            eventId: 'lazy_morning',
            effects: { mood: 5, energy: -5 }
          },
          { 
            text: '立刻起床', 
            action: 'trigger_event',
            eventId: 'active_morning',
            effects: { mood: -5, energy: 5 }
          }
        ]
      },
      
      'lazy_morning': {
        id: 'lazy_morning',
        title: '懒床的早晨',
        description: '多睡一会儿感觉真不错，不过时间好像有点来不及了...',
        choices: [
          { 
            text: '快速洗漱', 
            action: 'trigger_event',
            eventId: 'rushed_morning',
            effects: { mood: -10, energy: -10 }
          },
          { 
            text: '慢慢准备', 
            action: 'trigger_event',
            eventId: 'late_morning',
            effects: { mood: 5, energy: -5 }
          }
        ]
      },
      
      'active_morning': {
        id: 'active_morning',
        title: '活力早晨',
        description: '早起的鸟儿有虫吃！gai精神饱满地开始了一天。',
        choices: [
          { 
            text: '做早餐', 
            action: 'trigger_event',
            eventId: 'cooking_breakfast',
            effects: { mood: 10, energy: -5, money: -5 }
          },
          { 
            text: '随便吃点', 
            action: 'trigger_event',
            eventId: 'quick_breakfast',
            effects: { mood: -5, energy: 5, money: -10 }
          }
        ]
      },
      
      // 早餐事件
      'cooking_breakfast': {
        id: 'cooking_breakfast',
        title: '自制早餐',
        description: '自己做的早餐既健康又省钱，还能享受制作的乐趣。',
        choices: [
          { 
            text: '出门上班', 
            action: 'trigger_event',
            eventId: 'going_to_work',
            effects: { mood: 5, energy: 0 }
          }
        ]
      },
      
      'quick_breakfast': {
        id: 'quick_breakfast',
        title: '简便早餐',
        description: '买了个包子和豆浆，简单解决早餐问题。',
        choices: [
          { 
            text: '出门上班', 
            action: 'trigger_event',
            eventId: 'going_to_work',
            effects: { mood: 0, energy: 0 }
          }
        ]
      },
      
      // 上班路上事件
      'going_to_work': {
        id: 'going_to_work',
        title: '上班班',
        description: '[走在熟悉的上班路上，gai思考着今天的工作安排，每天996真开心嘻嘻...]',
        choices: [
          { 
            text: '走快捷路线', 
            action: 'trigger_event',
            eventId: 'shortcut_route',
            effects: { mood: 0, energy: -5 }
          },
          { 
            text: '走风景路线', 
            action: 'trigger_event',
            eventId: 'scenic_route',
            effects: { mood: 10, energy: -10 }
          }
        ]
      },
      
      'shortcut_route': {
        id: 'shortcut_route',
        title: '快捷路线',
        description: '选择了最短的路线，很快就到了公司。',
        choices: [
          { 
            text: '开始工作', 
            action: 'trigger_event',
            eventId: 'start_working',
            effects: { mood: 0, energy: 0 }
          }
        ]
      },
      
      'scenic_route': {
        id: 'scenic_route',
        title: '风景路线',
        description: '绕路走了一圈，欣赏了美丽的街景，心情愉悦。',
        choices: [
          { 
            text: '开始工作', 
            action: 'trigger_event',
            eventId: 'start_working',
            effects: { mood: 10, energy: -5 }
          }
        ]
      },
      
      // 工作事件
      'start_working': {
        id: 'start_working',
        title: '开始工作',
        description: '到达公司，准备开始一天的工作。今天有很多任务要完成。',
        choices: [
          { 
            text: '先处理紧急任务', 
            action: 'trigger_event',
            eventId: 'urgent_task',
            effects: { mood: -5, energy: -10 }
          },
          { 
            text: '先整理工作计划', 
            action: 'trigger_event',
            eventId: 'plan_day',
            effects: { mood: 5, energy: -5 }
          }
        ]
      },
      
      'urgent_task': {
        id: 'urgent_task',
        title: '紧急任务',
        description: '有一个紧急项目需要马上处理，这将占用你很多时间。',
        choices: [
          { 
            text: '加班完成', 
            action: 'trigger_event',
            eventId: 'overtime_work',
            effects: { mood: -15, energy: -20, money: 20 }
          },
          { 
            text: '请求帮助', 
            action: 'trigger_event',
            eventId: 'ask_for_help',
            effects: { mood: 5, energy: -5 }
          }
        ]
      },
      
      'plan_day': {
        id: 'plan_day',
        title: '制定计划',
        description: '制定了详细的工作计划，这样可以更高效地完成任务。',
        choices: [
          { 
            text: '按计划执行', 
            action: 'trigger_event',
            eventId: 'follow_plan',
            effects: { mood: 10, energy: -5 }
          }
        ]
      },
      
      'follow_plan': {
        id: 'follow_plan',
        title: '执行计划',
        description: '按照计划一步步执行，工作进展顺利。',
        choices: [
          { 
            text: '午餐时间到了', 
            action: 'trigger_event',
            eventId: 'lunch_time',
            effects: { mood: 5, energy: 0 }
          }
        ]
      },
      
      'overtime_work': {
        id: 'overtime_work',
        title: '加班工作',
        description: '为了完成紧急任务，gai决定加班到很晚。',
        choices: [
          { 
            text: '终于完成了', 
            action: 'trigger_event',
            eventId: 'work_finished',
            effects: { mood: 10, energy: -30 }
          }
        ]
      },
      
      'ask_for_help': {
        id: 'ask_for_help',
        title: '寻求帮助',
        description: '向同事寻求帮助，大家一起完成了任务。',
        choices: [
          { 
            text: '任务完成', 
            action: 'trigger_event',
            eventId: 'work_finished',
            effects: { mood: 15, energy: -5 }
          }
        ]
      },
      
      'work_finished': {
        id: 'work_finished',
        title: '工作完成',
        description: '经过努力，工作任务终于完成了。',
        choices: [
          { 
            text: '午餐时间到了', 
            action: 'trigger_event',
            eventId: 'lunch_time',
            effects: { mood: 10, energy: -5 }
          }
        ]
      },
      
      // 午休事件
      'lunch_time': {
        id: 'lunch_time',
        title: '吃饭饭',
        description: '[工作了一上午，到了午餐时间，GAI决定犒劳一下自己嘻嘻...]',
        choices: [
          { 
            text: '去餐厅吃饭', 
            action: 'trigger_event',
            eventId: 'restaurant_lunch',
            effects: { mood: 10, energy: 10, money: -15 }
          },
          { 
            text: '叫外卖', 
            action: 'trigger_event',
            eventId: 'delivery_lunch',
            effects: { mood: 5, energy: 5, money: -20 }
          },
          { 
            text: '自带便当', 
            action: 'trigger_event',
            eventId: 'home_made_lunch',
            effects: { mood: 0, energy: 10, money: -5 }
          }
        ]
      },
      
      'restaurant_lunch': {
        id: 'restaurant_lunch',
        title: '餐厅用餐',
        description: '去了喜欢的餐厅，享受了一顿美味的午餐。',
        choices: [
          { 
            text: '下午继续工作', 
            action: 'trigger_event',
            eventId: 'afternoon_work',
            effects: { mood: 5, energy: 5 }
          }
        ]
      },
      
      'delivery_lunch': {
        id: 'delivery_lunch',
        title: '外卖午餐',
        description: '叫了外卖，在办公室里享受午餐时光。',
        choices: [
          { 
            text: '下午继续工作', 
            action: 'trigger_event',
            eventId: 'afternoon_work',
            effects: { mood: 0, energy: 5 }
          }
        ]
      },
      
      'home_made_lunch': {
        id: 'home_made_lunch',
        title: '自制便当',
        description: '吃了自己做的便当，虽然简单但很满足。',
        choices: [
          { 
            text: '下午继续工作', 
            action: 'trigger_event',
            eventId: 'afternoon_work',
            effects: { mood: -5, energy: 5 }
          }
        ]
      },
      
      // 下午工作
      'afternoon_work': {
        id: 'afternoon_work',
        title: '下午工作',
        description: '下午的工作开始了，gai感到有些疲惫。',
        choices: [
          { 
            text: '喝杯咖啡提神', 
            action: 'trigger_event',
            eventId: 'coffee_break',
            effects: { mood: 5, energy: 10, money: -10 }
          },
          { 
            text: '小憩一下', 
            action: 'trigger_event',
            eventId: 'nap_break',
            effects: { mood: 10, energy: 15 }
          }
        ]
      },
      
      'coffee_break': {
        id: 'coffee_break',
        title: '咖啡时间',
        description: '一杯香浓的咖啡让gai重新充满了活力。',
        choices: [
          { 
            text: '继续工作', 
            action: 'trigger_event',
            eventId: 'continue_work',
            effects: { mood: 5, energy: 10 }
          }
        ]
      },
      
      'nap_break': {
        id: 'nap_break',
        title: '午休小憩',
        description: '趴在桌子上小憩了一会儿，感觉精神好多了。',
        choices: [
          { 
            text: '继续工作', 
            action: 'trigger_event',
            eventId: 'continue_work',
            effects: { mood: 10, energy: 20 }
          }
        ]
      },
      
      'continue_work': {
        id: 'continue_work',
        title: '继续工作',
        description: '休息过后，gai继续投入到工作中。',
        choices: [
          { 
            text: '下班时间到了', 
            action: 'trigger_event',
            eventId: 'end_of_work',
            effects: { mood: 5, energy: -10 }
          }
        ]
      },
      
      // 下班事件
      'end_of_work': {
        id: 'end_of_work',
        title: '下班班',
        description: '[终于下班了，GAI拖着疲惫的身体走出公司，今天真是累死宝宝了嘻嘻...]',
        choices: [
          { 
            text: '直接回家', 
            action: 'trigger_event',
            eventId: 'go_home_directly',
            effects: { mood: 0, energy: -5 }
          },
          { 
            text: '逛街放松', 
            action: 'trigger_event',
            eventId: 'shopping_relax',
            effects: { mood: 15, energy: -10, money: -30 }
          }
        ]
      },
      
      'go_home_directly': {
        id: 'go_home_directly',
        title: '直接回家',
        description: '没有停留，直接回家休息。',
        choices: [
          { 
            text: '到家了', 
            action: 'trigger_event',
            eventId: 'arrive_home',
            effects: { mood: -5, energy: -5 }
          }
        ]
      },
      
      'shopping_relax': {
        id: 'shopping_relax',
        title: '逛街放松',
        description: '去商场逛了逛，买了一些喜欢的东西，心情变好了。',
        choices: [
          { 
            text: '回家休息', 
            action: 'trigger_event',
            eventId: 'arrive_home',
            effects: { mood: 20, energy: -15, money: -30 }
          }
        ]
      },
      
      // 回家事件
      'arrive_home': {
        id: 'arrive_home',
        title: '到家了',
        description: '终于回到了家，gai感到既疲惫又放松。',
        choices: [
          { 
            text: '洗个热水澡', 
            action: 'trigger_event',
            eventId: 'take_shower',
            effects: { mood: 15, energy: 10 }
          },
          { 
            text: '直接休息', 
            action: 'trigger_event',
            eventId: 'rest_directly',
            effects: { mood: 0, energy: 5 }
          }
        ]
      },
      
      'take_shower': {
        id: 'take_shower',
        title: '洗热水澡',
        description: '洗了一个舒服的热水澡，洗去了疲惫。',
        choices: [
          { 
            text: '准备睡觉', 
            action: 'trigger_event',
            eventId: 'prepare_sleep',
            effects: { mood: 10, energy: 5 }
          }
        ]
      },
      
      'rest_directly': {
        id: 'rest_directly',
        title: '直接休息',
        description: '太累了，直接躺在床上休息。',
        choices: [
          { 
            text: '准备睡觉', 
            action: 'trigger_event',
            eventId: 'prepare_sleep',
            effects: { mood: 5, energy: 10 }
          }
        ]
      },
      
      // 睡觉事件
      'prepare_sleep': {
        id: 'prepare_sleep',
        title: '睡觉觉',
        description: '[忙碌了一天，GAI躺在床上，回想今天的经历，明天又会是新的一天嘻嘻...]',
        choices: [
          { 
            text: '关灯睡觉', 
            action: 'end_game',
            eventId: 'end_game',
            effects: { mood: 10, energy: 0 }
          }
        ]
      },
      
      // 拉屎事件（原型参考）
      'shit_event': {
        id: 'shit_event',
        title: '拉屎事件',
        description: '肚肚突然痛了',
        choices: [
          { 
            text: '控制屎的干湿度憋回去', 
            action: 'trigger_event',
            eventId: 'hold_shit',
            effects: { mood: -10, energy: -15 }
          },
          { 
            text: '拉在最讨厌的同事座位', 
            action: 'trigger_event',
            eventId: 'shit_on_enemy',
            effects: { mood: 20, energy: -10 }
          },
          { 
            text: '快速跑去厕所喷射', 
            action: 'trigger_event',
            eventId: 'shit_in_toilet',
            effects: { mood: 5, energy: -5 }
          }
        ]
      },
      
      'hold_shit': {
        id: 'hold_shit',
        title: '憋回去',
        description: '忍住了强烈的便意，但肚子还是有些不舒服。',
        choices: [
          { 
            text: '继续原来的事情', 
            action: 'trigger_event',
            eventId: 'continue_previous',
            effects: { mood: -15, energy: -10 }
          }
        ]
      },
      
      'shit_on_enemy': {
        id: 'shit_on_enemy',
        title: '恶作剧',
        description: '偷偷在讨厌的同事座位上解决了问题，心里有点爽。',
        choices: [
          { 
            text: '赶紧离开现场', 
            action: 'trigger_event',
            eventId: 'leave_scene',
            effects: { mood: 25, energy: -5 }
          }
        ]
      },
      
      'shit_in_toilet': {
        id: 'shit_in_toilet',
        title: '正常解决',
        description: '及时跑到厕所解决了问题，感觉轻松多了。',
        choices: [
          { 
            text: '洗手离开', 
            action: 'trigger_event',
            eventId: 'wash_hands',
            effects: { mood: 10, energy: -5 }
          }
        ]
      },
      
      'continue_previous': {
        id: 'continue_previous',
        title: '继续做事',
        description: '虽然肚子还有点不舒服，但还是要继续工作。',
        choices: [
          { 
            text: '专注工作', 
            action: 'trigger_event',
            eventId: 'focus_work',
            effects: { mood: -5, energy: -10 }
          }
        ]
      },
      
      'leave_scene': {
        id: 'leave_scene',
        title: '离开现场',
        description: '做了坏事之后赶紧离开，避免被发现。',
        choices: [
          { 
            text: '回到工位', 
            action: 'trigger_event',
            eventId: 'back_to_desk',
            effects: { mood: 15, energy: -5 }
          }
        ]
      },
      
      'wash_hands': {
        id: 'wash_hands',
        title: '洗手',
        description: '认真洗了洗手，保持个人卫生。',
        choices: [
          { 
            text: '回到工位', 
            action: 'trigger_event',
            eventId: 'back_to_desk',
            effects: { mood: 5, energy: -5 }
          }
        ]
      },
      
      'focus_work': {
        id: 'focus_work',
        title: '专注工作',
        description: '尽管身体不适，但还是努力专注于工作。',
        choices: [
          { 
            text: '午餐时间到了', 
            action: 'trigger_event',
            eventId: 'lunch_time',
            effects: { mood: 0, energy: -10 }
          }
        ]
      },
      
      'back_to_desk': {
        id: 'back_to_desk',
        title: '回到工位',
        description: '回到了自己的工位，准备继续工作。',
        choices: [
          { 
            text: '午餐时间到了', 
            action: 'trigger_event',
            eventId: 'lunch_time',
            effects: { mood: 5, energy: -5 }
          }
        ]
      },
      
      // 添加更多有趣的事件
      'found_money': {
        id: 'found_money',
        title: '意外之财',
        description: '在路上发现了一张100元钞票！',
        choices: [
          { 
            text: '交给警察叔叔', 
            action: 'trigger_event',
            eventId: 'give_to_police',
            effects: { mood: 20, money: 0 } // 精神奖励但没有金钱奖励
          },
          { 
            text: '自己收下', 
            action: 'trigger_event',
            eventId: 'keep_money',
            effects: { mood: -10, money: 100 } // 有金钱但良心不安
          },
          { 
            text: '寻找失主', 
            action: 'trigger_event',
            eventId: 'find_owner',
            effects: { mood: 30, money: 50 } // 找到失主可能会有感谢费
          }
        ]
      },
      
      'give_to_police': {
        id: 'give_to_police',
        title: '上交警察',
        description: '把钱交给了警察叔叔，虽然没得到奖励但心里很踏实。',
        choices: [
          { 
            text: '继续上班', 
            action: 'trigger_event',
            eventId: 'going_to_work',
            effects: { mood: 15, energy: -5 }
          }
        ]
      },
      
      'keep_money': {
        id: 'keep_money',
        title: '据为己有',
        description: '把钱收下了，心里有点不安但还是很开心。',
        choices: [
          { 
            text: '继续上班', 
            action: 'trigger_event',
            eventId: 'going_to_work',
            effects: { mood: -5, energy: -5 }
          }
        ]
      },
      
      'find_owner': {
        id: 'find_owner',
        title: '寻找失主',
        description: '通过钞票上的信息找到了失主，对方给了50元感谢费。',
        choices: [
          { 
            text: '继续上班', 
            action: 'trigger_event',
            eventId: 'going_to_work',
            effects: { mood: 25, energy: -10 }
          }
        ]
      },
      
      // 基于历史记录的事件
      'stomach_pain': {
        id: 'stomach_pain',
        title: '肚子不舒服',
        description: '可能是因为之前憋屎的原因，现在肚子有点不舒服。',
        choices: [
          { 
            text: '喝热水缓解', 
            action: 'trigger_event',
            eventId: 'lunch_time',
            effects: { mood: -5, energy: -5 }
          },
          { 
            text: '吃点药', 
            action: 'trigger_event',
            eventId: 'lunch_time',
            effects: { mood: 0, energy: -10, money: -10 }
          },
          { 
            text: '忍着继续工作', 
            action: 'trigger_event',
            eventId: 'lunch_time',
            effects: { mood: -10, energy: -15 }
          }
        ]
      },
      
      // 基于金钱情况的事件
      'borrow_money': {
        id: 'borrow_money',
        title: '借钱',
        description: '钱包空空如也，需要向同事借点钱。',
        choices: [
          { 
            text: '向好心同事借钱', 
            action: 'trigger_event',
            eventId: 'going_to_work',
            effects: { mood: 5, money: 20 }
          },
          { 
            text: '向老板预支工资', 
            action: 'trigger_event',
            eventId: 'going_to_work',
            effects: { mood: -10, money: 50 }
          }
        ]
      },
      
      // 基于心情值的事件
      'good_mood_boost': {
        id: 'good_mood_boost',
        title: '心情愉悦',
        description: '今天心情特别好，感觉做什么都顺利！',
        choices: [
          { 
            text: '继续保持好心情', 
            action: 'trigger_event',
            eventId: 'start_working',
            effects: { mood: 10, energy: 5 }
          }
        ]
      },
      
      // 基于精力值的事件
      'tired_slump': {
        id: 'tired_slump',
        title: '疲惫不堪',
        description: '太累了，感觉整个人都不好了...',
        choices: [
          { 
            text: '强打精神工作', 
            action: 'trigger_event',
            eventId: 'start_working',
            effects: { mood: -10, energy: -15 }
          },
          { 
            text: '申请休息一下', 
            action: 'trigger_event',
            eventId: 'start_working',
            effects: { mood: 5, energy: 10 }
          }
        ]
      }
    };
  }

  // 获取事件
  getEvent(eventId) {
    return this.events[eventId] || null;
  }

  // 获取所有事件ID
  getAllEventIds() {
    return Object.keys(this.events);
  }
}

module.exports = new EventSystem();