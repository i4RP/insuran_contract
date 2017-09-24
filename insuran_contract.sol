pragma solidity ^0.4.11;

contract Base {
  address contractOwner;

  function Base() {
    contractOwner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != contractOwner) revert(); _;
  }

  // コントラクトのデプロイしたオーナーかどうかを検査する．
  function verifyContractOwner() returns(bool){
    if (msg.sender == contractOwner) {
      return true;
    } else {
      return false;
    }
  }
}

contract Verify is Base {
  address[] public subscribeAddress;
  UserWallet public userWalletContract;

  function subscribe(address _userAddress) onlyOwner(){
    subscribeAddress.push(_userAddress);
  }

  function execTransfer(address _to, uint256 _amount) onlyOwner() returns(bool) {
    execUserWalletTransfer(_to, _amount);
    return true;
  }

  function execUserWalletTransfer(address _to, uint256 _amount) onlyOwner() returns(bool) {
    userWalletContract.transfer(_to, _amount);
    return true;
  }

  function setUserWalletContract(address _userWalletAddr) onlyOwner() returns(bool) {
    userWalletContract = UserWallet(_userWalletAddr);
  }
}

contract UserWallet is Base {
  Verify public verifyContract;
  uint256 public applicantNum;
  mapping (address => User[]) public applicants;
  mapping (address => uint) public balanceOf;

  event Sent(address from, address to, uint amount );

  struct User {
    address userWalletAddress;
    bool apply;
  }

  function() payable {
    uint value = msg.value;
    uint charge = value / 100 * 5;

    contractOwner.transfer(charge);
    balanceOf[msg.sender] += (value - charge);
  }

  // 補償情報をセットする．
  function setApplicant(address _userAddress, address _contractAddress) onlyOwner() returns (bool) {
    var applicant = true;
    for(uint256 index = 0; index < applicants[_contractAddress].length; index++) {
      if (applicants[_contractAddress][index].userWalletAddress == _userAddress) {
        applicant = false;
      }
    }
    if (applicant == true) {
      applicants[_contractAddress].push(User({userWalletAddress: _userAddress, apply: true}));
      applicantNum += 1;
      return true;
    } else {
      return false;
    }
  }

  function unsubscribeFromInsurance(address _userAddress, address _contractAddress) onlyOwner() returns (bool) {
    uint256 deleteIndex;
    bool flag = false;
    for(uint256 index = 0; index < applicants[_contractAddress].length; index++) {
      if (applicants[_contractAddress][index].userWalletAddress == _userAddress) {
        deleteIndex = index;
        flag = true;
      }
    }
    if (flag == true) {
      delete applicants[_contractAddress][deleteIndex];
      applicantNum -= 1;
    }

    return true;
  }

  function setVerifyContract(address _contractAddr) onlyOwner() {
    verifyContract =  Verify(_contractAddr);
  }

  // 検証結果を受け取るコントラクトに加入申請を出す．
  function callSubscribe(address _userAddress) onlyOwner() {
    verifyContract.subscribe(_userAddress);
  }

  function transfer(address _userAddress, uint _amount) onlyOwner() {
    address _contractAddress = msg.sender;
    uint divideAmount = _amount / (applicants[_contractAddress].length - 1);
    for(uint index = 0; index < applicants[_contractAddress].length; index++) {
      address walletAddress = applicants[_contractAddress][index].userWalletAddress;
      if ((walletAddress != _userAddress) && balanceOf[walletAddress] >= divideAmount ) {
        balanceOf[walletAddress] -= divideAmount;
        balanceOf[_userAddress] += divideAmount;
      }
    }
  }
}
