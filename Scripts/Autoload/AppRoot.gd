extends Node

const ContentResolverScript := preload("res://Scripts/Services/ContentResolver.gd")

var config_service: ConfigService
var content_resolver
var save_service: SaveService
var meta_service: MetaProgressionService
var map_service: MapService
var reward_service: RewardService
var effect_executor: EffectExecutor
var battle_service: BattleService
var run_session: RunSession
var flow_controller: FlowController

func _ready() -> void:
	boot()

func boot() -> void:
	if config_service != null:
		return
	config_service = ConfigService.new()
	config_service.load_config()
	content_resolver = ContentResolverScript.new()
	content_resolver.setup(config_service)
	save_service = SaveService.new()
	meta_service = MetaProgressionService.new()
	meta_service.setup(save_service, config_service)
	map_service = MapService.new()
	map_service.setup(config_service)
	reward_service = RewardService.new()
	reward_service.setup(content_resolver, map_service, meta_service)
	effect_executor = EffectExecutor.new()
	effect_executor.setup(config_service)
	battle_service = BattleService.new()
	battle_service.setup(content_resolver, effect_executor)
	run_session = RunSession.new()
	run_session.setup(config_service, map_service, meta_service)
	flow_controller = FlowController.new()

func reset_run() -> void:
	run_session.clear()
	if battle_service != null:
		battle_service.clear()
