(* Creates a new client *)
let add_client (currency, s: string * storage): storage = 
  { s with recipients = 
    Big_map.add Tezos.sender (currency, (Map.empty: (address, nat) map)) s.recipients }

(* Client adds a new recipient *)
let add_recipients (params, s: (address * nat) list * storage): storage = 
  (* Fetches existing recipients for the client *)
  let portfolio: (string * (address, nat) map) = 
    match Big_map.find_opt Tezos.sender s.recipients with
    | None -> (failwith "NO_CLIENT_FOUND": string * (address, nat) map)
    | Some p -> p in
  (* Loops through the list of provided new recipients and updates the recipients map *)
  let updated_recipients: (address, nat) map =
    List.fold (fun (p_map, el: (address, nat) map * (address * nat)) -> 
      Map.add el.0 el.1 p_map
    ) params portfolio.1 in
  (* Updates storage with the new recipients map *)
  { s with recipients = 
    Big_map.update Tezos.sender (Some (portfolio.0, updated_recipients)) s.recipients }

(* Client removes a recipient *)
let remove_recipient (recipient, s: address * storage): storage = 
  (* Fetches existing recipients for the client *)
  let portfolio: (string * (address, nat) map) = 
    match Big_map.find_opt Tezos.sender s.recipients with
    | None -> (failwith "NO_CLIENT_FOUND": string * (address, nat) map)
    | Some p -> p in
  (* Removes recipient *)
  if not Map.mem recipient portfolio.1
  then (failwith "NO_RECIPIENT_FOUND": storage)
  else
    let updated_portfolio = Map.remove recipient portfolio.1 in

    { s with recipients = 
      Big_map.update Tezos.sender (Some (portfolio.0, updated_portfolio)) s.recipients }

(* Allows client to update recipient's details *)
let update_recipient (params, s: (address * nat) * storage): storage = 
  (* Fetches existing recipients for the client *)
  let portfolio: (string * (address, nat) map) = 
    match Big_map.find_opt Tezos.sender s.recipients with
    | None -> (failwith "NO_CLIENT_FOUND": string * (address, nat) map)
    | Some p -> p in
  (* Updates recipient details *)
  if not Map.mem params.0 portfolio.1
  then (failwith "NO_RECIPIENT_FOUND": storage)
  else
    let updated_portfolio = Map.update params.0 (Some params.1) portfolio.1 in

    { s with recipients = 
      Big_map.update Tezos.sender (Some (portfolio.0, updated_portfolio)) s.recipients }

(* Modifies the client's address *)
let update_client (new_address, s: address * storage): storage = 
  (* Copies current value into the new slot *)
  let portfolio: (string * (address, nat) map) = 
    match Big_map.find_opt Tezos.sender s.recipients with
    | None -> (failwith "NO_CLIENT_FOUND": string * (address, nat) map)
    | Some p -> p in
  let new_recipients = Big_map.add new_address portfolio s.recipients in
  (* Removes previous binding and returns big map*)
  { s with recipients = Big_map.remove Tezos.sender new_recipients }