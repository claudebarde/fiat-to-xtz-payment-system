type storage = 
[@layout:comb]
{
  (* client => [currency * recipient => amount] *)
  recipients: (address, string * (address, nat) map) big_map; 
  pending_payments: (address, tez) map;
  tx_fee: tez;
  admin: address;
  oracle: address;
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