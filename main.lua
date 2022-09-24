print("----------------------------------------")
print("█▀ █▀▀ █▀█ █ ▄▀█ █     █▄▀ █ █   █   ▄▀█")
print("▄█ ██▄ █▀▄ █ █▀█ █▄▄   █ █ █ █▄▄ █▄▄ █▀█")
print("-----======--A ChuckB Joint-=======-----")


_AUTO_RELOAD_DEBUG = true

----------------------------
---headers
----------------------------
require "12tone"
require "file_utils"
require "DAW_interface"
require "WindowGUI"
require "OSC_audutils"
require "helperfuncs"

------Enable Test Mode------
test_mode = "true"
debug_option = "true"
----------------------------

dataload_in = nil

do_draw = "false"

first_load = "true"

--initialized 12 tone prime
initialized_prime = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
generated_prime = {}

--indexable note names
chromaref = {"c", "c#", "d", "d#", "e", "f", "f#", "g", "g#", "a", "a#", "b"}

--indexable scales

scale_chromatic = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
scale_major = {0, 2, 4, 5, 7, 9, 11}
scale_natminor = {0, 2, 3, 5, 7, 8, 10}
scale_harminor = {0, 2, 3, 5, 7, 8, 11}
scale_majorpent = {0, 2, 4, 7, 9}
scale_minorpent = {0, 3, 5, 7, 10}
scale_list = {scale_chromatic, scale_major, scale_natminor, scale_harminor, scale_majorpent, scale_minorpent}

--sets default scale
scale_current = scale_chromatic
curscalelen = #scale_current

--table for converting note names back to chroma index
notetochroma = {}
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

tonic_offset = 0
--active_primebut_clr = 0

--indexing variables for generating 12 tone prime
current_prime_index = 0
current_prime_val = 0

--octave offset
--local chromatic_offset = renoise.song().transport.octave*12
chromatic_offset = 0
interval_inv = false

--'spray' editstep (currently unused)
spray_spacing = 6

--view objects
vb = renoise.ViewBuilder()
view_input = vb.views

redraw_shell = vb:row{}
dialog_content = vb:column {id = "dialogchild"}
--column to hold generated matrix and buttons (for redraw)
matrix_column = vb:column{id = "matrixchild"}

--default button references
last_button_id = "punchbutton"
last_cell_id = "col1_1"

--button mode options
manual_mark_mode = "false"
notation_enable = "true"
notation_start = "false"


--default prime references
active_prime_type = "P"
active_prime_index = 1
active_prime_degree = 1

--defaults for menu control
note_inv_bool = true
vel_inv_bool = false
editstep_inv_bool = false
editstep_scale = 1
aux_inv_bool = false

global_edit_step = true
aux_place_enable = false

--buffer to save fields during tonal -> perc mode and back
-- chromainv_modebuf
-- octavemode_movebuf
-- scale_movebuf


auxstr = "0M"

chromatic_inversion_axis = 12
editstep_inversion_axis = 12

--local editstep_tmp = renoise.song().transport.edit_step
editstep_tmp = 0

global_motif_length = 12

spraymodeactive = false
-- received_degree_info
placenotebusy = false
refreshprimemaker = false

--loading variables
booleantable = {false, true}
booltonum = {}
booltonum[false] = 1
booltonum[true] = 2



--local punchaction




--///loads chroma from textfields into matrix and generates
function load_custom_prime()
  for prime_index_col = 1, global_motif_length do
    local tf_in = "prime_in"..tostring(prime_index_col)
    generated_prime[prime_index_col] = view_input[tf_in].text
  end
  generate_matrix()
end


--[[Completion Matrix Generation Logic]]--
function generate_matrix()

  --for each column
  for prime_index_col = 1, global_motif_length do
    --for each row
    for prime_index_row = 1, global_motif_length do

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
      local degree_offset = (generated_prime[prime_index_row] - generated_prime[1])
      local vel_offset = view_input["deg_vel_in"..prime_index_row].text - view_input.deg_vel_in1.text
      local aux_offset = view_input["deg_aux_in"..prime_index_row].text - view_input.deg_aux_in1.text
      local editstep_offset = view_input["deg_editstep_in"..prime_index_row].text - view_input.deg_editstep_in1.text

      --current values from textfields
      local curvel = tostring(view_input[vel_loc].text)
      local curaux = tostring(view_input[aux_loc].text)
      local cureditstep = tostring(view_input[editstep_loc].text)

      --inversion logic
      local rot_index = (prime_index_col + prime_index_row - 2)%global_motif_length + 1



      ---------------------------
      --note inversion alg
      ---------------------------

      --if inverting.....
      if note_inv_bool == true then

        --incorporates scale inversion axis, offset, and degree from motif
        local offset_adjusted = (generated_prime[prime_index_col] - degree_offset)
        local symmat_index = tostring(generated_prime[(prime_index_col + prime_index_row - 2)%global_motif_length + 1])

        local relative_octave

        if(interval_inv == true) then
          if(prime_index_row > prime_index_col) then
            relative_octave = tostring(-math.floor(symmat_index / curscalelen))
            if(relative_octave == "-0") then
              relative_octave = "-1"
            end
            --relative_octave = "-1"
          else
            relative_octave = tostring(math.floor(symmat_index / curscalelen))
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
        local chromafromscale = scale_current[degree_get + 1]

        --converts to "note" string and loads to text field
        local notestrreturn = chromaref[(chromafromscale + tonic_offset)%12 + 1]

        --fill cell
        view_input[cell_id].text = notestrreturn
        view_input[cell_id_oct].text = relative_octave

        --if note inversion not activated...
      else
        --gets chroma index
        local symmat_index = tostring(generated_prime[(prime_index_col + prime_index_row - 2)%global_motif_length + 1])

        --get degree index
        local degree_get = tonumber(symmat_index)%(curscalelen)
        local relative_octave = tostring(math.floor(symmat_index / curscalelen))

        --convert scale degree to chroma
        local chromafromscale = scale_current[degree_get + 1]

        --converts to "note" string and loads to text field
        local notestreturn = chromaref[chromafromscale + 1]

        --fill cell
        view_input[cell_id].text = notestreturn
        view_input[cell_id_oct].text = relative_octave
      end

      --velocity inversion or not
      if vel_inv_bool == true then
        view_input[cell_id_vel].text = tostring((view_input[vel_loc].text - vel_offset)%127)
      else
        view_input[cell_id_vel].text = view_input["deg_vel_in"..rot_index].text
      end

      --auxilary inversion or not
      if aux_inv_bool == true then
        view_input[cell_id_aux].text = tostring((view_input[aux_loc].text - aux_offset)%127)
      else
        view_input[cell_id_aux].text = view_input["deg_aux_in"..rot_index].text
      end

      --editstep inversion or not
      if editstep_inv_bool == true then
        view_input[cell_id_editstep].text = tostring((view_input[editstep_loc].text - editstep_offset)%editstep_inversion_axis)
      else
        view_input[cell_id_editstep].text = view_input["deg_editstep_in"..rot_index].text
      end
    end
  end

  --recolors punch button????
  local buttonname = "punchbutton"
  view_input[buttonname].color = {0x00, 0x00, 0x00}
end













-------------------------
-- TESTING ZONE
-------------------------

function set_test_vars()
print("test variables active")
--generate_prime()
end







rprint("Run Serial Killa")
