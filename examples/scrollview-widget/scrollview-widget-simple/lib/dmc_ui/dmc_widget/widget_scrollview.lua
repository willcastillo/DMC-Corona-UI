--====================================================================--
-- dmc_widget/widget_scrollview.lua
--
-- Documentation: http://docs.davidmccuskey.com/
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2015 David McCuskey

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]



--====================================================================--
--== DMC Corona UI : ScrollView Widget
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== DMC UI Setup
--====================================================================--


local dmc_ui_data = _G.__dmc_ui
local dmc_ui_func = dmc_ui_data.func
local ui_find = dmc_ui_func.find



--====================================================================--
--== DMC UI : newScrollView
--====================================================================--



--====================================================================--
--== Imports


local AxisMotion = require( ui_find( 'dmc_widget.widget_scrollview.axis_motion' ) )
local Gesture = require 'dmc_gestures'
local Objects = require 'dmc_objects'
local Utils = require 'dmc_utils'

local uiConst = require( ui_find( 'ui_constants' ) )

local View = require( ui_find( 'core.view' ) )
local Scroller = require( ui_find( 'dmc_widget.widget_scrollview.scroller' ) )



--====================================================================--
--== Setup, Constants


--== To be set in initialize()
local dUI = nil

local newClass = Objects.newClass

local mabs = math.abs
local sfmt = string.format
local tinsert = table.insert
local tremove = table.remove
local tstr = tostring



--====================================================================--
--== ScrollView Widget Class
--====================================================================--


local ScrollView = newClass( View, { name = "ScrollView" } )


--== Class Constants

ScrollView.HIT_TOP_LIMIT = 'top_limit_hit'
ScrollView.HIT_BOTTOM_LIMIT = 'bottom_limit_hit'
ScrollView.HIT_LEFT_LIMIT = 'left_limit_hit'
ScrollView.HIT_RIGHT_LIMIT = 'right_limit_hit'

--== Style/Theme Constants

ScrollView.STYLE_CLASS = nil -- added later
ScrollView.STYLE_TYPE = uiConst.SCROLLVIEW

-- TODO: hook up later
-- ScrollView.DEFAULT = 'default'

-- ScrollView.THEME_STATES = {
-- 	ScrollView.DEFAULT,
-- }


--== Event Constants

ScrollView.EVENT = 'scrollview-widget-event'


--======================================================--
-- Start: Setup DMC Objects

--== Init

function ScrollView:__init__( params )
	-- print( "ScrollView:__init__", params )
	params = params or {}
	if params.scrollWidth==nil then params.scrollWidth=dUI.WIDTH end
	if params.scrollHeight==nil then params.scrollHeight=dUI.HEIGHT end

	self:superCall( '__init__', params )
	--==--

	--== Create Properties ==--

	-- properties in this class

	self._contentPosition = {x=0,y=0}
	self._contentPosition_dirty=true

	-- self._enterFrameIterator = nil

	self._hasMoved = false
	self._isMoving = false
	self._isRendered = false

	self._scrollWidth = params.scrollWidth
	self._scrollWidth_dirty=true
	self._scrollHeight = params.scrollHeight
	self._scrollHeight_dirty=true

	-- controlled by Directional Lock Enabled
	self._scrollBlockedH = false
	self._scrollBlockedV = false

	-- eg, HIT_TOP_LIMIT, HIT_LEFT_LIMIT
	-- self._scrollLimitH = nil
	-- self._scrollLimitV = nil

	self._returnFocus = nil -- return focus callback
	self._returnFocusCancel = nil -- return focus callback
	self._returnFocus_t = nil -- return focus timer

	-- ref to current touch event
	self._tmpTouchEvt = nil
	-- used when calculating velocity
	self._touchEvtStack = {}

	-- velocity vectors
	self._velocityH = { value=0, vector=0 }
	self._velocityV = { value=0, vector=0 }

	-- properties from style

	self._bounceIsActive = true
	self._alwaysBounceVertically = false
	self._alwaysBounceHorizontally = false

	self._scrollHorizontalEnabled = true
	self._scrollVerticalEnabled = true
	self._isDirectionalLockEnabled = false

	self._showHorizontalScrollIndicator = false
	self._showVerticalScrollIndicator = false


	--== Display Groups ==--

	self._dgBg = nil
	self._dgViews = nil
	self._dgUI = nil

	--== Object References ==--

	self._axis_x = nil -- y-axis motion
	self._axis_y = nil -- x-axis motion

	self._gesture = nil -- pan gesture
	self._gesture_f = nil -- callback

	self._rectBg = nil -- background object, touch area

	self._scroller = nil -- our scroll area
	self._scroller_dirty=true


	-- self:setState( ScrollView.STATE_INIT )

end

function ScrollView:__undoInit__()
	-- print( "ScrollView:__undoInit__" )
	--==--
	self:superCall( '__undoInit__' )
end

--== createView

function ScrollView:__createView__()
	-- print( "ScrollView:__createView__" )
	self:superCall( '__createView__' )
	--==--
	local dg, o

	-- local background, hit area

	o = display.newRect( 0,0,0,0 )
	o.anchorX, o.anchorY = 0, 0
	o:setFillColor( 1,0,0,0.4 )
	self._dgBg:insert( o )
	self._rectBg = o

end

function ScrollView:__undoCreateView__()
	-- print( "ScrollView:__undoCreateView__" )
	local o

	self._axis_x:removeSelf()
	self._axis_x = nil

	self._axis_y:removeSelf()
	self._axis_y = nil

	self._rectBg:removeSelf()
	self._rectBg=nil

	self._dgBg:removeSelf()
	self._dgBg=nil
	--==--
	self:superCall( '__undoCreateView__' )
end


--== initComplete

function ScrollView:__initComplete__()
	-- print( "ScrollView:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--
	local o, f

	f = self:createCallback( self._gestureEvent_handler )
	o = Gesture.newPanGesture( self._rectBg, { touches=1, id="1 pan" } )
	o:addEventListener( o.EVENT, f )
	self._gesture = o
	self._gesture_f = f

	f = self:createCallback( self._axisEvent_handler )
	self._axis_x = AxisMotion:new{
		id='x',
		length=self._width,
		scrollLength=self._scrollWidth,
		callback=f
	}
	self._axis_y = AxisMotion:new{
		id='y',
		length=self._height,
		scrollLength=self._scrollHeight,
		callback=f
	}

	self._touchEvtStack = {}

	self._isRendered = true

	-- self:gotoState( ScrollView.STATE_AT_REST )
end

function ScrollView:__undoInitComplete__()
	--print( "ScrollView:__undoInitComplete__" )
	self._isRendered = false
	self._touchEvtStack = nil

	self:_removeScroller()

	local o = self._rectBg
	o:removeEventListener( 'touch', self )

	--==--
	self:superCall( '__undoInitComplete__' )
end

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Static Methods


function ScrollView.initialize( manager, params )
	-- print( "ScrollView.initialize" )
	dUI = manager
	local Widget = nil

	local Style = dUI.Style
	ScrollView.STYLE_CLASS = Style.ScrollView

	Style.registerWidget( ScrollView )
end



--====================================================================--
--== Public Methods


--== .contentPosition

function ScrollView.__getters:contentPosition()
	-- print( "ScrollView.__getters:contentPosition" )
	return self._contentPosition
end
function ScrollView.__setters:contentPosition( value )
	-- print( "ScrollView.__setters:contentPosition", value )
	self._contentPosition = value
	self._contentPosition_dirty=true
end


--== .isDirectionalLockEnabled

function ScrollView.__getters:isDirectionalLockEnabled()
	-- print( "ScrollView.__getters:isDirectionalLockEnabled" )
	return self._isDirectionalLockEnabled
end
function ScrollView.__setters:isDirectionalLockEnabled( value )
	-- print( "ScrollView.__setters:isDirectionalLockEnabled", value )
	self._isDirectionalLockEnabled = value
end


--== .isScrollEnabled

function ScrollView.__getters:isScrollEnabled()
	-- print( "ScrollView.__getters:isScrollEnabled" )
	return self._scrollHorizontalEnabled
end
function ScrollView.__setters:isScrollEnabled( value )
	-- print( "ScrollView.__setters:isScrollEnabled", value )
	self._scrollHorizontalEnabled = value
end


--== .scrollWidth

function ScrollView.__getters:scrollWidth()
	-- print( "ScrollView.__getters:scrollWidth" )
	return self._scrollWidth
end
function ScrollView.__setters:scrollWidth( value )
	-- print( "ScrollView.__setters:scrollWidth", value )
	if self._scrollWidth==value then return end
	self._scrollWidth = value
	self._scrollWidth_dirty=true
end

--== .scrollHeight

function ScrollView.__getters:scrollHeight()
	-- print( "ScrollView.__getters:scrollHeight" )
	return self._scrollHeight
end
function ScrollView.__setters:scrollHeight( value )
	-- print( "ScrollView.__setters:scrollHeight", value )
	if self._scrollHeight==value then return end
	self._scrollHeight = value
	self._scrollHeight_dirty=true
end

--== scrollTo()

-- pos={x,y}
function ScrollView:scrollTo( pos, params )
	params = params or {}
	if params.animate==nil then params.animate=true end
	params.time=params.time
	params.onComplete=params.onComplete
	--==--
	-- TODO: start animation
end

--== scrollToPosition()

-- pos={x,y}
function ScrollView:scrollToPosition( pos, params )
	params = params or {}
	if params.animate==nil then params.animate=true end
	params.time=params.time
	params.onComplete=params.onComplete
	--==--
	-- TODO: start animation
end


function ScrollView:takeFocus( event, params )
	params = params or {}
	params.returnFocus=params.returnFocus
	--==--
	-- TODO: start animation
end


--====================================================================--
--== Private Methods


function ScrollView:_removeScroller()
	-- print( "ScrollView:_removeScroller" )
	local o = self._scroller
	if not o then return end
	o:removeSelf()
	self._scroller = nil
end

function ScrollView:_createScroller()
	-- print( "ScrollView:_createScroller" )

	self:_removeScroller()

	local o = Scroller:new{
		width=self._scrollWidth,
		height=self._scrollHeight
	}
	self:_addSubView( o )
	self._scroller = o

end


function ScrollView:_loadViews()
	self:_createScroller()
end



function ScrollView:__commitProperties__()
	-- print( 'ScrollView:__commitProperties__' )
	local style = self.curr_style

	local view = self.view
	local bg = self._rectBg
	local scr = self._scroller

	--== position sensitive

	-- set text string

	if self._text_dirty then
		self._text_dirty=false

		self._width_dirty=true
		self._height_dirty=true
	end

	if self._align_dirty then
		self._align_dirty = false
	end

	if self._width_dirty then
		-- print("width", self._width)
		bg.width = self._width
		self._width_dirty=false
	end
	if self._height_dirty then
		bg.height = self._height
		self._height_dirty=false
	end

	if self._scrollWidth_dirty then
		scr.width = self._scrollWidth
		self._scrollWidth_dirty=false
	end
	if self._scrollHeight_dirty then
		scr.height = self._scrollHeight
		self._scrollHeight_dirty=false
	end


	if self._marginX_dirty then
		self._marginX_dirty=false

		self._rectBgWidth_dirty=true
		self._textX_dirty=true
		self._displayWidth_dirty=true
	end
	if self._marginY_dirty then
		-- reminder, we don't set text height
		self._marginY_dirty=false

		self._rectBgHeight_dirty=true
		self._textY_dirty=true
		self._displayHeight_dirty=true
	end

	-- bg width/height

	if self._rectBgWidth_dirty then
		self._rectBgWidth_dirty=false
	end
	if self._rectBgHeight_dirty then
		self._rectBgHeight_dirty=false
	end


	-- anchorX/anchorY

	if self._anchorX_dirty then
		-- bg.anchorX = style.anchorX
		self._anchorX_dirty=false

		self._x_dirty=true
		self._textX_dirty=true
	end
	if self._anchorY_dirty then
		-- bg.anchorY = style.anchorY
		self._anchorY_dirty=false

		self._y_dirty=true
		self._textY_dirty=true
	end

	-- x/y

	if self._x_dirty then
		view.x = self._x
		self._x_dirty = false
	end
	if self._y_dirty then
		view.y = self._y
		self._y_dirty = false
	end

	if self._contentPosition_dirty then
		scr.x = self._contentPosition.x
		scr.y = self._contentPosition.y
		self._contentPosition_dirty=false
	end

	--== non-position sensitive

	-- textColor/fillColor

	if self._fillColor_dirty or self._debugOn_dirty then
		if style.debugOn==true then
			bg:setFillColor( 1,0,0,0.2 )
		else
			bg:setFillColor( unpack( style.fillColor ))
		end
		self._fillColor_dirty=false
		self._debugOn_dirty=false
	end
	if self._strokeColor_dirty then
		-- bg:setStrokeColor( unpack( style.strokeColor ))
		self._strokeColor_dirty=false
	end
	if self._strokeWidth_dirty then
		-- bg.strokeWidth = style.strokeWidth
		self._strokeWidth_dirty=false
	end
	if self._textColor_dirty then
		-- display:setScrollViewColor( unpack( style.textColor ) )
		self._textColor_dirty=false
	end

end



--====================================================================--
--== Event Handlers


function ScrollView:stylePropertyChangeHandler( event )
	-- print( "ScrollView:stylePropertyChangeHandler", event.type, event.property )
	local style = event.target
	local etype= event.type
	local property= event.property
	local value = event.value

	-- print( "Style Changed", etype, property, value )

	if etype==style.STYLE_RESET then
		self._debugOn_dirty = true
		self._width_dirty=true
		self._height_dirty=true
		self._anchorX_dirty=true
		self._anchorY_dirty=true

		self._align_dirty=true
		self._fillColor_dirty = true
		self._font_dirty=true
		self._fontSize_dirty=true
		self._marginX_dirty=true
		self._marginY_dirty=true
		self._strokeColor_dirty=true
		self._strokeWidth_dirty=true

		self._text_dirty=true
		self._textColor_dirty=true

		property = etype

	else
		if property=='debugActive' then
			self._debugOn_dirty=true
		elseif property=='width' then
			self._width_dirty=true
		elseif property=='height' then
			self._height_dirty=true
			elseif property=='anchorX' then
				self._anchorX_dirty=true
			elseif property=='anchorY' then
				self._anchorY_dirty=true

		elseif property=='align' then
			self._align_dirty=true
		elseif property=='fillColor' then
			self._fillColor_dirty=true
		elseif property=='font' then
			self._font_dirty=true
		elseif property=='fontSize' then
			self._fontSize_dirty=true
		elseif property=='marginX' then
			self._marginX_dirty=true
		elseif property=='marginY' then
			self._marginY_dirty=true
		elseif property=='strokeColor' then
			self._strokeColor_dirty=true
		elseif property=='strokeWidth' then
			self._strokeWidth_dirty=true
		elseif property=='text' then
			self._text_dirty=true
		elseif property=='textColor' then
			self._textColor_dirty=true
		end

	end

	self:__invalidateProperties__()
	self:__dispatchInvalidateNotification__( property, value )
end





function ScrollView:_gestureEvent_handler( event )
	-- print( "ScrollView:_gestureEvent_handler", event.phase )
	local etype = event.type
	local phase = event.phase
	local gesture = event.target

	-- Utils.print( event )
	local evt = {
		name='touch',
		phase=event.phase,
		time=event.time,
		value=0, -- this is holder for x/y
		start=0, -- this is holder for xStart/yStart
	}

	if etype == gesture.GESTURE then
		evt.phase = 'began'
		if phase=='began' then
			if self._axis_x then
				evt.value = event.x
				evt.start = event.xStart
				self._axis_x:touch( evt )
			end
			if self._axis_y then
				-- evt.value = event.y
				-- evt.start = event.yStart
				-- self._axis_y:touch( evt )
			end
		elseif phase=='changed' then
			evt.phase = 'moved'
			if self._axis_x then
				evt.value = event.x
				evt.start = event.xStart
				self._axis_x:touch( evt )
			end
			if self._axis_y then
				-- evt.value = event.y
				-- evt.start = event.yStart
				-- self._axis_y:touch( evt )
			end
		else
			-- Utils.print( event )
			evt.phase = 'ended'
			if self._axis_x then
				evt.value = event.x
				evt.start = event.xStart
				self._axis_x:touch( evt )
			end
			if self._axis_y then
				-- evt.value = event.y
				-- evt.start = event.yStart
				-- self._axis_y:touch( evt )
			end
		end
	end
end



function ScrollView:_axisEvent_handler( event )
	-- print( "ScrollView:_axisEvent_handler", event.state )
	local state = event.state
	-- local velocity = event.velocity
	local id = event.id
	-- Utils.print( event )
	if id=='x' then
		self._contentPosition.x = event.value
	else
		self._contentPosition.y = event.value
	end
	self._contentPosition_dirty=true
	self:__invalidateProperties__()

end




return ScrollView
