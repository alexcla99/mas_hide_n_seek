/**
* Name: projetsma
* Based on the internal empty template. 
* Author: alexcla_ineslhd
* Tags: 
*/

model projetsma

// Model definition
global {
	
	// Parameters
	file csv_handler <- csv_file("../includes/map_0.csv", ",");
	int nb_hiding_init <- 2 parameter: "Number of hiding agents" min: 1 max: 10 step: 1;
	int nb_seeking <- 2 parameter: "Number of seekeing agents" min: 1 max: 10 step: 1;
	int timer_start <- 3 parameter: "Seeking agents start delay" min: 1 max: 10 step: 1; // time until the seekers start looking for something to catch
	int field_view <- 1 parameter: "Seeking agents view distance" min: 1 max: 5 step: 1;
	int starting_point_x <- 5;
	int starting_point_y <- 5;
	int nb_hiding <- nb_hiding_init;
	float seekers_flip_proba <- 15/20 parameter: "Proba to go on a random location (seeker agent)" min: 0.0 max: 1.0 step: 1/20;
	float hiding_flip_proba <- 15/20 parameter: "Proba to go on a random location (hiding agent)" min: 0.0 max: 1.0 step: 1/20;
	
	// Stop the simulation when there's nothing to catch
	// -- Does not work with multiple experiments, they have to be stopped manually --
	/*reflex stop_simulation when: (nb_hiding = 0) {
		do pause;
	}*/
	
	// Initiation
	init {
		matrix data <- matrix(csv_handler);
		// Get the cells where agents can move
		list<cell> white_cells <- [];
		ask cell {
			grid_value <- float(data[grid_x, grid_y]);
			do update_color;
			if color = #white {
				add (cell grid_at {grid_x, grid_y}) to: white_cells;
			}
		}
		// Create the agents
		create hiding_agent number: nb_hiding_init;
		create seeking_agent number: nb_seeking;
	}
	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Labyrith definition
grid cell width: 11 height: 11 {
	
	list<cell> neighbors <- (self neighbors_at 1); // cases voisines
	
	action update_color {
		color <- (grid_value = 1) ? # black : #white; // les agents peuvent circuler sur les cases blanches
	}
	
	bool is_hiding_place {
		// si une case est entourée de 3 cases noires, alors c'est une recoin -> une cachette
		return length(neighbors where (each.color = #black)) = 3;
	}
	
}

// Main class of players
species player_agent {
	
	rgb color;
	cell current_cell; // The current agent's cell
	list<cell> possible_cells; // The white cells around it
	
	init {
		current_cell <- cell[starting_point_x, starting_point_y];
		location <- current_cell.location;
		possible_cells <- current_cell.neighbors where (each.color = #white);
	}
	
	aspect asp_circle {
		draw circle(3.0) color: color border: #black; 
	}
	
	cell choose_cell {
		return nil;
	}
	
	reflex move {
		return nil;
	}
	
}

// Seekers definition
species seeking_agent skills: [moving] parent: player_agent{
	
	int number_caught <- 0; // Number of players caught by the seekeing agent
	rgb color <- #red;
	
	reflex move when: time > timer_start { // The agents start to seek after a delay
		current_cell <- choose_cell() ;
		possible_cells <- current_cell.neighbors where (each.color = #white);
    	location <- current_cell.location ;
	}
	
	cell choose_cell {
		// We move the farthest possible in order to avoid seeking on the same location
		// Else we move farthest from the center, or sometimes randomly to explore recesses
		if length(seeking_agent at_distance field_view) > 0 {
			return one_of(possible_cells with_max_of (each distance_to (seeking_agent closest_to self)));
		} else {
			return flip (seekers_flip_proba) ? possible_cells with_max_of (each distance_to cell[starting_point_x, starting_point_y]): one_of(possible_cells);  
		}
    }
    
	reflex catch_agent {
		// If some players are in the view distance, they are caught (eg. they "die")
		list<hiding_agent> caught_agents <- hiding_agent at_distance field_view;
		if(! empty(caught_agents)) {
			number_caught <- number_caught + length(caught_agents); 
			ask caught_agents {
				nb_hiding <- nb_hiding - 1;
				do die;
			}
		}
	}
	
}

// Hidings definition
species hiding_agent skills: [moving] parent: player_agent {
	
	rgb color <- #blue;
	
	cell choose_cell {
		if current_cell.neighbors one_matches each.is_hiding_place() {
			// Go on the farthest recess from the center
    		return (current_cell.neighbors where each.is_hiding_place()) with_max_of (each distance_to cell[starting_point_x, starting_point_y]);
		} else {
			// Else explore the map (while being as far as possible from the center) 
			return flip (hiding_flip_proba) ? possible_cells with_max_of (each distance_to cell[starting_point_x, starting_point_y]): one_of(possible_cells);
    	}
	}
	
	reflex move {	
		// We move while we do not have found any recess
    	if ! current_cell.is_hiding_place() {	
    		current_cell <- choose_cell();
			possible_cells <- current_cell.neighbors where (each.color = #white);
    		location <- current_cell.location ;
    	}
	}
	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Display of main experiment
experiment main type: gui {
	
	// Generating the others simulations
	init {
		loop i over: [1, 2] { // Maps "map_1" and "map_2"
			create simulation with:[csv_handler::csv_file("../includes/map_" + i + ".csv", ",")];
		}
	}
	
	// Combined chart
	permanent {
		// Current number of hiding agents
		display temporal_serie {
			chart "Hiding agents" type: series {
				loop s over: simulations {
					data "Remaining number of hiding agents (map " + int(s) + ")" value: s.nb_hiding color: s.color marker: false style: line thickness: 5;
				}
			}
		}
	}
	
	// Split output
	output {
		layout #split;
		display grid_display {
			grid cell;
			species hiding_agent aspect: asp_circle;
			species seeking_agent aspect: asp_circle;
		}
	}

}