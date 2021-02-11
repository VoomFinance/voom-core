const Voom = artifacts.require('./Voom.sol')
const TokenX = artifacts.require('./libraries/TokenX.sol')


module.exports = async function (deployer) {

    if (parseInt(process.env.DEPLOY_TEST) === 1) {

        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        const token_x = await TokenX.deployed()

        await token_x.transfer(accounts[1], "50000000000000000000000")
        await token_x.transfer(accounts[2], "50000000000000000000000")
        await token_x.transfer(accounts[3], "50000000000000000000000")
        await token_x.transfer(accounts[4], "50000000000000000000000")
        await token_x.transfer(accounts[5], "50000000000000000000000")
        await token_x.transfer(accounts[6], "50000000000000000000000")
        await token_x.transfer(accounts[7], "50000000000000000000000")
        await token_x.transfer(accounts[8], "50000000000000000000000")
        await token_x.transfer(accounts[9], "50000000000000000000000")

        await token_x.approve(voom.address, "50000000000000000000000", { from: accounts[1] })
        await token_x.approve(voom.address, "50000000000000000000000", { from: accounts[2] })
        await token_x.approve(voom.address, "50000000000000000000000", { from: accounts[3] })
        await token_x.approve(voom.address, "50000000000000000000000", { from: accounts[4] })
        await token_x.approve(voom.address, "50000000000000000000000", { from: accounts[5] })
        await token_x.approve(voom.address, "50000000000000000000000", { from: accounts[6] })
        await token_x.approve(voom.address, "50000000000000000000000", { from: accounts[7] })
        await token_x.approve(voom.address, "50000000000000000000000", { from: accounts[8] })
        await token_x.approve(voom.address, "50000000000000000000000", { from: accounts[9] })

        await voom.deposit("50000000000000000000", accounts[0], { from: accounts[1] })
        await voom.deposit("50000000000000000000", accounts[0], { from: accounts[2] })
        await voom.deposit("50000000000000000000", accounts[0], { from: accounts[3] })
        await voom.deposit("50000000000000000000", accounts[1], { from: accounts[4] })
        await voom.deposit("50000000000000000000", accounts[1], { from: accounts[5] })
        await voom.deposit("50000000000000000000", accounts[5], { from: accounts[6] })
        await voom.deposit("50000000000000000000", accounts[6], { from: accounts[7] })
        await voom.deposit("50000000000000000000", accounts[7], { from: accounts[8] })
        await voom.deposit("50000000000000000000", accounts[7], { from: accounts[9] })

    }

}