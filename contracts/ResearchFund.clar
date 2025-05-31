;; ResearchFund: Decentralized Scientific Research Funding Platform
;; Version: 1.0.0

(define-data-var fund-coordinator principal tx-sender)
(define-data-var total-research-credits uint u0)
(define-data-var monthly-allocation uint u50) ;; allocation credits per block
(define-data-var last-allocation-block uint u0) ;; last block when allocations were calculated
(define-map researcher-credits principal uint)

;; Helper function to ensure only the fund coordinator can perform certain actions
(define-private (is-fund-coordinator (caller principal))
  (begin
    (asserts! (is-eq caller (var-get fund-coordinator)) (err u200))
    (ok true)))

;; Initialize the research funding system
(define-public (establish-fund (coordinator principal))
  (begin
    (asserts! (is-none (map-get? researcher-credits coordinator)) (err u201))
    (var-set fund-coordinator coordinator)
    (ok "ResearchFund established successfully")))

;; Register research contribution credits
(define-public (contribute-research (credits uint))
  (begin
    (asserts! (> credits u0) (err u202))
    (let ((current-credits (default-to u0 (map-get? researcher-credits tx-sender))))
      (map-set researcher-credits tx-sender (+ current-credits credits))
      (var-set total-research-credits (+ (var-get total-research-credits) credits))
      (ok (+ current-credits credits)))))

;; Calculate monthly research allocations
(define-public (distribute-allocations)
  (begin
    (try! (is-fund-coordinator tx-sender))
    (let ((current-block tenure-height)
          (previous-distribution (var-get last-allocation-block)))
      (asserts! (> current-block previous-distribution) (err u203))
      ;; Calculate allocations based on blocks elapsed
      (let ((elapsed (- current-block previous-distribution))
            (total-allocation (* elapsed (var-get monthly-allocation))))
        (var-set last-allocation-block current-block)
        (var-set total-research-credits (+ (var-get total-research-credits) total-allocation))
        (ok total-allocation)))))

;; Submit research proposal and claim funding
(define-public (submit-proposal)
  (begin
    (let ((researcher-contribution (default-to u0 (map-get? researcher-credits tx-sender))))
      (asserts! (> researcher-contribution u0) (err u204))
      (let ((total-credits (var-get total-research-credits))
            (new-allocations (* (var-get monthly-allocation) (- tenure-height (var-get last-allocation-block))))
            (contribution-ratio (/ (* researcher-contribution u100000) total-credits)))
        ;; Calculate researcher's share of funding
        (let ((funding-share (/ (* contribution-ratio new-allocations) u100000)))
          (map-delete researcher-credits tx-sender)
          (var-set total-research-credits (- (var-get total-research-credits) researcher-contribution))
          (ok (+ researcher-contribution funding-share)))))))