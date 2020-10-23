const ethers = require('ethers');
const { ffmnemonic, projectId, mnemonicPhrase } = require('../secrets.json');
const erc20Abi = require('./ABI/erc20.abi.json');
const aaveAddress = '0x507f9d08b634783b808d7c70e8de3146d69ac8d7';
const stakerAddress = '0xc54Ba86eA320B92761aA5A31A3ED759B958947cB';

async function main() {
    const provider = new ethers.providers.InfuraProvider("kovan", projectId);
    const signer = new ethers.Wallet.fromMnemonic(mnemonicPhrase);
    const account = signer.connect(provider);

    const aave = new ethers.Contract(aaveAddress, erc20Abi, account);
    //const amountToApprove = Number(1e18).toString();
    await aave.approve(stakerAddress, 1e18.toString());
    const allowed = await aave.allowance(account.address, stakerAddress);

    console.log(ethers.utils.formatEther(allowed));

}

main();