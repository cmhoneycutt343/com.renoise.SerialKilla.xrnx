--------------------------------------------------------------------------------
-- Helper Functions / API
--------------------------------------------------------------------------------

function show_status(message)
  renoise.app():show_status(message)
  print(message)
end


function updatescaleinfo(index)
  scale_current = scale_list[index]

  --load scale length
  curscalelen = #scale_current

  --set inversion axis
  chromatic_inversion_axis = curscalelen
  view_input.chromainvaxis.text = tostring(curscalelen)
end

--concatenate pattern comments
function concat_pat_name(patindex, patcom)
  local curcom = renoise.song().patterns[patindex].name
  renoise.song().patterns[patindex].name = curcom..patcom
end

-------------------------------
--[[gets chroma from matrix]]--
-------------------------------
function retreivecellattribs(primetype, primeindex, degree)

  local row_index
  local col_index
  local fetched_degree
  local degreeinfo = {}

  --set row / column index based on prime type
  if primetype == ("P") then
    col_index = degree
    row_index = primeindex
  elseif primetype == ("I") then
    col_index = primeindex
    row_index = degree
  elseif primetype == ("R") then
    col_index = global_motif_length + 1 - degree
    row_index = primeindex
  elseif primetype == ("RI") then
    col_index = primeindex
    row_index = global_motif_length + 1 - degree
  else
    print("invalid primetype")
    return
  end

  --recall cell id from row and column
  local mat_cell_id = tostring(row_index).."_"..tostring(col_index)

  --add relevant data to buffer table
  table.insert(degreeinfo, view_input[mat_cell_id].text)
  table.insert(degreeinfo, view_input["vel"..mat_cell_id].text)
  table.insert(degreeinfo, view_input["step"..mat_cell_id].text)
  table.insert(degreeinfo, view_input["aux"..mat_cell_id].text)
  table.insert(degreeinfo, view_input["oct"..mat_cell_id].text)

  --return data
  return degreeinfo
end

--colors active prime button and resets last button
function active_primebut_clr(button_id)

  --reset last button color
  view_input[last_button_id].color = {0, 0, 0}

  --color current button blue
  view_input[button_id].color = {0x22, 0xaa, 0xff}

  --set current button to set button
  last_button_id = button_id
end

--for manual marking
function mark_primebut(button_id)

  --color current button green
  view_input[button_id].color = {0x22, 0xaa, 0x00}
  --last_button_id = "punchbutton"

  if button_id == last_button_id then
    last_button_id = "punchbutton"
  end

end

--colors next 'prime' box for punchin
function coloractivedegree(primetype, primeindex, degree)

  local row_index
  local col_index

  --set row / column index based on prime type
  if primetype == ("P") then
    col_index = degree
    row_index = primeindex
  elseif primetype == ("I") then
    col_index = primeindex
    row_index = degree
  elseif primetype == ("R") then
    col_index = global_motif_length + 1 - degree
    row_index = primeindex
  elseif primetype == ("RI") then
    col_index = primeindex
    row_index = global_motif_length + 1 - degree
  else
    print("invalid primetype")
    return
  end

  --resets last degree box
  view_input[last_cell_id].style = "panel"

  --colors current degree box
  local cell_id = "col"..tostring(row_index).."_"..tostring(col_index)
  print("cell_id")
  print(cell_id)

  view_input[cell_id].style = "plain"

  --sets current box to last box
  last_cell_id = cell_id
end

-------------------------------------------------
--[[function that draws note into pattern seq]]--
-------------------------------------------------
function placenote(notein, curvelin, auxin, octin, noteplacein)
  --
  local cureditpos = renoise.song().transport.edit_pos
  local curtrack = renoise.song().selected_track_index
  local curcolumn = renoise.song().selected_note_column_index

  local curvel = tonumber(curvelin)
  local curinst = tonumber(renoise.song().selected_instrument_index - 1)
  local curaux = tonumber(auxin)

  local curoct = 0

  --gets chroma index
  local degreein = notetochroma[notein]

  local oct_scale_crr = 0

  --correction to add octave to all notes 'below' the global tonic
  if(degreein < tonic_offset) then
    oct_scale_crr = 1
  end

  --gets octave offset from GUI
  chromatic_offset = (renoise.song().transport.octave + tonumber(curoct) + oct_scale_crr) * 12

  --variable for place to write in pattern seq
  --[[
  local noteplacepos = renoise.song().patterns[cureditpos.sequence].tracks[curtrack].lines[cureditpos.line].note_columns[curcolumn]
  ]]--
  local noteplacepos = noteplacein

  --write to pattern seq
  local reloct_buf = tonumber(octin)

  noteplacepos.note_value = degreein + chromatic_offset + (reloct_buf * 12)
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











--reset tone row marker buttons
local function reset_mkrs()
  for rowscan = 1, (global_motif_length) do
    view_input["P"..rowscan].color = {0, 0, 0}
    view_input["R"..rowscan].color = {0, 0, 0}
    view_input["I"..rowscan].color = {0, 0, 0}
    view_input["RI"..rowscan].color = {0, 0, 0}
  end
end

--function to color 'load user prime' button blue
function loadprime_remind()
  print("loadprime_remind()")
  view_input.loaduserprimebutton.color = {0x22, 0xaa, 0xff}
end