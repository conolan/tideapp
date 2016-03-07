local widget = require "widget"
local storyboard = require( "storyboard" )
storyboard.purgeOnSceneChange = true
local scene = storyboard.newScene()

-- The main tide screen. Reads in the xml file, creates the tide curve and overlay text
-- Also creates the text-ony info screen which has additional info
-- graph.calculateSections function could be a loop, but was created in an earlier version to accommodate different layout for first and last graph section

local http = require("socket.http")
local ltn12 = require("ltn12")
local thedate = require( "thedate" )

local graph = {}
local m_dates={}

local dayStrings={}
tideWeek={}
timeWeek={}
local tideText={}
local tideData={}
local tideList={}
local sunSet={}
local sunRise={}
local moonPhase={}
graph.graphPoints = {}
graph.numGraphPoints = 0
local myImage, infotext, graphWidth, tButton, tideLine, tideGroup, sunRiseTime, sunSetTime, currentTime, isToday
environment = system.getInfo( "environment" )
if environment == "simulator" then isPaid=true end

function string:split( inSplitPattern, outResults )

   if not outResults then
      outResults = {}
   end
   local theStart = 1
   local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
   while theSplitStart do
      table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
   end
   table.insert( outResults, string.sub( self, theStart ) )
   return outResults
end

function placeLoad()
	local path = system.pathForFile( "place.txt", system.DocumentsDirectory )
	local contents = ""
	local file = io.open( path, "r" )
	if ( file ) then
      -- Read all contents of file into a string
		local contents = file:read( "*a" )
		local myInfo=contents:split(",")
		io.close( file )
		return myInfo
	else
		local myInfo={"dublin",40}
		return (myInfo)
	end
end

local function readPurchase()
	local path = system.pathForFile( "myPurchase.txt", system.DocumentsDirectory )
	local contents = ""
	local file = io.open( path, "r" )
	if ( file ) then
      -- Read all contents of file into a string
		local contents = file:read( "*a" )
		if contents=="isPaid" then isPaid=true end
		io.close( file )
	else
		print("file not read")
	end
end

if theCity==nil then
	theInfo=placeLoad()
	theCity=theInfo[1]
	m_scale=tonumber(theInfo[2])
end

local function makeDate(date)
	if string.len(date)==1 then date="0"..date end
	return date
end

local function new_Vector(xComp, yComp)
	local vector = {}
	vector.x = xComp
	vector.y = yComp	
	return vector
end

local onSystem = function( event )
    if event.type == "applicationStart" then

    elseif event.type == "applicationExit" then

    elseif event.type == "applicationSuspend" then

    elseif event.type == "applicationResume" then
        storyboard.gotoScene("resume")
    end
end
-- setup a system event listener
Runtime:addEventListener( "system", onSystem )

---------------------------------------------------------------------------------------------------------------

graph.calculateSingleSection = function(tide1, tide2, pInterval, pPos, points)

	local numOfPoints = math.floor(pInterval/4);
	local point;
	local tempX = pPos.x;
	local tempY = pPos.y;

	for t = 1, numOfPoints do
		tempY = (( (tide1 + tide2)/2+(tide1-tide2)/2*math.cos((3.14/numOfPoints)*t) )*m_scale)

		point = new_Vector(tempX, pPos.y-tempY)
		points[graph.numGraphPoints] = point

		graph.numGraphPoints = graph.numGraphPoints+1
		tempX = tempX+pInterval/numOfPoints
	end
	
	return graph.numGraphPoints
end

graph.getHighest = function(tides)
	local highest = 0
	for i = 1, table.maxn(tides) do
		if tides[i].y > highest then
			highest = tides[i].y
		end
	end
	
	return highest
end

graph.getLowest = function(tides)
	local lowest = 100
	for i = 1, table.maxn(tides) do
		if tides[i].y < lowest then
			lowest = tides[i].y
		end
	end
	
	return lowest
end

graph.calculateSections = function(day)
	graph.graphPoints = {}
	graph.numGraphPoints = 0	

	local pointInterval=graph.timeToPixels(timeWeek[day][2])-graph.timeToPixels(timeWeek[day][1])+288

	graph.calculateSingleSection(tideWeek[day][1], tideWeek[day][2], pointInterval, new_Vector(m_position.x+graph.timeToPixels(timeWeek[day][1])-288, m_position.y), graph.graphPoints);

	local pointInterval=graph.timeToPixels(timeWeek[day][3])-graph.timeToPixels(timeWeek[day][2])

	graph.calculateSingleSection(tideWeek[day][2], tideWeek[day][3], pointInterval, new_Vector(m_position.x+graph.timeToPixels(timeWeek[day][2]), m_position.y), graph.graphPoints);

	local pointInterval=graph.timeToPixels(timeWeek[day][4])-graph.timeToPixels(timeWeek[day][3])

	graph.calculateSingleSection(tideWeek[day][3], tideWeek[day][4], pointInterval, new_Vector(m_position.x+graph.timeToPixels(timeWeek[day][3]), m_position.y), graph.graphPoints);
	
	if timeWeek[day][6]==nil then
	
		local pointInterval=graph.timeToPixels(timeWeek[day][5])-graph.timeToPixels(timeWeek[day][4])+288

		graph.calculateSingleSection(tideWeek[day][4], tideWeek[day][5], pointInterval, new_Vector(m_position.x+graph.timeToPixels(timeWeek[day][4]), m_position.y), graph.graphPoints);
	else
		local pointInterval=graph.timeToPixels(timeWeek[day][5])-graph.timeToPixels(timeWeek[day][4])

		graph.calculateSingleSection(tideWeek[day][4], tideWeek[day][5], pointInterval, new_Vector(m_position.x+graph.timeToPixels(timeWeek[day][4]), m_position.y), graph.graphPoints);
		
		local pointInterval=graph.timeToPixels(timeWeek[day][6])-graph.timeToPixels(timeWeek[day][5])+288

		graph.calculateSingleSection(tideWeek[day][5], tideWeek[day][6], pointInterval, new_Vector(m_position.x+graph.timeToPixels(timeWeek[day][5]), m_position.y), graph.graphPoints);
	end
end

graph.timeToPixels = function(pTime) 

	local minutes = pTime:sub(4,5)
	local hours = pTime:sub(1,2)
	-- 12 pixels per hour, 5 minutes per pixel.
	return (hours*12) + (minutes/5); 
end

graph.showText = function(day)
	local textGroup=display.newGroup()
	myImage = display.newImageRect("images/blankpage.png", 320,280)
	myImage.anchorX = 0
	myImage.anchorY = 0
	myImage.x = 0
	myImage.y =0
	textGroup:insert(myImage)
	
	local myName = display.newText(dayStrings[day], 10, 1, native.systemFont, 16)
	myName:setTextColor(1,1,1)
	myName.anchorX = 0
	myName.anchorY = 0
	myName.x=-(myName.width-320)/2
	textGroup:insert(myName)
	
	local texthead = display.newText("Time     Height(m)",160, 30, native.systemFont, 18)
	texthead:setTextColor(.7,.7,.7)
	texthead.anchorX = 0.5
	texthead.anchorY = 0.5
	textGroup:insert(texthead)
	
	local highest = tonumber(tideWeek[day][2])
	local lowest = tonumber(tideWeek[day][3])
	local range = display.newText("Range "..math.abs(highest-lowest), 160, 192, native.systemFont, 20)
	local midTide=math.abs(highest-lowest)
	
	for i=2,#timeWeek[day]-1 do
		local text = display.newText("",70, -15+i*36, native.systemFont, 30)
		
		if tonumber(tideWeek[day][i])> midTide then 
			text.text=text.text.."H "
			text:setTextColor(1,1,1)
		else
			text.text=text.text.."L "
			text:setTextColor(0,0,0)
		end
		text.text=text.text..tideText[day][i-1]
		text.x=160
		if string.len(tideText[day][i-1])==11 then text.text=text.text.."  " end
		
		textGroup:insert(text)
	end
	
	range.anchorX = 0.5
	range.anchorY = .5
	range:setTextColor(.7,.7,.9)
	textGroup:insert(range)
	
	local sunRise = display.newText("Sunrise "..sunRise[day], 160, 220, native.systemFont, 24)
	sunRise.anchorX = 0.5
	sunRise.anchorY = .5
	sunRise:setTextColor(1,1,1)
	textGroup:insert(sunRise)
	
	local sunSet = display.newText("Sunset "..sunSet[day], 160, 245, native.systemFont, 24)
	sunSet:setTextColor(1,1,1)
	sunSet.anchorX = 0.5
	sunSet.anchorY = .5
	textGroup:insert(sunSet)

		if moonPhase[day]~="*" then

			local moon = display.newImageRect("images/"..moonPhase[day]..".png", 50,50)

			moon.x=270
			moon.y=230
			textGroup:insert(moon)
		end
	
	return textGroup
end

graph.drawTideGraph = function(day)
	tideGroup=display.newGroup()
	myImageTop = display.newImageRect("images/graphhead.png", graphWidth,21)
	myImageTop.anchorX = 0
	myImageTop.anchorY = 0
	myImageTop.x = 0
	myImageTop.y =0
	tideGroup:insert(myImageTop)
	myImageEnd = display.newImageRect("images/graphend.png", graphWidth,37)
	myImageEnd.anchorX = 0
	myImageEnd.anchorY = 0
	myImageEnd.x = 0
	myImageEnd.y =225
	tideGroup:insert(myImageEnd)
	myImageMid = display.newImageRect("images/graphv.png", graphWidth-32,205)
	myImageMid.anchorX = 0
	myImageMid.anchorY = 0
	myImageMid.x = 16
	myImageMid.y =21
	tideGroup:insert(myImageMid)
	local myName = display.newText(dayStrings[day], 10, 1, native.systemFont, 16)
	myName:setTextColor(1,1,1)

	myName.anchorX = 0
	myName.anchorY = 0
	myName.x=-(myName.width-320)/2
	tideGroup:insert(myName)
	
	display.setDefault("lineColor",0,0,0)
	
	local rect = display.newRect(m_position.x ,21, graph.timeToPixels(sunRise[day]), 204,10)
	rect:setFillColor(0,0,0,0.3)
	rect.anchorX = 0
	rect.anchorY = 0
	tideGroup:insert(rect)
	
	local rect = display.newRect(m_position.x+graph.timeToPixels(sunSet[day]),21, graphWidth-graph.timeToPixels(sunSet[day])-m_position.x*2, 204,10)	
	tideGroup:insert(rect)
	rect:setFillColor(0,0,0,0.3)
	rect.anchorX = 0
	rect.anchorY = 0

	local highest = graph.getHighest(graph.graphPoints)
	local lowest = graph.getLowest(graph.graphPoints)
	
	if day==1 and isToday==true then
		local nowLineX=graph.timeToPixels(currentTime)+m_position.x
		local line = display.newLine(nowLineX,20,nowLineX,225)
		line:setStrokeColor(0,1,0,1)
		line.strokeWidth=4
		tideGroup:insert(line)
	end
	
	display.setDefault("lineColor",0.5,0.5,1)
	tideLine=display.newGroup()
	
	for i = 1, #graph.graphPoints-1 do

		if graph.graphPoints[i].x >= m_position.x-10 and graph.graphPoints[i+1].x <= (m_position.x)+290 then
--first graphpoint greater than left edge and second point less than right edge
			
			local line = display.newLine(graph.graphPoints[i].x, graph.graphPoints[i].y, graph.graphPoints[i+1].x, graph.graphPoints[i+1].y)
			line.strokeWidth=2
			line:setStrokeColor(45/256,119/256,219/256,1)
			tideLine:insert(line)
			
			pPoints={graph.graphPoints[i].x,226, graph.graphPoints[i].x, graph.graphPoints[i].y, graph.graphPoints[i+1].x, graph.graphPoints[i+1].y,graph.graphPoints[i+1].x,226}
			local poly=display.newPolygon( graph.graphPoints[i].x, 226,pPoints )
			poly:setFillColor( 45/256,119/256,219/256,0.5 )
			poly.anchorX = 0
			poly.anchorY = 1
			tideLine:insert(poly)
		end
		
	end

	tideGroup:insert(tideLine)
	tideLine.x=tideLine.x+2
	local rect = display.newRect(3,21,13,204)
	rect:setFillColor(60/256,131/256,204/256)
	rect.anchorX = 0
	rect.anchorY = 0
	tideGroup:insert(rect)
	
	local rect = display.newRect(304,21,13,204)
	rect:setFillColor(60/256,131/256,204/256)
	rect.anchorX = 0
	rect.anchorY = 0
	tideGroup:insert(rect)
	
	for i=4,0,-1 do
		local tideh = display.newText(i, 5, 200-(i*m_scale), native.systemFont, 14)
		tideh:setTextColor(1,1,1)
		tideh.anchorX = 0
		tideh.anchorY = 0
		tideGroup:insert(tideh)
	end
	
	local tide1a = display.newText(timeWeek[day][2], graph.timeToPixels(timeWeek[day][2]), -20, native.systemFont, 16)
	tide1a:setTextColor(1,1,1)
	tide1a.anchorX = 0
	tide1a.anchorY = 0.5
	if tide1a.x<15 then tide1a.x=15 end
	tide1a.y=250
	tideGroup:insert(tide1a)
	local tide1b = display.newText(tideWeek[day][2], graph.timeToPixels(timeWeek[day][2]), -20, native.systemFont, 16)
	tide1b:setTextColor(0,0,0)
	--tide1b:setReferencePoint(display.CenterLeftReferencePoint);
	tide1b.anchorX = 0
	tide1b.anchorY = 0.5
	if tide1b.x<15 then tide1b.x=15 end
	if tonumber(tideWeek[day][2])<2 then
		tide1b.y=highest-40
	else
		tide1b.y=lowest+40
	end
	tideGroup:insert(tide1b)
	local tide2a = display.newText(timeWeek[day][3], graph.timeToPixels(timeWeek[day][3]), -20, native.systemFont, 16)
	tide2a:setTextColor(1,1,1)
	tide2a.y=250
	tide2a.anchorX = 0
	tide2a.anchorY = 0.5
	tideGroup:insert(tide2a)
	local tide2b = display.newText(tideWeek[day][3], graph.timeToPixels(timeWeek[day][3]), -20, native.systemFont, 16)
	tide2b:setTextColor(0,0,0)
	if tonumber(tideWeek[day][3])<2 then
		tide2b.y=highest-40
	else
		tide2b.y=lowest+40
	end
	tide2b.anchorX = 0
	tide2b.anchorY = 0.5
	tideGroup:insert(tide2b)
	local tide3a = display.newText(timeWeek[day][4], graph.timeToPixels(timeWeek[day][4]), -20, native.systemFont, 16)
	tide3a:setTextColor(1,1,1)
	tide3a.y=250
	tide3a.anchorX = 0
	tide3a.anchorY = 0.5
	tideGroup:insert(tide3a)
	local tide3b = display.newText(tideWeek[day][4], graph.timeToPixels(timeWeek[day][4]), -20, native.systemFont, 16)
	tide3b:setTextColor(0,0,0)
	if tonumber(tideWeek[day][4])<2 then
		tide3b.y=highest-40
	else
		tide3b.y=lowest+40
	end
	tide3b.anchorX = 0
	tide3b.anchorY = 0.5
	tideGroup:insert(tide3b)
	if timeWeek[day][6]~=nil then
		local tide4a = display.newText(timeWeek[day][5], graph.timeToPixels(timeWeek[day][5]), -20, native.systemFont, 16)
		tide4a:setTextColor(1,1,1)
		tide4a.anchorX = 0
		tide4a.anchorY = 0.5
		if tide4a.x>270 then 
			tide4a.x=265 
			if tide3a.x>220 then tide3a.x=215 end
		end
		tide4a.y=250
		tideGroup:insert(tide4a)
		local tide4b = display.newText(tideWeek[day][5], graph.timeToPixels(timeWeek[day][5]), -20, native.systemFont, 16)
		tide4b:setTextColor(0,0,0)
		tide4b.anchorX = 0
		tide4b.anchorY = 0.5
		if tide4a.x>262 then 
			tide4b.x=262 
			if tide3b.x>220 then tide3b.x=215 end
		end
		
	if tonumber(tideWeek[day][5])<2 then
		tide4b.y=highest-40
	else
		tide4b.y=lowest+40
	end
		tideGroup:insert(tide4b)
	end
	
	return tideGroup
	
end

local function onComplete( event )
        if "clicked" == event.action then
                local i = event.index
                if 1 == i then
				--print("forget")
                        -- Do nothing; dialog will simply dismiss
                elseif 2 == i then
				--print("send")
                        sendText()
                end
        end
end

local function showButtons()
	local bTop=414-display.screenOriginY

	local offset=0
	if isPaid then offset=5 end
	local txtButton = widget.newButton{
		top=bTop,
		left = 10-offset,
		width=80-offset,
		height=60,
		defaultFile = "images/map.png",
		
		onRelease=function(event)
			storyboard.gotoScene("map", storyboard.options)	
			transition.to(event.target,{time=50,alpha=1})
			return true
		end,
		onPress=function(event)
						
			transition.to(event.target,{time=50,alpha=0.5})
			return true
		end
	}
	screenGroup:insert(txtButton)
	
	lButton = widget.newButton{
		top=bTop,
		left = 118-offset*7,
		width=80-offset,
		height=60,
		defaultFile = "images/list.png",
				
		onPress=function(event)
			showList()
			cButton.isVisible=true
			lButton.isVisible=false
		end
	}
	screenGroup:insert(lButton)	
	
	cButton = widget.newButton{
		top=bTop,
		left = 118-offset*7,
		width=80-offset,
		height=60,
		defaultFile = "images/chart.png",
		
		
		onPress=function(event)
			showList()
			lButton.isVisible=true
			cButton.isVisible=false
		end
	}
	cButton.isVisible=false
	screenGroup:insert(cButton)	
	
	local iButton = widget.newButton{
		top=bTop,
		left = 228-offset*13,
		width=80-offset,
		height=60,
		defaultFile = "images/info.png",
		
		onRelease=function(event)
			storyboard.gotoScene("splash", storyboard.options)	
			transition.to(event.target,{time=50,alpha=1})
			return true
		end,
		onPress=function(event)
						
			transition.to(event.target,{time=50,alpha=0.5})
			return true
		end
	}
	screenGroup:insert(iButton)
	
	if isPaid then
	local dButton = widget.newButton{
		top=bTop,
		left = 243,
		width=75,
		width=75,
		height=60,
		defaultFile = "images/calendar.png",
		
		onRelease=function(event)
			storyboard.gotoScene("datepicker", storyboard.options)
			transition.to(event.target,{time=50,alpha=1})
			return true
		end,
		onPress=function(event)
						
			transition.to(event.target,{time=50,alpha=0.5})
			return true
		end
	}
	screenGroup:insert(dButton)
	end
end

function showList()
	local sPosX,sPosY=tideScroll:getContentPosition()
	--if (math.round(sPosX/graphWidth)*graphWidth)==0 then tideScroll:scrollToPosition( -320, 0, 0) end
	for i=1,7 do
		if tideList[i].isVisible==false then
			tideList[i].isVisible=true
			tideData[i].isVisible=false
		else
			tideList[i].isVisible=false
			tideData[i].isVisible=true
		end
	end
end

function scene:createScene( event )

	screenGroup = self.view
	local rect = display.newRect(display.screenOriginX, display.screenOriginY, display.contentWidth-display.screenOriginX*2, display.contentHeight-display.screenOriginY*2)
	rect:setFillColor(1,1,1)
	rect.anchorX = 0
	rect.anchorY = 0
	screenGroup:insert(rect)
	
	local myImage = display.newImageRect("images/header.png", 320,96)
	myImage.anchorX = 0
	myImage.anchorY = 0
	myImage.x = 0
	myImage.y =display.screenOriginY/2
	screenGroup:insert(myImage)	
	
	local texthead = display.newText(string.upper(theCity),100, display.screenOriginY/2+56, native.systemFont, 40)
	texthead:setTextColor(254/256,153/256,0)
	texthead.anchorX = 0
	texthead.anchorY = 0.5
	screenGroup:insert(texthead)
	
	local function doAd(self, touch)	
		if touch.phase == "began" then system.openURL( "http://www.apptoonz.com/m") end
	end
	
	local myImage = display.newImageRect("images/apptoonzmini.png", 320,50)
	myImage.anchorX = 0
	myImage.anchorY = 0
	myImage.x = 0
	myImage.touch = doAd
	myImage:addEventListener("touch", myImage)
	myImage.y =display.screenOriginY/2+96-display.screenOriginY/2
	screenGroup:insert(myImage)	
	
	-- ads.init( "inneractive", "Apptoonz_DublinTides_iPhone", adListener )
	-- ads.show( "banner", { x=0, y=67, interval=60 } )
	
end

function scene:enterScene( event )
	local myDate
	m_position.x=16
	graphWidth=320

	graph.graphPoints = {}
	graph.numGraphPoints = 0
	xmlapi = require( "xml" ).newParser()
	local currentYear = tonumber(os.date( "%Y" ) )
	local currentMonth = tonumber(os.date( "%m" ) )
	local currentDay = tonumber(os.date( "%d" ) )
	local xmlFile=(theCity.."2016ukho.xml")

	tidexml = xmlapi:loadFile(xmlFile)
	if _G.pickedDate~="" then
		myDate=_G.pickedDate
		isToday=false
	else
		myDate=( makeDate(currentDay).."/"..makeDate(currentMonth).."/"..currentYear )
		isToday=true
		if currentMonth<12 and currentYear==2015 then 
			myDate="02/02/2016" 
			isToday=false
		end
	end
	thedate.init()
	local nowdate=thedate.load()
	if nowdate=="." then
		thedate.save( myDate )
	end
	
	currentTime = os.date( "%H:%M" ) 
	local endDate=7
	for i=1,#tidexml.child do
	
		local tideDate = tidexml.child[i].child[3].value

		if tideDate==myDate then
			-- This checks for the last day of year. need change if required to roll into a new year
			if tonumber(string.sub(tideDate,1,2))>24 and tonumber(string.sub(tideDate,4,5))==12 and tonumber(string.sub(tideDate,9,10))==15 then
				endDate=31-tonumber(string.sub(tideDate,1,2))

			end
			for z=1,endDate do
				local m_times={}
				local m_tides={}
				local m_text={}
				if tidexml.child[i+z-1-1].child[11].value~="*" then
					m_times[1]=tidexml.child[i+z-1-1].child[10].value
					m_tides[1]=tidexml.child[i+z-1-1].child[11].value
				else
					m_times[1]=tidexml.child[i+z-1-1].child[8].value
					m_tides[1]=tidexml.child[i+z-1-1].child[9].value
				end
				m_times[2]=tidexml.child[i+z-1].child[4].value
				m_tides[2]=tidexml.child[i+z-1].child[5].value

				m_text[1]=tidexml.child[i+z-1].child[4].value.." : "..tidexml.child[i+z-1].child[5].value
				m_times[3]=tidexml.child[i+z-1].child[6].value
				m_tides[3]=tidexml.child[i+z-1].child[7].value
				m_text[2]=tidexml.child[i+z-1].child[6].value.." : "..tidexml.child[i+z-1].child[7].value
				m_times[4]=tidexml.child[i+z-1].child[8].value
				m_tides[4]=tidexml.child[i+z-1].child[9].value
				m_text[3]=tidexml.child[i+z-1].child[8].value.." : "..tidexml.child[i+z-1].child[9].value
				if tidexml.child[i+z-1].child[11].value~="*" then
					m_times[5]=tidexml.child[i+z-1].child[10].value
					m_tides[5]=tidexml.child[i+z-1].child[11].value
					m_text[4]=tidexml.child[i+z-1].child[10].value.." : "..tidexml.child[i+z-1].child[11].value
					m_times[6]=tidexml.child[i+z-1+1].child[4].value
					m_tides[6]=tidexml.child[i+z-1+1].child[5].value
				else
					m_times[5]=tidexml.child[i+z-1+1].child[4].value
					m_tides[5]=tidexml.child[i+z-1+1].child[5].value
				end
				dayStrings[z]=tidexml.child[i+z-1].child[2].value.." "..tidexml.child[i+z-1].child[3].value
				if tidexml.child[i+z-1].child[15].value~="*" then dayStrings[z]=dayStrings[z].." Tide:"..tidexml.child[i+z-1].child[15].value end
				tideWeek[z]=m_tides
				timeWeek[z]=m_times
				tideText[z]=m_text
				sunRise[z]=tidexml.child[i+z-1].child[12].value
				sunSet[z]=tidexml.child[i+z-1].child[13].value
				moonPhase[z]=tidexml.child[i+z-1].child[14].value
			end
		end		
	end

	if currentYear==2015 or currentYear==2016 then
	
		local function scrollViewListener( event )
		
			local s = event.target    -- reference to scrollView object
			local phase = event.phase
			tButton.isVisible=false
			if "ended"==phase then

				local sPosX,sPosY=s:getContentPosition()
				if sPosX>0 then s:scrollToPosition{x=0, y=sPosY,} end
				if sPosX<-graphWidth*6 then s:scrollToPosition{x=-graphWidth*6, y=sPosY,} end
				s:scrollToPosition{	x=(math.round(sPosX/graphWidth)*graphWidth),y= 0, time=200}
			end
		end
	
		tideScroll = widget.newScrollView
		{
			top = 148-display.screenOriginY/2,
			left = 0,
			width = graphWidth,
			height = 350,
			scrollWidth = graphWidth,
			scrollHeight = 0,
			--maskFile="images/scroll280.png",
			listener = scrollViewListener,
			verticalScrollDisabled=true,
		}			

		for i=1,endDate do
			graph.calculateSections(i)
			tideData[i]=graph.drawTideGraph(i)
			tideList[i]=graph.showText(i)
			tideData[i].y=0
			tideList[i].y=0
			tideData[i].x=-graphWidth+i*graphWidth
			tideList[i].x=-graphWidth+i*graphWidth
			tideScroll:insert(tideList[i])
			tideList[i].isVisible=false
			tideScroll:insert(tideData[i])			
		end

		screenGroup:insert(tideScroll)
		
		if nowdate==myDate then
			local mySwipe = display.newImageRect("images/swipe.png", 320,60)
			mySwipe.anchorX = 0
			mySwipe.anchorY = 0
			mySwipe.x = 0
			mySwipe.y =300
			mySwipe.alpha=.7
			screenGroup:insert(mySwipe)
			timer.performWithDelay(4000, function () if (mySwipe~=nil) then mySwipe:removeSelf() end end)
		end
		
		tButton = widget.newButton{
		top=358,
		left = 279,
		width=37,
		height=39,
		default = "images/pageturn.png",
		
		onRelease=function(event)
						showList()	
						transition.to(event.target,{time=50,alpha=1})
						return true
		end,
		onPress=function(event)
						
						transition.to(event.target,{time=50,alpha=0.5})
						return true
		end
		}
		tButton.isVisible=false
		screenGroup:insert(tButton)
		readPurchase()
		showButtons()
	end
end


-- Called when scene is about to move offscreen:
function scene:exitScene( event )
	--ads.hide()
end


-- Called prior to the removal of scene's "view" (display group)
function scene:destroyScene( event )
	
end

---------------------------------------------------------------------------------
-- END OF IMPLEMENTATION
---------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )

-- "exitScene" event is dispatched before next scene's transition begins
scene:addEventListener( "exitScene", scene )

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroyScene", scene )

return scene