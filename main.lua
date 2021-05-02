 -- add your test snippets and other code here, that you want to quickly
-- try out without writing a full blown 'tool'...

-- dummy: recursively prints all available functions and classes
rprint("Run Serial Killa 2")


--***Fx Column
--renoise.song().patterns[1].tracks[1].lines[1].effect_columns[1].number_string="0A"


--***Add a colscan
--renoise.song().patterns[1].tracks[1].lines[1].colscan_columns[1].colscan_value=89

--------------------------------------------------------------------------------
-- matrix Generation Logic
--------------------------------------------------------------------------------

local initialized_prime = {0,1,2,3,4,5,6,7,8,9,10,11}
local generated_prime = {}

local  current_prime_index = 0
local  current_prime_val = 0

local chromatic_offset = 60

local spray_spacing = 6

local vb = renoise.ViewBuilder()
local view_input = vb.views

local initialized_prime = {0,1,2,3,4,5,6,7,8,9,10,11}
local generated_prime = {}

local last_button_id = "P1"

local last_cell_id = "1_1"

local active_prime_type="P"
local active_prime_index=1
local active_prime_degree=1


local function generate_prime() 
  
  print("renoise.ViewBuilder().views")
  
  local pookie = "1_1"
  
  print(vb.views[pookie].text)
  
  initialized_prime = {0,1,2,3,4,5,6,7,8,9,10,11}
  generated_prime = {}
  
  local  current_prime_index = 0
  local  current_prime_val = 0
  
  for prime_gen_index = 1,12 do
    --rprint(initialized_prime[prime_gen_index])
     --generate a random index
     current_prime_index=math.random(1,13-prime_gen_index)
     
     rprint(initialized_prime[current_prime_index])     
     current_prime_val=initialized_prime[current_prime_index]
     
     table.remove(initialized_prime,current_prime_index)
     
     table.insert(generated_prime,current_prime_val)
     
     --[[
     renoise.song().patterns[19].tracks[4].lines[spray_spacing*(prime_gen_index)-(spray_spacing-1)].note_columns[1].note_value=current_prime_val+chromatic_offset
     renoise.song().patterns[19].tracks[4].lines[spray_spacing*(prime_gen_index)-(spray_spacing-1)].note_columns[1].instrument_string='01'     
    ]]--
    
    for prime_index_col = 1,12 do
      local tf_in = "prime_in"..tostring(prime_index_col)
      view_input[tf_in].text = tostring(generated_prime[prime_index_col])
    end 

      
  end

  generate_matrix()   
  
end

function load_custom_prime()
  for prime_index_col = 1,12 do
      local tf_in = "prime_in"..tostring(prime_index_col)
      generated_prime[prime_index_col]=view_input[tf_in].text
   end    
   generate_matrix()
end

function generate_matrix()
  for prime_index_col = 1,12 do
    for prime_index_row = 1,12 do
    
      local cell_id = tostring(prime_index_row).."_"..tostring(prime_index_col)
      local cell_id_vel = "vel"..cell_id
      local cell_id_aux = "aux"..cell_id
       
      local degree_offset=(generated_prime[prime_index_row]-generated_prime[1])
      local vel_loc = "deg_vel_in"..prime_index_col
      local aux_loc = "deg_aux_in"..prime_index_col
      
      local curvel = tostring(view_input[vel_loc].text)
      local curaux = tostring(view_input[aux_loc].text)
      
      print("view_input["..vel_loc.."].text")
      print(tostring(view_input[vel_loc].text))
      
      view_input[cell_id].text = tostring((generated_prime[prime_index_col]-degree_offset)%12)
      view_input[cell_id_vel].text = curvel
      view_input[cell_id_aux].text = curaux
    end
  end

  local buttonname = "P1"
 
  view_input[buttonname].color = {0x00, 0x00, 0x00}
end


--------------------------------------------------------------------------------
-- Helper Functions / API
--------------------------------------------------------------------------------

local function show_status(message)
  renoise.app():show_status(message)
  print(message)
end

renoise.tool():add_keybinding {
    name = "Global:Tools:Serial Killa",
    invoke = function() draw_tool_window2() end
  }

local function getmatrixdegree(primetype,primeindex,degree)
  
  local row_index
  local col_index
  
  local fetched_degree
  
  
  if primetype==("P") then
     col_index=degree
     row_index=primeindex
  elseif primetype==("I") then
     col_index=primeindex
     row_index=degree
  elseif primetype==("R") then
     col_index=13-degree
     row_index=primeindex
  elseif primetype==("RI") then
     col_index=primeindex
     row_index=13-degree
  else
    print("invalid primetype")
    return
  end
  
  local mat_cell_id = tostring(row_index).."_"..tostring(col_index)

  print(mat_cell_id)
  print(view_input[mat_cell_id].text)
  
  return view_input[mat_cell_id].text
  
end

local function prime_but_fcn(button_id)
  print("button_id")
  
  
  
  --view_input[last_button_id].color={0,0,0}
 
  view_input[button_id].color={0x22, 0xaa, 0xff}
  
  last_button_id = button_id
end

local function coloractivedegree(primetype,primeindex,degree)

  local row_index
  local col_index
 

  if primetype==("P") then
     col_index=degree
     row_index=primeindex
  elseif primetype==("I") then
     col_index=primeindex
     row_index=degree
  elseif primetype==("R") then
     col_index=13-degree
     row_index=primeindex
  elseif primetype==("RI") then
     col_index=primeindex
     row_index=13-degree
  else
    print("invalid primetype")
    return
  end
  
  view_input[last_cell_id].style = "disabled"

  local cell_id = tostring(row_index).."_"..tostring(col_index)
  print(cell_id)
  view_input[cell_id].style = "strong"
  
  last_cell_id = cell_id
  
end

function placenote(degreein)
  local cureditpos = renoise.song().transport.edit_pos
  local curtrack =renoise.song().selected_track_index
  local curvel = tonumber(view_input.base_vel_num.text)
  local curinst = tonumber(view_input.base_inst_num.text)

  
  renoise.song().patterns[cureditpos.sequence].tracks[curtrack].lines[cureditpos.line].note_columns[1].note_value=degreein+chromatic_offset
  renoise.song().patterns[cureditpos.sequence].tracks[curtrack].lines[cureditpos.line].note_columns[1].volume_value = curvel
  renoise.song().patterns[cureditpos.sequence].tracks[curtrack].lines[cureditpos.line].note_columns[1].instrument_value = curinst
  
  
end

function jumpbystep(manualeditstep)
    local tmp_pos = renoise.song().transport.edit_pos
    tmp_pos.global_line_index = tmp_pos.global_line_index + manualeditstep
    renoise.song().transport.edit_pos = tmp_pos

end

------------------
--global line index API expansion (special thanks to user "Joule" <333
------------------
renoise.SongPos.global_line_index = property(
  function(obj)
    local lines_amt, song = 0, renoise.song()
    local pat_seq = song.sequencer.pattern_sequence
    for seq_idx = 1, obj.sequence do
      lines_amt = (seq_idx == obj.sequence) and lines_amt + obj.line or
      lines_amt + song:pattern(pat_seq[seq_idx]).number_of_lines
    end
    return lines_amt
  end,

  function(obj, val)
    assert(val > 0, "global_line_index must be larger than 0.")
    local line_inc, song = 0, renoise.song()
    local pat_seq = song.sequencer.pattern_sequence
    for seq_idx = 1, #pat_seq do
      local pattern_lines = song:pattern(pat_seq[seq_idx]).number_of_lines
      line_inc = line_inc + pattern_lines
      if (val <= line_inc) then
        obj.sequence = seq_idx
        obj.line = pattern_lines - line_inc + val
        return
      end
    end
    error("Global line (" .. tostring(val) .. ") is out of bounds.")
  end
)

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Serial Killa",
  invoke = function() draw_tool_window2() end 
}




function draw_tool_window2()
   -- as shown in dynamic_content(), you can build views either in the "nested"
  -- notation, or "by hand". You can of course also combine both ways, for 
  -- example if you want to dynamically build equally behaving view "blocks"

  -- here is a simple example that creates a colscan-rowscan-matrix with buttons

 

  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local BUTTON_WIDTH = 2*renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local BUTTON_HEIGHT = BUTTON_WIDTH
  
  local DEFAULT_DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DEFAULT_CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
    
  local dialog_content = vb:column {}
  
  local settings_row = vb:row {}
  local menu_row = vb:row {}
  
  local row_completed = false
  
  local menu_button_scale = 2
  local matrix_button_scale = 1
    
    --[[
    local reset_button = vb:button {
        text = "Reset",
        tooltip = "Click to Reset",
        notifier = function()
          --local my_text_view = vb.views.prime_el_A
          --my_text_view.text = "Button was hit."
              
          draw_tool_window2()
        end
      }
    --]]
   
  --[[base note stuff
  local base_note_txt = vb:text {
      width = BUTTON_WIDTH,
      height = BUTTON_HEIGHT/4,
      align = "center",
      text = "Base Note:"
    }
    
  local base_note_num = vb:textfield {
      width = BUTTON_WIDTH,
      height = BUTTON_HEIGHT/4,
      align = "center",
      text = "60",
      id = "base_note_num",
      notifier = function(text)
        rprint(text)
      end
  }]]--
              
  local base_vel_txt = vb:text {
      width = BUTTON_WIDTH,
      height = BUTTON_HEIGHT/menu_button_scale,
      align = "center",
      text = "Base Vel:"
    }
    
  local base_vel_num = vb:textfield {
      width = BUTTON_WIDTH,
      height = BUTTON_HEIGHT/menu_button_scale,
      align = "center",
      text = "126",
      id = "base_vel_num",
      notifier = function(text)
        rprint(text)
      end
      }   
      
  local base_inst_txt = vb:text {
      width = BUTTON_WIDTH,
      height = BUTTON_HEIGHT/menu_button_scale,
      align = "center",
      text = "inst #:"
    }
    
  local base_inst_num = vb:textfield {
      width = BUTTON_WIDTH,
      height = BUTTON_HEIGHT/menu_button_scale,
      align = "center",
      text = "0",
      id = "base_inst_num",
      notifier = function(text)
        rprint(text)
      end
      }
  ---buttons

  local gen_button = vb:button {
    text = "Generate Random Prime",
    tooltip = "Click to Generate Random Prime Serial Form",
    notifier = function()
      --local my_text_view = vb.views.prime_el_A
      --my_text_view.text = "Button was hit."
          
      generate_prime()
    end
  } 
  
   local load_button = vb:button {
        text = "Load User Prime",
        tooltip = "Click to Calculate Matrix from User Prime",
        notifier = function()
          --local my_text_view = vb.views.prime_el_A
          --my_text_view.text = "Button was hit."

          load_custom_prime()
        end
  }

  settings_row:add_child(base_vel_txt)
  settings_row:add_child(base_vel_num)
  settings_row:add_child(base_inst_txt)
  settings_row:add_child(base_inst_num)     
  
  --per note GUI
      
  local degree_chroma_row = vb:row {}
  local degree_vel_row = vb:row {}
  local degree_aux_row = vb:row {}
  
  --chroma
  for tfrowscan = 1,14 do
    if (tfrowscan==1) then
      local tf_obj =vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "note:"
        }
      degree_chroma_row:add_child(tf_obj) 
    elseif (tfrowscan==14) then
      local tf_obj =vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = " "
        }
      degree_chroma_row:add_child(tf_obj) 
   
    else
      local tf_obj =vb:textfield {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = " ",
          id = "prime_in"..tfrowscan-1,
          rprint("prime_in"..tfrowscan-1)
        }
      degree_chroma_row:add_child(tf_obj)
    end
  end
  
  --velocity  
  for tfrowscan = 1,14 do
    if (tfrowscan==1) then
      local tf_obj =vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "vel:"
        }
      degree_vel_row:add_child(tf_obj) 
    elseif (tfrowscan==14) then
      local tf_obj =vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = " "
        }
      degree_vel_row:add_child(tf_obj) 
   
    else
      local tf_obj =vb:textfield {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "127",
          id = "deg_vel_in"..tfrowscan-1,
          rprint("deg_vel_in"..tfrowscan-1)
        }
      degree_vel_row:add_child(tf_obj)
    end
  end
  
  --aux  
  for tfrowscan = 1,14 do
    if (tfrowscan==1) then
      local tf_obj =vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "aux:"
        }
      degree_aux_row:add_child(tf_obj) 
    elseif (tfrowscan==14) then
      local tf_obj =vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = " "
        }
      degree_aux_row:add_child(tf_obj) 
   
    else
      local tf_obj =vb:textfield {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "127",
          id = "deg_aux_in"..tfrowscan-1,
          rprint("deg_aux_in"..tfrowscan-1)
        }
      degree_aux_row:add_child(tf_obj)
    end
  end
  
  
  --order pre-matrix GUI

  
  dialog_content:add_child(settings_row)  
  
  menu_row:add_child(gen_button)
  dialog_content:add_child(menu_row)
  
  dialog_content:add_child(degree_chroma_row)
  dialog_content:add_child(degree_vel_row)
  dialog_content:add_child(degree_aux_row)
  
  dialog_content:add_child(load_button)
  
      

  for rowscan = 1,14 do
    -- create a row for each rowscan
    local rowscan_row = vb:row {}

    for colscan = 1,14 do
      
      if ((rowscan==1)and(colscan==1))or((rowscan==1)and(colscan==14))or((rowscan==14)and(colscan==1))or((rowscan==14)and(colscan==14)) then
        local colscan_button =vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT,
          align = "center",
          text = " "
        }  
        
        rowscan_row:add_child(colscan_button)
    
      elseif (colscan == 1) then
      
        local colscan_button = vb:button {
              width = BUTTON_WIDTH,
              height = BUTTON_HEIGHT,
              text = "P"..tostring(rowscan-1),
              id = "P"..tostring(rowscan-1),
              
              notifier = function(width)
                active_prime_type="P"
                active_prime_index=(rowscan-1)
                active_prime_degree=1
                
                prime_but_fcn("P"..tostring(rowscan-1))
                coloractivedegree("P",tostring(rowscan-1),1)
              end
      
            }
        rowscan_row:add_child(colscan_button)
      elseif (colscan == 14) then
      
        local colscan_button = vb:button {
              width = BUTTON_WIDTH,
              height = BUTTON_HEIGHT,
              text = "R"..tostring(rowscan-1),
              id = "R"..tostring(rowscan-1),
      
              notifier = function()
                active_prime_type="R"
                active_prime_index=(rowscan-1)
                active_prime_degree=1
                
                prime_but_fcn("R"..tostring(rowscan-1))
                coloractivedegree("R",tostring(rowscan-1),1)
              end
      
            }
        rowscan_row:add_child(colscan_button)
      elseif (rowscan == 1) then
      
        local rowscan_button = vb:button {
              width = BUTTON_WIDTH,
              height = BUTTON_HEIGHT,
              text ="I"..tostring(colscan-1),
              id ="I"..tostring(colscan-1),
      
              notifier = function()
                active_prime_type="I"
                active_prime_index=(colscan-1)
                active_prime_degree=1
              
                prime_but_fcn("I"..tostring(colscan-1))
                coloractivedegree("I",tostring(colscan-1),1)
              end
      
            }
        rowscan_row:add_child(rowscan_button)
      elseif (rowscan == 14) then
      
        local rowscan_button = vb:button {
              width = BUTTON_WIDTH,
              height = BUTTON_HEIGHT,
              text = "RI"..tostring(colscan-1),
              id = "RI"..tostring(colscan-1),
      
              notifier = function()
                active_prime_type="RI"
                active_prime_index=(colscan-1)
                active_prime_degree=1
                
                prime_but_fcn("RI"..tostring(colscan-1))
                coloractivedegree("RI",tostring(colscan-1),1)
              end
      
            }
        rowscan_row:add_child(rowscan_button)
          
      else --indices are displayed here
      ---matrix cell text fields
      
      local colscan_button = vb:column {
        spacing = -10
      }
      
        local chroma_val = vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/3,
          align = "center",
          id = tostring(rowscan-1).."_"..tostring(colscan-1),
          --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
          text = "XXX",
          style = "disabled"
        }
        
        local vel_val = vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/3,
          align = "center",
          id = "vel"..tostring(rowscan-1).."_"..tostring(colscan-1),
          --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
          text = "YYY",
          style = "disabled"
        }
        
        local aux_val = vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/3,
          align = "center",
          id = "aux"..tostring(rowscan-1).."_"..tostring(colscan-1),
          --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
          text = "ZZZ",
          style = "disabled"
        }
        
        colscan_button:add_child(chroma_val)
        colscan_button:add_child(vel_val)
        colscan_button:add_child(aux_val)
        rowscan_row:add_child(colscan_button)
        
      end
      
      
    end

    dialog_content:add_child(rowscan_row)
  end
  
  local punch_row = vb:row{}
  
  local punch_button = vb:button {
              width = BUTTON_WIDTH*4,
              height = BUTTON_HEIGHT/menu_button_scale,
              text = "Punch",
      
              notifier = function()

                local received_degree

                received_degree = getmatrixdegree(active_prime_type,active_prime_index,active_prime_degree)
                print(received_degree)
                placenote(received_degree)

               
                local editstep_tmp = renoise.song().transport.edit_step
                
                jumpbystep(editstep_tmp)
                
                renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
                
                active_prime_degree=active_prime_degree+1
                
                if(active_prime_degree==13) then
                  print('prime row complete')
                  view_input[active_prime_type..active_prime_index].color={0x22, 0xaa, 0x00}
                  active_prime_degree=1
                end
                
                coloractivedegree(active_prime_type,active_prime_index,active_prime_degree)
              end
      
            }
            
  local jumpdown_button = vb:button {
              width = BUTTON_WIDTH*4,
              height = BUTTON_HEIGHT/menu_button_scale,
              text = "JumpDown by EditStep",
              
              notifier = function()
                local editstep_tmp = renoise.song().transport.edit_step
                
                jumpbystep(editstep_tmp)
                
                renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
              end
              }
            
  punch_row:add_child(punch_button)
  punch_row:add_child(jumpdown_button)   
  
  dialog_content:add_child(punch_row)

  renoise.app():show_custom_dialog(
    "Batch Building Views", dialog_content)
end



