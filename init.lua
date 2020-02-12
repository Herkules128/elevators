elevators = {}
elevators.modpath = minetest.get_modpath("elevators")

-- topspeed in blocks per second (default=10)
top_speed = 10

-- bigger values = faster acceleration (default 0.20)
time_to_accelerate = 0.20

dofile(elevators.modpath.."/elevator_entity.lua")
dofile(elevators.modpath.."/elevator_rails.lua")
