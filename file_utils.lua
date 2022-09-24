
--[[**********************]]--
--Handles lua IO stuff
--[[**********************]]--
function io_write_txt( file, tbl )
    print( "------------------------ " )
    print( "write in "..file )
    io.output( io.open( file, "w" ) )
    io.write( tbl )
    io.close()
    print( "---- write done ----" )
end

--[[**********************]]--
--Writes Settings to file
--[[**********************]]--
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



----------------------------------------------
-- File Loading
----------------------------------------------
function load_file_in_bytes_to_table(file_types, dialog_title)
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
    return string.format("%02X", num)
  end

  --------------------------------------------------------------------------------
  --read the user supplied file and put it byte by byte into a table using Lua io.
  --------------------------------------------------------------------------------
  --create table to return
  local file_bytes = {}

  --get file path
  local file_in = renoise.app():prompt_for_filename_to_read(file_types, dialog_title)

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
    local file = assert(io.open(file_in, "rb"))

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

-------------------------
--[[input file parser]]--
-------------------------
function file_parser()

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
      parser_index = parser_index + 1
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

  global_motif_length = prsinc - 1
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
  tonic_offset = tonumber(parsed_data[13]) - 1

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
