;; BrightWave Core Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-prompt (err u101))
(define-constant err-submission-closed (err u102))
(define-constant err-duplicate-submission (err u103))
(define-constant err-invalid-duration (err u104))
(define-constant err-already-voted (err u105))

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

(define-map user-votes (tuple (challenge-id uint) (voter principal) (submission-author principal)) bool)

;; Private functions
(define-private (is-valid-duration (duration uint))
  (and (>= duration u10) (<= duration u10000)))

;; Public functions
(define-public (create-challenge (prompt (string-utf8 500)) (duration uint) (reward uint))
  (begin
    (asserts! (is-valid-duration duration) (err err-invalid-duration))
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
      (ok challenge-id))))

(define-public (submit-entry (challenge-id uint) (content (string-utf8 5000)))
  (let ((challenge (unwrap! (map-get? challenges challenge-id) (err err-invalid-prompt))))
    (asserts! (<= block-height (get end-block challenge)) (err err-submission-closed))
    (asserts! (is-none (map-get? submissions {challenge-id: challenge-id, author: tx-sender})) 
             (err err-duplicate-submission))
    (ok (map-set submissions {challenge-id: challenge-id, author: tx-sender}
      {
        content: content,
        votes: u0,
        timestamp: block-height
      }))))

(define-public (vote-submission (challenge-id uint) (submission-author principal))
  (let ((challenge (unwrap! (map-get? challenges challenge-id) (err err-invalid-prompt)))
        (submission (unwrap! (map-get? submissions {challenge-id: challenge-id, author: submission-author}) 
                           (err err-invalid-prompt))))
    (asserts! (<= block-height (get end-block challenge)) (err err-submission-closed))
    (asserts! (is-none (map-get? user-votes {challenge-id: challenge-id, 
                                            voter: tx-sender, 
                                            submission-author: submission-author}))
             (err err-already-voted))
    (map-set user-votes {challenge-id: challenge-id, 
                        voter: tx-sender, 
                        submission-author: submission-author} 
             true)
    (ok (map-set submissions {challenge-id: challenge-id, author: submission-author}
      {
        content: (get content submission),
        votes: (+ (get votes submission) u1),
        timestamp: (get timestamp submission)
      }))))
