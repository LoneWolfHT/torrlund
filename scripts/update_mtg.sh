#!/bin/bash
# Taken from my CTF script

MOD_PREFIX=mtg_
MODS_TO_KEEP=(creative player_api screwdriver sfinv)

cd ./mods/mtg/ && {
	git clone git@github.com:minetest/minetest_game.git

	mv ./minetest_game/mods .
	rm -rf ./minetest_game/

	echo "Updating mods..."

	for mod in "${MODS_TO_KEEP[@]}"; do
		rm -r "./${MOD_PREFIX}${mod}/";
		mv "./mods/${mod}" "./${MOD_PREFIX}${mod}";
	done

	echo "Done. Removing unneeded folders..."

	rm -r ./mods/

	echo "Done. minetest_game mods are updated!"
}
