import { ethers } from 'ethers';
import { useEffect, useState } from 'react';
import { GoArrowDown } from 'react-icons/go';
import { useAccount, useBalance, useContractRead } from 'wagmi'

const style = {
    wrapper: `flex items-center justify-center mt-14`,
    content: `bg-gray-200 w-[40rem] rounded-2xl p-4 flex flex-col`,
    formHeader: `px-2 flex items-center justify-between font-semibold text-xl`,
    transferPropContainer: `bg-white my-3 rounded-2xl p-6 text-3xl  border border-[#20242A] hover:border-[#41444F]  flex justify-between`,
    transferPropInput: `bg-transparent placeholder:text-[#B2B9D2] outline-none mb-6 w-full text-2xl`,
    currencyBalance: `flex flex-row text-sm justify-center`,
    currencySelector: `flex w-1/4 flex-col`,
    currencySelectorContent: `w-full h-min flex justify-center items-center bg-blue-200 hover:bg-blue-300 rounded-2xl text-xl font-medium cursor-pointer p-2 mt-[-0.2rem]`,
    currencySelectorIcon: `flex items-center`,
    currencySelectorTicker: `mx-2`,
    currencySelectorArrow: `text-lg`,
    confirmButton: `w-full bg-blue-600 text-white my-2 rounded-2xl py-6 px-8 text-xl font-semibold flex items-center justify-center cursor-pointer border border-blue-800 hover:border-blue-800 disabled:opacity-50`,
  }

export default function SwapComponent(props: any) {
    const { address, isConnected, connect } = props;
    const [iplAmount, setIplAmount] = useState(0.0);
    const [bblAmount, setBblAmount] = useState(0.0);
    const [iplBalance, setIplBalance] = useState(0.0);
    const [bblBalance, setBblBalance] = useState(0.0);
    const [hasMounted, setHasMounted] = useState(false);
    const [srcToken, setSrcToken] = useState("IPL");
    const [desTokenExchangeRate, setDesTokenExchangeRate] = useState(0.0);
    const ammAbi = [
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "_token0",
                    "type": "address"
                },
                {
                    "internalType": "address",
                    "name": "_token1",
                    "type": "address"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "constructor"
        },
        {
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "_amount0",
                    "type": "uint256"
                },
                {
                    "internalType": "uint256",
                    "name": "_amount1",
                    "type": "uint256"
                }
            ],
            "name": "addLiquidity",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "shares",
                    "type": "uint256"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "",
                    "type": "address"
                }
            ],
            "name": "balanceOf",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "_shares",
                    "type": "uint256"
                }
            ],
            "name": "removeLiquidity",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "amount0",
                    "type": "uint256"
                },
                {
                    "internalType": "uint256",
                    "name": "amount1",
                    "type": "uint256"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "reserve0",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "reserve1",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "_tokenIn",
                    "type": "address"
                },
                {
                    "internalType": "uint256",
                    "name": "_amountIn",
                    "type": "uint256"
                }
            ],
            "name": "swap",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "amountOut",
                    "type": "uint256"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "_tokenIn",
                    "type": "address"
                },
                {
                    "internalType": "uint256",
                    "name": "_amountIn",
                    "type": "uint256"
                }
            ],
            "name": "swapTokenAmount",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "amountOut",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "token0",
            "outputs": [
                {
                    "internalType": "contract IERC20",
                    "name": "",
                    "type": "address"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "token1",
            "outputs": [
                {
                    "internalType": "contract IERC20",
                    "name": "",
                    "type": "address"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "totalSupply",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        }
    ];
    const ercAbi = [
        {
            "inputs": [],
            "stateMutability": "nonpayable",
            "type": "constructor"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "internalType": "address",
                    "name": "owner",
                    "type": "address"
                },
                {
                    "indexed": true,
                    "internalType": "address",
                    "name": "spender",
                    "type": "address"
                },
                {
                    "indexed": false,
                    "internalType": "uint256",
                    "name": "value",
                    "type": "uint256"
                }
            ],
            "name": "Approval",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "internalType": "address",
                    "name": "previousOwner",
                    "type": "address"
                },
                {
                    "indexed": true,
                    "internalType": "address",
                    "name": "newOwner",
                    "type": "address"
                }
            ],
            "name": "OwnershipTransferred",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": false,
                    "internalType": "address",
                    "name": "account",
                    "type": "address"
                }
            ],
            "name": "Paused",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "internalType": "address",
                    "name": "from",
                    "type": "address"
                },
                {
                    "indexed": true,
                    "internalType": "address",
                    "name": "to",
                    "type": "address"
                },
                {
                    "indexed": false,
                    "internalType": "uint256",
                    "name": "value",
                    "type": "uint256"
                }
            ],
            "name": "Transfer",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": false,
                    "internalType": "address",
                    "name": "account",
                    "type": "address"
                }
            ],
            "name": "Unpaused",
            "type": "event"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "owner",
                    "type": "address"
                },
                {
                    "internalType": "address",
                    "name": "spender",
                    "type": "address"
                }
            ],
            "name": "allowance",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "spender",
                    "type": "address"
                },
                {
                    "internalType": "uint256",
                    "name": "amount",
                    "type": "uint256"
                }
            ],
            "name": "approve",
            "outputs": [
                {
                    "internalType": "bool",
                    "name": "",
                    "type": "bool"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "account",
                    "type": "address"
                }
            ],
            "name": "balanceOf",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "amount",
                    "type": "uint256"
                }
            ],
            "name": "burn",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "account",
                    "type": "address"
                },
                {
                    "internalType": "uint256",
                    "name": "amount",
                    "type": "uint256"
                }
            ],
            "name": "burnFrom",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "decimals",
            "outputs": [
                {
                    "internalType": "uint8",
                    "name": "",
                    "type": "uint8"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "spender",
                    "type": "address"
                },
                {
                    "internalType": "uint256",
                    "name": "subtractedValue",
                    "type": "uint256"
                }
            ],
            "name": "decreaseAllowance",
            "outputs": [
                {
                    "internalType": "bool",
                    "name": "",
                    "type": "bool"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "spender",
                    "type": "address"
                },
                {
                    "internalType": "uint256",
                    "name": "addedValue",
                    "type": "uint256"
                }
            ],
            "name": "increaseAllowance",
            "outputs": [
                {
                    "internalType": "bool",
                    "name": "",
                    "type": "bool"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "to",
                    "type": "address"
                },
                {
                    "internalType": "uint256",
                    "name": "amount",
                    "type": "uint256"
                }
            ],
            "name": "mint",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "name",
            "outputs": [
                {
                    "internalType": "string",
                    "name": "",
                    "type": "string"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "owner",
            "outputs": [
                {
                    "internalType": "address",
                    "name": "",
                    "type": "address"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "pause",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "paused",
            "outputs": [
                {
                    "internalType": "bool",
                    "name": "",
                    "type": "bool"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "renounceOwnership",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "symbol",
            "outputs": [
                {
                    "internalType": "string",
                    "name": "",
                    "type": "string"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "totalSupply",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "to",
                    "type": "address"
                },
                {
                    "internalType": "uint256",
                    "name": "amount",
                    "type": "uint256"
                }
            ],
            "name": "transfer",
            "outputs": [
                {
                    "internalType": "bool",
                    "name": "",
                    "type": "bool"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "from",
                    "type": "address"
                },
                {
                    "internalType": "address",
                    "name": "to",
                    "type": "address"
                },
                {
                    "internalType": "uint256",
                    "name": "amount",
                    "type": "uint256"
                }
            ],
            "name": "transferFrom",
            "outputs": [
                {
                    "internalType": "bool",
                    "name": "",
                    "type": "bool"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "newOwner",
                    "type": "address"
                }
            ],
            "name": "transferOwnership",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "unpause",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        }
    ];
    const iplTokenAddress = "0x7E884Bf184C4A61f58764D707aD6681dEF278a08";
    const bblTokenAddress = "0x7EBdc2a44b3d06f96bDF6aF992a7d9712af9D80A";
    const contractAddress = "0xdf50f23c1dAAe906450CDf410a03FAB338e1B7c0";
    const provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:7545");

    const handleIplChange = (event: any) => {
        // 👇 Get input value from "event"
        setIplAmount(event.target.value);
        if(event.target.value > 0) {
            updateSwapTokenAmount("IPL", event.target.value)
        } else {
            setBblAmount(0);
        }
       
    };
    const handleBblChange = (event: any) => {
        // 👇 Get input value from "event"
        setBblAmount(event.target.value);
        if(event.target.value > 0) {
            updateSwapTokenAmount("BBL", event.target.value)
        } else {
            setIplAmount(0);
        }
    };

    async function updateSwapTokenAmount(tokenIn: string, amount: any) {
        const contract = new ethers.Contract(contractAddress, ammAbi, provider);
        if(tokenIn == "IPL") {
            let swapBalance = await contract.swapTokenAmount(iplTokenAddress,`${amount}000000000000000000`);
            setBblAmount(Number(parseInt(swapBalance._hex, 16))/(10**18));
        } else if (tokenIn == "BBL") {
            let swapBalance = await contract.swapTokenAmount(bblTokenAddress,`${amount}000000000000000000`);
            setIplAmount(Number(parseInt(swapBalance._hex, 16))/(10**18));
        }
    }

    async function swapAmount(tokenIn: string, amount: any) {
        const contract = new ethers.Contract(contractAddress, ammAbi, provider);
        let swapBalance;
        if(tokenIn == "IPL") {
            swapBalance = await contract.swapTokenAmount(iplTokenAddress,`${amount}000000000000000000`);
        } else if (tokenIn == "BBL") {
            swapBalance = await contract.swapTokenAmount(bblTokenAddress,`${amount}000000000000000000`);
        }
        return Number(parseInt(swapBalance._hex, 16))/(10**18);
    }

    function getDestToken(tokenIn: string) {
        if(tokenIn == "BBL") {
            return "IPL"
        } else {
            return "BBL"
        }
    }

        // Hooks
    useEffect(() => {
        setHasMounted(true);
        if(isConnected) {
            setBalanceOfTokens();
        } else {
            setBblBalance(0);
            setIplBalance(0);
        }
    }, [props.isConnected])

    useEffect(() => {
        swapAmount(srcToken,1).then((amount) => {
            setDesTokenExchangeRate(amount);
        })
    }, [srcToken])

    function swapSrcDestToken() {
        if(srcToken == "IPL") {
            setSrcToken("BBL");
        } else {
            setSrcToken("IPL");
        }
       let el =  document.querySelector("div.token-input-container");
       if(el?.classList.contains("flex-col")) {
        el.classList.remove('flex-col')
        el.classList.add("flex-col-reverse")
       } 
       else if(el?.classList.contains("flex-col-reverse")) {
        el.classList.add("flex-col")
        el.classList.remove('flex-col-reverse')
       } 
    }

    function setBalanceOfTokens() {
        setBalanceOfToken(iplTokenAddress, "IPL");  
        setBalanceOfToken(bblTokenAddress, "BBL");  
    }

    async function swapToken() {
        const signer = provider.getSigner(address);
        const contract = new ethers.Contract(contractAddress, ammAbi, signer);
        const swapTokenInAddress = (srcToken === "IPL") ? iplTokenAddress : bblTokenAddress;
        const swapAmount = (srcToken === "IPL") ? iplAmount : bblAmount;
        let tokenOut = await contract.swap(swapTokenInAddress, `${swapAmount}000000000000000000`);
        setIplAmount(0.0);
        setBblAmount(0.0);
        setBalanceOfTokens();
    }

    async function setBalanceOfToken(tokenAddress: string, token:string) {
        const contract = new ethers.Contract(tokenAddress, ercAbi, provider);
        let balanceOfToken = await contract.balanceOf(address);
        if(token == "IPL") {
            setIplBalance(Number(parseInt(balanceOfToken._hex, 16))/(10**18));
        } else {
            setBblBalance(Number(parseInt(balanceOfToken._hex, 16))/(10**18));
        }
    }

    if (!hasMounted) return null;
    return (
        <div className={style.wrapper}>
      <div className={style.content}>
        <div className={style.formHeader}>
          <div className="text-black">Swap</div>
          { (desTokenExchangeRate > 0) && <div className="text-black text-sm font-normal">1 {srcToken} = {desTokenExchangeRate.toFixed(3)} {getDestToken(srcToken)}</div> }
        </div>
        <div className='flex flex-col token-input-container'>
        <div className={style.transferPropContainer}>
          <input
            type='text'
            className={style.transferPropInput}
            placeholder='0.0'
            value={iplAmount}
            pattern='^[0-9]*[.,]?[0-9]*$'
            onChange={handleIplChange}
          />
          <div className={style.currencySelector}>
            <div className={style.currencySelectorContent}>
              <div className={style.currencySelectorTicker}>{"IPL"}</div>
            </div>
            {iplBalance > 0 && <div className={style.currencyBalance}>Bal : {iplBalance.toFixed(2)}</div> 
            }
          </div>
        </div>
        <div className="text-2xl justify-center text-center relative h-0 bottom-6">
            <button className='bg-blue-200 text-4xl p-2 text-black rounded-lg' onClick={() => swapSrcDestToken()}><GoArrowDown /></button>
        </div>
        <div className={style.transferPropContainer}>
          <input
            type='text'
            className={style.transferPropInput}
            placeholder='0.0'
            pattern='^[0-9]*[.,]?[0-9]*$'
            value={bblAmount}
            onChange={handleBblChange}
          />
          <div className={style.currencySelector}>
          <div className={style.currencySelectorContent}>
              <div className={style.currencySelectorTicker}>{"BBL"}</div>
            </div>
            {bblBalance >0 && <div className={style.currencyBalance}>Bal : {bblBalance.toFixed(2)}</div> 
            }
          </div>
        </div>
        </div>
        {   isConnected ? 
            <button className={style.confirmButton} disabled={(!iplAmount || !bblAmount)} onClick={() => swapToken()}> Swap </button> : <div className={style.confirmButton} onClick={() => connect()}> Connect Wallet </div>
        }
      </div>
    </div>
    )
}