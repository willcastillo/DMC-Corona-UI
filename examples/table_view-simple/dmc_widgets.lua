--====================================================================--
-- dmc_widgets.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_widgets.lua
--====================================================================--

--[[

Copyright (C) 2013-2014 David McCuskey. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in the
Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.0"



--====================================================================--
-- DMC Widgets Config
--====================================================================--

local Widget = {}


local args = { ... }
local PATH = args[1]

local dmc_widget_data, dmc_widget_func

if _G.__dmc_widget == nil then

	_G.__dmc_widget = {}
	dmc_widget_data = _G.__dmc_widget

	dmc_widget_data.func = {}
	dmc_widget_func = dmc_widget_data.func
	dmc_widget_func.find = function( name )
		local loc = ''
		if PATH then loc = PATH end
		if loc ~= '' and string.sub( loc, -1 ) ~= '.' then
			loc = loc .. '.'
		end
		return loc .. name
	end

end


--====================================================================--
-- DMC Library Config
--====================================================================--

local dmc_lib_data, dmc_lib_func, dmc_lib_info, dmc_lib_location



local dmc_lib_data, dmc_lib_info, dmc_lib_location

-- boot dmc_library with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require 'dmc_corona_boot' end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona
dmc_lib_info = dmc_lib_data.dmc_corona



--===================================================================--
-- Imports
--===================================================================--


--===================================================================--
-- newScroller widget
--===================================================================--

function Widget.newScroller( options )
	local theme = nil
	local _library = require( PATH .. '.' .. 'widget_scroller' )
	return _library:new( options, theme )
end


--===================================================================--
-- newSlideView widget
--===================================================================--

function Widget.newSlideView( options )
	local theme = nil
	local _library = require( PATH .. '.' .. 'widget_slideview' )
	return _library:new( options, theme )
end


--===================================================================--
-- newTableView widget
--===================================================================--

function Widget.newTableView( options )
	local theme = nil
	local _library = require( PATH .. '.' .. 'widget_tableview' )
	return _library:new( options, theme )
end


--===================================================================--
-- newViewPager widget
--===================================================================--

function Widget.newViewPager( options )
	local theme = nil
	local _library = require( PATH .. '.' .. 'widget_viewpager' )
	return _library:new( options, theme )
end



return Widget
