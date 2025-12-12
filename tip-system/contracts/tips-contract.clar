;; Tip System Smart Contract
;; Allows users to send tips to articles using STX

;; Define map to store tips per article
(define-map tips-per-article
  ((article-id (buff 32)))
  ((total-amount uint)
   (tip-count uint)))

;; Define map to store individual tipper info (optional - for stats)
(define-map tip-history
  ((article-id (buff 32))
   (tipper principal))
  ((amount uint)
   (timestamp uint)))

;; Event: Emit when someone tips
(define-public (tip-article 
  (article-id (buff 32))
  (amount uint))
  
  (let (
    (existing-tip (map-get? tips-per-article {article-id: article-id}))
    (new-total (if (is-some existing-tip)
                   (+ (get total-amount (unwrap-panic existing-tip)) amount)
                   amount))
    (new-count (if (is-some existing-tip)
                   (+ (get tip-count (unwrap-panic existing-tip)) u1)
                   u1))
  )
    ;; Transfer STX from sender to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Update total tips
    (map-set tips-per-article
      {article-id: article-id}
      {total-amount: new-total, tip-count: new-count})
    
    ;; Record individual tip
    (map-set tip-history
      {article-id: article-id, tipper: tx-sender}
      {amount: amount, timestamp: block-height})
    
    (ok {success: true, total-amount: new-total})
  )
)

;; Read-only: Get total tips for an article
(define-read-only (get-article-tips (article-id (buff 32)))
  (match (map-get? tips-per-article {article-id: article-id})
    tip-data {
      total-amount: (get total-amount tip-data),
      tip-count: (get tip-count tip-data)
    }
    {total-amount: u0, tip-count: u0}
  )
)

;; Read-only: Get specific tipper amount
(define-read-only (get-tipper-amount 
  (article-id (buff 32))
  (tipper principal))
  (match (map-get? tip-history {article-id: article-id, tipper: tipper})
    tip-record (get amount tip-record)
    u0
  )
)

;; Admin: Withdraw funds (optional)
(define-public (withdraw (amount uint))
  (if (is-eq tx-sender (as-contract tx-sender))
    (stx-transfer? amount (as-contract tx-sender) tx-sender)
    (err u1)
  )
)