pragma solidity 0.6.12;





contract AaveRestaker is Initializable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private stkAaveAddress;             //stkAAVE address
    IStakedToken stkAave;                       //stkAAVE interface
    address private aaveAddress;                //AAVE address
    IERC20 aave;                                //AAVE interface
    uint256 totalStkAave;                       //Total pool stkAAVE
    uint256 poolRewards;                        //Total pool rewards to claim
    mapping(address => uint256) public shares;  //Mapping addresses to pool shares
    uint256 totalShares;                        //Total pool shares (KEEP TRACK MANUALLY
    uint256 maxInt;
    //Initialize variables and approve stkAave
    function initialize() public initializer {
        stkAaveAddress = address(0xf2fbf9A6710AfDa1c4AaB2E922DE9D69E0C97fd2);   //Kovan proxy
        stkAave = IStakedToken(stkAaveAddress);

        aaveAddress = address(0xB597cd8D3217ea6477232F9217fa70837ff667Af);      //Kovan proxy
        aave = IERC20(aaveAddress);

        totalShares = 0;
        totalStkAave = 0;
        poolRewards = 0;
        maxInt = 2 ** 256 - 1;

        aave.safeApprove(address(stkAave), maxInt);
    }

    function updateStkAave() internal {
        totalStkAave = stkAave.balanceOf(address(this));
    }

    //Deposit function (1e18 share begins as 1 AAVE)
    //First, fetch the pool's total staked AAVE
    //Then transfer in the caller's AAVE and stake it
    function deposit(uint256 amount) external {
        updateStkAave();
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
        shares[msg.sender] = sharesToMint;
        totalShares = totalShares.add(shares[msg.sender]); //Something here isn't working. totalShares remains at 0.
        updateStkAave();
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

        updateStkAave();
    }

    //Withdraws a set amount of shares to transfer stkAAVE back to the user
    //First, fetch the user's shares
    //Next, calculate the amount of stkAAVE to transfer to the user
    //Lastly, transfer them back. Can't use safeTransfer, so manually checking success
    function withdrawShares(uint256 shareCount) external {
        updateStkAave(); //Security
        uint256 userShareCount = shares[msg.sender];
        require(userShareCount > 0, "No pool ownership.");
        require(shareCount <= userShareCount, "Cannot withdraw more than what is owned.");
        uint256 stkAaveToWithdraw = shareCount.div(totalShares).mul(totalStkAave);
        bool success = stkAave.transfer(msg.sender, stkAaveToWithdraw);

        if (success) {
            totalShares = totalShares.sub(shareCount);
            shares[msg.sender] = shares[msg.sender].sub(shareCount);
            updateStkAave();
        } else {
            revert("Transfer failed.");
        }
    }

    //Returns the user's stkAAVE balance in the pool
    function stkAaveBalanceOf(address query) external view returns (uint256) {
        uint256 userStkAaveBalance = shares[query].div(totalShares).mul(totalStkAave);
        return userStkAaveBalance;
    }

    //Returns the pool's total shared balance
    function totalShareBalance() external view returns (uint256) {
        return totalShares;
    }

    /*function testAdd(uint256 amount) external pure returns (uint256) {
        //return stkAave.balanceOf(msg.sender);
        uint256 a = 0;
        a = a.add(amount);
        
        return a;
        //return aave.allowance(address(this), address(stkAave));
    }*/

    function getStkAavePoolBalance() external view returns (uint256) {
        return totalStkAave;
    }