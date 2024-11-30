;; This smart contract facilitates a decentralized marketplace for resource listing, transactions, and reimbursements. 
;; It allows users to list, acquire, and manage resources while handling platform fees, reimbursements, and administrative controls. 
;; The contract supports user resource balances, ensures fair transactions, and maintains system-wide resource limits and pricing.
;; Only the admin can set platform fees, resource prices, and manage system-wide settings, while users can interact with resources 
;; based on available balances and predefined limits.

;; Define constants
(define-constant contract-admin tx-sender)
(define-constant err-admin-only (err u200))
(define-constant err-insufficient-balance (err u201))
(define-constant err-transfer-issue (err u202))
(define-constant err-price-invalid (err u203))
(define-constant err-quantity-invalid (err u204))
(define-constant err-fee-invalid (err u205))
(define-constant err-refund-issue (err u206))
(define-constant err-same-user-transaction (err u207))
(define-constant err-exceeds-reserve-limit (err u208))
(define-constant err-invalid-reserve (err u209))

;; Define data variables
(define-data-var resource-price uint u50) ;; Price per resource unit
(define-data-var max-resource-per-user uint u500) ;; Maximum resource allocation per user
(define-data-var platform-fee-rate uint u10) ;; Platform fee in percentage (e.g., 10%)
(define-data-var reimbursement-rate uint u80) ;; Reimbursement rate (e.g., 80%)
(define-data-var total-resource-limit uint u10000) ;; System-wide resource limit
(define-data-var current-resource-balance uint u0) ;; Current resource balance in the system

;; Define data maps
(define-map user-resource-balance principal uint)
(define-map user-stx-balance principal uint)
(define-map resources-listed {user: principal} {quantity: uint, price: uint})

;; Private functions

;; Calculate platform fee
(define-private (compute-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-rate)) u100))

;; Calculate reimbursement
(define-private (compute-reimbursement (amount uint))
  (/ (* amount (var-get resource-price) (var-get reimbursement-rate)) u100))

;; Update resource balance
(define-private (adjust-resource-balance (amount int))
  (let (
    (current-balance (var-get current-resource-balance))
    (new-balance (if (< amount 0)
                     (if (>= current-balance (to-uint (- 0 amount)))
                         (- current-balance (to-uint (- 0 amount)))
                         u0)
                     (+ current-balance (to-uint amount)))))
    (asserts! (<= new-balance (var-get total-resource-limit)) err-exceeds-reserve-limit)
    (var-set current-resource-balance new-balance)
    (ok true)))

;; Public functions

;; Set resource price (only contract admin)
(define-public (set-resource-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-admin) err-admin-only)
    (asserts! (> new-price u0) err-price-invalid)
    (var-set resource-price new-price)
    (ok true)))

;; Set platform fee rate (only contract admin)
(define-public (set-platform-fee (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-admin) err-admin-only)
    (asserts! (<= new-rate u100) err-fee-invalid)
    (var-set platform-fee-rate new-rate)
    (ok true)))

;; Set reimbursement rate (only contract admin)
(define-public (set-reimbursement-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-admin) err-admin-only)
    (asserts! (<= new-rate u100) err-fee-invalid)
    (var-set reimbursement-rate new-rate)
    (ok true)))

;; Set resource reserve limit (only contract admin)
(define-public (set-resource-reserve-limit (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender contract-admin) err-admin-only)
    (asserts! (>= new-limit (var-get current-resource-balance)) err-invalid-reserve)
    (var-set total-resource-limit new-limit)
    (ok true)))

;; List resources for sharing
(define-public (list-resources (quantity uint) (price uint))
  (let (
    (current-balance (default-to u0 (map-get? user-resource-balance tx-sender)))
    (current-listed (get quantity (default-to {quantity: u0, price: u0} (map-get? resources-listed {user: tx-sender}))))
    (new-listing (+ quantity current-listed)))
    (asserts! (> quantity u0) err-quantity-invalid)
    (asserts! (> price u0) err-price-invalid)
    (asserts! (>= current-balance new-listing) err-insufficient-balance)
    (try! (adjust-resource-balance (to-int quantity)))
    (map-set resources-listed {user: tx-sender} {quantity: new-listing, price: price})
    (ok true)))

;; Acquire resources from another user
(define-public (acquire-resources (provider principal) (quantity uint))
  (let (
    (listing-data (default-to {quantity: u0, price: u0} (map-get? resources-listed {user: provider})))
    (resource-cost (* quantity (get price listing-data)))
    (platform-fee (compute-platform-fee resource-cost))
    (total-cost (+ resource-cost platform-fee))
    (provider-resource (default-to u0 (map-get? user-resource-balance provider)))
    (requester-balance (default-to u0 (map-get? user-stx-balance tx-sender)))
    (provider-balance (default-to u0 (map-get? user-stx-balance provider)))
    (admin-balance (default-to u0 (map-get? user-stx-balance contract-admin))))
    (asserts! (not (is-eq tx-sender provider)) err-same-user-transaction)
    (asserts! (> quantity u0) err-quantity-invalid)
    (asserts! (>= (get quantity listing-data) quantity) err-insufficient-balance)
    (asserts! (>= provider-resource quantity) err-insufficient-balance)
    (asserts! (>= requester-balance total-cost) err-insufficient-balance)

    ;; Update provider's resource balance and listing quantity
    (map-set user-resource-balance provider (- provider-resource quantity))
    (map-set resources-listed {user: provider} 
             {quantity: (- (get quantity listing-data) quantity), price: (get price listing-data)})

    ;; Update requester's STX and resource balance
    (map-set user-stx-balance tx-sender (- requester-balance total-cost))
    (map-set user-resource-balance tx-sender (+ (default-to u0 (map-get? user-resource-balance tx-sender)) quantity))

    ;; Update provider's and contract admin's STX balance
    (map-set user-stx-balance provider (+ provider-balance resource-cost))
    (map-set user-stx-balance contract-admin (+ admin-balance platform-fee))

    (ok true)))

;; Request resource reimbursement
(define-public (request-reimbursement (quantity uint))
  (let (
    (user-resource (default-to u0 (map-get? user-resource-balance tx-sender)))
    (reimbursement-amount (compute-reimbursement quantity))
    (contract-stx-balance (default-to u0 (map-get? user-stx-balance contract-admin))))
    (asserts! (> quantity u0) err-quantity-invalid)
    (asserts! (>= user-resource quantity) err-insufficient-balance)
    (asserts! (>= contract-stx-balance reimbursement-amount) err-refund-issue)

    ;; Update user's resource balance
    (map-set user-resource-balance tx-sender (- user-resource quantity))

    ;; Update user's and contract admin's STX balance
    (map-set user-stx-balance tx-sender (+ (default-to u0 (map-get? user-stx-balance tx-sender)) reimbursement-amount))
    (map-set user-stx-balance contract-admin (- contract-stx-balance reimbursement-amount))

    ;; Return reimbursed resource to contract admin's balance
    (map-set user-resource-balance contract-admin (+ (default-to u0 (map-get? user-resource-balance contract-admin)) quantity))

    ;; Update resource balance
    (try! (adjust-resource-balance (to-int (- quantity))))

    (ok true)))
