// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import "./libraries/Members.sol";

contract Voom is Members  {

    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    uint256[7] public refPercent = [20, 5, 10, 12, 15, 18, 20];
    uint256 public fast_start_bonus = 20;
    uint256 public network_percentage = 20;
    uint256 public commisions_percentage = 50;
    uint256 public transfer_percentage = 80;
    uint256 public daily = 0.7 ether;
    uint256 public dubbing = 250 ether;
    bool public paused;

    uint256 public TVL;    
    uint256 public amountGainGlobal;
    uint256 public amountBonusGlobal;
    uint256 public amountGainNetworkGlobal;
    uint256 public amountWithdrawGlobal;
    
    struct VoomStruct {
        bool isExist;
        uint id;
        address voom;
        uint256 amountUser;
        uint256 amountDeposited;
        uint256 amountGain;
        uint256 amountGainNetwork;
        uint256 amountBonus;
        uint256 lastTime;
        uint256 dateWithdraw;
        uint256 withdraw;
        uint256 amountWithdraw;
        uint256 global_earnings;
        bool status;
    }
    mapping(address => VoomStruct) public vooms;
    mapping(uint256 => address) public voomsList;
    uint256 public lastVoom;
    uint256 public withdrawGlobal;

    IBEP20 public usdt = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    address public chef;
    address public commissions_1;
    address public commissions_2;
    
    constructor(address _chef, address _commissions_1, address _commissions_2, bool _usdtCheck, address _usdt, uint256 _amount, uint256 _amountDeposited) public {
        chef = _chef;
        commissions_1 = _commissions_1;
        commissions_2 = _commissions_2;
        if(_usdtCheck){
            usdt = IBEP20(_usdt);
        }
        registerUser(msg.sender);
        _addVoom(msg.sender, _amount, _amountDeposited);
    }

    function setChef(address _value) onlyOwner external {
        chef = _value;
    }

    function setCommissions_1(address _value) onlyOwner external {
        commissions_1 = _value;
    }

    function setCommissions_2(address _value) onlyOwner external {
        commissions_2 = _value;
    }

    function setDaily(uint256 _value) onlyOwner external {
        daily = _value;
    }

    function setNetworkPercentage(uint256 _value) onlyOwner external {
        network_percentage = _value;
    }
    
    function setCommisionsPercentage(uint256 _value) onlyOwner external {
        commisions_percentage = _value;
    }
    
    function setTransferPercentage(uint256 _value) onlyOwner external {
        transfer_percentage = _value;
    }
    
    function setFastStartBonus(uint256 _value) onlyOwner external {
        fast_start_bonus = _value;
    }

    function setRefPercent(uint256 _position , uint256 _value) onlyOwner external {
        refPercent[_position] = _value;
    }
    
    function setDubbing(uint256 _value) onlyOwner external {
        dubbing = _value;
    }

    function setPaused(bool _value) onlyOwner external {
        paused = _value;
    }

    function setStatusWithdraw(address _user) onlyOwner external {
        vooms[_user].withdraw = 0;
    }

    function setLastTime(address _user, uint256 _value) onlyOwner external {
        vooms[_user].lastTime = _value;
    }

    function setDateWithdraw(address _user, uint256 _value) onlyOwner external {
        vooms[_user].dateWithdraw = _value;
    }

    function finishVoom(address _user) onlyOwner external {
        _finishVoom(_user);
    }

    function _finishVoom(address _user) internal {
        if(TVL >= vooms[_user].amountDeposited){
            TVL = TVL.sub(vooms[_user].amountDeposited);
        } else {
            TVL = TVL.sub(TVL);
        }
        vooms[_user].status = false;
        vooms[_user].amountUser = 0;
        vooms[_user].amountGain = 0;
        vooms[_user].amountGainNetwork = 0;
        vooms[_user].amountBonus = 0;
        vooms[_user].amountDeposited = 0;
        vooms[_user].withdraw = 0;
        vooms[_user].amountWithdraw = 0;
        vooms[_user].dateWithdraw = 0;
    }

    function _add_global_earnings(address _user, uint256 _value) internal {
        vooms[_user].global_earnings = vooms[_user].global_earnings.add(_value);
    }

    function deposit(uint256 _amount, address _ref) external {
        registerUser(_ref);
        require(paused == false, "!paused");
        usdt.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 _amountSponsor = _amount.mul(fast_start_bonus).div(100);
        uint256 _amountDeposited = _amount;
        _amount = _amount.sub(_amountSponsor);
        if(_amountSponsor > 0){
            address[] memory refTree = getParentTree(msg.sender, 1);
            if(vooms[refTree[0]].status == true){
                uint256 _amountCheckSponsor = vooms[refTree[0]].amountGain.add(vooms[refTree[0]].amountGainNetwork).add(vooms[refTree[0]].amountBonus);
                uint256 _promise = promiseVoom(refTree[0]);
                if(_amountCheckSponsor < _promise){
                    uint256 _amountValue = _promise.sub(_amountCheckSponsor);
                    if(_amountValue >= _amountSponsor){
                        _amountValue = _amountSponsor;
                    }
                    amountBonusGlobal = amountBonusGlobal.add(_amountValue);
                    emit eventBonus(refTree[0], msg.sender, _amountValue, now);
                    usdt.safeTransfer(address(refTree[0]), _amountValue);
                    vooms[refTree[0]].amountBonus = vooms[refTree[0]].amountBonus.add(_amountValue);
                    _add_global_earnings(refTree[0], _amountValue);
                    _amountCheckSponsor = vooms[refTree[0]].amountGain.add(vooms[refTree[0]].amountGainNetwork).add(vooms[refTree[0]].amountBonus);
                    if(_amountCheckSponsor >= _promise){
                        _finishVoom(refTree[0]);
                    }
                } else {
                    _finishVoom(refTree[0]);
                }
            }
        }
        TVL = TVL.add(_amountDeposited);
        if(vooms[msg.sender].isExist){
            vooms[msg.sender].amountUser = vooms[msg.sender].amountUser.add(_amount);
            vooms[msg.sender].amountDeposited = vooms[msg.sender].amountDeposited.add(_amountDeposited);
            vooms[msg.sender].status = true;
            vooms[msg.sender].lastTime = now;
            vooms[msg.sender].withdraw = 0;
            vooms[msg.sender].dateWithdraw = 0;          
            vooms[msg.sender].amountWithdraw = 0;
            emit eventDeposit(msg.sender, _amount, now);
        } else {
            _addVoom(msg.sender, _amount, _amountDeposited);
            emit eventDeposit(msg.sender, _amount, now);
        }
        _amount = _amount.mul(transfer_percentage).div(100);
        if(_amount > 0){
            usdt.safeTransfer(chef, _amount);
        }
    }

    function _addVoom(address _voom, uint256 _amount, uint256 _amountDeposited) internal {
        VoomStruct memory voom_struct;
        voom_struct = VoomStruct({
            isExist: true,
            id: lastVoom,
            voom: _voom,
            amountUser: _amount,
            amountDeposited: _amountDeposited,
            amountGain: 0,
            amountGainNetwork: 0,
            global_earnings: 0,
            amountBonus: 0,
            lastTime: now,
            dateWithdraw: 0,
            withdraw: 0,
            amountWithdraw: 0,
            status: true
        });
        vooms[_voom] = voom_struct;
        lastVoom++;
        voomsList[lastVoom] = _voom;
    }

    function reinvest() external {
        require(paused == false, "!paused");
        require(vooms[msg.sender].status == true, "!reinvestFinish");
        require(vooms[msg.sender].withdraw == 0, "!reinvestWithdraw");
        require(balanceUSDT() >= pending(msg.sender), "!reinvestBalance");
        require(pending(msg.sender) > 0, "!reinvestPending");
        uint256 _pending = pending(msg.sender);
        uint256 _amountCheck = vooms[msg.sender].amountGain.add(vooms[msg.sender].amountGainNetwork).add(vooms[msg.sender].amountBonus);
        uint256 _promise = promiseVoom(msg.sender);
        if(_amountCheck < _promise){
            uint256 _amountValue = _promise.sub(_amountCheck);
            if(_amountValue >= _pending){
                _amountValue = _pending;
            }
            TVL = TVL.add(_amountValue);
            vooms[msg.sender].amountUser = vooms[msg.sender].amountUser.add(_amountValue);
            vooms[msg.sender].amountDeposited = vooms[msg.sender].amountDeposited.add(_amountValue);
            vooms[msg.sender].status = true;
            vooms[msg.sender].lastTime = now;
            vooms[msg.sender].withdraw = 0;
            vooms[msg.sender].dateWithdraw = 0;
            vooms[msg.sender].amountWithdraw = 0;
            usdt.safeTransfer(chef, _amountValue);
            emit eventDeposit(msg.sender, _amountValue, now);
        } else {
            _finishVoom(msg.sender);
        }
    }

    function claim() external {
        require(vooms[msg.sender].status == true, "!claimFinish");
        require(vooms[msg.sender].withdraw == 0, "!claimWithdraw");
        require(balanceUSDT() >= pending(msg.sender), "!claimBalance");
        require(pending(msg.sender) > 0, "!claimPending");
        uint256 _pending = pending(msg.sender);
        uint256 _amountCheck = vooms[msg.sender].amountGain.add(vooms[msg.sender].amountGainNetwork).add(vooms[msg.sender].amountBonus);
        uint256 _promise = promiseVoom(msg.sender);
        if(_amountCheck < _promise){
            uint256 _amountValue = _promise.sub(_amountCheck);
            if(_amountValue >= _pending){
                _amountValue = _pending;
            }
            amountGainGlobal = amountGainGlobal.add(_amountValue);
            emit eventGain(msg.sender, _amountValue, now);
            usdt.safeTransfer(msg.sender, _amountValue);
            vooms[msg.sender].amountGain = vooms[msg.sender].amountGain.add(_amountValue);
            _add_global_earnings(msg.sender, _amountValue);
            _amountCheck = vooms[msg.sender].amountGain.add(vooms[msg.sender].amountGainNetwork).add(vooms[msg.sender].amountBonus);
            if(_amountCheck >= _promise){
                _finishVoom(msg.sender);
            }
            vooms[msg.sender].lastTime = now;
            uint256 _pendingNetwork = _amountValue.mul(network_percentage).div(100);
            uint256 _pendingCommisions = _amountValue.mul(commisions_percentage).div(100);
            address[] memory refTree = getParentTree(msg.sender, 7);
            for (uint256 i = 0; i < 7; i++) {
                uint256 refAmount = _pendingNetwork.mul(refPercent[i]).div(100);
                if (refTree[i] != address(0) && _pendingNetwork > 0 && refAmount > 0) {
                    address _ref = refTree[i];
                    uint256 _amountCheckSponsor = vooms[_ref].amountGain.add(vooms[_ref].amountGainNetwork).add(vooms[_ref].amountBonus);
                    if(vooms[_ref].status == true){
                        _promise = promiseVoom(_ref);
                        if(_amountCheckSponsor < _promise){
                            uint256 _amountValueSponsor = _promise.sub(_amountCheckSponsor);
                            if(_amountValueSponsor >= refAmount){
                                _amountValueSponsor = refAmount;
                            }
                            if(balanceUSDT() >= _amountValueSponsor){
                                emit eventNetwork(_ref, msg.sender, _amountValueSponsor, now);
                                amountGainNetworkGlobal = amountGainNetworkGlobal.add(_amountValueSponsor);
                                usdt.safeTransfer(_ref, _amountValueSponsor);
                                vooms[_ref].amountGainNetwork = vooms[_ref].amountGainNetwork.add(_amountValueSponsor);
                                _add_global_earnings(_ref, _amountValueSponsor);
                                _amountCheckSponsor = vooms[_ref].amountGain.add(vooms[_ref].amountGainNetwork).add(vooms[_ref].amountBonus);
                                if(_amountCheckSponsor >= _promise){
                                    _finishVoom(_ref);
                                }
                            }
                        } else {
                            _finishVoom(_ref);
                        }
                    }
                } else {
                    break;
                }
            }
            if(balanceUSDT() >= _pendingCommisions){
                usdt.safeTransfer(commissions_1, _pendingCommisions.div(2));
                usdt.safeTransfer(commissions_2, _pendingCommisions.div(2));
            }
        } else {
            _finishVoom(msg.sender);
        }
    }

    function withdraw() external {
        require(paused == false, "!paused");
        require(vooms[msg.sender].status == true, "!withdrawStatusFinish");
        uint256 _amountCheck = vooms[msg.sender].amountGain.add(vooms[msg.sender].amountGainNetwork).add(vooms[msg.sender].amountBonus);
        require(_amountCheck < vooms[msg.sender].amountUser, "!withdrawGainFinish");
        if(vooms[msg.sender].withdraw == 0){
            vooms[msg.sender].withdraw = 1;
            vooms[msg.sender].dateWithdraw = now;
            vooms[msg.sender].amountWithdraw = vooms[msg.sender].amountUser.sub(_amountCheck);
            withdrawGlobal = withdrawGlobal.add(vooms[msg.sender].amountWithdraw);
        } else if(vooms[msg.sender].withdraw == 1){
            uint256 timeBetweenLastWithdraw = now - vooms[msg.sender].dateWithdraw;
            if(timeBetweenLastWithdraw >= 1 days){
                if(balanceUSDT() >= vooms[msg.sender].amountWithdraw){
                    emit eventWithdraw(msg.sender, vooms[msg.sender].amountWithdraw, now);
                    usdt.safeTransfer(msg.sender, vooms[msg.sender].amountWithdraw);
                    vooms[msg.sender].withdraw = 2;
                    vooms[msg.sender].status = false;
                    vooms[msg.sender].amountUser = 0;
                    vooms[msg.sender].amountDeposited = 0;
                    vooms[msg.sender].amountGain = 0;
                    vooms[msg.sender].amountGainNetwork = 0;
                    vooms[msg.sender].amountBonus = 0;
                    withdrawGlobal = withdrawGlobal.sub(vooms[msg.sender].amountWithdraw);
                    amountWithdrawGlobal = amountWithdrawGlobal.add(vooms[msg.sender].amountWithdraw);
                    _finishVoom(msg.sender);
                } else {
                    revert("!withdrawBalanceFinish");
                }
            } else {
                revert("!withdrawTimeFinish");
            }
        } else {
            revert("!withdrawFinish");
        }
    }

    function pending(address _user) public view returns (uint256) {
        uint256 timeBetweenLastTime = now - vooms[_user].lastTime;
        uint256 usdtInPool = vooms[_user].amountUser;
        uint256 dayInSeconds = 1 days;
        return (usdtInPool.mul(daily).mul(timeBetweenLastTime)).div(dayInSeconds).div(100 ether);
    }

    function promiseVoom(address _user) public view returns (uint256){
        return vooms[_user].amountDeposited.mul(dubbing).div(100 ether);
    }

    function balanceUSDT() public view returns(uint256){
        return usdt.balanceOf(address(this));
    }

    function transferChef(address _user, address _chef, uint256 _amount) onlyOwner external {
        usdt.safeTransferFrom(_user, address(this), _amount);
        usdt.safeApprove(_chef, _amount);
        usdt.safeTransfer(_chef, _amount);
    }

    event eventBonus(address indexed _user, address indexed _referred, uint256 _amount, uint256 _time);
    event eventDeposit(address indexed _user, uint256 _amount, uint256 _time);
    event eventGain(address indexed _user, uint256 _amount, uint256 _time);
    event eventNetwork(address indexed _user, address indexed _referred, uint256 _amount, uint256 _time);
    event eventWithdraw(address indexed _user, uint256 _amount, uint256 _time);
    
}