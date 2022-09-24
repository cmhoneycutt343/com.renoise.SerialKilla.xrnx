---------------------------
---------------------------
--12-tone Only Functions---
---------------------------
---------------------------

--[[**********************]]--
--generates random 12 tone prime
--[[**********************]]--
function generate_prime()
  rprint("GENERATEPRIME")

  --reinitialize prime values
  local initialized_prime = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
  local current_prime_val = 0

  --generates 12 tone randomized prime
  for prime_gen_index = 1, 12 do

    --generate a random index
    current_prime_index = math.random(1, 13 - prime_gen_index)

    --get the prime value
    current_prime_val = initialized_prime[current_prime_index]

    --remove that prime value from list of remaining available chroma
    table.remove(initialized_prime, current_prime_index)

    --add prime to newly generated from list
    table.insert(generated_prime, current_prime_val)

  end

  --load new prime into text fields
  for prime_index_col = 1, 12 do
    local tf_in = "prime_in"..tostring(prime_index_col)
    view_input[tf_in].text = tostring(generated_prime[prime_index_col])
  end

  --generate matrix from new prime
  generate_matrix()

  print("")
  print(view_input["1_1"].width)
  print(view_input.oct1_1.width)
  print(view_input.vel1_1.width)

  view_input.loaduserprimebutton.color = {0, 0, 0}

end
