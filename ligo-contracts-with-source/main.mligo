#include "./partials/types.mligo"
#include "./partials/client_features.mligo"
#include "./partials/admin_features.mligo"
#include "./partials/payment.mligo"

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