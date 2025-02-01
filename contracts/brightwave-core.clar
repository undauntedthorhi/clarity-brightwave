;; BrightWave Core Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-prompt (err u101))
(define-constant err-submission-closed (err u102))

;; Data vars
(define-data-var challenge-counter uint u0)

;; Data maps
(define-map challenges uint {
  creator: principal,
  prompt: (string-utf8 500),
  start-block: uint,
  end-block: uint,
  reward: uint,
  status: (string-ascii 10)
})

(define-map submissions (tuple (challenge-id uint) (author principal)) {
  content: (string-utf8 5000),
  votes: uint,
  timestamp: uint
})

;; Public functions
(define-public (create-challenge (prompt (string-utf8 500)) (duration uint) (reward uint))
  (let ((challenge-id (var-get challenge-counter)))
    (map-set challenges challenge-id {
      creator: tx-sender,
      prompt: prompt,
      start-block: block-height,
      end-block: (+ block-height duration),
      reward: reward,
      status: "active"
    })
    (var-set challenge-counter (+ challenge-id u1))
    (ok challenge-id)))

(define-public (submit-entry (challenge-id uint) (content (string-utf8 5000)))
  (let ((challenge (unwrap! (map-get? challenges challenge-id) (err err-invalid-prompt))))
    (asserts! (<= block-height (get end-block challenge)) (err err-submission-closed))
    (ok (map-set submissions {challenge-id: challenge-id, author: tx-sender}
      {
        content: content,
        votes: u0,
        timestamp: block-height
      }))))
