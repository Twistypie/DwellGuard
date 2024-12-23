# DwellGuard: Secure Real Estate Escrow Smart Contract

DwellGuard is a robust smart contract system built on the Stacks blockchain that facilitates secure real estate transactions through automated escrow management. It provides a trustless environment for handling property sales, earnest money deposits, and post-sale maintenance funds.

## Features

- **Secure Escrow Management**: Automated handling of earnest money deposits and final payments
- **Property Registration**: Secure recording of property details including location, size, and construction date
- **Inspection Integration**: Built-in support for property inspection results
- **Time-Bound Transactions**: Automatic deadline management for transaction completion
- **Maintenance Fund Support**: Post-sale maintenance fund management capabilities
- **User Verification**: Robust principal verification system for all participants

## Contract Structure

### Core Components

1. **Escrow Management**
   - Setup and initialization of escrow agreements
   - Handling of earnest money deposits
   - Processing of final payments
   - Support for deposit refunds

2. **Property Management**
   - Property registration system
   - Inspection status tracking
   - Construction and size verification

3. **Financial Controls**
   - Safe arithmetic operations
   - Overflow protection
   - Deposit percentage calculations

### Security Features

- Input validation for all user-provided data
- Overflow protection for arithmetic operations
- Principal verification system
- Time-bound transaction enforcement
- Role-based access control

## Usage

### Setup Process

1. **Initialize Escrow**
```clarity
(contract-call? .dwellguard setup-escrow 
    seller-address 
    buyer-address 
    property-price 
    escrow-duration)
```

2. **Register Property**
```clarity
(contract-call? .dwellguard register-home
    property-id
    property-location
    square-footage
    construction-year)
```

3. **Submit Earnest Money**
```clarity
(contract-call? .dwellguard submit-earnest)
```

### Transaction Flow

1. Seller initiates by registering the property
2. Buyer submits earnest money
3. Property inspection is recorded
4. Buyer completes the payment
5. Transaction is finalized

### Error Handling

The contract includes comprehensive error handling with specific error codes:
- `ERR-UNAUTHORIZED`: Unauthorized access attempt
- `ERR-SETUP-EXISTS`: Double initialization attempt
- `ERR-NO-SETUP`: Operations before setup
- `ERR-INVALID-COST`: Invalid price inputs
- And more...

## Constants

- `DURATION-LIMIT`: 365 days
- `BUILD-YEAR-MIN`: 1900
- `BUILD-YEAR-MAX`: 2100
- `DAILY-BLOCKS`: 144 blocks
- `EARNEST-MONEY-PERCENT`: 10%

## Safety Measures

1. **Input Validation**
   - All user inputs are validated before processing
   - Range checks for numerical values
   - Format verification for strings
   - Principal address verification

2. **Arithmetic Safety**
   - Overflow checks for all calculations
   - Safe addition operations
   - Protected block height calculations

3. **State Management**
   - Clear state transitions
   - Protected state variables
   - Verified state checks before operations

## Development

### Prerequisites

- Clarity Contract Development Environment
- Stacks Blockchain Node
- Clarity Testing Framework

### Testing

1. Deploy the contract to a test environment
2. Run the test suite
3. Verify all state transitions
4. Check error conditions

## License

MIT License - see LICENSE file for details

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Best Practices

1. Always verify contract state before operations
2. Handle all error conditions appropriately
3. Test thoroughly before deployment
4. Monitor transaction deadlines
5. Verify all principals involved in transactions

## Technical Notes

- Block time is approximately 10 minutes
- Default escrow period is 365 days maximum
- Earnest money is set to 10% of property price
- All numerical operations include overflow protection
- String inputs are limited to appropriate lengths

## Production Deployment

When deploying to production:
1. Verify all constants are appropriate for mainnet
2. Ensure proper principal permissions
3. Test all error conditions
4. Verify arithmetic safety measures
5. Review state transitions

