;; BrightWave Token Contract

(define-fungible-token brightwave)

(define-constant token-name "BrightWave Token")
(define-constant token-symbol "BWT")
(define-constant contract-owner tx-sender)

(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (ft-transfer? brightwave amount sender recipient))

(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u403))
    (ft-mint? brightwave amount recipient)))
