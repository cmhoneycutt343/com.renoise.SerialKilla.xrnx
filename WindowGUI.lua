

-------------------------------------------
--function for when motif length is changed
-------------------------------------------
local dialog_box_window

notstr_pat = ""

function motiflen_chg()
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

--add SerialKilla to menu
renoise.tool():add_menu_entry {
name = "Main Menu:Tools:Serial Killa",
invoke = function()
  dialog_box_window = renoise.app():show_custom_dialog(
  "Serial Killa", redraw_shell, my_keyhandler_func)
end
}

renoise.tool():add_keybinding {
name = "Global:Tools:Serial Killa",
invoke = function()
  dialog_box_window = renoise.app():show_custom_dialog(
  "Serial Killa", redraw_shell, my_keyhandler_func)
end
}

function draw_window()

  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

  local BUTTON_WIDTH = 3 * renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local BUTTON_HEIGHT = 2 * renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

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

      dataload_in = load_file_in_bytes_to_table({"*.srl"}, "Choose a .srl SerialKilla File")
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
      text = "Motif Len:"
    },
    vb:textfield {
      width = BUTTON_WIDTH,
      height = BUTTON_HEIGHT / 2,
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
  for tfrowscan = 1, (global_motif_length + 2) do
    if (tfrowscan == 1) then
      local tf_obj = vb:text {
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT / menu_button_scale,
        align = "center",
        text = "deg:"
      }
      degree_chroma_row:add_child(tf_obj)
    elseif (tfrowscan == (global_motif_length + 2)) then

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
      local tf_obj = vb:textfield {
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT / menu_button_scale,
        align = "center",
        text = " ",
        id = "prime_in"..tfrowscan - 1,
        --rprint("prime_in"..tfrowscan - 1),
        notifier = function()
          loadprime_remind()
        end,
      }
      degree_chroma_row:add_child(tf_obj)
    end
  end

  --velocity
  for tfrowscan = 1, (global_motif_length + 3) do
    if (tfrowscan == 1) then
      local tf_obj = vb:text {
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT / menu_button_scale,
        align = "center",
        text = "vel:"
      }

      degree_vel_row:add_child(tf_obj)

      --inversion check box
    elseif (tfrowscan == (global_motif_length + 2)) then

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
    elseif (tfrowscan == (global_motif_length + 3)) then

      local tf_obj = vb:row{}

      local vel_rev_but = vb:button {
        text = "R",
        id = "vel_rev_but",
        notifier = function()
          loadprime_remind()

          --reverse textfields
          quickrev_buf = {}
          for index = 1, global_motif_length do
            table.insert(quickrev_buf, view_input["deg_vel_in"..index].text)
          end
          for index = 1, global_motif_length do
            view_input["deg_vel_in"..index].text = quickrev_buf[global_motif_length + 1 - index]
          end

        end,
      }

      tf_obj:add_child(vel_rev_but)
      degree_vel_row:add_child(tf_obj)

    else
      local tf_obj = vb:textfield {
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT / menu_button_scale,
        align = "center",
        text = "64",
        id = "deg_vel_in"..tfrowscan - 1,
        --rprint("deg_vel_in"..tfrowscan - 1),
        notifier = function()
          loadprime_remind()
        end,
      }
      degree_vel_row:add_child(tf_obj)
    end
  end

  --aux
  for tfrowscan = 1, (global_motif_length + 3) do
    if (tfrowscan == 1) then
      local tf_obj = vb:text {
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT / menu_button_scale,
        align = "center",
        text = "aux:"
      }
      degree_aux_row:add_child(tf_obj)

      --inversion checkbox
    elseif (tfrowscan == (global_motif_length + 2)) then

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
    elseif (tfrowscan == (global_motif_length + 3)) then

      local tf_obj = vb:row{}

      local aux_rev_but = vb:button {
        text = "R",
        id = "aux_rev_but",
        notifier = function()
          loadprime_remind()

          --reverse textfields
          quickrev_buf = {}
          for index = 1, global_motif_length do
            table.insert(quickrev_buf, view_input["deg_aux_in"..index].text)
          end
          for index = 1, global_motif_length do
            view_input["deg_aux_in"..index].text = quickrev_buf[global_motif_length + 1 - index]
          end
        end,
      }

      tf_obj:add_child(aux_rev_but)
      degree_aux_row:add_child(tf_obj)

    else
      local tf_obj = vb:textfield {
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT / menu_button_scale,
        align = "center",
        text = "64",
        id = "deg_aux_in"..tfrowscan - 1,
        --rprint("deg_aux_in"..tfrowscan - 1),
        notifier = function()
          loadprime_remind()
        end
      }
      degree_aux_row:add_child(tf_obj)
    end
  end

  --editstep
  for tfrowscan = 1, (global_motif_length + 3) do
    if (tfrowscan == 1) then
      local tf_obj = vb:text {
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT / menu_button_scale,
        align = "center",
        text = "step:"
      }
      degree_editstep_row:add_child(tf_obj)

      --inversion checkbox
    elseif (tfrowscan == (global_motif_length + 2)) then

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
    elseif (tfrowscan == (global_motif_length + 3)) then

      local tf_obj = vb:row{}

      local editstep_rev_but = vb:button {
        text = "R",
        id = "editstep_rev_but",
        notifier = function()
          loadprime_remind()
          --reverse textfields
          quickrev_buf = {}
          for index = 1, global_motif_length do
            table.insert(quickrev_buf, view_input["deg_editstep_in"..index].text)
          end
          for index = 1, global_motif_length do
            view_input["deg_editstep_in"..index].text = quickrev_buf[global_motif_length + 1 - index]
          end
        end,
      }

      tf_obj:add_child(editstep_rev_but)
      degree_editstep_row:add_child(tf_obj)

    else
      local tf_obj = vb:textfield {
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT / menu_button_scale,
        align = "center",
        text = "12",
        id = "deg_editstep_in"..tfrowscan - 1,
        --rprint("deg_editstep_in"..tfrowscan - 1),
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
      text = "EditStep Scale:"
    },
    vb:textfield {
      width = BUTTON_WIDTH,
      height = BUTTON_HEIGHT / 2,
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
      text = "EditStep Inv Axis:"
    },
    vb:textfield {
      width = BUTTON_WIDTH,
      height = BUTTON_HEIGHT / 2,
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
      text = "Chroma Inv Axis:"
    },
    vb:textfield {
      width = BUTTON_WIDTH,
      height = BUTTON_HEIGHT / 2,
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
    mode = "center",
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
      height = BUTTON_HEIGHT / 2,
      align = "center",
      text = "0M",
      id = "auxprefix",
      notifier = function(text)
        auxstr = text
      end
    }
  }

  local aux_row = vb:row{}
  local colspr1 = vb:column{width = 20, height = BUTTON_HEIGHT * 1.25}
  local colspr2 = vb:column{width = 20}
  local colspr3 = vb:column{width = 20}
  local colspr4 = vb:column{width = 20}
  local colspr5 = vb:column{width = 20}
  local colspr6 = vb:column{width = 20}

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
      items = {"Chromatic", "Major", "Natural Minor", "Harmonic Minor", "Major Pent.", "Minor Pent."},
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
      items = {"c", "c#", "d", "d#", "e", "f", "f#", "g", "g#", "a", "a#", "b"},
      notifier = function(new_index)
        loadprime_remind()
        tonic_offset = tonumber(new_index - 1)
      end
    }
  }

  local load_button = vb:button {
    text = "Load User Prime",
    id = "loaduserprimebutton",
    tooltip = "Click to Calculate Matrix from User Prime",
    color = {0x22, 0xaa, 0xff},
    notifier = function()
      --local my_text_view = vb.views.prime_el_A
      --my_text_view.text = "Button was hit."
      view_input.loaduserprimebutton.color = {0, 0, 0}

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
  if global_motif_length == 12 then
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
    for rowscan = 1, (global_motif_length + 2) do
      -- create a row for each rowscan
      local rowscan_row = vb:row {}

      for colscan = 1, (global_motif_length + 2) do

        -----corners to be blank spaces-------
        if ((rowscan == 1)and(colscan == 1)) then
          local colscan_button = vb:button {
            width = BUTTON_WIDTH,
            height = BUTTON_HEIGHT,
            text = "Aud\nCell",
            notifier = function()
              audition_cell()
            end
          }

          rowscan_row:add_child(colscan_button)

        elseif ((rowscan == (global_motif_length + 2))and(colscan == 1)) then
          local colscan_button2 = vb:button {
            width = BUTTON_WIDTH,
            height = BUTTON_HEIGHT,
            text = "Aud\nRow",
            notifier = function()
              audition_row()
            end
          }

          rowscan_row:add_child(colscan_button2)



          --reset markers
        elseif ((rowscan == (global_motif_length + 2))and(colscan == (global_motif_length + 2))) then
          local resetmkr_button = vb:button {
            width = BUTTON_WIDTH,
            height = BUTTON_HEIGHT,
            text = "Reset\nMkrs",

            notifier = function(width)
              reset_mkrs()
            end
          }
          rowscan_row:add_child(resetmkr_button)
        elseif ((rowscan == 1)and(colscan == (global_motif_length + 2))) then
          local manual_mkrcont = vb:horizontal_aligner{
            width = BUTTON_WIDTH,
            mode = "center",
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
                      manual_mark_mode = "true"
                    else
                      manual_mark_mode = "false"
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
            text = "P"..tostring(rowscan - 1),
            id = "P"..tostring(rowscan - 1),

            notifier = function(width)
              if manual_mark_mode == "true" then
                mark_primebut("P"..tostring(rowscan - 1))
              else
                active_prime_type = "P"
                active_prime_index = (rowscan - 1)
                active_prime_degree = 1

                active_primebut_clr("P"..tostring(rowscan - 1))
                coloractivedegree("P", tostring(rowscan - 1), 1)
              end
            end
          }
          rowscan_row:add_child(colscan_button)
        elseif (colscan == (global_motif_length + 2)) then
          local colscan_button = vb:button {
            width = BUTTON_WIDTH,
            height = BUTTON_HEIGHT,
            text = "R"..tostring(rowscan - 1),
            id = "R"..tostring(rowscan - 1),

            notifier = function()
              if manual_mark_mode == "true" then
                mark_primebut("R"..tostring(rowscan - 1))
              else
                active_prime_type = "R"
                active_prime_index = (rowscan - 1)
                active_prime_degree = 1

                active_primebut_clr("R"..tostring(rowscan - 1))
                coloractivedegree("R", tostring(rowscan - 1), 1)
              end
            end
          }
          rowscan_row:add_child(colscan_button)
        elseif (rowscan == 1) then
          local rowscan_button = vb:button {
            width = BUTTON_WIDTH,
            height = BUTTON_HEIGHT,
            text = "I"..tostring(colscan - 1),
            id = "I"..tostring(colscan - 1),

            notifier = function()
              if manual_mark_mode == "true" then
                mark_primebut("I"..tostring(colscan - 1))
              else
                active_prime_type = "I"
                active_prime_index = (colscan - 1)
                active_prime_degree = 1

                active_primebut_clr("I"..tostring(colscan - 1))
                coloractivedegree("I", tostring(colscan - 1), 1)
              end
            end
          }
          rowscan_row:add_child(rowscan_button)
        elseif (rowscan == (global_motif_length + 2)) then
          local rowscan_button = vb:button {
            width = BUTTON_WIDTH,
            height = BUTTON_HEIGHT,
            text = "RI"..tostring(colscan - 1),
            id = "RI"..tostring(colscan - 1),

            notifier = function()
              if manual_mark_mode == "true" then
                mark_primebut("RI"..tostring(colscan - 1))
              else
                active_prime_type = "RI"
                active_prime_index = (colscan - 1)
                active_prime_degree = 1

                active_primebut_clr("RI"..tostring(colscan - 1))
                coloractivedegree("RI", tostring(colscan - 1), 1)
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
            id = "col"..tostring(rowscan - 1).."_"..tostring(colscan - 1),

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
              height = BUTTON_HEIGHT / 2,
              id = tostring(rowscan - 1).."_"..tostring(colscan - 1),
              --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
              text = "N",
              style = "strong",
              align = "left"
            },
            vb:text {
              width = 18,
              height = BUTTON_HEIGHT / 2,
              id = "oct"..tostring(rowscan - 1).."_"..tostring(colscan - 1),
              text = "",
              style = "disabled",
              align = "left"
            },
            vb:text {
              width = 18,
              height = BUTTON_HEIGHT / 2,
              id = "vel"..tostring(rowscan - 1).."_"..tostring(colscan - 1),
              --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
              text = "V",
              align = "right"
            },
          }

          local cell_btm_algn = vb:horizontal_aligner {
            width = BUTTON_WIDTH,

            mode = "justify",
            vb:text {
              height = BUTTON_HEIGHT / 3,
              id = "step"..tostring(rowscan - 1).."_"..tostring(colscan - 1),
              --rprint(tostring(rowscan-1).."_"..tostring(colscan-1)),
              text = "S",
              --align = "left",
            },
            vb:text {
              height = BUTTON_HEIGHT / 3,
              id = "aux"..tostring(rowscan - 1).."_"..tostring(colscan - 1),
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

--local punchaction
local function punchaction()

  --get cell attributes
  received_degree_info = retreivecellattribs(active_prime_type, active_prime_index, active_prime_degree)

  --get note position
  local cureditpos = renoise.song().transport.edit_pos
  local curtrack = renoise.song().selected_track_index
  local curcolumn = renoise.song().selected_note_column_index
  local noteplacepos = renoise.song().patterns[cureditpos.sequence].tracks[curtrack].lines[cureditpos.line].note_columns[curcolumn]

  if(aud_bool == true) then
    audition_cell()
  end


  --place note
  placenote(received_degree_info[1], received_degree_info[2], received_degree_info[4], received_degree_info[5], noteplacepos)

  --either jump by global editstep or draw from cell
  if global_edit_step == false then
    editstep_tmp = received_degree_info[3]
  else
    editstep_tmp = renoise.song().transport.edit_step
  end



  --if starting a new prime and notation is enabled...
  if ((active_prime_degree == 1)and(notation_enable == "true")) then
    --record where pattern started
    notstr_pat = renoise.song().transport.edit_pos.sequence
    local curline = renoise.song().transport.edit_pos.line - 1

    --add part that was started
    local commentinfo = "<"..active_prime_type..active_prime_index..":"..curline
    concat_pat_name(notstr_pat, commentinfo)

    --set flag to show current notation
    notation_start = "true"
  end

  --move cursor -
  jumpbystep(editstep_tmp * editstep_scale)


  --increment to next degree in current prime string
  active_prime_degree = active_prime_degree + 1

  --if all elements in prime string have been called
  if(active_prime_degree == (global_motif_length + 1)) then
    print('prime row complete')

    --disqualify prime button from color reset
    last_button_id = "punchbutton"
    --color it blue
    view_input[active_prime_type..active_prime_index].color = {0x22, 0xaa, 0x00}

    --spray mode off
    spraymodeactive = false

    --if notation is ongoing....(now complete)
    if ((notation_start == "true")and(notation_enable == "true")) then

      --finish notation
      local commentinfo = ">"
      concat_pat_name(notstr_pat, commentinfo)

      --reset flag
      notation_start = "false"
    end



    --reset prime counter
    active_prime_degree = 1
  end

  -- color the next degree cell
  coloractivedegree(active_prime_type, active_prime_index, active_prime_degree)
end

---------------------------
--spraystep
---------------------------

local function spraystep()

  local editstepsum_buffer = 0

  --get note insertion position
  local cureditpos = renoise.song().transport.edit_pos
  local curtrack = renoise.song().selected_track_index
  local curcolumn = renoise.song().selected_note_column_index

  for sprayinsert_index = active_prime_degree, global_motif_length do
    --get cell attributes
    received_degree_info = retreivecellattribs(active_prime_type, active_prime_index, sprayinsert_index)




    local tmp_pos_2 = renoise.song().transport.edit_pos
    tmp_pos_2.global_line_index = tmp_pos_2.global_line_index + editstepsum_buffer

    print("")
    print("sprayinsert_index:", sprayinsert_index)
    print("editstepsum_buffer", editstepsum_buffer)
    print("tmp_pos.global_line_index", tmp_pos_2.global_line_index)
    print("tmp_pos_2.sequence", tmp_pos_2.sequence)
    print("tmp_pos_2.line", tmp_pos_2.line)
    print("")

    --calculate position based on already factored steps
    local noteplacepos = renoise.song().patterns[tmp_pos_2.sequence].tracks[curtrack].lines[tmp_pos_2.line].note_columns[curcolumn]

    --place note
    placenote(received_degree_info[1], received_degree_info[2], received_degree_info[4], received_degree_info[5], noteplacepos)

    --either jump by global editstep or draw from cell
    if global_edit_step == false then
      editstep_tmp = received_degree_info[3]
    else
      editstep_tmp = renoise.song().transport.edit_step
    end

    --if starting a new prime and notation is enabled...
    if ((sprayinsert_index == 1)and(notation_enable == "true")) then
      --record where pattern started
      notstr_pat = renoise.song().transport.edit_pos.sequence
      local curline = renoise.song().transport.edit_pos.line - 1

      --add part that was started
      local commentinfo = "<"..active_prime_type..active_prime_index..":"..curline
      concat_pat_name(notstr_pat, commentinfo)

      --set flag to show current notation
      notation_start = "true"
    end

    --accumulate position by adding last editstep jump
    editstepsum_buffer = editstepsum_buffer + (editstep_tmp)

    --local tmp_pos = renoise.song().transport.edit_pos
    --cureditpos.line = tmp_pos.global_line_index + editstepsum_buffer


    --increment to next degree in current prime string
    --active_prime_degree=active_prime_degree+1

    --if all elements in prime string have been called
    if(sprayinsert_index == (global_motif_length)) then
      print('prime row complete')

      --disqualify prime button from color reset
      last_button_id = "punchbutton"
      --color it blue
      view_input[active_prime_type..active_prime_index].color = {0x22, 0xaa, 0x00}

      --spray mode off
      spraymodeactive = false

      --if notation is ongoing....(now complete)
      if ((notation_start == "true")and(notation_enable == "true")) then

        --finish notation
        local commentinfo = ">"
        concat_pat_name(notstr_pat, commentinfo)

        --reset flag
        notation_start = "false"

        --reset active prime degree
        active_prime_degree = 1

        --uncolor last cell
        -- color the next degree cell
        coloractivedegree(active_prime_type, active_prime_index, active_prime_degree)
      end



      --reset prime counter
      --=1
      -- color the next degree cell
      coloractivedegree(active_prime_type, active_prime_index, 0)
    end


  end
end

--punch button writes cell to pattern seq
local punch_button = vb:button {
  width = BUTTON_WIDTH * (global_motif_length + 2) / 3,
  height = BUTTON_HEIGHT / menu_button_scale,
  text = "Punch",
  id = "punchbutton",
  notifier = function()
    punchaction()
  end
}

--jumps down by global edit step
local jumpdown_button = vb:button {
  width = BUTTON_WIDTH * (global_motif_length + 2) / 3,
  height = BUTTON_HEIGHT / menu_button_scale,
  text = "Jump by EditStep",

  notifier = function()
    local editstep_tmp = renoise.song().transport.edit_step

    jumpbystep(editstep_tmp)

    renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
  end
}

--**ought to** write all remaining notes in prime string
local spray_button = vb:button {
  width = BUTTON_WIDTH * (global_motif_length + 2) / 3,
  height = BUTTON_HEIGHT / menu_button_scale,
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
if do_draw == "true" then
  dialog_box_window = renoise.app():show_custom_dialog(
  "Serial Killa", redraw_shell, my_keyhandler_func)
end

if test_mode == "true" then
  set_test_vars()
end
end