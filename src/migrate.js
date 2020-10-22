const ethers = require('ethers');
const { ffmnemonic, projectId } = require('../secrets.json');
const migratorAbi = require('./ABI/LendToAaveMigrator.json');
const erc20Abi = require('./ABI/erc20.abi.json');

const migratorAddress = '0x6Fd2fDc2d911d728943feCB24B81543D789660ef';
const lendAddress = '0x690eAcA024935Aaff9B14b9FF9e9C8757a281f3C';
const aaveAddress = '0x507f9d08b634783b808d7c70e8de3146d69ac8d7';

async function migrate() {
    const provider = new ethers.providers.InfuraProvider("kovan", projectId);
    const signer = new ethers.Wallet.fromMnemonic(ffmnemonic);
    const account = signer.connect(provider);
    //const value = await provider.getBalance(signer.address);
    //console.log(value.toString());

    const migrator = new ethers.Contract(migratorAddress, migratorAbi, account);
    const lendToken = new ethers.Contract(lendAddress, erc20Abi, account);
    const aaveToken = new ethers.Contract(aaveAddress, erc20Abi, account);

    const lendBalance = await lendToken.balanceOf(account.address);

    console.log(lendBalance.toString());
    await lendToken.approve(migratorAddress, lendBalance);

    await migrator.migrateFromLEND(lendBalance);

    const aaveBalance = await aaveToken.balanceOf(account.address);
    console.log(aaveBalance.toString());
    //WE DID IT BROH
}

migrate();