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

(* Admin withdraw income from transaction fee *)
let withdraw (s: storage): operation list * storage =
  if Tezos.sender <> s.admin
  then (failwith "NOT_AN_ADMIN": operation list * storage)
  else
    let account: unit contract = 
      match (Tezos.get_contract_opt (s.admin): unit contract option) with
      | None -> (failwith "INCORRECT_ACCOUNT": unit contract)
      | Some a -> a in
    let op = Tezos.transaction unit Tezos.balance account in

    [op], s