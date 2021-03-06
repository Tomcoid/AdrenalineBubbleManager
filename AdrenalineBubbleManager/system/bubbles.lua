--[[

    Licensed by Creative Commons Attribution-ShareAlike 4.0
   http://creativecommons.org/licenses/by-sa/4.0/
   
   Designed By Gdljjrod & DevDavisNunez.
   Collaborators: BaltaR4 & Wzjk.
   
]]

bubbles = {}
bubbles.len, dels = 0,0
local crono2, click = timer.new(), false -- Timer and Oldstate to click actions.

function bubbles.scan()

	--id, type, version, dev, path, title
	local list = game.list(__GAME_LIST_APP)
	table.sort(list ,function (a,b) return string.lower(a.id)<string.lower(b.id) end)

	bubbles.list = {}
	for i=1, #list do
		if files.exists(list[i].path.."/data/boot.inf") or files.exists(list[i].path.."/data/boot.bin") then

			local entry = {
				id = list[i].id,                           			-- GAMEID of the game.
				path = list[i].path,                           		-- Path of the game.
				boot = list[i].path.."/data/boot.bin",				-- Path to the boot.bin
				imgp = "ur0:appmeta/"..list[i].id.."/icon0.png",	-- Path to icon0 of the game.
				title =	list[i].title,								-- TITLEID of the game.
				delete = false,
			}

			if files.exists(list[i].path.."/data/boot.bin") then
				--checking magic
				local fp = io.open(list[i].path.."/data/boot.bin","r")
				if fp then
					local magic = str2int(fp:read(4))
					fp:close()
					if magic == 0x00424241 then	table.insert(bubbles.list, entry) end
				end

			else
				AutoMakeBootBin(list[i])
				if files.exists(list[i].path.."/data/boot.bin") then table.insert(bubbles.list, entry) end
			end
		end

	end--for

	bubbles.len = #bubbles.list

	if bubbles.len > 0 then
		table.sort(bubbles.list ,function (a,b) return string.lower(a.id)<string.lower(b.id) end)

		--Read data/boot.bin
		for i=1, bubbles.len do
			bubbles.list[i].lines = {}
			local fp = io.open(bubbles.list[i].boot,"r")
			if fp then
				--Driver
				fp:seek("set",0x04)
				local driver = str2int(fp:read(4))
				if driver < 0 or driver > 2 then driver = 0 end
				table.insert(bubbles.list[i].lines, driver)

				--Execute
				fp:seek("set",0x08)
				local modebin = str2int(fp:read(4))
				if modebin < 0 or modebin > 2 then modebin = 0 end
				table.insert(bubbles.list[i].lines, modebin)

				--Customized
				fp:seek("set",0x0C)
				local custom = str2int(fp:read(4))
				if custom < 0 or custom > 1 then custom = 0 end
				table.insert(bubbles.list[i].lines, custom)

				--Path
				fp:seek("set",0x20)
				bubbles.list[i].iso = fp:read()

				if files.exists(bubbles.list[i].iso) then bubbles.list[i].exist = true end
				--Close
				fp:close()

			end--fp
		end
	end

end

-- src = objet game to launch
function bubbles.install(src)

	files.delete("ux0:data/ABMVPK/")
	local bubble_title,timg = nil,nil

	if src.title then
		bubble_title = osk.init(strings.titleosk, src.title or strings.putnameosk, 128, __OSK_TYPE_DEFAULT, __OSK_MODE_TEXT)
	end
	if not bubble_title or (string.len(bubble_title)<=0) then bubble_title = src.title or src.name end

	local i=0
	while game.exists(string.format("%s%03d",string.sub("PSPEMU00",1,-3),i)) do
		i+=1
	end
	local lastid = string.format("%s%03d",string.sub("PSPEMU00",1,-3),i)

	local work_dir = "ux0:data/ABMVPK/"
	files.mkdir(work_dir)

	files.delete(work_dir+lastid)
	files.copy("bubbles/pspemuxxx",work_dir)
	files.rename(work_dir.."pspemuxxx", lastid)
	work_dir += lastid.."/"

	--Resources to 8bits
	buttons.homepopup(0)

		------------------------------icon0 & startup
		timg = game.geticon0(src.path)

		if back2 then back2:blit(0,0) end
		draw.fillrect(0,0,960,30, color.shine)
		screen.print(10,10,strings.convert)
		screen.print(950,10,"ICON0.PNG",1, color.white, color.blue, __ARIGHT)

		if timg then
			timg:resize(252,151)
			timg:center()
			timg:blit(480,272)
		end
		screen.flip()

		if timg then
			timg:reset()
			if src.nostretched then
				image.save(timg:copyscale(128,128),work_dir.."sce_sys/icon0.png", 1)
			else
				image.save(image.nostretched(timg, colors[src.selcc]), work_dir.."sce_sys/icon0.png", 1)
			end
			image.save(timg, work_dir.."sce_sys/livearea/contents/startup.png", 1)
		else
			files.copy("bubbles/sce_sys_lman/icon0.png", work_dir.."sce_sys")
			files.copy("bubbles/sce_sys_lman/startup.png", work_dir.."sce_sys/livearea/contents/")
		end

		------------------------------pic0 & bg0
		if __SET == 0 then
			timg = game.getpic1(src.path)

			if back2 then back2:blit(0,0) end
			draw.fillrect(0,0,960,30, color.shine)
			screen.print(10,10,strings.convert)
			screen.print(950,10,"PIC0.PNG",1, color.white, color.gray, __ARIGHT)

			if timg then
				timg:resize(252,151)
				timg:center()
				timg:blit(480,272)
			end
			screen.flip()

			if timg then
				timg:reset()
				image.save(timg:copyscale(960,544), work_dir.."sce_sys/pic0.png", 1)
				files.copy(work_dir.."sce_sys/pic0.png", work_dir.."sce_sys/livearea/contents")
				files.rename(work_dir.."/sce_sys/livearea/contents/pic0.png","bg0.png")
			else
				files.copy("bubbles/sce_sys_lman/pic0.png", work_dir.."sce_sys/")
				files.copy("bubbles/sce_sys_lman/bg0.png", work_dir.."sce_sys/livearea/contents/")
			end
		else
			--"PIC0.PNG", 	 w = 960,	h = 544

			local setimg = false
			timg = image.load(__PATHSETS.."Set"..__SET.."/PIC0.PNG")

			if timg then setimg = true
			else timg = game.getpic1(src.path) end
			
			if back2 then back2:blit(0,0) end
			draw.fillrect(0,0,960,30, color.shine)
			screen.print(10,10,strings.convert)
			screen.print(950,10,"PIC0.PNG",1, color.white, color.gray, __ARIGHT)

			if timg then
				timg:resize(252,151)
				timg:center()
				timg:blit(480,272)
			end
			screen.flip()

			if timg then
				timg:reset()
				local scale = false
				if timg:getrealw() != 960 or timg:getrealh() != 544 then
					timg=timg:copyscale(960,544)
					scale = true
				end

				if __8PNG == 1 then
					image.save(timg, work_dir.."sce_sys/pic0.png", 1)
				else
					if scale then
						image.save(timg, work_dir.."sce_sys/pic0.png", 1)
					elseif setimg then
						files.copy(__PATHSETS.."Set"..__SET.."/PIC0.PNG", work_dir.."sce_sys/")
					else
						image.save(timg, work_dir.."sce_sys/pic0.png", 1)
					end
				end

			else
				files.copy("bubbles/sce_sys_lman/pic0.png", work_dir.."sce_sys/")
			end

			--"BG0.PNG", 	 w = 840,	h = 500
			setimg = false
			local bg0 = image.load(__PATHSETS.."Set"..__SET.."/BG0.PNG")
			if not bg0 then
				if timg then bg0 = timg end
			else
				setimg = true
			end

			if back2 then back2:blit(0,0) end
			draw.fillrect(0,0,960,30, color.shine)
			screen.print(10,10,strings.convert)
			screen.print(950,10,"BG0.PNG",1, color.white, color.blue, __ARIGHT)

			if bg0 then
				bg0:resize(252,151)
				bg0:center()
				bg0:blit(480,272)
			end
			screen.flip()

			if bg0 then
				bg0:reset()
				local scale = false
				if bg0:getrealw() != 840 or bg0:getrealh() != 500 then
					bg0 = bg0:copyscale(840,500)
					scale = true
				end

				if __8PNG == 1 then
					image.save(bg0, work_dir.."sce_sys/livearea/contents/bg0.png", 1)
				else
					if scale then
						image.save(bg0, work_dir.."sce_sys/livearea/contents/bg0.png", 1)
					elseif setimg then
						files.copy(__PATHSETS.."Set"..__SET.."/BG0.PNG", work_dir.."sce_sys/livearea/contents/")
					else
						image.save(bg0, work_dir.."sce_sys/livearea/contents/bg0.png", 1)
					end
				end

			else
				files.copy("bubbles/sce_sys_lman/bg0.png", work_dir.."sce_sys/livearea/contents/")
			end

			--TEMPLATE.XML
			if files.exists(__PATHSETS.."Set"..__SET.."/TEMPLATE.XML") then
				files.copy(__PATHSETS.."Set"..__SET.."/TEMPLATE.XML", work_dir.."sce_sys/livearea/contents/")
			end

		end
	buttons.homepopup(1)

	-- Set SFO & TITLE
	game.setsfo(work_dir.."sce_sys/PARAM.SFO", "STITLE", tostring(bubble_title), 0)
	game.setsfo(work_dir.."sce_sys/PARAM.SFO", "TITLE", tostring(bubble_title), 0)
	game.setsfo(work_dir.."sce_sys/PARAM.SFO", "TITLE_ID", tostring(lastid), 0)

	-- Path ISO/CSO/PBP to BOOT.BIN
	local fp = io.open(work_dir.."data/boot.bin", "r+")
	if fp then
		local path2game = src.path
		local fill = 256 - #src.path
		for j=1,fill do
			path2game = path2game..string.char(00)
		end

		fp:seek("set",0x20)
		fp:write(path2game)

		--Close
		fp:close()

	end--fp

	--Install Bubble
	buttons.homepopup(0)
		bubble_id = lastid
		result = game.installdir(work_dir)
		buttons.read()
	buttons.homepopup(1)

	if result == 1 then
		src.install,src.state = "b",true
		if src.inst then
			src.inst,src.nostretched = false,false
			src.selcc = __COLOR
			if toinstall >0 then toinstall-=1 end
		end

		if bubbles.list then
			local entry = {
				id = lastid,
				path = "ux0:app/"..lastid,
				boot = "ux0:app/"..lastid.."/boot.bin",
				imgp = "ur0:appmeta/"..lastid.."/icon0.png",
				title = bubble_title,
				delete = false
			}
			table.insert(bubbles.list, entry)-- Insert entry in list of bubbles! :)

			--Path2Game
			bubbles.list[#bubbles.list].iso = src.path:lower()

			--Driver&Execute&Customized
			bubbles.list[#bubbles.list].lines = {}
			table.insert(bubbles.list[#bubbles.list].lines, 0)
			table.insert(bubbles.list[#bubbles.list].lines, 0)
			table.insert(bubbles.list[#bubbles.list].lines, 0)

			bubbles.len = #bubbles.list
			table.sort(bubbles.list ,function (a,b) return string.lower(a.id)<string.lower(b.id) end)
		end
	else
		os.message(strings.errinst)
	end
	----------------------------------------------------------------------------------------------------------------------------
	files.delete("ux0:data/ABMVPK/")
end

function bubbles.settings()

	local options_edit = { "DRIVER:", "EXECUTE:", "CUSTOMIZED:" }
	local drivers   = { "INFERNO", "MARCH33", "NP9660" }
	local bins      = { "EBOOT.BIN", "BOOT.BIN", "EBOOT.OLD" }
	local enables   = { "NO", "YES" }

	local selector, optsel, change, bmaxim = 1,1,false,9
	local scrids, xscr1, xscr2 = newScroll(bubbles.list, bmaxim), 110, 15
	local mark,preview = false,nil

	buttons.interval(12,5)
	while true do
		buttons.read()
			touch.read()

		if back2 then back2:blit(0,0) end
		if math.minmax(tonumber(os.date("%d%m")),2512,2512)== tonumber(os.date("%d%m")) then stars.render() end

		draw.fillrect(0,0,960,30, 0x64545353) --UP
		screen.print(480,5, strings.btitle, 1, color.white, color.blue, __ACENTER)
		screen.print(950,5,strings.count.." "..bubbles.len, 1, color.red, color.gray, __ARIGHT)

		draw.fillrect(70,60,820,420,color.new(105,105,105,230))
			draw.gradline(70,310,890,310,color.blue,color.green)
			draw.gradline(70,311,890,311,color.green,color.blue)
		draw.rect(70,60,820,420,color.blue)

		if scrids.maxim > 0 then

			local y = 75
			for i=scrids.ini, scrids.lim do
				if i == scrids.sel then
					draw.fillrect(320,y-1,330,18,color.green:a(100))
					if not preview then
						preview = image.load(bubbles.list[scrids.sel].imgp)
						if preview then
							preview:resize(120,120)
							preview:setfilter(__IMG_FILTER_LINEAR, __IMG_FILTER_LINEAR)
						end
					end
				end
				screen.print(480,y,bubbles.list[i].id or strings.unk,1.0,color.white,color.gray,__ACENTER)

				if bubbles.list[i].delete then
					draw.fillrect(750,y-1,30,18,color.new(255,255,255,100))
					screen.print(757,y,SYMBOL_CROSS,1.0,color.white,color.red)
				end

				y += 23
			end

			--Bar Scroll
			local ybar,h=70, (bmaxim*24)-2
			draw.fillrect(660, ybar-2, 8, h, color.shine)
			if scrids.maxim >= bmaxim then -- Draw Scroll Bar
				local pos_height = math.max(h/scrids.maxim, bmaxim)
				draw.fillrect(660, ybar-2 + ((h-pos_height)/(scrids.maxim-1))*(scrids.sel-1), 8, pos_height, color.new(0,255,0))
			end

			if preview then
				screen.clip(200,165, 120/2)
					preview:center()
					preview:blit(200,165)
				screen.clip()
			end

			--Options txts
			if bubbles.list[scrids.sel].exist then ccolor = color.green else ccolor = color.orange end

			if screen.textwidth(bubbles.list[scrids.sel].iso or strings.unk) > 765 then
				xscr1 = screen.print(xscr1, 320, bubbles.list[scrids.sel].iso or strings.unk,1,ccolor,color.gray,__SLEFT,765)
			else
				screen.print(480, 320, bubbles.list[scrids.sel].iso or strings.unk,1,ccolor,color.gray, __ACENTER)
			end

			local y1=346
			for i=1,3 do
				if change then
					if i == optsel then draw.fillrect(240,y1-1,480,18,color.green:a(100)) end
				end
				screen.print(280, y1, options_edit[i],1,color.white,color.gray, __ALEFT)
				y1+=23
			end
			screen.print(680, 346, drivers[ bubbles.list[scrids.sel].lines[1] + 1 ],1,color.white,color.gray, __ARIGHT)
			screen.print(680, 369, bins[ bubbles.list[scrids.sel].lines[2] + 1 ],1,color.white,color.gray, __ARIGHT)
			screen.print(680, 392, enables[ bubbles.list[scrids.sel].lines[3] + 1 ],1,color.white,color.gray, __ARIGHT)

			if not change then
				screen.print(480,435, strings.marks, 1, color.white, color.blue, __ACENTER)
				screen.print(480,460, SYMBOL_SQUARE..": "..strings.uninstall.." ( "..dels.." )   |   "..SYMBOL_TRIANGLE..": "..strings.editboot.."   |   "..SYMBOL_BACK2..": "..strings.inject.."   |   "..SYMBOL_BACK..": "..strings.back, 1, color.white, color.blue, __ACENTER)
			else
				screen.print(480,460, "<- -> "..strings.toggle.."      |      "..SYMBOL_TRIANGLE..": "..strings.doneedit.."      ", 1, color.white, color.blue, __ACENTER)
			end

			if screen.textwidth(bubbles.list[scrids.sel].boot) > 940 then
				xscr2 = screen.print(xscr2, 523, bubbles.list[scrids.sel].boot,1,color.white,color.blue,__SLEFT,940)
			else
				screen.print(15, 523, bubbles.list[scrids.sel].boot,1,color.white,color.blue)
			end

		else
			screen.print(480,200, strings.notbubbles, 1, color.white, color.red, __ACENTER)
			screen.print(480,230, strings.createbb, 1, color.white, color.red, __ACENTER)
			screen.print(480,460, SYMBOL_BACK..": "..strings.togoback, 1, color.white, color.blue, __ACENTER)
		end
		draw.fillrect(0,516,960,30, 0x64545353)--Down

		screen.flip()

		--Controls
		if scrids.maxim > 0 then

			if buttons.triangle then
				change = not change
				if change then buttons.homepopup(0)
				else
					if bubbles.list[scrids.sel].update then
						local fp = io.open(bubbles.list[scrids.sel].boot, "r+")
						if fp then
							local offset = 0x04
							for i=1,3 do
								fp:seek("set", offset * i)
								fp:write(int2str(bubbles.list[scrids.sel].lines[i]))
							end
							fp:close()
							bubbles.list[scrids.sel].update = false
						end
					end
					buttons.read()
					buttons.homepopup(1)
					optsel = 1
				end
			end

			if not change then

				if (buttons.up or buttons.analogly < -60) then
					if scrids:up() then preview = nil end
				end
				if (buttons.down or buttons.analogly > 60) then
					if scrids:down() then preview = nil end
				end

				if buttons[accept] then
					bubbles.edit(bubbles.list[scrids.sel])
					preview = nil
				end

				if buttons.square then
					if dels>=1 then
						local vbuff = screen.toimage()
						local tmp,c = dels,0
						if os.message(strings.uninstallbb.." "..dels,1) == 1 then

							for i=bubbles.len,1,-1 do
								if bubbles.list[i].delete then
									if vbuff then vbuff:blit(0,0) end
									draw.fillrect(70, 285, ( (tmp-c) * 820 )/tmp, 25, color.new(0,255,0))
									screen.flip()
									buttons.homepopup(0)
									game.delete(bubbles.list[i].id)
									if not game.exists(bubbles.list[i].id) then
										preview = nil
										table.remove(bubbles.list, i)
										bubbles.len -= 1
										scrids:set(bubbles.list, bmaxim)
										dels-=1
										c+=1
									end
									buttons.read()
									buttons.homepopup(1)
								end
							end--for

							--Update
							for i=1,scan.len do
								scan.list[i].install,scan.list[i].state = "a",false
								for j=1,bubbles.len do
									if scan.list[i].path:lower() == bubbles.list[j].iso:lower() then
										scan.list[i].install,scan.list[i].state = "b",true
										break
									end
								end
							end
						end
					end
					bubbles.len = #bubbles.list
				end

				if buttons.select then
					bubbles.list[scrids.sel].delete = not bubbles.list[scrids.sel].delete
					if bubbles.list[scrids.sel].delete then dels+=1 else dels-=1 end
				end

				if buttons.start then
					mark = not mark
					for i=1,bubbles.len do
						bubbles.list[i].delete = mark
						if mark then dels=bubbles.len else dels=0 end
					end
				end

				if isTouched(155,90,240,175) and touch.front[1].released then--pressed then
					if click then
						click = false
						if crono2:time() <= 300 then -- Double click and in time to Go.
							-- Your action here.
							game.launch(bubbles.list[scrids.sel].id)
						end
					else
						-- Your action here.
						click = true
						crono2:reset()
						crono2:start()
					end
				end

				if crono2:time() > 300 then -- First click, but long time to double click...
					click = false
				end

			--edit
			else
				if (buttons.up or buttons.held.l) then optsel-=1 end
				if (buttons.down or buttons.held.r) then optsel+=1 end

				if optsel > 3 then optsel = 1 end
				if optsel < 1 then optsel = 3 end

				if (buttons.left or buttons.right) then
					if buttons.left then selector-=1 end
					if buttons.right then selector+=1 end

					if optsel == 3 then
						if selector > 2 then selector = 1 end
						if selector < 1 then selector = 2 end
					else
						if selector > 3 then selector = 1 end
						if selector < 1 then selector = 3 end
					end

					bubbles.list[scrids.sel].lines[optsel] = selector - 1
					bubbles.list[scrids.sel].update = true
				end	
			end--not change

		end

		if buttons[cancel] and not change then return false end

	end
end

function bubbles.edit(obj)

	local tmp = files.listdirs("ux0:ABM/")

	if tmp then table.sort(tmp,function(a,b) return string.lower(a.name)<string.lower(b.name) end)
	else tmp = {} end

	local resources = { 
		{ name = "ICON0.PNG", 	 w = 128,	h = 128,	dest = "/sce_sys/icon0.png",						restore = "/sce_sys/" },
		{ name = "STARTUP.PNG",  w = 262,	h = 125,	dest = "/sce_sys/livearea/contents/startup.png",	restore = "/sce_sys/livearea/contents/" },
		{ name = "PIC0.PNG", 	 w = 960,	h = 544,	dest = "/sce_sys/pic0.png",							restore = "/sce_sys/" },
		{ name = "BG0.PNG", 	 w = 840,	h = 500,	dest = "/sce_sys/livearea/contents/bg0.png",		restore = "/sce_sys/livearea/contents/" },
		{ name = "TEMPLATE.XML", w = 0,		h = 0,		dest = "/sce_sys/livearea/contents/",				restore = "/sce_sys/livearea/contents/" },
	}
	local preview, find_png, inside, backl = nil,false,false,{}

	local maximset = 10
	local scrids, newpath = newScroll(tmp, maximset),"ux0:ABM/"
	buttons.interval(12,5)
	while true do
		buttons.read()

		if back2 then back2:blit(0,0) end
		if math.minmax(tonumber(os.date("%d%m")),2512,2512)== tonumber(os.date("%d%m")) then stars.render() end

		draw.fillrect(0,0,960,30, 0x64545353) --UP
		screen.print(480,5, strings.redit, 1, color.white, color.blue, __ACENTER)
		screen.print(950,5, strings.count.." "..scrids.maxim, 1, color.red, color.gray, __ARIGHT)

		if scrids.maxim > 0 then

			screen.print(15,35, newpath, 1, color.white,color.blue)
			local y = 75
			for i=scrids.ini, scrids.lim do

				if i == scrids.sel then
					draw.fillrect(14,y-3,682,25,color.green:a(100))

					if not preview then
						if tmp[i].ext and tmp[i].ext:upper() == "PNG" then
							preview = image.load(tmp[i].path)
							if preview then
								preview:resize(252,151)
								preview:setfilter(__IMG_FILTER_LINEAR, __IMG_FILTER_LINEAR)
							end
						end
					end

				end
				screen.print(20,y,tmp[i].name,1.0,color.white,color.blue,__ALEFT)

				y += 32
			end

			--Bar Scroll
			local ybar, h = 70, (maximset*32)-2
			draw.fillrect(3, ybar-2, 8, h, color.shine)
			if scrids.maxim >= maximset then -- Draw Scroll Bar
				local pos_height = math.max(h/scrids.maxim, maximset)
				draw.fillrect(3, ybar-2 + ((h-pos_height)/(scrids.maxim-1))*(scrids.sel-1), 8, pos_height, color.new(0,255,0))
			end

			if preview then
				preview:blit(700,84)
			end

			screen.print(15,400, strings.editbubbles, 1, color.white, color.blue, __ALEFT)
			screen.print(15,425, obj.id, 1, color.white, color.blue, __ALEFT)
			screen.print(15,450, obj.title, 1, color.white, color.blue, __ALEFT)

			if inside and find_png then
				screen.print(480,523,strings.reinstall,1.0,color.green,color.gray,__ACENTER)
			end

		else
			screen.print(480,230, strings.notresources, 1, color.white, color.red, __ACENTER)
		end

		if inside then
			screen.print(480,490, SYMBOL_BACK..": "..strings.togoback, 1, color.white, color.blue, __ACENTER)
		else
			screen.print(480,523, SYMBOL_BACK..": "..strings.togoback, 1, color.white, color.blue, __ACENTER)
		end

		draw.fillrect(0,516,960,30, 0x64545353)--Down

		screen.flip()

		--Controls
		if scrids.maxim > 0 then

			if (buttons.up or buttons.analogly < -60) then
				if scrids:up() then preview = nil end
			end

			if (buttons.down or buttons.analogly > 60) then
				if scrids:down() then preview = nil end
			end

			if buttons[accept] and tmp[scrids.sel].directory then
				table.insert(backl, {maxim = scrids.maxim, ini = scrids.ini, sel = scrids.sel, lim = scrids.lim })
				inside = true
				newpath = "ux0:ABM/"..tmp[scrids.sel].name
				local png = files.listfiles(newpath)
				if png then
					table.sort(png,function(a,b) return string.lower(a.name)<string.lower(b.name) end)
					if #png > 0 then
						tmp = {}
						for i=1,#png do
							if png[i].ext:upper() == "PNG" or png[i].ext:upper() == "XML" then
								for j=1,#resources do
									if png[i].name:upper() == resources[j].name then
										table.insert(tmp, { name = png[i].name, path = png[i].path, ext = png[i].ext, directory = png[i].directory or false })
										find_png = true
									end
								end
								
							end
						end
						maximset = 5
						scrids = newScroll(tmp, maximset)
					end
				end
			end

			if buttons[cancel] then
				if inside then
					newpath = files.nofile(newpath)
					tmp = files.listdirs(newpath)

					if tmp then table.sort(tmp,function(a,b) return string.lower(a.name)<string.lower(b.name) end)
					else tmp = {} end

					preview, find_png, inside, backlist = nil,false,false,{}
					maximset = 10
					scrids:set(tmp,maximset)
					if #backl>0 then
						if scrids.maxim == backl[#backl].maxim then
							scrids.ini = backl[#backl].ini
							scrids.lim = backl[#backl].lim
							scrids.sel = backl[#backl].sel
						end
						backl[#backl] = nil
					end

				else
					buttons.read() break
				end
			end

			if buttons.start and find_png and inside then--hacer la reinstalación
				local img = nil
				local path_tmp = ("ux0:data/vpk_abm/")
				files.delete(path_tmp)
				files.mkdir(path_tmp)
				for i=1,#resources do
					for j=1,#tmp do

						if tmp[j].name:upper() == resources[i].name then

							--Resources to 8bits
							buttons.homepopup(0)

								if back2 then back2:blit(0,0) end

								if i < 5 then

									img = image.load(tmp[j].path)
									if img then
										img:resize(252,151)
										img:center()
										img:blit(480,272)
									end

									draw.fillrect(0,0,960,30, color.shine)
									screen.print(10,10,strings.convert)
									screen.print(950,10,resources[i].name,1, color.white, color.blue, __ARIGHT)
									screen.flip()

									if img then
										files.copy(obj.path..resources[i].dest, path_tmp)--backup
										img:reset()

										local scale = false
										if img:getrealw() != resources[i].w or img:getrealh() != resources[i].h then
											img=img:copyscale(resources[i].w, resources[i].h)
											scale = true
										end

										if __8PNG == 1 then
											image.save(img, obj.path..resources[i].dest, 1)
										else
											if scale then
												image.save(img, obj.path..resources[i].dest, 1)
											else
												files.copy(tmp[j].path, obj.path..resources[i].restore)
											end
										end
									end

								else
									files.copy(obj.path..resources[i].dest, path_tmp)--backup
									files.copy(tmp[j].path, obj.path..resources[i].dest)
								end
							buttons.homepopup(1)
						end
					end
				end--for
				buttons.homepopup(1)


				--Install Bubble
				buttons.homepopup(0)
					files.copy(obj.path.."/sce_sys/package/",path_tmp)--backup
					files.copy("ur0:shell/db/app.db",path_tmp)
					bubble_id,reinstall = obj.id,true
					result = game.installdir(obj.path)
					if result != 1 then
						--Restore
						files.copy(path_tmp.."app.db", "ur0:shell/db/")
						files.copy(path_tmp.."package/",obj.path.."/sce_sys/")
						for i=1,#resources do
							files.copy(path_tmp..resources[i].name, obj.path..resources[i].restore)
						end
						os.message(strings.errinst)
					end
					buttons.read()--flush
					files.delete(path_tmp)
					reinstall = false
				buttons.homepopup(1)

				buttons.read() break
			end

		else

			if buttons[cancel] and inside then
				newpath = files.nofile(newpath)
				tmp = files.listdirs(newpath)

				if tmp then table.sort(tmp,function(a,b) return string.lower(a.name)<string.lower(b.name) end)
				else tmp = {} end

				preview, find_png, inside, backlist = nil,false,false,{}
				scrids:set(tmp,maximset)
				if #backl>0 then
					if scrids.maxim == backl[#backl].maxim then
						scrids.ini = backl[#backl].ini
						scrids.lim = backl[#backl].lim
						scrids.sel = backl[#backl].sel
					end
					backl[#backl] = nil
				end
			end

			if buttons.released[cancel] and not inside then buttons.read() break end

		end--maxim>0

	end--while

end
