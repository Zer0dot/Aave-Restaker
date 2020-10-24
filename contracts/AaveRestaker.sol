//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IStakedToken.sol";
//import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";


contract AaveRestaker is Initializable, ERC20UpgradeSafe {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    address private stkAaveAddress;                      //stkAAVE address
    IStakedToken stkAave;                                //stkAAVE interface
    address private aaveAddress;                         //AAVE address
    IERC20 aave;                                         //AAVE interface
    uint256 totalStkAave;                                //Total pool stkAAVE
    uint256 poolRewards;                                 //Total pool rewards to claim
    //mapping(address => uint256) public shares;           //Mapping addresses to pool shares
    uint256 totalShares;                                 //Total pool shares (KEEP TRACK MANUALLY
    uint256 maxInt;                                      //Value that stores max uint256
    //ERC20PresetMinterPauserUpgradeSafe public pStkAave;  //ERC20 representing shares

    //Initialize variables and approve stkAave
    function initialize() public initializer {
        stkAaveAddress = address(0xf2fbf9A6710AfDa1c4AaB2E922DE9D69E0C97fd2);   //Kovan proxy
        stkAave = IStakedToken(stkAaveAddress);
        aaveAddress = address(0xB597cd8D3217ea6477232F9217fa70837ff667Af);      //Kovan proxy
        aave = IERC20(aaveAddress);
        
        __ERC20_init("Pool-Staked AAVE", "pStkAAVE");

        //pStkAave = new ERC20PresetMinterPauserUpgradeSafe();                    //Creates ERC-20
        //pStkAave.initialize("Pool-Staked AAVE", "pStkAave");

        totalShares = 0;
        totalStkAave = 0;
        poolRewards = 0;
        maxInt = 2 ** 256 - 1;

        aave.safeApprove(address(stkAave), maxInt);
    }

    function updateStkAaveAndShares() internal {
        totalStkAave = stkAave.balanceOf(address(this));
        totalShares = totalSupply();
    }

    //Deposit function (1e18 share begins as 1 AAVE)
    //First, fetch the pool's total staked AAVE
    //Then transfer in the caller's AAVE and stake it
    function deposit(uint256 amount) external {
        updateStkAaveAndShares();
        aave.safeTransferFrom(msg.sender, address(this), amount);
        stkAave.stake(address(this), amount);

        //Initialize the user's shares to mint and calculate the appropriate amount
        uint256 sharesToMint = 0;
        if (totalStkAave > 0 && totalShares > 0) {
            sharesToMint = amount.div(totalStkAave).mul(totalShares);
        } else if (totalStkAave == 0 && totalShares == 0) {
            sharesToMint = amount;
        }
        require(sharesToMint >= 0, "No shares to mint.");

        //Assign shares to depositor and update state variables
        _mint(msg.sender, sharesToMint);
        //shares[msg.sender] = balanceOf(msg.sender);
        updateStkAaveAndShares();
    }

    //Check total pool pending AAVE rewards
    function checkRewards() external view returns (uint256) {
        return stkAave.getTotalRewardsBalance(address(this));
    }

    //Claims and re-invests AAVE rewards, then update the pool's total stkAAVE
    function claimAndStake() external {
        stkAave.claimRewards(address(this), uint(-1));
        uint256 aaveBalance = aave.balanceOf(address(this));

        require(aaveBalance > 0, "Cannot stake 0 tokens.");
        stkAave.stake(address(this), aaveBalance);

        updateStkAaveAndShares();
    }

    //Withdraws a set amount of shares to transfer stkAAVE back to the user
    //First, fetch the user's shares
    //Next, calculate the amount of stkAAVE to transfer to the user
    //Lastly, transfer them back. Can't use safeTransfer, so manually checking success
    function withdrawShares(uint256 shareCount) external {
        updateStkAaveAndShares(); //Security
        uint256 userShareCount = balanceOf(msg.sender);
        require(userShareCount > 0, "No pool ownership.");
        require(shareCount <= userShareCount, "Cannot withdraw more than what is owned.");
        uint256 stkAaveToWithdraw = shareCount.div(totalShares).mul(totalStkAave);
        bool success = stkAave.transfer(msg.sender, stkAaveToWithdraw);

        if (success) {
            //totalShares = totalShares.sub(shareCount);
            _burn(msg.sender, shareCount);
            //shares[msg.sender] = pStkAave.balanceOf(msg.sender);
            updateStkAaveAndShares();
        } else {
            revert("Transfer failed.");
        }
    }

    //Returns the user's stkAAVE balance in the pool
    function stkAaveBalanceOf(address query) external view returns (uint256) {
        uint256 userStkAaveBalance = balanceOf(query).div(totalShares).mul(totalStkAave);
        return userStkAaveBalance;
    }

    //Returns the pool's total shared balance
    function totalShareBalance() external view returns (uint256) {
        return totalShares;
    }

    function getStkAavePoolBalance() external view returns (uint256) {
        return totalStkAave;
    }
}