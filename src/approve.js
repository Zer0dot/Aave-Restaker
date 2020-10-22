const ethers = require('ethers');
const { ffmnemonic, projectId } = require('../secrets.json');
const erc20Abi = require('./ABI/erc20.abi.json');
const aaveAddress = '0x507f9d08b634783b808d7c70e8de3146d69ac8d7';
const stakerAddress = '0xBb61641E7a54678F5bc1708996F03552f6b88D36';

async function main() {
    const provider = new ethers.providers.InfuraProvider("kovan", projectId);
    const signer = new ethers.Wallet.fromMnemonic(ffmnemonic);
    const account = signer.connect(provider);

    const aave = new ethers.Contract(aaveAddress, erc20Abi, account);
    //const amountToApprove = Number(1e18).toString();
    const tx = await aave.approve(stakerAddress, 1e18.toString());
    const allowed = await aave.allowance(account.address, stakerAddress);

    console.log(allowed.toString());
    //console.log(1e18);
}

main();