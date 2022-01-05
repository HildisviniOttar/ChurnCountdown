# ChurnCountdown

Useful macOS tray app to show THORChain churn countdown.  

![ChurnCountdown Screenshot](/doc/screenshot.png)

On startup it loads mimir CHURNINTERVAL from https://midgard.thorchain.info/v2/thorchain/mimir  
Then loads nextChurnHeight from https://midgard.thorchain.info/v2/network

It then connects to Websockets **wss://rpc.thorchain.info/websocket** and receives new block info every ~6 seconds and updates the UI.  

Pressing 'Reconnect' will reload all of the above connections.  

App is not Notarised but does use Xcode sandbox features for Incoming/Outgoing network connection (required for WebSockets).  

### Build Instructions (Xcode)

Open project in Xcode.  
Choose *Product* > *Archive*.  
Choose app in list that appears and press *Distribute app*.  
Choose *Copy app* and choose a destination, e.g. Desktop.  
Open folder just saved and right click on binary and choose 'Open'.  
