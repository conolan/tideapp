local storyboard = require( "storyboard" )
storyboard.purgeOnSceneChange = true
local scene = storyboard.newScene()
local localInfo
local widget = require( "widget" )
local http = require("socket.http")
local ltn12 = require("ltn12")
local pickerWheel

-- Used to select a startdate for the 7 days tide view. Only accessable once inapp purchase has been made
-- Uses pickerwheel widget 

local function makeDate(date)
	if string.len(date)==1 then date="0"..date end
	return date
end
		
function scene:createScene( event )

	local screenGroup = self.view
	local rect = display.newRect(display.screenOriginX, display.screenOriginY, display.contentWidth-display.screenOriginX*2, display.contentHeight -display.screenOriginY*2)
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
	
	disText = display.newText("Pick a date to view tides (2016)", 160, 156, 300,100, native.systemFont, 20)
	disText:setTextColor(0,0,.8)

	disText.anchorX = 0.5
	disText.anchorY = 0
	screenGroup:insert(disText)

	-- Create two tables to hold our days & years      
	local days = {}

	-- Populate the days table
	for i = 1, 31 do
		days[i] = i
	end

	local pMonth=tonumber(os.date( "%m" ))
	local pDay=tonumber(os.date( "%d" ))
	-- Set up the Picker Wheel's columns
	local columnData = 
	{ 
		{
			align = "center",
			width = 150,
			startIndex = pDay,
			labels = days,
			
		},
		{ 
			align = "left",
			width = 150,
			startIndex = pMonth ,
			labels = 
			{
				"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" 
			},
		},
	}

	-- Create a new Picker Wheel
	pickerWheel = widget.newPickerWheel
	{
		top = 180,
		font = native.systemFontBold,
		columns = columnData,
	}
	screenGroup:insert(pickerWheel)	
	
	local myRectangle = display.newRect(15, 268, 280, 47)
	myRectangle:setFillColor(1, 0.5, 0.5)
	myRectangle.anchorX=0
	myRectangle.anchorY=0
	myRectangle.alpha=0
	screenGroup:insert(myRectangle)
	
	local homeButton = widget.newButton{
		top=410,
		left = 10,
		width=78,
		height=59,
		defaultFile = "images/tide.png",
		
		onRelease=function(event)
			
			local selectedRows = pickerWheel:getValues()
			local isOK=true
			if selectedRows[2].index == 4 or selectedRows[2].index==6 or selectedRows[2].index==9 or selectedRows[2].index==11 then
				if selectedRows[1].index==31 then isOK=false end
			end
			if selectedRows[2].index == 2 then
				if selectedRows[1].index>29 then isOK=false end
			end
			
			if isOK==false then 
				myRectangle.alpha=0.75
				transition.to(myRectangle,{time=500,alpha=0})
				
			else
				_G.pickedDate= (makeDate(selectedRows[1].index).."/"..makeDate(selectedRows[2].index).."/2016" )
				storyboard.gotoScene( "tide", storyboard.options)
				
			end
			transition.to(event.target,{time=50,alpha=1})
			return true
		end,
		onPress=function(event)
						
			transition.to(event.target,{time=50,alpha=0.5})
			return true
		end
	}
	screenGroup:insert(homeButton)
end


function scene:enterScene( event )

end


-- Called when scene is about to move offscreen:
function scene:exitScene( event )

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