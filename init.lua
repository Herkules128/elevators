elevators = {}
elevators.modpath = minetest.get_modpath("elevators")

-- topspeed in blocks per second (default = 10)
top_speed = 10

-- higher values lead to faster acceleration (default = 0.20)
time_to_accelerate = 0.20

-- allow other players to interrupt the driver (default = false)
eject_by_others = false



dofile(elevators.modpath.."/elevator_entity.lua")
dofile(elevators.modpath.."/elevator_rails.lua")
