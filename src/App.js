import logo from './logo.svg';
import './App.css';
import { Mainnet, useCall, useEtherBalance, useEthers, useContractFunction, Config } from '@usedapp/core'
import { formatEther } from '@ethersproject/units'
import  contractAbi  from './build/GoBlockchain.json';
import { ethers} from "ethers";
import React, { useState } from 'react';



//function mintBatch(
//  owner: string | Falsy,
//  ids: string | Falsy,
//  amount: string | Falsy
//
//){
//  const {value, error} = 
//  useCall(
//    owner && ids && amount &&
//    {
//      contract: new Contract( contractInterface.abi, contractAddress),
//      method: "mintBatch",
//      args:[owner, ids, amount],
//    }
//  ) ?? {};
//  if(error) {
//    console.error(error.message)
//    return undefined
//  } 
//  return value?.[0]
//}

const provider = new ethers.providers.Web3Provider(window.ethereum)
const signer = provider.getSigner()

const contractAddress = "0xc7af5eeea580f0064f00ee20d1467b7b50c39e34"

const goContract = new ethers.Contract(contractAddress, contractAbi.abi , provider);


function App (props) {

  //  constructor(props){
  //    super(props);
  //    this.state = {
  //      ids: [],
  //      amounts: [],
  //    };
  //  }

    const [ids, setId] = useState([1])
    const [amounts, setAmount] = useState([1])

    const {activateBrowserWallet, account } = useEthers()
    const etherBalance = useEtherBalance(account)

    const { state, send } = useContractFunction(goContract, 'mintBatch', { transactionName: 'Wrap', signer: signer  }) 

    const mintBatch = (sender, ids, amounts) => {
      send(sender, ids, amounts)
    }

  //  changeHandler = (e) => {
  //    this.setState({ids: e.target.value} );
  //    this.setState({amounts : e.target.value} );
  //  }

    console.log((ids[ids.length-1]))
    console.log(amounts)
    
    return (
      <div className="App">
        <div>
          <header className="App-header">
            <img src={logo} className="App-logo" alt="logo" />
            <p>
              Edit <code>src/App.js</code> and save to reload.
            </p>
            <a
              className="App-link"
              href="https://reactjs.org"
              target="_blank"
              rel="noopener noreferrer"
            >
              Learn React
            </a>
            <button onClick={()=> activateBrowserWallet()}> Connect </button>
            {/* account && ... means if(account){execute this} */}
            {account && <p>Account:{account}</p>}
            {etherBalance && <p>Balance: {formatEther(etherBalance)} ETH </p>}
            {/*I just need to get a way to pass in those parameters into the function in order for the transaction
            to be sent*/}
            <input type="text" onChange={(e)=> setId( arr => [...arr ,e.target.value])} placeholder="ids"></input>
            <input type="text" onChange={(e)=>setAmount(arr => [...arr, e.target.value])} placeholder="amounts"></input>
            <button onClick={()=>mintBatch("0xD1e13F880AF5F65e34E118Ce785d77dA474093fb", JSON.parse(ids[ids.length-1]), JSON.parse(amounts[amounts.length-1]))}>mintBatch</button>
          </header>
        </div>  
      </div>
    );
  
}

export default App;
