minetest.register_node("elevators:rail", {
	description = ("Elevator Rail"),
	tiles = {"elevator_rail.png"},
	walkable = false,
	paramtype = "light",
	sunlight_propagates = true,
	groups = {dig_immediate = 2},
	sounds = default.node_sound_metal_defaults(),
	drawtype = "nodebox",
    	node_box = {
        	 type = "fixed",
        	 fixed = {
		    			{-0.5, -0.5, -0.5, -(0.375), 0.5, -(0.375)},
            	       	{ (0.375), -0.5, -0.5,  0.5, 0.5, -(0.375)},
            	       	{-0.5, -0.5,  (0.375), -(0.375), 0.5,  0.5},
            	       	{ (0.375), -0.5,  (0.375),  0.5, 0.5,  0.5},			
        	 },
    	},
})






minetest.register_node("elevators:brakerail", {
	description = ("Elevator Brakerail"),
	tiles = {"elevator_brakerail_top.png", "elevator_brakerail_top.png", "elevator_brakerail.png"},
	walkable = false,
	paramtype = "light",
	sunlight_propagates = true,
	groups = {dig_immediate = 2},
	sounds = default.node_sound_metal_defaults(),
	drawtype = "nodebox",
    	node_box = {
        	 type = "fixed",
        	 fixed = {
		    			{-0.5, -0.5, -0.5, -(0.375), 0.5, -(0.375)},
            	       	{ (0.375), -0.5, -0.5,  0.5, 0.5, -(0.375)},
            	       	{-0.5, -0.5,  (0.375), -(0.375), 0.5,  0.5},
            	       	{ (0.375), -0.5,  (0.375),  0.5, 0.5,  0.5},
						
						{ -0.375, -0.0625,    -0.5,   0.375, 0.0625, -0.4375},
						{ -0.375, -0.0625,  0.4375,   0.375, 0.0625,     0.5},

						{   -0.5, -0.0625,  -0.375, -0.4375, 0.0625,   0.375},
						{ 0.4375, -0.0625,  -0.375,     0.5, 0.0625,   0.375},

        	 },
    	},
})






minetest.register_craft({
	type = "shaped",
	output = "elevators:rail 16",
	recipe = {
	       {'default:steel_ingot', '', 'default:steel_ingot'},
	       {'', '', ''},
	       {'default:steel_ingot', '', 'default:steel_ingot'}
	},
})






minetest.register_craft({
	type = "shaped",
	output = "elevators:brakerail 12",
	recipe = {
	       {'default:steel_ingot', '', 'default:steel_ingot'},
	       {'', 'default:coal_lump', ''},
	       {'default:steel_ingot', '', 'default:steel_ingot'}
	},
})

