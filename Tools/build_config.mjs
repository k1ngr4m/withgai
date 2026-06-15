import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const dataOut = path.join(root, "Data", "Generated", "Config");
const tablesOut = path.join(root, "DataTables", "Datas");
fs.mkdirSync(dataOut, { recursive: true });
fs.mkdirSync(tablesOut, { recursive: true });

const classDefs = [
  ["backend", "后端", "programmer", 1, "default", "", "relic_backend_gray_release", ["card_backend_interface_probe", "card_backend_interface_probe", "card_backend_interface_probe", "card_backend_interface_probe", "card_backend_circuit_breaker", "card_backend_circuit_breaker", "card_backend_circuit_breaker", "card_backend_circuit_breaker", "card_backend_publish_script", "card_backend_hotfix_rollback"], ["programmer_shared"], 1, true, "稳健、防守、服务引擎", "#3AA7A3"],
  ["frontend", "前端", "programmer", 2, "boss_defeated", "boss_pitch_supervisor", "relic_frontend_design_link", ["card_frontend_pixel_tap", "card_frontend_pixel_tap", "card_frontend_pixel_tap", "card_frontend_pixel_tap", "card_frontend_flex_layout", "card_frontend_flex_layout", "card_frontend_flex_layout", "card_frontend_flex_layout", "card_frontend_slice_sprint", "card_frontend_hotfix_style"], ["programmer_shared"], 2, true, "连击、组件、样式层滚雪球", "#E676AF"],
  ["tester", "测试", "programmer", 3, "elite_wins", "3", "relic_tester_automation_framework", ["card_tester_defect_log", "card_tester_defect_log", "card_tester_defect_log", "card_tester_defect_log", "card_tester_smoke_test", "card_tester_smoke_test", "card_tester_smoke_test", "card_tester_smoke_test", "card_tester_repro_steps", "card_tester_regression_confirm"], ["programmer_shared"], 3, true, "Bug、用例、Diff 锁场", "#F0B64D"],
  ["algorithm", "算法", "programmer", 5, "reach_floor", "top", "relic_algorithm_local_cluster", ["card_algo_linear_probe", "card_algo_linear_probe", "card_algo_linear_probe", "card_algo_linear_probe", "card_algo_complexity_compress", "card_algo_complexity_compress", "card_algo_complexity_compress", "card_algo_complexity_compress", "card_algo_heuristic_search", "card_algo_local_opt"], ["programmer_shared"], 5, true, "算力、复杂度、高爆发", "#8B7FF5"],
  ["product_manager", "产品经理", "office_other", 3, "event_count", "6", "relic_pm_review_minutes", ["card_pm_schedule_compress", "card_pm_schedule_compress", "card_pm_schedule_compress", "card_pm_schedule_compress", "card_pm_priority_shuffle", "card_pm_priority_shuffle", "card_pm_priority_shuffle", "card_pm_priority_shuffle", "card_pm_meeting_minutes", "card_pm_revision_notice"], [], 3, true, "需求变更、优先级、意图操控", "#6BB7F0"],
  ["hr", "HR", "office_other", 4, "boss_defeated", "boss_mutant_hr", "relic_hr_annual_review", ["card_hr_performance_talk", "card_hr_performance_talk", "card_hr_performance_talk", "card_hr_performance_talk", "card_hr_compliance_reminder", "card_hr_compliance_reminder", "card_hr_compliance_reminder", "card_hr_compliance_reminder", "card_hr_optimization_warning", "card_hr_attendance_check"], [], 4, false, "绩效、优化名单、经济收割", "#77C776"],
];

const classMap = Object.fromEntries(classDefs.map((c) => [c[0], c]));

const cardNames = {
  backend: [
    ["card_backend_interface_probe", "接口打点", "attack", 1], ["card_backend_circuit_breaker", "熔断保护", "skill", 1], ["card_backend_publish_script", "发布脚本", "skill", 1], ["card_backend_hotfix_rollback", "热修复回滚", "skill", 0],
    ["card_backend_cache_hit", "缓存命中", "skill", 1], ["card_backend_log_collect", "日志收集", "skill", 1], ["card_backend_timeout_retry", "超时重试", "attack", 1], ["card_backend_service_degrade", "服务降级", "skill", 0], ["card_backend_traffic_shaping", "流量削峰", "skill", 1], ["card_backend_request_merge", "请求聚合", "attack", 1],
    ["card_backend_ticket_debug", "工单排查", "skill", 1], ["card_backend_session_keep", "会话保持", "skill", 1], ["card_backend_pool_maintain", "连接池维护", "skill", 1], ["card_backend_read_replica", "只读副本", "skill", 1],
    ["card_backend_api_gateway", "API网关", "power", 2], ["card_backend_redis_warmup", "Redis预热", "skill", 1], ["card_backend_message_queue", "消息队列堆积", "skill", 1], ["card_backend_sharding", "分库分表", "power", 2], ["card_backend_gray_cutover", "灰度切流", "skill", 1],
    ["card_backend_rate_limit", "限流策略", "skill", 1], ["card_backend_async_compensate", "异步补偿", "skill", 1], ["card_backend_slow_query", "慢查询优化", "attack", 1], ["card_backend_hot_standby", "双机热备", "skill", 2], ["card_backend_container_orchestration", "容器编排", "power", 2],
    ["card_backend_flush_all", "全量回写", "attack", 2], ["card_backend_cluster_scale", "集群扩容", "power", 2], ["card_backend_lossless_release", "无损发布", "skill", 2], ["card_backend_trace_chain", "追踪链路", "skill", 1], ["card_backend_disaster_recovery", "灾备接管", "skill", 2], ["card_backend_zero_downtime", "零停机升级", "power", 3],
  ],
  frontend: [
    ["card_frontend_pixel_tap", "像素敲击", "attack", 1], ["card_frontend_flex_layout", "Flex排版", "skill", 1], ["card_frontend_slice_sprint", "切图冲刺", "skill", 0], ["card_frontend_hotfix_style", "热更新样式", "skill", 1],
    ["card_frontend_pixel_align", "像素级对齐", "skill", 0], ["card_frontend_compat_patch", "兼容性补丁", "skill", 1], ["card_frontend_button_bounce", "按钮回弹", "attack", 1], ["card_frontend_component_mount", "组件挂载", "skill", 1], ["card_frontend_css_override", "CSS覆盖", "skill", 1], ["card_frontend_first_screen", "首屏优化", "skill", 1],
    ["card_frontend_grid_stretch", "栅格拉伸", "attack", 1], ["card_frontend_event_bubble", "事件冒泡", "attack", 1], ["card_frontend_breakpoint_adapt", "断点适配", "skill", 1], ["card_frontend_tracking", "交互埋点", "skill", 1],
    ["card_frontend_component_reuse", "组件复用", "skill", 1], ["card_frontend_state_boost", "状态提升", "power", 1], ["card_frontend_motion_overload", "动效超载", "attack", 2], ["card_frontend_vue_suite", "Vue三件套", "power", 2], ["card_frontend_style_isolate", "样式隔离", "skill", 1],
    ["card_frontend_night_theme", "夜间主题", "skill", 1], ["card_frontend_h5_accel", "H5加速", "skill", 1], ["card_frontend_lazy_load", "懒加载", "skill", 1], ["card_frontend_design_system", "设计系统", "power", 2], ["card_frontend_animation_compose", "动画编排", "attack", 2],
    ["card_frontend_crash_animation", "崩溃动画", "attack", 2], ["card_frontend_site_refactor", "全站重构", "power", 3], ["card_frontend_cross_platform", "跨端统一", "skill", 2], ["card_frontend_ssr", "SSR直出", "skill", 2], ["card_frontend_visual_climax", "视觉高潮", "attack", 3], ["card_frontend_infinite_scroll", "无限滚动", "power", 2],
  ],
  tester: [
    ["card_tester_defect_log", "缺陷登记", "attack", 1], ["card_tester_smoke_test", "冒烟测试", "skill", 1], ["card_tester_repro_steps", "复现步骤", "skill", 1], ["card_tester_regression_confirm", "回归确认", "skill", 0],
    ["card_tester_assert_fail", "断言失败", "attack", 1], ["card_tester_boundary_check", "边界值校验", "skill", 0], ["card_tester_log_screenshot", "日志截图", "skill", 1], ["card_tester_env_reset", "环境重置", "skill", 1], ["card_tester_version_compare", "版本比对", "skill", 1], ["card_tester_whitebox", "白盒排查", "attack", 1],
    ["card_tester_blackbox", "黑盒巡检", "skill", 1], ["card_tester_case_add", "Case补录", "skill", 1], ["card_tester_missed_test", "漏测补刀", "attack", 1], ["card_tester_ticket_chase", "工单追击", "attack", 1],
    ["card_tester_auto_regression", "自动化回归", "power", 2], ["card_tester_bug_upgrade", "缺陷升级", "skill", 1], ["card_tester_case_matrix", "用例矩阵", "power", 1], ["card_tester_stress_test", "压力测试", "attack", 2], ["card_tester_stability_sample", "稳定性抽检", "skill", 1],
    ["card_tester_rollback_review", "回滚复盘", "skill", 1], ["card_tester_smoke_recheck", "冒烟复检", "skill", 1], ["card_tester_permission_retest", "权限复测", "skill", 1], ["card_tester_night_patrol", "夜间巡检", "skill", 1], ["card_tester_repro_harden", "复现加严", "skill", 1],
    ["card_tester_92_bugs", "提交92个致命Bug", "skill", 3], ["card_tester_report_lock", "测试报告封板", "attack", 2], ["card_tester_full_chain", "全链路压测", "attack", 3], ["card_tester_shutdown_verify", "停服验证", "skill", 2], ["card_tester_zero_bug_fantasy", "零缺陷幻想", "power", 2], ["card_tester_release_block", "上线拦截", "skill", 2],
  ],
  algorithm: [
    ["card_algo_linear_probe", "线性试探", "attack", 1], ["card_algo_complexity_compress", "复杂度压缩", "skill", 1], ["card_algo_heuristic_search", "启发式搜索", "skill", 1], ["card_algo_local_opt", "局部最优", "skill", 0],
    ["card_algo_greedy_sample", "贪心取样", "attack", 1], ["card_algo_pruning", "剪枝优化", "skill", 1], ["card_algo_recursion", "递归下钻", "attack", 1], ["card_algo_state_compress", "状态压缩", "skill", 1], ["card_algo_hash_accel", "哈希加速", "skill", 1], ["card_algo_eval_func", "估值函数", "skill", 1],
    ["card_algo_data_clean", "数据清洗", "skill", 1], ["card_algo_backtrack", "搜索回溯", "attack", 1], ["card_algo_path_read", "路径预读", "skill", 1], ["card_algo_edge_reweight", "边权重排", "skill", 1],
    ["card_algo_dynamic_programming", "动态规划", "power", 2], ["card_algo_complexity_burst", "复杂度爆炸", "attack", 2], ["card_algo_big_o_compress", "大O压缩", "skill", 1], ["card_algo_monte_carlo", "蒙特卡洛试投", "skill", 1], ["card_algo_astar", "A星寻路", "skill", 1],
    ["card_algo_convolution", "卷积加速", "attack", 2], ["card_algo_memo_search", "记忆化搜索", "power", 2], ["card_algo_binary_cut", "二分切割", "attack", 1], ["card_algo_graph_opt", "图优化", "skill", 1], ["card_algo_matrix_warmup", "矩阵预热", "skill", 1],
    ["card_algo_global_optimum", "全局最优解", "attack", -1], ["card_algo_matrix_mul", "矩阵乘法", "attack", 2], ["card_algo_distill", "神经网络蒸馏", "power", 3], ["card_algo_compute_surge", "算力洪峰", "skill", 2], ["card_algo_model_converge", "模型收敛", "attack", 2], ["card_algo_zero_complexity", "复杂度归零", "skill", 2],
  ],
  product_manager: [
    ["card_pm_change_wording", "需求改口", "skill", 1], ["card_pm_priority_shuffle", "优先级重排", "skill", 1], ["card_pm_meeting_minutes", "会议纪要", "skill", 0], ["card_pm_revision_notice", "改版通知", "skill", 1],
    ["card_pm_message_align", "口径统一", "skill", 1], ["card_pm_schedule_compress", "排期压缩", "attack", 1], ["card_pm_scope_confirm", "范围确认", "skill", 1], ["card_pm_prd_append", "PRD增补", "skill", 1], ["card_pm_reopen_task", "任务重开", "attack", 1], ["card_pm_tracking_backfill", "埋点回填", "skill", 1],
    ["card_pm_split_ticket", "需求拆票", "skill", 1], ["card_pm_extra_requirement", "临时加需求", "skill", 1], ["card_pm_sync_conclusion", "同步结论", "skill", 1], ["card_pm_pending_item", "待确认项", "skill", 1],
    ["card_pm_review", "需求评审", "power", 2], ["card_pm_delay_meeting", "会议延期", "skill", 1], ["card_pm_priority_top", "优先级置顶", "skill", 0], ["card_pm_milestone_split", "里程碑拆分", "skill", 1], ["card_pm_scope_spread", "范围蔓延", "power", 1],
    ["card_pm_department_align", "部门对齐", "skill", 1], ["card_pm_proto_walkthrough", "原型走查", "skill", 1], ["card_pm_weekly_sync", "周会拉通", "skill", 1], ["card_pm_urgent_schedule", "紧急排期", "attack", 1], ["card_pm_verbal_promise", "口头承诺", "skill", 1],
    ["card_pm_align_all", "全员对齐", "skill", 2], ["card_pm_roadmap", "版本路线图", "attack", 2], ["card_pm_snowball", "需求雪崩", "attack", 3], ["card_pm_goal_drift", "目标漂移", "skill", 2], ["card_pm_ceo_tone", "CEO口风", "power", 3], ["card_pm_roadmap_reset", "路线图重置", "skill", 2],
  ],
  hr: [
    ["card_hr_performance_talk", "绩效面谈", "attack", 1], ["card_hr_compliance_reminder", "合规提醒", "skill", 1], ["card_hr_optimization_warning", "优化预警", "skill", 1], ["card_hr_attendance_check", "考勤抽查", "skill", 0],
    ["card_hr_onboarding", "入职手续", "skill", 1], ["card_hr_background_check", "背调申请", "attack", 1], ["card_hr_policy_broadcast", "制度宣导", "skill", 1], ["card_hr_probation_watch", "试用观察", "skill", 1], ["card_hr_exit_interview", "离职访谈", "attack", 1], ["card_hr_salary_calc", "薪酬核算", "skill", 1],
    ["card_hr_interview_review", "面试复盘", "skill", 1], ["card_hr_candidate_pool", "候选池维护", "skill", 1], ["card_hr_regularization", "转正申请", "skill", 1], ["card_hr_discipline_warning", "纪律警示", "attack", 1],
    ["card_hr_performance_archive", "绩效归档", "power", 1], ["card_hr_last_place_cut", "末位淘汰", "attack", 2], ["card_hr_compliance_review", "合规审查", "skill", 1], ["card_hr_annual_award", "年度评优", "power", 2], ["card_hr_org_optimization", "组织优化", "skill", 1],
    ["card_hr_layoff_list", "裁员名单", "skill", 2], ["card_hr_headhunter_offer", "猎头报价", "skill", 1], ["card_hr_org_diagnosis", "组织诊断", "skill", 1], ["card_hr_interview_bargain", "面试压价", "attack", 1], ["card_hr_transfer_notice", "调岗通知", "skill", 1],
    ["card_hr_nplusone", "N+1结算", "attack", -1], ["card_hr_annual_inventory", "年度盘点", "power", 3], ["card_hr_talent_extraction", "人才盘剥", "attack", 3], ["card_hr_all_hands_review", "全员述职", "skill", 2], ["card_hr_blacklist_share", "黑名单共享", "power", 2], ["card_hr_optimization_storm", "优化风暴", "attack", 3],
  ],
  shared: [
    ["card_shared_keyboard_smash", "键盘重击", "attack", 1], ["card_shared_stapler_burst", "订书机连射", "attack", 1], ["card_shared_noise_cancel", "戴上降噪耳机", "skill", 1], ["card_shared_coffee_boost", "咖啡续命", "skill", 0],
    ["card_shared_toilet_break", "带薪拉屎", "skill", 1], ["card_shared_desk_inspection", "工位巡检", "skill", 1], ["card_shared_rollback", "回滚版本", "skill", 1], ["card_shared_standup", "晨会同步", "skill", 1],
    ["card_shared_clock_out", "下班打卡", "skill", 1], ["card_shared_hotfix_patch", "临时补丁", "skill", 0], ["card_shared_badge_throw", "工牌甩脸", "attack", 0], ["card_shared_meeting_mute", "会议静音", "skill", 1],
  ],
};

const rarityByIndex = (i) => (i < 14 ? "common" : i < 24 ? "uncommon" : "rare");
const targetForType = (type) => (type === "attack" ? "single_enemy" : "self");
const targetForCard = (type, id) => (id === "card_shared_meeting_mute" ? "selected" : targetForType(type));

const specialCardDescriptions = {
  card_shared_rollback: "回滚版本：获得防线，清除脆弱、易伤与焦虑。",
  card_shared_standup: "晨会同步：获得防线，抽牌并返还精力。",
  card_shared_meeting_mute: "会议静音：获得防线并削弱目标攻击意图。",
};

function descriptionForCard(id, name, type) {
  return specialCardDescriptions[id] ?? `${name}：${type === "attack" ? "造成伤害" : type === "power" ? "建立长期收益" : "获得防线并触发职业资源"}。`;
}

function cardEffects(classId, cardId, type, cost, idx) {
  const n = Math.max(cost, 0);
  const rareBoost = idx >= 24 ? 4 : idx >= 14 ? 2 : 0;
  if (cardId === "card_status_option_promise") {
    return [
      { effect_type: "apply_status", target_type: "self", params: { status_id: "anxiety", amount: 1 } },
    ];
  }
  if (cardId === "card_status_meeting_minutes") {
    return [
      { effect_type: "apply_status", target_type: "self", params: { status_id: "overtime", amount: 1 } },
    ];
  }
  if (cardId === "card_curse_next_year_promotion") {
    return [
      { effect_type: "apply_status", target_type: "self", params: { status_id: "weak", amount: 1 } },
      { effect_type: "apply_status", target_type: "self", params: { status_id: "vulnerable", amount: 1 } },
    ];
  }
  if (cardId === "card_shared_coffee_boost") {
    return [
      { effect_type: "gain_energy", target_type: "self", params: { amount: 1 } },
      { effect_type: "draw_cards", target_type: "self", params: { amount: 1 } },
    ];
  }
  if (cardId === "card_shared_rollback") {
    return [
      { effect_type: "gain_block", target_type: "self", params: { amount: 6 } },
      { effect_type: "remove_status", target_type: "self", params: { status_id: "weak" } },
      { effect_type: "remove_status", target_type: "self", params: { status_id: "vulnerable" } },
      { effect_type: "remove_status", target_type: "self", params: { status_id: "anxiety" } },
    ];
  }
  if (cardId === "card_shared_standup") {
    return [
      { effect_type: "gain_block", target_type: "self", params: { amount: 5 } },
      { effect_type: "draw_cards", target_type: "self", params: { amount: 1 } },
      { effect_type: "gain_energy", target_type: "self", params: { amount: 1 } },
    ];
  }
  if (cardId === "card_shared_meeting_mute") {
    return [
      { effect_type: "gain_block", target_type: "self", params: { amount: 5 } },
      { effect_type: "modify_intent", target_type: "selected", params: { amount: -4 } },
    ];
  }
  if (type === "attack") {
    const damage = cost < 0 ? 10 : 6 + n * 4 + rareBoost;
    const effects = [{ effect_type: "deal_damage", target_type: "selected", params: { amount: damage } }];
    if (classId === "backend") effects.push({ effect_type: "add_cache", target_type: "self", params: { amount: 1 + Math.floor(idx / 14) } });
    if (classId === "tester") effects.push({ effect_type: "add_case", target_type: "selected", params: { amount: 1 + Math.floor(idx / 14) } });
    if (classId === "algorithm") effects.push({ effect_type: "add_compute", target_type: "self", params: { amount: 1 + Math.floor(idx / 14) } });
    if (classId === "product_manager") effects.push({ effect_type: "apply_status", target_type: "selected", params: { status_id: "requirement_change", amount: 1 } });
    return effects;
  }
  if (type === "power") {
    const statusId = classId === "backend" ? "service_online" : classId === "frontend" ? "style_layer" : classId === "tester" ? "case_mark" : classId === "algorithm" ? "compute" : classId === "product_manager" ? "priority" : "performance";
    return [
      { effect_type: "apply_status", target_type: "self", params: { status_id: statusId, amount: 1 } },
      { effect_type: "draw_cards", target_type: "self", params: { amount: 1 } },
    ];
  }
  const block = 5 + n * 3 + rareBoost;
  const effects = [{ effect_type: "gain_block", target_type: "self", params: { amount: block } }];
  if (cost === 0) effects.push({ effect_type: "draw_cards", target_type: "self", params: { amount: 1 } });
  if (cardId === "card_backend_publish_script") {
    effects.push({ effect_type: "deploy_service", target_type: "self", params: { amount: 1 } });
  } else if (classId === "backend") {
    effects.push({ effect_type: "add_cache", target_type: "self", params: { amount: 1 } });
  }
  if (classId === "frontend") effects.push({ effect_type: idx % 2 === 0 ? "add_component" : "add_style_layer", target_type: "self", params: { amount: 1 } });
  if (classId === "tester") effects.push({ effect_type: idx % 2 === 0 ? "inject_bug" : "add_diff", target_type: "selected", params: { amount: 1 } });
  if (classId === "algorithm") effects.push({ effect_type: idx % 2 === 0 ? "add_compute" : "modify_complexity", target_type: "self", params: { amount: idx % 2 === 0 ? 1 : -1 } });
  if (classId === "product_manager") {
    if (["card_pm_change_wording", "card_pm_revision_notice", "card_pm_extra_requirement"].includes(cardId)) {
      effects.push({ effect_type: "apply_status", target_type: "selected", params: { status_id: "requirement_change", amount: 1 } });
      effects.push({ effect_type: "modify_intent", target_type: "selected", params: { amount: -3 } });
    } else if (["card_pm_priority_shuffle", "card_pm_priority_top"].includes(cardId)) {
      effects.push({ effect_type: "apply_status", target_type: "selected", params: { status_id: "priority", amount: 1 } });
    } else {
      effects.push({ effect_type: idx % 2 === 0 ? "modify_intent" : "apply_status", target_type: "selected", params: idx % 2 === 0 ? { amount: -3 } : { status_id: "priority", amount: 1 } });
    }
  }
  return effects;
}

const cards = [];
for (const [classId, names] of Object.entries(cardNames)) {
  for (let i = 0; i < names.length; i++) {
    const [id, name, type, cost] = names[i];
    const isShared = classId === "shared";
    cards.push({
      id, name, class_tags: isShared ? ["programmer_shared"] : [classId], rarity: isShared ? "common" : rarityByIndex(i),
      type, cost, target_type: targetForCard(type, id), keywords: [], effect_group_id: `eg_${id}`, upgrade_to: `${id}_plus`,
      enabled_in_first_playable: !["hr"].includes(classId), description: descriptionForCard(id, name, type),
      art_path: id === "card_backend_publish_script" ? "res://Resources/Art/Generated/P0/cards/card_illust_backend_publish_script_v1/final.png" : "",
    });
  }
}

const pollutionCards = [
  ["card_status_option_promise", "期权承诺", "status", "焦虑 +1。"],
  ["card_status_meeting_minutes", "会议纪要污染", "status", "加班 +1。"],
  ["card_curse_next_year_promotion", "明年提拔你", "curse", "脆弱与易伤 +1。"],
].map(([id, name, type, description]) => ({
  id,
  name,
  class_tags: ["pollution"],
  rarity: "special",
  type,
  cost: 0,
  target_type: "self",
  keywords: ["pollution"],
  effect_group_id: `eg_${id}`,
  upgrade_to: "",
  enabled_in_first_playable: true,
  description: `${name}：${description}`,
  art_path: "",
}));
cards.push(...pollutionCards);

const effectGroups = {};
const effectEntries = [];
for (const card of cards) {
  const classId = card.class_tags[0] === "programmer_shared" ? "shared" : card.class_tags[0];
  const idx = (cardNames[classId] || cardNames.shared).findIndex((row) => row[0] === card.id);
  const entries = cardEffects(classId, card.id, card.type, card.cost, idx);
  const entryIds = entries.map((entry, entryIndex) => {
    const entryId = `${card.effect_group_id}_e${String(entryIndex + 1).padStart(2, "0")}`;
    effectEntries.push({
      id: entryId,
      effect_group_id: card.effect_group_id,
      order: entryIndex + 1,
      effect_type: entry.effect_type,
      target_type: entry.target_type,
      params: entry.params ?? {},
    });
    return entryId;
  });
  effectGroups[card.effect_group_id] = { id: card.effect_group_id, entry_ids: entryIds, entries };
}

function relicTriggers(id) {
  const triggers = {
    relic_backend_gray_release: ["battle_start", "card_played"],
    relic_frontend_design_link: ["card_played"],
    relic_tester_automation_framework: ["apply_status"],
    relic_algorithm_local_cluster: ["card_played"],
    relic_pm_review_minutes: ["apply_status", "modify_intent"],
    relic_hr_annual_review: ["enemy_defeated"],
    relic_blue_light_glasses: ["battle_start"],
    relic_cold_brew_bucket: ["card_played"],
    relic_hair_shampoo: ["battle_start"],
    relic_lumbar_cushion: ["battle_start"],
    relic_standing_desk: ["gain_block"],
    relic_parking_pass: ["elite_reward"],
    relic_employee_coupon: ["shop_purchase"],
    relic_error_log_repo: ["enemy_turn"],
    relic_figma_library: ["add_component"],
    relic_read_replica: ["damage_taken"],
    relic_gantt_roadmap: ["modify_intent"],
    relic_paper_citation: ["deal_damage"],
  };
  return triggers[id] ?? [];
}

const relics = [
  ["relic_backend_gray_release", "灰度发布开关", ["backend"], "starter", "战斗开始获得 1 缓存；首次部署服务抽 1 张。", "res://Resources/Art/Generated/P0/icons/relic_icon_traffic_valve_v1/prop.png"],
  ["relic_frontend_design_link", "设计稿链接", ["frontend"], "starter", "每回合第 3 张牌获得 1 样式层。", "res://Resources/Art/Generated/P0/icons/relic_icon_design_review_v1/prop.png"],
  ["relic_tester_automation_framework", "自动化测试框架", ["tester"], "starter", "首次施加 Bug 时追加用例。", "res://Resources/Art/Generated/P0/icons/relic_icon_unit_test_template_v1/prop.png"],
  ["relic_algorithm_local_cluster", "本地算力集群", ["algorithm"], "starter", "首次 X 费牌返还 1 精力。", "res://Resources/Art/Generated/P0/icons/relic_icon_gpu_card_v1/prop.png"],
  ["relic_pm_review_minutes", "需求评审纪要", ["product_manager"], "starter", "首次需求变更时抽牌并获得防线。", "res://Resources/Art/Generated/P0/icons/relic_icon_meeting_room_claim_v1/prop.png"],
  ["relic_hr_annual_review", "年度考评表", ["hr"], "starter", "首次击败敌人获得绩效。", "res://Resources/Art/Generated/P0/icons/relic_icon_performance_table_v1/prop.png"],
  ["relic_blue_light_glasses", "蓝光眼镜", ["backend", "frontend", "tester", "algorithm", "product_manager"], "common", "首回合额外抽 1 张。", "res://Resources/Art/Generated/P0/icons/relic_icon_blue_light_glasses_v1/prop.png"],
  ["relic_cold_brew_bucket", "冷萃咖啡桶", ["backend", "frontend", "tester", "algorithm", "product_manager"], "common", "首次打出 0 费牌获得 1 精力。", "res://Resources/Art/Generated/P0/icons/relic_icon_cold_brew_bucket_v1/prop.png"],
  ["relic_hair_shampoo", "防脱洗发水", ["backend", "frontend", "tester", "algorithm", "product_manager"], "common", "开局最大精神状态 +6。", "res://Resources/Art/Generated/P0/icons/relic_icon_hair_shampoo_v1/prop.png"],
  ["relic_lumbar_cushion", "护腰靠垫", ["backend", "frontend", "tester", "algorithm", "product_manager"], "common", "战斗开始获得 4 防线。", "res://Resources/Art/Generated/P0/icons/relic_icon_lumbar_cushion_v1/prop.png"],
  ["relic_standing_desk", "升降桌", ["backend", "frontend", "tester", "algorithm", "product_manager"], "common", "每回合首次获得防线追加 2。", "res://Resources/Art/Generated/P0/icons/relic_icon_standing_desk_v1/prop.png"],
  ["relic_parking_pass", "园区停车月卡", ["backend", "frontend", "tester", "algorithm", "product_manager"], "common", "击败精英额外获得绩效点。", "res://Resources/Art/Generated/P0/icons/relic_icon_parking_pass_v1/prop.png"],
  ["relic_employee_coupon", "员工内购券", ["backend", "frontend", "tester", "algorithm", "product_manager"], "common", "首次商店消费折扣。", "res://Resources/Art/Generated/P0/icons/relic_icon_employee_discount_coupon_v1/prop.png"],
  ["relic_error_log_repo", "报错日志仓库", ["tester"], "uncommon", "Bug 触发时追加伤害。", "res://Resources/Art/Generated/P0/icons/relic_icon_error_log_repo_v1/prop.png"],
  ["relic_figma_library", "Figma组件库", ["frontend"], "uncommon", "首次生成组件时额外复制。", "res://Resources/Art/Generated/P0/icons/relic_icon_figma_library_v1/prop.png"],
  ["relic_read_replica", "只读从库快照", ["backend"], "uncommon", "首次承压时返还资源。", "res://Resources/Art/Generated/P0/icons/relic_icon_read_replica_v1/prop.png"],
  ["relic_gantt_roadmap", "路线图甘特图", ["product_manager"], "uncommon", "首次重置意图后抽牌。", "res://Resources/Art/Generated/P0/icons/relic_icon_gantt_roadmap_v1/prop.png"],
  ["relic_paper_citation", "论文引用榜", ["algorithm"], "uncommon", "高复杂度时终结牌更强。", "res://Resources/Art/Generated/P0/icons/relic_icon_paper_citation_v1/prop.png"],
].map(([id, name, allowed_classes, rarity, description, art_path]) => ({
  id, name, allowed_classes, rarity, trigger_list: relicTriggers(id), effect_group_id: "", shop_weight: rarity === "starter" ? 0 : 10, description, art_path,
}));

const phaseScripts = {
  enemy_airdrop_director: [
    { threshold_pct: 0.5, name: "空降姿态切换", actions: [{ action_type: "block", amount: 8 }, { action_type: "force_intent", intent: { intent_type: "multi_attack", amount: 4, hits: 2 } }] },
  ],
  elite_airdrop_project_lead: [
    { threshold_pct: 0.5, name: "Deadline 收紧", actions: [{ action_type: "debuff_player", status_id: "anxiety", amount: 2 }, { action_type: "force_intent", intent: { intent_type: "multi_attack", amount: 6, hits: 2 } }] },
  ],
  elite_outsource_manager: [
    { threshold_pct: 0.5, name: "外包协同", actions: [{ action_type: "spawn", enemy_id: "enemy_process_specialist", amount: 1, max_allies: 4 }, { action_type: "block", amount: 8 }] },
  ],
  elite_approval_eye: [
    { threshold_pct: 0.5, name: "审批冻结", actions: [{ action_type: "cleanse_player", amount: 3 }, { action_type: "pollute", card_id: "card_curse_next_year_promotion", amount: 1, destination: "discard" }] },
  ],
  boss_pitch_supervisor: [
    { threshold_pct: 0.66, name: "期权加码", actions: [{ action_type: "pollute", card_id: "card_status_option_promise", amount: 1, destination: "hand" }, { action_type: "block", amount: 10 }] },
    { threshold_pct: 0.33, name: "明年一定", actions: [{ action_type: "pollute", card_id: "card_curse_next_year_promotion", amount: 1, destination: "draw" }, { action_type: "force_intent", intent: { intent_type: "attack", amount: 18 } }] },
  ],
  boss_mutant_hr: [
    { threshold_pct: 0.66, name: "绩效面谈升级", actions: [{ action_type: "cleanse_player", amount: 2 }, { action_type: "debuff_player", status_id: "overtime", amount: 1 }, { action_type: "block", amount: 10 }] },
    { threshold_pct: 0.33, name: "优化名单扩散", actions: [{ action_type: "pollute", card_id: "card_status_meeting_minutes", amount: 2, destination: "discard" }, { action_type: "force_intent", intent: { intent_type: "debuff", status_id: "overtime", amount: 3 } }] },
  ],
  boss_mutant_ceo: [
    { threshold_pct: 0.7, name: "季度会启动", actions: [{ action_type: "spawn", enemy_id: "enemy_meeting_maniac", amount: 1, max_allies: 4 }, { action_type: "block", amount: 12 }] },
    { threshold_pct: 0.4, name: "资本意志压顶", actions: [{ action_type: "pollute", card_id: "card_status_meeting_minutes", amount: 2, destination: "discard" }, { action_type: "force_intent", intent: { intent_type: "multi_attack", amount: 8, hits: 3 } }] },
    { threshold_pct: 0.2, name: "全员大会", actions: [{ action_type: "spawn", enemy_id: "enemy_process_specialist", amount: 1, max_allies: 5 }, { action_type: "pollute", card_id: "card_curse_next_year_promotion", amount: 1, destination: "draw" }, { action_type: "block", amount: 20 }] },
  ],
};

const enemies = [
  ["enemy_slacker_coworker", "摸鱼同事", [1], 34, "偶尔跳过攻击并叠防线", "res://Resources/Art/Generated/P0/enemies/enemy_slacker_coworker_v1/raw.png"],
  ["enemy_workaholic_coworker", "卷王同事", [1], 38, "高频多段攻击", "res://Resources/Art/Generated/P0/enemies/enemy_workaholic_coworker_v1/raw.png"],
  ["enemy_angry_cleaner", "暴躁保洁阿姨", [1], 42, "高面板单次伤害", "res://Resources/Art/Generated/P0/enemies/enemy_angry_cleaner_v1/raw.png"],
  ["enemy_salesman", "西装推销员", [1], 36, "向牌组塞低价值污染", "res://Resources/Art/Generated/P0/enemies/enemy_salesman_v1/raw.png"],
  ["enemy_process_specialist", "流程专员", [2], 48, "频繁获得防线与增益", ""],
  ["enemy_performance_inspector", "绩效监察", [2], 52, "惩罚拖回合与手牌膨胀", ""],
  ["enemy_meeting_maniac", "开会狂人", [2], 46, "通过议程召唤衍生物", ""],
  ["enemy_airdrop_director", "空降总监", [3], 58, "切换姿态压迫节奏", ""],
  ["enemy_compliance_judge", "合规审判官", [3], 60, "清除玩家增益并塞入污染", ""],
  ["elite_airdrop_project_lead", "空降项目组长", [1], 78, "Deadline 倒计时", "res://Resources/Art/Generated/P0/enemies/elite_airdrop_project_lead_v1/raw.png"],
  ["elite_outsource_manager", "外包统筹经理", [1, 2], 82, "召唤杂兵并强化协同", ""],
  ["elite_budget_gatekeeper", "预算守门人", [2], 88, "压缩绩效点收益", ""],
  ["elite_approval_eye", "审批流之眼", [3], 96, "冻结高费牌并扭曲顺序", ""],
  ["boss_pitch_supervisor", "画饼主管", [1], 120, "塞入期权与明年提拔你", "res://Resources/Art/Generated/P0/characters/boss_pitch_supervisor_v1.png"],
  ["boss_mutant_hr", "变异HR", [2], 150, "压缩续航、惩罚冗余手牌", ""],
  ["boss_mutant_ceo", "变异总裁", [3], 190, "多阶段、多意图、召唤会议纪要", ""],
].map(([id, name, chapter_tags, base_hp, description, art_path]) => ({
  id, name, chapter_tags, base_hp, intent_group_id: `ig_${id}`, phase_group_id: phaseScripts[id] ? `pg_${id}` : "", reward_profile_id: "reward_default", description, art_path,
}));

const specialtyIntents = {
  enemy_workaholic_coworker: [
    { intent_type: "multi_attack", amount: 3, hits: 3, weight: 4 },
  ],
  enemy_salesman: [
    { intent_type: "pollute", card_id: "card_status_option_promise", amount: 1, destination: "discard", weight: 4 },
  ],
  enemy_process_specialist: [
    { intent_type: "block", amount: 10, weight: 3 },
  ],
  enemy_performance_inspector: [
    { intent_type: "debuff", status_id: "weak", amount: 1, weight: 2 },
  ],
  enemy_meeting_maniac: [
    { intent_type: "spawn", enemy_id: "enemy_process_specialist", amount: 1, max_allies: 3, weight: 3 },
    { intent_type: "pollute", card_id: "card_status_meeting_minutes", amount: 1, destination: "discard", weight: 2 },
  ],
  enemy_airdrop_director: [
    { intent_type: "phase_shift", amount: 5, weight: 2 },
  ],
  enemy_compliance_judge: [
    { intent_type: "cleanse_player", amount: 2, card_id: "card_status_meeting_minutes", weight: 3 },
  ],
  elite_airdrop_project_lead: [
    { intent_type: "multi_attack", amount: 5, hits: 2, weight: 3 },
  ],
  elite_outsource_manager: [
    { intent_type: "spawn", enemy_id: "enemy_process_specialist", amount: 1, max_allies: 4, weight: 4 },
  ],
  elite_budget_gatekeeper: [
    { intent_type: "debuff", status_id: "vulnerable", amount: 1, weight: 2 },
  ],
  elite_approval_eye: [
    { intent_type: "cleanse_player", amount: 3, card_id: "card_curse_next_year_promotion", weight: 3 },
  ],
  boss_pitch_supervisor: [
    { intent_type: "pollute", card_id: "card_status_option_promise", amount: 2, destination: "discard", weight: 4 },
    { intent_type: "pollute", card_id: "card_curse_next_year_promotion", amount: 1, destination: "draw", weight: 2 },
  ],
  boss_mutant_hr: [
    { intent_type: "cleanse_player", amount: 3, card_id: "card_status_meeting_minutes", weight: 3 },
    { intent_type: "debuff", status_id: "overtime", amount: 2, weight: 2 },
  ],
  boss_mutant_ceo: [
    { intent_type: "multi_attack", amount: 6, hits: 3, weight: 3 },
    { intent_type: "spawn", enemy_id: "enemy_meeting_maniac", amount: 1, max_allies: 4, weight: 3 },
    { intent_type: "pollute", card_id: "card_status_meeting_minutes", amount: 2, destination: "discard", weight: 2 },
  ],
};

const intentGroups = {};
for (const enemy of enemies) {
  const boss = enemy.id.startsWith("boss");
  const elite = enemy.id.startsWith("elite");
  const baseEntries = [
    { intent_type: "attack", amount: boss ? 14 : elite ? 11 : 7, weight: 5 },
    { intent_type: "block", amount: boss ? 12 : elite ? 9 : 6, weight: 2 },
    { intent_type: "debuff", status_id: "anxiety", amount: 1, weight: 1 },
  ];
  intentGroups[`ig_${enemy.id}`] = {
    id: `ig_${enemy.id}`,
    intent_entries: baseEntries.concat(specialtyIntents[enemy.id] ?? []),
  };
}

const phaseGroups = Object.fromEntries(Object.entries(phaseScripts).map(([enemyId, phases]) => {
  const groupId = `pg_${enemyId}`;
  return [groupId, {
    id: groupId,
    enemy_id: enemyId,
    phase_entries: phases.map((phase, index) => ({
      id: `${groupId}_p${String(index + 1).padStart(2, "0")}`,
      order: index + 1,
      threshold_pct: phase.threshold_pct,
      name: phase.name,
      actions: phase.actions,
    })),
  }];
}));

const encounters = [
  ["enc_ch1_slacker", 1, "normal_battle", ["enemy_slacker_coworker"], 10, 1, 4],
  ["enc_ch1_workaholic", 1, "normal_battle", ["enemy_workaholic_coworker"], 10, 1, 4],
  ["enc_ch1_salesman_cleaner", 1, "normal_battle", ["enemy_salesman", "enemy_angry_cleaner"], 6, 2, 5],
  ["enc_ch1_elite_lead", 1, "elite_battle", ["elite_airdrop_project_lead"], 10, 2, 5],
  ["enc_ch1_boss_pitch", 1, "boss", ["boss_pitch_supervisor"], 1, 6, 6],
  ["enc_ch2_process", 2, "normal_battle", ["enemy_process_specialist"], 10, 7, 10],
  ["enc_ch2_performance", 2, "normal_battle", ["enemy_performance_inspector"], 10, 7, 10],
  ["enc_ch2_meeting", 2, "normal_battle", ["enemy_meeting_maniac", "enemy_process_specialist"], 8, 8, 11],
  ["enc_ch2_elite_budget", 2, "elite_battle", ["elite_budget_gatekeeper"], 8, 8, 11],
  ["enc_ch2_elite_outsource", 2, "elite_battle", ["elite_outsource_manager"], 6, 8, 11],
  ["enc_ch2_boss_hr", 2, "boss", ["boss_mutant_hr"], 1, 12, 12],
  ["enc_ch3_director", 3, "normal_battle", ["enemy_airdrop_director"], 10, 13, 16],
  ["enc_ch3_compliance", 3, "normal_battle", ["enemy_compliance_judge"], 10, 13, 16],
  ["enc_ch3_elite_eye", 3, "elite_battle", ["elite_approval_eye"], 8, 14, 17],
  ["enc_ch3_boss_ceo", 3, "boss", ["boss_mutant_ceo"], 1, 18, 18],
].map(([id, chapter, node_type, enemy_ids, weight, min_floor, max_floor]) => ({ id, chapter, node_type, enemy_ids, weight, min_floor, max_floor }));

const events = [
  ["event_unlocked_office", "老板办公室门没锁", "现金抽屉与待签文件都在。", [{ text: "拿走绩效点", effects: [{ effect_type: "gain_currency", target_type: "self", params: { amount: 45 } }] }, { text: "偷改一份文件", effects: [{ effect_type: "upgrade_card", target_type: "self", params: { amount: 1 } }] }]],
  ["event_wrong_email", "内网邮件误抄送", "你被卷入敏感链路。", [{ text: "顺手归档", effects: [{ effect_type: "draw_cards", target_type: "self", params: { amount: 1 } }] }, { text: "假装没看见", effects: [{ effect_type: "gain_currency", target_type: "self", params: { amount: 20 } }] }]],
  ["event_pantry_gossip", "茶水间八卦", "同事共享了一批黑料。", [{ text: "休息一下", effects: [{ effect_type: "recover_spirit", target_type: "self", params: { amount: 12 } }] }, { text: "删掉废牌", effects: [{ effect_type: "remove_card", target_type: "self", params: { amount: 1 } }] }]],
  ["event_vending_bug", "深夜自动贩卖机故障", "机器疯狂吐货。", [{ text: "低价购买", effects: [{ effect_type: "gain_currency", target_type: "self", params: { amount: -20 } }, { effect_type: "add_random_card", target_type: "self", params: { amount: 1 } }] }, { text: "强拿", effects: [{ effect_type: "gain_currency", target_type: "self", params: { amount: 35 } }] }]],
  ["event_intern_blame", "帮实习生背锅", "临时承担压力。", [{ text: "接下压力", effects: [{ effect_type: "lose_spirit", target_type: "self", params: { amount: 8 } }, { effect_type: "add_random_card", target_type: "self", params: { amount: 1 } }] }, { text: "流程转交", effects: [{ effect_type: "gain_currency", target_type: "self", params: { amount: 15 } }] }]],
  ["event_lottery", "年会抽奖预演", "一个赌博式收益机会。", [{ text: "抽奖", effects: [{ effect_type: "gain_currency", target_type: "self", params: { amount: 50 } }] }, { text: "不参与", effects: [{ effect_type: "recover_spirit", target_type: "self", params: { amount: 6 } }] }]],
  ["event_private_talk", "领导单独谈话", "资源与代价摆在眼前。", [{ text: "接受承诺", effects: [{ effect_type: "gain_currency", target_type: "self", params: { amount: 30 } }] }, { text: "要求资源", effects: [{ effect_type: "add_random_relic", target_type: "self", params: { amount: 1 } }] }]],
  ["event_layoff_rumor", "裁员传闻", "整层楼开始恐慌。", [{ text: "稳住心态", effects: [{ effect_type: "recover_spirit", target_type: "self", params: { amount: 10 } }] }, { text: "趁乱套利", effects: [{ effect_type: "gain_currency", target_type: "self", params: { amount: 40 } }] }]],
].map(([id, name, text, options], i) => ({ id, name, chapter_tags: [1, 2, 3], allowed_classes: ["backend", "frontend", "tester", "algorithm", "product_manager"], text, options, weight: 10 - (i % 3) }));

const statuses = [
  ["anxiety", "焦虑", "debuff"], ["overtime", "加班", "debuff"], ["vulnerable", "易伤", "debuff"], ["weak", "脆弱", "debuff"],
  ["service_online", "服务在线", "class"], ["cache", "缓存", "class"], ["component", "组件", "class"], ["style_layer", "样式层", "class"],
  ["bug", "Bug", "class"], ["case_mark", "用例", "class"], ["diff", "Diff", "class"], ["compute", "算力", "class"], ["complexity", "复杂度", "class"],
  ["requirement_change", "需求变更", "class"], ["priority", "优先级", "class"], ["performance", "绩效", "class"], ["optimization_target", "优化名单", "class"],
].map(([id, name, type]) => ({ id, name, stack_rule: "stack", timing_hooks: [], effect_group_id: "", max_stack: 99, is_hidden: false, type }));

const metaUpgrades = [
  ["meta_chair", "人体工学椅", "global_upgrade", [20, 40, 80], 3, "开局最大精神状态提升。"],
  ["meta_privacy_screen", "防窥膜", "global_upgrade", [20, 45, 90], 3, "战斗开始获得少量防线。"],
  ["meta_coffee_beans", "极品咖啡豆", "global_upgrade", [30, 60], 2, "首回合精力表现提升。"],
  ["meta_hard_drive", "扩容硬盘", "global_upgrade", [30, 60], 2, "首回合额外抽牌。"],
  ["meta_nap_bed", "午休折叠床", "global_upgrade", [20, 45, 90], 3, "休息处恢复量增加。"],
  ["meta_canteen_card", "员工食堂月卡", "global_upgrade", [25, 50], 2, "商店首次消费折扣。"],
  ["unlock_backend", "后端", "career_unlock", [0], 1, "默认开放。"],
  ["unlock_frontend", "前端", "career_unlock", [0], 1, "First Playable 开放。"],
  ["unlock_tester", "测试", "career_unlock", [0], 1, "First Playable 开放。"],
  ["unlock_algorithm", "算法", "career_unlock", [0], 1, "First Playable 开放。"],
  ["unlock_product_manager", "产品经理", "career_unlock", [0], 1, "First Playable 开放。"],
  ["unlock_hr", "HR", "career_unlock", [999], 1, "扩展职业，当前只展示。"],
].map(([id, name, type, cost_curve, max_level, description]) => ({ id, type, name, cost_curve, max_level, effect_group_id: "", prerequisite_ids: [], description }));

const mapNodes = [
  ["node_normal", "normal_battle", 45],
  ["node_elite", "elite_battle", 12],
  ["node_rest", "rest", 14],
  ["node_shop", "shop", 12],
  ["node_event", "event", 17],
  ["node_boss", "boss", 1],
].map(([id, node_type, weight]) => ({ id, chapter: 0, node_type, weight, can_repeat: true, reward_profile_id: "reward_default" }));

const rewardProfiles = {
  reward_default: { id: "reward_default", card_pool_ref: "class_and_shared", relic_pool_ref: "available", currency_range: [18, 35] },
};
const shopPools = {
  shop_default: { id: "shop_default", card_pool_refs: ["class_and_shared"], relic_pool_refs: ["available"], refresh_cost: 20 },
};

const config = {
  version: 1,
  classes: Object.fromEntries(classDefs.map(([id, name, family, unlock_order, unlock_type, unlock_param, starter_relic_id, starter_deck, shared_pool_refs, recommended_difficulty, enabled_in_first_playable, summary, color]) => [id, { id, name, family, unlock_order, unlock_type, unlock_param, starter_relic_id, starter_deck, shared_pool_refs, recommended_difficulty, enabled_in_first_playable, summary, color }])),
  cards: Object.fromEntries(cards.map((c) => [c.id, c])),
  relics: Object.fromEntries(relics.map((r) => [r.id, r])),
  enemies: Object.fromEntries(enemies.map((e) => [e.id, e])),
  encounters: Object.fromEntries(encounters.map((e) => [e.id, e])),
  map_nodes: Object.fromEntries(mapNodes.map((n) => [n.id, n])),
  events: Object.fromEntries(events.map((e) => [e.id, e])),
  statuses: Object.fromEntries(statuses.map((s) => [s.id, s])),
  meta_upgrades: Object.fromEntries(metaUpgrades.map((m) => [m.id, m])),
  effect_groups: effectGroups,
  effect_entries: Object.fromEntries(effectEntries.map((e) => [e.id, e])),
  intent_groups: intentGroups,
  phase_groups: phaseGroups,
  reward_profiles: rewardProfiles,
  shop_pools: shopPools,
};

fs.writeFileSync(path.join(dataOut, "game_config.json"), JSON.stringify(config, null, 2));

function csvEscape(v) {
  if (Array.isArray(v) || typeof v === "object") v = JSON.stringify(v);
  v = String(v ?? "");
  return /[",\n]/.test(v) ? `"${v.replaceAll('"', '""')}"` : v;
}
function csvType(rows, col) {
  const values = rows.map((row) => row[col]).filter((value) => value !== undefined && value !== null && value !== "");
  if (values.length === 0) return "string";
  if (values.every((value) => typeof value === "boolean")) return "bool";
  if (values.every((value) => Number.isInteger(value))) return "int";
  if (values.some((value) => Array.isArray(value) || (typeof value === "object" && value !== null))) return "json";
  return "string";
}
function writeCsv(name, rows, cols) {
  const lines = [
    cols.join(","),
    cols.map((c) => csvType(rows, c)).join(","),
    cols.map(() => "c").join(","),
    cols.map((c) => `## ${c}`).join(","),
    ...rows.map((r) => cols.map((c) => csvEscape(r[c])).join(",")),
  ];
  fs.writeFileSync(path.join(tablesOut, `${name}.csv`), lines.join("\n") + "\n");
}
const tableDefs = [
  ["ClassDef", Object.values(config.classes), ["id", "name", "family", "unlock_order", "unlock_type", "unlock_param", "starter_relic_id", "starter_deck", "shared_pool_refs", "recommended_difficulty", "enabled_in_first_playable", "summary", "color"]],
  ["CardDef", Object.values(config.cards), ["id", "name", "class_tags", "rarity", "type", "cost", "target_type", "keywords", "effect_group_id", "upgrade_to", "enabled_in_first_playable", "description", "art_path"]],
  ["RelicDef", Object.values(config.relics), ["id", "name", "allowed_classes", "rarity", "trigger_list", "effect_group_id", "shop_weight", "description", "art_path"]],
  ["EnemyDef", Object.values(config.enemies), ["id", "name", "chapter_tags", "base_hp", "intent_group_id", "phase_group_id", "reward_profile_id", "description", "art_path"]],
  ["EncounterDef", Object.values(config.encounters), ["id", "chapter", "node_type", "enemy_ids", "weight", "min_floor", "max_floor"]],
  ["MapNodeDef", Object.values(config.map_nodes), ["id", "chapter", "node_type", "weight", "can_repeat", "reward_profile_id"]],
  ["EventDef", Object.values(config.events), ["id", "name", "chapter_tags", "allowed_classes", "text", "options", "weight"]],
  ["StatusDef", Object.values(config.statuses), ["id", "name", "stack_rule", "timing_hooks", "effect_group_id", "max_stack", "is_hidden", "type"]],
  ["MetaUpgradeDef", Object.values(config.meta_upgrades), ["id", "type", "name", "cost_curve", "max_level", "effect_group_id", "prerequisite_ids", "description"]],
  ["EffectGroupDef", Object.values(config.effect_groups), ["id", "entry_ids"]],
  ["EffectEntryDef", Object.values(config.effect_entries), ["id", "effect_group_id", "order", "effect_type", "target_type", "params"]],
  ["EnemyIntentGroupDef", Object.values(config.intent_groups), ["id", "intent_entries"]],
  ["PhaseGroupDef", Object.values(config.phase_groups), ["id", "enemy_id", "phase_entries"]],
  ["RewardProfileDef", Object.values(config.reward_profiles), ["id", "card_pool_ref", "relic_pool_ref", "currency_range"]],
  ["ShopPoolDef", Object.values(config.shop_pools), ["id", "card_pool_refs", "relic_pool_refs", "refresh_cost"]],
];

for (const [name, rows, cols] of tableDefs) {
  writeCsv(name, rows, cols);
}

const manifest = ["name,file", ...tableDefs.map(([name]) => `${name},Datas/${name}.csv`)].join("\n") + "\n";
fs.writeFileSync(path.join(root, "DataTables", "__tables__.csv"), manifest);

const lubanConf = {
  groups: [
    {
      name: "client",
      default: true,
      tables: tableDefs.map(([name]) => ({ name, input: `Datas/${name}.csv` })),
    },
  ],
};
fs.writeFileSync(path.join(root, "DataTables", "luban.conf"), `${JSON.stringify(lubanConf, null, 2)}\n`);
console.log(`Generated ${Object.keys(config.cards).length} cards, ${Object.keys(config.enemies).length} enemies, ${Object.keys(config.events).length} events.`);
