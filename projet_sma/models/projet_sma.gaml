/**
* Name: projetsma
* Based on the internal empty template. 
* Author: alexcla_ineslhd
* Tags: 
*/

model projetsma

// Définition du modèle
global {
	file csv_handler <- csv_file("../includes/map_test.csv", ",");
	init {
		// Création du labyrinthe
		matrix data <- matrix(csv_handler);
		ask labyrinth {
			grid_value <- float(data[grid_x, grid_y]);
			write data[grid_x, grid_y];
		}
		// Positionnement des agents au centre
		// TODO
		// Exécution de ceux-ci
		// TODO
	}
}

// Définition du labyrinthe
grid labyrinth width: 11 height: 11 {
	reflex update_color {
		write grid_value;
		color <- (grid_value = 1) ? # black : #white;
	}
}

// Agent bleu (celui qui se cache)
species blue_agent {
	agent blue_a;
	// Recherche d'une planque
	reflex hide {
		// TODO
	}
}

// Agent rouge (celui qui cherche)
species red_agent {
	agent red_a;
	// Recherche de l'agent caché
	reflex seek {
		// TODO
	}
}

// Expérimentation principale
experiment main type: gui {
	output {
		display display_grid {
			grid labyrinth;
		}
	}
}