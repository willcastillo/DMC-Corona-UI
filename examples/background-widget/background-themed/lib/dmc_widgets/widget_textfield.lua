--====================================================================--
-- dmc_widgets/widget_textfield.lua
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
--== DMC Corona Widgets : Widget TextField Field
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== DMC Widgets Setup
--====================================================================--


local dmc_widget_data, dmc_widget_func
dmc_widget_data = _G.__dmc_widget
dmc_widget_func = dmc_widget_data.func



--====================================================================--
--== DMC Widgets : newTextField
--====================================================================--



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'
local Utils = require 'dmc_utils'
local LifecycleMixModule = require 'dmc_lifecycle_mix'

-- set later
local Widgets = nil
local ThemeMgr = nil
local TextFieldStyle = nil



--====================================================================--
--== Setup, Constants


-- setup some aliases to make code cleaner
local newClass = Objects.newClass
local ComponentBase = Objects.ComponentBase

local LifecycleMix = LifecycleMixModule.LifecycleMix

local LOCAL_DEBUG = false



--====================================================================--
--== TextField Widget Class
--====================================================================--


local TextField = newClass( {ComponentBase,LifecycleMix}, {name="TextField"}  )

--== Class Constants

-- alignment
TextField.LEFT = 'left'
TextField.CENTER = 'center'
TextField.RIGHT = 'right'

-- background styles
TextField.BORDER_STYLE_NONE = 'border-style-none'
TextField.BORDER_STYLE_LINE = 'border-style-line'
TextField.BORDER_STYLE_ROUNDED = 'border-style-rounded'
TextField.BORDER_IMAGE = 'border-style-rounded'

-- keyboard
TextField.INPUT_DEFAULT = 'default'
TextField.INPUT_DECIMAL = 'decimal'
TextField.INPUT_EMAIL = 'email'
TextField.INPUT_NUMBER = 'number'
TextField.INPUT_PASSWORD = 'password'
TextField.INPUT_PHONE = 'phone'
TextField.INPUT_URL = 'url'

-- return key
TextField.RETURN_DEFAULT = 'default'
TextField.RETURN_DONE = 'done'
TextField.RETURN_EMERGENCY = 'emergencyCall'
TextField.RETURN_GO = 'go'
TextField.RETURN_JOIN = 'join'
TextField.RETURN_NEXT = 'next'
TextField.RETURN_NONE = 'none'
TextField.RETURN_ROUTE = 'route'
TextField.RETURN_SEARCH = 'search'
TextField.RETURN_SEND = 'send'

-- visual styles
TextField.STYLE_DEFAULT = 'default'
TextField.STYLE_DISABLED = 'disabled'
TextField.STYLE_INVALID = 'invalid'

TextField.TOP = 'top'
TextField.BOTTOM = 'bottom'


TextField.EVENT = 'userInput'

TextField.BEGAN = 'began'
TextField.ENDED = 'ended'
TextField.SUBMITTED = 'submitted'
TextField.EDITING = 'editing'


--======================================================--
--== Start: Setup DMC Objects

--== Init

function TextField:__init__( params )
	-- print( "TextField:__init__", params )
	params = params or {}
	if params.x==nil then params.x=0 end
	if params.y==nil then params.y=0 end
	if params.align==nil then params.align=self.CENTER end
	self:superCall( LifecycleMix, '__init__', params )
	self:superCall( ComponentBase, '__init__', params )
	--==--

	--== Sanity Check ==--

	if self.is_class then return end

	local style = params.style
	if not style then
		style = Widgets.Style.TextField.createDefaultStyle()
		style:updateStyle( params )
	end

	assert( style.width, "TextField: requires param 'width'" )
	assert( style.height, "TextField: requires param 'height'" )

	self:addStyle( style.DEFAULT, style )

	--== Create Properties ==--

	--== Component-level
	self._parent = params.parent

	self._text = params.text
	self._text_dirty=true

	self._hintText = params.hintText
	self._hintText_dirty = true

	self._x = params.x
	self._x_dirty = true
	self._y = params.y
	self._y_dirty=true

	--== Widget-level
	self._width = style.width
	self._width_dirty=true
	self._height = style.height
	self._height_dirty=true
	self._align = style.align
	self._hint_align_dirty=true
	self._text_align_dirty=true
	self._anchorX = 0.5
	self._bg_anchorX_dirty=true
	self._anchorY = 0.5
	self._bg_anchorY_dirty=true

	self._inputType = params.inputType
	self._inputType_dirty = true
	self._returnKey = params.returnKey
	self._returnKey_dirty=true

	self._clear_onBeginEdit = false
	self._adjust_fontToFit = false
	self._clearButton_mode = 'never'

	-- hard coded
	self._hasBackground = false -- <<
	self._hasBackground_dirty = true

	--== Text-level
	-- align
	self._textColor = style.text.color
	self._textColor_dirty = true
	self._font = style.text.font
	self._font_dirty=true
	self._fontSize = style.text.fontSize
	self._fontSize_dirty=true

	--== Hint-level
	-- align?
	self._hintColor = style.hint.color
	self._hintColor_dirty = true
	self._hintFont = style.hint.font
	self._hintFont_dirty = true
	self._hintFontSize = style.hint.fontSize
	self._hintFontSize_dirty = true

	--== Background-level
	self._bgMarginX = style.background.marginX
	self._bgMarginY = style.background.marginY
	self._bgColor = style.background.color
	self._bgColor_dirty = true
	self._bgWidth_dirty=true
	self._bg_height_dirty=true

	--== Internal

	self._keyboardFocus=false
	self._keyboardFocus_dirty=true
	self._keyboardFocus_timer=nil

	self._is_enabled = true
	self._is_editing = false
	self._is_valid = true
	self._value = nil

	self._styles = {}
	self._curr_style = nil

	--== Object References ==--

	self._delegate = nil -- delegate
	self._formatter = nil -- data formatter

	self._bg = nil -- background object
	self._hint = nil -- text object
	self._newtextfield = nil -- textfield object
	self._newtextfield_f = nil -- textfield handler

end

function TextField:__undoInit__()
	-- print( "TextField:__undoInit__" )
	--==--
	self:superCall( ComponentBase, '__undoInit__' )
	self:superCall( LifecycleMix, '__undoInit__' )
end


--== createView

function TextField:__createView__()
	-- print( "TextField:__createView__" )
	self:superCall( ComponentBase, '__createView__' )
	--==--

	self._bg = display.newRect( 0,0,0,0 )
	self._bg.isHitTestable=true
	self:insert( self._bg )

	local hw = self._width-self._bgMarginX*2
	local hh = self._height-self._bgMarginY*2
	self._hint = Widgets.Text:new{
		text=self._hintText,
		font=self._hintFont,
		fontSize=self._hintFontSize,
		textColor=self._hintColor,
		fillColor={0,0,0,0},
		width=hw,
		height=hh,
		marginX=0,
		marginY=0,
		hasBackground=false
	}
	self:insert( self._hint.view )

end

function TextField:__undoCreateView__()
	-- print( "TextField:__undoCreateView__" )
	self:_removeNewTextField()

	self._bg:removeSelf()
	self._bg=nil
	--==--
	self:superCall( ComponentBase, '__undoCreateView__' )
end


--== initComplete

function TextField:__initComplete__()
	-- print( "TextField:__initComplete__" )
	self:superCall( ComponentBase, '__initComplete__' )
	--==--
	self._newtextfield_f = self:createCallback( self._textFieldEvent_handler )

	--[[
	self._hint.onUpdate = self:createCallback( self._textOnUpdateEvent_handler )
	--]]

	self._bg_f = self:createCallback( self._backgroundTouch_handler )
	self._bg:addEventListener( 'touch', self._bg_f )

	self:__commitProperties__()
	self:_stopEdit(false)
end

function TextField:__undoInitComplete__()
	--print( "TextField:__undoInitComplete__" )
	self:_removeTextField()

	self._bg:removeEventListener( 'touch', self._bg_f )
	self._bg_f = nil

	self._hint.onUpdate = nil

	self:_stopKeyboardFocus()

	self._newtextfield_f = nil
	--==--
	self:superCall( ComponentBase, '__undoInitComplete__' )
end

--== END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Static Methods


function TextField.__setWidgetManager( manager )
	-- print( "TextField.__setWidgetManager" )
	Widgets = manager
	ThemeMgr = Widgets.ThemeMgr
	ThemeMgr = Widgets.ThemeMgr

end



--====================================================================--
--== Public Methods


function TextField:addStyle( state_name, style )
	if not self.__styles then
		self.__styles = {}
		self.__curr_style = style
	end
	self.__styles[ state_name ]=style
end


function TextField:addStyle( name, style )
	if not self.__styles then
		self.__styles = {}
		self.__curr_style = style
	end
	self.__styles[ name ]=style
end



--== align

function TextField.__getters:align()
	return self._align
end
function TextField.__setters:align( value )
	-- print( 'TextField.__setters:align', value )
	assert( type(value)=='string' )
	if self._align == value then return end
	self._align = value
	self._hint_align_dirty=true
	self._text_align_dirty=true
	self:__invalidateProperties__()
end


--== anchorX

function TextField.__getters:anchorX()
	return self._anchorX
end
function TextField.__setters:anchorX( value )
	-- print( 'TextField.__setters:anchorX', value )
	assert( type(value)=='number' )
	--==--
	if value==self._anchorX then return end
	self._anchorX = value
	self._bg_anchorX_dirty=true
	self._text_posX_dirty=true
	self:__invalidateProperties__()
end


--== anchorY

function TextField.__getters:anchorY()
	return self._anchorY
end
function TextField.__setters:anchorY( value )
	-- print( 'TextField.__setters:anchorY', value )
	assert( type(value)=='number' )
	--==--
	if value==self._anchorY then return end
	self._anchorY = value
	self._bg_anchorY_dirty=true
	self:__invalidateProperties__()
end


--== formatter

function TextField.__setters:formatter( value )
	-- print( 'TextField.__setters:formatter', value )
	assert( value )
	--==--
	self._formatter = value
end


--== font

function TextField.__getters:font()
	return self._font
end
function TextField.__setters:font( value )
	-- print( 'TextField.__setters:font', value )
	assert( value )
	--==--
	if value==self._font then return end
	self._font = value
	self._font_dirty=true
	self._hintFont_dirty=true
	self:__invalidateProperties__()
end

--== fontSize

function TextField.__getters:fontSize()
	return self._fontSize
end
function TextField.__setters:fontSize( value )
	-- print( 'TextField.__setters:fontSize', value )
	assert( type(value)=='number' )
	--==--
	if value==self._fontSize then return end
	self._fontSize = value
	self._fontSize_dirty=true
	self._hintFontSize_dirty=true
	self:__invalidateProperties__()
end


--== isValid

function TextField.__setters:isValid( value )
	-- print( 'TextField.__setters:isValid', value )
	assert( type(value)=='boolean' )
	--==--
	if value == self._is_valid then return end
	self._is_valid = value
	self._valid_dirty=true
	self:__invalidateProperties__()
end


--== marginX

function TextField.__setters:marginX( value )
	-- print( 'TextField.__setters:marginX', value )
	assert( type(value)=='number' )
	if value < 0 then value=0 end
	--==--
	if value == self._bgMarginX then return end
	self._bgMarginX = value
	self._bgWidth_dirty=true
	self:__invalidateProperties__()
end


--== marginY

function TextField.__setters:marginY( value )
	-- print( 'TextField.__setters:marginY', value )
	assert( type(value)=='number' )
	if value < 0 then value=0 end
	--==--
	if value == self._bgMarginY then return end
	self._bgMarginY = value
	self._bg_height_dirty=true
	self:__invalidateProperties__()
end


--== text

function TextField.__getters:text()
	return self._text
end
function TextField.__setters:text( value )
	-- print( 'TextField.__setters:text', value )
	if value == self._text then return end
	self._text = value
	self._text_dirty=true
	self._hintText_dirty=true
	self:__invalidateProperties__()
end


--== X

function TextField.__setters:x( value )
	-- print( 'TextField.__setters:x', value )
	assert( type(value)=='number' )
	--==--
	if value == self._x then return end
	self._x = value
	self._x_dirty=true
	self:__invalidateProperties__()
end


--== Y

function TextField.__setters:y( value )
	-- print( 'TextField.__setters:y', value )
	assert( type(value)=='number' )
	--==--
	if value == self._y then return end
	self._y = value
	self._y_dirty=true
	self:__invalidateProperties__()
end


--== width

function TextField.__getters:width()
	local t, w = self._newtextfield, self._width
	if w==nil and t then w=t.width end
	return w
end
function TextField.__setters:width( value )
	-- print( 'TextField.__setters:width', value )
	assert( value==nil or type(value)=='number' )
	--==--
	if value==self._width then return end
	self._width = value
	self._width_dirty=true
	self._bgWidth_dirty=true
	self._text_posX_dirty=true
	self:__invalidateProperties__()
end


--== height

function TextField.__getters:height()
	local t, h = self._newtextfield, self._height
	if h==nil and t then h=t.height end
	return h
end
function TextField.__setters:height( value )
	-- print( 'TextField.__setters:height', value )
	assert( value==nil or type(value)=='number' )
	--==--
	if value==self._height then return end
	self._height = value
	self._height_dirty=true
	self._bg_height_dirty=true
	self:__invalidateProperties__()
end



--== setAnchor

function TextField:setAnchor( ... )
	-- print( 'TextField:setAnchor' )
	local args = {...}

	if type( args[1] ) == 'table' then
		self.anchorX, self.anchorY = unpack( args[1] )
	end
	if type( args[1] ) == 'number' then
		self.anchorX = args[1]
	end
	if type( args[2] ) == 'number' then
		self.anchorY = args[2]
	end
end


--== setFillColor

function TextField:setFillColor( ... )
	-- print( 'TextField:setFillColor' )
	--==--
	self._bgColor = {...}
	self._bgColor_dirty = true
	self:__invalidateProperties__()
end


--== setHintColor

function TextField:setHintColor( ... )
	-- print( 'TextField:setHintColor' )
	--==--
	self._hintColor = {...}
	self._hintColor_dirty = true
	self:__invalidateProperties__()
end


--== setKeyboardFocus

function TextField:setKeyboardFocus()
	-- print( 'TextField:setKeyboardFocus' )
	self._keyboardFocus = true
	self._keyboardFocus_dirty = true
	self:__invalidateProperties__()
end

function TextField:unsetKeyboardFocus()
	-- print( 'TextField:unsetKeyboardFocus' )
	self._keyboardFocus = false
	self._keyboardFocus_dirty = true
	self:__invalidateProperties__()
end


--== setReturnKey

function TextField:setReturnKey( value )
	-- print( 'TextField:setReturnKey', value )
	assert( type(value)=='string' )
	--==--
	if value==self._returnKey then return end
	--==--
	self._returnKey = value
	self._returnKey_dirty = true
	self:__invalidateProperties__()
end


--== setTextColor

function TextField:setTextColor( ... )
	-- print( 'TextField:setTextColor' )
	--==--
	self._textColor = {...}
	self._textColor_dirty = true
	self._hintColor_dirty = true
	self:__invalidateProperties__()
end


--======================================================--
--== Delegate

function TextField:shouldBeginEditing()
	return self._is_enabled
end

-- on tap
function TextField:_delegateShouldBeginEditing()
	local delegate = self._delegate or self
	if not delegate or not delegate.shouldBeginEditing then
		delegate = self
	end
	return delegate:shouldBeginEditing()
end


function TextField:shouldEndEditing( event )
	return self._is_valid
end

-- after end/submit
function TextField:_delegateShouldEndEditing()
	local delegate = self._delegate or self
	if not delegate or not delegate.shouldEndEditing then
		delegate = self
	end
	return delegate:shouldEndEditing()
end


function TextField:shouldClearTextField()
	return true
end

-- on button press
function TextField:_delegateShouldClearTextField()
	local delegate = self._delegate
	if not delegate or not delegate.shouldClearTextField then
		delegate = self
	end
	return delegate:shouldClearTextField()
end


--======================================================--
--== Formatter

function TextField:areCharactersValid( chars, text )
	return true
end

function TextField:_formatterAreCharactersValid( chars, text )
	local formatter = self._formatter or self
	if not formatter or not formatter.areCharactersValid then
		delegate = self
	end
	return formatter:areCharactersValid( chars, text )
end


function TextField:isTextValid( text )
	return true
end

function TextField:_formatterIsTextValid( text )
	-- print( "_formatterIsTextValid", text)
	local formatter = self._formatter or self
	if not formatter or not formatter.isTextValid then
		delegate = self
	end
	return formatter:isTextValid( text )
end



--====================================================================--
--== Private Methods


function TextField:_updateTextFieldProperties()
	-- CAN OVERRIDE FOR CUSTOM HANDLING
end


function TextField:_removeTextField()
	-- print( 'TextField:_removeTextField' )
	local o = self._newtextfield
	if not o then return end
	o:removeEventListener( 'userInput', self._newtextfield_f )
	o:removeSelf()
	self._newtextfield = nil
end

function TextField:_createTextField()
	-- print( 'TextField:_createTextField' )
	self:_removeTextField()
	self:_updateTextFieldProperties()

	local w = self._width-self._bgMarginX*2
	local h = self._height-self._bgMarginY*2

	self._newtextfield = native.newTextField(0,0,w,h)
	assert( self._newtextfield )
	self:insert( self._newtextfield )
	self._newtextfield:addEventListener( 'userInput', self._newtextfield_f )

	self:_updateVisibility()

	self._width_dirty=false
	self._height_dirty=false

	--== reset our text field object

	self._text_align_dirty=true
	self._text_posX_dirty=true
	self._text_posY_dirty=true

	self._text_dirty=true
	self._textColor_dirty=true
	self._font_dirty=true
	self._fontSize_dirty=true
	self._hasBackground_dirty=true
	self._keyboardFocus_dirty=true
end


function TextField:__commitProperties__()
	-- print( 'TextField:__commitProperties__' )

	if self._width_dirty or self._height_dirty then
		-- create new text field
		self:_createTextField()
	end

	local view = self.view
	local bg = self._bg
	local hint = self._hint
	local text = self._newtextfield

	--== View

	if self._x_dirty then
		view.x = self._x
		self._x_dirty = false
		self._text_posX_dirty=true
	end
	if self._y_dirty then
		view.y = self._y
		self._y_dirty = false

		self._text_posY_dirty=true
	end

	--== Background

	if self._bgColor_dirty then
		bg:setFillColor( unpack( self._bgColor ))
		self._bgColor_dirty=false
	end

	if self._bg_anchorX_dirty then
		bg.anchorX = self._anchorX
		self._bg_anchorX_dirty=false
		self._x_dirty=true
		self._hintX_dirty=true
	end
	if self._bg_anchorY_dirty then
		bg.anchorY = self._anchorY
		self._bg_anchorY_dirty=false
		self._y_dirty=true
		self._hintY_dirty=true
	end
	if self._bgWidth_dirty then
		bg.width = self.width
		self._bgWidth_dirty=false
		self._text_posX_dirty=true
		self._hint_alignX_dirty=true
	end
	if self._bg_height_dirty then
		bg.height = self.height
		self._bg_height_dirty=false
		self._text_posY_dirty=true
	end

	--== text field

	if self._text_align_dirty then
		text.align=self._align
		self._text_align_dirty = false
	end

	if self._text_posX_dirty then
		local offset
		if self._align==self.LEFT then
			text.anchorX = 0
			offset = -bg.width*(bg.anchorX)+self._bgMarginX
			text.x=bg.x+offset
		elseif self._align==self.RIGHT then
			text.anchorX = 1
			offset = bg.width*(1-bg.anchorX)-self._bgMarginX
			text.x=bg.x+offset
		else
			text.anchorX = 0.5
			offset = bg.width*(0.5-bg.anchorX)
			text.x=bg.x+offset
		end
		self._text_posX_dirty = false
	end
	if self._text_posY_dirty then
		local offset=bg.height/2+(-bg.height*bg.anchorY)
		text.y=bg.y+offset
		self._text_posY_dirty=false
	end

	if self._text_dirty then
		text.text = self._text
		self._text_dirty=false

		self._bg_anchorX_dirty=true
		self._bg_anchorY_dirty=true
	end
	if self._font_dirty or self._fontSize_dirty then
		text.font=native.newFont( self._font, self._fontSize )
		self._font_dirty=false
		self._fontSize_dirty=false
	end
	if self._textColor_dirty then
		text:setTextColor( unpack( self._textColor ) )
		self._textColor_dirty=false
	end

	if self._keyboardFocus_dirty then
		local focus = nil
		if self._keyboardFocus==true then
			focus = text
		end
		self:_startKeyboardFocus( focus )
		self._keyboardFocus_dirty=false
	end

	if self._text_align_dirty then
		text.align=self._align
		self._text_align_dirty = false
	end

	--== Hint

	if self._hint_align_dirty then
		hint.align=self._align
		self._hint_align_dirty = false
	end

	if self._hintX_dirty then
		local offset
		if self._align==self.LEFT then
			hint.anchorX = 0
			offset = -bg.width*(bg.anchorX)+self._bgMarginX
			hint.x=bg.x+offset
		elseif self._align==self.RIGHT then
			hint.anchorX = 1
			offset = bg.width*(1-bg.anchorX)-self._bgMarginX
			hint.x=bg.x+offset
		else
			text.anchorX = 0.5
			offset = bg.width*(0.5-bg.anchorX)
			hint.x=bg.x+offset
		end
		self._hintX_dirty = false
	end
	if self._hintY_dirty then
		local offset
		hint.anchorY = 0.5
		offset = bg.height/2-bg.height*(bg.anchorY) -- 0
		hint.y=bg.y+offset
		self._hintY_dirty = false
	end

	if self._hintText_dirty then
		if self._text=="" then
			hint.text=self._hintText
		else
			hint.text=self._text
		end
		self._hintText_dirty=false

		self._hintFont_dirty=true
		self._hintFontSize_dirty=true
		self._hintColor_dirty=true
	end
	if self._hintFont_dirty then
		if self._text=="" then
			hint.font=self._hintFont
		else
			hint.font=self._font
		end
		self._hintFont_dirty=false
	end
	if self._hintFontSize_dirty then
		if self._text=="" then
			hint.fontSize=self._hintFontSize
		else
			hint.fontSize=self._fontSize
		end
		self._hintFontSize_dirty=false
	end
	if self._hintColor_dirty then
		if self._text=="" then
			hint:setTextColor( unpack( self._hintColor ) )
		else
			hint:setTextColor( unpack( self._textColor ) )
		end
		self._hintColor_dirty=false
	end

end


function TextField:_startKeyboardFocus( focus )
	self:_stopKeyboardFocus()
	local f = function()
		native.setKeyboardFocus( focus )
		self._keyboardFocus_timer=nil
	end
	self._keyboardFocus_timer = timer.performWithDelay( 1, f )
end

function TextField:_stopKeyboardFocus()
	if not self._keyboardFocus_timer then return end
	timer.cancel( self._keyboardFocus_timer)
	self._keyboardFocus_timer = nil
end


function TextField:_updateVisibility()
	local hint = self._hint
	local text = self._newtextfield
	local is_editing = self._is_editing

	hint.isVisible=not is_editing
	text.isVisible=is_editing
end


function TextField:_startEdit( set_focus )
	-- print( 'TextField:_startEdit' )
	if set_focus==nil then set_focus=true end
	--==--
	self._is_editing=true
	self:_updateVisibility()

	if set_focus then
		native.setKeyboardFocus( self._newtextfield )
	end
end

function TextField:_stopEdit( set_focus )
	-- print( 'TextField:_stopEdit' )
	if set_focus==nil then set_focus=true end
	--==--
	self._is_editing=false
	self:_updateVisibility()

	if set_focus then
		native.setKeyboardFocus( nil )
	end
end


function TextField:_doStateBegan( event )
	-- print( 'TextField:_doStateBegan', event )
	self:_startEdit( false )

	self._tmp_text = self._text -- start last ok state

	event.target=self
	event.text=self._text -- fix broken simulator
	self:dispatchEvent( event )
end

function TextField:_doStateEditing( event )
	-- print( 'TextField:_doStateEditing', event )

	self._tmp_text = event.text -- save for last ok state

	event.target=self
	self:dispatchEvent( event )
end

function TextField:_doStateEnded( event )
	-- print( 'TextField:_doStateEnded', event )
	self:_stopEdit( false )

	self._tmp_text = nil

	event.target=self
	event.text=self._text
	self:dispatchEvent( event )
end



--====================================================================--
--== Event Handlers


function TextField:_backgroundTouch_handler( event )
	-- print( 'TextField:_backgroundTouch_handler', event.phase )
	local phase = event.phase
	local background = event.target

	if self._is_editing==true then return end

	if phase=='began' then
		display.getCurrentStage():setFocus( background )
		self._has_focus = true
	end

	if not self._has_focus then return false end

	if phase=='ended' or phase=='canceled' then
		local bgCb = background.contentBounds
		local isWithinBounds = ( bgCb.xMin <= event.x and bgCb.xMax >= event.x and bgCb.yMin <= event.y and bgCb.yMax >= event.y )
		if isWithinBounds and self:_delegateShouldBeginEditing() then
			self:_startEdit()
		end

		display.getCurrentStage():setFocus( nil )
		self._has_focus = false
	end

	return true
end


--[[
-- from our 'hint' text object
function TextField:_textOnUpdateEvent_handler( event )
	-- print( 'TextField:_textOnUpdateEvent_handler' )
	local text = event.target
	-- print( 'text height', text.textHeight )
end
--]]



function TextField:_textFieldEvent_handler( event )
	-- print( '\n\nTextField:_textFieldEvent_handler', event.phase )
	local phase = event.phase
	local textfield = event.target

	-- Utils.print( event )

	if phase==self.BEGAN then
		-- print( "text", event.text )
		self:_doStateBegan( event )

	elseif phase==self.ENDED or phase==self.SUBMITTED then
		-- print( "end text", textfield.text )
		local text = textfield.text

		self.isValid = self:_formatterIsTextValid( text )
		if self:_delegateShouldEndEditing( event ) then
			-- this delegate call needs checking
			self.text = textfield.text -- << Use Setter
			self:_doStateEnded( event )
		else
			self:setKeyboardFocus()
		end

	elseif phase==self.EDITING then

		--[[
		print( "start", event.startPosition )
		print( "delete", event.numDeleted )
		print( "new", event.newCharacters )
		print( "text", event.text )
		--]]
		local del = (event.numDeleted>0)
		if del or self:_formatterAreCharactersValid( event.newCharacters, event.text ) then
			self.isValid = self:_formatterIsTextValid( event.text )
			self:_doStateEditing( event )
		else
			textfield.text = self._tmp_text
		end

	end
end




return TextField