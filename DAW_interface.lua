----------------------
--Loading Notifiers
----------------------
 

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

-- Set up song opening & closing observables
local new_doc_observable = renoise.tool().app_new_document_observable
local close_doc_observable = renoise.tool().app_release_document_observable


-- Set up notifier functions that are called when song opened or closed
local function open_song()
chromatic_offset = renoise.song().transport.octave * 12
editstep_tmp = renoise.song().transport.edit_step

--make gui but dont display
if first_load == "true" then
  draw_window()
end

--set that it will now display
do_draw = "true"
first_load = "false"
end

local function close_song()
--redraw_shell:remove_child(dialog_content)
end


-- Add the notifiers
notifier.add(new_doc_observable, open_song)
notifier.add(close_doc_observable, close_song)




-------------------------------
--Key Shortcuts / Invocations 
-------------------------------
--adds SerialKilla to keyboard shortcuts
function my_keyhandler_func(dialog, key)
  print(key.name)
  --z==punch
  if(key.name == "z") then
    punchaction()
  end


  --p,i,r,d=prime,inverse,reverse,both(reverse-inverse)
  if(key.name == "p") then
    active_prime_type = "P"
    refreshprimemaker = true
  end
  if(key.name == "i") then
    active_prime_type = "I"
    refreshprimemaker = true
  end
  if(key.name == "r") then
    active_prime_type = "R"
    refreshprimemaker = true
  end
  if(key.name == "d") then
    active_prime_type = "RI"
    refreshprimemaker = true
  end

  --1-b (hex)=index
  if(key.name == "1") then
    active_prime_index = 1
    refreshprimemaker = true
  end

  if(key.name == "2") then
    active_prime_index = 2
    refreshprimemaker = true
  end

  if(key.name == "3") then
    active_prime_index = 3
    refreshprimemaker = true
  end

  if(key.name == "4") then
    active_prime_index = 4
    refreshprimemaker = true
  end

  if(key.name == "5") then
    active_prime_index = 5
    refreshprimemaker = true
  end

  if(key.name == "6") then
    active_prime_index = 6
    refreshprimemaker = true
  end

  if(key.name == "7") then
    active_prime_index = 7
    refreshprimemaker = true
  end

  if(key.name == "8") then
    active_prime_index = 8
    refreshprimemaker = true
  end

  if(key.name == "9") then
    active_prime_index = 9
    refreshprimemaker = true
  end

  if(key.name == "0") then
    active_prime_index = 10
    refreshprimemaker = true
  end

  if(key.name == "a") then
    active_prime_index = 11
    refreshprimemaker = true
  end

  if(key.name == "b") then
    active_prime_index = 12
    refreshprimemaker = true
  end

  if(refreshprimemaker == true) then
    active_prime_degree = 1
    active_primebut_clr(active_prime_type..tostring(active_prime_index))
    coloractivedegree(active_prime_type, tostring(active_prime_index), 1)
    refreshprimemaker = false
  end


  --[[
      
                        active_prime_type="P"
                       active_prime_index=(rowscan-1)
                      active_prime_degree=1
                      
                      active_primebut_clr("P"..tostring(rowscan-1))
                      coloractivedegree("P",tostring(rowscan-1),1)
    ]]--
end