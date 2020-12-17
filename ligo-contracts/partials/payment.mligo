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