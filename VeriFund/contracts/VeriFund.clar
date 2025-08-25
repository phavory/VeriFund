;; Small Business Loan Microfinance Contract
;; A blockchain-powered microfinance institution providing transparent small business loans to qualified entrepreneurs

;; Define constants
(define-constant LOAN-OFFICER tx-sender)
(define-constant ERROR-NOT-LOAN-OFFICER (err u100))
(define-constant ERROR-LOAN-ALREADY-DISBURSED (err u101))
(define-constant ERROR-ENTREPRENEUR-NOT-QUALIFIED (err u102))
(define-constant ERROR-INSUFFICIENT-LOAN-CAPITAL (err u103))
(define-constant ERROR-LENDING-PROGRAM-INACTIVE (err u104))
(define-constant ERROR-INVALID-LOAN-AMOUNT (err u105))
(define-constant ERROR-REPAYMENT-PERIOD-NOT-ENDED (err u106))
(define-constant ERROR-INVALID-ENTREPRENEUR (err u107))
(define-constant ERROR-INVALID-LOAN-TERM (err u108))

;; Define data variables
(define-data-var is-lending-program-active bool true)
(define-data-var total-loans-disbursed uint u0)
(define-data-var loan-amount-per-entrepreneur uint u100)
(define-data-var lending-program-launch-block uint stacks-block-height)
(define-data-var loan-term-duration uint u10000) ;; Number of blocks after which unclaimed funds can be withdrawn

;; Define data maps
(define-map qualified-business-entrepreneurs principal bool)
(define-map disbursed-loan-amounts principal uint)

;; Define fungible token
(define-fungible-token microfinance-loan-token)

;; Define events
(define-data-var next-transaction-id uint u0)
(define-map loan-transactions uint {transaction-type: (string-ascii 20), details: (string-ascii 256)})

;; Transaction logging function
(define-private (log-loan-transaction (transaction-type (string-ascii 20)) (details (string-ascii 256)))
  (let ((transaction-id (var-get next-transaction-id)))
    (map-set loan-transactions transaction-id {transaction-type: transaction-type, details: details})
    (var-set next-transaction-id (+ transaction-id u1))
    transaction-id))

;; Loan officer functions

(define-public (qualify-entrepreneur (entrepreneur-address principal))
  (begin
    (asserts! (is-eq tx-sender LOAN-OFFICER) ERROR-NOT-LOAN-OFFICER)
    (asserts! (is-none (map-get? qualified-business-entrepreneurs entrepreneur-address)) ERROR-INVALID-ENTREPRENEUR)
    (log-loan-transaction "qualified" "new entrepreneur qualified for loan")
    (ok (map-set qualified-business-entrepreneurs entrepreneur-address true))))

(define-public (disqualify-entrepreneur (entrepreneur-address principal))
  (begin
    (asserts! (is-eq tx-sender LOAN-OFFICER) ERROR-NOT-LOAN-OFFICER)
    (asserts! (is-some (map-get? qualified-business-entrepreneurs entrepreneur-address)) ERROR-ENTREPRENEUR-NOT-QUALIFIED)
    (log-loan-transaction "disqualified" "entrepreneur loan qualification revoked")
    (ok (map-delete qualified-business-entrepreneurs entrepreneur-address))))

(define-public (bulk-qualify-entrepreneurs (entrepreneur-addresses (list 200 principal)))
  (begin
    (asserts! (is-eq tx-sender LOAN-OFFICER) ERROR-NOT-LOAN-OFFICER)
    (log-loan-transaction "bulk-qualified" "multiple entrepreneurs qualified")
    (ok (map qualify-entrepreneur entrepreneur-addresses))))

(define-public (update-loan-amount (new-amount uint))
  (begin
    (asserts! (is-eq tx-sender LOAN-OFFICER) ERROR-NOT-LOAN-OFFICER)
    (asserts! (> new-amount u0) ERROR-INVALID-LOAN-AMOUNT)
    (var-set loan-amount-per-entrepreneur new-amount)
    (log-loan-transaction "amount-updated" "microloan amount per entrepreneur updated")
    (ok new-amount)))

(define-public (update-loan-term (new-term uint))
  (begin
    (asserts! (is-eq tx-sender LOAN-OFFICER) ERROR-NOT-LOAN-OFFICER)
    (asserts! (> new-term u0) ERROR-INVALID-LOAN-TERM)
    (var-set loan-term-duration new-term)
    (log-loan-transaction "term-updated" "loan term duration updated")
    (ok new-term)))

;; Loan disbursement function

(define-public (claim-business-loan)
  (let (
    (entrepreneur-address tx-sender)
    (loan-disbursement (var-get loan-amount-per-entrepreneur))
  )
    (asserts! (var-get is-lending-program-active) ERROR-LENDING-PROGRAM-INACTIVE)
    (asserts! (is-some (map-get? qualified-business-entrepreneurs entrepreneur-address)) ERROR-ENTREPRENEUR-NOT-QUALIFIED)
    (asserts! (is-none (map-get? disbursed-loan-amounts entrepreneur-address)) ERROR-LOAN-ALREADY-DISBURSED)
    (asserts! (<= loan-disbursement (ft-get-balance microfinance-loan-token LOAN-OFFICER)) ERROR-INSUFFICIENT-LOAN-CAPITAL)
    (try! (ft-transfer? microfinance-loan-token loan-disbursement LOAN-OFFICER entrepreneur-address))
    (map-set disbursed-loan-amounts entrepreneur-address loan-disbursement)
    (var-set total-loans-disbursed (+ (var-get total-loans-disbursed) loan-disbursement))
    (log-loan-transaction "loan-disbursed" "microloan disbursed to entrepreneur")
    (ok loan-disbursement)))

;; Capital withdrawal function

(define-public (withdraw-undisbursed-capital)
  (let (
    (current-block stacks-block-height)
    (withdrawal-allowed-after (+ (var-get lending-program-launch-block) (var-get loan-term-duration)))
  )
    (asserts! (is-eq tx-sender LOAN-OFFICER) ERROR-NOT-LOAN-OFFICER)
    (asserts! (>= current-block withdrawal-allowed-after) ERROR-REPAYMENT-PERIOD-NOT-ENDED)
    (let (
      (total-minted (ft-get-supply microfinance-loan-token))
      (total-disbursed (var-get total-loans-disbursed))
      (undisbursed-amount (- total-minted total-disbursed))
    )
      (try! (ft-burn? microfinance-loan-token undisbursed-amount LOAN-OFFICER))
      (log-loan-transaction "capital-withdrawn" "undisbursed loan capital withdrawn")
      (ok undisbursed-amount))))

;; Read-only functions

(define-read-only (get-lending-program-status)
  (var-get is-lending-program-active))

(define-read-only (is-entrepreneur-qualified (entrepreneur-address principal))
  (default-to false (map-get? qualified-business-entrepreneurs entrepreneur-address)))

(define-read-only (has-entrepreneur-received-loan (entrepreneur-address principal))
  (is-some (map-get? disbursed-loan-amounts entrepreneur-address)))

(define-read-only (get-entrepreneur-loan-amount (entrepreneur-address principal))
  (default-to u0 (map-get? disbursed-loan-amounts entrepreneur-address)))

(define-read-only (get-total-loans-disbursed)
  (var-get total-loans-disbursed))

(define-read-only (get-loan-amount-per-entrepreneur)
  (var-get loan-amount-per-entrepreneur))

(define-read-only (get-loan-term-duration)
  (var-get loan-term-duration))

(define-read-only (get-lending-program-launch-block)
  (var-get lending-program-launch-block))

(define-read-only (get-loan-transaction (transaction-id uint))
  (map-get? loan-transactions transaction-id))

;; Contract initialization

(begin
  (ft-mint? microfinance-loan-token u1000000000 LOAN-OFFICER))