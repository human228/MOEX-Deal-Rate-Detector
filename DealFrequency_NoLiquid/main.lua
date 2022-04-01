dofile(getScriptPath().."\\dataStorage.lua")
dofile(getScriptPath().."\\dll_Robot.lua")


is_run = true
Timer = 3
FileLog = getScriptPath().."\\BOT1_LOG.txt"
someData = os.date("%Y-%m-%d")
FileData = getScriptPath().."\\BOT1_DATA " .. someData .. ".txt"
Problem = ""

-----------------------------------
Class = "TQBR"

Columns = {
	_Ticker = 1,
	_Accumulation = 2,
	_OldDealValue = 3,
	_OldSpeedVolue = 4,
	_TickUpdateCount = 5
}


EmitentsSize = 35

function OnInit()
	TableID = AllocTable() 
	AddColumn(TableID, Columns._Ticker, "Ticker", true, QTABLE_STRING_TYPE, 15)
	AddColumn(TableID, Columns._Accumulation, "Grow Speed", true, QTABLE_STRING_TYPE, 15)
	AddColumn(TableID, Columns._TickUpdateCount, "Tick Count", true, QTABLE_STRING_TYPE, 15)
		
	CreateWindow(TableID)
	-- EmitentsInitialization()
	PutDataToTableInit()

	WriteToEndOfFile(FileLog, "Bot started")
end

function main()
	while is_run == true do
		Body()
	end
end


function OnStop()
	is_run = false
	DestroyTable(TableID)
	WriteToEndOfFile(FileLog, "Bot stopped")
end


