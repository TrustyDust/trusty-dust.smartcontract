sudo source .env

sudo forge script script/Deploy.s.sol:Deploy \
  --rpc-url $RPC_URL \
  --chain-id 84532 \
  --broadcast --verify --legacy --resume \
  --private-key $PRIVATE_KEY \
  --retries 10 --delay 5

# BASE SEPOLIA
  → new DustToken@0xb54e25Db229942E8E9360613A46A72cf0f92E83c
  → new Identity@0xa171051a408E9720D587A80247977d596dB37614
  → new Core@0x9dF9F9952cF743542Cf97337EfA37Ae936E669B7
  → new Content@0x7F9194dD652a4A4796c01a5a625a2aC71017fB2c
  → new Jobs@0x245b947434a2C28134f6d6C26eB57962e11bc1b0
  → new Verifier@0xbca221bCcf6c4cF32d1e578b75eC53fA697c0979

# LISK SEPOLIA
  → new DustToken@0x330a7b9BCE82363879Ef5383E4754d66e65343C4
  → new Identity@0xc459e56EE983De8d5e10c18C6cFD9FDcC51cBBf4
  → new Core@0x11e7B912D56a3F3e96aD9bE2737debDE38bFc2a2
  → new Content@0xF88b5e87bb25c68278c6FdA529536bE45936A017
  → new Jobs@0xf2654Ac6b25C9815003d0a8f3D14422b822B01a9
  → new Verifier@0x60cd018766a0C3e521324d77b79D08EA786dBdc0