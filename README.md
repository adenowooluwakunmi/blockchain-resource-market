# Clarinet Clarity 2.0 Smart Contract

This smart contract allows users to list, acquire, and manage resources in a decentralized platform with a robust fee and reimbursement structure. The contract is designed to facilitate efficient resource exchange while ensuring platform transparency, security, and user control.

## Features

- **Resource Listing**: Users can list available resources with a specified price.
- **Resource Acquisition**: Users can acquire resources from other users by paying for them with STX and incurring platform fees.
- **Reimbursement**: Users can request reimbursement for their resources under certain conditions.
- **Admin Control**: The contract admin has control over resource price, fee rates, and reserve limits.
- **Fee Management**: Platform fees are calculated as a percentage of the transaction cost.
- **Resource Balance Management**: Resource balance is tracked for each user, and transactions are adjusted accordingly.
- **Limitations**: Limits are set for total system resource balance and individual user allocations.

## Contract Constants

- **Admin**: The contract admin is the only entity with permission to change resource prices, platform fees, reimbursement rates, and resource reserve limits.
- **Error Codes**:
  - `err-admin-only`: Admin-only access error.
  - `err-insufficient-balance`: User balance insufficient error.
  - `err-transfer-issue`: Issue with transferring resources or funds.
  - `err-price-invalid`: Invalid resource price error.
  - `err-quantity-invalid`: Invalid resource quantity error.
  - `err-fee-invalid`: Invalid platform fee error.
  - `err-refund-issue`: Issue with processing reimbursements.
  - `err-same-user-transaction`: Error when a user tries to acquire resources from themselves.
  - `err-exceeds-reserve-limit`: Exceeds the system's resource reserve limit.
  - `err-invalid-reserve`: Invalid reserve error.

## Contract Data Variables

- **resource-price**: The price per resource unit.
- **max-resource-per-user**: The maximum number of resources a user can own.
- **platform-fee-rate**: Platform fee rate as a percentage.
- **reimbursement-rate**: The rate at which users can be reimbursed for resources.
- **total-resource-limit**: The system-wide limit on resources.
- **current-resource-balance**: The current available resources in the system.

## Contract Functions

### Public Functions
- **set-resource-price**: Only the admin can set the price for resources.
- **set-platform-fee**: Only the admin can set the platform fee rate.
- **set-reimbursement-rate**: Only the admin can set the reimbursement rate.
- **set-resource-reserve-limit**: Only the admin can set the system's resource limit.
- **list-resources**: Users can list their resources with a price and quantity.
- **remove-resources**: Users can remove resources from the listing.
- **acquire-resources**: Users can acquire resources from other users, paying the resource cost plus platform fees.
- **request-reimbursement**: Users can request reimbursement for their resources.

### Read-Only Functions
- **fetch-resource-price**: Fetches the current price per resource unit.
- **fetch-platform-fee**: Fetches the current platform fee rate.
- **fetch-reimbursement-rate**: Fetches the current reimbursement rate.
- **fetch-user-resource-balance**: Fetches the resource balance of a specified user.
- **fetch-user-stx-balance**: Fetches the STX balance of a specified user.

## Usage

### 1. Admin Functions:
Admins can configure the system parameters, including:
- Resource Price
- Platform Fee
- Reimbursement Rate
- Resource Reserve Limits

### 2. User Functions:
Users can:
- List their available resources.
- Remove resources from the listing.
- Acquire resources from other users by paying with STX.
- Request reimbursement for unused resources.

### 3. Transaction Process:
When a user acquires resources, the transaction includes:
- Payment of the resource cost.
- Platform fee deducted.
- Transfer of STX to both the resource provider and the platform admin.

### 4. Reimbursement Process:
Users can request reimbursement for resources they have previously listed and not used, following the system's rules for balance management.

## Installation and Setup

To deploy this contract on the Clarity blockchain, use the following commands:

1. Deploy the contract using your preferred Clarity interface (e.g., [Clarinet](https://clarinet.xyz/)).
2. Interact with the contract by calling the various functions based on your needs (e.g., setting the resource price, listing resources, acquiring resources).

## Security Considerations

- **Admin-only Access**: Only the contract admin can modify key settings such as resource price, fees, and resource limits.
- **Transaction Validation**: The contract ensures that users have sufficient balances before proceeding with transactions.
- **Resource Limits**: The contract enforces system-wide and user-specific resource limits to prevent abuse.

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Please fork this repository, submit an issue or pull request, and ensure that your changes are well-tested.
