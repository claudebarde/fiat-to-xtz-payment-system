# 1 "./ligo-contracts/fake_oracle.mligo"
type storage = (string, timestamp * nat) big_map

type data = 
[@layout:comb]
{
    currency_pair: string;
    last_update: timestamp;
    exchange_rate: nat;
}

type param_get = string * data contract

type entrypoints =
| Get of param_get
| Update of data

(* Emits a transaction containing the data from the storage *)
let get (param, s: param_get * storage): operation list * storage =
    let info: timestamp * nat = 
        match Big_map.find_opt param.0 s with
        | None -> (failwith "NO_CURRENCY_PAIR_FOUND": timestamp * nat)
        | Some i -> i in
    let data: data = { currency_pair = param.0; last_update = info.0; exchange_rate = info.1 } in

    let op = Tezos.transaction data 0tez param.1 in

    [op], s

(* Saves parameter as new storage *)
let update (param, s: data * storage): operation list * storage =
    ([]: operation list), Big_map.update param.currency_pair (Some (param.last_update, param.exchange_rate)) s

let main ((p, s): entrypoints * storage): operation list * storage =
    match p with
    | Get p -> get (p, s)
    | Update p -> update (p, s)
