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

------Enable Test Mode------
local test_mode = "true"
----------------------------

local initialized_prime = {0,1,2,3,4,5,6,7,8,9,10,11}
local generated_prime = {}

local chromaref = {"c","c#","d","d#","e","f","f#","g","g#","a","a#","b"}

local notetochroma = {}
notetochroma["c"] = 0
notetochroma["c#"] = 1
notetochroma["d"] = 2
notetochroma["d#"] = 3

notetochroma["e"] = 4
notetochroma["f"] = 5
notetochroma["f#"] = 6
notetochroma["g"] = 7

notetochroma["g#"] = 8
notetochroma["a"] = 9
notetochroma["a#"] = 10
notetochroma["b"] = 11

local current_prime_index = 0
local current_prime_val = 0

local chromatic_offset = renoise.song().transport.octave*12

local spray_spacing = 6

local vb = renoise.ViewBuilder()
local view_input = vb.views

local initialized_prime = {0,1,2,3,4,5,6,7,8,9,10,11}
local generated_prime = {}

local last_button_id = "punchbutton"  
local last_cell_id = "col1_1"

local active_prime_type="P"
local active_prime_index=1
local active_prime_degree=1

local note_inv_bool=true
local vel_inv_bool=false
local editstep_inv_bool=false
local aux_inv_bool=false

local global_edit_step = false
local aux_place_enable = false

local auxstr="0M"

local chromatic_inversion_axis = 12
local editstep_inversion_axis = 4

local editstep_tmp = renoise.song().transport.edit_step

local global_motif_length = 12

local spraymodeactive = false

local received_degree_info

local placenotebusy = false

local dialog_box_window

local matrix_column = vb:column{id = "matrixchild"}

local function generate_prime() 
    
  initialized_prime = {0,1,2,3,4,5,6,7,8,9,10,11}
  generated_prime = {}

  if global_motif_length ~= 12 then
    error("Motif length must be 12 for a 12 tone prime")
  end
  
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
  for prime_index_col = 1,global_motif_length do
      local tf_in = "prime_in"..tostring(prime_index_col)
      generated_prime[prime_index_col]=view_input[tf_in].text
   end    
   generate_matrix()
end

function generate_matrix()
  for prime_index_col = 1,global_motif_length do
    for prime_index_row = 1,global_motif_length do
    
      local cell_id = tostring(prime_index_row).."_"..tostring(prime_index_col)
      local cell_id_vel = "vel"..cell_id
      local cell_id_aux = "aux"..cell_id
      local cell_id_editstep = "step"..cell_id

      local vel_loc = "deg_vel_in"..prime_index_col
      local aux_loc = "deg_aux_in"..prime_index_col
      local editstep_loc = "deg_editstep_in"..prime_index_col

      print("generated_prime[prime_index_row]")
      print(generated_prime[prime_index_row])
      print("generated_prime[1]")
      print(generated_prime[1])

      local degree_offset=(generated_prime[prime_index_row]-generated_prime[1])
      local vel_offset=view_input["deg_vel_in"..prime_index_row].text-view_input.deg_vel_in1.text
      local aux_offset=view_input["deg_aux_in"..prime_index_row].text-view_input.deg_aux_in1.text
      local editstep_offset=view_input["deg_editstep_in"..prime_index_row].text-view_input.deg_editstep_in1.text
      
      local curvel = tostring(view_input[vel_loc].text)
      local curaux = tostring(view_input[aux_loc].text)
      local cureditstep = tostring(view_input[editstep_loc].text)
            
      --print("view_input["..vel_loc.."].text")
      --print(tostring(view_input[vel_loc].text))
      
      --inversion logic
      local rot_index = (prime_index_col+prime_index_row-2)%global_motif_length+1
      
      if note_inv_bool == true then
        view_input[cell_id].text = tostring((generated_prime[prime_index_col]-degree_offset)%chromatic_inversion_axis)
        
        view_input[cell_id].text = chromaref[tonumber(view_input[cell_id].text)+1]
        
      else
        local callindex = tostring(generated_prime[(prime_index_col+prime_index_row-2)%global_motif_length+1])
        view_input[cell_id].text = callindex
      end      
      
      if vel_inv_bool == true then
        view_input[cell_id_vel].text = tostring((view_input[vel_loc].text-vel_offset)%127)
      else
        view_input[cell_id_vel].text = view_input["deg_vel_in"..rot_index].text
      end
      
      if aux_inv_bool == true then
        view_input[cell_id_aux].text = tostring((view_input[aux_loc].text-aux_offset)%127)
      else
        view_input[cell_id_aux].text = view_input["deg_aux_in"..rot_index].text
      end
      
      if editstep_inv_bool == true then
        view_input[cell_id_editstep].text = tostring((view_input[editstep_loc].text-editstep_offset)%editstep_inversion_axis)
      else
        view_input[cell_id_editstep].text = view_input["deg_editstep_in"..rot_index].text
      end
    end
  end

  local buttonname = "punchbutton"
 
  view_input[buttonname].color = {0x00, 0x00, 0x00}
end


--------------------------------------------------------------------------------
-- Helper Functions / API
--------------------------------------------------------------------------------

function delay(seconds)  
   local init = os.clock()  
   while init+seconds > os.clock() do  
   -- nothing  
   end  
end  

local function show_status(message)
  renoise.app():show_status(message)
  print(message)
end

renoise.tool():add_keybinding {
    name = "Global:Tools:Serial Killa",
    invoke = function() draw_window() end
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
     col_index=global_motif_length+1-degree
     row_index=primeindex
  elseif primetype==("RI") then
     col_index=primeindex
     row_index=global_motif_length+1-degree
  else
    print("invalid primetype")
    return
  end
  
  local mat_cell_id = tostring(row_index).."_"..tostring(col_index)

  print(mat_cell_id)
  print(view_input[mat_cell_id].text)
  
  local degreeinfo = {}
  
  table.insert(degreeinfo,view_input[mat_cell_id].text)
  table.insert(degreeinfo,view_input["vel"..mat_cell_id].text)
  table.insert(degreeinfo,view_input["step"..mat_cell_id].text)
  table.insert(degreeinfo,view_input["aux"..mat_cell_id].text)
  
  return degreeinfo
  
end

local function prime_but_fcn(button_id)
  print("button_id")
  
  view_input[last_button_id].color={0,0,0}
 
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
     col_index=global_motif_length+1-degree
     row_index=primeindex
  elseif primetype==("RI") then
     col_index=primeindex
     row_index=global_motif_length+1-degree
  else
    print("invalid primetype")
    return
  end
  
  view_input[last_cell_id].style = "panel"

  local cell_id = "col"..tostring(row_index).."_"..tostring(col_index)
  print(cell_id)
  view_input[cell_id].style = "plain"
  
  last_cell_id = cell_id
  
end

function placenote(notein,curvelin,auxin)
  local cureditpos = renoise.song().transport.edit_pos
  local curtrack =renoise.song().selected_track_index
  local curvel = tonumber(curvelin)
  local curinst = tonumber(renoise.song().selected_instrument_index-1)
  local curaux = tonumber(auxin)
  local curcolumn = renoise.song().selected_note_column_index
  
  local degreein = notetochroma[notein]
  
  print("degreein")
  print(degreein)
  
  print("degreein - place note")
  print(degreein)
  print("curvelin")
  print(curvel)
  
  chromatic_offset = renoise.song().transport.octave*12  
  
  local noteplacepos = renoise.song().patterns[cureditpos.sequence].tracks[curtrack].lines[cureditpos.line].note_columns[curcolumn]
  
  noteplacepos.note_value=degreein+chromatic_offset
  noteplacepos.volume_value = curvel
  noteplacepos.instrument_value = curinst
  
  if aux_place_enable == true then
    renoise.song().patterns[cureditpos.sequence].tracks[curtrack].lines[cureditpos.line].effect_columns[1].number_string = auxstr
    renoise.song().patterns[cureditpos.sequence].tracks[curtrack].lines[cureditpos.line].effect_columns[1].amount_value = curaux
  end
  
  placenotebusy = false
  
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
    --error("Global line (" .. tostring(val) .. ") is out of bounds.")
    editwarning()
  end
)

function editwarning()

  local editwarning_title = "!Warning!"

  local editwarning_content = vb:text {
    text = "Your last punch reached past the end of score"
  }

  local editwarning_buttons = {"OK"}

  renoise.app():show_custom_prompt(
    editwarning_title, editwarning_content, editwarning_buttons)

end


----------------------------------------------
-- File Loading 
----------------------------------------------
local function load_file_in_bytes_to_table(file_types,dialog_title)
------------------------------------------------------------------------------------ 
  ----------------------------------------------------------
 --Helper to convert file stream stringbytes to "hex" format
 ----------------------------------------------------------
 local function num_to_hex_string(num)

 num = tonumber(num)
 if num == nil then
 return
 end
 --format to 2 digits hex and return 
 return string.format("%02X",num)
 end
  
  --------------------------------------------------------------------------------
  --read the user supplied file and put it byte by byte into a table using Lua io. 
  --------------------------------------------------------------------------------
  --create table to return
  local file_bytes = {}
  
  --get file path
  local file_in = renoise.app():prompt_for_filename_to_read(file_types,dialog_title)
  
  --check if file path returned
  if file_in == "" then
    return nil
  else 

    --incrementor so we can loop through whole file
    local inc = 1 
    ----------------
    -- //Lua io.//
    ----------------
    -- io.open(),opens a file -- needs to be called whether you are reading or writing to a file
    --"rb" indicates "read binary mode"
    -----------------------------------
    local file = assert(io.open(file_in,"rb"))   

    --loop through the file 1 byte at a time 
    while true do
      ---------------
      --//Lua io.//--
      ---------------
      --read the file 1 byte at a time
      ---------------------------------
      local current_byte = file:read(1)
           
      --if bytes exist continue looping
      if current_byte ~= nil then
        --convert string to bytes with the Lua string.byte()function
        --current_byte = string.byte(current_byte)
        --add byte to table using num_to_hex_string()
        --file_bytes[inc] = num_to_hex_string(current_byte)
        file_bytes[inc] = current_byte
        
        ---------------
        --//Lua io.//--
        ---------------
        --increment file stream pointer along the file
        --"set" means the `inc` offset is counted from file start ("cur" and "end" can be used as alternatives here)
        ---------------------
        file:seek("set", inc)
        --increment for next time round (used for `file_bytes` and file:seek)
        inc = inc + 1 
        
      else
        --break the loop as there are no more bytes in the file
        break
      end
    end   
  end
  return file_bytes  
end --of load file in bytes to table

--run above function and rprint returned table. If no file is loaded then nil will be printed
----------------------------------------------------------------------------------------------

--[[dataload_in = load_file_in_bytes_to_table({"*.srl"},"Choose a .srl SerialKilla File")]]--

--[[
dataparse1 = {}
for s in dataload_in:gmatch("[^\r\n]+") do
    table.insert(lines, s)
end
--]]

local parsed_data = {}
local parse_stringbuf = ""
local parsed_index = 1
local byte_buffer
local dataload_in

local function file_parser()
  
  for s = 1, #dataload_in do
    
    local current_byte = string.byte(dataload_in[s])
    byte_buffer = dataload_in[s]
    --print(current_byte)
    
    if current_byte == 10 then
      parsed_data[parsed_index] = parse_stringbuf
      parsed_index = parsed_index+1
      parse_stringbuf = ""
    else
      parse_stringbuf = parse_stringbuf..byte_buffer
    end
  end
  
  local prsinc = 1
  
  for s in parsed_data[1]:gmatch("[^\r,]+") do
    local tf_in = "prime_in"..tostring(prsinc)
    view_input[tf_in].text = s
    prsinc = prsinc + 1
  end
  
  prsinc = 1
  
  for s in parsed_data[2]:gmatch("[^\r,]+") do
    local tf_in = "deg_vel_in"..tostring(prsinc)
    view_input[tf_in].text = s
    prsinc = prsinc + 1
  end 
  
  prsinc = 1
  
  for s in parsed_data[3]:gmatch("[^\r,]+") do
    local tf_in = "deg_editstep_in"..tostring(prsinc)
    view_input[tf_in].text = s
    prsinc = prsinc + 1
  end 
  
  prsinc = 1
  
  for s in parsed_data[4]:gmatch("[^\r,]+") do
    local tf_in = "deg_aux_in"..tostring(prsinc)
    view_input[tf_in].text = s
    prsinc = prsinc + 1
  end  
  
end


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Serial Killa",
  invoke = function() draw_window() end 
}

function draw_window()
   -- as shown in dynamic_content(), you can build views either in the "nested"
  -- notation, or "by hand". You can of course also combine both ways, for 
  -- example if you want to dynamically build equally behaving view "blocks"

  -- here is a simple example that creates a colscan-rowscan-matrix with buttons

 

  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

  local BUTTON_WIDTH = 2.7*renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local BUTTON_HEIGHT = 2*renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  
  local DEFAULT_DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DEFAULT_CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
    
  local dialog_content = vb:column {}
  
  local settings_row = vb:row {}
  local menu_row = vb:row {}
  
  local row_completed = false
  
  local menu_button_scale = 2
  local matrix_button_scale = 1    
   
  last_button_id = "punchbutton"  
  last_cell_id = "col1_1" 
   
  local function motiflen_chg()
    dialog_content:remove_child(matrix_column)
    --matrix_column = nil
    vb = renoise.ViewBuilder()
    view_input = vb.views
    matrix_column = vb:column{}
    dialog_box_window:close()
    draw_window()
  
  end
  
  local glbmotiflen_tf = vb:textfield {
      width = BUTTON_WIDTH,
      height = BUTTON_HEIGHT/2,
      align = "center",
      text = tostring(global_motif_length),
      id = "glbmotiflen",
      notifier = function(text)
        global_motif_length = tonumber(text)
        motiflen_chg()
      end
  }
  

    
   
  --base note stuff
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
  }
              
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
  local file_row = vb:row{}
  
  local loadfile_button = vb:button {
    text = "Load . srl File",
    tooltip = "Click to Load Serial Killa Preset",
    notifier = function()
      --local my_text_view = vb.views.prime_el_A
      --my_text_view.text = "Button was hit."
          
      dataload_in = load_file_in_bytes_to_table({"*.srl"},"Choose a .srl SerialKilla File")
      file_parser()
    end
  }

  file_row:add_child(loadfile_button)

  local gen_button = vb:button {
    text = "Generate Random Prime",
    tooltip = "Click to Generate Random Prime Serial Form",
    notifier = function()
      --local my_text_view = vb.views.prime_el_A
      --my_text_view.text = "Button was hit."
          
      generate_prime()
    end
  } 
  
  
  local gen_button = vb:button {
    text = "Generate Random Prime",
    tooltip = "Click to Generate Random Prime Serial Form",
    notifier = function()
      --local my_text_view = vb.views.prime_el_A
      --my_text_view.text = "Button was hit."
          
      generate_prime()
    end
  }
  
  -- editstep chooser 
  local editstepchooser_row = vb:row {
    vb:chooser {
      id = "chooser",
      value = 2,
      items = {"Global EditStep", "Per Note EditStep"},
      notifier = function(new_index)
        --print("new_index:")
        --print(new_index)
        if new_index == 1 then
          global_edit_step = true
        else
          global_edit_step = false
        end
      end
    }
  }
  
  local auxstr_tf = vb:textfield {
      width = BUTTON_WIDTH,
      height = BUTTON_HEIGHT/2,
      align = "center",
      text = "0M",
      id = "Aux Prefix",
      notifier = function(text)
        auxstr = text
      end
  }
  
  -- aux enable chooser 
  local auxenable_row = vb:row {
    vb:chooser {
      id = "auxenable",
      value = 2,
      items = {"Aux Place - On", "Aux Place - Off"},
      notifier = function(new_index)
        if new_index == 1 then
          aux_place_enable = true  
        else
          aux_place_enable = false
        end
      end
    }
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
  
  ----------------------------
  --per degree GUI
  ----------------------------    

  
  local degree_chroma_row = vb:row {}
  local degree_vel_row = vb:row {}
  local degree_aux_row = vb:row {}
  local degree_editstep_row = vb:row {}
  
  --chroma
  for tfrowscan = 1,(global_motif_length+2) do
    if (tfrowscan==1) then
      local tf_obj =vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "degree:"
        }
      degree_chroma_row:add_child(tf_obj) 
    elseif (tfrowscan==(global_motif_length+2)) then
      --[[
      local tf_obj =vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = " "
        }
      ]]--
      local tf_obj = vb:row{}
      
      local note_inv_bool = vb:checkbox {
        value = true,
        id = "note_inv_bool",
        notifier = function(value)
            note_inv_bool = value
        end,
      }
      
      tf_obj:add_child(note_inv_bool)
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
  for tfrowscan = 1,(global_motif_length+2) do
    if (tfrowscan==1) then
      local tf_obj =vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "vel:"
        }
      
      degree_vel_row:add_child(tf_obj) 
    
    elseif (tfrowscan==(global_motif_length+2)) then
      
      local tf_obj = vb:row{}
    
      local vel_inv_bool = vb:checkbox {
        value = false,
        id = "vel_inv_bool",
        notifier = function(value)
          vel_inv_bool = value 
        end,
      }
      
      tf_obj:add_child(vel_inv_bool)
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
  for tfrowscan = 1,(global_motif_length+2) do
    if (tfrowscan==1) then
      local tf_obj =vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "aux:"
        }
      degree_aux_row:add_child(tf_obj) 
    elseif (tfrowscan==(global_motif_length+2)) then
      
      local tf_obj = vb:row{}
    
      local aux_inv_bool = vb:checkbox {
        value = false,
        id = "aux_inv_bool",
        notifier = function(value)
          aux_inv_bool = value  
        end,
      }
      
      tf_obj:add_child(aux_inv_bool)
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
  
  --editstep  
  for tfrowscan = 1,(global_motif_length+2) do
    if (tfrowscan==1) then
      local tf_obj =vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "step:"
        }
      degree_editstep_row:add_child(tf_obj) 
    elseif (tfrowscan==(global_motif_length+2)) then
      
     local tf_obj = vb:row{}
    
      local editstep_inv_bool = vb:checkbox {
        value = false,
        id = "editstep_inv_bool",
        notifier = function(value)
          editstep_inv_bool = value  
        end,
      }
      
      tf_obj:add_child(editstep_inv_bool)
      degree_editstep_row:add_child(tf_obj) 
   
    else
      local tf_obj =vb:textfield {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "12",
          id = "deg_editstep_in"..tfrowscan-1,
          rprint("deg_editstep_in"..tfrowscan-1)
        }
      degree_editstep_row:add_child(tf_obj)
    end
  end
  
  -----------------------
  --pre-matrix GUI build
  -----------------------
  
  --dialog_content:add_child(settings_row)  
  
  dialog_content:add_child(glbmotiflen_tf)
  dialog_content:add_child(file_row)
  menu_row:add_child(gen_button)
  dialog_content:add_child(menu_row)
  dialog_content:add_child(editstepchooser_row)
  dialog_content:add_child(auxenable_row)
  dialog_content:add_child(auxstr_tf)

  
  dialog_content:add_child(degree_chroma_row)
  dialog_content:add_child(degree_vel_row)
  dialog_content:add_child(degree_editstep_row)
  dialog_content:add_child(degree_aux_row)
  
  dialog_content:add_child(load_button)
  
  --------------------
  ------matrix GUI
  --------------------
 
  local function drawmatrixgui()
  
    
       
    for rowscan = 1,(global_motif_length+2) do
      -- create a row for each rowscan
      local rowscan_row = vb:row {}
  
      for colscan = 1,(global_motif_length+2) do
        
        if ((rowscan==1)and(colscan==1))or((rowscan==1)and(colscan==(global_motif_length+2)))or((rowscan==(global_motif_length+2))and(colscan==1))or((rowscan==(global_motif_length+2))and(colscan==(global_motif_length+2))) then
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
        elseif (colscan == (global_motif_length+2)) then
        
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
        elseif (rowscan == (global_motif_length+2)) then
        
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
        
        -----------
        --
        --------------
        local cell_column = vb:column{
          style = "panel",
          id = "col"..tostring(rowscan-1).."_"..tostring(colscan-1),
  
        }
          local cell_row_top = vb:row {
          width = BUTTON_WIDTH,
  
        }
        local cell_row_bottom = vb:row {
          width = BUTTON_WIDTH,
  
        }
        
        local chroma_val = vb:horizontal_aligner {
          width = BUTTON_WIDTH/2,
          mode = "left",
          vb:text {
            height = BUTTON_HEIGHT/2,
            id = tostring(rowscan-1).."_"..tostring(colscan-1),
            --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
            text = "N",
            font = "big",
            style = "strong",
            align = "center"
          },
        }
        
        local vel_val = vb:horizontal_aligner {
          width = BUTTON_WIDTH/2,
          mode = "right",       
          vb:text {
            height = BUTTON_HEIGHT/2,
            id = "vel"..tostring(rowscan-1).."_"..tostring(colscan-1),
            --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
            text = "V",
            align = "center"
          },
        }
        
        local step_val = vb:horizontal_aligner {
          width = BUTTON_WIDTH/2,
          mode = "left",
          vb:text {
            height = BUTTON_HEIGHT/3,
            id = "step"..tostring(rowscan-1).."_"..tostring(colscan-1),
            --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
            text = "S",
            align = "center",
          },
        }
        
        local aux_val = vb:horizontal_aligner {
          width = BUTTON_WIDTH/2,
          mode = "right",
          vb:text {
            height = BUTTON_HEIGHT/3,
            id = "aux"..tostring(rowscan-1).."_"..tostring(colscan-1),
            --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
            text = "A",
            style = "disabled",
            align = "left"
          },
        }
        
        cell_row_top:add_child(chroma_val)
        cell_row_top:add_child(vel_val)
        cell_row_bottom:add_child(step_val)
        cell_row_bottom:add_child(aux_val)
        cell_column:add_child(cell_row_top)
        cell_column:add_child(cell_row_bottom)
        rowscan_row:add_child(cell_column)
          
        end
        
        
      end
  
      --dialog_content:add_child(rowscan_row)
        matrix_column:add_child(rowscan_row)  
    end
    
    dialog_content:add_child(matrix_column)
    
  end
  
  
  drawmatrixgui() 
  
  -------------------------
  ---post matrix GUI
  ----------------------
  local punch_row = vb:row{}
  
  local function punchaction()
     
    received_degree_info = getmatrixdegree(active_prime_type,active_prime_index,active_prime_degree)
      
    --place note
    placenote(received_degree_info[1],received_degree_info[2],received_degree_info[4])
        
    if global_edit_step == false then            
      editstep_tmp = received_degree_info[3]
    else
      editstep_tmp = renoise.song().transport.edit_step
    end                 
      
    jumpbystep(editstep_tmp)

    
    active_prime_degree=active_prime_degree+1
    
    if(active_prime_degree==(global_motif_length+1)) then
      print('prime row complete')
      
      last_button_id = "punchbutton"
      view_input[active_prime_type..active_prime_index].color={0x22, 0xaa, 0x00}
      
      spraymodeactive=false
      
      active_prime_degree=1
    end
    
    coloractivedegree(active_prime_type,active_prime_index,active_prime_degree)
  end
  
  
  local punch_button = vb:button {
    width = BUTTON_WIDTH*(global_motif_length+2)/3,
    height = BUTTON_HEIGHT/menu_button_scale,
    text = "Punch",
    id = "punchbutton",
    notifier = function()
      punchaction()      
    end
  
  }
            
  local jumpdown_button = vb:button {
    width = BUTTON_WIDTH*(global_motif_length+2)/3,
    height = BUTTON_HEIGHT/menu_button_scale,
    text = "Jump by EditStep",
    
    notifier = function()
      local editstep_tmp = renoise.song().transport.edit_step
      
      jumpbystep(editstep_tmp)
      
      renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
    end
  }
  
  local spray_button = vb:button {
    width = BUTTON_WIDTH*(global_motif_length+2)/3,
    height = BUTTON_HEIGHT/menu_button_scale,
    text = "Spray Row",
    
    notifier = function()
       punchaction() 
       punchaction() 
       punchaction() 
       punchaction() 
    end
  }
              
  punch_row:add_child(punch_button)
  --punch_row:add_child(spray_button)
  punch_row:add_child(jumpdown_button)   
  
  dialog_content:add_child(punch_row)

  dialog_box_window = renoise.app():show_custom_dialog(
    "Serial Killa", dialog_content)

    if test_mode == "true" then
      set_test_vars()
    end    
end

-------------------------
-- TESTING ZONE
-------------------------

function set_test_vars()
   print("test variables active")
   --generate_prime()
end





