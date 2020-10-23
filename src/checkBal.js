const ethers = require('ethers');
const { mnemonicPhrase, projectId } = require('../secrets.json');
const erc20Abi = require('./ABI/erc20.abi.json');
const aaveAddress = '0x507f9d08b634783b808d7c70e8de3146d69ac8d7';

async function main() {
    const provider = new ethers.providers.InfuraProvider("kovan", projectId);
    const signer = new ethers.Wallet.fromMnemonic(mnemonicPhrase);
    const account = signer.connect(provider);
    const value = await provider.getBalance(account.address);
    const ffValue = await provider.getBalance('0x18d9bA2baEfBdE0FF137C4ad031427EF205f1Fd9');
    console.log("Eth value of old acc:", ethers.utils.formatEther(value));
    console.log("Eth value of FF account:", ethers.utils.formatEther(ffValue));
    console.log("Address of old acc:", account.address);
    
    const aave = new ethers.Contract(aaveAddress, erc20Abi, account);

    const aaveBal = await aave.balanceOf(account.address);

    console.log("AAVE balance on old acc:", ethers.utils.formatEther(aaveBal));
}

main();