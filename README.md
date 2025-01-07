# Treasure Hunters Smart Contract Documentation

This document provides an overview of the key methods of the **Treasure Hunters** smart contract that can be interacted with. The goal is to make the information accessible to non-technical users, such as designers or project managers.

---

## Methods You Can Interact With

### 1. **Add Initial Balance**

- **Description**: Allows the contract owner to add funds to the contract.
- **Usage**: Only the owner of the contract can perform this action.

### 2. **Withdraw Funds**

- **Description**: Enables the contract owner to withdraw funds that are available and not reserved.
- **Usage**:
  - Triggered by the owner.
  - Ensures only funds that are not reserved for claims or bonuses can be withdrawn.

### 3. **Claim Rewards**

- **Description**: Allows a player who has won an expedition to claim their treasure.
- **Conditions**:
  - Only winners can call this method.
  - The amount won is sent to the winner’s address.

### 4. **Buy a Ticket**

- **Description**: Players can buy tickets to participate in an expedition.
- **Conditions**:
  - The player must send enough funds to cover the ticket price.
  - Optionally, a referrer’s address can be provided to earn a bonus.

### 5. **Request Referral Bonus**

- **Description**: Referrers can claim their accumulated referral bonuses.
- **Conditions**:
  - Referrer must have an existing bonus balance.

### 6. **Expedition History**

- **Description**: Retrieves the list of past expeditions and their results.
- **Output**: A history of expeditions, including winners and their rewards.

### 7. **Check Contract Balance**

- **Description**: Returns the current balance of the contract.
- **Output**: Total funds in the contract.

### 8. **Available Funds for Withdrawal**

- **Description**: Shows the amount of funds that the owner can withdraw.
- **Output**: Amount available for withdrawal.

### 9. **Check Claimable Rewards**

- **Description**: Allows a player to check if they have any claimable rewards.
- **Input**: Player’s wallet address.
- **Output**: The amount of rewards, if available.

### 10. **Check Referral Bonus**

- **Description**: Referrers can check their bonus balance.
- **Input**: Referrer’s wallet address.
- **Output**: Bonus amount available for claiming.

---

## Key Concepts

- **Expeditions**: Adventures where players can win treasures by participating. Players must purchase tickets to join an expedition.
- **Referral Bonus**: A percentage of the ticket price rewarded to a referrer when a referred player buys a ticket.
- **Owner**: The person or entity that deployed the contract. Has special permissions like withdrawing funds and adding initial balances.

---

## FAQs

### Who can claim rewards?

Only winners of expeditions can claim their rewards.

### How do I earn a referral bonus?

Provide your wallet address as a referrer when someone buys a ticket. You’ll earn a percentage of their ticket price as a bonus.

### What happens if I don’t claim my reward?

Rewards remain in the contract until claimed by the winner.

---

This document covers the external methods available in the **Treasure Hunters** contract. If you have any questions, feel free to reach out to the technical team for further clarification.
