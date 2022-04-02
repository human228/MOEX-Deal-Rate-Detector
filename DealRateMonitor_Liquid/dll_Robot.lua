prevSecValue = 0
prevMinValue = 0
prevHourValue = 0

currentSecValue = 0
currentMinValue = 0
currentHourValue = 0

currentTime = 0

-- Менять при компиляции --
local IS_LUQID_ROBOT = true
-----------------------------

------Максимальные периуды--------
local MAX_1M_PERIOD_SIZE = 6 -- 6 секунд по 10 секунд за тик
local MAX_3M_PERIOD_SIZE = 6 -- 30 секунд по 6 секунд за тик
local MAX_5M_PERIOD_SIZE = 5 -- 5 периудов по 1 минуте
local MAX_10M_PERIOD_SIZE = 10 -- 10 минут по 1 минутке за тик
--##############################-

local offSpeed = 5/100

local tickStepSize = 0.01
local tickTimeUpdate = 10 -- 20 секунд

local function getCurrentDealValue(ticker_id)
	local tradeValue = getParamEx(Class, Emitents[ticker_id][Columns._Ticker], "NUMTRADES").param_value
	-- message("called 3 " .. tradeValue)
	return tonumber(tradeValue)
end


local function addElementToList(src, v, perioudSize)
    if (#src == perioudSize) then
        table.remove(src, 1)
    end
    

    table.insert(src, v)

end

function Body() -- Основные вычисления
	currentTime = getInfoParam("SERVERTIME")
	currentHourValue, currentMinValue, currentSecValue = currentTime:match("(%d+):(%d+):(%d+)")

	if (Timer > 0) then
		Timer = Timer - 1
		PutDataToTableTimer()
		sleep(1000)
		return
	end


	local ServerTime = getInfoParam("SERVERTIME")
	if (ServerTime == nil or ServerTime == "") then
		Problem = "Server time not received!"
		Timer = 3
		return 
	else
		Problem = ""
	end

	if (IsWindowClosed(TableID)) then
		CreateWindow(TableID)
		PutDataToTableInit()
	end

		-- Callback update
		if currentHourValue ~= prevHourValue then
			OnOneHourUpdate(currentHourValue)
			prevHourValue = currentHourValue
		end
	
		if currentMinValue ~= prevMinValue then
			OnOneMinUpdate(currentMinValue)
			prevMinValue = currentMinValue
		end
	
		OnOneSecUpdate(currentSecValue)
		prevSecValue = currentSecValue
	
		updateAllCells()
		-- updateStartPosition()

	sleep(1000)
end

-- Callbacks
function OnOneHourUpdate(dHour)

end

function OnOneMinUpdate(dMin)

	-- if (tonumber(currentHourValue) == 7 and (tonumber(currentHourValue) <= 8)) or (tonumber(currentHourValue) >= 10 and (tonumber(currentHourValue) <= 12)) then
		if (tonumber(dMin) % 5 == 0) then
			for i=1, #Emitents do
				resetAccumulationValue(i)
				Emitents[i][Columns._TickUpdateCount] = 0
			end
		end
	-- end

end


-- В 7:00 -> 7:10 и 10:00 -> 11:00 совершаются большие кол-во сделок и в таблице сложно разобраться, поэтому нужно обнулять значение чтобы видеть
-- текущую скорость
function resetAccumulationValue(ticker_id)
	Emitents[ticker_id][Columns._Accumulation] = 0
end

function OnOneSecUpdate(dSec)
	-- срабатывает каждую секунду
	-- Сбрасывание TickUpdateCount каждую минуту.
	-- Обновление каждые 3 секунды
	if dSec % tickTimeUpdate == 0 then
		-- Сбрасывание TickUpdateCount каждые 30 секунд.
		for i=1, #Emitents do
			if Emitents[i][Columns._TickUpdateCount] > 0 then 
				Emitents[i][Columns._TickUpdateCount] = Emitents[i][Columns._TickUpdateCount] - tickStepSize
				if Emitents[i][Columns._TickUpdateCount] < 0 then Emitents[i][Columns._TickUpdateCount] = 0 end
			end		
		end
	end

	if (tonumber(currentHourValue) >= 19) then
		offSpeed = 1/200
	else
		offSpeed = 5/100
	end

		for i = 1, #Emitents do
			local newV = nil
			local v = getCurrentDealValue(i)

			if (Emitents[i][Columns._OldDealValue] == 0) then Emitents[i][Columns._OldDealValue] = 0.00001 end

			if (v - Emitents[i][Columns._OldDealValue] <= 1) then
				newV = Emitents[i][Columns._Accumulation] - Emitents[i][Columns._Accumulation] * offSpeed
				if newV < 0 then newV = 0 end
				Emitents[i][Columns._Accumulation] = math.floor(newV*100)/100
				Emitents[i][Columns._OldSpeedVolue] = Emitents[i][Columns._OldSpeedVolue] - Emitents[i][Columns._OldSpeedVolue] * 1/100

				if Emitents[i][Columns._OldSpeedVolue] < 0 then Emitents[i][Columns._OldSpeedVolue] = 0 end

			else
				local speedV = ((v - Emitents[i][Columns._OldDealValue]) / Emitents[i][Columns._OldDealValue]) * 100

				if speedV < 0 then speedV = 0 end
					if Emitents[i][Columns._OldSpeedVolue] + Emitents[i][Columns._OldSpeedVolue] * 1/2 < speedV then
						if Emitents[i][Columns._Accumulation] >= 0.3  then
							-- Red
							Highlight(TableID, i,  QTABLE_NO_INDEX, RGB(255, 0, 0), RGB(255, 255, 255), 700)
							Emitents[i][Columns._TickUpdateCount] = Emitents[i][Columns._TickUpdateCount] + tickStepSize
							WriteToEndOfFile(FileData,  Emitents[i][Columns._Ticker] .. ";" .. Emitents[i][Columns._TickUpdateCount])
						elseif Emitents[i][Columns._Accumulation] >= 0.1 then
							-- Green
							Highlight(TableID, i,  QTABLE_NO_INDEX, RGB(76, 153, 0), RGB(255, 255, 255), 500)
							Emitents[i][Columns._TickUpdateCount] = Emitents[i][Columns._TickUpdateCount] + tickStepSize
							WriteToEndOfFile(FileData,  Emitents[i][Columns._Ticker] .. ";" .. Emitents[i][Columns._TickUpdateCount])
						end
					end
					newV = Emitents[i][Columns._Accumulation] + speedV
					Emitents[i][Columns._OldSpeedVolue] = speedV
				
	
				Emitents[i][Columns._Accumulation] = math.floor(newV*100)/100
				Emitents[i][Columns._OldDealValue] = v
				
				if Emitents[i][Columns._Accumulation] < 0 then
					Emitents[i][Columns._Accumulation] = 0
				end
			end

		end

end


function updateAllCells()
	for i = 1, #Emitents do
		SetCell(TableID, i, Columns._Accumulation, tostring(Emitents[i][Columns._Accumulation]))
		SetCell(TableID, i, Columns._TickUpdateCount, tostring(Emitents[i][Columns._TickUpdateCount]))
	end
end

function PutDataToTableTimer()
	SetCell(TableID, 1, 3, Problem)
	Highlight(TableID, 1,  QTABLE_NO_INDEX, RGB(0, 20, 255), RGB(255, 255, 255), 500)
end

-- Инициализация таблицы при первом запуске
function EmitentsInitialization()
	for i = 1, #Emitents do
		Emitents[i][Columns._OldDealValue] = getCurrentDealValue(i)
	end
end


function PutDataToTableInit()
	--Clear(TableID)
	SetWindowPos(TableID, 100, 200, 500, 300)
	SetWindowCaption(TableID, "DealRateMonitor | Liquid Market")

	----------------------[Инициализация инструментов]---------------
	for i = 1, #Emitents do
		InsertRow(TableID, -1)
		SetCell(TableID, i, Columns._Ticker, Emitents[i][Columns._Ticker])
		Emitents[i][Columns._OldDealValue] = getCurrentDealValue(i)

		SetCell(TableID, i, Columns._Accumulation, tostring(Emitents[i][Columns._Accumulation]))
		SetCell(TableID, i, Columns._TickUpdateCount, tostring(Emitents[i][Columns._TickUpdateCount]))
	end
end

function WriteToEndOfFile(sFile, sDataString)
	local serverTime = getInfoParam("SERVERTIME")
	local serverData = getInfoParam("TRADEDATE")
	sDataString = serverData..";"..serverTime..";"..sDataString.."\n"
	local f = io.open(sFile, "r+")
	if (f == nil) then
		f = io.open(sFile, "w")
	end
	if (f ~= nil) then
		f:seek("end", 0) -- устанавливает в определенном месте файла курсор
		f:write(sDataString)
		f:flush() -- сохранение
		f:close()
	end
end
