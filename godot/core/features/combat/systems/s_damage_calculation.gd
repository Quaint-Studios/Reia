class_name DamageCalculationSystem extends System

func query():
	return q.with_all([C_Health, C_DamageEvent]).with_none([C_Dead])

func process(entities: Array[Entity], _components: Array, _delta: float):
	for entity in entities:
		var health := entity.get_component(C_Health) as C_Health
		var damage_event := entity.get_component(C_DamageEvent) as C_DamageEvent
		
		health.current -= damage_event.amount
		
		if health.current <= 0:
			health.current = 0
			cmd.add_component(entity, C_Dead.new())
			
		# Consume the event so it doesn't process again next frame
		cmd.remove_component(entity, C_DamageEvent)
