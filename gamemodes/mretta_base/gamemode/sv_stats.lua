module("mretta",package.seeall)

local sqlTables = {
	mretta_stats_minigames = {
		Id = "TEXT",
		DateFirstPlayed = "TEXT",
		Plays = "INTEGER",
		CompletedGames = "INTEGER",
		PointsScored = "INTEGER",
		VotesAppearedIn = "INTEGER",
		VotesFor = "INTEGER"
	},
	mretta_stats_maps = {
		Id = "TEXT",
		DateFirstPlayed = "TEXT",
		Plays = "INTEGER",
		CompletedGames = "INTEGER",
		PointsScored = "INTEGER",
		VotesAppearedIn = "INTEGER",
		VotesFor = "INTEGER"
	}
}

local function checkLibraries()
	if not istable(co) then
		ErrorNoHalt("Helper library/function for coroutines 'co' is not present in '_G'. Mretta Statistics are unavailable!")
		return false
	end

	if not istable(db) then
		ErrorNoHalt("Helper library for using PostgreSQL 'db' is not present in '_G'. Mretta Statistics are unavailable!")
		return false
	end

	return true
end

function TrackRefresh()
	if not checkLibraries() then return end

	co(function()
		-- Wait 4 ticks
		for i=1,4 do co.waittick() end

		for k,v in next,sqlTables do
			db.Query(("CREATE TABLE IF NOT EXISTS %s(Id TEXT NOT NULL PRIMARY KEY, DateFirstPlayed TEXT)"):format(k))

			local columns = ""
			local i,iEnd = 0,table.Count(v)

			for colName,colType in next,v do
				i = i+1

				columns = columns..("ADD COLUMN IF NOT EXISTS %s INTEGER DEFAULT 0"):format(colName)

				if i != iEnd then
					columns = columns..", "
				end
			end

			if columns != "" then
				db.Query(("ALTER TABLE %s %s"):format(k,columns))
			end
		end
	end)
end

function TrackMinigameStat(key,amountToAdd,minigame)
	if not checkLibraries() then return end

	if sqlTables.mretta_stats_minigames[key] != "INTEGER" then return end

	amountToAdd = amountToAdd or 1
	if amountToAdd <= 0 then return end

	minigame = minigame or engine.ActiveGamemode()

	db.Query(("SELECT %s FROM mretta_stats_minigames WHERE Id = '%s' LIMIT 1"):format(key,minigame),function(data)
		data = data and data[1]

		if not data then
			db.Query(("INSERT INTO mretta_stats_minigames(Id, DateFirstPlayed) VALUES('%s', '%s')"):format(minigame,os.date("%Y-%m-%d %H:%M:%S")),function()
				update(key,amountToAdd,minigame)
			end)

			return
		end

		update(key,tonumber(data[key])+amountToAdd,minigame)
	end)
end

function TrackMapStat(key,amountToAdd,map)
	if not checkLibraries() then return end

	if sqlTables.mretta_stats_maps[key] != "INTEGER" then return end

	amountToAdd = amountToAdd or 1
	if amountToAdd <= 0 then return end

	map = map or game.GetMap()

	db.Query(("SELECT %s FROM mretta_stats_maps WHERE Id = '%s' LIMIT 1"):format(key,map),function(data)
		data = data and data[1]

		local function update(_key,_add,_map)
			db.Query(("UPDATE mretta_stats_maps SET %s = %s WHERE Id = '%s'"):format(_key,_add,_map))
		end

		if not data then
			db.Query(("INSERT INTO mretta_stats_maps(Id, DateFirstPlayed) VALUES('%s', '%s')"):format(map,os.date("%Y-%m-%d %H:%M:%S")),function()
				update(key,amountToAdd,map)
			end)

			return
		end

		update(key,tonumber(data[key])+amountToAdd,map)
	end)
end

if util.OnInitialize then
	util.OnInitialize(TrackRefresh)
else
	hook.Add("InitPostEntity","mretta_stats",TrackRefresh)
end