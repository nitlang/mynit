# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2014-2015 Alexandre Terrasa <alexandre@moz-code.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# `nitrpg` game structures.
#
# Here we define the main game entities:
#
# * `Game` holds all the entities for a game and provides high level services.
# * `Player` represents a `Github::User` which plays the `Game`.
#
# Developpers who wants to extend the game capabilities should look at
# the `GameReactor` abstraction.
module game

import mongodb
import github::api

# An entity within a `Game`.
#
# All game entities can be saved in a json format.
interface GameEntity
	# The game instance containing `self`.
	fun game: Game is abstract

	# Collection `self` should be saved in.
	fun collection_name: String is abstract

	# Uniq key of this entity within the collection.
	fun key: String is abstract

	# Saves `self` in db.
	fun save do game.db.collection(collection_name).save(to_json)

	# Json representation of `self`.
	fun to_json: JsonObject do
		var json = new JsonObject
		json["_id"] = key
		return json
	end

	# Pretty print `self` to be displayed in a terminal.
	fun pretty: String is abstract
end

# Holder for game data and main services.
#
# Game is a `GameEntity` so it can be saved.
class Game
	super GameEntity

	redef fun game do return self

	# We need a `GithubAPI` client to load Github data.
	var api: GithubAPI

	# A game takes place in a `github::Repo`.
	var repo: Repo

	# Game name
	var name: String = repo.full_name is lazy

	redef var key = name is lazy

	# Mongo server url where this game data are stored.
	var mongo_url = "mongodb://localhost:27017" is writable

	# Mongo db client.
	var client = new MongoClient(mongo_url) is lazy

	# Mongo db name where this game data are stored.
	var db_name = "nitrpg" is writable

	# Mongo db instance for this game.
	var db: MongoDb is lazy do return client.database(db_name)

	redef var collection_name = "games"

	# Init the Game and try to load saved data.
	init from_mongo(api: GithubAPI, repo: Repo) do
		init(api, repo)
		var req = new JsonObject
		req["name"] = repo.full_name
		var res = db.collection("games").find(req)
		if res != null then from_json(res)
	end

	# Init `self` from a JsonObject.
	#
	# Used to load entities from saved data.
	fun from_json(json: JsonObject) do end

	redef fun to_json do
		var json = super
		json["name"] = name
		return json
	end

	# Create a player from a Github `User`.
	#
	# Or return the existing one from game data.
	fun add_player(user: User): Player do
		# check if player already exists
		var player = load_player(user.login)
		if player != null then return player
		# create and store new player
		player = new Player(self, user.login)
		player.save
		return player
	end

	# Get a Player from his `name` or null if no player was found.
	#
	# Looks for the player save file in game data.
	#
	# Returns `null` if the player cannot be found.
	# In this case, the player can be created with `add_player`.
	fun load_player(name: String): nullable Player do
		var req = new JsonObject
		req["name"] = name
		req["game"] = game.key
		var res = db.collection("players").find(req)
		if res != null then return new Player.from_json(self, res)
		return null
	end

	# List known players.
	#
	# This list is reloaded from game data each time its called.
	#
	# To add players see `add_player`.
	fun load_players: MapRead[String, Player] do
		var req = new JsonObject
		req["game"] = game.key
		var res = new HashMap[String, Player]
		for obj in db.collection("players").find_all(req) do
			var player = new Player.from_json(self, obj)
			res[player.name] = player
		end
		return res
	end

	# Return a list of player name associated to their rank in the game.
	fun player_ranking: MapRead[String, Int] do
		var arr = load_players.values.to_a
		var res = new HashMap[String, Int]
		(new PlayerCoinComparator).sort(arr)
		var rank = 1
		for player in arr do
			res[player.name] = rank
			rank += 1
		end
		return res
	end

	# Erase all saved data for this game.
	fun clear do db.collection(collection_name).remove(to_json)

	# Verbosity level used fo stdout.
	#
	# * `-1` quiet
	# * `0` error and warnings
	# * `1` info
	# * `2` debug
	var verbose_lvl = 0 is writable

	# Display `msg` if `lvl` >= `verbose_lvl`
	fun message(lvl: Int, msg: String) do
		if lvl > verbose_lvl then return
		print msg
	end

	redef fun pretty do
		var res = new FlatBuffer
		res.append "-------------------------\n"
		res.append "{repo.full_name}\n"
		res.append "-------------------------\n"
		res.append "# {load_players.length} players \n"
		return res.write_to_string
	end
end

# Players can battle on nitrpg for nitcoins and glory.
#
# A `Player` is linked to a `Github::User`.
class Player
	super GameEntity

	# Stored in collection `players`.
	redef var collection_name = "players"

	redef var game

	# FIXME contructor should be private

	# Player name.
	#
	# This is the unic key for this player.
	# Should be equal to the associated `Github::User::login`.
	#
	# The name is also used to load the user data lazilly from Github API.
	var name: String

	redef var key = name is lazy

	# Player amount of nitcoins.
	#
	# Nitcoins is the currency used in nitrpg.
	# They can be obtained by performing actions on the `Game::Repo`.
	var nitcoins: Int = 0 is public writable

	# `Github::User` linked to this player.
	var user: User is lazy do
		var user = game.api.load_user(name)
		assert user isa User
		return user
	end

	# Init `self` from a `json` object.
	#
	# Used to load players from saved data.
	init from_json(game: Game, json: JsonObject) do
		init(game, json["name"].as(String))
		nitcoins = json["nitcoins"].as(Int)
	end

	redef fun to_json do
		var json = super
		json["game"] = game.key
		json["name"] = name
		json["nitcoins"] = nitcoins
		return json
	end

	redef fun pretty do
		var res = new FlatBuffer
		res.append "-- {name} ({nitcoins} $)\n"
		return res.write_to_string
	end

	redef fun to_s do return name
end

redef class User
	# The player linked to `self`.
	fun player(game: Game): Player do
		var player = player_cache.get_or_null(game)
		if player != null then return player
		player = game.load_player(login)
		if player == null then player = game.add_player(self)
		player_cache[game] = player
		return player
	end

	private var player_cache = new HashMap[Game, Player]
end

# utils

# Sort games by descending number of players.
#
# The first in the list is the game with the more players.
class GamePlayersComparator
	super Comparator

	redef type COMPARED: Game

	redef fun compare(a, b) do
		return b.load_players.length <=> a.load_players.length
	end
end

# Sort players by descending number of nitcoins.
#
# The first in the list is the player with the more of nitcoins.
class PlayerCoinComparator
	super Comparator

	redef type COMPARED: Player

	redef fun compare(a, b) do return b.nitcoins <=> a.nitcoins
end
