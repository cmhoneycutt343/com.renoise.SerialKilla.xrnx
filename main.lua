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
----------------------------------------------------------------------------------------


------Enable Test Mode------
local test_mode = "true"
----------------------------

local do_draw = "false"

local first_load = "true"

--initialized 12 tone prime
local initialized_prime = {0,1,2,3,4,5,6,7,8,9,10,11}
local generated_prime = {}

--indexable note names
local chromaref = {"c","c#","d","d#","e","f","f#","g","g#","a","a#","b"}

--indexable scales

local scale_chromatic = {0,1,2,3,4,5,6,7,8,9,10,11}
local scale_major = {0,2,4,5,7,9,11}
local scale_natminor = {0,2,3,5,7,8,10}
local scale_harminor = {0,2,3,5,7,8,11}
local scale_majorpent = {0,2,4,7,9}
local scale_minorpent = {0,3,5,7,10}
local scale_list = {scale_chromatic,scale_major,scale_natminor,scale_harminor,scale_majorpent,scale_minorpent}

--sets default scale
local scale_current = scale_chromatic
local curscalelen = #scale_current

--table for converting note names back to chroma index
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

--global tonic

local tonic_offset = 0
local active_primebut_clr = 0

--indexing variables for generating 12 tone prime
local current_prime_index = 0
local current_prime_val = 0

--octave offset
--local chromatic_offset = renoise.song().transport.octave*12
local chromatic_offset
local relative_octave
local interval_inv = false

--'spray' editstep (currently unused)
local spray_spacing = 6

--view objects
local vb = renoise.ViewBuilder()
local view_input = vb.views
local dialog_box_window 
local quickrev_buf
local redraw_shell = vb:row{}
local dialog_content = vb:column {id = "dialogchild"}
--column to hold generated matrix and buttons (for redraw)
local matrix_column = vb:column{id = "matrixchild"}

--default button references
local last_button_id = "punchbutton"  
local last_cell_id = "col1_1"

--button mode options
local manual_mark_mode="false"
local notation_enable="true"
local notation_start="false"
local notstr_pat

--default prime references
local active_prime_type="P"
local active_prime_index=1
local active_prime_degree=1

--defaults for menu control
local note_inv_bool=true
local vel_inv_bool=false
local editstep_inv_bool=false
local editstep_scale = 1
local aux_inv_bool=false

local global_edit_step = true
local aux_place_enable = false

--buffer to save fields during tonal -> perc mode and back
local chromainv_modebuf
local octavemode_movebuf
local scale_movebuf


local auxstr="0M"

local chromatic_inversion_axis = 12
local editstep_inversion_axis = 12

--local editstep_tmp = renoise.song().transport.edit_step
local editstep_tmp

local global_motif_length = 12

local spraymodeactive = false

local received_degree_info

local placenotebusy = false

--loading variables
local booleantable = {false,true}
local booltonum = {}
booltonum[false] = 1
booltonum[true] = 2


------------------------------------------
--[[function to generate 12 tone prime]]--
------------------------------------------
local function generate_prime() 

  --error against motifs not of length 12
--[[  if global_motif_length ~= 12 then
    error("Motif length must be 12 for a 12 tone prime")
  end]]--
    
  --reinitialize prime values  
  initialized_prime = {0,1,2,3,4,5,6,7,8,9,10,11}
  generated_prime = {}
  local  current_prime_val = 0
  
  --generates 12 tone randomized prime
  for prime_gen_index = 1,12 do
    
     --generate a random index
     current_prime_index=math.random(1,13-prime_gen_index)
     
     --get the prime value     
     current_prime_val=initialized_prime[current_prime_index]
     
     --remove that prime value from list of remaining available chroma
     table.remove(initialized_prime,current_prime_index)
     
     --add prime to newly generated from list 
     table.insert(generated_prime,current_prime_val)
      
  end
  
  --load new prime into text fields
  for prime_index_col = 1,12 do
      local tf_in = "prime_in"..tostring(prime_index_col)
      view_input[tf_in].text = tostring(generated_prime[prime_index_col])
  end
  
  --generate matrix from new prime
  generate_matrix()   
  
  print("")
  print(view_input["1_1"].width)
  print(view_input.oct1_1.width)
  print(view_input.vel1_1.width)
  
  
  view_input.loaduserprimebutton.color = {0,0,0}
  
end

--loads chroma from textfields into matrix and generates
function load_custom_prime()
  for prime_index_col = 1,global_motif_length do
      local tf_in = "prime_in"..tostring(prime_index_col)
      generated_prime[prime_index_col]=view_input[tf_in].text
   end    
   generate_matrix()
end


--[[Completion Matrix Generation Logic]]--
function generate_matrix()
  
  --for each column
  for prime_index_col = 1,global_motif_length do
    --for each row
    for prime_index_row = 1,global_motif_length do
    
      --cell reference prefixes
      local cell_id = tostring(prime_index_row).."_"..tostring(prime_index_col)
      local cell_id_oct = "oct"..cell_id
      local cell_id_vel = "vel"..cell_id
      local cell_id_aux = "aux"..cell_id
      local cell_id_editstep = "step"..cell_id
      

      --column based 
      local vel_loc = "deg_vel_in"..prime_index_col
      local aux_loc = "deg_aux_in"..prime_index_col
      local editstep_loc = "deg_editstep_in"..prime_index_col

      --inversion offset based on value of first degree, velocity
      local degree_offset=(generated_prime[prime_index_row]-generated_prime[1])
      local vel_offset=view_input["deg_vel_in"..prime_index_row].text-view_input.deg_vel_in1.text
      local aux_offset=view_input["deg_aux_in"..prime_index_row].text-view_input.deg_aux_in1.text
      local editstep_offset=view_input["deg_editstep_in"..prime_index_row].text-view_input.deg_editstep_in1.text
      
      --current values from textfields
      local curvel = tostring(view_input[vel_loc].text)
      local curaux = tostring(view_input[aux_loc].text)
      local cureditstep = tostring(view_input[editstep_loc].text)
      
      --inversion logic
      local rot_index = (prime_index_col+prime_index_row-2)%global_motif_length+1
      
      
      
      ---------------------------
      --note inversion alg
      ---------------------------
      
      --if inverting.....
      if note_inv_bool == true then
        
        --incorporates scale inversion axis, offset, and degree from motif
        local offset_adjusted = (generated_prime[prime_index_col]-degree_offset)
        local symmat_index = tostring(generated_prime[(prime_index_col+prime_index_row-2)%global_motif_length+1])
        
        local relative_octave
        
        if(interval_inv == true) then
          if(prime_index_row>prime_index_col) then
            relative_octave = tostring(-math.floor(symmat_index/curscalelen))
            if(relative_octave=="-0") then
              relative_octave = "-1"
            end  
            --relative_octave = "-1"
          else
            relative_octave = tostring(math.floor(symmat_index/curscalelen))
            --relative_octave = "0"
          end
        else
          relative_octave = "0"
        end
        
        --fold with inversion axis       
        local inversion_stripped = tostring((offset_adjusted)%chromatic_inversion_axis)
        
        --gets scale degree index (0-scale length)
        local degree_get = tonumber(inversion_stripped)%(curscalelen)
                
        --convert scale degree to chroma
        local chromafromscale = scale_current[degree_get+1]
        
        --converts to "note" string and loads to text field      
        local notestrreturn = chromaref[(chromafromscale+tonic_offset)%12+1]
        
        --fill cell
        view_input[cell_id].text = notestrreturn
        view_input[cell_id_oct].text = relative_octave
      
      --if note inversion not activated...  
      else
        --gets chroma index   
        local symmat_index = tostring(generated_prime[(prime_index_col+prime_index_row-2)%global_motif_length+1])
        
        --get degree index 
        local degree_get = tonumber(symmat_index)%(curscalelen)
        local relative_octave = tostring(math.floor(symmat_index/curscalelen))
        
        --convert scale degree to chroma
        local chromafromscale = scale_current[degree_get+1]
        
        --converts to "note" string and loads to text field
        local notestreturn = chromaref[chromafromscale+1]
        
        --fill cell
        view_input[cell_id].text = notestreturn
        view_input[cell_id_oct].text = relative_octave
      end      
      
      
      
      
      
      --velocity inversion or not
      if vel_inv_bool == true then
        view_input[cell_id_vel].text = tostring((view_input[vel_loc].text-vel_offset)%127)
      else
        view_input[cell_id_vel].text = view_input["deg_vel_in"..rot_index].text
      end
      
      --auxilary inversion or not
      if aux_inv_bool == true then
        view_input[cell_id_aux].text = tostring((view_input[aux_loc].text-aux_offset)%127)
      else
        view_input[cell_id_aux].text = view_input["deg_aux_in"..rot_index].text
      end
      
      --editstep inversion or not
      if editstep_inv_bool == true then
        view_input[cell_id_editstep].text = tostring((view_input[editstep_loc].text-editstep_offset)%editstep_inversion_axis)
      else
        view_input[cell_id_editstep].text = view_input["deg_editstep_in"..rot_index].text
      end
    end
  end

  --recolors punch button????
  local buttonname = "punchbutton"
  view_input[buttonname].color = {0x00, 0x00, 0x00}

end


--------------------------------------------------------------------------------
-- Helper Functions / API
--------------------------------------------------------------------------------

--handles lua IO stuff
function io_write_txt( file, tbl )
    print( "------------------------ " )
    print( "write in "..file )
    io.output( io.open( file, "w" ) )
    io.write( tbl )
    io.close()
    print( "---- write done ----" )
end

function write_settings_to_file()

  --**calls file write prompt
  local file_out = renoise.app():prompt_for_filename_to_write(".srl", "mytitle")

  local s_indx

  --compile master table
  --1. degree list [multiple elements]
  local degreerow_out = ""
  
  for s_indx = 1,global_motif_length do
    degreerow_out = degreerow_out..view_input["prime_in"..s_indx].text
    if(s_indx<global_motif_length) then
      degreerow_out = degreerow_out..","
    end
  end
  
  --print("degreerow_out")
  --print(degreerow_out)
  
  --2. degree velocity list [multiple elements]
  local velrow_out = ""
  
  for s_indx = 1,global_motif_length do
    velrow_out = velrow_out..view_input["deg_vel_in"..s_indx].text
    if(s_indx<global_motif_length) then
      velrow_out = velrow_out..","
    end
  end
  
  --print("velrow_out")
  --print(velrow_out)
  
  --3. degree editstep list [multiple elements]
  local editsteprow_out = ""
  
  for s_indx = 1,global_motif_length do
    editsteprow_out = editsteprow_out..view_input["deg_editstep_in"..s_indx].text
    if(s_indx<global_motif_length) then
      editsteprow_out = editsteprow_out..","
    end
  end
  
  --print("editsteprow_out")
  --print(editsteprow_out)
  
  --4. degree auxilary list [multiple elements]
  local auxrow_out = ""
  
  for s_indx = 1,global_motif_length do
    auxrow_out = auxrow_out..view_input["deg_aux_in"..s_indx].text
    if(s_indx<global_motif_length) then
      auxrow_out = auxrow_out..","
    end
  end
 
  --print("auxrow_out")
  --print(auxrow_out)
  
  --5. inversion bools [4 bools]
  local invbool_out = ""
  
  invbool_out = invbool_out..tostring(booltonum[view_input.note_inv_bool.value])..","
  invbool_out = invbool_out..tostring(booltonum[view_input.vel_inv_bool.value])..","
  invbool_out = invbool_out..tostring(booltonum[view_input.editstep_inv_bool.value])..","
  invbool_out = invbool_out..tostring(booltonum[view_input.aux_inv_bool.value])
  
  --print("invbool_out")
  --print(invbool_out)
  
  --6. Editstep scale [1:num]
  local editstepscale_out = view_input.editstepscale.text
  
  --print("editstepscale_out")
  --print(editstepscale_out)
  
  --7. Editstep Inv Axis [1:num]
  local editstepinv_out = view_input.editstepinvaxis.text
  
  --print("editstepinv_out")
  --print(editstepinv_out)
  
  --8. Octave Option [chooser:2]
  local octaveoption_out = view_input.octavemode.value
  
  --print("octaveoption_out")
  --print(octaveoption_out)
  
  --9. Add notation [bool]
  local addnotebool_out = booltonum[view_input.notationenable.value]
  
  --print("addnotebool_out")
  --print(addnotebool_out) 
  
  --10. Editstep select [chooser:2]
  local editstepoptselect_out = view_input.editsteptype.value
  
  --print("editstepoptselect_out")
  --print(editstepoptselect_out)
  
  --11. Aux Place [chooser:2]
  local auxplaceoptselect_out = view_input.auxenable.value
  
  --print("auxplaceoptselect_out")
  --print(auxplaceoptselect_out)
  
  --12. Aux FX Prefix [2 Byte String]
  local auxfxprefix_out = view_input.auxprefix.text
  
  --print("auxfxprefix_out")
  --print(auxfxprefix_out)
  
  --13. Tonic Offset [chooser:12]
  local tonicoffset_out = view_input.tonicpopup.value
  
  --print("tonicoffset_out")
  --print(tonicoffset_out)
  
  --14. scale [chooser:6]
  local scaleselect_out = view_input.scalepopup.value
  
  --print("tonicoffset_out")
  --print(tonicoffset_out)
  
  --15. Chroma Inv Axis [1:int]
  local chromainvaxis_out = view_input.chromainvaxis.text
  
 print("chromainvaxis_out")
  print(chromainvaxis_out)

  --combine all variables into master table
  local outtbl =degreerow_out.."\n"..
             velrow_out.."\n"..
             editsteprow_out.."\n"..
             auxrow_out.."\n"..
             invbool_out.."\n"..
             editstepscale_out.."\n"..
             editstepinv_out.."\n"..
             octaveoption_out.."\n"..
             addnotebool_out.."\n"..
             editstepoptselect_out.."\n"..
             auxplaceoptselect_out.."\n"..
             auxfxprefix_out.."\n"..
             tonicoffset_out.."\n"..
             scaleselect_out.."\n"..
             chromainvaxis_out.."\n"
  

  io_write_txt( file_out, outtbl )

  print(outtbl)
end


local function show_status(message)
  renoise.app():show_status(message)
  print(message)
end

--adds SerialKilla to keyboard shortcuts
renoise.tool():add_keybinding {
    name = "Global:Tools:Serial Killa",
    invoke = function()      
      
      dialog_box_window = renoise.app():show_custom_dialog(
    "Serial Killa", redraw_shell)
      
    end
  }

local function updatescaleinfo(index)
  scale_current = scale_list[index]
  
  --load scale length
  curscalelen = #scale_current
    
  --set inversion axis
  chromatic_inversion_axis = curscalelen
  view_input.chromainvaxis.text = tostring(curscalelen)
end

--concatenate pattern comments  
local function concat_pat_name(patindex, patcom)
    local curcom = renoise.song().patterns[patindex].name
    renoise.song().patterns[patindex].name = curcom..patcom 
end 

-------------------------------
--[[gets chroma from matrix]]-- 
-------------------------------
local function retreivecellattribs(primetype,primeindex,degree)
  
  local row_index
  local col_index
  local fetched_degree
  local degreeinfo = {}
  
  --set row / column index based on prime type
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
  
  --recall cell id from row and column
  local mat_cell_id = tostring(row_index).."_"..tostring(col_index)
  
  --add relevant data to buffer table
  table.insert(degreeinfo,view_input[mat_cell_id].text)
  table.insert(degreeinfo,view_input["vel"..mat_cell_id].text)
  table.insert(degreeinfo,view_input["step"..mat_cell_id].text)
  table.insert(degreeinfo,view_input["aux"..mat_cell_id].text)
  table.insert(degreeinfo,view_input["oct"..mat_cell_id].text)
  
  --return data
  return degreeinfo 
end

--colors active prime button and resets last button
local function active_primebut_clr(button_id)
  
  --reset last button color
  view_input[last_button_id].color={0,0,0}
 
  --color current button blue
  view_input[button_id].color={0x22, 0xaa, 0xff}
  
  --set current button to set button
  last_button_id = button_id
end

--for manual marking
local function mark_primebut(button_id)
  
  --color current button green
  view_input[button_id].color={0x22, 0xaa, 0x00}
  --last_button_id = "punchbutton"
  
  if button_id == last_button_id then
    last_button_id = "punchbutton"
  end
  
end

--colors next 'prime' box for punchin
local function coloractivedegree(primetype,primeindex,degree)

  local row_index
  local col_index

  --set row / column index based on prime type
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
  
  --resets last degree box 
  view_input[last_cell_id].style = "panel"
  
  --colors current degree box
  local cell_id = "col"..tostring(row_index).."_"..tostring(col_index)
  print(cell_id)
  view_input[cell_id].style = "plain"
  
  --sets current box to last box
  last_cell_id = cell_id
end

-------------------------------------------------
--[[function that draws note into pattern seq]]--
-------------------------------------------------
function placenote(notein,curvelin,auxin,octin,noteplacein)
  --
  local cureditpos = renoise.song().transport.edit_pos
  local curtrack =renoise.song().selected_track_index
  local curcolumn = renoise.song().selected_note_column_index
  
  local curvel = tonumber(curvelin)
  local curinst = tonumber(renoise.song().selected_instrument_index-1)
  local curaux = tonumber(auxin)
  
  local curoct = 0
  
  --gets chroma index
  local degreein = notetochroma[notein]
  
  local oct_scale_crr = 0
  
  --correction to add octave to all notes 'below' the global tonic
  if(degreein<tonic_offset) then
    oct_scale_crr = 1 
  end
  
  --gets octave offset from GUI
  chromatic_offset = (renoise.song().transport.octave+tonumber(curoct)+oct_scale_crr)*12  
  
  --variable for place to write in pattern seq
  --[[
  local noteplacepos = renoise.song().patterns[cureditpos.sequence].tracks[curtrack].lines[cureditpos.line].note_columns[curcolumn]
  ]]--
  local noteplacepos = noteplacein
  
  --write to pattern seq
  local reloct_buf = tonumber(octin)
  
  noteplacepos.note_value=degreein+chromatic_offset+(reloct_buf*12)
  noteplacepos.volume_value = curvel
  noteplacepos.instrument_value = curinst

  --if aux place is enable  
  if aux_place_enable == true then
    renoise.song().patterns[cureditpos.sequence].tracks[curtrack].lines[cureditpos.line].effect_columns[1].number_string = auxstr
    renoise.song().patterns[cureditpos.sequence].tracks[curtrack].lines[cureditpos.line].effect_columns[1].amount_value = curaux
  end
  
  --placenotebusy = false
  
end

--jump by editstep
function jumpbystep(manualeditstep)
    --get pattern cursor position
    local tmp_pos = renoise.song().transport.edit_pos
    tmp_pos.global_line_index = tmp_pos.global_line_index + manualeditstep
    --move pattern cursor
    renoise.song().transport.edit_pos = tmp_pos
end

----------------------------------------------------------------------------
--[[global line index API expansion (special thanks to user "Joule" <333]]--
----------------------------------------------------------------------------
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

--parser datat buffers / index

--table whose elements are each lists of options, attribute, etc
local parsed_data = {}
local sub_parsed_data = {}
--buffer for elements of parsed_data
local parse_stringbuf = ""
local parser_index = 1
local byte_buffer
local dataload_in

-------------------------
--[[input file parser]]--
-------------------------
local function file_parser()
  
  parser_index = 1
  
  --for all bytes loaded from file/////
  for s = 1, #dataload_in do
    
    --convert current byte to hex 
    local current_byte = string.byte(dataload_in[s])
    --hole current byte as string
    byte_buffer = dataload_in[s]
    
    --if 'line feed (10)' byte
    if current_byte == 10 then
      --write compiled data field into single 'parsed_data' field
      parsed_data[parser_index] = parse_stringbuf
      --increment index and reinitialize buffer
      parser_index = parser_index+1
      parse_stringbuf = ""
    else
      --concatenate bytes until 'line feed' found
      parse_stringbuf = parse_stringbuf..byte_buffer
    end
  end
  
  -------------------------------
  --.SRL FILE FORMAT----
  -------------------------------
  --[[
  --a. individual options are seperated by line (aka 'linefeed' hex 0x10)
  --b. options with multiple fields are seperated by comma
  --c. booleans are '1' and '2' for false and true respectively
  --d. multi-choosers are 0,1,2...etc  
  --e. file must maintain order of variables below:
  
  1. degree list [multiple elements]
  **calculate 'motif_len' from this
  2. degree velocity list [multiple elements] 
  3. degree editstep list [multiple elements]
  4. degree auxilary list [multiple elements]
  5. inversion bools [4 bools]
  6. Editstep scale [1:num]
  7. Editstep Inv Axis [1:num]
  8. Octave Option [chooser:2]
  9. Add notation [bool]
  10. Editstep select [chooser:2]
  11. Aux Place [chooser:2]
  12. Aux FX Prefer [2 Byte String]
  13. Tonic Offset
  14. scale [chooser:6]
  15. Chromainvaxis
  
  ]]--
  
  local prsinc = 1
 
  ---**calculate 'motif_len'  
  for s in parsed_data[1]:gmatch("[^\r,]+") do
    prsinc = prsinc + 1
  end
  
  global_motif_length = prsinc-1
  view_input.glbmotiflen.text = tostring(global_motif_length)
 
  --1. degree list [multiple elements]
  local prsinc = 1   
  for s in parsed_data[1]:gmatch("[^\r,]+") do
    local tf_in = "prime_in"..tostring(prsinc)
    view_input[tf_in].text = s
    prsinc = prsinc + 1
  end
  
  --2. degree velocity list [multiple elements]
  prsinc = 1
  for s in parsed_data[2]:gmatch("[^\r,]+") do
    local tf_in = "deg_vel_in"..tostring(prsinc)
    view_input[tf_in].text = s
    prsinc = prsinc + 1
  end 
  
  --3. degree editstep list [multiple elements]
  prsinc = 1
  for s in parsed_data[3]:gmatch("[^\r,]+") do
    local tf_in = "deg_editstep_in"..tostring(prsinc)
    view_input[tf_in].text = s
    prsinc = prsinc + 1
  end 
  
  --4. degree auxilary list [multiple elements]
  prsinc = 1
  for s in parsed_data[4]:gmatch("[^\r,]+") do
    local tf_in = "deg_aux_in"..tostring(prsinc)
    view_input[tf_in].text = s
    prsinc = prsinc + 1
  end  
  
  --5. inversion bools [4 bools]
  prsinc = 1
  for s in parsed_data[5]:gmatch("[^\r,]+") do
    sub_parsed_data[prsinc] = booleantable[tonumber(s)]
    prsinc = prsinc + 1
  end
  view_input.note_inv_bool.value = sub_parsed_data[1]
  view_input.vel_inv_bool.value = sub_parsed_data[2]
  view_input.editstep_inv_bool.value = sub_parsed_data[3]
  view_input.aux_inv_bool.value = sub_parsed_data[4]
 
  --6. Editstep scale [1:num]
  view_input.editstepscale.text = tostring(parsed_data[6])
  editstep_scale = parsed_data[6]
  
  --7. Editstep Inv Axis [1:num]
  view_input.editstepinvaxis.text = tostring(parsed_data[7])
  editstep_inversion_axis = tonumber(parsed_data[7])

  --8. Octave Option [chooser:2]
  view_input.octavemode.value = tonumber(parsed_data[8])
  interval_inv = booleantable[tonumber(parsed_data[8])]
  
  --9. Add notation [bool]
  view_input.notationenable.value = booleantable[tonumber(parsed_data[9])]
  notation_enable = booleantable[parsed_data[9]]
  
  --10. Editstep select [chooser:2]
  view_input.editsteptype.value = tonumber(parsed_data[10])
  interval_inv = not booleantable[tonumber(parsed_data[10])]
  
  --11. Aux Place [chooser:2]
  view_input.auxenable.value = tonumber(parsed_data[11])
  aux_place_enable = not booleantable[tonumber(parsed_data[11])]
  
  --12. Aux FX Prefix [2 Byte String]
  view_input.auxprefix.text = tostring(parsed_data[12])
  auxstr = tostring(parsed_data[12])

  --13. Tonic Offset [chooser:12]
  view_input.tonicpopup.value = tonumber(parsed_data[13])
  tonic_offset = tonumber(parsed_data[13])-1
  
  --14. Scale [chooser:6]
  view_input.scalepopup.value = tonumber(parsed_data[14])
  updatescaleinfo(tonumber(parsed_data[14]))
  
  --15. Chroma Inv Axis [1:int]
  view_input.chromainvaxis.text = tostring(parsed_data[15])
  chromatic_inversion_axis = tonumber(parsed_data[15])
  
  print("chromatic_inversion_axis")
  print(chromatic_inversion_axis)
  
  --initialize data parsing variables  
  parsed_data = {}
  dataload_in = {}
  
  
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--add SerialKilla to menu
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Serial Killa",
  invoke = function() 
    dialog_box_window = renoise.app():show_custom_dialog(
    "Serial Killa", redraw_shell) 
  end 
}

--reset tone row marker buttons
local function reset_mkrs()
  for rowscan = 1,(global_motif_length) do
    view_input["P"..rowscan].color={0,0,0}
    view_input["R"..rowscan].color={0,0,0}
    view_input["I"..rowscan].color={0,0,0}
    view_input["RI"..rowscan].color={0,0,0}
  end
end 

--function to color 'load user prime' button blue
local function loadprime_remind()
    print("loadprime_remind()")
    view_input.loaduserprimebutton.color={0x22, 0xaa, 0xff}
end

function draw_window()

  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

  local BUTTON_WIDTH = 3*renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local BUTTON_HEIGHT = 2*renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  
  local DEFAULT_DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DEFAULT_CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  
  --all gui content  
 
  
  local settings_row = vb:row {}
  local menu_row = vb:row {}
  
  local row_completed = false
  
  local menu_button_scale = 2
  local matrix_button_scale = 1    
  
  --button defaults 
  last_button_id = "punchbutton"  
  last_cell_id = "col1_1" 
  
  -------------------------------------------
  --function for when motif length is changed
  -------------------------------------------
  local function motiflen_chg()
    --remove matrix from gui
    dialog_content:remove_child(matrix_column)
    redraw_shell:remove_child(dialog_content)
    
    --make new vb object instances
    vb = renoise.ViewBuilder()
    view_input = vb.views
    redraw_shell = vb:column{}
    matrix_column = vb:column{}
    dialog_content = vb:column{}
    
    --close then reopen window
    dialog_box_window:close()
    draw_window()
  end
  
  ---------------
  ---File buttons
  ---------------
  local file_row = vb:horizontal_aligner{
    mode = "justify"
  }
  
  local loadfile_button = vb:button {
    text = "Load .srl File",
    tooltip = "Click to Load Serial Killa Preset",
    notifier = function()
      --local my_text_view = vb.views.prime_el_A
      --my_text_view.text = "Button was hit."
          
      dataload_in = load_file_in_bytes_to_table({"*.srl"},"Choose a .srl SerialKilla File")
      file_parser()
    end
  }
  
  local brand_graphic = vb:bitmap {
      -- recolor to match the GUI theme:
      mode = "body_color",
      -- bitmaps names should be specified with a relative path using
      -- your tool script bundle path as base:
      bitmap = "/Bitmaps/chuckb-serialkillagraphic-bmp.bmp",
      notifier = function()
        show_status("http://chuckb.biz")
      end
    }
  
  
  local savefile_button = vb:button {
    text = "Save .srl File",
    tooltip = "Click to Save Serial Killa Preset",
    notifier = function()
      write_settings_to_file()  
    end
  }


  
  file_row:add_child(loadfile_button)
  
  file_row:add_child(savefile_button) 
  
  ------------------------
  ---Generate random Prime
  ------------------------  
  local genprime_button = vb:button {
    text = "Generate 12-tone Prime",
    tooltip = "Click to Generate Random Prime Serial Form",
    notifier = function()
      --local my_text_view = vb.views.prime_el_A
      --my_text_view.text = "Button was hit."
      
      interval_inv = false
      
      view_input.scalepopup.value = 1
      updatescaleinfo(1)    
      generate_prime()
    end
  }
  
  -------------------------------
  --global motif length textfield
  -------------------------------
  local glbmotiflen_tf = vb:column{
    vb:text{
      text="Motif Len:"
     },
     vb:textfield {
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT/2,
        align = "center",
        text = tostring(global_motif_length),
        id = "glbmotiflen",
        notifier = function(text)
          --color 'load user prime' button blue
          loadprime_remind()
        
          global_motif_length = tonumber(text)
          --chromatic_inversion_axis = tonumber(text)
          motiflen_chg()
        end
    }
  }
  
  ----------------------------
  ----------------------------
  --per degree GUI textfields
  ----------------------------    
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
          text = "deg:"
        }
      degree_chroma_row:add_child(tf_obj) 
    elseif (tfrowscan==(global_motif_length+2)) then

      local tf_obj = vb:row{}
      
      local note_inv_bool = vb:checkbox {
        value = true,
        id = "note_inv_bool",
        notifier = function(value)
          loadprime_remind()
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
          rprint("prime_in"..tfrowscan-1),
          notifier = function()
            loadprime_remind()
          end,        
        }
      degree_chroma_row:add_child(tf_obj)
    end
  end
  
  --velocity  
  for tfrowscan = 1,(global_motif_length+3) do
    if (tfrowscan==1) then
      local tf_obj =vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "vel:"
        }
      
      degree_vel_row:add_child(tf_obj) 
    
    --inversion check box
    elseif (tfrowscan==(global_motif_length+2)) then
      
      local tf_obj = vb:row{}
    
      local vel_inv_bool = vb:checkbox {
        value = false,
        id = "vel_inv_bool",
        notifier = function(value)
          loadprime_remind()
          vel_inv_bool = value 
        end,
      }
      
      tf_obj:add_child(vel_inv_bool)
      degree_vel_row:add_child(tf_obj)
    
    --quickrev buton  
    elseif (tfrowscan==(global_motif_length+3)) then
      
      local tf_obj = vb:row{}
    
      local vel_rev_but = vb:button {
        text = "R",
        id = "vel_rev_but",
        notifier = function()
          loadprime_remind()
          
          --reverse textfields
          quickrev_buf = {} 
          for index=1,global_motif_length do
            table.insert(quickrev_buf,view_input["deg_vel_in"..index].text)
          end
          for index=1,global_motif_length do
            view_input["deg_vel_in"..index].text=quickrev_buf[global_motif_length+1-index]
          end
          
        end,
      }
      
      tf_obj:add_child(vel_rev_but)
      degree_vel_row:add_child(tf_obj)  
   
    else
      local tf_obj =vb:textfield {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "64",
          id = "deg_vel_in"..tfrowscan-1,
          rprint("deg_vel_in"..tfrowscan-1),
          notifier = function()
            loadprime_remind()
          end,
        }
      degree_vel_row:add_child(tf_obj)
    end
  end
  
  --aux  
  for tfrowscan = 1,(global_motif_length+3) do
    if (tfrowscan==1) then
      local tf_obj =vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "aux:"
        }
      degree_aux_row:add_child(tf_obj) 
    
    --inversion checkbox
    elseif (tfrowscan==(global_motif_length+2)) then
      
      local tf_obj = vb:row{}
    
      local aux_inv_bool = vb:checkbox {
        value = false,
        id = "aux_inv_bool",
        notifier = function(value)
          loadprime_remind()
          aux_inv_bool = value  
        end,
      }
      
      tf_obj:add_child(aux_inv_bool)
      degree_aux_row:add_child(tf_obj)
    
    --quickrev button  
    elseif (tfrowscan==(global_motif_length+3)) then
      
      local tf_obj = vb:row{}
    
      local aux_rev_but = vb:button {
        text = "R",
        id = "aux_rev_but",
        notifier = function()
          loadprime_remind()
          
          --reverse textfields
          quickrev_buf = {} 
          for index=1,global_motif_length do
            table.insert(quickrev_buf,view_input["deg_aux_in"..index].text)
          end
          for index=1,global_motif_length do
            view_input["deg_aux_in"..index].text=quickrev_buf[global_motif_length+1-index]
          end
        end,
      }
      
      tf_obj:add_child(aux_rev_but)
      degree_aux_row:add_child(tf_obj)  
   
    else
      local tf_obj =vb:textfield {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "64",
          id = "deg_aux_in"..tfrowscan-1,
          rprint("deg_aux_in"..tfrowscan-1),
          notifier = function()
            loadprime_remind()
          end
        }
      degree_aux_row:add_child(tf_obj)
    end
  end
  
  --editstep  
  for tfrowscan = 1,(global_motif_length+3) do
    if (tfrowscan==1) then
      local tf_obj =vb:text {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "step:"
        }
      degree_editstep_row:add_child(tf_obj) 
    
    --inversion checkbox
    elseif (tfrowscan==(global_motif_length+2)) then
      
     local tf_obj = vb:row{}
    
      local editstep_inv_bool = vb:checkbox {
        value = false,
        id = "editstep_inv_bool",
        notifier = function(value)
          loadprime_remind()
          editstep_inv_bool = value  
        end,
      }
      
      tf_obj:add_child(editstep_inv_bool)
      degree_editstep_row:add_child(tf_obj)
    
    --quickrev button  
    elseif (tfrowscan==(global_motif_length+3)) then
      
     local tf_obj = vb:row{}
    
      local editstep_rev_but = vb:button {
        text = "R",
        id = "editstep_rev_but",
        notifier = function()
          loadprime_remind()
          --reverse textfields
          quickrev_buf = {} 
          for index=1,global_motif_length do
            table.insert(quickrev_buf,view_input["deg_editstep_in"..index].text)
          end
          for index=1,global_motif_length do
            view_input["deg_editstep_in"..index].text=quickrev_buf[global_motif_length+1-index]
          end
        end,
      }
      
      tf_obj:add_child(editstep_rev_but)
      degree_editstep_row:add_child(tf_obj) 
   
    else
      local tf_obj =vb:textfield {
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT/menu_button_scale,
          align = "center",
          text = "12",
          id = "deg_editstep_in"..tfrowscan-1,
          rprint("deg_editstep_in"..tfrowscan-1),
          notifier = function()
            loadprime_remind()
          end
        }
      degree_editstep_row:add_child(tf_obj)
    end
  end
  
  ----------------------
  ---menu options-------
  ----------------------

  --inversion axis stuff
  local tonaloption_row = vb:row{} 
  
  local editstepscale_tf = vb:column{
    vb:text{
      text="EditStep Scale:"
     },
     vb:textfield {
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT/2,
        align = "center",
        text = tostring(editstep_scale),
        id = "editstepscale",
        notifier = function(text)
          loadprime_remind()
          editstep_scale = tonumber(text)
        end
    }
  }
  
  local editstepaxis_tf = vb:column{
    vb:text{
      text="EditStep Inv Axis:"
     },
     vb:textfield {
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT/2,
        align = "center",
        text = tostring(editstep_inversion_axis),
        id = "editstepinvaxis",
        notifier = function(text)
          loadprime_remind()
          editstep_inversion_axis = tonumber(text)
        end
    }
  }   
  
  local tonalmode_tf = vb:column{
    vb:vertical_aligner{
      mode = "bottom",
      height = BUTTON_HEIGHT,
      vb:chooser {
        id = "tonalmode",
        value = 1,
        items = {"Tonal Mode", "Perc Mode"},
        notifier = function(new_index)
            loadprime_remind()
  
            if new_index == 1 then
            
                view_input.chromaxis_tfbox.visible = true
                view_input.octaveoption_tfbox.visible = true
                view_input.tonic_popupbox.visible = true
                view_input.scale_popupbox.visible = true
                
               
                interval_inv = octavemode_movebuf
                if view_input.octavemode.value == 1 then
                  interval_inv = false
                else
                  interval_inv = true
                end
        
                
                updatescaleinfo(scale_movebuf)
                
                
     
                chromatic_inversion_axis = chromainv_modebuf
                view_input.chromainvaxis.text = tostring(chromatic_inversion_axis)

                --chromatic_inversion_axis = chromainv_modebuf
                
              
              else
              
                view_input.chromaxis_tfbox.visible = false
                view_input.octaveoption_tfbox.visible = false
                view_input.tonic_popupbox.visible = false
                view_input.scale_popupbox.visible = false
                
                --always strip octave
                octavemode_movebuf = interval_inv
                interval_inv = false
                
                --always chromatic scale
                --this will update the chromatic inversion axis so no need to reset that manually
                scale_movebuf = view_input.scalepopup.value
                updatescaleinfo(1)
                
                 --in perc mode....
                --chroma inv axis should always be motif length
                chromainv_modebuf = chromatic_inversion_axis        
                chromatic_inversion_axis = global_motif_length
                print("chromatic_inversion_axis reset to")
                print(chromatic_inversion_axis)
                
                
              end
        
        end
        }
     }
  }
  
  local chromaxis_tf = vb:column{
    id = "chromaxis_tfbox",
    vb:text{
      text="Chroma Inv Axis:"
     },
     vb:textfield {
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT/2,
        align = "center",
        text = tostring(chromatic_inversion_axis),
        id = "chromainvaxis",
        notifier = function(text)
          loadprime_remind()
          chromatic_inversion_axis = tonumber(text)
        end
    }
  }
  
  
  local octaveoption_tf = vb:column{
    id = "octaveoption_tfbox",
    vb:vertical_aligner{
      mode = "bottom",
      height = BUTTON_HEIGHT,
      vb:chooser {
        id = "octavemode",
        value = 1,
        items = {"Strip Octave", "Invert Interval"},
        notifier = function(new_index)
          
          loadprime_remind()
        
          if new_index == 1 then
            interval_inv = false
          else
            interval_inv = true
          end
        
        end
        }
    }
  }
   
  local commentoption_tf = 
  vb:vertical_aligner{
    mode = "center",
      vb:text {
        text = "Add Notation:"
      },
      vb:checkbox{
        id = "notationenable",
        value = true,
        notifier = function(value)
          if value == false then
            notation_enable = "false"
          else
            notation_enable = "true"
          end
               
        end
      }
    }
 
  
  local axiscolspr1 = vb:column{width = 20}
  local axiscolspr2 = vb:column{width = 20}
  local axiscolspr3 = vb:column{width = 20}
  local axiscolspr4 = vb:column{width = 20}
  local axiscolspr5 = vb:column{width = 20}
  local axiscolspr6 = vb:column{width = 25}
   
  -- editstep chooser 
  local editstepchooser_row = vb:vertical_aligner {
    mode="center",
    vb:chooser {
      id = "editsteptype",
      value = 1,
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
  
  local auxstr_tf = vb:vertical_aligner{
    mode = "center",
    vb:text{
      text = "Aux FX Prefix:"
    },
    
    vb:textfield {
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT/2,
        align = "center",
        text = "0M",
        id = "auxprefix",
        notifier = function(text)
          auxstr = text
        end
        }
  }
  
  local aux_row = vb:row{}
  local colspr1 = vb:column{width=20,height = BUTTON_HEIGHT*1.25}
  local colspr2 = vb:column{width=20}
  local colspr3 = vb:column{width=20}
  local colspr4 = vb:column{width=20}
  local colspr5 = vb:column{width=20}
  local colspr6 = vb:column{width=20}
  
  -- aux enable chooser 
  local auxenable_row = vb:vertical_aligner {
    mode = "center",

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
  
    -- popup 
    local scale_popup = vb:column {
      id = "scale_popupbox",
      vb:text {
        text = "Scale:"
      },
      vb:popup {
        id = "scalepopup",
        width = 100,
        value = 1,
        items = {"Chromatic","Major","Natural Minor","Harmonic Minor","Major Pent.","Minor Pent."},
        notifier = function(new_index)
          loadprime_remind()
          updatescaleinfo(new_index)  
          end
      }
    }
    
    local tonic_popup = vb:column {
      id = "tonic_popupbox",
      vb:text {
        text = "Tonic Offset:"
      },
      vb:popup {
        id = "tonicpopup",
        width = 100,
        value = 1,
        items = {"c","c#","d","d#","e","f","f#","g","g#","a","a#","b"},
        notifier = function(new_index)
          loadprime_remind()
          tonic_offset = tonumber(new_index-1)
        end
      }
    }
  
   local load_button = vb:button {
        text = "Load User Prime",
        id = "loaduserprimebutton",
        tooltip = "Click to Calculate Matrix from User Prime",
        color={0x22, 0xaa, 0xff},
        notifier = function()
          --local my_text_view = vb.views.prime_el_A
          --my_text_view.text = "Button was hit."
          view_input.loaduserprimebutton.color={0,0,0}

          load_custom_prime()
        end
  }
  
  -------------------------
  -------------------------
  --pre-matrix GUI assemble
  -------------------------
  -------------------------
  dialog_content:add_child(file_row)
 
  local motiflen_row = vb:horizontal_aligner{
    mode = "justify"
  }
  motiflen_row:add_child(glbmotiflen_tf)
  if global_motif_length==12 then
      motiflen_row:add_child(genprime_button)
  end
  motiflen_row:add_child(brand_graphic)
  dialog_content:add_child(motiflen_row)
 
 --motif define row
  dialog_content:add_child(degree_chroma_row)
  dialog_content:add_child(degree_vel_row)
  dialog_content:add_child(degree_editstep_row)
  dialog_content:add_child(degree_aux_row)


 
  tonaloption_row:add_child(tonalmode_tf)
  tonaloption_row:add_child(axiscolspr6)
  tonaloption_row:add_child(chromaxis_tf)
  tonaloption_row:add_child(axiscolspr3)
  tonaloption_row:add_child(octaveoption_tf)
  tonaloption_row:add_child(axiscolspr4)
  tonaloption_row:add_child(tonic_popup)
  tonaloption_row:add_child(colspr2)
  tonaloption_row:add_child(scale_popup)  
  
  aux_row:add_child(editstepscale_tf)
  aux_row:add_child(axiscolspr1)
  aux_row:add_child(editstepaxis_tf)
  aux_row:add_child(axiscolspr2)
  aux_row:add_child(editstepchooser_row)
  aux_row:add_child(colspr3) 
  aux_row:add_child(auxenable_row)
  aux_row:add_child(colspr1)
  aux_row:add_child(auxstr_tf)
  aux_row:add_child(colspr4)
  aux_row:add_child(commentoption_tf)
  

    
  dialog_content:add_child(tonaloption_row) 
  dialog_content:add_child(aux_row)  
  dialog_content:add_child(load_button)
  
  --------------------
  --------------------
  ------matrix GUI
  --------------------
  --------------------
  local function drawmatrixgui()
  
    
    --draws matrix of dimensions (global motif length + 2)^2
    --the "+2x" adds room for buttons on top, bottom and sides   
    for rowscan = 1,(global_motif_length+2) do
      -- create a row for each rowscan
      local rowscan_row = vb:row {}
  
      for colscan = 1,(global_motif_length+2) do
        
        -----corners to be blank spaces-------
        if ((rowscan==(global_motif_length+2))and(colscan==1))or((rowscan==(1))and(colscan==1)) then
          local colscan_button =vb:text {
            width = BUTTON_WIDTH,
            height = BUTTON_HEIGHT,
            align = "center",
            text = " "
          }  
          rowscan_row:add_child(colscan_button)
        
        --reset markers
        elseif ((rowscan==(global_motif_length+2))and(colscan==(global_motif_length+2))) then
          local resetmkr_button = vb:button {
                width = BUTTON_WIDTH,
                height = BUTTON_HEIGHT,
                text = "Reset\nMkrs",
                
                notifier = function(width)
                  reset_mkrs()
                end
              }
          rowscan_row:add_child(resetmkr_button)
        elseif ((rowscan==1)and(colscan==(global_motif_length+2))) then
          local manual_mkrcont = vb:horizontal_aligner{
          width = BUTTON_WIDTH,
          mode ="center",
            vb:column{
               vb:text{
                  text = "Manual:",
                  align = "center"
               },
               vb:horizontal_aligner {
                  mode = "center",
                  vb:checkbox {
                    value = false,
                    id = "manualmrk_chk",
                    notifier = function(value)
                      if value == true then
                        manual_mark_mode="true" 
                      else
                        manual_mark_mode="false"
                      end
                    end
               }
             }
           }
         }
              
              
              
          rowscan_row:add_child(manual_mkrcont)
        --add prime selection butons
        elseif (colscan == 1) then  
          local colscan_button = vb:button {
                width = BUTTON_WIDTH,
                height = BUTTON_HEIGHT,
                text = "P"..tostring(rowscan-1),
                id = "P"..tostring(rowscan-1),
                
                notifier = function(width)
                  if manual_mark_mode=="true" then
                    mark_primebut("P"..tostring(rowscan-1))
                  else
                    active_prime_type="P"
                    active_prime_index=(rowscan-1)
                    active_prime_degree=1
                    
                    active_primebut_clr("P"..tostring(rowscan-1))
                    coloractivedegree("P",tostring(rowscan-1),1)
                  end
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
                  if manual_mark_mode=="true" then
                    mark_primebut("R"..tostring(rowscan-1))
                  else
                    active_prime_type="R"
                    active_prime_index=(rowscan-1)
                    active_prime_degree=1
                    
                    active_primebut_clr("R"..tostring(rowscan-1))
                    coloractivedegree("R",tostring(rowscan-1),1)
                  end
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
                  if manual_mark_mode=="true" then
                    mark_primebut("I"..tostring(colscan-1))
                  else
                    active_prime_type="I"
                    active_prime_index=(colscan-1)
                    active_prime_degree=1
                  
                    active_primebut_clr("I"..tostring(colscan-1))
                    coloractivedegree("I",tostring(colscan-1),1)
                  end
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
                  if manual_mark_mode=="true" then
                    mark_primebut("RI"..tostring(colscan-1))
                  else
                    active_prime_type="RI"
                    active_prime_index=(colscan-1)
                    active_prime_degree=1
                    
                    active_primebut_clr("RI"..tostring(colscan-1))
                    coloractivedegree("RI",tostring(colscan-1),1)
                  end
                end
              }
          rowscan_row:add_child(rowscan_button)
        else
         
        -------------
        --add 'degree cells'
        --------------
        local cell_column = vb:column{
          style = "panel",
          id = "col"..tostring(rowscan-1).."_"..tostring(colscan-1), 
          
        }
 
        local cell_row_top = vb:row {
          
        }
        
        local cell_row_bottom = vb:row {
  
        }
        
        local cell_top_algn = vb:horizontal_aligner {
          width = BUTTON_WIDTH,
          spacing = -5,
          mode = "justify",
          vb:text {
            width = 18,
            height = BUTTON_HEIGHT/2,
            id = tostring(rowscan-1).."_"..tostring(colscan-1),
            --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
            text = "N",
            style = "strong",
            align = "left"
          },
          vb:text {
            width = 18,
            height = BUTTON_HEIGHT/2,
            id = "oct"..tostring(rowscan-1).."_"..tostring(colscan-1),
            text = "",
            style = "disabled",
            align = "left"
          },
          vb:text {
            width = 18,
            height = BUTTON_HEIGHT/2,
            id = "vel"..tostring(rowscan-1).."_"..tostring(colscan-1),
            --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
            text = "V",
            align = "right"
          },
        }
        
        local cell_btm_algn = vb:horizontal_aligner {
          width = BUTTON_WIDTH,

          mode = "justify",
          vb:text {
            height = BUTTON_HEIGHT/3,
            id = "step"..tostring(rowscan-1).."_"..tostring(colscan-1),
            --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
            text = "S",
            --align = "left",
          },
          vb:text {
            height = BUTTON_HEIGHT/3,
            id = "aux"..tostring(rowscan-1).."_"..tostring(colscan-1),
            --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
            text = "A",
            style = "disabled",
            align = "right"
          },
        }
        
        --[[
        local step_val = vb:row {
          --width = BUTTON_WIDTH/2,
          --mode = "left",
          vb:text {
            height = BUTTON_HEIGHT/3,
            id = "step"..tostring(rowscan-1).."_"..tostring(colscan-1),
            --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
            text = "S",
            align = "left",
          },
        }
        
        local aux_val = vb:row {
          --width = BUTTON_WIDTH/2,
          --mode = "right",
          vb:text {
            height = BUTTON_HEIGHT/3,
            id = "aux"..tostring(rowscan-1).."_"..tostring(colscan-1),
            --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
            text = "A",
            style = "disabled",
            align = "right"
          },
        }--]]
        
        --construct 'degree cell'

        cell_row_top:add_child(cell_top_algn)
        --cell_row_top:add_child(vel_val)
        --cell_row_bottom:add_child(step_val)
        cell_row_bottom:add_child(cell_btm_algn)
        cell_column:add_child(cell_row_top)
        cell_column:add_child(cell_row_bottom)
        
        --add cell to row
        rowscan_row:add_child(cell_column)
        end
      end
  
        --add row to entire matrix cell
        matrix_column:add_child(rowscan_row)  
    end
    
    --add matrix to dialog box
    dialog_content:add_child(matrix_column) 
  end
  
  --draw matrix (for first call)
  drawmatrixgui() 
  
  -----------------------
  ---post matrix GUI
  ----------------------
  local punch_row = vb:row{}
  
  local function punchaction()
    
    --get cell attributes
    received_degree_info = retreivecellattribs(active_prime_type,active_prime_index,active_prime_degree)
    
    --get note position
    local cureditpos = renoise.song().transport.edit_pos
    local curtrack =renoise.song().selected_track_index
    local curcolumn = renoise.song().selected_note_column_index
    local noteplacepos = renoise.song().patterns[cureditpos.sequence].tracks[curtrack].lines[cureditpos.line].note_columns[curcolumn]
      
    --place note
    placenote(received_degree_info[1],received_degree_info[2],received_degree_info[4],received_degree_info[5],noteplacepos)
    
    --either jump by global editstep or draw from cell    
    if global_edit_step == false then            
      editstep_tmp = received_degree_info[3]
    else
      editstep_tmp = renoise.song().transport.edit_step
    end                 
       
    

    --if starting a new prime and notation is enabled...    
    if ((active_prime_degree==1)and(notation_enable=="true")) then
      --record where pattern started
      notstr_pat = renoise.song().transport.edit_pos.sequence
      local curline = renoise.song().transport.edit_pos.line-1
      
      --add part that was started
      local commentinfo = "<"..active_prime_type..active_prime_index..":"..curline
      concat_pat_name(notstr_pat,commentinfo)
      
      --set flag to show current notation
      notation_start = "true"
    end
   
    --move cursor -
    jumpbystep(editstep_tmp*editstep_scale)
  

    --increment to next degree in current prime string
    active_prime_degree=active_prime_degree+1
    
    --if all elements in prime string have been called
    if(active_prime_degree==(global_motif_length+1)) then
      print('prime row complete')
      
      --disqualify prime button from color reset 
      last_button_id = "punchbutton"
      --color it blue
      view_input[active_prime_type..active_prime_index].color={0x22, 0xaa, 0x00}
      
      --spray mode off
      spraymodeactive=false
      
      --if notation is ongoing....(now complete)
      if ((notation_start=="true")and(notation_enable=="true")) then
        
        --finish notation
        local commentinfo = ">"
        concat_pat_name(notstr_pat,commentinfo)
        
        --reset flag
        notation_start = "false"
      end
      
      
      
      --reset prime counter
      active_prime_degree=1
    end
    
    -- color the next degree cell
    coloractivedegree(active_prime_type,active_prime_index,active_prime_degree)
  end
  
  ---------------------------
  --spraystep
  ---------------------------
  local function spraystep()
  
    local editstepsum_buffer = 0
    
    --get note insertion position
    local cureditpos = renoise.song().transport.edit_pos
    local curtrack =renoise.song().selected_track_index
    local curcolumn = renoise.song().selected_note_column_index
    
    for sprayinsert_index = 1,global_motif_length do    
        --get cell attributes
        received_degree_info = retreivecellattribs(active_prime_type,active_prime_index,sprayinsert_index)
        
        

        
        local tmp_pos_2 = renoise.song().transport.edit_pos  
        tmp_pos_2.global_line_index = tmp_pos_2.global_line_index + editstepsum_buffer
        
        print("")
        print("sprayinsert_index:",sprayinsert_index)
        print("editstepsum_buffer",editstepsum_buffer)
        print("tmp_pos.global_line_index",tmp_pos_2.global_line_index)
        print("tmp_pos_2.sequence",tmp_pos_2.sequence)
        print("tmp_pos_2.line",tmp_pos_2.line)
        print("")
          
        --calculate position based on already factored steps
        local noteplacepos = renoise.song().patterns[tmp_pos_2.sequence].tracks[curtrack].lines[tmp_pos_2.line].note_columns[curcolumn] 
          
        --place note
        placenote(received_degree_info[1],received_degree_info[2],received_degree_info[4],received_degree_info[5],noteplacepos)
        
        --either jump by global editstep or draw from cell    
        if global_edit_step == false then            
          editstep_tmp = received_degree_info[3]
        else
          editstep_tmp = renoise.song().transport.edit_step
        end                 
       
        --if starting a new prime and notation is enabled...    
        if ((sprayinsert_index==1)and(notation_enable=="true")) then
          --record where pattern started
          notstr_pat = renoise.song().transport.edit_pos.sequence
          local curline = renoise.song().transport.edit_pos.line-1
          
          --add part that was started
          local commentinfo = "<"..active_prime_type..active_prime_index..":"..curline
          concat_pat_name(notstr_pat,commentinfo)
          
          --set flag to show current notation
          notation_start = "true"
        end
       
        --accumulate position by adding last editstep jump
        editstepsum_buffer=editstepsum_buffer+(editstep_tmp)
              
        --local tmp_pos = renoise.song().transport.edit_pos
        --cureditpos.line = tmp_pos.global_line_index + editstepsum_buffer
      
    
        --increment to next degree in current prime string
        --active_prime_degree=active_prime_degree+1
        
        --if all elements in prime string have been called
        if(sprayinsert_index==(global_motif_length)) then
          print('prime row complete')
          
          --disqualify prime button from color reset 
          last_button_id = "punchbutton"
          --color it blue
          view_input[active_prime_type..active_prime_index].color={0x22, 0xaa, 0x00}
          
          --spray mode off
          spraymodeactive=false
          
          --if notation is ongoing....(now complete)
          if ((notation_start=="true")and(notation_enable=="true")) then
            
            --finish notation
            local commentinfo = ">"
            concat_pat_name(notstr_pat,commentinfo)
            
            --reset flag
            notation_start = "false"
          end
          
          
          
          --reset prime counter
          --=1
        end
        
        -- color the next degree cell
        --coloractivedegree(active_prime_type,active_prime_index,active_prime_degree)
      end
  end
  
  --punch button writes cell to pattern seq
  local punch_button = vb:button {
    width = BUTTON_WIDTH*(global_motif_length+2)/3,
    height = BUTTON_HEIGHT/menu_button_scale,
    text = "Punch",
    id = "punchbutton",
    notifier = function()
      punchaction()      
    end
  
  }
  
  --jumps down by global edit step     
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
  
  --**ought to** write all remaining notes in prime string
  local spray_button = vb:button {
    width = BUTTON_WIDTH*(global_motif_length+2)/3,
    height = BUTTON_HEIGHT/menu_button_scale,
    text = "Spray Row",
    
    notifier = function()
      --internally loop spray
      spraystep()      
    end
  }
  
  --------------------------
  --Assemble post Matrix GUI            
  --------------------------
  punch_row:add_child(punch_button)
  punch_row:add_child(jumpdown_button)   
  punch_row:add_child(spray_button)   
  
  
  dialog_content:add_child(punch_row)
  
  redraw_shell:add_child(dialog_content)

  --displays dialog box
  if do_draw=="true" then
    dialog_box_window = renoise.app():show_custom_dialog(
      "Serial Killa", redraw_shell)
  end

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

-- Notifier handler functions  
local notifier = {}  
  
 function notifier.add(observable, n_function)  
 if not observable:has_notifier(n_function) then  
 observable:add_notifier(n_function)  
 end  
 end  
  
 function notifier.remove(observable, n_function)  
 if observable:has_notifier(n_function) then  
 observable:remove_notifier(n_function)  
 end  
 end  
  
----------------------
--Loading Notifiers
----------------------  
  
  
-- Set up song opening & closing observables  
local new_doc_observable = renoise.tool().app_new_document_observable  
local close_doc_observable = renoise.tool().app_release_document_observable  
  
  
-- Set up notifier functions that are called when song opened or closed  
local function open_song()
  chromatic_offset = renoise.song().transport.octave*12
  editstep_tmp = renoise.song().transport.edit_step
  
  --make gui but dont display
  if first_load=="true" then
    draw_window()
  end
  
  --set that it will now display
  do_draw="true"
  first_load="false"
  
  
end  
  
local function close_song()  
  --redraw_shell:remove_child(dialog_content)
end  
  
  
-- Add the notifiers  
notifier.add(new_doc_observable, open_song)  
notifier.add(close_doc_observable, close_song)  



