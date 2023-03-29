import React, { useEffect, useState } from 'react'
import { useAccount, useConnect, useDisconnect, useEnsName } from 'wagmi'
import { InjectedConnector } from 'wagmi/connectors/injected'
import Image from 'next/image'
import { FaPowerOff } from 'react-icons/fa';

export default function HeaderComponent(props: any) {
    const [hasMounted, setHasMounted] = useState(false);

    const { disconnect } = useDisconnect()
    const {address, isConnected, connect} = props;

    // Hooks
    useEffect(() => {
        setHasMounted(true);
    }, [])

    // Render
    if (!hasMounted) return null;

    return (
        <div className="flex flex-row justify-between h-10">
            <Image
                src="/images/logo.png"
                alt="Coindcx Logo"
                width={150}
                height={20}
                priority
              />
            {!isConnected
                ? <div>
                    <button className="h-10 bg-blue-600 text-white px-6 rounded-full hover:bg-blue-800 transition-colors ease-in-out duration-200" onClick={() => connect()}>Connect</button>
                </div>
                : <div className="flex flex-row">
                    <code className="bg-blue-600 text-zinc-200 h-10 px-4 pt-2 w-48 rounded-full block"><pre className="overflow-auto">{address}</pre></code>
                    <button className="h-10 bg-red-600 text-white mx-2 px-6 rounded-full hover:bg-red-800 transition-colors ease-in-out duration-200" onClick={() => disconnect()}><FaPowerOff /></button>
                </div>}
        </div>
    );
}