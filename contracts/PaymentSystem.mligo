# 1 "./ligo-contracts/main.mligo"

# 1 "./ligo-contracts/./partials/types.mligo" 1
type pending_payment = (address * tez) option

type storage = 
[@layout:comb]
{
  (* client => [currency * recipient => amount] *)
  recipients: (address, string * (address, nat) map) big_map; 
  pending_payment: pending_payment;
  tx_fee: tez;
  admin: address;
  oracle: address;
  paused: bool;
}

type oracle_val = string * (timestamp * nat)
type oracle_param = string * oracle_val contract

type entrypoints =
| Add_client of string
| Add_recipients of (address * nat) list
| Remove_recipient of address
| Update_recipient of address * nat
| Update_client of address
| Request_payment of unit
| Process_payment of oracle_val
| Update_tx_fee of tez
| Update_oracle of address
| Pause of unit
| Withdraw of unit
# 2 "./ligo-contracts/main.mligo" 2

# 1 "./ligo-contracts/./partials/client_features.mligo" 1
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
# 3 "./ligo-contracts/main.mligo" 2

# 1 "./ligo-contracts/./partials/admin_features.mligo" 1
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
# 4 "./ligo-contracts/main.mligo" 2

# 1 "./ligo-contracts/./partials/payment.mligo" 1
(* Client requests a new payment *)
let request_payment (s: storage): operation list * storage = 
  (* Verifies there is no active pending payment for the same client *)
  if s.paused
  then (failwith "ACTIVE_PENDING_PAYMENT": operation list * storage)
  else
    if Tezos.amount = 0tez
    then (failwith "NO_AMOUNT": operation list * storage)
    else 
      (* Verifies sender is a registered client *)
      let portfolio: (string * (address, nat) map) = 
        match Big_map.find_opt Tezos.sender s.recipients with
        | None -> (failwith "NO_CLIENT_FOUND": string * (address, nat) map)
        | Some p -> p in
      (* Verifies the recipients map is not empty *)
      if Map.size portfolio.1 = 0n
      then (failwith "NO_RECIPIENTS": operation list * storage)
      else
        (* Prepares oracle reference *)
        let contract: oracle_param contract = 
          match ((Tezos.get_entrypoint_opt "%get" s.oracle): oracle_param contract option) with
          | None -> (failwith "NO_ORACLE_FOUND": oracle_param contract)
          | Some c -> c in
        (* Prepares parameter to be attached to transaction *)
        let param: string * oracle_val contract = 
          String.concat "XTZ-" portfolio.0, (Tezos.self("%process_payment"): oracle_val contract) in
        (* Emits transaction to the oracle *)
        let op = Tezos.transaction param 0tez contract in

        (* Updates pending payments and returns storage *)
        [op], 
        { s with 
          pending_payment = Some (Tezos.sender, (Tezos.amount - s.tx_fee)); 
          paused = true }

(* Value for payment is returned from the oracle *)
let process_payment (params, s: oracle_val * storage): operation list * storage = 
  (* Contract must be paused *)
  if not s.paused
  then (failwith "CONTRACT_IS_UNLOCKED": operation list * storage)
  else
    (* There must be a value in pending payments *)
    let pending_payment: address * tez =
      match s.pending_payment with
      | None -> (failwith "NO_ACTIVE_PENDING_PAYMENT": address * tez)
      | Some p -> p in
    let exchange_rate: nat = params.1.1 in
    (* Accepts transactions coming only from oracle *)
    if Tezos.sender <> s.oracle
    then (failwith "UNRECOGNIZED_SENDER": operation list * storage)
    else
      (* Must be a registered client *)
      let client: string * (address, nat) map = 
        match Big_map.find_opt pending_payment.0 s.recipients with
        | None -> (failwith "NO_CLIENT": string * (address, nat) map)
        | Some c -> c in
      (* Verifies the currencies pair is correct *)
      if String.concat "XTZ-" client.0 <> params.0
      then (failwith "UNKNOWN_CURRENCY_PAIR": operation list * storage)
      else
        (* Prepares list of operations *)
        let total_amount = pending_payment.1 in
        let xtz_dispatch: operation list * tez =
          Map.fold (fun ((ops, payment), recipient: (operation list * tez) * (address * nat)) -> 
            let amount_in_fiat: nat = recipient.1 in
            let amount_to_send: tez = ((amount_in_fiat * 1_000_000_000_000n) / exchange_rate) * 0.000_001tez in
            if payment - amount_to_send < 0tez
            then (failwith "INSUFFICIENT_BALANCE": operation list * tez)
            else 
              let account: unit contract = 
                match (Tezos.get_contract_opt (recipient.0: address): unit contract option) with
                | None -> (failwith "INCORRECT_ACCOUNT": unit contract)
                | Some a -> a in

              let tx = Tezos.transaction unit amount_to_send account in

              (tx :: ops, payment - amount_to_send)
          ) client.1 (([]: operation list), total_amount) in
          let list_of_operations = xtz_dispatch.0 in
          let remainder = xtz_dispatch.1 in
        (* Sends back remaining tez if some is left *)
        if remainder > 0.0001tez
        then
          let account: unit contract = 
            match (Tezos.get_contract_opt pending_payment.0: unit contract option) with
            | None -> (failwith "INCORRECT_ACCOUNT": unit contract)
            | Some a -> a in

          let tx = Tezos.transaction unit remainder account in
          let operations = tx :: list_of_operations in

          operations, 
          { s with pending_payment = (None: pending_payment); paused = false }
        else
          list_of_operations, 
          { s with pending_payment = (None: pending_payment); paused = false }
# 5 "./ligo-contracts/main.mligo" 2

let main (p, s: entrypoints * storage): operation list * storage =
  match p with
  | Add_client n -> ([]: operation list), add_client (n, s)
  | Add_recipients n -> ([]: operation list), add_recipients (n, s)
  | Remove_recipient n -> ([]: operation list), remove_recipient (n, s)
  | Update_recipient n -> ([]: operation list), update_recipient (n, s)
  | Update_client n -> ([]: operation list), update_client (n, s)
  | Request_payment n -> request_payment s
  | Process_payment n -> process_payment (n, s)
  | Update_tx_fee n -> ([]: operation list), update_tx_fee (n, s)
  | Update_oracle n -> ([]: operation list), update_oracle (n, s)
  | Pause n -> ([]: operation list), pause s
  | Withdraw n -> withdraw s
