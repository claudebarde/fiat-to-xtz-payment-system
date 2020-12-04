(* Admin updates transaction fee *)
let update_tx_fee (new_fee, s: tez * storage): storage = 
  if Tezos.sender <> s.admin
  then (failwith "NOT_AN_ADMIN": storage)
  else
    { s with tx_fee = new_fee }

(* Admin updates oracle's address *)
let update_oracle (new_oracle, s: address * storage): storage = 
  if Tezos.sender <> s.admin
  then (failwith "NOT_AN_ADMIN": storage)
  else
    { s with oracle = new_oracle }

(* Admin pauses/unpauses the contract *)
let pause (s: storage): storage = { s with paused = not s.paused }