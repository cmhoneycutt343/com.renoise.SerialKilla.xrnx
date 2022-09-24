-----------------------
--OSC / Note Triggering
-----------------------
--osc objects
local client, socket_error
local OscMessage
local OscBundle
local notevalue_curaud
aud_bool = true
received_degree_info = 0

function current_degree_abspitch()
  --get degree info
  received_degree_info = retreivecellattribs(active_prime_type, active_prime_index, active_prime_degree)

  local degreein = notetochroma[received_degree_info[1]]

  local oct_scale_crr = 0
  local reloct_buf = tonumber(received_degree_info[5])

  --correction to add octave to all notes 'below' the global tonic
  if(degreein < tonic_offset) then
    oct_scale_crr = 1
  end

  --gets octave offset from GUI
  chromatic_offset = (renoise.song().transport.octave + oct_scale_crr) * 12

  local note_absvalue = degreein + chromatic_offset + (reloct_buf * 12)

  return note_absvalue
end

function start_osc()
  client, socket_error = renoise.Socket.create_client(
  "localhost", 8008, renoise.Socket.PROTOCOL_UDP)

  if (socket_error) then
    renoise.app():show_warning(("Failed to start the " ..
    "OSC client. Error: '%s'"):format(socket_error))
    return
  end

  OscMessage = renoise.Osc.Message
  OscBundle = renoise.Osc.Bundle
end

start_osc()

function note_off_func()

  local note_off = OscMessage("/renoise/trigger/note_off", {
    {tag = "i", value = -1},
    {tag = "i", value = -1},
    {tag = "i", value = notevalue_curaud},
  })

  client:send(note_off)
  renoise.tool():remove_timer(note_off_func)
end

function audition_cell()
  print("in audition_cell()")



  if (renoise.tool():has_timer(note_off_func) == true) then
    print("im bsuy damnit")
    note_off_func()


  else

  end

  notevalue_curaud = current_degree_abspitch()

  local note_on = OscMessage("/renoise/trigger/note_on", {
    {tag = "i", value = -1},
    {tag = "i", value = -1},
    {tag = "i", value = notevalue_curaud},
    {tag = "i", value = tonumber(received_degree_info[2])}
  })

  client:send(note_on)
  renoise.tool():add_timer(note_off_func, 1000)
end

function audition_row()
end
