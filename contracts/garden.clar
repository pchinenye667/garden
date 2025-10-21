;; title: Blockchain Garden
;; version: 1.0.0
;; summary: A simple NFT garden where each wallet grows a plant over time
;; description: Plants grow when watered and wither from neglect

;; token definitions
(define-non-fungible-token garden-plant uint)

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-planted (err u101))
(define-constant err-no-plant (err u102))
(define-constant err-plant-dead (err u103))
(define-constant err-not-owner (err u104))

;; Growth and decay rates (blocks)
(define-constant growth-rate u144) ;; ~1 day in blocks
(define-constant decay-rate u288) ;; ~2 days without water before withering starts
(define-constant max-health u100)
(define-constant min-health u0)
(define-constant water-boost u10)
(define-constant wither-penalty u5)

;; data vars
(define-data-var next-plant-id uint u1)

;; data maps
(define-map plants
  uint
  {
    owner: principal,
    planted-at: uint,
    last-watered: uint,
    health: uint,
    total-waters: uint
  }
)

(define-map owner-plants principal uint)

;; private functions

(define-private (calculate-health (plant-id uint))
  (let (
    (plant (unwrap! (map-get? plants plant-id) u0))
    (current-block block-height)
    (last-watered (get last-watered plant))
    (current-health (get health plant))
    (blocks-since-water (- current-block last-watered))
  )
    (if (>= blocks-since-water decay-rate)
      ;; Plant is withering - reduce health
      (let ((wither-periods (/ (- blocks-since-water decay-rate) growth-rate)))
        (if (> (* wither-periods wither-penalty) current-health)
          min-health
          (- current-health (* wither-periods wither-penalty))
        )
      )
      ;; Plant is healthy - increase health
      (let ((growth-periods (/ blocks-since-water growth-rate)))
        (if (> (+ current-health growth-periods) max-health)
          max-health
          (+ current-health growth-periods)
        )
      )
    )
  )
)

(define-private (get-growth-stage (health uint))
  (if (<= health u0)
    "dead"
    (if (<= health u20)
      "withered"
      (if (<= health u40)
        "seedling"
        (if (<= health u60)
          "sprout"
          (if (<= health u80)
            "growing"
            "flourishing"
          )
        )
      )
    )
  )
)

;; public functions

(define-public (plant-seed)
  (let (
    (plant-id (var-get next-plant-id))
    (sender tx-sender)
  )
    ;; Check if user already has a plant
    (asserts! (is-none (map-get? owner-plants sender)) err-already-planted)

    ;; Mint the NFT
    (try! (nft-mint? garden-plant plant-id sender))

    ;; Create plant record
    (map-set plants plant-id {
      owner: sender,
      planted-at: block-height,
      last-watered: block-height,
      health: u50,
      total-waters: u0
    })

    ;; Map owner to plant
    (map-set owner-plants sender plant-id)

    ;; Increment next plant ID
    (var-set next-plant-id (+ plant-id u1))

    (ok plant-id)
  )
)

(define-public (water-plant (plant-id uint))
  (let (
    (plant (unwrap! (map-get? plants plant-id) err-no-plant))
    (sender tx-sender)
    (current-health (calculate-health plant-id))
  )
    ;; Check if sender owns this plant
    (asserts! (is-eq sender (get owner plant)) err-not-owner)

    ;; Check if plant is still alive
    (asserts! (> current-health u0) err-plant-dead)

    ;; Calculate new health with water boost
    (let ((new-health (if (> (+ current-health water-boost) max-health)
                          max-health
                          (+ current-health water-boost))))

      ;; Update plant record
      (map-set plants plant-id (merge plant {
        last-watered: block-height,
        health: new-health,
        total-waters: (+ (get total-waters plant) u1)
      }))

      (ok {health: new-health, stage: (get-growth-stage new-health)})
    )
  )
)

(define-public (transfer-plant (plant-id uint) (recipient principal))
  (let (
    (plant (unwrap! (map-get? plants plant-id) err-no-plant))
    (sender tx-sender)
  )
    ;; Check if sender owns this plant
    (asserts! (is-eq sender (get owner plant)) err-not-owner)

    ;; Check if recipient doesn't already have a plant
    (asserts! (is-none (map-get? owner-plants recipient)) err-already-planted)

    ;; Transfer NFT
    (try! (nft-transfer? garden-plant plant-id sender recipient))

    ;; Update plant owner
    (map-set plants plant-id (merge plant {owner: recipient}))

    ;; Update owner mappings
    (map-delete owner-plants sender)
    (map-set owner-plants recipient plant-id)

    (ok true)
  )
)

;; read only functions

(define-read-only (get-plant-info (plant-id uint))
  (let (
    (plant (unwrap! (map-get? plants plant-id) err-no-plant))
    (current-health (calculate-health plant-id))
  )
    (ok {
      owner: (get owner plant),
      planted-at: (get planted-at plant),
      last-watered: (get last-watered plant),
      health: current-health,
      stage: (get-growth-stage current-health),
      total-waters: (get total-waters plant),
      blocks-since-water: (- block-height (get last-watered plant))
    })
  )
)

(define-read-only (get-my-plant)
  (match (map-get? owner-plants tx-sender)
    plant-id (get-plant-info plant-id)
    err-no-plant
  )
)

(define-read-only (get-owner-plant (owner principal))
  (match (map-get? owner-plants owner)
    plant-id (get-plant-info plant-id)
    err-no-plant
  )
)

(define-read-only (get-plant-owner (plant-id uint))
  (ok (nft-get-owner? garden-plant plant-id))
)

(define-read-only (get-total-plants)
  (ok (- (var-get next-plant-id) u1))
)
