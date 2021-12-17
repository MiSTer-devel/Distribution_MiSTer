# [Atari 2600](https://en.wikipedia.org/wiki/Atari_2600) for [MiSTer Platform](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

### This is the port of [A2601 by  Retromaster](http://retromaster.wordpress.com/a2601)

### Installation
* Copy the *.rbf file to the root of the system SD card.
* Place some Atari 2600 ROMs into Atari2600 folder

## Usage notes

### Paddle
It's recommended to use mr.Spinner for paddles.

Supported options for paddle:
* "Paddle Btn" is pressed - mr.Spinner (or known controllers with integrated paddle/spinner) is used .
* "Stick Btn" is pressed - Analog Stick X/Y is used (maximum angle will choose X or Y).
* Mouse button L/R is pressed - mouse controlls the P1 paddle (L - X move, R - Y move).


### Supported mappers
* Auto detected: F8, FA, F6, F4, 32
* Manual set through file extension(ex: my_game.E0) : E0, FE, 3F, P2, CV, UA, E7, F0
* SuperChip (128b RAM). 's' can be added to extension to automatically enable SuperChip (i.e. my_game.00s).
* Any supported mapper can be forced through file extension.


## Download precompiled binaries
Go to [releases](https://github.com/MiSTer-devel/Atari2600_MiSTer/tree/master/releases) folder.


## Original readme
A2601 An FPGA-based clone of the Atari 2600 video game console (Release 0.1.0)

This archive contains source code for VHDL implementation and Python script utilities for the A2601 video game console project.

VHDL source code provided includes implementation of the 6502(7) CPU, the TIA, the 6532 RIOT, additional audio/video/joypad circuitry and bankswitching schemes plus additional RAM used by some game cartridges. Test benches are supplied for all main components (although they may be slightly out of date).

The 6502 CPU core has been developed from scratch for this project. It contains hand-crafted finite state machine and controls that implement all documented 6502 opcodes. It synthesizes quickly and has good performance in the simulator. 

The TIA implementation digitally synthesizes NTSC composite video signal via a lookup table that contains a sequence of values that signifies a sine wave at correct phase for each one of the 16 chrominance values selectable in the TIA. 

You should be able to synthesize the A2601 in Xilinx ISE without any major problems. No project files are included, but it is best to create these yourself, anyway. Two top level entities are provided: One reads cartridge ROM data from on-board flash memory, the other stores the ROM data in the FPGA built-in SRAM. It is also possible to run A2601 sources in a VHDL simulator. Some helper utilities and a test bench are provided for this purpose in the A2601/util directory.

For more information, visit the project website at <http://retromaster.wordpress.com/a2601>.

All source code and other content found in this archive is subject to GNU General Public License Version 3. See the included LICENSE.TXT file for details.

Copyright 2006, 2007, 2010 Retromaster.


# Appendix: Mappers

| Title                                      | Bankswitch Type (Extension) | TV Format | MD5                              |
|--------------------------------------------|-----------------------------|-----------|----------------------------------|
| 2 Pak Special - Challenge, Surfing         | F6                          | PAL       | fd7464edaa8cc264b97ba0d13e7f0678 |
| 2 Pak Special - Hoppy, Alien Force         | F6                          | PAL       | 5b9c2e0012fbfd29efd3306359bbfc4a |
| 2 Pak Special - Star Warrior, Frogger      | F6                          | PAL       | 4d2cef8f19cafeec72d142e34a1bbc03 |
| 32 in 1 Game Cartridge                     | 32                          | PAL       | 291bcdb05f2b37cdf9452d2bf08e0321 |
| 3-D Tic-Tac-Toe                            |                             | NTSC      | 0db4f4150fecf77e4ce72ca4d04c052f |
| 3-D Tic-Tac-Toe                            |                             | NTSC      | f3213a8a702b0646d2eaf9ee0722b51c |
| 3-D Tic-Tac-Toe                            |                             | PAL       | 7b5207e68ee85b16998bea861987c690 |
| Acid Drop                                  | F6                          | PAL       | 17ee23e5da931be82f733917adcb6386 |
| Action Force                               |                             | PAL       | d573089534ca596e64efef474be7b6bc |
| Adventure                                  |                             | NTSC      | 157bddb7192754a45372be196797f284 |
| Adventures of TRON                         |                             | NTSC      | ca4f8c5b4d6fb9d608bb96bc7ebd26c7 |
| Adventures on GX-12                        |                             | PAL       | 06cfd57f0559f38b9293adae9128ff88 |
| Air Raid                                   |                             | PAL       | 35be55426c1fec32dfb503b4f0651572 |
| Air Raiders                                |                             | NTSC      | a9cb638cd2cb2e8e0643d7a67db4281c |
| Airlock                                    |                             | NTSC      | 4d77f291dca1518d7d8e47838695f54b |
| Air-Sea Battle                             |                             | NTSC      | 16cb43492987d2f32b423817cdaaf7c4 |
| Air-Sea Battle                             |                             | NTSC      | 1d1d2603ec139867c1d1f5ddf83093f1 |
| Air-Sea Battle                             |                             | PAL       | 8aad33da907bed78b76b87fceaa838c1 |
| AKA Space Adventure                        |                             | NTSC      | 8786c1e56ef221d946c64f6b65b697e9 |
| AKA Space Adventure                        |                             | NTSC      | 8786c1e56ef221d946c64f6b65b697e9 |
| AKA Space Adventure                        |                             | NTSC      | 8786c1e56ef221d946c64f6b65b697e9 |
| Alien                                      |                             | NTSC      | f1a0a23e6464d954e3a9579c4ccd01c8 |
| Alligator People                           |                             | NTSC      | e1a51690792838c5c687da80cd764d78 |
| Alpha Beam with Ernie                      | F8                          | NTSC      | 9e01f7f95cb8596765e03b9a36e8e33c |
| Amidar                                     |                             | NTSC      | acb7750b4d0c4bd34969802a7deb2990 |
| Angeln I                                   |                             | PAL       | 6672de8f82c4f7b8f7f1ef8b6b4f614d |
| Ant Party                                  |                             | PAL       | afe4eefc7d885c277fc0649507fbcd84 |
| Apples and Dolls                           |                             | NTSC      | e73838c43040bcbc83e4204a3e72eef4 |
| Aquaventure                                | F8                          | NTSC      | 038e1e79c3d4410defde4bfe0b99cc32 |
| Armor Ambush                               |                             | NTSC      | a7b584937911d60c120677fe0d47f36f |
| Artillery Duel                             | F8                          | NTSC      | c77c35a6fc3c0f12bf9e8bae48cba54b |
| Assault                                    |                             | NTSC      | de78b3a064d374390ac0710f95edde92 |
| Asterix                                    | F8                          | PAL       | c5c7cc66febf2d4e743b4459de7ed868 |
| Asteroid Fire                              |                             | PAL       | 18f299edb5ba709a64c80c8c9cec24f2 |
| Asteroids                                  | F8                          | NTSC      | ccbd36746ed4525821a8083b0d6d2c2c |
| Asteroids                                  | F8                          | NTSC      | b227175699e372b8fe10ce243ad6dda5 |
| Astroblast                                 |                             | NTSC      | 75169c08b56e4e6c36681e599c4d8cc5 |
| Astroblast                                 |                             | NTSC      | 75169c08b56e4e6c36681e599c4d8cc5 |
| Astrowar                                   |                             | NTSC      | 8f53a3b925f0fd961d9b8c4d46ee6755 |
| Astrowar                                   |                             | NTSC      | 8f53a3b925f0fd961d9b8c4d46ee6755 |
| Atari 2600 Invaders                        |                             | NTSC      | a4aa7630e4c0ad7ebb9837d2d81de801 |
| Atari Video Cube                           |                             | NTSC      | 3f540a30fdee0b20aed7288e4a5ea528 |
| A-Team, The                                | F8                          | NTSC      | c00734a2233ef683d9b6e622ac97a5c8 |
| Atlantis                                   |                             | NTSC      | cb8afcbc4a779b588b0428ea7af211d5 |
| Atlantis II                                |                             | NTSC      | 826481f6fc53ea47c9f272f7050eedf7 |
| Autorennen                                 |                             | PAL       | b4f87ce75f7329c18301a2505fe59cd3 |
| Bachelor Party                             |                             | NTSC      | 5b124850de9eea66781a50b2e9837000 |
| Bachelorette Party                         |                             | NTSC      | 274d17ccd825ef9c728d68394b4569d2 |
| backfire                                   |                             | NTSC      | ea08d519122e6af06117fdded62c525d |
| Backgammon                                 |                             | NTSC      | 8556b42aa05f94bc29ff39c39b11bff4 |
| Bank Heist                                 |                             | NTSC      | 00ce0bdd43aed84a983bef38fe7f5ee3 |
| Barnstorming                               |                             | NTSC      | f8240e62d8c0a64a61e19388414e3104 |
| Base Attack                                |                             | NTSC      | c469151655e333793472777052013f4f |
| Basic Programming                          |                             | NTSC      | 9f48eeb47836cf145a15771775f0767a |
| Basketball                                 |                             | PAL       | 1228c01cd3c4b9c477540c5adb306d2a |
| Basketball                                 |                             | NTSC      | e13c7627b2e136b9c449d9e8925b4547 |
| Battlezone                                 | F8                          | NTSC      | 41f252a66c6301f1e8ab3612c19bc5d4 |
| Beamrider                                  | F8                          | NTSC      | 79ab4123a83dc11d468fb2108ea09e2e |
| Beany Bopper                               |                             | NTSC      | d0b9df57bfea66378c0418ec68cfe37f |
| Beat 'Em & Eat 'Em                         |                             | NTSC      | 59e96de9628e8373d1c685f5e57dcf10 |
| Berenstain Bears                           | F8                          | NTSC      | ee6665683ebdb539e89ba620981cb0f6 |
| Bermuda                                    |                             | NTSC      | 073d7aff37b7601431e4f742c36c0dc1 |
| Bermuda Triangle                           |                             | NTSC      | b8ed78afdb1e6cfe44ef6e3428789d5f |
| Berzerk                                    |                             | NTSC      | 136f75c4dd02c29283752b7e5799f978 |
| Berzerk                                    | F6                          | NTSC      | be41463cd918daef107d249f8cde3409 |
| Big Bird's Egg Catch                       | F8                          | NTSC      | 1802cc46b879b229272501998c5de04f |
| Bionic Breakthrough                        | F8                          | NTSC      | f0541d2f7cda5ec7bab6d62b6128b823 |
| Blackjack                                  |                             | NTSC      | 0a981c03204ac2b278ba392674682560 |
| Blackjack                                  |                             | NTSC      | b2761efb8a11fc59b00a3b9d78022ad6 |
| Blackjack                                  |                             | PAL       | ff7627207e8aa03730c35c735a82c26c |
| Bloody Human Freeway                       |                             | NTSC      | 1086ff69f82b68d6776634f336fb4857 |
| Blueprint                                  | F8                          | NTSC      | 33d68c3cd74e5bc4cf0df3716c5848bc |
| BMX Air Master                             | F6                          | NTSC      | 968efc79d500dce52a906870a97358ab |
| Bobby Is Going Home                        |                             | PAL       | 3cbdf71bb9fd261fbc433717f547d738 |
| Bogey Blaster                              |                             | NTSC      | c59633dbebd926c150fb6d30b0576405 |
| Boggle                                     |                             | NTSC      | a5855d73d304d83ef07dde03e379619f |
| Boing!                                     |                             | NTSC      | 0e08cd2c5bcf11c6a7e5a009a7715b6a |
| Boing!                                     |                             | NTSC      | 14c2548712099c220964d7f044c59fd9 |
| Boom Bang                                  |                             | NTSC      | a2aae759e4e76f85c8afec3b86529317 |
| Bowling                                    |                             | NTSC      | c9b7afad3bfd922e006a6bfc1d4f3fe7 |
| Bowling                                    |                             | PAL       | 4a1a0509bfc1015273a542dfe2040958 |
| Bowling                                    |                             | PAL       | f69bb58b815a6bdca548fa4d5e0d5a75 |
| Bowling                                    |                             | NTSC      | a28d872fc50fa6b64eb35981d0f4bb8d |
| Boxing                                     |                             | NTSC      | c3ef5c4653212088eda54dc91d787870 |
| Boxing                                     |                             | NTSC      | 277cca62014fceebb46c549bac25a2e3 |
| Boxing                                     |                             | PAL       | 2c45c3eb819a797237820a1816c532eb |
| Brain Games                                |                             | NTSC      | 1cca2197d95c5a41f2add49a13738055 |
| Brain Games                                |                             | NTSC      | cb9626517b440f099c0b6b27ca65142c |
| Breakout                                   |                             | NTSC      | f34f08e5eb96e500e851a80be3277a56 |
| Breakout                                   |                             | NTSC      | 9a25b3cfe2bbb847b66a97282200cca2 |
| Bridge                                     |                             | NTSC      | cfd6a8b23d12b0462baf6a05ef347cd8 |
| Buck Rogers - Planet of Zoom               | F8                          | NTSC      | 1cf59fc7b11cdbcefe931e41641772f6 |
| Bugs                                       |                             | NTSC      | 68597264c8e57ada93be3a5be4565096 |
| Bugs Bunny                                 | F8                          | NTSC      | fa4404fabc094e3a31fcd7b559cdd029 |
| Bump 'n' Jump                              | E7                          | NTSC      | 76f53abbbf39a0063f24036d6ee0968a |
| BurgerTime                                 | E7                          | NTSC      | 0443cfa9872cdb49069186413275fa21 |
| Burning Desire                             |                             | NTSC      | 19d6956ff17a959c48fcd8f4706a848d |
| Cakewalk                                   |                             | NTSC      | 7f6533386644c7d6358f871666c86e79 |
| California Games                           | F6                          | NTSC      | 9ab72d3fd2cc1a0c9adb504502579037 |
| Canyon Bomber                              |                             | NTSC      | 3051b6071cb26377cd428af155e1bfc4 |
| Carnival                                   |                             | NTSC      | 028024fb8e5e5f18ea586652f9799c96 |
| Casino                                     |                             | NTSC      | b816296311019ab69a21cb9e9e235d12 |
| Cat Trax                                   |                             | NTSC      | 76f66ce3b83d7a104a899b4b3354a2f2 |
| Cat Trax                                   |                             | NTSC      | 76f66ce3b83d7a104a899b4b3354a2f2 |
| Cathouse Blues                             |                             | NTSC      | 9e192601829f5f5c2d3b51f8ae25dbe5 |
| Centipede                                  | F8                          | NTSC      | 91c2098e88a6b13f977af8c003e0bca5 |
| Challenge                                  | F8                          | PAL       | 9905f9f4706223dadee84f6867ede8e3 |
| Challenge of.... Nexar, The                |                             | NTSC      | 5d799bfa9e1e7b6224877162accada0d |
| Challenge of.... Nexar, The                |                             | NTSC      | 5d799bfa9e1e7b6224877162accada0d |
| Chase the Chuckwagon                       |                             | NTSC      | 3e33ac10dcf2dff014bc1decf8a9aea4 |
| Chase the Chuckwagon                       |                             | NTSC      | 3e33ac10dcf2dff014bc1decf8a9aea4 |
| Checkers                                   |                             | PAL       | bce93984b920e9b56cf24064f740fe78 |
| Checkers                                   |                             | NTSC      | 3f5a43602f960ede330cd2f43a25139e |
| China Syndrome                             |                             | NTSC      | 749fec9918160921576f850b2375b516 |
| Chopper Command                            |                             | NTSC      | 85a4133f6dcf4180e36e70ad0fca0921 |
| Circus Atari                               |                             | NTSC      | a7b96a8150600b3e800a4689c3ec60a2 |
| Circus Atari                               |                             | NTSC      | a29df35557f31dfea2e2ae4609c6ebb7 |
| Circus Atari                               |                             | NTSC      | efffafc17b7cb01b9ca35324aa767364 |
| climber5_NTSC                              |                             | NTSC      | 13a11a95c9a9fb0465e419e4e2dbd50a |
| Coco Nuts                                  |                             | NTSC      | 1e587ca91518a47753a28217cd4fd586 |
| Codebreaker                                |                             | NTSC      | 5846b1d34c296bf7afc2fa05bbc16e98 |
| Codebreaker                                |                             | NTSC      | 83f50fa0fbae545e4b88bb53b788c341 |
| Color Bar Generator                        |                             | NTSC      | 76a9bf05a6de8418a3ebc7fc254b71b4 |
| Colors Demo                                |                             | NTSC      | 3f9431cc8c5e2f220b2ac14bbc8231f4 |
| Combat                                     |                             | PAL       | 0ef64cdbecccb7049752a3de0b7ade14 |
| Combat                                     |                             | NTSC      | be35d8b37bbc03848a5f020662a99909 |
| Combat Two                                 | F8                          | NTSC      | b0c9cf89a6d4e612524f4fd48b5bb562 |
| Commando                                   | F6                          | NTSC      | 5d2cc33ca798783dee435eb29debf6d6 |
| Commando Raid                              |                             | NTSC      | f457674cef449cfd85f21db2b4f631a7 |
| Communist Mutants from Space               | AR                          | NTSC      | 2c8835aed7f52a0da9ade5226ee5aa75 |
| Confrontation                              |                             | NTSC      | f965cc981cbb0822f955641f8d84e774 |
| Congo Bongo                                | F8                          | NTSC      | 00b7b4cbec81570642283e7fc1ef17af |
| Congo Bongo                                | F8                          | NTSC      | 00b7b4cbec81570642283e7fc1ef17af |
| Conquest of Mars                           | F6                          | NTSC      | 50dd164c77c4df579843baf838327469 |
| Cookie Monster Munch                       | F8                          | NTSC      | 57c5b351d4de021785cf8ed8191a195c |
| Corrida da Matematica                      |                             | NTSC      | 01e5c81258860dd82f77339d58bc5f5c |
| Cosmic Ark                                 |                             | NTSC      | 98ef1593624b409b9fb83a1c272a0aa7 |
| Cosmic Commuter                            |                             | NTSC      | 133b56de011d562cbab665968bde352b |
| Cosmic Corridor                            |                             | NTSC      | f367e58667a30e7482175809e3cec4d4 |
| Cosmic Creeps                              |                             | NTSC      | 3c853d864a1d5534ed0d4b325347f131 |
| Cosmic Swarm                               |                             | NTSC      | 9dec0be14d899e1aac4337acef5ab94a |
| Cosmic Swarm                               |                             | NTSC      | e5f17b3e62a21d0df1ca9aee1aa8c7c5 |
| Crack'ed                                   | F6S                         | NTSC      | fe67087f9c22655ce519616fc6c6ef4d |
| Crackpots                                  |                             | NTSC      | a184846d8904396830951217b47d13d9 |
| Crash Dive                                 |                             | NTSC      | fb88c400d602fe759ae74ef1716ee84e |
| Crazy Climber                              | F8                          | NTSC      | 55ef7b65066428367844342ed59f956c |
| Crazy Valet                                |                             | NTSC      | 4a7eee19c2dfb6aeb4d9d0a01d37e127 |
| crazyballoon-ntsc                          |                             | NTSC      | 0f1e13666dccc0783b1c4fc714d05ec6 |
| Cross Force                                |                             | NTSC      | c17bdc7d14a36e10837d039f43ee5fa3 |
| Crossbow                                   | F6                          | NTSC      | 8cd26dcf249456fe4aeb8db42d49df74 |
| Crypts of Chaos                            |                             | NTSC      | 384f5fbf57b5e92ed708935ebf8a8610 |
| Crystal Castles                            | F6S                         | NTSC      | 1c6eb740d3c485766cade566abab8208 |
| Cubicolor                                  |                             | NTSC      | 6fa0ac6943e33637d8e77df14962fbfc |
| Cubo Magico                                |                             | NTSC      | 64ca518905311d2d9aeb56273f6caa04 |
| Custer's Revenge                           |                             | NTSC      | 58513bae774360b96866a07ca0e8fd8e |
| Dancing Plate                              |                             | PAL       | 929e8a84ed50601d9af8c49b0425c7ea |
| Dark Cavern                                |                             | NTSC      | a422194290c64ef9d444da9d6a207807 |
| Dark Chambers                              | F6S                         | NTSC      | 106855474c69d08c8ffa308d47337269 |
| Dark Mage                                  | F8                          | NTSC      | 6333ef5b5cbb77acd47f558c8b7a95d3 |
| Deadly Duck                                |                             | NTSC      | e4c00beb17fdc5881757855f2838c816 |
| Death Trap                                 |                             | NTSC      | 4e15ddfd48bca4f0bf999240c47b49f5 |
| Decathlon                                  | FE                          | NTSC      | ac7c2260378975614192ca2bc3d20e0b |
| Defender                                   |                             | NTSC      | 0f643c34e40e3f1daafd9c524d3ffe64 |
| Defender 2                                 | F6S                         | NTSC      | d1fc4cf675c9b49fb7deb792f2f3a7a5 |
| Defender II                                | F8S                         | NTSC      | 3a771876e4b61d42e3a3892ad885d889 |
| Demolition Herby                           |                             | NTSC      | d09935802d6760ae58253685ff649268 |
| Demon Attack                               |                             | NTSC      | bcb2967b6a9254bcccaf906468a22241 |
| Demons to Diamonds                         |                             | NTSC      | f91fb8da3223b79f1c9a07b77ebfa0b2 |
| Desert Falcon                              | F6S                         | NTSC      | fd4f5536fd80f35c64d365df85873418 |
| Dice Puzzle                                |                             | NTSC      | 9222b25a0875022b412e8da37e7f6887 |
| Dig Dug                                    | F6                          | NTSC      | 6dda84fb8e442ecf34241ac0d1d91d69 |
| Dishaster                                  |                             | NTSC      | 939ce554f5c0e74cc6e4e62810ec2111 |
| Dodge 'Em                                  |                             | NTSC      | 83bdc819980db99bf89a7f2ed6a2de59 |
| Dolphin                                    |                             | NTSC      | ca09fa7406b7d2aea10d969b6fc90195 |
| Donald Duck's Speedboat                    | F8                          | NTSC      | 937736d899337036de818391a87271e0 |
| Donkey Kong                                |                             | NTSC      | 36b20c427975760cb9cf4a47e41369e4 |
| Donkey Kong Jr                             | F8                          | NTSC      | 5a6febb9554483d8c71c86a84a0aa74e |
| Double Dragon                              | F6                          | PAL       | 47464694e9cce07fdbfd096605bf39d4 |
| Double Dunk                                | F6                          | NTSC      | 368d88a6c071caba60b4f778615aae94 |
| Dragon Defender                            |                             | PAL       | 6a882fb1413912d2ce5cf5fa62cf3875 |
| Dragon Defender                            |                             | PAL       | 6a882fb1413912d2ce5cf5fa62cf3875 |
| Dragon Treasure                            |                             | NTSC      | 41810dd94bd0de1110bedc5092bef5b0 |
| Dragonstomper                              | AR                          | NTSC      | 90ccf4f30a5ad8c801090b388ddd5613 |
| Dragster                                   |                             | NTSC      | 77057d9d14b99e465ea9e29783af0ae3 |
| Dragster                                   |                             | NTSC      | 63a6eda1da30446569ac76211d0f861c |
| Dukes of Hazzard                           | F6                          | NTSC      | 51de328e79d919d7234cf19c1cd77fbc |
| Dukes of Hazzard                           |                             | NTSC      | 34ca2fcbc8ba4a0b544acd94991cfb50 |
| Dumbo's Flying Circus                      | F8                          | NTSC      | 1f773a94d919b2a3c647172bbb97f6b4 |
| Dune                                       | F8                          | NTSC      | 469473ff6fed8cc8d65f3c334f963aab |
| E.T. - The Extra-Terrestrial               | F8                          | NTSC      | 615a3bf251a38eb6638cdc7ffbde5480 |
| Earth Dies Screaming, The                  |                             | NTSC      | 033e21521e0bf4e54e8816873943406d |
| Eggomania                                  |                             | NTSC      | 42b2c3b4545f1499a083cfbc4a3b7640 |
| Elevator Action                            | F8S                         | NTSC      | 71f8bacfbdca019113f3f0801849057e |
| Eli's Ladder                               |                             | NTSC      | b6812eaf87127f043e78f91f2028f9f4 |
| Elk Attack                                 | F8                          | NTSC      | 7eafc9827e8d5b1336905939e097aae7 |
| Encounter at L-5                           |                             | NTSC      | dbc8829ef6f12db8f463e30f60af209f |
| Enduro                                     |                             | NTSC      | 94b92a882f6dbaa6993a46e2dcc58402 |
| Entity, The                                |                             | NTSC      | 9f5096a6f1a5049df87798eb59707583 |
| Entombed                                   |                             | NTSC      | 6b683be69f92958abe0e2a9945157ad5 |
| Escape from the Mindmaster                 | AR                          | NTSC      | 81f4f0285f651399a12ff2e2f35bab77 |
| Espial                                     | 3F                          | PAL       | f7a138eed69665b5cd1bfa796a550b01 |
| Euchre                                     |                             | NTSC      | 6205855cc848d1f6c4551391b9bfa279 |
| Euchre                                     |                             | PAL       | 199985cae1c0123ab1aef921daace8be |
| Exocet                                     |                             | NTSC      | 6362396c8344eec3e86731a700b13abf |
| falldown_ntsc                              | F8                          | NTSC      | 76181e047c0507b2779b4bcbf032c9d5 |
| Fantastic Voyage                           |                             | NTSC      | b80d50ecee73919a507498d0a4d922ae |
| Farmyard Fun                               |                             | NTSC      | f7e07080ed8396b68f2e5788a5c245e2 |
| Fast Eddie                                 |                             | NTSC      | 9de0d45731f90a0a922ab09228510393 |
| Fast Food                                  |                             | NTSC      | 665b8f8ead0eef220ed53886fbd61ec9 |
| Fatal Run                                  | F4S                         | PAL       | 074ec425ec20579e64a7ded592155d48 |
| Fathom                                     | F8                          | NTSC      | 0b55399cf640a2a00ba72dd155a0c140 |
| Fighter Pilot                              | F6                          | PAL       | 2ac3a08cfbf1942ba169c3e9e6c47e09 |
| Fighter Pilot                              | F6                          | PAL       | 2ac3a08cfbf1942ba169c3e9e6c47e09 |
| Final Approach                             |                             | NTSC      | 211fbbdbbca1102dc5b43dc8157c09b3 |
| Fire Birds                                 |                             | PAL       | 01e60a109a6a67c70d3c0528381d0187 |
| Fire Fighter                               |                             | NTSC      | d09f1830fb316515b90694c45728d702 |
| Fire Fly                                   |                             | NTSC      | 20dca534b997bf607d658e77fbb3c0ee |
| Fireball                                   | AR                          | NTSC      | 386ff28ac5e254ba1b1bac6916bcc93a |
| Fishing                                    |                             | PAL       | 2517827950fee41a3b9de60275c8aa6a |
| Fishing Derby                              | F6                          | NTSC      | 3c82e808fe0e6a006dc0c4e714d36209 |
| Fishing Derby                              |                             | PAL       | 7628d3cadeee0fd2e41e68b3b8fbe229 |
| Flag Capture                               |                             | PAL       | f5445b52999e229e3789c39e7ee99947 |
| Flag Capture                               |                             | NTSC      | 30512e0e83903fc05541d2f6a6a62654 |
| FlapPing                                   |                             | NTSC      | 163ff70346c5f4ce4048453d3a2381db |
| Football                                   |                             | NTSC      | e549f1178e038fa88dc6d657dc441146 |
| Football                                   |                             | NTSC      | d86deb100c6abed1588aa84b2f7b3a98 |
| Forest                                     |                             | PAL       | 213e5e82ecb42af237cfed8612c128ac |
| Frankenstein's Monster                     |                             | NTSC      | 15dd21c2608e0d7d9f54c0d3f08cca1f |
| Freeway                                    |                             | NTSC      | 8e0ab801b1705a740b476b7f588c6d16 |
| Freeway                                    |                             | NTSC      | 851cc1f3c64eaedd10361ea26345acea |
| Freeway Chicken                            |                             | PAL       | 914a8feaf6d0a1bbed9eb61d33817679 |
| Freeway Rabbit                             |                             | PAL       | 481d20ec22e7a63e818d5ef9679d548b |
| Frisco                                     |                             | NTSC      | e80a4026d29777c3c7993fbfaee8920f |
| Frog Pond                                  | F8                          | NTSC      | 5f73e7175474c1c22fb8030c3158e9b3 |
| Frogger                                    |                             | NTSC      | 081e2c114c9c20b61acf25fc95c71bf4 |
| Frogger II                                 | E0                          | NTSC      | 27c6a2ca16ad7d814626ceea62fa8fb4 |
| Frogs and Flies                            |                             | NTSC      | dcc2956c7a39fdbf1e861fc5c595da0d |
| Front Line                                 | F8                          | NTSC      | e556e07cc06c803f2955986f53ef63ed |
| Frostbite                                  |                             | NTSC      | 4ca73eb959299471788f0b685c3ba0b5 |
| Fun with Numbers                           |                             | PAL       | d816fea559b47f9a672604df06f9d2e3 |
| Fun with Numbers                           |                             | NTSC      | 819aeeb9a2e11deb54e6de334f843894 |
| Fussball                                   |                             | PAL       | cd568d6acb2f14477ebf7e59fb382292 |
| G.I. Joe - Cobra Strike                    |                             | NTSC      | c1fdd44efda916414be3527a47752c75 |
| Galaxian                                   | F8                          | NTSC      | 211774f4c5739042618be8ff67351177 |
| Gangster Alley                             |                             | NTSC      | 20edcc3aa6c189259fa7e2f044a99c49 |
| Garfield                                   | F6                          | NTSC      | dc13df8420ec69841a7c51e41b9fbba5 |
| Gas Hog                                    |                             | NTSC      | 728152f5ae6fdd0d3a9b88709bee6c7a |
| Gauntlet                                   |                             | NTSC      | e64a8008812327853877a37befeb6465 |
| Ghost Manor                                |                             | NTSC      | 0eecb5f58f55de9db4eedb3a0f6b74a8 |
| Ghost Manor                                | F8                          | NTSC      | 2bee7f226d506c217163bad4ab1768c0 |
| Ghost Manor                                | F8                          | NTSC      | 2bee7f226d506c217163bad4ab1768c0 |
| Ghostbusters                               | F8                          | NTSC      | e314b42761cd13c03def744b4afc7b1b |
| Ghostbusters II                            | F6                          | PAL       | c2b5c50ccb59816867036d7cf730bf75 |
| Gigolo                                     |                             | NTSC      | 1c8c42d1aee5010b30e7f1992d69216e |
| Glacier Patrol                             |                             | NTSC      | 5e0c37f534ab5ccc4661768e2ddf0162 |
| Glib                                       |                             | NTSC      | 2d9e5d8d083b6367eda880e80dfdfaeb |
| Go Go Home                                 |                             | NTSC      | 4093382187f8387e6d011883e8ea519b |
| Go Go Home Monster                         |                             | PAL       | 103f1756d9dc0dd2b16b53ad0f0f1859 |
| GoFish_NTSC                                | F8                          | NTSC      | 787a2faebadc670a887a0e2483b8f034 |
| Golf                                       |                             | NTSC      | 2e663eaa0d6b723b645e643750b942fd |
| Golf                                       |                             | NTSC      | f542b5d0193a3959b54f3c4c803ba242 |
| Golf                                       |                             | PAL       | 95351b46fa9c45471d852d28b9b4e00b |
| Golf                                       |                             | NTSC      | 2e663eaa0d6b723b645e643750b942fd |
| Gopher                                     |                             | NTSC      | c16c79aad6272baffb8aae9a7fff0864 |
| Gorf                                       |                             | NTSC      | 81b3bf17cf01039d311b4cd738ae608e |
| Grand Prix                                 | F6                          | NTSC      | de4436eaa41e5d7b7609512632b90078 |
| Gravitar                                   | F8                          | NTSC      | 8ac18076d01a6b63acf6e2cab4968940 |
| Gremlins                                   | F8                          | NTSC      | 01cb3e8dfab7203a9c62ba3b94b4e59f |
| Grover's Music Maker                       | F8                          | NTSC      | 4ac9f40ddfcf194bd8732a75b3f2f214 |
| Guardian                                   |                             | NTSC      | 7ab2f190d4e59e8742e76a6e870b567e |
| Gunfight 2600                              |                             | NTSC      | f750b5d613796963acecab1690f554ae |
| Gyruss                                     | E0                          | NTSC      | b311ab95e85bc0162308390728a7361d |
| H.E.R.O.                                   | F8                          | NTSC      | fca4a5be1251927027f2c24774a02160 |
| Halloween                                  |                             | NTSC      | 30516cfbaa1bc3b5335ee53ad811f17a |
| Hangman                                    |                             | NTSC      | f16c709df0a6c52f47ff52b9d95b7d8d |
| Harbor Escape                              |                             | NTSC      | b9232c1de494875efe1858fc8390616d |
| Haunted House                              |                             | NTSC      | f0a6e99f5875891246c3dbecbf2d2cea |
| Hole Hunter                                |                             | NTSC      | 3d48b8b586a09bdbf49f1a016bf4d29a |
| Holey Moley                                | F8                          | NTSC      | c52d9bbdc5530e1ef8e8ba7be692b01e |
| Home Run                                   |                             | NTSC      | 0bfabf1e98bdb180643f35f2165995d0 |
| Home Run                                   |                             | NTSC      | 9f901509f0474bf9760e6ebd80e629cd |
| Homerun                                    |                             | PAL       | ca7aaebd861a9ef47967d31c5a6c4555 |
| Human Cannonball                           |                             | PAL       | ad42e3ca3144e2159e26be123471bffc |
| Human Cannonball                           |                             | NTSC      | 7972e5101fa548b952d852db24ad6060 |
| Human Cannonball                           |                             | NTSC      | ffe51989ba6da2c6ae5a12d277862e16 |
| Hunt & Score - Memory Match                |                             | NTSC      | 102672bbd7e25cd79f4384dd7214c32b |
| Hunt & Score - Memory Match                |                             | NTSC      | 102672bbd7e25cd79f4384dd7214c32b |
| I Want My Mommy                            |                             | NTSC      | f6a282374441012b01714e19699fc62a |
| Ice Hockey                                 |                             | NTSC      | a4c08c4994eb9d24fb78be1793e82e26 |
| Ikari Warriors                             | F6                          | PAL       | 9813b9e4b8a6fd919c86a40c6bda8c93 |
| Imagic Selector ROM                        |                             | NTSC      | c4bc8c2e130d76346ebf8eb544991b46 |
| Immies & Aggies                            |                             | NTSC      | 9b21d8fc78cc4308990d99a4d906ec52 |
| Indy 500                                   |                             | NTSC      | 08188785e2b8300983529946dbeff4d2 |
| Infiltrate                                 |                             | NTSC      | afe88aae81d99e0947c0cfb687b16251 |
| International Soccer                       |                             | NTSC      | b4030c38a720dd84b84178b6ce1fc749 |
| International Soccer                       |                             | PAL       | ce904c0ae58d36d085cd506989116b0b |
| INV+                                       |                             | NTSC      | 9ea8ed9dec03082973244a080941e58a |
| Invaders by Erik Mooney                    |                             | NTSC      | 4868a81e1b6031ed66ecd60547e6ec85 |
| IQ 180                                     |                             | NTSC      | 4b9581c3100a1ef05eac1535d25385aa |
| IQ 180                                     |                             | NTSC      | 4b9581c3100a1ef05eac1535d25385aa |
| Ixion                                      | F8                          | NTSC      | 2f0546c4d238551c7d64d884b618100c |
| James Bond 007                             | E0                          | NTSC      | e51030251e440cffaab1ac63438b44ae |
| Jammed                                     |                             | NTSC      | 04dfb4acac1d0909e4c360fd2ac04480 |
| Jaw Breaker                                |                             | NTSC      | 58a82e1da64a692fd727c25faef2ecc9 |
| John K Harvey's Equalizer                  |                             | NTSC      | 30997031b668e37168d4d0e299ccc46f |
| Journey Escape                             |                             | NTSC      | 718ae62c70af4e5fd8e932fee216948a |
| Joust                                      | F8                          | NTSC      | 3276c777cbe97cdd2b4a63ffc16b7151 |
| JoustPong                                  |                             | NTSC      | ec40d4b995a795650cf5979726da67df |
| Jr. Pac-Man                                | F6S                         | NTSC      | 36c29ceee2c151b23a1ad7aa04bd529d |
| Jungle Fever                               |                             | NTSC      | 2cccc079c15e9af94246f867ffc7e9bf |
| Jungle Hunt                                | F8                          | NTSC      | 2bb9f4686f7e08c5fcc69ec1a1c66fe7 |
| Kaboom!                                    |                             | NTSC      | 5428cdfada281c569c74c7308c7f2c26 |
| Kaboom!                                    |                             | NTSC      | af6ab88d3d7c7417db2b3b3c70b0da0a |
| Kamikaze Saucers                           |                             | NTSC      | 7b43c32e3d4ff5932f39afcb4c551627 |
| Kangaroo                                   | F8                          | NTSC      | 4326edb70ff20d0ee5ba58fa5cb09d60 |
| Karate                                     |                             | NTSC      | cedbd67d1ff321c996051eec843f8716 |
| Keystone Kapers                            |                             | NTSC      | be929419902e21bd7830a7a7d746195d |
| Killer Satellites                          | AR                          | NTSC      | 9c27ef3bd01c611cdb80182a59463a82 |
| King Kong                                  |                             | PAL       | 0b1056f1091cfdc5eb0e2301f47ac6c3 |
| Klax                                       | F6S                         | PAL       | eed9eaf1a0b6a2b9bc4c8032cb43e3fb |
| Knight on the Town                         |                             | NTSC      | 7fcd1766de75c614a3ccc31b25dd5b7a |
| Kool-Aid Man                               |                             | NTSC      | 534e23210dd1993c828d944c6ac4d9fb |
| Krull                                      | F8                          | NTSC      | 4baada22435320d185c95b7dd2bcdb24 |
| Kung Fu                                    |                             | PAL       | 6805734a0b7bcc8925d9305b071bf147 |
| Kung Fu Superkicks                         | F8                          | NTSC      | 3f58f972276d1e4e0e09582521ed7a5b |
| Kung Fu Superkicks                         | F8                          | NTSC      | 3f58f972276d1e4e0e09582521ed7a5b |
| Kung-Fu Master                             | F8                          | NTSC      | 5b92a93b23523ff16e2789b820e2a4c5 |
| labyrinth                                  | AR                          | NTSC      | 925dda3c61b81eeb7bd8467b6e99dedc |
| Lady in Wading                             |                             | NTSC      | 95a89d1bf767d7cc9d0d5093d579ba61 |
| Laser Blast                                |                             | NTSC      | 931b91a8ea2d39fe4dca1a23832b591a |
| Laser Blast                                |                             | NTSC      | d5e27051512c1e7445a9bf91501bda09 |
| Laser Blast                                |                             | PAL       | 0d1b3abf681a2fc9a6aa31a9b0e8b445 |
| Laser Gates                                |                             | NTSC      | 1fa58679d4a39052bd9db059e8cda4ad |
| Laser Gates                                |                             | NTSC      | 1fa58679d4a39052bd9db059e8cda4ad |
| Laser Volley                               |                             | NTSC      | 48287a9323a0ae6ab15e671ac2a87598 |
| Lochjaw                                    |                             | NTSC      | 86128001e69ab049937f265911ce7e8a |
| Lock 'n' Chase                             |                             | NTSC      | 71464c54da46adae9447926fdbfc1abe |
| London Blitz                               |                             | NTSC      | b4e2fd27d3180f0f4eb1065afc0d7fc9 |
| Looping                                    | F8                          | NTSC      | 5babe0cad3ec99d76b0aa1d36a695d2f |
| Lord of the Rings                          |                             | NTSC      | e4b12deaafd1dbf5ac31afe4b8e9c233 |
| Lord of the Rings                          | E0                          | NTSC      | e24d7d879281ffec0641e9c3f52e505a |
| Lost Luggage                               |                             | NTSC      | 7c00e7a205d3fda98eb20da7c9c50a55 |
| M.A.D.                                     |                             | NTSC      | 393e41ca8bdd35b52bf6256a968a9b89 |
| M.A.S.H                                    |                             | NTSC      | 835759ff95c2cdc2324d7c1e7c5fa237 |
| MagiCard                                   | CV                          | NTSC      | cddabfd68363a76cd30bee4e8094c646 |
| Malagai                                    |                             | NTSC      | ccb5fa954fb76f09caae9a8c66462190 |
| Mangia'                                    |                             | NTSC      | 54a1c1255ed45eb8f71414dadb1cf669 |
| Marauder                                   |                             | NTSC      | 13895ef15610af0d0f89d588f376b3fe |
| Marine Wars                                |                             | NTSC      | b00e8217633e870bf39d948662a52aac |
| Marineflieger                              |                             | PAL       | 1b8d35d93697450ea26ebf7ff17bd4d1 |
| Mario Bros.                                | F8                          | NTSC      | e908611d99890733be31733a979c62d8 |
| Master Builder                             |                             | NTSC      | ae4be3a36b285c1a1dff202157e2155d |
| Masters of the Universe                    | E7                          | NTSC      | 3b76242691730b2dd22ec0ceab351bc6 |
| Math Gran Prix                             |                             | NTSC      | 470878b9917ea0348d64b5750af149aa |
| Maze Craze                                 |                             | PAL       | f825c538481f9a7a46d1e9bc06200aaf |
| Maze Craze                                 |                             | PAL       | 8108ad2679bd055afec0a35a1dca46a4 |
| mc_ntsc_7_26_3                             | F4                          | NTSC      | 09a03e0c85e667695bcd6c6394e47e5f |
| mc_pal_4_28_3                              | F4                          | PAL       | dcd5057de94c86ff81db76cb4a146439 |
| McDonald's                                 |                             | NTSC      | 35b43b54e83403bb3d71f519739a9549 |
| Mega Force                                 |                             | NTSC      | daeb54957875c50198a7e616f9cc8144 |
| MegaMania                                  |                             | NTSC      | 318a9d6dda791268df92d72679914ac3 |
| Meltdown                                   |                             | NTSC      | 96e798995af6ed9d8601166d4350f276 |
| Midnight Magic                             | F6                          | NTSC      | f1554569321dc933c87981cf5c239c43 |
| Millipede                                  | F6S                         | NTSC      | 3c57748c8286cf9e821ecd064f21aaa9 |
| Mind Maze                                  | F8                          | NTSC      | 0e224ea74310da4e7e2103400eb1b4bf |
| Miner 2049er                               | 3F                          | NTSC      | fa0570561aa80896f0ead05c46351389 |
| Miner 2049er Volume II                     | 3F                          | PAL       | 468f2dec984f3d4114ea84f05edf82b6 |
| Mines of Minos                             |                             | NTSC      | 4543b7691914dfd69c3755a5287a95e1 |
| Minesweeper                                |                             | PAL       | ac5f78bae0638cf3f2a0c8d07eb4df69 |
| Miniature Golf                             |                             | NTSC      | df62a658496ac98a3aa4a6ee5719c251 |
| Miniature Golf                             |                             | NTSC      | 384db97670817103dd8c0bbdef132445 |
| Miniature Golf                             |                             | NTSC      | df62a658496ac98a3aa4a6ee5719c251 |
| Miniaturer Golf                            |                             | PAL       | 73521c6b9fed6a243d9b7b161a0fb793 |
| Miss Piggy's Wedding                       | F8                          | NTSC      | 4181087389a79c7f59611fb51c263137 |
| Missile Command                            |                             | NTSC      | 3a2e2d0c6892aa14544083dfb7762782 |
| Missile Control                            |                             | PAL       | cb24210dc86d92df97b38cf2a51782da |
| Mission 3000 A.D.                          |                             | PAL       | 6efe876168e2d45d4719b6a61355e5fe |
| Mission Survive                            |                             | PAL       | cf9069f92a43f719974ee712c50cd932 |
| Misterious Thief, A                        |                             | NTSC      | e13818a5c0cb2f84dd84368070e9f099 |
| Mogul Maniac                               |                             | NTSC      | 7af40c1485ce9f29b1a7b069a2eb04a7 |
| Mondo Pong V2                              |                             | NTSC      | 1f60e48ad98b659a05ce0c1a8e999ad9 |
| Monster Cise                               | F8                          | NTSC      | 6913c90002636c1487538d4004f7cac2 |
| Montezuma's Revenge                        | E0                          | NTSC      | 3347a6dd59049b15a38394aa2dafa585 |
| Moon Patrol                                | F8                          | NTSC      | 515046e3061b7b18aa3a551c3ae12673 |
| Moonsweeper                                | F8                          | NTSC      | 203abb713c00b0884206dcc656caa48f |
| Moto Laser                                 |                             | NTSC      | eb503cc64c3560cd78b7051188b7ba56 |
| Motocross                                  | F8                          | NTSC      | 5641c0ff707630d2dd829b26a9f2e98f |
| Motocross                                  |                             | PAL       | f5a2f6efa33a3e5541bc680e9dc31d5b |
| Motocross Racer                            | F8                          | NTSC      | de0173ed6be9de6fd049803811e5f1a8 |
| MotoRodeo                                  | F6                          | PAL       | b1e2d5dc1353af6d56cd2fe7cfe75254 |
| Mountain King                              | FA                          | NTSC      | 7e51a58de2c0db7d33715f518893b0db |
| Mouse Trap                                 |                             | NTSC      | 5678ebaa09ca3b699516dba4671643ed |
| Mr. Do!                                    | F8                          | NTSC      | 0164f26f6b38a34208cd4a2d0212afc3 |
| Mr. Do!'s Castle                           | E0                          | NTSC      | b7a7e34e304e4b7bc565ec01ba33ea27 |
| Mr. Postman                                |                             | NTSC      | f0daaa966199ef2b49403e9a29d12c50 |
| Ms. Pac-Man                                | F8                          | NTSC      | 87e79cd41ce136fd4f72cc6e2c161bee |
| Ms. Pac-Man                                | F8                          | NTSC      | aeb104f1e7b166bc0cbaca0a968fde51 |
| Multi-Sprite Demo 2                        | AR                          | NTSC      | 42ae81ae8ac51e5c238639f9f77d91ae |
| Music Machine, The                         |                             | NTSC      | 65b106eba3e45f3dab72ea907f39f8b4 |
| My Golf                                    | F8                          | PAL       | dfad86dd85a11c80259f3ddb6151f48f |
| Mysterious Thief, A                        |                             | NTSC      | 48f18d69799a5f5451a5f0d17876acef |
| Name This Game                             |                             | NTSC      | 36306070f0c90a72461551a7a4f3a209 |
| Name This Game                             |                             | NTSC      | 36306070f0c90a72461551a7a4f3a209 |
| NFL Football                               |                             | PAL       | 7608abdfd9b26f4a0ecec18b232bea54 |
| Night Driver                               |                             | NTSC      | f48022230bb774a7f22184b48a3385af |
| Night Stalker                              |                             | PAL       | 2783006ee6519f15cbc96adae031c9a9 |
| No Escape!                                 |                             | NTSC      | b6d52a0cf53ad4216feb04147301f87d |
| Nuts                                       |                             | NTSC      | de7a64108074098ba333cc0c70eef18a |
| Obelix                                     | F8                          | PAL       | 669840b0411bfbab5c05b786947d55d4 |
| Ocean City                                 |                             | NTSC      | 4cabc895ea546022c2ecaa5129036634 |
| Off the Wall                               | F6S                         | NTSC      | 98f63949e656ff309cefa672146dc1b8 |
| Off Your Rocker                            |                             | NTSC      | b6166f15720fdf192932f1f76df5b65d |
| Official Frogger, The                      | AR                          | NTSC      | c73ae5ba5a0a3f3ac77f0a9e14770e73 |
| Oink!                                      |                             | NTSC      | c9c25fc536de9a7cdc5b9a916c459110 |
| Okie Dokie                                 |                             | NTSC      | cca33ae30a58f39e3fc5d80f94dc0362 |
| Omega Race                                 | FA                          | NTSC      | 9947f1ebabb56fd075a96c6d37351efa |
| Open Sesame                                |                             | PAL       | 28d5df3ed036ed63d33a31d0d8b85c47 |
| Oscar's Trash Race                         | F8                          | NTSC      | fa1b060fd8e0bca0c2a097dcffce93d3 |
| Out of Control                             |                             | NTSC      | f97dee1aa2629911f30f225ca31789d4 |
| Outlaw                                     |                             | PAL       | 2e3728f3086dc3e71047ffd6b2d9f015 |
| Outlaw                                     |                             | NTSC      | f060826626aac9e0d8cda0282f4b7fc3 |
| Oystron                                    |                             | NTSC      | 91f0a708eeb93c133e9672ad2c8e0429 |
| Pac Kong                                   |                             | NTSC      | 936ef1d6f8a57b9ff575dc195ee36b80 |
| Pac-Kong                                   |                             | PAL       | d223bc6f13358642f02ddacfaf4a90c9 |
| Pac-Man                                    |                             | NTSC      | 6e372f076fb9586aff416144f5cfe1cb |
| Pac-Space                                  |                             | NTSC      | c569e57dca93d3bee115a49923057fd7 |
| Panda Chase                                |                             | PAL       | f8582bc6ca7046adb8e18164e8cecdbc |
| Parachute                                  |                             | PAL       | 714e13c08508ee9a7785ceac908ae831 |
| Party Mix                                  | AR                          | NTSC      | 012b8e6ef3b5fd5aabc94075c527709d |
| Peek-A-Boo                                 |                             | NTSC      | e40a818dac4dd851f3b4aafbe2f1e0c1 |
| Pele's Soccer                              |                             | PAL       | 7a09299f473105ae1ef3ad6f9f2cd807 |
| Pele's Soccer                              |                             | NTSC      | ace319dc4f76548659876741a6690d57 |
| Pele's Soccer                              |                             | NTSC      | ace319dc4f76548659876741a6690d57 |
| Pengo                                      | F8                          | NTSC      | 04014d563b094e79ac8974366f616308 |
| Pepsi Invaders                             |                             | NTSC      | 212d0b200ed8b45d8795ad899734d7d7 |
| Persian Gulf War                           |                             | NTSC      | 6ce2110ac5dd89ab398d9452891752ab |
| Pete Rose Baseball                         | F6                          | NTSC      | 09388bf390cd9a86dc0849697b96c7dc |
| Phantom Tank                               |                             | PAL       | 6b1fc959e28bd71aed7b89014574bdc2 |
| Phantom Tank                               |                             | PAL       | 6b1fc959e28bd71aed7b89014574bdc2 |
| Pharaoh's Curse                            |                             | NTSC      | 62f74a2736841191135514422b20382d |
| Phaser Patrol                              | AR                          | NTSC      | 7dcbfd2acc013e817f011309c7504daa |
| Philly Flasher                             |                             | NTSC      | ca54de69f7cdf4d7996e86f347129892 |
| Phoenix                                    | F8                          | NTSC      | 7e52a95074a66640fcfde124fffd491a |
| Pick 'n' Pile                              | F6                          | PAL       | da79aad11572c80a96e261e4ac6392d0 |
| Pick Up                                    |                             | NTSC      | 1d4e0a034ad1275bc4d75165ae236105 |
| Picnic                                     |                             | NTSC      | 17c0a63f9a680e7a61beba81692d9297 |
| Piece o' Cake                              |                             | NTSC      | d3423d7600879174c038f53e5ebbf9d3 |
| Pigs in Space                              | F8                          | NTSC      | 8e4fa8c6ad8d8dce0db8c991c166cdaa |
| Pitfall II                                 | P2                          | NTSC      | 6d842c96d5a01967be9680080dd5be54 |
| Pitfall!                                   |                             | NTSC      | aad91be0bf78d33d29758876d999848a |
| Pitfall!                                   |                             | NTSC      | e42b937c30c617241ca9e01e4510c3f6 |
| Pitfall!                                   |                             | NTSC      | 3e90cf23106f2e08b2781e41299de556 |
| Pizza Chef                                 |                             | NTSC      | 82efe7984783e23a7c55266a5125c68e |
| Planet of the Apes                         |                             | NTSC      | 9efb4e1a15a6cdd286e4bcd7cd94b7b8 |
| Planet Patrol                              |                             | NTSC      | 043f165f384fbea3ea89393597951512 |
| Plaque Attack                              |                             | NTSC      | da4e3396aa2db3bd667f83a1cb9e4a36 |
| Pleiades                                   | UA                          | NTSC      | 8bbfd951c89cc09c148bfabdefa08bec |
| Poker Squares                              |                             | NTSC      | 8c136e97c0a4af66da4a249561ed17db |
| Polaris                                    | 3F                          | PAL       | 203049f4d8290bb4521cc4402415e737 |
| Pole Position                              | F8                          | NTSC      | 5f39353f7c6925779b0169a87ff86f1e |
| Polo                                       |                             | NTSC      | ee28424af389a7f3672182009472500c |
| Pompeii                                    |                             | NTSC      | a83b070b485cf1fb4d5a48da153fdf1a |
| Pooyan                                     |                             | NTSC      | 4799a40b6e889370b7ee55c17ba65141 |
| Popeye                                     | E0                          | NTSC      | c7f13ef38f61ee2367ada94fdcc6d206 |
| Porky's                                    | F8                          | NTSC      | f93d7fee92717e161e6763a88a293ffa |
| Pressure Cooker                            | F8                          | NTSC      | 97d079315c09796ff6d95a06e4b70171 |
| Private Eye                                | F8                          | NTSC      | ef3a4f64b6494ba770862768caf04b86 |
| Pumuckl I                                  |                             | PAL       | fb833ed50c865a9a505a125fc9d79a7e |
| Pyramid War                                |                             | PAL       | 37fd7fa52d358f66984948999f1213c5 |
| Qb                                         |                             | NTSC      | ac53b83e1b57a601eeae9d3ce1b4a458 |
| Qb                                         |                             | PAL       | 9281eccd7f6ef4b3ebdcfd2204c9763a |
| Qb                                         |                             | NTSC      | 34e37eaffc0d34e05e40ed883f848b40 |
| Q-bert                                     |                             | NTSC      | 484b0076816a104875e00467d431c2d2 |
| Q-bert's Qubes                             | E0                          | NTSC      | 517592e6e0c71731019c0cebc2ce044f |
| Quadrun                                    | F8                          | NTSC      | 392d34c0498075dd58df0ce7cd491ea2 |
| Quest for Quintana Roo                     | F8                          | NTSC      | a0675883f9b09a3595ddd66a6f5d3498 |
| Quick Step!                                |                             | NTSC      | 7eba20c2291a982214cc7cbe8d0b47cd |
| Rabbit Transit                             | F8                          | NTSC      | 2e5b184da8a27c4d362b5a81f0b4a68f |
| Rabbit Transit                             | AR                          | NTSC      | fb4ca865abc02d66e39651bd9ade140a |
| Racing Car                                 |                             | NTSC      | 4df9d7352a56a458abb7961bf10aba4e |
| Racquetball                                |                             | NTSC      | a20d931a8fddcd6f6116ed21ff5c4832 |
| Radar                                      |                             | NTSC      | 74f623833429d35341b7a84bc09793c0 |
| Radar                                      |                             | NTSC      | 74f623833429d35341b7a84bc09793c0 |
| Radar Lock                                 | F6S                         | NTSC      | baf4ce885aa281fd31711da9b9795485 |
| Raft Rider                                 |                             | NTSC      | 92a1a605b7ad56d863a56373a866761b |
| Raiders of the Lost Ark                    | F8                          | NTSC      | f724d3dd2471ed4cf5f191dbb724b69f |
| Rainbow Invaders                           |                             | NTSC      | cb96b0cf90ab7777a2f6f05e8ad3f694 |
| Ram It                                     |                             | NTSC      | 7096a198531d3f16a99d518ac0d7519a |
| Rampage!                                   | F6                          | NTSC      | 5e1b4629426f4992cf3b2905a696e1a7 |
| Reactor                                    |                             | NTSC      | 9f8fad4badcd7be61bbd2bcaeef3c58f |
| RealSports Baseball                        | F8                          | NTSC      | eb634650c3912132092b7aee540bbce3 |
| RealSports Boxing                          | F6                          | NTSC      | 3177cc5c04c1a4080a927dfa4099482b |
| RealSports Football                        | F8                          | NTSC      | 7ad257833190bc60277c1ca475057051 |
| RealSports Soccer                          | F8                          | NTSC      | 08f853e8e01e711919e734d85349220d |
| RealSports Tennis                          | F8                          | PAL       | c7eab66576696e11e3c11ffff92e13cc |
| RealSports Volleyball                      |                             | NTSC      | aed0b7bd64cc384f85fdea33e28daf3b |
| Rescue Bira Bira                           |                             | NTSC      | 8a9d874a38608964f33ec0c35cab618d |
| Rescue Terra I                             |                             | NTSC      | 60a61da9b2f43dd7e13a5093ec41a53d |
| Resgate Espacial                           | F8                          | NTSC      | 42249ec8043a9a0203dde0b5bb46d8c4 |
| Revenge of the Apes                        | F8                          | NTSC      | 0b01909ba84512fdaf224d3c3fd0cf8d |
| Revenge of the Beefsteak Tomatoes          |                             | NTSC      | 4f64d6d0694d9b7a1ed7b0cb0b83e759 |
| Reversi                                    |                             | PAL       | 6468d744be9984f2a39ca9285443a2b2 |
| Riddle of the Sphinx                       |                             | NTSC      | a995b6cbdb1f0433abc74050808590e6 |
| River Patrol                               | 3F                          | NTSC      | 31512cdfadfd82bfb6f196e3b0fd83cd |
| River Raid                                 |                             | NTSC      | 01b09872dcd9556427761f0ed64aa42a |
| River Raid                                 | F6                          | NTSC      | 291cc37604bc899e8e065c30153fc4b9 |
| River Raid II                              | F6                          | NTSC      | ab56f1b2542a05bebc4fbccfc4803a38 |
| Road Runner                                | F6                          | NTSC      | 2bd00beefdb424fa39931a75e890695d |
| Robin Hood                                 | F8                          | NTSC      | 72a46e0c21f825518b7261c267ab886e |
| Robin Hood                                 | F8                          | NTSC      | 72a46e0c21f825518b7261c267ab886e |
| Robot Tank                                 | FE                          | NTSC      | 4f618c2429138e0280969193ed6c107e |
| Roc 'n Rope                                | F8                          | NTSC      | 65bd29e8ab1b847309775b0de6b2e4fe |
| Room of Doom                               |                             | NTSC      | 67931b0d37dc99af250dd06f1c095e8d |
| Rubik's Cube 3-D                           |                             | NTSC      | 40b1832177c63ebf81e6c5b61aaffd3a |
| Rush Hour                                  |                             | NTSC      | f3cd0f886201d1376f3abab2df53b1b9 |
| Saboteur                                   | F8                          | NTSC      | 1ec57bbd27bdbd08b60c391c4895c1cf |
| Save Mary!                                 | F6S                         | NTSC      | 4d502d6fb5b992ee0591569144128f99 |
| Save Our Ship                              |                             | NTSC      | ed1a784875538c7871d035b7a98c2433 |
| Save the Whales                            |                             | NTSC      | e377c3af4f54a51b85efe37d4b7029e6 |
| scsi200_NTSC                               |                             | NTSC      | 137373599e9b7bf2cf162a102eb5927f |
| SCSIcide                                   |                             | NTSC      | 523f5cbb992f121e2d100f0f9965e33f |
| SCSIcide                                   |                             | NTSC      | 523f5cbb992f121e2d100f0f9965e33f |
| Scuba Diver                                |                             | NTSC      | 19e761e53e5ec8e9f2fceea62715ca06 |
| Sea Hawk                                   |                             | NTSC      | 3fd53bfeee39064c945a769f17815a7f |
| Sea Hunt                                   |                             | NTSC      | 5dccf215fdb9bbf5d4a6d0139e5e8bcb |
| Sea Monster                                |                             | PAL       | 68489e60268a5e6e052bad9c62681635 |
| seantsc                                    |                             | NTSC      | dde55d9868911407fe8b3fefef396f00 |
| Seaquest                                   |                             | NTSC      | 240bfbac5163af4df5ae713985386f92 |
| Secret Agent                               |                             | NTSC      | 605fd59bfef88901c8c4794193a4cbad |
| Secret Quest                               | F6S                         | NTSC      | fc24a94d4371c69bc58f5245ada43c44 |
| Sentinel                                   | F6                          | NTSC      | 8da51e0c4b6b46f7619425119c7d018e |
| Shark Attack                               |                             | NTSC      | 54f7efa6428f14b9f610ad0ca757e26c |
| Shootin' Gallery                           |                             | NTSC      | b5a1a189601a785bdb2f02a424080412 |
| Shooting Arcade                            | F6S                         | NTSC      | 15c11ab6e4502b2010b18366133fc322 |
| Shuttle Orbiter                            |                             | NTSC      | 25b6dc012cdba63704ea9535c6987beb |
| Sinistar                                   | F8                          | NTSC      | ea38fcfc06ad87a0aed1a3d1588744e4 |
| Sir Lancelot                               | F8                          | NTSC      | 7ead257e8b5a44cac538f5f54c7a0023 |
| Skate Boardin'                             | F8                          | NTSC      | f847fb8dba6c6d66d13724dbe5d95c4d |
| Skeet Shoot                                |                             | NTSC      | 39c78d682516d79130b379fa9deb8d1c |
| Skeet Shoot                                |                             | NTSC      | 5f2b4c155949f01c06507fb32369d42a |
| Skeleton                                   |                             | PAL       | 8e887d1ba5f3a71ae8a0ea16a4af9fc9 |
| Skeleton                                   |                             | NTSC      | 28a4cd87fb9de4ee91693a38611cb53c |
| Skeleton+                                  |                             | NTSC      | eafe8b40313a65792e88ff9f2fe2655c |
| Skeleton+                                  |                             | PAL       | 63c7395d412a3cd095ccdd9b5711f387 |
| Ski Hunt                                   |                             | PAL       | 8654d7f0fb351960016e06646f639b02 |
| Ski Run                                    |                             | PAL       | f10e3f45fb01416c87e5835ab270b53a |
| Skiing                                     |                             | NTSC      | b76fbadc8ffb1f83e2ca08b6fb4d6c9f |
| Skiing                                     |                             | NTSC      | 60bbd425cb7214ddb9f9a31948e91ecb |
| Skiing                                     |                             | PAL       | 367411b78119299234772c08df10e134 |
| Sky Diver                                  |                             | PAL       | 3f75a5da3e40d486b21dfc1c8517adc0 |
| Sky Diver                                  |                             | NTSC      | 46c021a3e9e2fd00919ca3dd1a6b76d8 |
| Sky Jinks                                  |                             | NTSC      | 8bd8f65377023bdb7c5fcf46ddda5d31 |
| Sky Patrol                                 | F8                          | NTSC      | 4c9307de724c36fd487af6c99ca078f2 |
| Sky Skipper                                |                             | NTSC      | 3b91c347d8e6427edbe942a7a405290d |
| Slot Machine                               |                             | PAL       | 75ea128ba96ac6db8edf54b071027c4e |
| Slot Machine                               |                             | NTSC      | f90b5da189f24d7e1a2117d8c8abc952 |
| Slot Racers                                |                             | PAL       | d1d704a7146e95709b57b6d4cac3f788 |
| Slot Racers                                |                             | NTSC      | aed82052f7589df05a3f417bb4e45f0c |
| Slot Racers                                |                             | NTSC      | 5f708ca39627697e859d1c53f8d8d7d2 |
| Smurf - Rescue in Gargamel's Castle        | F8                          | NTSC      | 3d1e83afdb4265fa2fb84819c9cfd39c |
| Smurfs Save the Day                        | F8                          | NTSC      | a204cd4fb1944c86e800120706512a64 |
| Sneak 'n Peek                              |                             | NTSC      | 9c6faa4ff7f2ae549bbcb14f582b70e4 |
| Snoopy and the Red Baron                   | F8                          | NTSC      | 57939b326df86b74ca6404f64f89fce9 |
| Snow White and the Seven Dwarfs            | F8                          | NTSC      | 75ee371ccfc4f43e7d9b8f24e1266b55 |
| Solar Fox                                  | F8                          | NTSC      | 947317a89af38a49c4864d6bdd6a91fb |
| Solar Storm                                |                             | NTSC      | 97842fe847e8eb71263d6f92f7e122bd |
| Solaris                                    | F6                          | NTSC      | e72eb8d4410152bdcb69e7fba327b420 |
| SolarPlexus                                |                             | NTSC      | b5be87b87fd38c61b1628e8e2d469cb5 |
| Sorcerer                                   |                             | NTSC      | d2c4f8a4a98a905a9deef3ba7380ed64 |
| Sorcerer's Apprentice                      | F8                          | NTSC      | 5f7ae9a7f8d79a3b37e8fc841f65643a |
| Space Attack                               |                             | NTSC      | 17badbb3f54d1fc01ee68726882f26a6 |
| Space Canyon                               |                             | NTSC      | 559317712f989f097ea464517f1a8318 |
| Space Cavern                               |                             | NTSC      | df6a28a89600affe36d94394ef597214 |
| Space Instigators                          | F8                          | NTSC      | b2a6f31636b699aeda900f07152bab6e |
| Space Invaders                             |                             | NTSC      | e10bf1af6bf3b4a253c5bef6577fe923 |
| Space Invaders                             |                             | NTSC      | 72ffbef6504b75e69ee1045af9075f66 |
| Space Jockey                               |                             | NTSC      | d1a9478b99d6a55e13a9fd4262da7cd4 |
| Space Jockey                               |                             | NTSC      | 6f2aaffaaf53d23a28bf6677b86ac0e3 |
| Space Raid                                 |                             | PAL       | 1a624e236526c4c8f31175e9c89b2a22 |
| Space Robot                                |                             | PAL       | 1bef389e3dd2d4ca4f2f60d42c932509 |
| Space Robot                                |                             | NTSC      | 3dfb7c1803f937fadc652a3e95ff7dc6 |
| Space Shuttle                              | F8                          | NTSC      | 5894c9c0c1e7e29f3ab86c6d3f673361 |
| Space Treat                                |                             | NTSC      | 6c9a32ad83bcfde3774536e52be1cce7 |
| Space Tunnel                               |                             | PAL       | 8917f7c1ac5eb05b82331cf01c495af2 |
| Space Tunnel                               |                             | NTSC      | df2745d585238780101df812d00b49f4 |
| Space War                                  |                             | PAL       | b702641d698c60bcdc922dbd8c9dd49c |
| Space War                                  |                             | NTSC      | 7e9da5cb84d5bc869854938fe3e85ffa |
| Space War                                  |                             | NTSC      | a7ef44ccb5b9000caf02df3e6da71a92 |
| Spacechase                                 |                             | NTSC      | ec5c861b487a5075876ab01155e74c6c |
| SpaceMaster X-7                            |                             | NTSC      | 45040679d72b101189c298a864a5b5ba |
| Spider Fighter                             | F6                          | NTSC      | ba3a17efd26db8b4f09c0cf7afdf84d1 |
| Spider Fighter                             |                             | NTSC      | 24d018c4a6de7e5bd19a36f2b879b335 |
| Spider Maze                                |                             | NTSC      | 21299c8c3ac1d54f8289d88702a738fd |
| Spiderdroid                                |                             | NTSC      | 8454ed9787c9d8211748ccddb673e920 |
| Spider-Man                                 |                             | NTSC      | 199eb0b8dce1408f3f7d46411b715ca9 |
| Spike's Peak                               | F8                          | NTSC      | a4e885726af9d97b12bb5a36792eab63 |
| Spinning Fireball                          |                             | NTSC      | d3171407c3a8bb401a3a62eb578f48fb |
| Spitfire Attack                            |                             | NTSC      | cef2287d5fd80216b2200fb2ef1adfa8 |
| Springer                                   | 3F                          | NTSC      | 4cd796b5911ed3f1062e805a3df33d98 |
| Sprint Master                              | F6S                         | NTSC      | 5a8afe5422abbfb0a342fb15afd7415f |
| Spy Hunter                                 | F8                          | NTSC      | 3105967f7222cc36a5ac6e5f6e89a0b4 |
| Squeeze Box                                |                             | NTSC      | ba257438f8a78862a9e014d831143690 |
| Squirrel                                   |                             | NTSC      | 68878250e106eb6c7754bc2519d780a0 |
| Squoosh                                    |                             | NTSC      | 22abbdcb094d014388d529352abe9b4b |
| Sssnake                                    |                             | NTSC      | 21a96301bb0df27fde2e7eefa49e0397 |
| Stampede                                   |                             | NTSC      | 21d7334e406c2407e69dbddd7cec3583 |
| Stampede                                   |                             | NTSC      | e66e5af5dea661d58420088368e4ef0d |
| Stampede                                   |                             | PAL       | c9196e28367e46f8a55e04c27743148f |
| Star Fox                                   |                             | NTSC      | f526d0c519f5001adb1fc7948bfbb3ce |
| Star Raiders                               | F8                          | NTSC      | cbd981a23c592fb9ab979223bb368cd5 |
| Star Ship                                  |                             | NTSC      | e363e467f605537f3777ad33e74e113a |
| Star Ship                                  |                             | NTSC      | e363e467f605537f3777ad33e74e113a |
| Star Ship                                  |                             | NTSC      | 7b938c7ddf18e8362949b62c7eaa660a |
| Star Strike                                |                             | NTSC      | 79e5338dbfa6b64008bb0d72a3179d3c |
| Star Trek - Strategic Operations Simulator | F8                          | NTSC      | 03c3f7ba4585e349dd12bfa7b34b7729 |
| Star Trek - Strategic Operations Simulator | F8                          | NTSC      | 03c3f7ba4585e349dd12bfa7b34b7729 |
| Star Voyager                               |                             | NTSC      | 813985a940aa739cc28df19e0edd4722 |
| Star Voyager                               |                             | NTSC      | 813985a940aa739cc28df19e0edd4722 |
| Star Wars - Death Star Battle              | E0                          | NTSC      | 5336f86f6b982cc925532f2e80aa1e17 |
| Star Wars - Death Star Battle              | E0                          | NTSC      | 5336f86f6b982cc925532f2e80aa1e17 |
| Star Wars - Ewok Adventure                 | E0                          | NTSC      | c246e05b52f68ab2e9aee40f278cd158 |
| Star Wars - Ewok Adventure                 | E0                          | PAL       | 6dfad2dd2c7c16ac0fa257b6ce0be2f0 |
| Star Wars - Jedi Arena                     |                             | NTSC      | c9f6e521a49a2d15dac56b6ddb3fb4c7 |
| Star Wars - Jedi Arena                     |                             | NTSC      | c9f6e521a49a2d15dac56b6ddb3fb4c7 |
| Star Wars - The Arcade Game                | E0                          | NTSC      | 6339d28c9a7f92054e70029eb0375837 |
| Star Wars - The Arcade Game                | E0                          | NTSC      | 6339d28c9a7f92054e70029eb0375837 |
| Star Wars - The Empire Strikes Back        |                             | NTSC      | 3c8e57a246742fa5d59e517134c0b4e6 |
| Star Wars - The Empire Strikes Back        |                             | NTSC      | 3c8e57a246742fa5d59e517134c0b4e6 |
| Stargate                                   | F6S                         | NTSC      | 57fa2d09c9e361de7bd2aa3a9575a760 |
| Stargunner                                 |                             | NTSC      | a3c1c70024d7aabb41381adbfb6d3b25 |
| StarMaster                                 |                             | NTSC      | d69559f9c9dc6ef528d841bf9d91b275 |
| Steeplechase                               |                             | NTSC      | 656dc247db2871766dffd978c71da80c |
| Steeplechase                               |                             | NTSC      | a174cece06b3abc0aec3516913cdf9cc |
| Stellar Track                              |                             | NTSC      | 0b8d3002d8f744a753ba434a4d39249a |
| Stell-A-Sketch                             | AR                          | NTSC      | 47aef18509051bab493589cb2619170b |
| Strategy X                                 |                             | NTSC      | 9333172e3c4992ecf548d3ac1f2553eb |
| Strat-O-Gems Deluxe                        | F4                          | PAL       | 807a8ff6216b00d52aba2dfea5d8d860 |
| Strawberry Shortcake - Musical Match-Ups   |                             | NTSC      | e10d2c785aadb42c06390fae0d92f282 |
| Street Racer                               |                             | NTSC      | 6ff4156d10b357f61f09820d03c0f852 |
| Stronghold                                 |                             | NTSC      | 7b3cf0256e1fa0fdc538caf3d5d86337 |
| Stunt Cycle                                |                             | NTSC      | c3bbc673acf2701b5275e85d9372facf |
| Stunt Man                                  |                             | NTSC      | ed0ab909cf7b30aff6fc28c3a4660b8e |
| Stunt Man                                  |                             | NTSC      | ed0ab909cf7b30aff6fc28c3a4660b8e |
| Stunt Man                                  |                             | NTSC      | ed0ab909cf7b30aff6fc28c3a4660b8e |
| Submarine Commander                        |                             | NTSC      | f3f5f72bfdd67f3d0e45d097e11b8091 |
| Sub-Scan                                   |                             | NTSC      | 5af9cd346266a1f2515e1fbc86f5186a |
| Subterranea                                | F8                          | NTSC      | 93c52141d3c4e1b5574d072f1afde6cd |
| Suicide Mission                            | AR                          | NTSC      | e4c666ca0c36928b95b13d33474dbb44 |
| Summer Games                               | F6                          | NTSC      | 45027dde2be5bdd0cab522b80632717d |
| Super Baseball                             | F6                          | NTSC      | 7adbcf78399b19596671edbffc3d34aa |
| Super Box                                  | F6                          | NTSC      | 1c85c0fc480bbd69dc301591b6ecb422 |
| Super Breakout                             |                             | NTSC      | 0ad9a358e361256b94f3fb4f2fa5a3b1 |
| Super Challenge Baseball                   |                             | NTSC      | 9d37a1be4a6e898026414b8fee2fc826 |
| Super Challenge Football                   |                             | NTSC      | e275cbe7d4e11e62c3bfcfb38fca3d49 |
| Super Cobra                                | E0                          | NTSC      | c29f8db680990cb45ef7fef6ab57a2c2 |
| Super Futebol                              | F8                          | NTSC      | 2447e17a4e18e6b609de498fe4ab52ba |
| Super-Ferrari                              |                             | NTSC      | 724613effaf7743cbcd695fab469c2a8 |
| Superman                                   |                             | NTSC      | a9531c763077464307086ec9a1fd057d |
| Superman                                   |                             | NTSC      | 5de8803a59c36725888346fdc6e7429d |
| Surfer's Paradise                          |                             | PAL       | c20f15282a1aa8724d70c117e5c9709e |
| Surf's Up                                  | F8                          | NTSC      | aec9b885d0e8b24e871925630884095c |
| Surround                                   |                             | PAL       | a60598ad7ee9c5ccad42d5b0df1570a1 |
| Surround                                   |                             | NTSC      | 31d08cb465965f80d3541a57ec82c625 |
| Survival Island                            | AR                          | NTSC      | 045035f995272eb2deb8820111745a07 |
| Survival Run                               |                             | NTSC      | 85e564dae5687e431955056fbda10978 |
| Sweat! - The Decathlon Game                | AR                          | NTSC      | e51c23389e43ab328ccfb05be7d451da |
| SWOOPS!                                    |                             | PAL       | 5d8f1ab95362acdf3426d572a6301bf2 |
| SWOOPS!                                    |                             | NTSC      | 278f14887d601b5e5b620f1870bc09f6 |
| Sword of Saros                             | AR                          | NTSC      | 528400fad9a77fd5ad7fc5fdc2b7d69d |
| SwordQuest - EarthWorld                    | F8                          | NTSC      | 05ebd183ea854c0a1b56c218246fbbae |
| SwordQuest - FireWorld                     | F8                          | NTSC      | f9d51a4e5f8b48f68770c89ffd495ed1 |
| SwordQuest - WaterWorld                    | F8                          | NTSC      | bc5389839857612cfabeb810ba7effdc |
| Synthcart                                  | F8                          | NTSC      | 2c2aea31b01c6126c1a43e10cacbfd58 |
| T.F. Space Invaders                        |                             | NTSC      | 294762000e853b4319f9991c1ced5dfc |
| Tac-Scan                                   |                             | NTSC      | d45ebf130ed9070ea8ebd56176e48a38 |
| Tanks But No Tanks                         |                             | NTSC      | fa6fe97a10efb9e74c0b5a816e6e1958 |
| Tapeworm                                   |                             | NTSC      | de3d0e37729d85afcb25a8d052a6e236 |
| Tapper                                     | F8                          | NTSC      | c0d2434348de72fa6edcc6d8e40f28d7 |
| Targ                                       |                             | NTSC      | 2d6741cda3000230f6bbdd5e31941c01 |
| Task Force                                 |                             | NTSC      | 0c35806ff0019a270a7acae68de89d28 |
| Tax Avoiders                               | F8                          | NTSC      | a1ead9c181d67859aa93c44e40f1709c |
| Taz                                        | F8                          | NTSC      | 4702d8d9b48a332724af198aeac9e469 |
| Teddy Apple                                |                             | PAL       | 8c2fa33048f055f38358d51eefe417db |
| Telepathy                                  | F8                          | NTSC      | 3d7aad37c55692814211c8b590a0334c |
| Tempest                                    | F8                          | NTSC      | c830f6ae7ee58bcc2a6712fb33e92d55 |
| Tennis                                     |                             | NTSC      | 42cdd6a9e42a3639e190722b8ea3fc51 |
| Tennis                                     |                             | NTSC      | aca09ffea77174b148b96b205109db4d |
| Tennis                                     |                             | PAL       | 16e04823887c547dc24bc70dff693df4 |
| Test Cart                                  |                             | NTSC      | f0631c6675033428238408885d7e4fde |
| Tetris 2600                                |                             | NTSC      | b0e1ee07fbc73493eac5651a52f90f00 |
| Texas Chainsaw Massacre, The               |                             | NTSC      | 5eeb81292992e057b290a5cd196f155d |
| This Planet Sucks                          |                             | NTSC      | a98b649912b6ca19eaf5c2d2faf38562 |
| This Planet Sucks                          |                             | NTSC      | a98b649912b6ca19eaf5c2d2faf38562 |
| Threshold                                  |                             | NTSC      | e63a87c231ee9a506f9599aa4ef7dfb9 |
| Thrust                                     | F6                          | NTSC      | de7bca4e569ad9d3fd08ff1395e53d2d |
| Thrust                                     | F6                          | NTSC      | de7bca4e569ad9d3fd08ff1395e53d2d |
| Thrust v1.26                               | F6                          | NTSC      | 7ded20e88b17c8149b4de0d55c795d37 |
| Thunderground                              |                             | NTSC      | cf507910d6e74568a68ac949537bccf9 |
| Time Machine                               |                             | PAL       | 7576dd46c2f8d8ab159d97e3a3f2052f |
| Time Pilot                                 | F8                          | NTSC      | 4e99ebd65a967cabf350db54405d577c |
| Time Race                                  |                             | PAL       | 5db9e5bf663cad6bf159bc395f6ead53 |
| Time Warp                                  |                             | NTSC      | 619de46281eb2e0adbb98255732483b4 |
| Title Match Pro Wrestling                  | F8                          | NTSC      | 12123b534bdee79ed7563b9ad74f1cbd |
| Tom Boy                                    |                             | PAL       | de61a0b171e909a5a4cfcf81d146dbcb |
| Tom Boy                                    |                             | NTSC      | ece908d77ab944f7bac84322b9973549 |
| Tomarc the Barbarian                       | F8                          | NTSC      | 8bc0d2052b4f259e7a50a7c771b45241 |
| Tooth Protectors                           | E0                          | NTSC      | fa2be8125c3c60ab83e1c0fe56922fcb |
| Towering Inferno                           |                             | NTSC      | 0aa208060d7c140f20571e3341f5a3f8 |
| Track and Field                            | F6                          | NTSC      | 6ae4dc6d7351dacd1012749ca82f9a56 |
| Treasure Below                             |                             | NTSC      | 81414174f1816d5c1e583af427ac89fc |
| Treasure Island                            |                             | PAL       | 1bb91bae919ddbd655fa25c54ea6f532 |
| treat_ntsc                                 |                             | NTSC      | 9e135f5dce61e3435314f5cddb33752f |
| Trick Shot                                 |                             | NTSC      | 24df052902aa9de21c2b2525eb84a255 |
| TRON - Deadly Discs                        |                             | NTSC      | fb27afe896e7c928089307b32e5642ee |
| Tunnel Runner                              | FA                          | NTSC      | b2737034f974535f5c0c6431ab8caf73 |
| Turmoil                                    |                             | NTSC      | 7a5463545dfb2dcfdafa6074b2f2c15e |
| Tutankham                                  | E0                          | NTSC      | 085322bae40d904f53bdcc56df0593fc |
| UFO                                        |                             | PAL       | 6bb09bc915a7411fe160d0b2e4d66047 |
| Ungeheuer der Tiefe                        |                             | PAL       | 1278f74ca1dfaa9122df3eca3c5bcaad |
| Universal Chaos                            |                             | NTSC      | 81a010abdba1a640f7adf7f84e13d307 |
| Unknown 20th Century Fox Game              | F8                          | NTSC      | 5f950a2d1eb331a1276819520705df94 |
| Unknown Activision Game #1                 |                             | NTSC      | ee681f566aad6c07c61bbbfc66d74a27 |
| Unknown Activision Game #2                 |                             | NTSC      | 700a786471c8a91ec09e2f8e47f14a04 |
| Up 'n Down                                 | F8                          | NTSC      | a499d720e7ee35c62424de882a3351b6 |
| Vanguard                                   | F8                          | NTSC      | c6556e082aac04260596b4045bc122de |
| Vault Assault                              |                             | NTSC      | 787ebc2609a31eb5c57c4a18837d1aee |
| Venetian Blinds Demo                       |                             | NTSC      | d08fccfbebaa531c4a4fa7359393a0a9 |
| Venture                                    |                             | NTSC      | 3e899eba0ca8cd2972da1ae5479b4f0d |
| Video Checkers                             |                             | NTSC      | 539d26b6e9df0da8e7465f0f5ad863b7 |
| Video Chess                                |                             | NTSC      | f0b7db930ca0e548c41a97160b9f6275 |
| Video Cube                                 |                             | NTSC      | ed1492d4cafd7ebf064f0c933249f5b0 |
| Video Jogger                               |                             | NTSC      | 4191b671bcd8237fc8e297b4947f2990 |
| Video Olympics                             |                             | NTSC      | 60e0ea3cbe0913d39803477945e9e5ec |
| Video Olympics                             |                             | NTSC      | c00b65d1bae0aef6a1b5652c9c2156a1 |
| Video Pinball                              |                             | NTSC      | 107cc025334211e6d29da0b6be46aec7 |
| Video Pinball                              |                             | NTSC      | 107cc025334211e6d29da0b6be46aec7 |
| Video Reflex                               |                             | NTSC      | ee659ae50e9df886ac4f8d7ad10d046a |
| Video Time Machine                         |                             | NTSC      | 93acd5020ae8eb5673601e2edecbc158 |
| Vogel Flieh                                |                             | NTSC      | e17699a54c90f3a56ae4820f779f72c4 |
| Vulture Attack                             |                             | NTSC      | 1f21666b8f78b65051b7a609f1d48608 |
| Vulture Attack                             |                             | NTSC      | 1f21666b8f78b65051b7a609f1d48608 |
| Vulture Attack                             |                             | NTSC      | 1f21666b8f78b65051b7a609f1d48608 |
| Wabbit                                     |                             | NTSC      | 6041f400b45511aa3a69fab4b8fc8f41 |
| Walker                                     |                             | PAL       | 7ff53f6922708119e7bf478d7d618c86 |
| Walker                                     |                             | NTSC      | d175258b2973b917a05b46df4e1cf15d |
| Wall Ball                                  |                             | NTSC      | d3456b4cf1bd1a7b8fb907af1a80ee15 |
| Wall Break                                 |                             | NTSC      | c16fbfdbfdf5590cc8179e4b0f5f5aeb |
| Wall-Defender                              |                             | PAL       | 372bddf113d088bc572f94e98d8249f5 |
| War 2000                                   |                             | PAL       | 6522717cfd75d1dba252cbde76992090 |
| Warlords                                   |                             | NTSC      | cbe5a166550a8129a5e6d374901dffad |
| Warplock                                   |                             | NTSC      | 679e910b27406c6a2072f9569ae35fc8 |
| Warring Worms                              |                             | NTSC      | 7e7c4c59d55494e66eef5e04ec1c6157 |
| Wavy Line Test 2                           |                             | NTSC      | 5c73693a89b06e5a09f1721a13176f95 |
| Weltraumtunnel                             |                             | PAL       | bce4c291d0007f16997faa5c4db0a6b8 |
| Wing War                                   | F8                          | PAL       | 9d2938eb2b17bb73e9a79bbc06053506 |
| Wings                                      | FA                          | NTSC      | 8e48ea6ea53709b98e6f4bd8aa018908 |
| Winter Games                               | F6                          | NTSC      | 83fafd7bd12e3335166c6314b3bde528 |
| Wizard                                     |                             | NTSC      | 7b24bfe1b61864e758ada1fe9adaa098 |
| Wizard of Wor                              |                             | NTSC      | 7e8aa18bc9502eb57daaf5e7c1e94da7 |
| Word Zapper                                |                             | NTSC      | ec3beb6d8b5689e867bafb5d5f507491 |
| Words-Attack                               |                             | PAL       | 2facd460a6828e0e476d3ac4b8c5f4f7 |
| World End                                  |                             | PAL       | 130c5742cd6cbe4877704d733d5b08ca |
| Worm War I                                 |                             | NTSC      | 87f020daa98d0132e98e43db7d8fea7e |
| X-Doom V.26                                |                             | NTSC      | 0d35618b6d76ddd46d2626e9e3e40db5 |
| Xenophobe                                  | F6                          | NTSC      | eaf744185d5e8def899950ba7c6e7bb5 |
| Xevious                                    | F8                          | NTSC      | c6688781f4ab844852f4e3352772289b |
| X-Man                                      |                             | NTSC      | 5961d259115e99c30b64fe7058256bcf |
| X'Mission                                  |                             | PAL       | 332f01fd18e99c6584f61aa45ee7791e |
| Yahtzee                                    |                             | NTSC      | d090836f0a4ea8db9ac7abb7d6adf61e |
| Yars' Revenge                              |                             | NTSC      | c5930d0e8cdae3e037349bfa08e871be |
| Zaxxon                                     | F8                          | NTSC      | eea0da9b987d661264cce69a7c13c3bd |
| Z-Tack                                     |                             | PAL       | d6dc9b4508da407e2437bfa4de53d1b2 |
