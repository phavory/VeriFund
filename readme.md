# Small Business Loan Microfinance Contract

A blockchain-powered microfinance institution providing transparent small business loans to qualified entrepreneurs on the Stacks blockchain.

## Overview

This smart contract facilitates microfinance lending by allowing a loan officer to qualify entrepreneurs, disburse loans through fungible tokens, and manage the lending program. The contract ensures transparency, accountability, and fair distribution of microfinance capital.

## Features

- **Entrepreneur Qualification System**: Loan officers can qualify/disqualify entrepreneurs for loans
- **Automated Loan Disbursement**: Qualified entrepreneurs can claim their allocated loan amounts
- **Transparent Transaction Logging**: All loan activities are recorded on-chain
- **Capital Management**: Undisbursed funds can be withdrawn after the loan term expires
- **Bulk Operations**: Support for qualifying multiple entrepreneurs at once

## Contract Components

### Constants

- `LOAN-OFFICER`: The contract deployer who manages the lending program
- Various error codes for different failure scenarios

### Data Variables

- `is-lending-program-active`: Controls whether loans can be disbursed
- `total-loans-disbursed`: Tracks total amount of loans given out
- `loan-amount-per-entrepreneur`: Standard loan amount (default: 100 tokens)
- `loan-term-duration`: Duration before undisbursed funds can be withdrawn (default: 10,000 blocks)

### Fungible Token

- `microfinance-loan-token`: The token used for loan disbursement (1 billion tokens minted initially)

## Key Functions

### Loan Officer Functions

#### `qualify-entrepreneur(entrepreneur-address)`
- Qualifies an entrepreneur to receive a loan
- Only callable by the loan officer
- Logs the qualification transaction

#### `disqualify-entrepreneur(entrepreneur-address)`
- Removes an entrepreneur's loan qualification
- Only callable by the loan officer

#### `bulk-qualify-entrepreneurs(entrepreneur-addresses)`
- Qualifies up to 200 entrepreneurs in a single transaction
- More efficient for large-scale operations

#### `update-loan-amount(new-amount)`
- Updates the standard loan amount for all future loans
- Must be greater than 0

#### `update-loan-term(new-term)`
- Updates the loan term duration
- Must be greater than 0

### Entrepreneur Functions

#### `claim-business-loan()`
- Allows qualified entrepreneurs to claim their loan
- Transfers tokens from loan officer to entrepreneur
- Can only be claimed once per entrepreneur
- Requires active lending program and sufficient capital

### Administrative Functions

#### `withdraw-undisbursed-capital()`
- Allows loan officer to withdraw undisbursed funds after loan term expires
- Burns the withdrawn tokens to maintain supply integrity

## Read-Only Functions

- `get-lending-program-status()`: Check if lending program is active
- `is-entrepreneur-qualified(address)`: Check if an address is qualified for loans
- `has-entrepreneur-received-loan(address)`: Check if entrepreneur already received loan
- `get-entrepreneur-loan-amount(address)`: Get loan amount received by entrepreneur
- `get-total-loans-disbursed()`: Get total amount disbursed across all loans
- `get-loan-amount-per-entrepreneur()`: Get current standard loan amount
- `get-loan-term-duration()`: Get current loan term duration
- `get-lending-program-launch-block()`: Get block when program was launched
- `get-loan-transaction(id)`: Get details of a specific transaction

## Usage Examples

### For Loan Officers

1. **Qualify an entrepreneur:**
   ```clarity
   (contract-call? .microfinance-contract qualify-entrepreneur 'SP1234...)
   ```

2. **Update loan amount:**
   ```clarity
   (contract-call? .microfinance-contract update-loan-amount u200)
   ```

3. **Bulk qualify entrepreneurs:**
   ```clarity
   (contract-call? .microfinance-contract bulk-qualify-entrepreneurs (list 'SP1234... 'SP5678...))
   ```

### For Entrepreneurs

1. **Claim loan:**
   ```clarity
   (contract-call? .microfinance-contract claim-business-loan)
   ```

2. **Check qualification status:**
   ```clarity
   (contract-call? .microfinance-contract is-entrepreneur-qualified 'SP1234...)
   ```

## Error Codes

- `u100`: Not loan officer
- `u101`: Loan already disbursed to entrepreneur
- `u102`: Entrepreneur not qualified
- `u103`: Insufficient loan capital
- `u104`: Lending program inactive
- `u105`: Invalid loan amount
- `u106`: Repayment period not ended
- `u107`: Invalid entrepreneur
- `u108`: Invalid loan term

## Security Features

1. **Role-based Access Control**: Only the loan officer can manage qualifications and program settings
2. **One Loan Per Entrepreneur**: Prevents double-spending through disbursement tracking
3. **Capital Controls**: Ensures sufficient funds before disbursement
4. **Time-locked Withdrawals**: Prevents premature withdrawal of undisbursed capital
5. **Transaction Logging**: All activities are recorded for transparency and auditing

## Deployment and Initialization

The contract automatically:
- Mints 1 billion microfinance tokens to the loan officer
- Sets the lending program launch block to deployment block
- Activates the lending program
- Initializes default loan parameters

## Best Practices

1. **For Loan Officers:**
   - Carefully vet entrepreneurs before qualification
   - Monitor total disbursements to manage capital
   - Update loan terms based on program performance
   - Use bulk operations for efficiency

2. **For Entrepreneurs:**
   - Ensure qualification before attempting to claim loans
   - Claim loans promptly once qualified
   - Understand that loans can only be claimed once

