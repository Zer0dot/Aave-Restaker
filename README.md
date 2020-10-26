# Aave Restaker
 Automatic Aave Safety Module Restaker

 Issues ERC-20 compliant shares.
 
## This is just a practice project! Use at your own risk.
##### State-Modifying Functions
After approving the contract for the user's AAVE, call deposit(amount) with the AAVE amount to deposit.
This will stake and mint shares for the user.

Call withdrawShares(shareCount) to burn shares and get stkAAVE back. (Not AAVE.)

Call claimAndStake() to withdraw rewards and 

##### View/Pure Non-State Modifying Functions
Call checkRewards() to get the pool's pending rewards

Call stkAaveBalanceOf(query) to get the queried address' pooled stkAAVE balance.
