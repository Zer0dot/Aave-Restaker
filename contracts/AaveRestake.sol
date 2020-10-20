//SPDX-License-Identifier: MIT

   /* 
    ---PLAN---
    1. Map the addresses to their share of the pool.
    2. Every time someone adds AAVE to the pool, mint their share.
    3. Every time someone unstakes and withdraws AAVE from the pool, burn their share.
    4. Keep the shares constant, growing in value with stkAAVE rewards (do not make restaking aave mint new shares)
    
    ---VARIABLES---
    1. Mapping address to shares
    2. totalstkAAVE = Pool's entire staked aave amount
    3. rewardsToClaim = Pool's accumulated AAVE rewards
    4. totalShares = Pool's total amount of shares
        New ones are minted when AAVE is deposited
        Existing ones are burned when AAVE is withdrawn
    
    ---FUNCTIONS---
    1. Deposit AAVE into the pool --public
        a. Make sure AAVE is approved
        b. Check total pool stkAAVE balance (store temporarily)
        c. Mint new shares equal to: (depositAmount/totalstkAAVE) * totalShares
            This calculates the new share of the pool after the AAVE is deposited, then mints the appropriate shares.
            For instance:
                totalShares = 9
                totalstkAAVE = 90
                depositAmount = 10
                depositAmount/(totalstkAAVE+depositAmount) = 10/(90) = 0.1111
                (depositAmount/(totalstkAAVE+depositAmount)) * totalShares = 0.1111 * 9 = 1
                totalShares = 9 + 1 = 10
                totalstkAave = 100
                    Note: This just happens to map perfectly, if there was 6251 stkAave and 10 shares, this logic still works.
            This should also update every appropriate value
        d. Stake the new AAVE

    2. Withdraw shares --public
        a. Start unstaking cooldown
        b. Unstake when possible
        c. Return AAVE in accordance to mapped pool share
        d. Burn mapped pool share
            Should update state 

    3. Restake AAVE rewards into SM --public
        a. Withdraw AAVE rewards
        b. Approve AAVE
        b. Stake AAVE 

    */
pragma solidity 0.6.12;

import "./interfaces/IStakedAave.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";

contract AaveRestake is Initializable {
    using SafeERC20 for IERC20;

    address private stkAaveAddress;             //stkAAVE address
    IStakedAave stkAave;                        //stkAAVE interface
    address private aaveAddress;                //AAVE address
    IERC20 aave;                                //AAVE interface
    uint256 totalStkAave;                       //Total pool stkAAVE
    uint256 rewardsToClaim;                     //Total pool rewards to claim
    mapping(address => uint256) public shares;  //Mapping addresses to pool shares
    uint256 totalShares;                        //Total pool shares (KEEP TRACK MANUALLY
    
    //Initialize variables (CURRENTLY KOVAN)
    function initialize() public initializer {
        stkAaveAddress = address(0x3AF6Ff96Ba32E62d46459F899Af6Fc80218C0336);   //Kovan
        stkAave = IStakedAave(stkAaveAddress);

        aaveAddress = address(0x507F9D08B634783b808d7C70E8dE3146D69Ac8d7);      //Kovan
        aave = IERC20(aaveAddress);
    }



    
}