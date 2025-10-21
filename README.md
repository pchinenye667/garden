🌱 Blockchain Garden

Overview

Blockchain Garden is an interactive NFT-based plant growth simulation built on the Stacks blockchain.
Each wallet can own and grow a unique digital plant NFT, which evolves over time based on player interaction and care.
Your plant flourishes when watered regularly and withers when neglected — representing a living NFT that responds to blockchain activity.

🌼 Core Concept

Each wallet can own one plant NFT.

The plant has attributes like:

Health — dynamic value affected by watering and neglect.

Growth stage — visualized as stages: seedling → sprout → growing → flourishing.

Last watered — determines decay or growth over time.

Total waters — tracks player engagement.

Plants grow when watered and wither if ignored too long.

🧩 Features
Function	Description
plant-seed	Mints a new plant NFT for the sender if they don’t already have one.
water-plant	Waters the plant to restore or increase its health.
transfer-plant	Transfers ownership of a plant to another wallet (recipient must not already own one).
get-plant-info	Returns detailed information about any plant (owner, health, stage, watering stats, etc.).
get-my-plant	Returns information about the caller’s plant.
get-owner-plant	Fetches a plant by its owner’s address.
get-plant-owner	Returns the owner of a specific plant NFT.
get-total-plants	Returns total number of plants created.
🌿 Growth and Decay Logic

Growth Rate: Every ~144 blocks (~1 day), health may increase if watered regularly.

Decay Rate: After ~288 blocks (~2 days) without watering, plants begin to lose health.

Water Boost: Watering adds +10 health points.

Wither Penalty: Neglect causes a loss of -5 health points per decay period.

Health Range: 0–100

0 → Dead

1–20 → Withered

21–40 → Seedling

41–60 → Sprout

61–80 → Growing

81–100 → Flourishing

💧 Data Model

Non-fungible token: garden-plant

Maps:

plants: stores plant metadata (owner, health, timestamps, watering stats)

owner-plants: links owners to their plant IDs

Variable: next-plant-id — increments with each new plant

🔒 Error Codes
Code	Error	Description
u100	err-owner-only	Action restricted to contract owner
u101	err-already-planted	User already owns a plant
u102	err-no-plant	No plant found with given ID
u103	err-plant-dead	Plant has no remaining health
u104	err-not-owner	Sender is not the plant owner
🧠 Example Flow

User A calls plant-seed → receives plant #1.

After 1 day, A calls water-plant → plant health increases.

After 2+ days of neglect, health starts to decline.

When the plant reaches 0 health → it’s permanently dead.

A can transfer the plant to another user using transfer-plant.

🧪 Testing Scenarios

✅ Successfully mint and water a plant

✅ Prevent double planting by same wallet

✅ Ensure decay over time without watering

✅ Reject watering by non-owner

✅ Verify NFT ownership updates correctly on transfer

✅ Fetch plant details and total supply

⚙️ Deployment

Deploy to the Stacks testnet using Clarinet
:

clarinet deploy


Run tests:

clarinet test

📜 License

MIT License — feel free to build upon and extend the garden mechanics.