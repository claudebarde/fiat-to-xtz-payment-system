(* Client requests a new payment *)
let request_payment (s: storage): operation list * storage = 
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
      (* Verifies there is no pending payment for the same client *)
      if Map.mem Tezos.sender s.pending_payments
      then (failwith "ACTIVE_PENDING_PAYMENT": operation list * storage)
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
        [op], { s with pending_payments = Map.add Tezos.sender Tezos.amount s.pending_payments }

(* Value for payment is returned from the oracle *)
let process_payment (params, s: oracle_val * storage): operation list * storage = 
  let exchange_rate: nat = params.1.1 in
  (* Accepts transactions coming only from oracle *)
  if Tezos.sender <> s.oracle
  then (failwith "UNRECOGNIZED_SENDER": operation list * storage)
  else
    (* Must be a registered client *)
    let client: string * (address, nat) map = 
      match Big_map.find_opt Tezos.source s.recipients with
      | None -> (failwith "NO_CLIENT": string * (address, nat) map)
      | Some c -> c in
    (* Verifies the currencies pair is correct *)
    if String.concat "XTZ-" client.0 <> params.0
    then (failwith "UNKNOWN_CURRENCY_PAIR": operation list * storage)
    else
      (* Prepares list of operations *)
      let total_amount = 
        match Map.find_opt Tezos.source s.pending_payments with
        | None -> (failwith "UNRECOGNIZED_OPERATION": tez)
        | Some t -> t - s.tx_fee in
      let list_of_operations: operation list * tez =
        Map.fold (fun ((ops, payment), recipient: (operation list * tez) * (address * nat)) -> 
          let amount_to_send: tez = (recipient.1 * exchange_rate) * 0.000_001tez in
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
      (* Sends back remaining tez if some is left *)
      if total_amount > 0tez
      then
        let account: unit contract = 
          match (Tezos.get_contract_opt Tezos.source: unit contract option) with
          | None -> (failwith "INCORRECT_ACCOUNT": unit contract)
          | Some a -> a in

        let tx = Tezos.transaction unit total_amount account in
        let operations = tx :: list_of_operations.0 in

        operations, 
        { s with pending_payments = Map.remove Tezos.source s.pending_payments }
      else
        list_of_operations.0, 
        { s with pending_payments = Map.remove Tezos.source s.pending_payments }