// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import "./interfaces/ICakePool.sol";
import "./interfaces/IMembers.sol";
import "./interfaces/IPancakeSwapRouter.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IWBNB.sol";
import "./interfaces/IVoom.sol";

contract VoomCakeUser  {

    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    address public owner;
    address public dev;
    IVoom public voomMaster;
    address chef;
    
    ICakePool public Pool = ICakePool(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
    IBEP20 public lp = IBEP20(0xA527a61703D82139F8a06Bc30097cC9CAA2df5A6);
    ICakePool public lpCake = ICakePool(0xA527a61703D82139F8a06Bc30097cC9CAA2df5A6);
    IBEP20 public wbnb = IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IWBNB public wbnbGlobal = IWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IBEP20 public usdt = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    IBEP20 public fuel = IBEP20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    address public pancakeSwapRouter = address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    address public pancakeSwapFactory = address(0xBCfCcbde45cE874adCB698cC183deBcF17952812);
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    IMembers public member;
    uint256 public pid = 1;
    uint256 public voom_id;
    uint256 public amountUser;
    uint256 public amountPromise;
    uint256 public amountGain;
    uint256 public amountGainNetwork;
    uint256 public tokensLP;
    bool public finish;
    uint256[7] public refPercent = [20, 5, 10, 12, 15, 18, 20];
    bool initialized;

    constructor(address _owner, IMembers _member, address _dev, address _chef, address _voomMaster, uint256 _voom_id) public {
        owner = _owner;
        member = _member;
        dev = _dev;
        chef = _chef;
        voomMaster = IVoom(_voomMaster);
        voom_id = _voom_id;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    receive () external payable {}

    function _RemoveLP() internal {
        uint256 _amount = lp.balanceOf(address(this));
        if(_amount > 0){
            lp.safeApprove(pancakeSwapRouter, 0);
            lp.safeApprove(pancakeSwapRouter, _amount);            
            IPancakeSwapRouter(pancakeSwapRouter).removeLiquidityETHSupportingFeeOnTransferTokens(
                address(fuel),
                _amount,
                uint256(0),
                uint256(0),
                address(this),
                now.add(1800)
            );
        }
    }

    function _BNBxWBNB() internal {
        if(address(this).balance > 0){
            wbnbGlobal.deposit{value: address(this).balance}();
        }
    }

    function _FUELxUSDT() internal {
        uint256 _amount = fuel.balanceOf(address(this));
        if(_amount > 0){
            fuel.safeApprove(pancakeSwapRouter, 0);
            fuel.safeApprove(pancakeSwapRouter, _amount);
            address[] memory path = new address[](3);
            path[0] = address(fuel);
            path[1] = address(wbnb);
            path[2] = address(usdt);
            IPancakeSwapRouter(pancakeSwapRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, uint256(0), path, address(this), now.add(1800));
        }
    }

    function _WBNBxUSDT() internal {
        uint256 _amount = wbnb.balanceOf(address(this));
        if(_amount > 0){
            wbnb.safeApprove(pancakeSwapRouter, 0);
            wbnb.safeApprove(pancakeSwapRouter, _amount);
            address[] memory path = new address[](2);
            path[0] = address(wbnb);
            path[1] = address(usdt);
            IPancakeSwapRouter(pancakeSwapRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, uint256(0), path, address(this), now.add(1800));
        }
    }    

    function _USDTxWBNB(uint256 _amount) internal {
        if(_amount > 0){
            usdt.safeApprove(pancakeSwapRouter, 0);
            usdt.safeApprove(pancakeSwapRouter, _amount);
            address[] memory path = new address[](2);
            path[0] = address(usdt);
            path[1] = address(wbnb);
            IPancakeSwapRouter(pancakeSwapRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, uint256(0), path, address(this), now.add(1800));
        }
    }

    function _WBNBxFuel() internal {
        uint256 _amount = wbnb.balanceOf(address(this));
        if(_amount > 0){
            wbnb.safeApprove(pancakeSwapRouter, 0);
            wbnb.safeApprove(pancakeSwapRouter, _amount.div(2));
            address[] memory path = new address[](2);
            path[0] = address(wbnb);
            path[1] = address(fuel);
            IPancakeSwapRouter(pancakeSwapRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount.div(2), uint256(0), path, address(this), now.add(1800));
        }
    }

    function _addLiquidity() internal {
        uint256 _wbnb = wbnb.balanceOf(address(this));
        uint256 _fuel = fuel.balanceOf(address(this));
        uint256 _usdt = usdt.balanceOf(address(this));
        wbnb.safeApprove(address(uniswapRouter), _wbnb);
        fuel.safeApprove(address(uniswapRouter), _fuel);
        uint256 _wbnb_min = _wbnb.sub(_wbnb.mul(3).div(100));
        uint256 _fuel_min = _fuel.sub(_fuel.mul(3).div(100));
        IPancakeSwapRouter(pancakeSwapRouter).addLiquidity(
            address(wbnb),
            address(fuel),
            _wbnb,
            _fuel,
            _wbnb_min,
            _fuel_min,
            address(this),
            now.add(1800)
        );
        _wbnb = wbnb.balanceOf(address(this));
        _fuel = fuel.balanceOf(address(this));
        if(_wbnb > 0){
            wbnb.safeTransfer(address(dev), _wbnb);
        }
        if(_fuel > 0){
            fuel.safeTransfer(address(dev), _fuel);
        }
        if(_usdt > 0){
            usdt.safeTransfer(address(dev), _usdt);
        }
        tokensLP = lp.balanceOf(address(this));
    }

    function _deposit(uint256 _amount) internal {
        lp.safeApprove(address(Pool), _amount);
        Pool.deposit(pid, _amount);
    }

    function deposit(uint256 _amount) onlyOwner external {
        require(initialized == false, "!initialized");
        usdt.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 _amountSponsor = _amount.mul(20).div(100);
        uint256 _amountUser = _amount.sub(_amountSponsor);
        amountUser = _amountUser;
        amountPromise = _amount.mul(200).div(100);
        address[] memory refTree = member.getParentTree(msg.sender, 1);
        usdt.safeTransfer(address(refTree[0]), _amountSponsor);
        _USDTxWBNB(amountUser);
        _WBNBxFuel();
        _addLiquidity();
        _deposit(tokensLP);
        initialized = true;
        voomMaster.deposit(_amountUser, amountPromise, _amountSponsor, tokensLP, voom_id, owner);
    }

    function pending() external view returns (uint256) {
        return Pool.pendingCake(pid, address(this));
    }

    function claim() onlyOwner external {
        require(amountPromise > amountGain, "finish");
        require(finish == false, "finish");
        Pool.deposit(pid, 0);
        _FUELxUSDT();
        uint256 _usdt = usdt.balanceOf(address(this));
        uint256 _usdtNerwork = _usdt.mul(20).div(100);
        uint256 _usdtUser = _usdt.mul(50).div(100);
        address[] memory refTree = member.getParentTree(msg.sender, 7);
        for (uint256 i = 0; i < 7; i++) {
            if (refTree[i] != address(0) && _usdtNerwork > 0) {
                uint256 refAmount = _usdtNerwork.mul(refPercent[i]).div(100);
                usdt.safeTransfer(address(refTree[i]), refAmount);
            } else {
                break;
            }
        }
        usdt.safeTransfer(msg.sender, _usdtUser);
        usdt.safeTransfer(dev, usdt.balanceOf(address(this)));
        amountGain = amountGain.add(_usdtUser);
        amountGainNetwork = amountGainNetwork.add(_usdtNerwork);
        if(amountGain >= amountPromise){
            Pool.withdraw(pid, tokensLP);
            Pool.emergencyWithdraw(pid);
            lp.safeTransfer(chef, lp.balanceOf(address(this)));
            finish = true;
        }
        voomMaster.claim(_usdtUser, _usdtNerwork, finish, voom_id, owner);
    }

    function emergencyWithdraw() onlyOwner external {
        require(finish == false, "finish");
        Pool.deposit(pid, 0);
        Pool.emergencyWithdraw(pid);
        uint256 _usdt = usdt.balanceOf(address(this));
        uint256 _wbnb = wbnb.balanceOf(address(this));
        uint256 _fuel = fuel.balanceOf(address(this));
        uint256 _lp = lp.balanceOf(address(this));
        if(_lp > 0){
            lp.safeTransfer(address(owner), _lp);
        }
        if(_wbnb > 0){
            wbnb.safeTransfer(address(chef), _wbnb);
        }
        if(_fuel > 0){
            fuel.safeTransfer(address(chef), _fuel);
        }
        if(_usdt > 0){
            usdt.safeTransfer(address(chef), _usdt);
        }
        finish = true;
        voomMaster.withdraw(voom_id, owner);
    }

    function withdraw() onlyOwner external {
        require(amountPromise > amountGain, "finish");
        require(finish == false, "finish");
        Pool.deposit(pid, 0);
        Pool.emergencyWithdraw(pid);
        _RemoveLP();
        _BNBxWBNB();
        _FUELxUSDT();
        _WBNBxUSDT();
        uint256 _usdt = usdt.balanceOf(address(this));
        uint256 remaining = amountPromise.sub(amountGain);
        if(remaining >= _usdt){
            remaining = _usdt;
        } else {
            if(_usdt >= remaining){
                remaining = remaining;
            } else {
                remaining = _usdt;
            }
        }
        usdt.safeTransfer(msg.sender, remaining);
        _usdt = usdt.balanceOf(address(this));
        uint256 _wbnb = wbnb.balanceOf(address(this));
        uint256 _fuel = fuel.balanceOf(address(this));
        uint256 _lp = lp.balanceOf(address(this));
        if(_wbnb > 0){
            wbnb.safeTransfer(address(chef), _wbnb);
        }
        if(_fuel > 0){
            fuel.safeTransfer(address(chef), _fuel);
        }
        if(_usdt > 0){
            usdt.safeTransfer(address(chef), _usdt);
        }
        if(_lp > 0){
            lp.safeTransfer(address(chef), _lp);
        }
        finish = true;
        voomMaster.withdraw(voom_id, owner);
    }

    function balanceFUEL() public view returns(uint256){
        return fuel.balanceOf(address(this));
    }

    function balanceWBNB() public view returns(uint256){
        return wbnb.balanceOf(address(this));
    }

    function balanceUSDT() public view returns(uint256){
        return usdt.balanceOf(address(this));
    }

    function balanceLP() public view returns(uint256){
        return lp.balanceOf(address(this));
    }

    function balanceBNB() public view returns(uint256){
        return address(this).balance;
    }
    
    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

}