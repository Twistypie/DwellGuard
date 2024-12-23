;; DwellGuard: A Secure Escrow Smart Contract for Real Estate Transactions
;; Version: 2.1
;; Author: Your Organization
;; License: MIT

;; Constants
(define-constant ADMIN tx-sender)
(define-constant DURATION-LIMIT u365)
(define-constant BUILD-YEAR-MIN u1900)
(define-constant BUILD-YEAR-MAX u2100)
(define-constant DAILY-BLOCKS u144)
(define-constant EARNEST-MONEY-PERCENT u10)
(define-constant UINT-CEILING u340282366920938463463374607431768211455)

;; Error Constants
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-SETUP-EXISTS (err u101))
(define-constant ERR-NO-SETUP (err u102))
(define-constant ERR-INVALID-COST (err u103))
(define-constant ERR-FUNDS-SENT (err u104))
(define-constant ERR-NO-FUNDS (err u105))
(define-constant ERR-BAD-STATE (err u106))
(define-constant ERR-BAD-OWNER (err u107))
(define-constant ERR-BAD-PURCHASER (err u108))
(define-constant ERR-BAD-USER (err u109))
(define-constant ERR-TIME-EXPIRED (err u110))
(define-constant ERR-FAILED-CHECK (err u111))
(define-constant ERR-BAD-SUM (err u112))
(define-constant ERR-BAD-TIMEFRAME (err u113))
(define-constant ERR-BAD-HOME-ID (err u114))
(define-constant ERR-BAD-DIMENSIONS (err u115))
(define-constant ERR-BAD-DATE (err u116))
(define-constant ERR-BAD-LOCATION (err u117))
(define-constant ERR-MATH-OVERFLOW (err u118))

;; Data Variables
(define-data-var admin-wallet principal ADMIN)
(define-data-var home-owner principal ADMIN)
(define-data-var home-buyer (optional principal) none)
(define-data-var home-cost uint u0)
(define-data-var earnest-money uint u0)
(define-data-var setup-complete bool false)
(define-data-var funds-received bool false)
(define-data-var deal-closed bool false)
(define-data-var expiration uint u0)
(define-data-var check-passed bool false)
(define-data-var repair-reserve uint u0)

;; Data Maps
(define-map verified-users principal bool)
(define-map payment-log
  { payment-id: uint }
  {
    value: uint,
    block: uint,
    state: (string-ascii 20)
  })

(define-map home-registry
  { home-id: uint }
  {
    location: (string-ascii 50),
    square-feet: uint,
    construction-date: uint,
    check-date: uint
  })

;; Private Functions
(define-private (is-admin)
  (is-eq tx-sender (var-get admin-wallet)))

(define-private (is-owner)
  (is-eq tx-sender (var-get home-owner)))

(define-private (is-purchaser)
  (match (var-get home-buyer)
    buyer-wallet (is-eq tx-sender buyer-wallet)
    false))

(define-private (verify-user (user-wallet principal))
  (begin
    (asserts! (not (is-eq user-wallet ADMIN)) ERR-BAD-USER)
    (asserts! (not (is-eq user-wallet tx-sender)) ERR-BAD-USER)
    (ok user-wallet)))

(define-private (register-user (user-wallet principal))
  (begin
    (try! (verify-user user-wallet))
    (map-set verified-users user-wallet true)
    (ok user-wallet)))

(define-private (check-time)
  (if (> block-height (var-get expiration))
    ERR-TIME-EXPIRED
    (ok true)))

(define-private (verify-timeframe (days uint))
  (if (and (> days u0) (<= days DURATION-LIMIT))
    (ok days)
    ERR-BAD-TIMEFRAME))

(define-private (verify-home-id (id uint))
  (if (and (> id u0) (< id UINT-CEILING))
    (ok id)
    ERR-BAD-HOME-ID))

(define-private (verify-dimensions (size uint))
  (if (and (> size u0) (< size UINT-CEILING))
    (ok size)
    ERR-BAD-DIMENSIONS))

(define-private (verify-build-date (year uint))
  (if (and (>= year BUILD-YEAR-MIN) (<= year BUILD-YEAR-MAX))
    (ok year)
    ERR-BAD-DATE))

(define-private (verify-location (loc (string-ascii 50)))
  (if (> (len loc) u0)
    (ok loc)
    ERR-BAD-LOCATION))

(define-private (verify-check-status (status bool))
  (ok status))

(define-private (calc-blocks (days uint))
  (let ((verified-days (try! (verify-timeframe days))))
    (asserts! (< (* verified-days DAILY-BLOCKS) UINT-CEILING) ERR-MATH-OVERFLOW)
    (ok (* verified-days DAILY-BLOCKS))))

(define-private (safe-sum (a uint) (b uint))
  (let ((total (+ a b)))
    (asserts! (>= total a) ERR-MATH-OVERFLOW)
    (ok total)))

;; Public Functions
(define-public (setup-escrow (seller principal) (buyer principal) (price uint) (days uint))
  (begin
    (asserts! (not (var-get setup-complete)) ERR-SETUP-EXISTS)
    (asserts! (is-admin) ERR-UNAUTHORIZED)
    (asserts! (> price u0) ERR-INVALID-COST)
    (asserts! (not (is-eq seller buyer)) ERR-BAD-USER)
    
    (let ((verified-days (unwrap! (verify-timeframe days) ERR-BAD-TIMEFRAME))
          (blocks (try! (calc-blocks verified-days))))
      
      (try! (register-user seller))
      (try! (register-user buyer))
      
      (var-set home-owner seller)
      (var-set home-buyer (some buyer))
      (var-set home-cost price)
      (var-set earnest-money (/ (* price EARNEST-MONEY-PERCENT) u100))
      (try! (safe-sum block-height blocks))
      (var-set expiration (+ block-height blocks))
      (var-set setup-complete true)
      (ok true))))

(define-public (register-home (id uint) (loc (string-ascii 50)) (size uint) (year uint))
  (begin
    (asserts! (is-owner) ERR-UNAUTHORIZED)
    (asserts! (var-get setup-complete) ERR-NO-SETUP)
    
    (let ((verified-id (unwrap! (verify-home-id id) ERR-BAD-HOME-ID))
          (verified-loc (unwrap! (verify-location loc) ERR-BAD-LOCATION))
          (verified-size (unwrap! (verify-dimensions size) ERR-BAD-DIMENSIONS))
          (verified-year (unwrap! (verify-build-date year) ERR-BAD-DATE)))
      
      (map-set home-registry
        { home-id: verified-id }
        {
          location: verified-loc,
          square-feet: verified-size,
          construction-date: verified-year,
          check-date: u0
        })
      (ok true))))

(define-public (record-check (id uint) (status bool))
  (begin
    (asserts! (is-admin) ERR-UNAUTHORIZED)
    (asserts! (var-get setup-complete) ERR-NO-SETUP)
    
    (let ((verified-id (unwrap! (verify-home-id id) ERR-BAD-HOME-ID))
          (verified-status (unwrap! (verify-check-status status) ERR-BAD-STATE)))
      (var-set check-passed verified-status)
      (ok true))))

(define-public (submit-earnest)
  (let ((deposit (var-get earnest-money)))
    (begin
      (try! (check-time))
      (asserts! (var-get setup-complete) ERR-NO-SETUP)
      (asserts! (is-purchaser) ERR-UNAUTHORIZED)
      (asserts! (not (var-get funds-received)) ERR-FUNDS-SENT)
      
      (try! (stx-transfer? deposit tx-sender (as-contract tx-sender)))
      (var-set funds-received true)
      (map-set payment-log {payment-id: u1}
        {
          value: deposit,
          block: block-height,
          state: "RECEIVED"
        })
      (ok true))))

(define-public (complete-payment)
  (let ((balance (- (var-get home-cost) (var-get earnest-money))))
    (begin
      (try! (check-time))
      (asserts! (var-get setup-complete) ERR-NO-SETUP)
      (asserts! (is-purchaser) ERR-UNAUTHORIZED)
      (asserts! (var-get funds-received) ERR-NO-FUNDS)
      (asserts! (var-get check-passed) ERR-FAILED-CHECK)
      
      (try! (stx-transfer? balance tx-sender (var-get home-owner)))
      (var-set deal-closed true)
      (map-set payment-log {payment-id: u2}
        {
          value: balance,
          block: block-height,
          state: "FINALIZED"
        })
      (ok true))))

(define-public (return-earnest)
  (let ((buyer-wallet (unwrap! (var-get home-buyer) ERR-NO-SETUP)))
    (begin
      (asserts! (var-get setup-complete) ERR-NO-SETUP)
      (asserts! (is-admin) ERR-UNAUTHORIZED)
      (asserts! (var-get funds-received) ERR-NO-FUNDS)
      (asserts! (not (var-get deal-closed)) ERR-BAD-STATE)
      
      (try! (as-contract (stx-transfer? (var-get earnest-money) tx-sender buyer-wallet)))
      (var-set funds-received false)
      (map-set payment-log {payment-id: u3}
        {
          value: (var-get earnest-money),
          block: block-height,
          state: "RETURNED"
        })
      (ok true))))

(define-public (add-repair-funds (amount uint))
  (begin
    (asserts! (var-get deal-closed) ERR-BAD-STATE)
    (asserts! (> amount u0) ERR-BAD-SUM)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set repair-reserve (+ (var-get repair-reserve) amount))
    (ok true)))

;; Read-only Functions
(define-read-only (get-escrow-info)
  {
    owner: (var-get home-owner),
    purchaser: (var-get home-buyer),
    cost: (var-get home-cost),
    earnest: (var-get earnest-money),
    setup-complete: (var-get setup-complete),
    funds-received: (var-get funds-received),
    deal-closed: (var-get deal-closed),
    expiration: (var-get expiration),
    check-status: (var-get check-passed),
    repair-balance: (var-get repair-reserve)
  })

(define-read-only (get-payment-info (payment-id uint))
  (map-get? payment-log {payment-id: payment-id}))

(define-read-only (get-home-info (home-id uint))
  (map-get? home-registry {home-id: home-id}))

(define-read-only (is-verified-user (user-wallet principal))
  (default-to false (map-get? verified-users user-wallet)))

(define-read-only (get-remaining-time)
  (if (> (var-get expiration) block-height)
    (some (- (var-get expiration) block-height))
    none))