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

# Various implementations of `GameReactor` can be found here.
module reactors

import events

redef class Game
	redef fun init_default_reactors do
		super
		add_reactor(new PlayerReactor)
	end
end

# Reacts to event that can affect players (like giving nitcoins).
class PlayerReactor
	super GameReactor

	# Nitcoins rewarded when the player opens a new pull request.
	var nc_pull_open = 10

	# Nitcoins rewarded when the player reviews a pull request.
	var nc_pull_review = 2

	# Nitcoins rewarded when the player has a commit merged.
	var nc_commit_merged = 1

	redef fun react_event(game, e) do e.react_player_event(self, game)
end

redef class GithubEvent
	# Reacts to a player related event.
	#
	# Called by `PlayerReactor::react_event`.
	# No-op by default.
	private fun react_player_event(reactor: PlayerReactor, game: Game) do end

	# Generates a GameEvent preinitialized for a reward event.
	private fun player_reward_event(kind: String, player: Player, reward: Int, time: nullable ISODate): GameEvent do
		var obj = new JsonObject
		obj["player"] = player.name
		obj["reward"] = reward
		obj["github_event"] = json
		var event = new GameEvent(player.game, kind, obj)
		if time != null then event.time = time
		player.game.add_event(event)
		return event
	end
end

redef class IssuesEvent

	# Rewards player for opened pull requests.
	redef fun react_player_event(r, game) do
		if not issue.is_pull_request then return
		var pull = game.api.load_pull(game.repo, issue.number)
		if pull == null then return
		if action == "opened" or action == "reopened" then
			react_pull_open(r, game, pull)
		else if action == "closed" then
			react_pull_close(r, game, pull)
		end
	end

	private fun react_pull_open(r: PlayerReactor, game: Game, pull: PullRequest) do
		var player = pull.user.player(game)
		player.nitcoins += r.nc_pull_open
		player.save
		var event = player_reward_event("pull_open", player, r.nc_pull_open, pull.created_at)
		player.add_event(event)
	end

	private fun react_pull_close(r: PlayerReactor, game: Game, pull: PullRequest) do
		var player = pull.user.player(game)
		var reward
		var event
		if pull.merged then
			reward = pull.commits * r.nc_commit_merged
			event = player_reward_event("pull_merged", player, reward, pull.merged_at)
		else
			reward = -r.nc_pull_open
			event = player_reward_event("pull_closed", player, reward, pull.closed_at)
		end
		player.nitcoins += reward
		player.save
		player.add_event(event)
	end
end

redef class IssueCommentEvent

	# Rewards player for review comments.
	#
	# TODO only give nitcoins if reviewers < 2
	# TODO give more points to first reviewer
	redef fun react_player_event(r, game) do
		if comment.is_ack then
			react_player_review(r, game)
		end
	end

	# TODO same player should not be authorized to review multiple times? How to handle rerols?
	private fun react_player_review(r: PlayerReactor, game: Game) do
		if issue.state == "closed" then return
		var player = comment.user.player(game)
		if issue.user == player.user then return
		player.nitcoins += r.nc_pull_review
		player.save
		var event = player_reward_event("pull_review", player, r.nc_pull_review, comment.updated_at)
		player.add_event(event)
	end
end
