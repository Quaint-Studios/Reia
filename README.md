[![Godot Builder](https://github.com/Quaint-Studios/Reia/actions/workflows/godot.yml/badge.svg)](https://github.com/Quaint-Studios/Reia/actions/workflows/godot.yml)
[![Open Collective backers and sponsors](https://img.shields.io/opencollective/all/reia?logo=opencollective)](https://opencollective.com/reia)


# Reia
Explore endless worlds and embark on a magical adventure of a lifetime! Reia is an action-adventure RPG, also open-source. Play offline or online with friends, or login for an MMO experience! Create and explore worlds, manage your own economy and products, and restore Reia's world via the story. Choose the way you want to play.


## Info

> **Website:** Visit the website over at [https://www.playreia.com](https://www.playreia.com).

> **Discord:** Our Discord server is now finally more open! [Join our Discord now](https://discord.playreia.com). ❤️

> **Sustenet:** Visit [https://github.com/Quaint-Studios/Sustenet](https://github.com/Quaint-Studios/Sustenet) to see the netcode designed specifically for this project and made in Rust.

> **Jobs:** Check out the list of [jobs](https://github.com/Quaint-Studios/Reia/blob/master/docs/JOBS.md) for this project. You can also visit the [jobs page](https://www.playreia.com/jobs) on our website to learn more information.

## Table of Contents
<ol>
  <li><a href="/docs/ROADMAP.md">Roadmap</a></li>
  <li><a href="#contributing">Contributing</a></li>
  <li><a href="#about-this-project">About this Project</a>
    <ol>
      <li><a href="#overview">Overview</a></li>
      <li><a href="#play-the-way-you-want">Play the way you want</a></li>
      <li><a href="#why-this-project-was-created">Why this project was created</a></li>
      <li><a href="#lore">Lore</a>
        <ol>
          <li><a href="#realms">Realms</a></li>
          <li><a href="#combat-statuses">Combat Statuses</a></li>
          <li><a href="#ascension">Ascension</a></li>
          <li><a href="#rough-story">Rough Story</a></li>
        </ol>
      </li>
      <li><a href="#gameplay">Gameplay</a>
        <ol>
          <li><a href="#overview-1">Overview</a></li>
        </ol>
      </li>
    </ol>
  </li>
  <li><a href="#faqs">FAQs</a></li>
</ol>


## Contributing
If there's anything in the [Roadmap](/docs/ROADMAP.md) you want to work on then here's how you can help.

1. Create an issue specifically for that task.
2. Fork the repository.
3. Create a branch with the following format:
     - ❌ makosai
     - ❌ makosai/change-the-layout-of-buttons
     - ✔️ makosai/main-menu
     - ✔️ makosai/keybindings
     - ✔️ makosai/multiplayer
     - ✔️ makosai/art

    > **a.** Your username/the-root-focus where the root focus is something that you could build upon in the future.
    > 
    > **b.** You can add more art, you can improve the multiplayer, there will sometimes be more keybindings, and the main-menu may change over time.
    > 
    > **c.** It shouldn't be overly specific either.
3. Follow the existing commit patterns:
     - ❌ fix the attack state
     - ❌ Fixed the attack state
     - ❌ Fix the attack state (missing period)
     - ✔️ Fix the attack state.
     - ✔️ Update the Main Menu UI.
     - ✔️ Change the player speed.
     - ✔️ Read the player position on load.
     - ✔️ Remove the ability to walk.
  The length of the commit doesn't matter. Just don't go overboard. If it's a long commit, then summarize it and then put the rest of the information in the description of the commit.
5. Create a pull-request and done!

## About this Project

### Overview

Reia is an open-source oRPG where four Ethereals, the deities of this world have a conflict. One of them, their sister, is Reia herself. This universe is a world where magic is capable, that includes your standard elements and more. Every Ethereal can create their own realm, what would be the equivalent of a giant planet that continues to grow in size as they consume ether from their surroundings & other realms. Player-owned floating islands, raids of varying sizes (even server-wide raids), Bosses, PvP zones, and custom mini-games!

### Play the way you want
We want you to be able to focus on whatever sort of content you choose to. Whether that's the story, the combat, playing or the economy and getting rich. And it doesn't end there. Customize your own Island, explore Infinite Dungeons, and do so much more! That's the vision.

### Why this project was created

One of the main reasons why this project exists is to provide you with a game that you can have fun in. Another reason is a way to get myself outside of my 20 years of experience in programming. Migrating from Unity into Godot head first was definitely an experience. And making shaders, scripts, and art have all been an enjoyable process in the Godot engine. I'll have to say, going forward will be a fun ride. Wish both me and this project luck! And be sure to check out the [website](https://www.playreia.com).

### Lore
#### Realms
In this world are the Ethereals. These entities are the equivalent of deities. They create their own realms and govern them according to their unique gifts. When a realm is created, the Ethereal that rules over it can use the energy within the realm to form occupants. These occupants can become anything; mindless zombies or being of free will -- including a love or hate for their creator.

##### Combat Statuses
A realm can be ruled in several ways at this stage; neutrally, passively, aggressively, and defensively. This determines how fast the realm will grow.

In a neutral realm, the Ethereal keeps their size as is. This prevents them from growing rapidly. But, it's not impossible. The realm can still grow by absorbing pure ether from the void, an area of emptiness between realms.

A passive realm will passively take energy from both the void and neighboring realms. Both of these options are still slow. This still poses some risk. Taking from other realms is considered hostile and can spark wars. Compared to taking ether from the void, siphoning from neighboring realms is much faster but still slow.

An aggressive realm is one that actively attacks other realms. When realms are at war with each other, they can send invasions. Ether can be stole from the realm itself, occupants, and directly from the Ethereal when at war. This can result in killing an Ethereal.

There's an instance where a realm may be under attack by an aggressive realm. This realm can take a defensive stance where any invader can have their occupants taken in as food, absorbing their ether and making the Ethereal's realm stronger.

But there's another way that doesn't involve any conflicts. Instead, it involves collaboration. Ethereals can choose to merge. Thsi s where two Ethereals come to an agreement for cohabitation. Their realms merge and they become one being. Their consciousness' are still separate and they can always split their body. But they are now existing as one being. A single Ethereal. Just 3 times as strong. Their abilities increase this much as a result of the merge itself, it ends up pulling in more ether, increasing their power in the process.

###### Realm States
A realm has four states: faulted, normal, stimulated, and ascended. These determine how much the realm has matured via absorbing ether. A faulted state is a realm that is below the average strength. Normal realms are those that have naturally grown larger by absorbing the empty space around it. It factors in age. A stimulated realm is one that has chosen a path that accelerates its growth, such as attacking or defending. Lastly, an ascended realm is one that has been stimulated enough to have two times as much ether equal to that of their normal state.


###### Ascension
When a realm ascends, a phenomenon occurs. Two, four during a merge, new occupants are created in that realm and become Ethereals. These occupants will have free will, no matter what. These new Ethereals eventually take on a physical shape. The form they take on is typically a humanoid one. But it's not an explicit decision. Nor is it a permanent one. It's a preference and identity.

Each newborn Ethereal will have a unique power at birth but can still use ether to perform basic elemental *magic*.

Once the children become teenagers, aging every 100 years, or a rate of 1:100, they're taught how to make their own realms. They aren't particularly age-restricted in this process. But their energy to do so is usually enough at this stage. A prodigy could make a realm at birth. *Much like how a 2 year old could be the world's greatest mathematician.* Ridiculously unlikely, but not entirely impossible!

Once the children make their own realm, they move out of their parents' realm and transfer to their new home. At this point, they can make their own choices on how they'd like to govern. This includes how they choose to grow their realms & what type of occupants they may have.

#### Rough Story
The game instantly throws the player in an intense situation. Once they login for the first time, they're presented with a "Delve into the deep..." button that pulses and a "Sleep for a while longer." button. Immediately, this lets you know that your choices changes your outcome.

Sleeping for a while longer just allows the player to play as Reia and view how she interacted with her realm's occupants. It also depicts how much they loved and worshiped her. There's no conflict during this timeline. It's just extra story.

Delving into the deep starts the Nightmare of Reia. Reia, much like in the initial login view, is posted up on a hill. The player zooms into her, getting into the standard 3rd person perspective. They player will also be allowed to use all of Reia's abilities. Giving them her full arsenal. But the skill bar will only have a limited amount of abilities. Changing abilities is possible, but not something told to the player since they have no real need for it. The sky turns dark and a fleet of enemy occupants can be seen raining down from the sky. They seem like small meteors. But when a larger one lands, along with a large tower crashing down, she knows what's happening. She's being invaded by one of her siblings.

After the player finishes fending off the invasion, the vision backs out, a clock can be seen, it spins forward in time, it zooms in again, Reia can be seen fighting ferociously, time speeds up again, Reia can be seen in her crystal, it zooms out and the player wakes up in 1st person. They're panting, get out of bed, and walk up to a mirror where character customization now happens.

It should be noted that every outcome can be replayed and alternate choices can be played through without creating a new account. But, in reality, you're still stuck with your real choices. This process is just to allow you to experience alternate possibilities and unlock items from them as well.

### Gameplay
#### Overview
You play as an occupant of Reia's realm. One of your main tasks is to find spirits that are fragments of Reia. They possess unique elements and can be leveled up. Your individual levels and your spirit level are separate. But your individual levels can have an impact on your spirit form. There are player-owned floating islands where you can customize them & govern them with trainable NPCs. Upgradeable gear with replacable parts is also a feature for versaility in combat. Players can sell books, music, and in-game goods (skins) in a marketplace. This allows people to have a way to creatively express themselves and gives their island a way to act as an actual store. There are endless open-world areas that are procedurally generated. Puzzles and mini-games are also included, with mini-games potentially being player-created. Day night cycles & regions means that certain cities will have different time zones. This overview is very roughly written, but more will be added eventually.

## FAQs
### What's the progress on Reia?
1. What's left to do?
    
    We actually have a [roadmap](/docs/ROADMAP.md)! It's taking time because it's self-funded so we can give it the love and passion it deserves.

2. What features are currently being developed?

    Oh, where do I start?
    
    How about the not-so-technical stuff first. We're working on designing new locations for you to explore, drawing pretty art with awesome colors to make you drool, a Map system, a new UI system, and a custom quest system so you get intricate questing much like *Old School Runescape* and other great titles!

    Now for the slightly technical side of things -- our tech stack! We're designing our our own [networking solution](https://github.com/Quaint-Studios/Sustenet), we're use Turso with Rust so we can support databases both offline and offline, we also use [csprance/gecs](https://github.com/csprance/gecs) and GDScript for the bulk of the game!

3. Are there upcoming alpha or beta tests?

    Yep! There's no date yet. But you can [subscribe](https://www.playreia.com/newsletter?ref=GitHub) to our newsletter to get notified. We know how annoying emails can get. So you can always decide what you want to hear and how frequent! We respect that.

4. Are there any planned expansions or DLCs?

    Ooo... This is something we're excited about. We obviously want to monitize the game but we also want the barrier for entry to be low. You can read more about it in our [Monetization README](/docs/MONETIZATION.md).

### How is multiplayer and singleplayer handled in Reia?
1. Will this be online or offline?
  
    Reia will be both! You have three options:
    
    - Play on the main server with your friends and family, leveling up and questing together or on your own.
    - Adventure solo, enjoying an offline experience. Start a brand new character locally or clone your online character to your computer, continuing solo.
    - Use your local characters to host your own private server, playing with a small group of friends. Or join existing private servers to try out modded versions of the game.

2. If I migrate my online character to my local machine, can I migrate it back online?

    Sadly, no. And there's a good reason for this. Once the character is on your local machine, you're free to edit your currency and many other things. This means you're free to cheat. Go ahead! Just do it locally. Have fun.

3. Will migrating from online to offline delete my online character?
   
    No. While it's a one-way migration, the migration doesn't delete your online character. So you can take your online progress to offline mode but you can't take your offline progress back to the main online game.

4. Can I use my offline characters on all private servers?

    Private servers are just like the official servers. They can choose whether to force you to use a character that has only ever been online on either their server or the main servers, one that's only ever been on their servers alone, or they can allow all types of characters.

### How will mods work in Reia?

1. What type of mods are there?

    There are two types of mods: Server and Local. Just keep in mind when you're playing offline, you are the server. But there are different categories.

2. So what are the cetegories of mods?

    **Gameplay Mods** (Server): These mods can alter game mechanics, add new features, or change existing ones. Examples include altered combat systems, harder or easier content, additional minigames, or new events.
    
    **Visual Mods** (Server, Local): This can These mods focus on the aesthetics of the game. They can include new character skins, improved textures, custom animations, and enhanced visual effects.
    
    **Content Mods** (Server): These mods add new content to the game, such as new characters, items, weapons, and locations. They can also include new storylines, quests, or expansions to the existing game world.
    
    **Quality of Life Mods** (Server): These mods aim to improve the overall user experience by adding features like better inventory management, enhanced user interfaces, or tracking tools.
    
    **Utility Mods** (Local): These mods provide additional tools and functionalities, such as mod management systems, debugging tools, or performance optimizers.
    
    **Sound Mods** (Server, Local): These mods can change or enhance the game's audio, including new soundtracks, sound effects, or voiceovers.

    > *This entire mod section is still in progress. So some things may be added and removed. Like a category for lore or other things.*

3. How do I install mods in Reia?

    We wanted to use mod.io but we're going to do a custom modding solution. We'll eventually create a page or in-game tool! It's still under construction.

4. Are there any restrictions on the type of mods I can use?

    As of right now, no. But, there are some smart people out there. I'm sure someone will find something that needs a rule. Other than that, have fun with the mods. They're locked down in a way that we try not to make them influence other people's gameplay too much.

5. Are theyre any restrictions on the type of modes I can submit?

    Nothing explicit and nothing that infringes on someone else's copyrights. That should cover everything. But, just like the previous question, someone is bound to eventually cause this rule to change.

6. Can mods be used in both online and offline modes?

    In the second FAQ item for this section, it covers where you can use each mod type. So yeah, you can use them in those areas!

## 🌱 Made by Quaint Studios

We're independent developers of games and software. [Quaint Studios](https://www.quaintstudios.com) is a small team focused on making Reia a fun, open, and player-driven game that you can enjoy for free. Visit our website for updates, behind-the-scenes, and more projects!

- [Website](https://quaintstudios.com)
- [Reia Discord](https://discord.playreia.com)

---

## 💖 Sponsors & Supporters

_Reia is possible thanks to our amazing community and supporters!_

<p>
  <a href="https://www.digitalocean.com/">
    <img src="https://opensource.nyc3.cdn.digitaloceanspaces.com/attribution/assets/PoweredByDO/DO_Powered_by_Badge_blue.svg" width="201px">
  </a>
</p>

Want to support development? [Sponsor us on Open Collective!](https://opencollective.com/reia)
