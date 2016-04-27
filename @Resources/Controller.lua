function Initialize()
	inLen = RmGetUInt("BandCount", 25)
	if inLen <= 0 then inLen = 25 end

	iBarCount = RmGetUInt("BarCount", 200)
	if iBarCount <= 0 then iBarCount = 200 end

	-- Get all measures and put them in a table for fast access later on
	oMs = {}
	for i=1,inLen do
		oMs[i] = SKIN:GetMeasure("MsBand" .. i)
	end

	dataIn = {} -- Input data
	dataIn[inLen + 1] = 0 -- Create a zero value out of bounds to prevent errors
	dataOut = {} -- Output data
	for i=1,iBarCount do
		dataOut[i] = 0
	end

	ROI = 12 -- Region of influence
	avgWeight = 1/(ROI*2 + 1)
end

function Update()
	-- Get the input data
	for i=1,inLen do
		dataIn[i] = oMs[i]:GetValue()
	end

	-- Interpolate and average the new values
	for i=1,iBarCount do
		local y = 0
		local mapped = map(i, 1, iBarCount, 1, inLen)
		local cur = math.floor(mapped)
		local weight = mapped - cur
		
		dataOut[i] = dataOut[i]*0.2 + interpolate(weight, dataIn[cur], dataIn[cur + 1])*0.8
	end

	-- Average ROI bars forward and backward to create the smooth effect
	for i=1,iBarCount do
		local val = 0

		val = val + dataOut[i]

		for j=1,ROI do
			val = val + dataOut[ clip(i+j, 1, iBarCount) ]
			val = val + dataOut[ clip(i-j, 1, iBarCount) ]
		end

		SKIN:Bang("!SetOption", "MsCalc" .. i, "Formula", val * avgWeight)
	end
end

function interpolate(weight, v1, v2)
	return weight * (v2 - v1) + v1
end

function clip(var, min, max)
	if var < min then 
		return min
	elseif var > max then
		return max
	end

	return var
end

function map(nVar, nMin1, nMax1, nMin2, nMax2)
	return nMin2 + (nMax2 - nMin2) * ((nVar - nMin1) / (nMax1 - nMin1))
end

-- Returns a rainmeter variable rounded down to an integer
function RmGetInt(sVar, iDefault)
	return math.floor(SKIN:GetVariable(sVar, iDefault))
end
-- Returns a rainmeter variable rounded down to an integer, negative integers are converted to positive ones
function RmGetUInt(sVar, iDefault)
	return math.abs(RmGetInt(sVar, iDefault))
end